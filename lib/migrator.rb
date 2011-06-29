# Migrator
#
# Export/Import data to/from CSV files from BART 1
#
#
#
# Example:
#   In BART1 to export HIV Reception (assuming we have /tmp/migrate/concept_map.csv):
#
# > m = Migration.new('/tmp/migrate', 6)
# > m.to_csv('hiv_reception.csv')
#
# To Import in BART @
#
# > m = Migration.new('/tmp/migrate')
# > m.create_encounters('hiv_reception.csv')
#

require 'fastercsv'
require 'rest_client'

#gem 'fastercsv', '1.5.3'
#gem 'rest-client', '1.6.3'

class Migrator

  attr_reader :forms, :type, :default_fields, :header_col, :header_concepts,
              :csv_dir, :concept_map, :concept_name_map

  
  def initialize(csv_dir, encounter_type_id=nil)
    @default_fields = ['patient_id', 'encounter_id', 'workstation',
                       'date_created', 'encounter_datetime', 'provider_id']
    @_header_concepts = nil
    @concept_map = nil
    @concept_name_map = nil
    @csv_dir = csv_dir + '/'

    # Export mode
    if encounter_type_id 
      @type = EncounterType.find(encounter_type_id) rescue nil
      @header_col = {}
      self.header_concepts.each_with_index do |concept, col|
        @header_col[concept.concept_id] = col + @default_fields.length
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

    @concept_map['3'] = 1065
    @concept_map['4'] = 1066
    @concept_map['2'] = 1067

    @concept_name_map['Yes'] = 1065
    @concept_name_map['No'] = 1066
    @concept_name_map['Unknown'] = 1067
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
    @default_fields + self.header_concepts.map(&:name)
  end

  # Get all concepts saved in all observations of this encounter type
  def header_concepts
    @_header_concepts || @_header_concepts = Observation.all(
        :joins => [:encounter, :concept],
        :conditions => ['encounter_type = ?', @type.id],
        :group => 'concept.concept_id',
        :order => 'concept.concept_id').map(&:concept)
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

  # Export one encounter to one row of CSV
  def row(encounter)
    row = []
    row << encounter.patient_id
    row << encounter.encounter_id
    row << 31 # workstation
    row << encounter.date_created
    row << encounter.encounter_datetime
    Observation.all(:conditions => ['encounter_id = ?', encounter.id],
                    :order => 'concept_id').each do |o|

      row[@header_col[o.concept_id]] = obs_value(o) #.result_to_string
    end
    row
  end

  # Export encounters of given type to csv
  def to_csv(out_file=nil)
    outfile = self.to_filename(@type.name) + '.csv' unless out_file
    out_file = @csv_dir + out_file
    FasterCSV.open(out_file, 'w',:headers => self.headers) do |csv|
      csv << self.headers
      Encounter.all(:conditions => ['encounter_type = ?', @type.id],
                    :limit => 100, :order => 'encounter_id DESC').each do |e|
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

  def create_encounters(enc_file)
    f = FasterCSV.read(@csv_dir + enc_file, :headers => true)
    obs_headers = f.headers - self.default_fields

    self.load_concepts unless @concept_map and @concept_name_map
    enc_params = {}
    i = 1
    FasterCSV.foreach(@csv_dir + enc_file, :headers => true) do |row|

      #raise row.to_yaml
      case enc_file.split('.').first
      when 'hiv_reception'
        enc_params = hiv_reception_params(row, obs_headers)
      when 'hiv_first_visit'
        enc_params = art_initial_params(row, obs_headers)
      end
      
      raise enc_params.to_yaml
      
      begin
        RestClient.post('http://admin:test@localhost:3001/encounters/create',
                        enc_params)
      rescue
        logger.warn("Error while saving encounter no. #{i}")
      end
      puts enc_params['observations[]'].to_yaml
      i += 1
    end

  end

  def type_map
    {'hiv_reception'   => 'HIV Reception',
     'hiv_first_visit' => 'ART Initial'
    }
  end
  
end
