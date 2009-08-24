class DrugOrderCombinationRegimen < ActiveRecord::Base
  set_table_name :drug_order_combination_regimen
  has_many :drug_order_combinations, :foreign_key => :drug_order_combination_regimen_id, :dependent => :destroy
end
