drop table if exists settings;

CREATE TABLE `settings` (
  `name` varchar(255) NOT NULL,
  `value` varchar(1000),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB;
