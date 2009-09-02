class CreateCohortTools < ActiveRecord::Migration
  def self.up
    create_table :cohort_tools do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :cohort_tools
  end
end
