class CreateCohortReportFields < ActiveRecord::Migration
  def self.up
=begin
    create_table :cohort_report_fields do |t|
      t.string  :name, :null => false
      t.string  :short_name, :null => false
      t.integer :sort_weight
      t.timestamps
    end

    # TODO use hash index?
    add_index :cohort_report_fields, :short_name

    add_index :cohort_report_fields, :sort_weight
=end
  end

  def self.down
    drop_table :cohort_report_fields
  end
end
