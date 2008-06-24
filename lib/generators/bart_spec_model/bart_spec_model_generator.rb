class BartSpecModelGenerator < Rails::Generator::NamedBase

  def initialize(runtime_args, runtime_options = {})
    super    
  end

  def manifest
    record do |m|
      # Test directories.
      m.directory(File.join('spec/models', class_path))
      m.directory(File.join('spec/fixtures', class_path))   
      m.template('model_spec.rb', File.join('spec/models', class_path, "#{file_name}_spec.rb"))
      m.template('fixtures.yml', File.join('spec/fixtures', "#{actual_table_name}.yml"))
    end
  end

  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} bart_spec_model ModelName"
    end
    
    def actual_table_name
      model_name.classify.constantize.table_name  rescue class_name.underscore.downcase
    end

    def model_name 
      class_name.demodulize
    end
end
