# DAF Alerts

## DBexpansion

## Diagram

Image in the email.

## Epansion DDL

```sql
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

```

**The description columbs can be removed if not needed they where created if more information is needed**

## Population DML

**base population**

```sql
SET NAMES utf8mb4;

insert into `axis_source` (`axis_name`, `axis_dataset_table`) values
('x', 'dataset_x_axis_y_axis'),
('y', 'dataset_x_axis_y_axis'),
('z', 'dataset_a2_axis_z_axis'),
('w', 'dataset_w_axis_q1_axis'),
('q1', 'dataset_w_axis_q1_axis'),
('a1', 'dataset_a11_axis_a1_axis'),
('a2', 'dataset_a2_axis_z_axis'),
('a11', 'dataset_a11_axis_a1_axis'),
('b', 'dataset_c_axis_b_axis'),
('c', 'dataset_c_axis_b_axis');

insert into `sensor_source` (`sensor_name`, `sensor_description`) values
('Position', 'Sensor that tracks the position'),
('Speed', 'Sensor that tracks the speed'),
('Current', 'Sensor that tracks the current'),
('Torque', 'Sensor that tracks the torgue'),
('Motor_Temperature', 'Sensor that tracks the temperature of the motor'),
('PosDev', 'PosDev values'),
('Controldev', 'Controldev values'),
('Contourdev', 'Contourdev values'),
('Lag', 'The lag of the axis');

insert into `axis_sensor` (`axis_source_id`, `sensor_source_id`) values
('1', '1'),
('1', '2'),
('1', '3'),
('1', '4'),
('1', '5'),
('1', '6'),
('1', '7'),
('1', '8'),
('1', '9'),
('2', '1'),
('2', '2'),
('2', '3'),
('2', '4'),
('2', '5'),
('2', '6'),
('3', '1'),
('3', '2'),
('3', '3'),
('3', '4'),
('3', '5'),
('3', '6'),
('3', '7'),
('3', '8'),
('3', '9'),
('4', '1'),
('4', '2'),
('4', '3'),
('4', '4'),
('4', '5'),
('4', '6'),
('5', '1'),
('5', '2'),
('5', '3'),
('5', '4'),
('5', '5'),
('5', '6'),
('6', '1'),
('6', '2'),
('6', '3'),
('6', '4'),
('6', '5'),
('7', '1'),
('7', '2'),
('7', '3'),
('7', '4'),
('7', '5'),
('7', '6'),
('8', '1'),
('8', '2'),
('8', '3'),
('8', '4'),
('8', '5'),
('8', '6'),
('9', '1'),
('9', '2'),
('9', '3'),
('9', '4'),
('9', '5'),
('9', '6'),
('10', '1'),
('10', '2'),
('10', '3'),
('10', '4'),
('10', '5');

insert into `alarm_type` (`sensor_source_id`, `alarm_name`, `alarm_description`) values
('1', 'Min_Position', 'Alarm for when the minimum position has been passed'),
('1', 'Max_Position', 'Alarm for when the maximum position has been passed'),
('1', 'Mean_Position', 'Alarm for when the mean position has drifted'),
('1', 'Stdev_Position', 'Alarm for when the minimum position has been passed'),
('2', 'Mean_Speed', 'Alarm for when the mean speed has drifted'),
('3', 'Min_Current', 'Alarm for when the minimum current has been passed'),
('3', 'Max_Current', 'Alarm for when the maximum current has been passed'),
('3', 'Mean_Current', 'Alarm for when the mean current has drifted'),
('3', 'Stdev_Current', 'Alarm for when the minimum current has been passed'),
('4', 'Min_Torque', 'Alarm for when the minimum torque has been passed'),
('4', 'Max_Torque', 'Alarm for when the maximum torque has been passed'),
('4', 'Mean_Torque', 'Alarm for when the mean torque has drifted'),
('5', 'Max_Temperature', 'Alarm for when the maximum temperature has been passed'),
('6', 'Mean_PosDev', 'Alarm for when the mean PosDev has drifted'),
('6', 'Stdev_PosDev', 'Alarm for when the minimum PosDev has been passed'),
('7', 'Mean_Controldev', 'Alarm for when the mean controldev has drifted'),
('7', 'Stdev_Controldev', 'Alarm for when the minimum controldev has been passed'),
('8', 'Mean_Contourdev', 'Alarm for when the mean contourdev has drifted'),
('8', 'Stdev_Contourdev', 'Alarm for when the minimum contourdev has been passed'),
('9', 'Mean_Lag', 'Alarm for when the mean lag has drifted'),
('9', 'Stdev_Lag', 'Alarm for when the minimum lag has been passed');
```

**Dynamic population**

```sql
insert into `bfc_axis_sensor` (`bfc_source_id`, `axis_sensor_id`)
select 3, axis_sensor.id
from axis_sensor
where  axis_source_id in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

insert into `bfc_axis_sensor` (`bfc_source_id`, `axis_sensor_id`)
select 5, axis_sensor.id
from axis_sensor
where axis_source_id in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

insert into `bfc_axis_sensor` (`bfc_source_id`, `axis_sensor_id`)
select 6, axis_sensor.id
from axis_sensor
where axis_source_id in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

insert into `bfc_alarms_values` (`bfc_axis_sensor_id`, `alarm_type_id`, `alarm_value`)
select bfc_axis_sensor.id, alarm_type.id, 0
from alarm_type, bfc_axis_sensor inner join axis_sensor on bfc_axis_sensor.axis_sensor_id = axis_sensor.id
where axis_sensor.sensor_source_id = alarm_type.sensor_source_id ;
```

## Aleart value modification

We have created 2 versions of a stored prosidure that alows eassy flexible changes to the treshhold valuest. The first version is a bit faster and it uses the ID values to know what tresh hold is beeing changed. The second version is a bit slower but it uses the names instead of ID. Lastly the only two requered values are the new tresh hold value and the type of allarm. All other values can be null when calling in witch case you will change a broughder range of rows.

```sql
USE `daf_db`;
DROP procedure IF EXISTS `change_alert_values`;

DELIMITER //
CREATE PROCEDURE `change_alert_values` (in bfc_id bigint, in axis_id bigint, in sensor_id bigint, in alarm_value_new double, in alarm_name_in varchar(255))
BEGIN
START TRANSACTION;
	set bfc_id = nullif(bfc_id, '');
    set axis_id = nullif(axis_id, '');
    set sensor_id = nullif(sensor_id, '');
    
    update bfc_alarms_values
    set alarm_value = alarm_value_new
    where alarm_type_id in (select id 
				from alarm_type
				where (sensor_id is null or sensor_source_id = sensor_id)
				and alarm_name = alarm_name_in)
    and bfc_axis_sensor_id in (select bas.id 
								from bfc_axis_sensor as bas 
								inner join axis_sensor as sa on axis_sensor_id = sa.id
								where (bfc_id is null or bas.bfc_source_id = bfc_id)
								and (axis_id is null or sa.axis_source_id = axis_id)
								and (sensor_id is null or sensor_source_id = sensor_id));
COMMIT;
END //
DELIMITER ;
```

Example how the call works.

```sql
call change_alert_values (3, 1, 5, 70, 'Max_Temperature');
```

Second veriation

```sql
USE `daf_db`;
DROP procedure IF EXISTS `change_alert_values`;

DELIMITER //
CREATE PROCEDURE `change_alert_values` (in bfc_client varchar(255), in axis varchar(255), in sensor varchar(255), in alarm_value_new double, in alarm_name_in varchar(255))
BEGIN
START TRANSACTION;
	set bfc_client = nullif(bfc_client, '');
    set axis = nullif(axis, '');
    set sensor = nullif(sensor, '');
    
    update bfc_alarms_values
    set alarm_value = alarm_value_new
    where alarm_type_id in (select alarm_type.id 
				from alarm_type
                inner join sensor_source as sen on sen.id = alarm_type.sensor_source_id
				where (sensor is null or sen.sensor_name = sensor)
				and alarm_name = alarm_name_in)
    and bfc_axis_sensor_id in (select bas.id 
								from bfc_axis_sensor as bas 
								inner join axis_sensor as sa on bas.axis_sensor_id = sa.id
                                inner join axis_source as axi on sa.axis_source_id = axi.id
                                inner join sensor_source as sen on sa.sensor_source_id = sen.id
                                inner join bfc_sources as bfc on bfc.id = bas.bfc_source_id
								where (bfc_client is null or bfc.BFC_CLIENT_ID = bfc_client)
								and (axis is null or axi.axis_name = axis)
								and (sensor is null or sen.sensor_name = sensor));
COMMIT;
END //
DELIMITER ;
```

Example how the call works.

```sql
call change_alert_values ('M22838', 'x', 'Motor_Temperature', 75, 'Max_Temperature');
```


**That's a flexible query for selecting multiple or one bfc_source values and, 
as well as selecting several or one sensor_values and axis values that are passed to the query
!The queries below are based on the new ERD diagram**

## Examples of the titles on the alarms id's
### Alarm_Type
- id:1 , Min_Position
- id:2 , Max_Position
- id:3 , Mean_Postion
- id:4 , Stdev_Position
- id:5 , Mean_Speed
- id:6 , Min_Current
- id:7 , Max_Current
- id:8 , Mean_Current
- id:9 , Stdev_Current
- id:10 , Min_Torque
- id:11 , Max_Torque
- id:12 , Mean_Torque
- id:13 , Max_Temperature
- id:14 , Mean_PosDev
- id:15 , Stdev_PosDev
- id:16 , Mean_Controldev
- id:17 , Stdev_Controldev
- id:18 , Mean_Contourdev
- id:19 , Stdev_Contourdev
- id:20 , Mean_Lag
- id:21 , Stdev_Lag

### Sensor_Source
- id:1 , Position , Sensor that tracks the position
- id:2 , Speed , Sensor that tracks the speed
- id:3 , Current , Sensor that tracks the current
- id:4 , Torque      , Sensor that tracks the torgue
- id:5 ,    Motor_Temperature   , Sensor that tracks the temperature of the motor
- id:6 ,  PosDev     , Position Deviation values
- id:7 ,   Controldev    , Controldev values
- id:8 ,    Contourdev   , Contourdev values
- id:9 ,   Lag    , The lag of the axis

### Axis_Source
- id:1 , x , dataset_x_axis_y_axis
- id:2 , y , dataset_x_axis_y_axis
- id:3 , z , dataset_a2_axis_z_axis
- id:4 , w , dataset_w_axis_q1_axis
- id:5 , q1 , dataset_w_axis_q1_axis
- id:6 , a1 , dataset_a11_axis_a1_axis
- id:7 , a2 , dataset_a2_axis_z_axis
- id:8 , a11 , dataset_a11_axis_a1_axis
- id:9 , b , dataset_c_axis_b_axis
- id:10 , c , dataset_c_axis_b_axis


**Flexible query - prepared statement for concat bfc_timestamp**

```sql
select axis_dataset_table into @table_name
from axis_source 
where id = 1;	

set @query = CONCAT('SELECT BFC_TIMESTAMP FROM ', @table_name);

PREPARE stmt FROM @query;
EXECUTE stmt;
```

**Storred procedure that takes a list of values for alarm type, machine source, axis source and sensor source**

```sql
CREATE TYPE dbo.IntList AS TABLE (Value INT);

CREATE PROCEDURE GetAlarmData
  @alarmTypeIds dbo.IntList READONLY,
  @bfcSourceIds dbo.IntList READONLY,
  @axisSourceIds dbo.IntList READONLY,
  @sensorSourceIds dbo.IntList READONLY
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    $__timeGroup(<certain-timeStamp>, 180s) AS time,
    bfc_axis_sensor.bfc_source_id AS machine,
    bfc_alarms_values.alarm_value AS alarm_value,
    alarm_type.alarm_name AS alarm_name,
    alarm_type.description AS alarm_description
  FROM
    bfc_source
    JOIN bfc_axis_sensor ON bfc_source.id = bfc_axis_sensor.bfc_source_id
    JOIN bfc_alarms_values ON bfc_axis_sensor.id = bfc_alarms_values.bfc_axis_sensor_id
    JOIN alarm_type ON bfc_alarms_values.alarm_type_id = alarm_type.id
    JOIN axis_sensor ON bfc_axis_sensor.axis_sensor_id = axis_sensor.id
    JOIN axis_source ON axis_sensor.axis_source = axis_source.id
    JOIN sensor_source ON axis_sensor.sensor_source_id = sensor_source.id
  WHERE
    $__timeFilter(<certain-timeStamp>)
    AND alarm_type.id IN (SELECT Value FROM @alarmTypeIds)
    AND bfc_source.id IN (SELECT Value FROM @bfcSourceIds)
    AND axis_sensor.axis_source_id IN (SELECT Value FROM @axisSourceIds)
    AND axis_sensor.sensor_source_id IN (SELECT Value FROM @sensorSourceIds);
END;
```

**To execute the stored procedure**

```sql
DECLARE @alarmTypes dbo.IntList;
DECLARE @bfcSources dbo.IntList;
DECLARE @axisSources dbo.IntList;
DECLARE @sensorSources dbo.IntList;

INSERT INTO @alarmTypes (Value) VALUES (1), (2), (3); -- Example values for alarm type IDs
INSERT INTO @bfcSources (Value) VALUES (1), (2), (3); -- Example values for bfc source IDs
INSERT INTO @axisSources (Value) VALUES (1), (2), (3); -- Example values for axis source IDs
INSERT INTO @sensorSources (Value) VALUES (1), (2), (3); -- Example values for sensor source IDs

EXEC GetAlarmData
  @alarmTypeIds = @alarmTypes,
  @bfcSourceIds = @bfcSources,
  @axisSourceIds = @axisSources,
  @sensorSourceIds = @sensorSources;
  ```