# Migrator
#
# Export/Import data to/from CSV files from BART 1
#
# Example: to export Vitals:
# m = Migration.new(7)
# m.to_csv('/tmp/vitals.csv')
#
require 'rubygems'
require '/var/lib/gems/1.8/gems/fastercsv-1.5.3/lib/fastercsv'
require 'rest_client'

class Migrator

  attr_reader :forms, :type, :default_fields, :header_col

  @@concept_map = {}
  @@concept_name_map = {}

  def initialize(encounter_type_id=nil)
    if encounter_type_id 
      @type = EncounterType.find(encounter_type_id) rescue nil
      @forms = @type.forms rescue nil
      @default_fields = ['patient_id', 'encounter_id',
                         'workstation', 'date_created']
      @header_col = {}
      self.header_concepts.each_with_index do |concept, col|
        @header_col[concept.concept_id] = col + @default_fields.length
      end
    end
  end

  # Dump concepts to CSV
  # headers: old_concept_id, new_concept_id, old_concept_name
  def self.dump_concepts(file)
    FasterCSV.open(file, 'w',
        :headers => true) do |csv|
      csv << ['old_concept_id', 'old_concept_name', 'new_concept_id']
      Concept.all(:order => 'concept_id').each do |c|
        csv << [c.concept_id, c.name, @@concept_map[c.concept_id.to_s].to_i]
      end
    end
  end

  # Load mapping of old concepts to new ones
  # headers: old_concept_id, new_concept_id[, old_concept_name]
  def self.load_concepts(file)
    FasterCSV.foreach(file, :headers => true) do |row|
      unless @@concept_map[row['old_concept_id']]
        @@concept_map[row['old_concept_id']] = row['new_concept_id']
        if row['old_concept_name']
          @@concept_name_map[row['old_concept_name']] = row['new_concept_id']
        end
      end
    end
  end

  # Get all headers using forms (INCOMPLETE!)
  def headers_by_forms
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
    Observation.all(
      :joins => [:encounter, :concept],
      :conditions => ['encounter_type = ?', @type.id],
      :group => 'concept.concept_id',
      :order => 'concept.concept_id').map(&:concept)
  end

  # New concept ids for this encounter type
  def new_header_ids
    self.header_concepts.map do |c|
      @@concept_map[c.concept_id.to_s].to_i
    end if @@concept_map
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
    row << encounter.location_id
    row << encounter.date_created
    Observation.all(:conditions => ['encounter_id = ?', encounter.id],
                    :order => 'concept_id').each do |o|

      row[@header_col[o.concept_id]] = obs_value(o) #.result_to_string
    end
    row
  end

  # Export encounters of given type to csv
  def to_csv(out_file)
    FasterCSV.open(out_file, 'w',:headers => self.headers) do |csv|
      csv << self.headers
      Encounter.all(:conditions => ['encounter_type = ?', @type.id],
                    :limit => 100, :order => 'encounter_id DESC').each do |e|
        csv << self.row(e)
      end
    end
  end

  # Post to BART 2
  def create_encounters(enc_file, type_name)
    params = {}
    FasterCSV.foreach(enc_file, :headers => true) do |row|

      params['encounter'] = {}
      params[:observations] = {}

      params['encounter']['patient_id'] = 27 #row['patient_id']
      params['encounter']['encounter_type_name'] = type_name
      params['encounter']['provider_id'] = 1 #TODO
      params['encounter']['encounter_datetime'] = Time.now # TODO

      ['Guardian present', 'Patient present'].each do |q|
        params[:observations] = {
          :patient_id => 27,
          :concept_name => q,
          :value_coded_or_text => 'YES'
        }
      end
    end

    # login
    resp = RestClient.post('http://admin:test@localhost:3001/session',
      {:login => 'admin', :password => 'test', :location => '31'}
    ) #rescue nil
    # login
    resp = RestClient.post('http://admin:test@localhost:3001/session',
      {'_method' => 'put', 'location' => '31'}
    ) #rescue nil

    resp = RestClient.post('http://admin:test@localhost:3001/encounters/create', params) #rescue nil
    puts "*** response ****"
    #puts resp
  end


  
end
