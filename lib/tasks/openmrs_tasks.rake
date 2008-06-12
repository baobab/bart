namespace :openmrs do

  def setup_openmrs
    raise "You must specify the RAILS_ENV variable for the database environment you want to use" unless ENV["RAILS_ENV"] 
    require File.join(RAILS_ROOT, 'config', 'environment')
    require 'active_record/fixtures'    
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")    
  end  

  namespace :bootstrap do
    namespace :create do
      desc "Create a set of OpenMRS fixtures from the current database"
      task :defaults do
        setup_openmrs
        data = File.join(RAILS_ROOT, 'db', 'data')
        path = File.join(data, 'defaults')
        Dir.mkdir(data) unless File.exists?(data)
        Dir.mkdir(path) unless File.exists?(path)
        Concept.to_fixtures(path)
        ConceptAnswer.to_fixtures(path)
        ConceptClass.to_fixtures(path)
        ConceptDatatype.to_fixtures(path)
        ConceptMap.to_fixtures(path)
        ConceptName.to_fixtures(path)
        ConceptNumeric.to_fixtures(path)
        ConceptProposal.to_fixtures(path)
        ConceptSet.to_fixtures(path)
        ConceptSetDerived.to_fixtures(path)
        ConceptSource.to_fixtures(path)
        ConceptSynonym.to_fixtures(path)
        ConceptWord.to_fixtures(path)
        Drug.to_fixtures(path)
        DrugBarcode.to_fixtures(path)
        DrugIngredient.to_fixtures(path)
        EncounterType.to_fixtures(path)
        Field.to_fixtures(path)
        FieldAnswer.to_fixtures(path)
        FieldType.to_fixtures(path)
        Form.to_fixtures(path)
        FormField.to_fixtures(path)
        Location.to_fixtures(path)
        MimeType.to_fixtures(path)
        OrderType.to_fixtures(path)
        PatientIdentifierType.to_fixtures(path)
        RelationshipType.to_fixtures(path)
        Report.to_fixtures(path)
        ReportObject.to_fixtures(path)
        Tribe.to_fixtures(path)
        WeightForHeight.to_fixtures(path)
        WeightHeightForAge.to_fixtures(path)
      end
      
      desc "Create a set of site-specific OpenMRS fixtures from the current database"
      task :site do
        setup_openmrs
        puts "You must include the site code (SITE=llh)" and return unless ENV['SITE']
        data = File.join(RAILS_ROOT, 'db', 'data')
        path = File.join(data, ENV['SITE'])
        Dir.mkdir(data) unless File.exists?(data)
        Dir.mkdir(path) unless File.exists?(path)
        GlobalProperty.to_fixtures(path)
        NotificationTemplate.to_fixtures(path)
        Privilege.to_fixtures(path)
        Program.to_fixtures(path)
        Role.to_fixtures(path)
        RolePrivilege.to_fixtures(path)
        RoleRole.to_fixtures(path)
        SchedulerTaskConfig.to_fixtures(path)
        SchedulerTaskConfigProperty.to_fixtures(path)
        UserProperty.to_fixtures(path)
        UserRole.to_fixtures(path)      
      end 
    end
        
    namespace :load do
      desc "Load a set of OpenMRS fixtures into the current database"
      task :defaults do
        setup_openmrs
        Dir.glob(File.join(RAILS_ROOT, 'db', 'data', 'defaults', '*.yml')).each do |fixture_file|
          puts 'Loading fixture: ' + fixture_file 
          Fixtures.create_fixtures("db/data/defaults", File.basename(fixture_file, '.*'))
        end
      end
    
      desc "Load a set of site-specific OpenMRS fixtures from the current database"
      task :site do
        setup_openmrs
        puts "You must include the site code (SITE=llh)" and return unless ENV['SITE']
        Dir.glob(File.join(RAILS_ROOT, 'db', 'data', ENV['SITE'], '*.yml')).each do |fixture_file|
          puts 'Loading fixture: ' + fixture_file 
          Fixtures.create_fixtures("db/data/#{ENV['SITE']}", File.basename(fixture_file, '.*'))
        end
      end 

      desc "Load the test OpenMRS fixtures into the current database"
      task :samples do
        setup_openmrs
        Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.yml')).each do |fixture_file|
          puts 'Loading fixture: ' + fixture_file 
          Fixtures.create_fixtures("test/fixtures", File.basename(fixture_file, '.*'))
        end
      end 
    end
  end  
end
