# Blatantly stolen from http://matthewbass.com/2007/03/07/overriding-existing-rake-tasks/
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
 
def remove_task(task_name)
  Rake.application.remove_task(task_name)
end
 
namespace :db do
  namespace :test do 
    # Remove rails default test database preparation
    remove_task "db:test:prepare"
    remove_task "db:test:clone_structure"

    # Overwrite with an extended test database prepare that recognizes a new schema_format.
    desc "Overwritten standard prepare to include parsing of :migrate schema_format type."
    task :prepare => :environment do
      Rake::Task["db:test:purge"].invoke
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      ActiveRecord::Schema.verbose = false
      Rake::Task["db:migrate"].invoke
    end

    desc "Overwritten standard recreate the test databases from the development structure"
    task :clone_structure => [ "db:structure:dump" ] do
      abcs = ActiveRecord::Base.configurations
      case abcs["test"]["adapter"]
      when "mysql"
        ActiveRecord::Base.establish_connection(:test)
        ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
        IO.readlines("db/#{RAILS_ENV}_structure.sql").join.split(";").each do |table|
          ActiveRecord::Base.connection.execute(table)
        end
      else
        raise "Task not supported by '#{abcs["test"]["adapter"]}'"
      end
    end
  end
  
  namespace :structure do
    desc "Dump the database structure to a SQL file"
    task :dump => :environment do
      abcs = ActiveRecord::Base.configurations
      case abcs[RAILS_ENV]["adapter"]
      when "mysql"
        `mysqldump --no-data -u "#{abcs[RAILS_ENV]["username"]}" #{abcs[RAILS_ENV]["database"]} > db/#{RAILS_ENV}_structure.sql`
        raise "Error dumping database" if $?.exitstatus == 1      
      else
        raise "Task not supported by '#{abcs["test"]["adapter"]}'"
      end

      if ActiveRecord::Base.connection.supports_migrations?
        File.open("db/#{RAILS_ENV}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
      end
    end
  end
end