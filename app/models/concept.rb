class Concept < OpenMRS
  set_table_name "concept"
  set_fixture_name "name"
  validates_uniqueness_of :name
  has_many :obs, :foreign_key => :concept_id
  has_many :drugs, :foreign_key => :concept_id do
    def filter(filter_text)
      find(:all, :conditions => ["name LIKE ?", "%#{filter_text}%"])
    end
  end
  has_many :field_answers, :foreign_key => :answer_id
  has_many :concept_answers, :foreign_key => :concept_id
  has_many :answer_options, :through => :concept_answers
  has_many :fields, :foreign_key => :concept_id
  has_many :concept_synonyms, :foreign_key => :concept_id
  has_many :concept_sets_controlled, :class_name => "ConceptSet", :foreign_key => :concept_set
  has_many :concepts, :through => :concept_sets_controlled # this is for concept set children
  has_many :concept_sets, :foreign_key => :concept_id  # these are the concept sets that this concept belongs to
  has_many :set_concepts, :through => :concept_sets # these are the concepts that this concept belongs to through sets
  has_many :concept_numerics, :foreign_key => :concept_id
  has_many :drug_ingredients, :foreign_key => :ingredient_id
  has_many :concept_words, :foreign_key => :concept_id
  has_many :concept_names, :foreign_key => :concept_id
  has_many :concept_proposals, :foreign_key => :obs_concept_id
  belongs_to :concept_class, :foreign_key => :class_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :concept_datatype, :foreign_key => :datatype_id
#concept_id
  set_primary_key "concept_id"

  def self.load_cache
    @@concept_hash_by_name = Hash.new
    @@concept_hash_by_id = Hash.new
    self.find(:all).each{|concept|
      @@concept_hash_by_name[concept.name.downcase] = concept
      @@concept_hash_by_id[concept.id] = concept
    }
  end
  
  self.load_cache

# Use the cache hash to get these fast
  def self.find_from_ids(args, options)
    super if args.length > 1 and return
    return @@concept_hash_by_id[args.first] || super
  end
  
  def self.find_by_name(concept_name)
    return @@concept_hash_by_name[concept_name.downcase] || super
  end

  def to_s
    self.name
  end
  
  def to_short_s    
    self.short_name.blank? ? self.name : self.short_name
  end
  
  def add_concept_answer(concept_name)
    concept_answer_option = Concept.find_by_name(concept_name)
    unless self.answer_options.include?(concept_answer_option)
      concept_answer = ConceptAnswer.new()
      concept_answer.concept_id = self.concept_id
      concept_answer.answer_concept = concept_answer_option.concept_id
      concept_answer.save
    end
  end
  
  def add_yes_no_concept_answers
    self.add_concept_answer("Yes")
    self.add_concept_answer("No")
    true
  end
  
  def add_yes_no_unknown_concept_answers
    self.add_yes_no_concept_answers
    self.add_concept_answer("Unknown")
  end
  
  def add_yes_no_unknown_not_applicable_concept_answers
    self.add_yes_no_unknown_concept_answers
    self.add_concept_answer("Not applicable")
  end
  
  def self.create_start_substitute_switch_answers_for_regimen_type
    start = Concept.find_by_name("Start")
    substitute = Concept.find_by_name("Substitute")
    switch = Concept.find_by_name("Switch")
    arv_regimen_type = Concept.find_by_name("ARV Regimen type")
    if ConceptAnswer.find_by_concept_id(arv_regimen_type.concept_id).nil?
      [start,substitute,switch].each{|concept|
        answer = ConceptAnswer.new
        answer.concept_id = arv_regimen_type.concept_id
        answer.answer_concept = concept.concept_id
        answer.save
      }
    end
  end

  def create_field
    field = Field.new
    case self.concept_datatype.name
      when "Coded"
        field.type = FieldType.find_by_name("select")
      when "Number"
        field.type = FieldType.find_by_name("number")
      when "Date"
        field.type = FieldType.find_by_name("date")
      else
        field.type = FieldType.find_by_name("alpha")
    end
    field.name = self.name
    field.concept = self
    field.save
  end
  
  def humanize
    c = self
    c.name = c.name.humanize.gsub(/who/i,"WHO").gsub(/(^| )art/i,"#{$1}ART").gsub(/cd4/i, "CD4").gsub(/cpt/i,"CPT").gsub(/arv/i,"ARV").gsub(/hiv/i,"HIV").gsub(/pcp/i,"PCP"); c.save
  end
  
=begin
  def to_fixture_name
    raise "No name for concept #{id}" unless self.name || self.short_name
    n = self.name.downcase if self.name
    n ||= self.short_name.downcase
    n = n.gsub(/(\s|-|\/)/, '_')
    n = n.gsub(/__/, '_')
    n = n.gsub(/[^a-z0-9_]/, '') 
    n
  end
=end  

end



### Original SQL Definition for concept #### 
#   `concept_id` int(11) NOT NULL auto_increment,
#   `retired` tinyint(1) NOT NULL default '0',
#   `name` varchar(255) NOT NULL default '',
#   `short_name` varchar(255) default NULL,
#   `description` text,
#   `form_text` text,
#   `datatype_id` int(11) NOT NULL default '0',
#   `class_id` int(11) NOT NULL default '0',
#   `is_set` tinyint(1) NOT NULL default '0',
#   `icd10` varchar(255) default NULL,
#   `loinc` varchar(255) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `default_charge` int(11) default NULL,
#   `version` varchar(50) default NULL,
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   `form_location` varchar(50) default NULL,
#   `units` varchar(50) default NULL,
#   `view_count` int(11) default NULL,
#   PRIMARY KEY  (`concept_id`),
#   KEY `concept_classes` (`class_id`),
#   KEY `concept_creator` (`creator`),
#   KEY `concept_datatypes` (`datatype_id`),
#   KEY `user_who_changed_concept` (`changed_by`),
#   CONSTRAINT `concept_classes` FOREIGN KEY (`class_id`) REFERENCES `concept_class` (`concept_class_id`),
#   CONSTRAINT `concept_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `concept_datatypes` FOREIGN KEY (`datatype_id`) REFERENCES `concept_datatype` (`concept_datatype_id`),
#   CONSTRAINT `user_who_changed_concept` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`)
