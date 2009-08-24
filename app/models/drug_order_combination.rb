class DrugOrderCombination < ActiveRecord::Base
  set_table_name :drug_order_combination
  belongs_to :drug_order_combination_regimen, :foreign_key => drug_order_combination_regimen_id
end
