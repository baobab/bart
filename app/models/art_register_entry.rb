# REFACTOR. This class can be deleted. we use it in one place for a hash
class ArtRegisterEntry
  
  def to_s
    "#{name} #{sex} #{ambulant}"
  end
  
  attr_accessor :name, :sex, :age, :address, :arv_registration_number, 
   :date_of_registration, :outcome_status, :date_first_started_arv_drugs, 
   :date_of_art_initiation, :ambulant, :at_work_or_school, :guardian, 
   :date_of_visit, :reason_for_starting_arv, :quarter, :art_treatment_unit, 
   :ptb, :kaposissarcoma, :eptb, :refered_by_pmtct, :arv_regimen, :occupation,
   :last_weight ,:first_weight,:peripheral_neuropathy, :hepatitis, :skin_rash, 
   :lactic_acidosis, :lipodystrophy, :anaemia ,:other_side_effect, 
   :tablets_remaining   
end
