class FixDuplicateConcepts < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 96 WHERE concept_id IN (511,512) AND value_coded = 528;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 528 WHERE concept_id IN (511,512) AND value_coded = 96;
EOF
  end
end
