SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;

SET NAMES utf8mb4;

DROP TABLE IF EXISTS `axis_source`;
create table `axis_source`(
	`id` bigint not null auto_increment,
	`axis_name` varchar(255) not null,
    `axis_dataset_table` varchar(255) not null,
	PRIMARY KEY (`ID`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
DROP TABLE IF EXISTS `sensor_source`;

DROP TABLE IF EXISTS `sensor_source`;
create table `sensor_source`(
	`id` bigint not null auto_increment,
	`sensor_name` varchar(255) not null,
	`sensor_description` text not null,
	PRIMARY KEY (`ID`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `axis_sensor`;
create table `axis_sensor`(
	`id` bigint not null auto_increment,
    `axis_source_id` bigint not null,
	`sensor_source_id` bigint not null,
	PRIMARY KEY (`ID`),
    CONSTRAINT `sensor_axis_ibfk_1` foreign key(`sensor_source_id`) REFERENCES `sensor_source` (`id`) ON DELETE CASCADE,
    CONSTRAINT `sensor_axis_ibfk_2` foreign key(`axis_source_id`) REFERENCES `axis_source` (`id`) ON DELETE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `bfc_axis_sensor`;
create table `bfc_axis_sensor`(
	`id` bigint not null auto_increment,
	`bfc_source_id` bigint not null,
	`axis_sensor_id` bigint not null,
	PRIMARY KEY (`ID`),
    CONSTRAINT `bfc_axis_sensor_ibfk_1` foreign key(`bfc_source_id`) REFERENCES `bfc_sources` (`id`) ON DELETE CASCADE,
    CONSTRAINT `bfc_axis_sensor_ibfk_2` foreign key(`axis_sensor_id`) REFERENCES `axis_sensor` (`id`) ON DELETE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `alarm_type`;
create table `alarm_type`(
	`id` bigint not null auto_increment,
	`sensor_source_id` bigint not null,
	`alarm_name`  varchar(255) not null,
    `alarm_description` text not null,
	PRIMARY KEY (`ID`),
    CONSTRAINT `alarm_type_ibfk_1` foreign key(`sensor_source_id`) REFERENCES `sensor_source` (`id`) ON DELETE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP TABLE IF EXISTS `bfc_alarms_values`;
create table `bfc_alarms_values`(
	`id` bigint not null auto_increment,
	`bfc_axis_sensor_id` bigint not null,
	`alarm_type_id` bigint not null,
    `alarm_value` double not null,
	PRIMARY KEY (`ID`),
    CONSTRAINT `bfc_alarms_values_ibfk_1` foreign key(`bfc_axis_sensor_id`) REFERENCES `bfc_axis_sensor` (`id`) ON DELETE CASCADE,
    CONSTRAINT `bfc_alarms_values_ibfk_2` foreign key(`alarm_type_id`) REFERENCES `alarm_type` (`id`) ON DELETE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;




