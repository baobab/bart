require 'migrator'
require 'yaml'
require 'ftools'

Thread.abort_on_exception = true

puts "Starting Exporter at #{Time.now}"

#read the config file to get the settings
def read_config
  config = YAML.load_file("config/migration.yml")
  @export_path = config["config"]["export_path"]
  @export_type = config["config"]["export_type"]
  @file_map_location = config["config"]["file_map_location"]
  @limit = config["config"]["export_limit"]
  @min_date = config["config"]["start_date"]
  @max_date = config["config"]["end_date"]
end

#initialise the variables to use for export
def initialize_variables
  read_config
  @start_date = ''
  @end_date = ''
  @patients_list = []
  if @export_type == 'patient'
    if @max_date and @min_date
      @earliest_date = Time.parse(@min_date)
      @latest_date = Time.parse(@max_date)
    else
      @earliest_date = Patient.find(:first,
              :order => "date_created ASC").date_created
      @latest_date = Patient.find(:first,
            :order => "date_created DESC").date_created
    end
  else #encounter
    @earliest_date = Time.parse(@min_date) 
    @latest_date = Time.parse(@max_date)
  end

  #initialize an array of @threads
  @threads = []
  #initialize an array of acceptable @encounter_types
  @encounter_types = [1,2,3,4,5,6,7,14,15,17]
  @years_diff = (@latest_date.to_date).year -
                (@earliest_date.to_date).year
  @quarters = []
  @current_dir = ''
end

#This Exports data to the right directory
def export_enc(type)
  puts "starting #{EncounterType.find(type).name} export"
	m = EncounterExporter.new(@export_path, type, @limit, @patients_list,
                         @current_dir, @earliest_date,
                           @latest_date, @export_type)
	m.to_csv
  puts "#{EncounterType.find(type).name} done"
end


def prepare_environment
  Dir.mkdir(@export_path) unless File.exists?(@export_path) &&
                            File.directory?(@export_path)
  File.copy(@file_map_location + "/concept_map.csv", @export_path) unless \
                            File.exists?(@export_path + "/concept_map.csv")
  File.copy(@file_map_location + "/concept_name_map.csv", @export_path) unless \
                            File.exists?(@export_path + "/concept_name_map.csv")
  File.copy(@file_map_location + "/drug_map.csv", @export_path) unless \
                            File.exists?(@export_path + "/drug_map.csv")
end

def generate_quarters(year)
  @quarters = []

  date = Date.parse("1.1.#{year}")  unless date
  4.times do
    @quarters << [date.beginning_of_quarter, date.end_of_quarter]
    date = date.end_of_quarter+1.day
  end

end

initialize_variables
prepare_environment

if @export_type == 'patient'
  count = 0

  until count > @years_diff
    current_year = ((@earliest_date.to_date).year + count).to_s

    Dir.mkdir(@export_path + "/" + current_year) unless File.exists?(@export_path +
          "/" + current_year) && File.directory?(@export_path + "/" + current_year)
    generate_quarters(current_year.to_i)

    current_quarter = 1
    @quarters.each do |quarter|
      case current_quarter
      when 1
        Dir.mkdir(@export_path + "/" + current_year + "/first") unless \
                    File.exists?(@export_path + "/" + current_year + "/first") &&
                    File.directory?(@export_path + "/" + current_year + "/first")
        @current_dir = @export_path + "/" + current_year + "/first/"
      when 2
        Dir.mkdir(@export_path + "/" + current_year + "/second") unless \
                   File.exists?(@export_path + "/" + current_year + "/second") &&
                   File.directory?(@export_path + "/" + current_year + "/second")
        @current_dir = @export_path + "/" + current_year + "/second/"
      when 3
        Dir.mkdir(@export_path + "/" + current_year + "/third") unless \
                    File.exists?(@export_path + "/" + current_year + "/third") &&
                    File.directory?(@export_path + "/" + current_year + "/third")
        @current_dir = @export_path + "/" + current_year + "/third/"
      when 4
        Dir.mkdir(@export_path + "/" + current_year + "/fourth") unless \
                    File.exists?(@export_path + "/" + current_year + "/fourth") &&
                    File.directory?(@export_path + "/" + current_year + "/fourth")
        @current_dir = @export_path + "/" + current_year + "/fourth/"
      end

      @start_date = quarter[0]
      @end_date = quarter[1]
     
      if @patients_list.blank?
         @patients_list = Patient.find(:all,
                                  :order => 'date_created',
                                  :conditions => ['date_created BETWEEN ? AND ?',
                                  @start_date,@end_date]).each.collect{ |p|
                                  p['patient_id'].to_i
      end

      @encounter_types.each do |type|
        export_enc(type)
      end
      current_quarter+= 1
    end
    count+= 1
  end
else # encounter
  Dir.mkdir(@export_path + "/encounters") unless \
                    File.exists?(@export_path + "/encounters") &&
                    File.directory?(@export_path + "/encounters")
        @current_dir = @export_path + "/encounters/"

  @encounter_types.each do |type|
        export_enc(type)
  end
end

puts "Finished Exporting at #{Time.now}"
