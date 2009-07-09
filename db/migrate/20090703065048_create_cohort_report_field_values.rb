class CreateCohortReportFieldValues < ActiveRecord::Migration
  def self.up
    create_table :cohort_report_field_values do |t|
      t.date :start_date, :null => false
      t.date :end_date, :null => false
      t.string  :short_name, :null => false
      t.integer :value
      t.timestamps
    end

    add_index :cohort_report_field_values, [:start_date, :end_date, :short_name], :unique => true, :name => 'dates_short_name_index'
  end

  def self.down
    drop_table :cohort_report_field_values
  end
end
