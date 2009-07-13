class ConvertStartAndRegistrationDateViewsToTables < ActiveRecord::Migration
  def self.up
    
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_start_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_start_dates;
EOF
    create_table :patient_start_dates do |t|
      t.integer  :patient_id, :null => false
      t.datetime :start_date, :null => false
      t.integer  :age_at_initiation, :null => false
      t.timestamps
    end
    
    add_index :patient_start_dates, :patient_id
    add_index :patient_start_dates, :start_date
    
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_registration_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_registration_dates;
EOF
    
    create_table :patient_registration_dates do |t|
      t.integer :patient_id, :null => false
      t.integer :location_id, :null => false
      t.date    :registration_date, :null => false
      t.timestamps
    end
    
    add_index :patient_registration_dates, :patient_id
    add_index :patient_registration_dates, :registration_date
  end

  def self.down
    drop_table :patient_registration_dates
    drop_table :patient_start_dates
  end
end
