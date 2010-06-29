class CreateLabResultsDatabase < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
CREATE DATABASE IF NOT EXISTS healthdata;
EOF

    health_data = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['healthdata']
    ActiveRecord::Base.establish_connection(health_data)

    ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE IF NOT EXISTS `LabTestTable` (
  `AccessionNum` INTEGER NOT NULL auto_increment,
  `TestOrdered` varchar(30) NOT NULL default '',
  `Pat_ID` varchar(13) NOT NULL default '',
  `OrderDate` varchar(11) NOT NULL default '',
  `OrderTime` varchar(8) NOT NULL default '',
  `OrderedBy` varchar(6) NOT NULL default '',
  `Location` varchar(25) default NULL,
  `RcvdAtLabDate` varchar(11) default NULL,
  `RcvdAtLabTime` varchar(8) default NULL,
  PRIMARY KEY  (`AccessionNum`,`TestOrdered`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE IF NOT EXISTS `Lab_Parameter` (
  `Sample_ID` int(11) default NULL,
  `TESTTYPE` int(10) unsigned default NULL,
  `TESTVALUE` double default NULL,
  `TimeStamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `ID` int(10) unsigned NOT NULL auto_increment,
  `Range` enum('<','=','>') NOT NULL default '=',
  PRIMARY KEY  (`ID`),
  KEY `FK_sample_id` (`Sample_ID`)
) ENGINE=MyISAM AUTO_INCREMENT=264255 DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE IF NOT EXISTS `Lab_Sample` (
  `Sample_ID` int(20) unsigned NOT NULL auto_increment,
  `AccessionNum` int(10) unsigned default NULL,
  `PATIENTID` varchar(15) default NULL,
  `TESTDATE` varchar(11) default NULL,
  `USERID` varchar(255) default NULL,
  `DATE` varchar(255) default NULL,
  `TIME` varchar(255) default NULL,
  `SOURCE` int(11) default '0',
  `UpdateBy` varchar(255) default NULL,
  `UpdateTimeStamp` varchar(255) default NULL,
  `DeleteYN` smallint(6) default NULL,
  `Attribute` enum('pass','fail','lost','voided') default NULL,
  `TimeStamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`Sample_ID`),
  UNIQUE KEY `IndexAccessNum` (`AccessionNum`)
) ENGINE=MyISAM AUTO_INCREMENT=63262 DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE IF NOT EXISTS codes_TestType (
  `TestType` SMALLINT(6) NOT NULL,
  `TestName` VARCHAR(50),
  `ID` INTEGER NOT NULL auto_increment,
  `Panel_ID` INTEGER NOT NULL,
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

    ActiveRecord::Base.connection.execute <<EOF
DELETE FROM `codes_TestType`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
LOCK TABLES `codes_TestType` WRITE;
EOF

    ActiveRecord::Base.connection.execute <<EOF
INSERT INTO `codes_TestType` VALUES 
(9,'CD3_count',1,4),
(3,'CD4_count',2,4),
(4,'CD8_count',3,4),
(5,'CD4_CD8_ratio',4,4),
(6,'HIV_RNA_PCR',5,12),
(70,'CD3_percent',6,4),
(71,'CD4_percent',7,4),
(72,'CD8_percent',8,0),
(12,'CD8Tube',9,0),
(10,'ReagentLotID',10,0),
(11,'CD4Tube',11,0),
(12,'CD8Tube',12,0),
(14,'ControlRunReagentLotID',13,0),
(15,'ControlRunControlLotID',14,0),
(9,'TotalCD3Average',15,0),
(7,'CD4_CD3_ratio',16,4),
(8,'CD8_CD3_ratio',17,4),
(16,'Alanine_Aminotransferase',18,15),
(17,'Albumin',19,15),
(18,'Alkaline_Phosphatase',20,15),
(19,'Amylase',21,22),
(20,'Aspartate_Transaminase',22,15),
(21,'Basophil_count',23,25),
(22,'Basophil_percent',24,25),
(23,'Bilirubin_direct',25,15),
(24,'Bilirubin_total',26,15),
(25,'Urea_Nitrogen_blood',27,17),
(26,'Calcium',28,3),
(27,'Carbon_Dioxide',29,30),
(28,'Cell_count_pleural',30,29),
(29,'Chloride',31,17),
(30,'Cholesterol',32,21),
(31,'Creatinine',33,6),
(32,'Cryptococcal_Antigen',34,7),
(33,'Eosinophil_count',35,25),
(34,'Eosinophil_percent',36,25),
(35,'Glucose_blood',37,26),
(36,'Glucose_CSF',38,27),
(37,'Glutamyl_Transferase',39,15),
(38,'Hematocrit',40,10),
(39,'Hemoglobin',41,10),
(40,'HepBsAg',42,23),
(41,'HIV_DNA_PCR',43,12),
(42,'India_Ink',44,13),
(43,'Lactate',45,14),
(44,'Lymphocyte_count',46,10),
(45,'Lymphocyte_percent',47,10),
(46,'Malaria_Parasite_count',48,16),
(47,'MCH',49,10),
(48,'MCHC',50,10),
(49,'MCV',51,10),
(50,'Monocyte_count',52,25),
(51,'MPV',53,0),
(52,'Neutrophil_count',54,25),
(53,'Neutrophil_percent',55,25),
(54,'Phosphorus',56,3),
(55,'Platelet_count',57,10),
(56,'Potassium',58,17),
(57,'RBC',59,10),
(58,'RDW',60,0),
(59,'Sodium',61,17),
(60,'RPR_Syphilis',62,20),
(61,'Protein_total',63,15),
(62,'Toxoplasma_IgG',64,28),
(63,'Triglycerides',65,21),
(64,'WBC_count',66,10),
(65,'WBC_percent',67,10),
(66,'Monocyte_percent',68,25),
(73,'Lipase',70,0);
EOF

    ActiveRecord::Base.connection.execute <<EOF
UNLOCK TABLES;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE IF NOT EXISTS map_lab_panel (
  `rec_id` INT(4),
  `name` TEXT,
  `short_name` VARCHAR(60),
  `count_of_accession_num` INT(4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

    ActiveRecord::Base.connection.execute <<EOF
DELETE FROM `map_lab_panel`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
LOCK TABLES `map_lab_panel` WRITE;
EOF

    ActiveRecord::Base.connection.execute <<EOF
INSERT INTO `map_lab_panel` VALUES 
(26,'blood glucose','BLOOD_gluc',0),
(27,'cerebrospinal fluid glucose','CSF_gluc',0),
(28,'toxoplasmosis serology','TOXO',  0),
(29,'pleural fluid cell count','PLEU_cells',0),
(30,'other','OTHER',0),
(1,'acid fast bacilli smear microscopy','AFB_smear',645),
(2,'blood culture and      sensitivity','Blood_C_S',37),
(3,'calcium and phosphate in serum','Ca_PO4',3),
(4,'CD4 immunology','CD4',26551),
(5,'cholesterine','Cholest',6),
(6,'creatinine','Creat',64),
(7,'cryptococcal antigen','Crypto_AG',142),
(8,'cerebrospinal fluid culture and sensitivity','CSF_C_S',39),
(9,'erythrocyte sedimentation rate','ESR',29),
(10,'full blood count','FBC',4729),
(11,'cerebrospinal fluid full analysis','CSF_full',567),
(12,'HIV viral load','HIV_viral_load',50),
(13,'cerebrospinal fluid microscopy india ink stain','CSF_indiaink',340),
(14,'lactate','Lactate',219),
(15,'liver function tests','LFT',702),
(16,'malaria parasites','MP',2367),
(17,'urea and electolytes','U&E',809),
(18,'urine culture and sensitivity','Urine_C_S',97),
(19,'urine microscopy','Urine_micro',114),
(20,'syphilis serology','VDRL',195),
(21,'lipid profile','LIP',0),
(22,'amylase','AMYL',0),
(23,'hepatitis B serology','HEPB',0),
(24,'acid fast bacilli culture','AFB_culture',0),
(25,'white blood cell differential count','WBC_diff',0),
(26,'blood glucose','BLOOD_gluc',0),
(27,'cerebrospinal fluid glucose','CSF_gluc',0),
(28,'toxoplasmosis serology','TOXO',0),
(29,'pleural fluid cell count','PLEU_cells',0),
(30,'other','OTHER',0),
(1,'acid fast bacilli smear microscopy','AFB_smear',645),
(2,'blood culture and sensitivity','Blood_C_S',37),
(3,'calcium and phosphate in serum','Ca_PO4',3),
(4,'CD4 immunology','CD4',26551),
(5,'cholesterine','Cholest',6),
(6,'creatinine','Creat',64),
(7,'cryptococcal antigen','Crypto_AG',142),
(8,'cerebrospinal fluid culture and sensitivity','CSF_C_S',39),
(9,'erythrocyte sedimentation rate','ESR',29),
(10,'full blood count','FBC',4729),
(11,'cerebrospinal fluid full analysis','CSF_full',567),
(12,'HIV viral load','HIV_viral_load',50),
(13,'cerebrospinal fluid microscopy india ink stain','CSF_indiaink',340),
(14,'lactate','Lactate',  219),
(15,'liver function tests','LFT',702),
(16,'malaria parasites','MP',2367),
(17,'urea and electolytes','U&E',809),
(18,'urine culture and sensitivity','Urine_C_S',97),
(19,'urine microscopy','Urine_micro',114),
(20,'syphilis serology','VDRL',195),
(21,'lipid profile','LIP',0),
(22,'amylase','AMYL',0),
(23,'hepatitis B serology','HEPB',0),
(24,'acid fast bacilli culture','AFB_culture',0),
(25,'white blood cell differential count','WBC_diff',0),
(26,'blood glucose','BLOOD_gluc',0),
(27,'cerebrospinal fluid glucose','CSF_gluc',0),
(28,'toxoplasmosis serology','TOXO',0),
(29,'pleural fluid cell count','PLEU_cells', 0),
(30,'other','OTHER',0),
(1,'acid fast bacilli smear microscopy','AFB_smear',645),
(2,'blood culture and sensitivity','Blood_C_S',37),
(3,'calcium and phosphate in serum','Ca_PO4',3),
(4,'CD4 immunology','CD4',26551),
(5,'cholesterine','Cholest',6),
(6,'creatinine','Creat',64),
(7,'cryptococcal antigen','Crypto_AG',142),
(8,'cerebrospinal fluid culture and sensitivity','CSF_C_S',39),
(9,'erythrocyte sedimentation rate','ESR',29),
(10,'full blood count','FBC',4729),
(11,'cerebrospinal fluid full analysis','CSF_full',567),
(12,'HIV viral load','HIV_viral_load',50),
(13,'cerebrospinal fluid microscopy india ink stain','CSF_indiaink',340),
(14,'lactate','Lactate',219),
(15,'liver function tests','LFT',702),
(16,'malaria parasites','MP',2367),
(17,'urea and electolytes','U&E', 809),
(18,'urine culture and sensitivity','Urine_C_S',97),
(19,'urine microscopy','Urine_micro',114),
(20,'syphilis serology','VDRL',195),
(21,'lipid profile','LIP',0),
(22,'amylase','AMYL',0),
(23,'hepatitis B serology','HEPB',0),
(24,'acid fast bacilli culture','AFB_culture',0),
(25,'white blood cell differential count','WBC_diff',0);
EOF

    ActiveRecord::Base.connection.execute <<EOF
UNLOCK TABLES;
EOF

    openmrs_db = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))[RAILS_ENV]
    ActiveRecord::Base.establish_connection(openmrs_db)

  end

  def self.down
    health_data = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['healthdata']
    ActiveRecord::Base.establish_connection(health_data)

    ActiveRecord::Base.connection.execute <<EOF
DROP DATABASE IF EXISTS healthdata;
EOF

    openmrs_db = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))[RAILS_ENV]
    ActiveRecord::Base.establish_connection(openmrs_db)
  end
end
