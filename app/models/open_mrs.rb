# CachedModel uses memcached to speed things up 
# crazy is not convinced it helps much
# It only caches very simply one row queries

#class OpenMRS < CachedModel
class OpenMRS < ActiveRecord::Base
  def before_save
    super
    self.changed_by = User.current_user.user_id if self.attributes.has_key?("changed_by") && User.current_user
    self.date_changed = Time.now if self.attributes.has_key?("date_changed")
    self.creator = 1 if !User.current_user
  end

  def before_create
    super
    self.creator = User.current_user.user_id if self.attributes.has_key?("creator") && User.current_user
    self.provider_id = User.current_user.user_id if self.attributes.has_key?("provider_id") && User.current_user
    self.date_created = Time.now if self.attributes.has_key?("date_created")
    self.location_id = Location.current_location.location_id if self.attributes.has_key?("location_id")
    unless Location.set_current_location.blank?
      if self.attributes.has_key?("location_id")
        self.location_id = Location.set_current_location.location_id 
      end
    end
  end
  
  def void!(reason)
    void(reason)
    save!
  end

  def void(reason)
    # TODO right now we are not allowing voiding to work on patient_identifiers
    # because of the composite key problem. Eventually this needs to be replaced
    # with better logic (like person_attributes)

#   TODO: this needs testing before turning on. For now, don't void Patient Identifiers
#    if composite?
#      destroy
#      return
#    end
    unless voided?
      #puts "---- Voided!!"
      self.date_voided = Time.now
      self.voided = true
      self.void_reason = reason
      self.voided_by = User.current_user.user_id unless User.current_user.nil?
    end    
  end
  
  def voided?
    self.attributes.has_key?("voided") ? voided : raise("Model does not support voiding")
  end  
  
  # cloning when there are composite primary keys
  # will delete all of the key attributes, we don't want that
  def composite_clone
    if composite? 
      attrs = self.attributes_before_type_cast
      self.class.new do |record|
        record.send :instance_variable_set, '@attributes', attrs
      end    
    else
      clone
    end  
  end

  def self.find_like_name(name)
    self.find(:all, :conditions => ["name LIKE ?","%#{name}%"])
  end

  def self.cache_on(*args)
    self.cattr_accessor :cached
    self.cached = true
  end

  def self.cached?
    self.cached
  end
  
=begin

  @@encounter_type_hash_by_name = Hash.new
  @@encounter_type_hash_by_id = Hash.new
  self.find(:all).each{|encounter_type|
    @@encounter_type_hash_by_name[encounter_type.name.downcase] = encounter_type
    @@encounter_type_hash_by_id[encounter_type.id] = encounter_type
  }

  def self.find_from_ids(args, options)
    super if args.length > 1 and return
    return @@encounter_type_hash_by_id[args.first] || super
  end
  
  def self.find_by_name(encounter_type_name)
    return @@encounter_type_hash_by_name[encounter_type_name.downcase] || super
  end
=end
end
