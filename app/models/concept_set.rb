class ConceptSet < OpenMRS
  set_table_name "concept_set"
  set_primary_keys :concept_id, :concept_set

  belongs_to :concept, :class_name => "Concept", :foreign_key => :concept_id
  belongs_to :set_concept, :class_name => "Concept", :foreign_key => :concept_set
  belongs_to :user, :foreign_key => :user_id

  validates_uniqueness_of :concept_id, :scope => "concept_set"

  def to_s
    return "#{name}: #{self.set_concept.concepts.collect{|c|c.name}.join(', ')}"
  end

  def before_save
    super
    raise "Concept '#{self.set_concept.name}' is not a set - set the is_set property if you want it to be" unless self.set_concept.is_set
  end

  def name
    self.set_concept.name
  end

  # OPTIMIZE inefficient code (only called once, in admin)
  def self.find_by_name(name)
    ConceptSet.find(:all).collect{|cs|cs if cs.name == name}.compact
  end

end
