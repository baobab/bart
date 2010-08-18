class AddColumnToPharmacyObs < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE pharmacy_obs
ADD COLUMN expiry_date DATE AFTER value_numeric;
EOF

    ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE pharmacy_obs
ADD COLUMN value_text VARCHAR(15) AFTER value_numeric;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE pharmacy_obs DROP expiry_date;
EOF
    ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE pharmacy_obs DROP value_text;
EOF
  end
end
