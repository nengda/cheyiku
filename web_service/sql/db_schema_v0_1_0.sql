drop table if exists settings;
drop table if exists cyc_session;
drop table if exists cyc_service_interest;
drop table if exists cyc_service;
drop table if exists cyc_client;
drop table if exists cyc_promoter;
drop table if exists cyc_user;
drop table if exists cyc_car;
drop table if exists cyc_profession;
drop table if exists cyc_district;

CREATE TABLE `settings` (
  `name` varchar(255) NOT NULL,
  `value` varchar(1000),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB;

CREATE TABLE `cyc_user` (
  `email` varchar(255) NOT NULL PRIMARY KEY,
  `full_name` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `is_admin` TINYINT NOT NULL,
  `is_deleted` TINYINT NOT NULL,
  `create_timestamp` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_promoter` (
  `id` char(8) NOT NULL PRIMARY KEY,
  `full_name` varchar(255) NOT NULL,
  `club` varchar(255),
  `sex` char(1),
  `email` varchar(255) NOT NULL,
  `mobile_number` varchar(255) NOT NULL,
  `description` varchar(1024),
  `create_timestamp` datetime NOT NULL,
  `update_timestamp` datetime NOT NULL,
  `is_deleted` TINYINT NOT NULL,
  `created_by` varchar(255) NOT NULL,
  CONSTRAINT FOREIGN KEY (created_by) REFERENCES cyc_user(email)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_car` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `brand` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  INDEX `brand` (brand)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_profession` (
  `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_district` (
  `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_client` (
  `id` char(10) NOT NULL PRIMARY KEY,
  `promoter_id` char(8),
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `mobile_number` varchar(255) NOT NULL,
  `sex` char(1) CHARACTER SET ascii NOT NULL,
  `car_id` SMALLINT UNSIGNED NOT NULL,
  `profession_id` TINYINT UNSIGNED NOT NULL,
  `district_id` TINYINT UNSIGNED NOT NULL,
  `license` varchar(255) NOT NULL,
  `year_of_purchase` char(4) CHARACTER SET ascii NOT NULL,
  `mileage` varchar(255) NOT NULL,
  `is_deleted` TINYINT NOT NULL,
  `has_come` TINYINT NOT NULL,
  `create_timestamp` datetime NOT NULL,
  `update_timestamp` datetime NOT NULL,
  INDEX `promoter_id` (promoter_id)
  CONSTRAINT FOREIGN KEY (district_id) REFERENCES cyc_district(id),
  CONSTRAINT FOREIGN KEY (car_id) REFERENCES cyc_car(id),
  CONSTRAINT FOREIGN KEY (profession_id) REFERENCES cyc_profession(id)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_service` (
  `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_service_interest` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `service_id` TINYINT UNSIGNED NOT NULL,
  `client_id` char(10) NOT NULL,
  CONSTRAINT FOREIGN KEY (service_id) REFERENCES cyc_service(id),
  CONSTRAINT FOREIGN KEY (client_id) REFERENCES cyc_client(id)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `cyc_session` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_email` varchar(255) NOT NULL,
  `ip` char(15) NOT NULL,
  `checksum` char(40) CHARACTER SET ascii NOT NULL,
  `create_timestamp` datetime NOT NULL,
  CONSTRAINT FOREIGN KEY (user_email) REFERENCES cyc_user(email)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;


INSERT INTO `cyc_profession` (name) VALUES ('计算机/IT/互联网/电子商务');
INSERT INTO `cyc_profession` (name) VALUES ('高级管理');
INSERT INTO `cyc_profession` (name) VALUES ('人力资源');
INSERT INTO `cyc_profession` (name) VALUES ('销售');
INSERT INTO `cyc_profession` (name) VALUES ('客服及技术支持');
INSERT INTO `cyc_profession` (name) VALUES ('财务/审计/税务');
INSERT INTO `cyc_profession` (name) VALUES ('市场/营销');
INSERT INTO `cyc_profession` (name) VALUES ('生产/营运');
INSERT INTO `cyc_profession` (name) VALUES ('行政/后勤');
INSERT INTO `cyc_profession` (name) VALUES ('通信技术开发及应用');
INSERT INTO `cyc_profession` (name) VALUES ('银行金融/证券/期货/投资');
INSERT INTO `cyc_profession` (name) VALUES ('贸易/进出口');
INSERT INTO `cyc_profession` (name) VALUES ('机械/模具/工程/能源');
INSERT INTO `cyc_profession` (name) VALUES ('汽车');
INSERT INTO `cyc_profession` (name) VALUES ('建筑/监理/施工/市政建设');
INSERT INTO `cyc_profession` (name) VALUES ('房地产');
INSERT INTO `cyc_profession` (name) VALUES ('物业管理');
INSERT INTO `cyc_profession` (name) VALUES ('医疗生物/制药/医疗器械');
INSERT INTO `cyc_profession` (name) VALUES ('印刷/包装/造纸');
INSERT INTO `cyc_profession` (name) VALUES ('酒店/旅游');
INSERT INTO `cyc_profession` (name) VALUES ('餐饮/娱乐');
INSERT INTO `cyc_profession` (name) VALUES ('化工');
INSERT INTO `cyc_profession` (name) VALUES ('服装/纺织');
INSERT INTO `cyc_profession` (name) VALUES ('教育');
INSERT INTO `cyc_profession` (name) VALUES ('美容/美发/保健/体育');
INSERT INTO `cyc_profession` (name) VALUES ('照明');
INSERT INTO `cyc_profession` (name) VALUES ('矿产/地质勘查/冶金');
INSERT INTO `cyc_profession` (name) VALUES ('造船');
INSERT INTO `cyc_profession` (name) VALUES ('交通运输服务');
INSERT INTO `cyc_profession` (name) VALUES ('物流/仓储');
INSERT INTO `cyc_profession` (name) VALUES ('电力/电源');
INSERT INTO `cyc_profession` (name) VALUES ('艺术/设计');
INSERT INTO `cyc_profession` (name) VALUES ('百货/连锁/零售服务');
INSERT INTO `cyc_profession` (name) VALUES ('律师/法务/合规');
INSERT INTO `cyc_profession` (name) VALUES ('技工');
INSERT INTO `cyc_profession` (name) VALUES ('采购');
INSERT INTO `cyc_profession` (name) VALUES ('翻译');
INSERT INTO `cyc_profession` (name) VALUES ('环保/节能');
INSERT INTO `cyc_profession` (name) VALUES ('农业/养殖');
INSERT INTO `cyc_profession` (name) VALUES ('其它');

INSERT INTO `cyc_district` (name) VALUES ('宝山');
INSERT INTO `cyc_district` (name) VALUES ('黄浦');
INSERT INTO `cyc_district` (name) VALUES ('卢湾');
INSERT INTO `cyc_district` (name) VALUES ('徐汇');
INSERT INTO `cyc_district` (name) VALUES ('长宁');
INSERT INTO `cyc_district` (name) VALUES ('静安');
INSERT INTO `cyc_district` (name) VALUES ('普陀');
INSERT INTO `cyc_district` (name) VALUES ('闸北');
INSERT INTO `cyc_district` (name) VALUES ('虹口');
INSERT INTO `cyc_district` (name) VALUES ('杨浦');
INSERT INTO `cyc_district` (name) VALUES ('闵行');
INSERT INTO `cyc_district` (name) VALUES ('嘉定');
INSERT INTO `cyc_district` (name) VALUES ('浦东新区');
INSERT INTO `cyc_district` (name) VALUES ('金山');
INSERT INTO `cyc_district` (name) VALUES ('松江');
INSERT INTO `cyc_district` (name) VALUES ('青浦');
INSERT INTO `cyc_district` (name) VALUES ('南汇');
INSERT INTO `cyc_district` (name) VALUES ('奉贤');

INSERT INTO `cyc_service` (name) VALUES ('常规美容保养');
INSERT INTO `cyc_service` (name) VALUES ('博朗镀膜');
INSERT INTO `cyc_service` (name) VALUES ('伍尔特底盘装甲');
INSERT INTO `cyc_service` (name) VALUES ('艾丽车身改色膜');
INSERT INTO `cyc_service` (name) VALUES ('全车拉花');
INSERT INTO `cyc_service` (name) VALUES ('电控系统改装');
INSERT INTO `cyc_service` (name) VALUES ('底盘件升级');
INSERT INTO `cyc_service` (name) VALUES ('外观改装');
INSERT INTO `cyc_service` (name) VALUES ('经排气系统改装');
INSERT INTO `cyc_service` (name) VALUES ('轮胎轮毂升级');
INSERT INTO `cyc_service` (name) VALUES ('内饰部件');
INSERT INTO `cyc_service` (name) VALUES ('电子装备');

INSERT INTO `cyc_car` (brand, model) VALUES ('奥迪', '奥迪R8');
INSERT INTO `cyc_car` (brand, model) VALUES ('奥迪', '奥迪A2');
INSERT INTO `cyc_car` (brand, model) VALUES ('奥迪', '奥迪A3');
INSERT INTO `cyc_car` (brand, model) VALUES ('奥迪', '奥迪R8-敞篷');
INSERT INTO `cyc_car` (brand, model) VALUES ('宝马', '宝马5系-进口');
INSERT INTO `cyc_car` (brand, model) VALUES ('宝马', '宝马Active E');
INSERT INTO `cyc_car` (brand, model) VALUES ('宝马', '宝马Z2');
INSERT INTO `cyc_car` (brand, model) VALUES ('华晨宝马', '宝马5系');
INSERT INTO `cyc_car` (brand, model) VALUES ('奔驰', '奔驰G级');
INSERT INTO `cyc_car` (brand, model) VALUES ('奔驰', '奔驰CLK');

INSERT INTO cyc_user (full_name, email, password, is_admin, create_timestamp) VALUES ('测试管理员', 'nengda.jin@gmail.com', '8cb2237d0679ca88db6464eac60da96345513964', 1, now());
INSERT INTO cyc_user (full_name, email, password, is_admin, create_timestamp) VALUES ('测试用户', 'jeockk@gmail.com', '8cb2237d0679ca88db6464eac60da96345513964', 0, now());

