class CreateCohortReportFields < ActiveRecord::Migration
  def self.up
    create_table :cohort_report_fields do |t|
      t.string  :name, :null => false
      t.string  :short_name, :null => false
      t.integer :sort_weight
      t.timestamps
    end rescue nil

    # TODO use hash index?
    add_index :cohort_report_fields, :short_name rescue nil

    add_index :cohort_report_fields, :sort_weight rescue nil
  end

  def self.down
    drop_table :cohort_report_fields rescue nil
  end
end
