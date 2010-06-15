
def de_identification
  require 'faker'
  count = 0 
ActiveRecord::Base.connection.execute <<EOF
SET foreign_key_checks = 0;
EOF
=begin
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM users where user_id > 1;
EOF
=end

  rod_id = Patient.find(:last).patient_id + 1

  Patient.find(:all).each do |patient|
    patient.birthplace  = Faker::Address.city
    patient.save

    patient.patient_names.each{|patient_name|
      patient_name.given_name = Faker::Name.first_name if patient_name.given_name
      patient_name.family_name = Faker::Name.last_name if patient_name.family_name
      patient_name.save
    } rescue nil
   
    patient.patient_addresses.each{|patient_address|
      patient_address.city_village = Faker::Address.city_prefix
      patient_address.save
    } rescue nil
   
    patient.patient_identifiers.each do |patient_identifier|
      date_created  = patient_identifier.date_created.strftime("%Y-%m-%d %H:%M:%S")
      if patient_identifier.identifier_type == 2 
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{Faker::Name.first_name}"
WHERE patient_id=#{patient.id} AND identifier_type=2 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type == 1 
        national_id = PatientIdentifier.to_base(patient_identifier.identifier.gsub('P','')) rescue nil
        unless national_id.blank?
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{national_id}" 
WHERE patient_id=#{patient.id} AND identifier_type=1 AND date_created='#{date_created}';
EOF
        end
      elsif patient_identifier.identifier_type == 18 
        arv_number = patient_identifier.identifier.match(/[0-9]+/)[0].to_i + 1 rescue nil
        unless arv_number.blank?
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="XXX #{arv_number}" 
WHERE patient_id=#{patient.id} AND identifier_type=18 AND date_created='#{date_created}';
EOF
        end
      elsif patient_identifier.identifier_type == 5 
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{Faker::PhoneNumber.phone_number}" 
WHERE patient_id=#{patient.id} AND identifier_type=5 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  6 
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{Faker::Address.street_address}"
WHERE patient_id=#{patient.id} AND identifier_type=6 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  9
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{Faker::Company.name}" 
WHERE patient_id=#{patient.id} AND identifier_type=9 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  11
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{Faker::PhoneNumber.phone_number}" 
WHERE patient_id=#{patient.id} AND identifier_type=11 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  12 
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="#{Faker::PhoneNumber.phone_number}" 
WHERE patient_id=#{patient.id} AND identifier_type=12 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  10
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="FN1 #{patient.id}" 
WHERE patient_id=#{patient.id} AND identifier_type=10 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  19
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="FN2 #{patient.id}" 
WHERE patient_id=#{patient.id} AND identifier_type=19 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  20
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="XLX #{patient.id}" 
WHERE patient_id=#{patient.id} AND identifier_type=20 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  16
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="ALK #{patient.id}" 
WHERE patient_id=#{patient.id} AND identifier_type=16 AND date_created='#{date_created}';
EOF
      elsif patient_identifier.identifier_type ==  17
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier set identifier="PLX #{patient.id}" 
WHERE patient_id=#{patient.id} AND identifier_type=17 AND date_created='#{date_created}';
EOF
      end
    end

#updating patient_id in the following tables
ActiveRecord::Base.connection.execute <<EOF
UPDATE person SET patient_id=#{rod_id} WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE relationship SET person_id=#{rod_id} WHERE person_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_address SET patient_id=#{rod_id} 
WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_name SET patient_id=#{rod_id} 
WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_identifier SET patient_id=#{rod_id} 
WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE patient SET patient_id=#{rod_id} 
WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_program SET patient_id=#{rod_id} 
WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE encounter SET patient_id=#{rod_id} 
WHERE patient_id=#{patient.id};
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET patient_id=#{rod_id}  
WHERE patient_id=#{patient.id};
EOF

    count+=1
    rod_id+=1
    puts "#{count} <<<<<<<<<<<<<<<<<<<<<<"
  end

end


 def update_creator
 require 'faker'

ActiveRecord::Base.connection.execute <<EOF
SET foreign_key_checks = 0;
EOF

tables = []
tables << "patient_start_dates"
tables << "patient_registration_dates"
tables << "patient_adherence_dates"
tables << "patient_adherence_rates"
tables << "tmp_patient_dispensations_and_prescriptions"
tables << "patient_prescription_totals"
tables << "patient_whole_tablets_remaining_and_brought"
tables << "patient_historical_outcomes"
tables << "patient_historical_regimens"

    tables.each do |table_name|
      puts "deleting #{table_name} <<<<<<<<<<<"
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM #{table_name};
EOF
    end



    ["patient_address","patient_identifier","obs","relationship"].map{|table_name|
      puts "updating #{table_name} table <<<<<<<<<<<"
ActiveRecord::Base.connection.execute <<EOF
UPDATE #{table_name} SET creator = (creator + 700);
EOF

ActiveRecord::Base.connection.execute <<EOF
UPDATE #{table_name} SET voided_by = (voided_by + 700) WHERE voided_by IS NOT NULL;
EOF
    }

    puts "updating orders table <<<<<<<<<<<"
    Order.find(:all).each do |order| 
      order.orderer+= 700
      order.creator+= 700
      order.voided_by+= 700 unless order.voided_by.blank?
      order.save  
    end

    puts "updating patient_name table <<<<<<<<<<<"
    PatientName.find(:all).each{|table|
      table.creator+= 700
      table.changed_by+= 700
      table.voided_by+= 700 unless table.voided_by.blank?
      table.save
    }

    puts "updating patient table <<<<<<<<<<<"
    Patient.find(:all).each{|table|
      table.creator+= 700
      table.changed_by+= 700
      table.voided_by+= 700 unless table.voided_by.blank?
      table.save
    }

    puts "updating patient_program  table <<<<<<<<<<<"
    PatientProgram.find(:all).each{|table|
      table.creator+= 700
      table.changed_by+= 700
      table.voided_by+= 700 unless table.voided_by.blank?
      table.save
    }

    puts "updating encounter table <<<<<<<<<<<"
    Encounter.find(:all).each do |encounter|
      encounter.creator+= 700
      encounter.provider_id+= 700
      encounter.save
    end

=begin
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM users where user_id > 1;
EOF
=end

ActiveRecord::Base.connection.execute <<EOF
UPDATE users SET user_id = (user_id + 700);
EOF

    User.find(:all).map{|user|
      user.username = Faker::Internet.user_name
      user.first_name = Faker::Name.first_name if user.first_name
      user.last_name = Faker::Name.last_name if user.last_name
      user.middle_name = Faker::Name.first_name if user.middle_name
      user.save
    }
  end



User.current_user = User.find(1)
update_creator
de_identification





