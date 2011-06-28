# Migrator
#
# Export/Import data to/from CSV files from BART 1
#
# Example: to export Vitals:
# m = Migration.new(7)
# m.to_csv('/tmp/vitals.csv')
#

#require 'rubygems'
require 'fastercsv'
require 'rest_client'

#gem 'fastercsv', '1.5.3'
#gem 'rest-client', '1.6.3'

class Migrator

  attr_reader :forms, :type, :default_fields, :header_col, :header_concepts

  @@concept_map = {}
  @@concept_name_map = {}

  def initialize(encounter_type_id=nil)
    if encounter_type_id 
      @type = EncounterType.find(encounter_type_id) rescue nil
      @default_fields = ['patient_id', 'encounter_id', 'workstation',
                         'date_created', 'encounter_datetime', 'provider_id']
      @header_col = {}
      self.header_concepts.each_with_index do |concept, col|
        @header_col[concept.concept_id] = col + @default_fields.length
      end
    end
  end

  def self.concept_name_map
    @@concept_name_map
  end

  def self.concept_map
    @@concept_map
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

    @@concept_map['3'] = 1065
    @@concept_map['4'] = 1066
    @@concept_map['2'] = 1067

    @@concept_name_map['Yes'] = 1065
    @@concept_name_map['No'] = 1066
    @@concept_name_map['Unknown'] = 1067
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
    enc_params = {}
    i = 1
    FasterCSV.foreach(enc_file, :headers => true) do |row|
      enc_params = {}
      enc_params['encounter'] = {}
      enc_params['observations[]'] = []

      enc_params[:location] = row['workstation']

      enc_params['encounter']['patient_id'] = 27 #row['patient_id']
      enc_params['encounter']['encounter_type_name'] = type_name
      enc_params['encounter']['provider_id'] = row['provider_id']
      enc_params['encounter']['encounter_datetime'] = row['encounter_datetime']

      #self.headers
      ['Guardian present', 'Patient present'].each do |q|
        enc_params['observations[]'] << {
          :patient_id =>  27, # row['patient_id'],
          :concept_name => Concept.find(@@concept_name_map[q]).fullname,
          :value_coded_or_text => Concept.find(@@concept_map[row[q]]).fullname,
          :obs_datetime => row['encounter_datetime']
        }
      end
      
      begin
        RestClient.post('http://admin:test@localhost:3001/encounters/create',
                      enc_params)
      rescue
        logger.warn("Error while saving encounter no. #{i}")
      end
      puts enc_params['observations[]'].to_yaml
      i += 1
    end

=begin
    # login
    resp = nil
    begin
    #  RestClient.post('http://admin:test@localhost:3001/session',
    #    {:login => 'admin', :password => 'test', :location => '31'}
    #  )
    rescue
      # follow_redirection if resp.status == 302
    end

    # location
    begin
      #RestClient.put('http://admin:test@localhost:3001/session',
      #  {'location' => '31'})
    rescue
      # resp.follow_redirection if resp.status == 302
    end


    # post
    begin
      resp = RestClient.post('http://admin:test@localhost:3001/encounters/create',
                      enc_params)
    rescue
      puts resp.to_yaml
    end
=end
  end


  
end
