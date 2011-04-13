DROP TABLE IF EXISTS tmp_ids;

CREATE TABLE `tmp_ids` (
 `id` integer NOT NULL AUTO_INCREMENT,
 `record_id` double NOT NULL default '0',
 `date_created` DATETIME,
 PRIMARY KEY(id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
CREATE UNIQUE INDEX tmp_ids_record ON tmp_ids (record_id);
INSERT INTO tmp_ids (record_id, date_created) (
  SELECT encounter_id,date_created FROM encounter
);

DROP TABLE IF EXISTS tmp_next_ids;
CREATE TABLE `tmp_next_ids` (
 `id` integer NOT NULL AUTO_INCREMENT,
 `next_id` double NOT NULL default '0',
 `next_date_created` DATETIME,
 PRIMARY KEY(id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE INDEX next_ids_next_id ON tmp_next_ids (next_id);

INSERT INTO tmp_next_ids (next_id, next_date_created) (
  SELECT encounter_id, date_created FROM encounter LIMIT 1,999999999
);

SELECT record_id, date_created, next_id, next_date_created, DATEDIFF(next_date_created, date_created) AS diff
 FROM tmp_ids
 INNER JOIN tmp_next_ids USING(id) HAVING diff > 1000 OR diff < -1000
 ORDER BY record_id, diff DESC;
 
DROP TABLE IF EXISTS tmp2_ids;
CREATE TABLE `tmp2_ids` (
 `id` integer NOT NULL AUTO_INCREMENT,
 `record_id` double NOT NULL default '0',
 `date_created` DATETIME,
 PRIMARY KEY(id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
CREATE UNIQUE INDEX tmp2_ids_record ON tmp2_ids (record_id);
INSERT INTO tmp2_ids (record_id, date_created) (
  SELECT next_id, date_created
    FROM tmp_ids
    INNER JOIN tmp_next_ids USING(id) WHERE DATEDIFF(tmp_next_ids.next_date_created, date_created) < -1000
    ORDER BY record_id
);

DROP TABLE IF EXISTS tmp2_next_ids;
CREATE TABLE `tmp2_next_ids` (
 `id` integer NOT NULL AUTO_INCREMENT,
 `next_id` double NOT NULL default '0',
 `next_date_created` DATETIME,
 PRIMARY KEY(id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE INDEX next_ids_next_id ON tmp2_next_ids (next_id);

INSERT INTO tmp2_next_ids (next_id, next_date_created) (
  SELECT record_id, next_date_created
    FROM tmp_ids
    INNER JOIN tmp_next_ids USING(id) WHERE DATEDIFF(tmp_next_ids.next_date_created, date_created) > 1000
    ORDER BY record_id
);

