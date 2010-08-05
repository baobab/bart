class FixDuplicateConcepts < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 96 WHERE concept_id IN (511,512) AND value_coded = 528;
EOF

    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 580 WHERE concept_id = 563 AND value_coded = 581;
EOF

    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 635 WHERE concept_id = 563 AND value_coded IN (636,637,638);
EOF

    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 91 WHERE concept_id IN (511,512) AND value_coded = 645;
EOF

  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_coded = 528 WHERE concept_id IN (511,512) AND value_coded = 96;
EOF
  end
end
