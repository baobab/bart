class PatientNationalId < OpenMRS
  set_table_name "patient_national_id"

  named_scope :active, :conditions => ['assigned = 0']

    def self.read_file_and_create_ids
=begin
      national_ids = []
      ids = File.open(File.join(RAILS_ROOT, "ZombaIds.csv"), File::RDONLY).readlines.first
      ids.split(',').map{|i|
        national_id = i.strip
        next unless national_id.length == 6
        national_ids << national_id
      }

      national_ids.each do |national_id|
        p_national_id = self.new()
        p_national_id.national_id = national_id
        p_national_id.save
        puts "#{national_id} <<<<<<<<<<<<<<<<<<<"
      end
      return "Done"
=end
    end

    def self.next_id(patient_id = nil)
      id = self.active.find(:first)
      return id.national_id if patient_id.blank?
      id.assigned = true
      id.save
      return id.national_id
    end

end
