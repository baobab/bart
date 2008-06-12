class Program < OpenMRS
  set_table_name "program"
  set_primary_key "program_id"
  belongs_to :concept
  has_many :patient_programs, :foreign_key => :program_id
  has_many :patients, :through => :patient_programs
  
  @@program_hash_by_id = Hash.new
  self.find(:all).each{|program|
    @@program_hash_by_id[program.id] = program
  }

# Use the cache hash to get these fast
  def self.find_from_ids(args, options)
    super if args.length > 1 and return
    return @@program_hash_by_id[args.first] || super
  end

  def self.find_by_name(program_name)
    concept = Concept.find_by_name(program_name)
    return self.find_by_concept_id(concept.id)
  end

  def name
    self.concept.name
  end


end

#
#
#CREATE TABLE `program` (
#  `program_id` int(11) NOT NULL auto_increment,
#  `concept_id` int(11) NOT NULL default '0',
#  `creator` int(11) NOT NULL default '0',
#  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#  `changed_by` int(11) default NULL,
#  `date_changed` datetime default NULL,
#  `voided` tinyint(1) NOT NULL default '0',
#  `voided_by` int(11) default NULL,
#  `date_voided` datetime default NULL,
#  `void_reason` varchar(255) default NULL,
#  PRIMARY KEY  (`program_id`),
#  KEY `program_concept` (`concept_id`),
#  KEY `program_creator` (`creator`),
#  KEY `user_who_changed_program` (`changed_by`),
#  KEY `user_who_voided_program` (`voided_by`),
#  CONSTRAINT `user_who_voided_program` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`),
#  CONSTRAINT `program_concept` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`),
#  CONSTRAINT `program_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#  CONSTRAINT `user_who_changed_program` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`)
#) ENGINE=InnoDB DEFAULT CHARSET=utf8;
