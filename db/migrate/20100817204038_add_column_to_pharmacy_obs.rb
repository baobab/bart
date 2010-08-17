class AddColumnToPharmacyObs < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE pharmacy_obs
ADD COLUMN expiry_date DATE  AFTER value_numeric;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE pharmacy_obs DROP expiry_date;
EOF
  end
end
