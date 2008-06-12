class EncounterGenerator < Rails::Generator::NamedBase

  attr_accessor :form, :form_fields

  def manifest
    record do |m|
      puts "Using database \'#{Form.connection.current_database}\'..."

      # Lookup the form in the database so that we can start to build the
      # rhtml for the encounter based on the set of fields
      @form = Form.find_by_uri(name, :include => :form_fields) 
      if (@form.nil?)
        puts "Form \'#{name}\' does not exist"        
        exit
      end  
 
      # Copy the fields and sort them by the field number  
      @form_fields = form.form_fields.sort_by { |form_field|
        form_field.field_number 
      }
            

      # Model class, unit test, and fixtures.
      if name.match(/art_(\w*)_staging_(\w*)/i)
        m.directory File.join('app', 'views', "art_who_staging")
        m.template '_encounter_form.rhtml', File.join('app', 'views', "art_who_staging", "_form_#{$1}_#{$2}.rhtml")
      else
        # Stylesheet and public directories.
        m.directory File.join('public', 'stylesheets')
        m.directory File.join('app', 'views', @form.uri)
        m.template '_encounter.rb', File.join('app', 'controllers', "#{@form.uri}_controller.rb")
#        m.template '_encounter.rhtml', File.join('app', 'views', @form.uri, "index.rhtml")
        m.template '_encounter_new.rhtml', File.join('app', 'views', @form.uri, "new.rhtml")
        m.template '_encounter_form.rhtml', File.join('app', 'views', "observation", "_form.rhtml")
        m.template 'encounter.css', File.join('public', 'stylesheets', "encounter.css")
      end
      
      
    end
  end
end
  
