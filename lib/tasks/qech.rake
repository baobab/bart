ENV['OFFSET_ARV'] ||= "-1"
ENV['ENDPOINT_ARV'] ||= "10000"
ENV['OFFSET_INSERT'] ||= "10"

namespace :db do
  namespace :migrate do
    desc "Migrate the Queen Elizabeth Central Hospital data"
    task :qech => :environment do
      
      # Don't even think of doing this remotely!
      raise RuntimeError.new("The connection host is not localhost!") unless (ActiveRecord::Base.connection.instance_variable_get(:@config)[:host] == "localhost")

      class BufferedPatient < Patient 
        acts_as_buffered
      end

      class BufferedPatientIdentifier < PatientIdentifier 
        acts_as_buffered
      end

      class BufferedPatientName < PatientName 
        acts_as_buffered
      end

      class BufferedPatientAddress < PatientAddress 
        acts_as_buffered
      end

      class BufferedPerson < Person 
        acts_as_buffered
      end

      class BufferedEncounter < Encounter
        acts_as_buffered
      end

      class BufferedObs < Observation
        acts_as_buffered
      end

      class BufferedOrder < Order
        acts_as_buffered
      end

      class BufferedDrugOrder < DrugOrder
        acts_as_buffered
      end

      class BufferedRelationship < Relationship 
        acts_as_buffered
      end

      class Qech

        def self.migrate
          @@program_hash = {}
          @@concept_hash = {}
          @@drug_hash = {}
          @@encounter_hash = {}
          @@relation_hash = {}
          
          # We need to maintain some simple buffers to handle buffered inserts
          @@buffered_patient = BufferedPatient.new
          @@buffered_person = BufferedPerson.new
          @@buffered_relation = BufferedRelationship.new
          @@buffered_patient_name = BufferedPatientName.new
          @@buffered_patient_address = BufferedPatientAddress.new
          @@buffered_patient_identifier = BufferedPatientIdentifier.new
          @@buffered_encounter = BufferedEncounter.new
          @@buffered_obs = BufferedObs.new
          @@buffered_order = BufferedOrder.new
          @@buffered_drug_order = BufferedDrugOrder.new

          # Disable keys for speed
          @@buffered_patient.disable_keys
          @@buffered_person.disable_keys
          @@buffered_relation.disable_keys
          @@buffered_patient_name.disable_keys
          @@buffered_patient_identifier.disable_keys
          @@buffered_encounter.disable_keys
          @@buffered_obs.disable_keys
          @@buffered_order.disable_keys
          @@buffered_drug_order.disable_keys
              
          # This is for displaying elapsed time, nothing else!
          @@start_time = Time.now


          if (ActiveRecord::Base.connection.select_one("SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit'")["Value"] != "2")
            puts "Set innodb_flush_log_at_trx_commit = 2? (y|n)"
            ans = STDIN.gets.strip()
            if (ans == "y") 
              ActiveRecord::Base.connection.execute("SET GLOBAL innodb_flush_log_at_trx_commit = 2")
            end
          end  
          
          if (ActiveRecord::Base.connection.select_one("SHOW VARIABLES LIKE 'innodb_support_xa'")["Value"] != "ON")
            puts "Set innodb_support_xa = 0? (y|n)"
            ans = STDIN.gets.strip()
            if (ans == "y") 
              ActiveRecord::Base.connection.execute("SET @innodb_support_xa = 0;")
            end
          end  

          @@cleared = Patient.count == 0

          self.delete_all

          if (User.find_by_username("migrate").nil?)    
            puts "Add the migration user (y|n)"
            ans = STDIN.gets.strip()
            if (ans == "y") 
              ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
              u = User.new
              u.creator = 1
              u.date_created = DateTime.now
              u.username = "migrate"
              u.password = "???????"
              u.save!

              u = User.new
              u.creator = 1
              u.date_created = DateTime.now
              u.username = "unknown"
              u.password = "???????"
              u.save!
              ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1")
            end
          end  
           
          # Set up the defaults so that the foreign keys are okay...
          User.current_user = User.find_by_username "migrate"
          Location.current_location = Location.find_by_name "Baobab Health Programming Room"         
          
          # Migrate the sites
          migrate_sites
                          
          # We don't want to look these ids up every time!
          # Look up all of the ids for concepts and types once and pass them in
          @@arv_nat_id = PatientIdentifierType.find_by_name("Arv national id").id.to_s
          @@cell_phone_id = PatientIdentifierType.find_by_name("Cell phone number").id.to_s
          @@home_phone_id = PatientIdentifierType.find_by_name("Home phone number").id.to_s
          @@legacy_nat_id = PatientIdentifierType.find_by_name("Legacy national id").id.to_s
          @@legacy_ped_id = PatientIdentifierType.find_by_name("Legacy pediatric id").id.to_s
          @@nat_id = PatientIdentifierType.find_by_name("National id").id.to_s
          @@occupation_id = PatientIdentifierType.find_by_name("Occupation").id.to_s
          @@office_phone_id = PatientIdentifierType.find_by_name("Office phone number").id.to_s
          @@other_name_id = PatientIdentifierType.find_by_name("Other name").id.to_s
          @@physical_address_id = PatientIdentifierType.find_by_name("Physical address").id.to_s
          @@birth_ta_id = PatientIdentifierType.find_by_name("Traditional authority").id.to_s
          
          sdc_name_mappings = {
            "Asymptomatic" =>                                  "Asymptomatic",
            "Persistent Genz. Lymphadenopathy" =>              "Persistent Generalised lymphadenopathy",
            "UWL < 10% of body weight" =>                      "Unintentional weight loss in the absence of concurrent illness",
            "Minor mucocutaneous manifestations" =>            "Minor mucocutaneous manifestations (seborrheic dermatitis, prurigo, fungal nail infections, recurrent oral ulcerations, angular cheilitis)",
            "Herpes Zoster in the last 5 years" =>             "Herpes zoster",
            "Recurrent upper respiratory tract infections" =>  "Recurrent upper respiratory tract infections (ie, bacterial sinusitis)",
            "Oral candidiasis" =>                              "Oral candidiasis",
            "Oral hairy leukoplakia w/ oth. systemic feas." => "Oral hairy leukoplakia",
            "Vulvo-vaginal cands w/ oth. systemic feas." =>    "Unspecified stage 3 condition", # TODO Need to add this concept as a retired concept, then scope_out around retireds in the model
            "WL > 10% of body weight" =>                       "Unintentional weight loss: more than 10% of body weight in the absence of concurrent illness",
            "Chronic diarrhoea > 1 mo" =>                      "Chronic diarrhoea for more than 1 month",
            "Prolonged fever > 1 mo" =>                        "Prolonged fever (intermittent or constant) for more than 1 month",
            "Active Pulmonary Tuberculosis(PTB)" =>            "Active Pulmonary Tuberculosis ",
            "PTB within the last year" =>                      "PTB within the past 2 years", # This is a superset, 2 > 1
            "Severe bacterial infs." =>                        "Severe bacterial infections (eg pneumonia, pyomyositis, sepsis)",                                                         
            "HIV Wasting Syndrome" =>                          "HIV wasting syndrome (weight loss more than 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)",
            "Pneumocystis carinii pneumonia" =>                "Pneumocystis carinii pneumonia",
            "Toxoplasmosis of the brain" =>                    "Toxoplasmosis of the brain",
            "Cryptosporidiosis w. diarrhoea > 1 mo" =>         "Cryptosporidiosis or Isosporiasis",
            "Isosporiasis w. diarrhoea > 1 mo" =>              "Cryptosporidiosis or Isosporiasis",
            "Cryptococcosis, Extrapulmonary" =>                "Cryptococcosis, extrapulmonary",
            "Cytomegalovirus not in liver, spleen or lymph" => "Cytomegalovirus of an organ other than liver, spleen or lymph node",
            "Herpes simplex inf., mucocutaneous > 1 mo" =>     "Herpes simplex infection, mucocutaneous for longer than  1 month or visceral",
            "Progressive multifocal leucoencephalopathy" =>    "Progressive multifocal leucoencephalopathy",
            "Dissem. endemic mycosis" =>                       "Any disseminated endemic mycosis",
            "Cands. of oesophagus, trachea and bronchus" =>    "Candidiasis of oesophagus /trachea / bronchus",
            "Atypical mycobacteriosis, dissem. or lungs" =>    "Atypical mycobacteriosis, disseminated or lung",
            "Non-typhoidal salmonella septicaemia" =>          "Unspecified stage 4 condition", # TODO Need to add this concept as a retired concept, then scope_out around retireds in the model
            "Extrapulmonary TB(EPTB)" =>                       "Extrapulmonary tuberculosis (EPTB) ",
            "Lymphoma" =>                                      "Lymphoma (cerebral or B-cell Non Hodgkin)",
            "Kaposis Sarcoma" =>                               "Kaposi's sarcoma",
            "HIV encephalopathy" =>                            "HIV encephalopathy"}
          @@sdc_queens_id_to_openmrs_id_hash = Hash.new
          ActiveRecord::Base.connection.select_all("SELECT * FROM qech.arv_stage_defining_conditions").each { |c| 
            @@sdc_queens_id_to_openmrs_id_hash[c["id"]] = Concept.find_by_name(sdc_name_mappings[c["condition"]]).id 
          }

          # Migrate the Clinicians
          puts "Migrate clinicians (safe)? (y|n)"
          ans = STDIN.gets.strip()
          if (ans == "y") 
            ActiveRecord::Base.connection.select_all("SELECT * FROM qech.Clinician").each { |clinician|   
              migrate_clinician_to_user(clinician)
            }
          end    
          
          # Hash the username|user_id
          @@user_hash = Hash.new
          User.find(:all).each { |u| @@user_hash[u.username] = u.user_id.to_s }

          # Migrate master patients
          puts "Migrate master patients? (y|n)"
          ans = STDIN.gets.strip()
          if (ans == "y") 
            migrate_all_master_patient_record_to_patient
          end     

          # Migrate arv patients
          puts "Migrate arv patients? (y|n)"
          ans = STDIN.gets.strip()
          if (ans == "y") 
            migrate_all_arv_patient_record_to_patient() #  TEMP
          end  
              
          # Handle those last few records
          @@buffered_encounter.commit
          @@buffered_obs.commit
          @@buffered_order.commit
          @@buffered_drug_order.commit
          @@buffered_patient.commit
          @@buffered_patient_identifier.commit
          @@buffered_patient_name.commit
          @@buffered_patient_address.commit
          @@buffered_person.commit
          @@buffered_relation.commit

          # Okay, turn those keys back on!
          @@buffered_relation.enable_keys
          @@buffered_encounter.enable_keys
          @@buffered_obs.enable_keys
          @@buffered_order.enable_keys
          @@buffered_drug_order.enable_keys
          @@buffered_patient.enable_keys
          @@buffered_patient_identifier.enable_keys
          @@buffered_patient_name.enable_keys
          @@buffered_patient_address.enable_keys
          @@buffered_person.enable_keys

          puts "Migration complete"
        end


        def self.migrate_clinician_to_user(clinician)

          # Feedback
          puts "Migrating Clinician #{clinician['Clinician_F_Name']} #{clinician['Clinician_L_Name']} (#{clinician['Clinician_ID']})\n" 
            
          # Try to see if this user already exists
          user = User.find_by_username(clinician["Clinician_ID"])

          # If not add the clinician as a user 
          if (user.nil?)
            user = User.new
            user.first_name = clinician["Clinician_F_Name"] 
            user.last_name = clinician["Clinician_L_Name"] 
            username = "#{clinician['Clinician_F_Name'][0..2]}#{clinician['Clinician_L_Name'][0..2]}"
            username = "#{clinician['Clinician_F_Name']}" if username.length < 6
            user.username =  
            user.password = clinician["Clinician_ID"] 
            user.date_created = DateTime.now     
            user.roles << Role.find_by_role("Clinician")

            ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
            user.save!
            ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1")
          end
                  
          # If the user is there, update the last used
          unless (user.nil? or clinician["Date_Last_Used"].nil?) 
            user_prop = UserProperty.find(:first, :conditions => ["user_id = ? AND property = ?", user.id, "Date Last Used"])       
            user_prop = UserProperty.new if user_prop.nil?
            user_prop.user_id = user.id
            user_prop.property = "Date last used"
            user_prop.property_value = clinician["Date_Last_Used"]
            user_prop.save
          end  
              
        end

        def self.migrate_all_master_patient_record_to_patient(site_id = nil, pat_id = nil)
          count = 0          
          where = ""
          where = " WHERE Site_ID = #{site_id} AND Pat_ID = #{pat_id}" unless site_id.blank? || pat_id.blank?
          # Grab all of the MasterPatientRecords into memory. This is slow, but not the
          # primary bottleneck, Loop through all of those records. You might be able to 
          # speed this up with a traditional for loop
          ActiveRecord::Base.connection.select_all("SELECT * FROM qech.MasterPatientRecord #{where}").each { |mpr|    
            
            # Migrate the patient
            migrate_master_patient_record_to_patient(mpr)
            
            count = count + 1
            if (count % 100 == 0)
              puts "Buffering... " + count.to_s  + " (" + (Time.now - @@start_time).to_s + " elapsed)"
            end
          
            if (count % 1000 == 0)
              puts "Inserting block (" + (Time.now - @@start_time).to_s + " elapsed)"
              @@buffered_patient.commit
              @@buffered_patient_identifier.commit
              @@buffered_patient_name.commit
              @@buffered_patient_address.commit
              @@buffered_person.commit
            end     
              
          }
          
        end

=begin    migrate_master_patient_record_to_patient
        - Creates a new patient record (it does not attempt
          to look up an existing patient record and merge data)
          - Adds demographic data about the patient including:
            patient.birthdate (and possibly, patient.birthdate_estimated) 
            patient.gender   
            Legacy national id (if present) 
            Legacy pediatric id (if present) 
            Birth traditional authority (if present) 
            First Name, Last Name (always added even if NULL)
            Address (always added even if NULL)  
=end      
        def self.migrate_master_patient_record_to_patient(mpr)      
        
          # The Day_Of_Birth and Month_Of_Birth are used to contain the displayed
          # birthdate, actual or estimated. If the birth day is unknown, the
          # Day_Of_Birth field contains the string "??" instead of a number. This
          # is always displayed in the application as "??" but for date
          # calculations, the Birth_Date field is used (see below). The Birth_Date
          # field always contains the "15" for an unknown date and "Jun" for an
          # unknown month,  or the actual birth date or month if available. So for
          # example, if a patient has no idea what time of year they were born and
          # an estimated year of 1981 is given, the following two fields contain
          # "??" and "???" and the Birth_Date field is assigned "15-Jun-1981".

          # In openMRS this will need to be stored as patient.birthdate with
          # patient.birthdate_estimated = 1 (treated as boolean even though the
          # data type is SMALLINT(5) in the case of an estimated date). If only 
          # day of month is unknown it gets set to 15. If month is also unknown 
          # then month gets set to July and day of month gets set to 1. With this 
          # in place we will be able to determine which component of the date was 
          # estimated, which is important.
          @@buffered_patient.birthdate_estimated = 0
          
          # If both are unknown
          if (mpr["Month_Of_Birth"] = "??") 
            mpr["Day_Of_Birth"] = "01"
            mpr["Month_Of_Birth"] = "07"
            @@buffered_patient.birthdate_estimated = 1
          # If only day is unknown
          elsif (mpr["Day_Of_Birth"] = "??")
            mpr["Day_Of_Birth"] = "15"
            @@buffered_patient.birthdate_estimated = 1
          end  
          site_id = mpr['Site_ID'] == "102" ? "102" : "101"
          @@buffered_patient.birthdate = Date.new(mpr["Year_Of_Birth"].to_i, mpr["Month_Of_Birth"].to_i,  mpr["Day_Of_Birth"].to_i)    
          @@buffered_patient.creator = @@user_hash[mpr["Reg_By"]] || @@user_hash["unknown"]
          @@buffered_patient.health_center = @@location_hash[site_id]
          @@buffered_patient.date_created = convert_date(mpr["Date_Reg"], "")
          raise "The location could not be found: #{mpr.inspect}" unless @@buffered_patient.health_center

          if (mpr["Sex"] == "M") 
            @@buffered_patient.gender = "Male" 
          else
            @@buffered_patient.gender = "Female" 
          end  
          
          # save into buffer (assigns the id)
          @@buffered_patient.save
                  
          # add a person        
          @@buffered_person.patient_id = @@buffered_patient.id
          @@buffered_person.save
                  
          # set up the identifiers        
          @@buffered_patient_identifier.patient_id = @@buffered_patient.id
          @@buffered_patient_identifier.location_id = @@buffered_patient.health_center
          @@buffered_patient_identifier.creator = @@buffered_patient.creator
          @@buffered_patient_identifier.date_created = @@buffered_patient.date_created

          # Add in the identifiers and traditional authority
          unless (mpr["Pat_ID"].nil?)
            @@buffered_patient_identifier.identifier = mpr["Site_ID"] + ("%06d" % mpr["Pat_ID"])
            @@buffered_patient_identifier.identifier_type = @@legacy_nat_id
            @@buffered_patient_identifier.save            
          end  

          unless (mpr["Legacy_Pat_Num"].nil?)
            @@buffered_patient_identifier.identifier = mpr["Legacy_Pat_Num"]
            @@buffered_patient_identifier.identifier_type = @@legacy_ped_id
            @@buffered_patient_identifier.save            
          end  
          
          unless (mpr["Birth_TA"].nil?)
            @@buffered_patient_identifier.identifier = mpr["Birth_TA"].split(" / ")[1]
            @@buffered_patient_identifier.identifier_type = @@birth_ta_id
            @@buffered_patient_identifier.save            
          end  
              
          # Add in first and last name
          @@buffered_patient_name.patient_id = @@buffered_patient.id 
          @@buffered_patient_name.given_name = mpr["First_Name"]
          @@buffered_patient_name.family_name = mpr["Last_Name"]
          @@buffered_patient_name.creator = @@buffered_patient.creator
          @@buffered_patient_name.date_created = @@buffered_patient.date_created
          @@buffered_patient_name.save            

          # Add the address
          @@buffered_patient_address.patient_id = @@buffered_patient.id 
          @@buffered_patient_address.address1 = mpr["Address"]
          @@buffered_patient_address.patient_id = @@buffered_patient 
          @@buffered_patient_address.creator = @@buffered_patient.creator
          @@buffered_patient_address.date_created = @@buffered_patient.date_created
          @@buffered_patient_address.save            
        end
        
        
        def self.migrate_all_arv_patient_record_to_patient(ids = nil)
          puts "Migrating ARV patients"
          self.delete_ecounters_obs_demographics          
          count = 0
           
          # Grab all of the arv_patient Records into memory. This is slow, but not the
          # primary bottleneck, Loop through all of those records. You might be able to 
          # speed this up with a traditional for loop
          ids = []
          where = ""
          where = "WHERE id IN (#{ids.join(',')})" unless ids.blank?
          
          # TEMP!!!!
          # ids = [5125, 6653]
          # where = "WHERE id IN (#{ids.join(',')}) or (arv_start_date >= '2007-03-01' and arv_start_date < '2007-08-01')" unless ids.blank?

          ActiveRecord::Base.connection.select_all("SELECT * FROM qech.arv_patients #{where}").each { |arv_patient|    
            
            # Migrate the patient
            migrate_arv_patient_record_to_patient(arv_patient) if count > ENV['OFFSET_ARV'].to_i && (ENV['ENDPOINT_ARV'].to_i == -1 || count <= ENV['ENDPOINT_ARV'].to_i)
            
            count = count + 1
            if (count % 1 == 0)
              puts "Buffering... " + count.to_s  + " (" + (Time.now - @@start_time).to_s + " elapsed)"
            end
          
            if (count % ENV['OFFSET_INSERT'].to_i == 0 && count > ENV['OFFSET_ARV'].to_i && (ENV['ENDPOINT_ARV'].to_i == -1 || count <= ENV['ENDPOINT_ARV'].to_i))
              puts "Inserting... " + count.to_s  + " (" + (Time.now - @@start_time).to_s + " elapsed)"
              begin
                @@buffered_patient.commit
                @@buffered_person.commit
                @@buffered_relation.commit
                @@buffered_patient_name.commit
                @@buffered_patient_identifier.commit
                @@buffered_encounter.commit
                @@buffered_obs.commit
                @@buffered_order.commit
                @@buffered_drug_order.commit
              rescue Exception => e
                raise "#{arv_patient.inspect} #{e}"
              end  
            end     
          }
        end


=begin  migrate_arv_patient_record_to_patient
        Takes the arv_patient record and attempts to add the appropriate
        demographics and identifiers, create encounters, add observations
        
        Patient dead flag and death_date is set if the patient has died. 
        Cause of death is "Unknown"
=end
        def self.migrate_arv_patient_record_to_patient(arv_patient)

          user_id = @@user_hash[arv_patient["registered_by"]] || @@user_hash["unknown"]
          location_id = @@location_hash[arv_patient['site_id']]
          raise "The location could not be found: #{arv_patient['site_id']}" unless location_id
          
          
          # This is a real date, don't try to convert it!
          date_created = Date.parse(arv_patient["registration_date"])
          
          # In the QECH data model, patients are unique by site and patient id
          # So when we attempt to retrieve them from openmrs, we must use the 
          # combination of location and patient_identifier
          pi = PatientIdentifier.find(:first, :conditions => ["identifier_type = ? AND identifier = ? AND location_id = ?", @@legacy_nat_id, arv_patient["site_id"] + ("%06d" % arv_patient["pat_id"]), location_id])
          if (pi.nil?) 
            migrate_all_master_patient_record_to_patient(arv_patient["site_id"], arv_patient["pat_id"])            
            @@buffered_patient.commit
            @@buffered_patient_identifier.commit
            @@buffered_patient_name.commit
            @@buffered_patient_address.commit
            @@buffered_person.commit
            pi = PatientIdentifier.find(:first, :conditions => ["identifier_type = ? AND identifier = ? AND location_id = ?", @@legacy_nat_id, arv_patient["site_id"] + ("%06d" % arv_patient["pat_id"]), location_id])
          end
          puts "Could not find person record for #{arv_patient["site_id"] + ("%06d" % arv_patient["pat_id"])}" && return if pi.nil?
          
          # We need that patient... (for the birthdate of course, and in case the patient died)
          pat = Patient.find(pi.patient_id, :include => :people)      
                  
          # Patient Death Date #######################################################

          # Death Date
          unless (arv_patient["death_date"] == "0000-00-00 00:00:00")
             # There will be an outcome status for the visit when this occurred
             # The date_changed may be off here, it is unintuitive
             # We save it for now
             pat.dead = 1
             pat.death_date = Date.parse(arv_patient["death_date"])
             pat.cause_of_death = "Unknown"
             pat.changed_by = user_id
             pat.date_changed = date_created
             pat.save
          end
          
          # Patient Guardian #########################################################
          unless (arv_patient["guardian_first_name"].blank?)

            @@buffered_patient.birthdate_estimated = 0
            @@buffered_patient.birthdate = nil
            @@buffered_patient.creator = user_id
            @@buffered_patient.health_center = location_id
            @@buffered_patient.date_created = date_created
            @@buffered_patient.gender = "" 
            @@buffered_patient.save

            @@buffered_patient_name.patient_id = @@buffered_patient.id 
            @@buffered_patient_name.given_name = arv_patient["guardian_first_name"]
            @@buffered_patient_name.family_name = arv_patient["guardian_last_name"]
            @@buffered_patient_name.creator = @@buffered_patient.creator
            @@buffered_patient_name.date_created = @@buffered_patient.date_created
            @@buffered_patient_name.save            

            @@buffered_person.patient_id = @@buffered_patient.id
            @@buffered_person.save

            @@buffered_relation.relative_id = @@buffered_person.id
            @@buffered_relation.person_id = pat.people.first.id
            @@buffered_relation.relationship = relation("ART Guardian")
            @@buffered_relation.date_created = date_created
            @@buffered_relation.creator = user_id
            @@buffered_relation.save
          end  

          #  Demographics ############################################################
          @@buffered_patient_identifier.patient_id = pat.id
          @@buffered_patient_identifier.location_id = 703
          @@buffered_patient_identifier.creator = user_id
          @@buffered_patient_identifier.date_created = date_created
        
          unless (arv_patient["patient_arv_number"].nil? ||
["",
"QEC108",
"QEC1958",
"QEC1966",
"QEC2055",
"QEC2327",
"QEC2664",
"QEC286",
"QEC2906",
"QEC3106",
"QEC3219",
"QEC3422",
"QEC3660",
"QEC3720",
"QEC3722",
"QEC3725",
"QEC3738",
"QEC430",
"QEC438",
"QEC557",
"QEC5577",
"QEC6426",
"QEC926"].include?(arv_patient["patient_arv_number"]) )
            @@buffered_patient_identifier.identifier = arv_patient["patient_arv_number"]
            @@buffered_patient_identifier.identifier_type = @@arv_nat_id
            @@buffered_patient_identifier.save
          end  

          unless (arv_patient["physical_address"].nil?)
            @@buffered_patient_identifier.identifier = arv_patient["physical_address"]
            @@buffered_patient_identifier.identifier_type = @@physical_address_id
            @@buffered_patient_identifier.save
          end  

          unless (arv_patient["home_phone"].nil?)
            @@buffered_patient_identifier.identifier = arv_patient["home_phone"]
            @@buffered_patient_identifier.identifier_type = @@home_phone_id
            @@buffered_patient_identifier.save
          end  

          unless (arv_patient["work_phone"].nil?)
            @@buffered_patient_identifier.identifier = arv_patient["work_phone"]
            @@buffered_patient_identifier.identifier_type = @@office_phone_id
            @@buffered_patient_identifier.save
          end  

          unless (arv_patient["cell_phone"].nil?)
            @@buffered_patient_identifier.identifier = arv_patient["cell_phone"]
            @@buffered_patient_identifier.identifier_type = @@cell_phone_id
            @@buffered_patient_identifier.save
          end  

          unless (arv_patient["occupation"].nil?)
            occ = arv_patient["occupation"]
            occ = "Student" if occ == "Student/School"
            occ = "Other" if ["Unknown", "N/A", "NULL", nil].include? occ 
            @@buffered_patient_identifier.identifier = occ
            @@buffered_patient_identifier.identifier_type = @@occupation_id
            @@buffered_patient_identifier.save
          end  

          # middle_name (*not* patient_name.middle_name)
          unless (arv_patient["middle_name"].nil?)
            @@buffered_patient_identifier.identifier = arv_patient["middle_name"]
            @@buffered_patient_identifier.identifier_type = @@other_name_id
            @@buffered_patient_identifier.save
          end  
          
          pat.add_programs([program("HIV")])
          
          # HIV First Visit Encounter ################################################
          @@buffered_encounter.encounter_type = encounter("HIV First visit")
          @@buffered_encounter.patient_id = pat.id
          @@buffered_encounter.provider_id = user_id
          @@buffered_encounter.location_id = location_id
          @@buffered_encounter.encounter_datetime = date_created
          @@buffered_encounter.creator = user_id
          @@buffered_encounter.date_created = date_created
          @@buffered_encounter.save
          
          @@buffered_obs.patient_id = pat.id
          @@buffered_obs.encounter_id = @@buffered_encounter.id
          @@buffered_obs.obs_datetime = date_created
          @@buffered_obs.location_id = location_id
          @@buffered_obs.creator = user_id
          @@buffered_obs.date_created = date_created
          
          # Agrees to Followup, there are no "Unknown" values in the database
          @@buffered_obs.concept_id = concept("Agrees to followup")
          @@buffered_obs.value_coded = (arv_patient["agree_to_contact"] == "Y") ? concept("Yes") : concept("No")
          @@buffered_obs.value_datetime = nil
          @@buffered_obs.value_numeric = nil
          @@buffered_obs.save

          # HIV test date
          unless (arv_patient["hiv_test_date"] == "0000-00-00 00:00:00")
            @@buffered_obs.concept_id = concept("Date of first positive HIV test")
            @@buffered_obs.value_coded = nil
            @@buffered_obs.value_datetime = arv_patient["hiv_test_date"]
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.save
          end    

          # HIV test location
          unless (arv_patient['hiv_test_place'].nil?)
            testing_center = @@testing_centers_hash[arv_patient['hiv_test_place']] || @@testing_centers_hash['Unknown']
            @@buffered_obs.concept_id = concept("Location of first positive HIV test")
            @@buffered_obs.value_coded = nil
            @@buffered_obs.value_datetime = nil
            @@buffered_obs.value_numeric = testing_center
            @@buffered_obs.save
          end    
          
          # Height
          unless (arv_patient["initial_height"].nil?)
            @@buffered_obs.concept_id = concept("Height")
            @@buffered_obs.value_coded = nil
            @@buffered_obs.value_datetime = nil
            @@buffered_obs.value_numeric = arv_patient["initial_height"]
            @@buffered_obs.save
          end    

          # Weight
          unless (arv_patient["initial_weight"].nil?)
            @@buffered_obs.concept_id = concept("Weight")
            @@buffered_obs.value_coded = nil
            @@buffered_obs.value_datetime = nil
            @@buffered_obs.value_numeric = arv_patient["initial_weight"]
            @@buffered_obs.save
          end    
          
          # arv start date
          unless (arv_patient["arv_start_date"].nil?)
            begin
              time = Time.parse(arv_patient["arv_start_date"])
            rescue Exception => e
              puts "Error converting time for ARV start date '#{arv_patient["arv_start_date"]}': #{e}"
              time = nil
            end  
            @@buffered_obs.concept_id = concept("Date of ART initiation")
            @@buffered_obs.value_coded = nil
            @@buffered_obs.value_datetime = time
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.save
          end    

          # transfers
          @@buffered_obs.concept_id = concept("Ever registered at ART clinic")
          @@buffered_obs.value_coded = concept(arv_patient["transfer_in"] == "Yes" ? "Yes" : "No")
          @@buffered_obs.value_datetime = nil
          @@buffered_obs.value_numeric = nil
          @@buffered_obs.save

          @@buffered_obs.concept_id = concept("Ever received ART")
          @@buffered_obs.value_coded = concept(arv_patient["transfer_in"] == "Yes" ? "Yes" : "No")
          @@buffered_obs.value_datetime = nil
          @@buffered_obs.value_numeric = nil
          @@buffered_obs.save

          @@buffered_obs.concept_id = concept("Has transfer letter")
          @@buffered_obs.value_coded = concept(arv_patient["transfer_in"] == "Yes" ? "Yes" : "No")
          @@buffered_obs.value_datetime = nil
          @@buffered_obs.value_numeric = nil
          @@buffered_obs.save

          ########################### HIV Staging ###################################
          @@buffered_encounter.encounter_type = encounter("HIV Staging")    
          @@buffered_encounter.save
          @@buffered_obs.encounter_id = @@buffered_encounter.id
              
          reason_arv_started = nil
          
          case arv_patient["reason_for_starting_arv"]
            when "WHO Stage III"            
              reason_arv_started = concept("Unspecified stage 3 condition")
              @@buffered_obs.value_coded = concept("Yes")
            when "WHO Stage IV"   
              reason_arv_started = concept("Unspecified stage 4 condition")
              @@buffered_obs.value_coded = concept("Yes")
            when "Stage I"   
              reason_arv_started = concept("Unspecified stage 1 condition")
              @@buffered_obs.value_coded = concept("Yes")
            when "CD4 < 200", "CD4<200"
              reason_arv_started = concept("CD4 count")
              @@buffered_obs.value_coded = nil
              @@buffered_obs.value_numeric = 200
              @@buffered_obs.value_modifier = "<"
            else 
              puts "Unknown reason for starting '#{arv_patient["reason_for_starting_arv"]}', classified as stage 3" 
              reason_arv_started = concept("Unspecified stage 3 condition")
              @@buffered_obs.value_coded = concept("Yes")
          end
          unless (reason_arv_started.blank?)
            @@buffered_obs.obs_datetime = date_created
            @@buffered_obs.date_created = date_created
            @@buffered_obs.concept_id = reason_arv_started
            @@buffered_obs.value_datetime = nil
            @@buffered_obs.save
            # reset these two
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.value_modifier = nil
          end  

          sdcs = ActiveRecord::Base.connection.select_all("SELECT * FROM qech.arv_patient_stage_defining_conditions WHERE arv_patients_id = #{arv_patient['id']}")   
          sdcs.each { |sdc|    
            sdc_concept = @@sdc_queens_id_to_openmrs_id_hash[sdc["arv_stage_defining_conditions_id"]]
            unless (sdc_concept.blank? || sdc["arv_stage_defining_conditions_id"].blank?)
              @@buffered_obs.obs_datetime = date_created
              @@buffered_obs.date_created = date_created
              @@buffered_obs.concept_id = sdc_concept
              @@buffered_obs.value_coded = concept("Yes")      
              @@buffered_obs.value_datetime = nil
              @@buffered_obs.value_numeric = nil
              @@buffered_obs.save
            else
              puts "Unknown stage defining condition '#{sdc_concept}'/'#{sdc["arv_stage_defining_conditions_id"]}'"
            end   
          }
          
          # ARV Visits ###############################################################      
          last_visit = nil
          last_drugs = nil

          visits = ActiveRecord::Base.connection.select_all("SELECT * FROM qech.arv_visits WHERE arv_patients_id = #{arv_patient['id']} ORDER BY visit_date")   
          visits.each { |arv_visit|    
          
            user_id = @@user_hash[arv_visit["user_id"]] || @@user_hash["unknown"]
            puts "User not found: " << arv_visit["user_id"] if user_id.nil?

            # *** HIV Reception ***
            @@buffered_encounter.encounter_type = encounter("HIV Reception")    
            @@buffered_encounter.provider_id = user_id
            @@buffered_encounter.location_id = location_id
            @@buffered_encounter.encounter_datetime = arv_visit["visit_date"]
            @@buffered_encounter.creator = user_id
            @@buffered_encounter.date_created = arv_visit["visit_date"]
            @@buffered_encounter.save
           
            @@buffered_obs.patient_id = pat.id
            @@buffered_obs.encounter_id = @@buffered_encounter.id
            @@buffered_obs.obs_datetime = arv_visit["visit_date"]
            @@buffered_obs.location_id = location_id
            @@buffered_obs.creator = user_id
            @@buffered_obs.date_created = arv_visit["visit_date"]
            @@buffered_obs.concept_id = concept("Guardian present")
            @@buffered_obs.value_coded = concept(arv_visit["arv_recipient"] == "Guardian" ? "Yes" : "No")
            @@buffered_obs.value_datetime = nil
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.save

            @@buffered_obs.concept_id = concept("Patient present")
            @@buffered_obs.value_coded = concept(arv_visit["arv_recipient"] != "Guardian" ? "Yes" : "No")
            @@buffered_obs.save
             
            # *** Height/Weight ***
            current_weight = nil
            unless (arv_visit["weight"].blank?)
              @@buffered_encounter.encounter_type = encounter("Height/Weight")    
              @@buffered_encounter.save
              @@buffered_obs.encounter_id = @@buffered_encounter.id
              
              current_weight = arv_visit["weight"].to_f
              @@buffered_obs.concept_id = concept("Weight")
              @@buffered_obs.value_coded = nil
              @@buffered_obs.value_numeric = current_weight
              @@buffered_obs.save
            end  

            # *** ART Visit ***
            @@buffered_encounter.encounter_type = encounter("ART Visit")    
            @@buffered_encounter.save
            @@buffered_obs.encounter_id = @@buffered_encounter.id
            
            @@buffered_obs.concept_id = concept("Is able to walk unaided")
            case arv_visit["is_ambulatory"]
              when "Amb"
                @@buffered_obs.value_coded = concept("Yes")
              when "Bed"
                @@buffered_obs.value_coded = concept("No")
              else
                @@buffered_obs.value_coded = concept("Unknown")
            end
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.save
            
            @@buffered_obs.concept_id = concept("Is at work/school")
            case arv_visit["is_working"]
              when "Yes"
                @@buffered_obs.value_coded = concept("Yes")
              when "No"
                @@buffered_obs.value_coded = concept("No")
              else
                @@buffered_obs.value_coded = concept("Unknown")
            end
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.save

            # side_effects: Lactic acidosis, Lipodystrophy, Anaemia not used
            side_effects = arv_visit["side_effects"]

            @@buffered_obs.concept_id = concept("Peripheral neuropathy")
            @@buffered_obs.value_coded = concept(side_effects.include?("PN") ? "Yes" : "No")
            @@buffered_obs.save

            @@buffered_obs.concept_id = concept("Hepatitis")
            @@buffered_obs.value_coded = concept(side_effects.include?("HP") ? "Yes" : "No")
            @@buffered_obs.save

            @@buffered_obs.concept_id = concept("Skin rash")
            @@buffered_obs.value_coded = concept(side_effects.include?("SK") ? "Yes" : "No")
            @@buffered_obs.save

            unless (last_drugs.nil?)
              last_drugs.each { |drug_s|
                @@buffered_obs.concept_id = concept("Whole tablets remaining and brought to clinic")
                @@buffered_obs.value_coded = nil
                @@buffered_obs.value_drug = drug(drug_s) 
                @@buffered_obs.value_numeric = arv_visit["pill_count"].to_i
                @@buffered_obs.save
              }
              # Reset
              @@buffered_obs.value_drug = nil
            end

            # For now we are assuming everyone is getting the standard dosage and 1 month supply
            drugs = convert_arv_drug(arv_visit['arv_arvs_id'], current_weight, pat.age(date_created))
            drugs.each { |drug_s|
              @@buffered_obs.concept_id = concept("Prescribed Dose")
              @@buffered_obs.value_coded = nil
              @@buffered_obs.value_drug = drug(drug_s)
              @@buffered_obs.value_numeric = 1
              @@buffered_obs.value_text = "Morning"
              @@buffered_obs.save
            }      
            @@buffered_obs.concept_id = concept("Prescription Time Period")
            @@buffered_obs.value_coded = nil
            @@buffered_obs.value_drug = nil
            @@buffered_obs.value_numeric = nil
            @@buffered_obs.value_text = "1 month"
            @@buffered_obs.save

            @@buffered_obs.value_text = nil

            # *** Give them drugs ***
            @@buffered_encounter.encounter_type = encounter("Give drugs")    
            @@buffered_encounter.save

            @@buffered_order.encounter_id = @@buffered_encounter.id
            @@buffered_order.concept_id = 0
            @@buffered_order.voided = 0
            @@buffered_order.discontinued = 0
            @@buffered_order.order_type_id = 1
            @@buffered_order.orderer = user_id
            @@buffered_order.creator = user_id
            @@buffered_order.date_created = arv_visit["visit_date"]
            @@buffered_order.save

            @@buffered_drug_order.order_id = @@buffered_order.id
            @@buffered_drug_order.prn = 0
            @@buffered_drug_order.complex = 0
            @@buffered_drug_order.units = nil

            drugs.each { |drug_s|
              @@buffered_drug_order.quantity = 60 # TODO test weird drug regimens against this
              @@buffered_drug_order.drug_inventory_id = drug(drug_s)
              @@buffered_drug_order.save
            }      
                  
            # *** Update outcome ***
            outcome_status = nil
            case arv_visit["outcome_status"]
              when "Transfer Out"   
                outcome_status = concept("Transfer Out(With Transfer Note)")
              when "Stop"          
                outcome_status = concept("ART Stop")
              when "Died"
                outcome_status = concept("Died")
            end

            if outcome_status
              @@buffered_encounter.encounter_type = encounter("Update outcome")    
              @@buffered_encounter.save
              @@buffered_obs.encounter_id = @@buffered_encounter.id

              @@buffered_obs.concept_id = concept("Outcome")
              @@buffered_obs.value_coded = outcome_status
              @@buffered_obs.value_datetime = nil
              @@buffered_obs.value_numeric = nil
              @@buffered_obs.save
            end  
            
            last_visit = arv_visit
            last_drugs = drugs
            
          } # end of visits loop


        end
        
        def self.migrate_sites
          @@location_hash = {}
          ActiveRecord::Base.connection.select_all("SELECT SiteID, Description FROM qech.Site").each { |r| 
            site_id = r["SiteID"] == "102" ? "102" : "101"      
            location = Location.find(:first, :conditions => ["name = ?", r["Description"]]) 
            @@location_hash[r["SiteID"]] = location.id
          }
          location_names = {
           "MACRO" => "MACRO Blantyre", 
           "Lepra VCT" => "Lepra", 
           "Lepra Clinic" => "Lepra", 
           "BAH" => "MACRO Blantyre", 
           "Tiyanjane" => "Tiyanjane", 
           "Napham" => "Napham", 
           "College of Medicine" => "College of Medicine", 
           "QECH" => "Queen Elizabeth Central Hospital", 
           "Lighthouse" => "Lighthouse HTC", 
           "Mwaiwathu" => "Mwaiwathu", 
           "John Hopkins" => "John Hopkins",
           "Unknown" => "Unknown"}
          @@testing_centers_hash = {} 
          location_names.each { |k,v|
            @@testing_centers_hash[k] = Location.find(:first, :conditions => ["name = ?", v]).id
          } 
        end
        
        def self.program(name) 
          @@program_hash[name] ||= Program.find_by_name(name) # not the id, the actual object
        rescue
          raise "Error loading program '#{name}'"
        end

        def self.concept(name) 
          @@concept_hash[name] ||= Concept.find_by_name(name).id
        rescue
          raise "Error loading concept '#{name}'"
        end

        def self.drug(name) 
          @@drug_hash[name] ||= Drug.find_by_name(name).id
        end
        
        def self.encounter(name) 
          @@encounter_hash[name] ||= EncounterType.find_by_name(name).id
        end
        
        def self.relation(name) 
          @@relation_hash[name] ||= RelationshipType.find_by_name(name).id
        end
        
        def self.convert_arv_drug(arv_id, current_weight, age)
          # The id was off by one, lets fix that here  
          arv_id = arv_id.to_i + 1 
          current_weight ||= 59
          age ||= 15
          drugs = []
          
          # 1 | Triomune
          # 5 | Unknown            
          if ([1,5].include? arv_id)
            drugs << "Stavudine 30 Lamivudine 150 Nevirapine 200" if current_weight < 60
            drugs << "Stavudine 40 Lamivudine 150 Nevirapine 200" if current_weight >= 60
          end
        
          # 6 | Triomune 30        
          if (arv_id == 6)
            drugs << "Stavudine 30 Lamivudine 150 Nevirapine 200"
          end

          # 7 | Triomune 40        
          if (arv_id == 7)            
            drugs << "Stavudine 40 Lamivudine 150 Nevirapine 200"
          end

          # 2 | d4T/3TC/Efavirenz 
          if (arv_id == 2) 
            drugs << "Efavirenz 600"
            drugs << "Stavudine 30 Lamivudine 150" if current_weight < 60
            drugs << "Stavudine 40 Lamivudine 150" if current_weight >= 60
          end

          # 3 | AZT/3TC/NVP        
          if (arv_id == 3) 
            drugs << "Zidovudine 300 Lamivudine 150"
            drugs << "Nevirapine 200"
          end
       
           # 4 | Kaletra (AZT/3TC [Lopinavir/ Ritonavir]
          if (arv_id == 4)       
            if (age > 14)
              drugs << "Tenofovir 300"
              drugs << "Zidovudine 300 Lamivudine 150"
              drugs << "Lopinavir 133 Ritonavir 33"
            else      
              # If they are children on switch
              drugs << "Abacavir 300"
              drugs << "Didanosine 125" if current_weight < 50
              drugs << "Didanosine 200" if current_weight >= 45
              drugs << "Lopinavir 133 Ritonavir 33"
            end  
          end    
          drugs
        end

        # Convert a 12-JUL-2005 date to a Ruby DateTime
        # Yes, I know this function is longer than it could be, but it also faster
        # Than a Hash by 50% in some cases, so it is what it is
        def self.convert_date(old_date, old_time)
          old_day = old_date.slice(0, 2)
          old_month = old_date.slice(3, 3)
          old_year = old_date.slice(7, 4)
          case old_month
            when "JAN"
              Time::parse "#{old_year}-01-#{old_day}T#{old_time}"
            when "FEB"
              Time::parse "#{old_year}-02-#{old_day}T#{old_time}"
            when "MAR"
              Time::parse "#{old_year}-03-#{old_day}T#{old_time}"
            when "APR"
              Time::parse "#{old_year}-04-#{old_day}T#{old_time}"
            when "MAY"
              Time::parse "#{old_year}-05-#{old_day}T#{old_time}"
            when "JUN"
              Time::parse "#{old_year}-06-#{old_day}T#{old_time}"
            when "JUL"
              Time::parse "#{old_year}-07-#{old_day}T#{old_time}"
            when "AUG"
              Time::parse "#{old_year}-08-#{old_day}T#{old_time}"
            when "SEP"
              Time::parse "#{old_year}-09-#{old_day}T#{old_time}"
            when "OCT"
              Time::parse "#{old_year}-10-#{old_day}T#{old_time}"
            when "NOV"
              Time::parse "#{old_year}-11-#{old_day}T#{old_time}"
            when "DEC"
              Time::parse "#{old_year}-12-#{old_day}T#{old_time}"
            else  
              raise "Invalid date for conversion: " + old_date + "T" + old_time
          end           
        end
        
        def self.delete_all  
          unless (@@cleared && false)
            puts "Delete Patient and Encounter Information? (y|n)"
            ans = STDIN.gets.strip()
            if (ans == "y") 
              ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
              puts "  Deleting patient identifiers"
              ActiveRecord::Base.connection.execute("DELETE FROM patient_identifier")
              puts "  Deleting patient names"
              ActiveRecord::Base.connection.execute("DELETE FROM patient_name")
              puts "  Deleting patient addresses"
              ActiveRecord::Base.connection.execute("DELETE FROM patient_address")
              puts "  Deleting patient relationships"
              ActiveRecord::Base.connection.execute("DELETE FROM relationship")
              puts "  Deleting persons"
              ActiveRecord::Base.connection.execute("DELETE FROM person")
              puts "  Deleting observations"
              ActiveRecord::Base.connection.execute("DELETE FROM obs")    
              puts "  Deleting drug order"
              ActiveRecord::Base.connection.execute("DELETE FROM drug_order")            
              puts "  Deleting orders"
              ActiveRecord::Base.connection.execute("DELETE FROM orders")    
              puts "  Deleting encounters"
              ActiveRecord::Base.connection.execute("DELETE FROM encounter")    
              puts "  Deleting patient_programs"
              ActiveRecord::Base.connection.execute("DELETE FROM patient_program")
              puts "  Deleting patients"
              ActiveRecord::Base.connection.execute("DELETE FROM patient")
              ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1")
              @@cleared = true
            end
          end    
        end
        
        def self.delete_ecounters_obs_demographics
          unless (@@cleared)
            puts "Delete only the arv demographics, encounters and observations? (y|n)"
            ans = STDIN.gets.strip()
            if (ans == "y") 
              puts "  Deleting patient identifiers"
              ActiveRecord::Base.connection.execute("DELETE FROM patient_identifier" + \
                " WHERE identifier_type = #{@@arv_nat_id}" + \
                "  OR identifier_type = #{@@physical_address_id}" + \
                "  OR identifier_type = #{@@home_phone_id}" + \
                "  OR identifier_type = #{@@office_phone_id}" + \
                "  OR identifier_type = #{@@cell_phone_id}" + \
                "  OR identifier_type = #{@@occupation_id}" + \
                "  OR identifier_type = #{@@other_name_id}")
              puts "  Deleting observations"
              ActiveRecord::Base.connection.execute("DELETE FROM obs")    
              puts "  Deleting drug order"
              ActiveRecord::Base.connection.execute("DELETE FROM drug_order")            
              puts "  Deleting orders"
              ActiveRecord::Base.connection.execute("DELETE FROM orders")    
              puts "  Deleting encounters"
              ActiveRecord::Base.connection.execute("DELETE FROM encounter")            
            end
          end    
        end
      end  
      
      puts "Preparing migration"
      Qech::migrate
    end
  end
end     
      
