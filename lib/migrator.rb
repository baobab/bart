# =Migrator
#
# Export/Import data to/from CSV files from BART 1
#
#
#
# Example:
#   In BART1 to export HIV Reception (assuming we have /tmp/migrate/concept_map.csv):
#
# > m = Migrator.new('/tmp/migrate', 6)
# > m.to_csv('hiv_reception.csv')
#
# To Import in BART2
#
# > m = Migrator.new('/tmp/migrate')
# > m.create_encounters('hiv_reception.csv', 'username:password@locahost:3000')
#

require 'fastercsv'
require 'rest_client'

#gem 'fastercsv', '1.5.3'
#gem 'rest-client', '1.6.3'

class Migrator

  attr_reader :forms, :type, :default_fields, :header_col, :header_concepts,
              :csv_dir, :concept_map, :concept_name_map, :bart_url

  
  def initialize(csv_dir, encounter_type_id=nil)
    @default_fields = ['patient_id', 'encounter_id', 'workstation',
                       'date_created', 'encounter_datetime', 'provider_id',
                       'voided', 'voided_by', 'date_voided', 'void_reason'
                       ]
    @_header_concepts = nil
    @concept_map = nil
    @concept_name_map = nil
    @csv_dir = csv_dir + '/'

    # Export mode
    if encounter_type_id 
      @type = EncounterType.find(encounter_type_id) rescue nil
      @header_col = {}
      concepts = self.header_concepts
      concepts.each_with_index do |concept, col|
        @header_col[concept.concept_id] = col + @default_fields.length
      end

      # prefixing drug_ to prevent conflicts between concept_ids and drug_ids (22)
      self.header_drugs.each_with_index do |drug, col|
        @header_col["drug_#{drug.drug_id}"] = col + @default_fields.length +
                                    concepts.length
      end
    end
  end
  
  # Dump concepts to CSV
  # headers: old_concept_id, new_concept_id, old_concept_name
  def dump_concepts(file='concept_map.csv')
    FasterCSV.open(@csv_dir + file, 'w',
        :headers => true) do |csv|
      csv << ['old_concept_id', 'old_concept_name', 'new_concept_id']
      Concept.all(:order => 'concept_id').each do |c|
        csv << [c.concept_id, c.name, @concept_map[c.concept_id.to_s].to_i]
      end
    end
  end

  # Load mapping of old concepts to new ones
  # headers: old_concept_id, new_concept_id[, old_concept_name]
  def load_concepts(file='concept_map.csv')
    @concept_map = {}
    @concept_name_map = {}
    FasterCSV.foreach(@csv_dir + file, :headers => true) do |row|
      unless @concept_map[row['old_concept_id']]
        @concept_map[row['old_concept_id']] = row['new_concept_id']
        if row['old_concept_name']
          @concept_name_map[row['old_concept_name']] = row['new_concept_id']
        end
      end
    end

  end

  # Get all headers using forms (INCOMPLETE!)
  def headers_by_forms
    @forms = @type.forms rescue nil
    @default_fields + @forms.first.fields.all(
        :order => 'field_number'
      ).map(&:concept).map(&:name)
  end

  # List of all headers including the default ones
  def headers
    fields = @default_fields + self.header_concepts.map(&:name)
    if @type.name == 'Give drugs'
      fields += self.header_drugs.map(&:name)
    end

    fields
  end

  # Get all concepts saved in all observations of this encounter type
  def header_concepts
    @_header_concepts || @_header_concepts = Observation.all(
        :joins => [:encounter, :concept],
        :conditions => ['encounter_type = ?', @type.id],
        :group => 'concept.concept_id',
        :order => 'concept.concept_id').map(&:concept)
  end

  # Get all drugs dispensed in all drug orders
  def header_drugs
    DrugOrder.all(
      :joins => 'INNER JOIN orders USING(order_id)
                 INNER JOIN encounter USING(encounter_id)',
      :conditions => ['encounter_type = ?', @type.id],
      :group => 'drug_order.drug_inventory_id',
      :order => 'drug_order.drug_inventory_id'
    ).map(&:drug)
  end

  # New concept ids for this encounter type
  def new_header_ids
    self.header_concepts.map do |c|
      @concept_map[c.concept_id.to_s].to_i
    end if @concept_map
  end

  # Get value of given observation
  def obs_value(obs)
    return obs.value_coded unless obs.value_coded.nil?
    return obs.value_datetime unless obs.value_datetime.nil?
    return obs.value_text unless obs.value_text.nil?
    return obs.value_boolean unless obs.value_boolean.nil?
    return obs.value_numeric unless obs.value_numeric.nil?
  end

  # Get void data if the given OpenMRS record is voided
  def set_void_info(record)
    void_info = {}
    if record and record.voided?
      void_info = {
        :voided => 1,
        :voided_by => record.voided_by,
        :date_voided => record.date_voided,
        :void_reason => record.void_reason
      }
    end
    void_info
  end

  # Export one encounter to one row of CSV
  def row(encounter)
    row = []
    row << encounter.patient_id
    row << encounter.encounter_id
    row << 31 # TODO: workstation
    row << encounter.date_created
    row << encounter.encounter_datetime
    row << encounter.provider_id
    
    obs = Observation.all(:conditions => ['encounter_id = ?', encounter.id],
                          :order => 'concept_id')
    void_info = self.set_void_info(obs.first)
    obs.each do |o|
      row[@header_col[o.concept_id]] = obs_value(o)
    end

    # Export drug orders for Give drugs encounters
    if @type.name == 'Give drugs'
      # order.voided, order.voided_by, order.date.voided
      # drug_order.drug_inventory_id, drug_order.quantity
      orders = Order.all(
          :select => 'orders.*, drug_order.drug_inventory_id,
                      SUM(drug_order.quantity) AS total_qty',
          :conditions => ['orders.encounter_id = ?', encounter.id],
          :joins => [:drug_orders, :encounter],
          :group => 'orders.encounter_id, drug_order.drug_inventory_id',
          :order => 'drug_inventory_id')
      set_void_info(orders.first) if void_info.blank?
      orders.each do |o|
        row[@header_col["drug_#{o.drug_inventory_id}"]] = o.total_qty
      end
    end

    # mark voided if it is
    unless void_info.blank?
      row[6] = void_info[:voided]
      row[7] = void_info[:voided_by]
      row[8] = void_info[:date_voided]
      row[9] = void_info[:void_reason]
    end
    
    row
  end

  # Export encounters of given type to csv
  def to_csv(out_file=nil)
    out_file = self.to_filename(@type.name) + '.csv' unless out_file
    out_file = @csv_dir + out_file
    FasterCSV.open(out_file, 'w',:headers => self.headers) do |csv|
      csv << self.headers
      Encounter.all(:conditions => ['encounter_type = ?', @type.id],
                    :limit => 1000, :order => 'encounter_id').each do |e|
        csv << self.row(e)
      end
    end
  end

  def to_filename(name)
    name.downcase.gsub(' ', '_')
  end

  # Post to BART 2

  def init_params(enc_row, type_name)
    enc_params = {}
    enc_params['encounter'] = {}
    enc_params['observations[]'] = []

    enc_params[:location] = enc_row['workstation']

    # encounter params
    enc_params['encounter']['patient_id'] = 27 #enc_row['patient_id']
    enc_params['encounter']['encounter_type_name'] = type_name
    enc_params['encounter']['provider_id'] = enc_row['provider_id']
    enc_params['encounter']['encounter_datetime'] = enc_row['encounter_datetime']

    enc_params
  end

  # Create HIV Reception Params from a CSV Encounter row
  def hiv_reception_params(enc_row, obs_headers)
    type_name = 'HIV Reception'
    enc_params = init_params(enc_row, type_name)

    obs_headers.each do |question|
      next unless enc_row[question]
      enc_params['observations[]'] << {
        :patient_id =>  27, # enc_row['patient_id'],
        :concept_name => Concept.find(@concept_name_map[question]).fullname,
        :obs_datetime => enc_row['encounter_datetime'],
        :value_coded_or_text => Concept.find(@concept_map[enc_row[question]]).fullname
      }
    end
    enc_params
  end

  # Create HIV Reception Params from a CSV Encounter row
  def art_initial_params(enc_row, obs_headers)
    type_name = 'ART Initial'
    enc_params = init_params(enc_row, type_name)

    # program params
    enc_params['programs[]'] = []
    enc_params['programs[]'] << {
      'program_id' => Program.find_by_name('HIV PROGRAM').id,
      'date_enrolled' => enc_row['encounter_datetime'],
      'states[]' => {'state' => 'FOLLOWING'},
      'patient_program_id' => '',
      'location_id' => Location.current_health_center.id
    }

    obs_headers.each do |question|
      next unless enc_row[question]
      concept = Concept.find(@concept_name_map[question]) rescue nil
      next unless concept
      quest_params = {
        :patient_id =>  27, # enc_row['patient_id'],
        :concept_name => Concept.find(@concept_name_map[question]).fullname,
        :obs_datetime => enc_row['encounter_datetime']
      }

      case question
      when 'Date of positive HIV test', 'Date of ART initiation',
           'Date last ARVs taken'
        quest_params[:value_datetime] = enc_row[question]
      when 'Height', 'Weight'
        quest_params[:value_numeric]  = enc_row[question]
      when 'ARV number at that site'
        quest_params[:value_text]     = enc_row[question]
      else
        begin
          quest_params[:value_coded_or_text] = Concept.find(
            @concept_map[enc_row[question]]
          ).concept_id
        rescue
          next
        end
      end
      enc_params['observations[]'] << quest_params
    end
    
    enc_params
  end

  def hiv_staging_params(enc_row, obs_headers)
    type_name = 'HIV STAGING'
    enc_params = init_params(enc_row, type_name)

    obs_headers.each do |question|
      next unless enc_row[question]
      concept = Concept.find(@concept_name_map[question]) rescue nil
      next unless concept
      quest_params = {
        :patient_id   =>  27, # enc_row['patient_id'],
        :concept_name => Concept.find(@concept_name_map[question]).fullname,
        :obs_datetime => enc_row['encounter_datetime']
      }

      case question
      when "LYMPHOCYTE COUNT DATETIME", "CD4 COUNT DATETIME", "CD4 PERCENT DATETIME"
        quest_params[:value_datetime] = enc_row[question]
      when "CD4 PERCENT", "LYMPHOCYTE COUNT"
        quest_params[:value_numeric]  = enc_row[question]
      when "CLINICAL NOTES CONSTRUCT"
        quest_params[:value_text]     = enc_row[question]
      else
        begin
          quest_params[:value_coded_or_text] = Concept.find(
            @concept_map[enc_row[question]]
          ).concept_id
        rescue
          next
        end
      end
      enc_params['observations[]'] << quest_params
    end

    enc_params
  end

  def appointment_params(enc_row)
    type_name = 'Appointment'
    enc_params = init_params(enc_row, type_name)

    visit_date = enc_row['encounter_datetime']
    enc_params['observations[]']
    question = 'Appointment date'
    if enc_row[question]
      appointment_date = enc_row[question].to_date
      enc_params['observations[]'] << {
        :patient_id =>  27, # enc_row['patient_id'],
        :concept_name => 'RETURN VISIT DATE', # Concept.find(@concept_name_map[question]).fullname,
        :obs_datetime => visit_date,
        :value_datetime => appointment_date
      }
      enc_params[:time_until_next_visit] = (appointment_date - visit_date.to_date).to_i/7
    end
    enc_params
  end

  # Create Drug Dispensations from an Encounter row
  def create_dispensations(enc_row, obs_headers)
    obs_headers.each do |question|
      next unless enc_row[question]

      enc_params = {}
      
      case question
      when 'Number of ARV tablets dispensed'
        next # TODO: find regimens for the first 15 dispensation at MPC

      when 'Number of CPT tablets dispensed'
        enc_params = {
          :patient_id => 27, # TODO: enc_row['patient_id'],
          :drug_id    => 297,
          :quantity   => enc_row[question]
        }
        post_params('dispensations/create', enc_params, @bart_url)

      when 'Appointment date'
        enc_params = self.appointment_params(enc_row)
        post_params('encounters/create', enc_params, @bart_url)

      else # dispensed drugs
        enc_params = {
          :patient_id => 27, # TODO: enc_row['patient_id'],
          :drug_id    => @drug_name_map[question],
          :quantity   => enc_row[question]
        }
        post_params('dispensations/create', enc_params, @bart_url)
      end
    end
    
    nil
  end

  def create_encounters(enc_file, bart_url)
    @bart_url = bart_url
    f = FasterCSV.read(@csv_dir + enc_file, :headers => true)
    obs_headers = f.headers - self.default_fields

    self.load_concepts unless @concept_map and @concept_name_map
    enc_params = {}
    i = 1
    FasterCSV.foreach(@csv_dir + enc_file, :headers => true) do |row|

      post_action = 'encounters/create'
      case enc_file.split('.').first
      when 'hiv_reception'
        enc_params = hiv_reception_params(row, obs_headers)
        raise enc_params.to_yaml
        post_params(post_action, enc_params, bart_url)
      when 'hiv_first_visit'
        enc_params = art_initial_params(row, obs_headers)
        raise enc_params.to_yaml
        post_params(post_action, enc_params, bart_url)
      when 'hiv_staging'
        enc_params = art_initial_params(row, obs_headers)
        raise enc_params.to_yaml
        post_params(post_action, enc_params, bart_url)
      when 'give_drugs'
        create_dispensations(row, obs_headers)
      end
      
      i += 1
    end

  end

  def post_params(post_action, enc_params, bart_url)
    begin
      RestClient.post("http://#{bart_url}/#{post_action}",
                      enc_params)
    rescue
      logger.warn("Migrator: Error while importing encounter")
    end
  end

  def type_map
    {'hiv_reception'   => 'HIV Reception',
     'hiv_first_visit' => 'ART Initial'
    }
  end
  
end
