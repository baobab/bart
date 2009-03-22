class FieldType < OpenMRS
  set_table_name "field_type"
  set_primary_key "field_type_id"
  has_many :fields, :foreign_key => :field_type
  belongs_to :user, :foreign_key => :user_id

  class << self
    def build_hash_cache
      @@field_type_hash_by_name = Hash.new
      @@field_type_hash_by_id = Hash.new
      find(:all).each do |field_type|
        @@field_type_hash_by_name[field_type.name.downcase] = field_type
        @@field_type_hash_by_id[field_type.id] = field_type
      end
    end

    # Use the cache hash to get these fast
    def find_from_ids(args, options = {})
      build_hash_cache if @@field_type_hash_by_id.blank?

      args.flatten!
      results = args.map{|id| @@field_type_hash_by_id[id]}.compact
      return results.first if !results.blank? && args.size == 1
      return results if !results.blank? && results.size == args.size
      super
    end

    def find_by_name(field_type_name)
      build_hash_cache if @@field_type_hash_by_name.blank?
      return @@field_type_hash_by_name[field_type_name.downcase] || super
    end
  end

  build_hash_cache

end

