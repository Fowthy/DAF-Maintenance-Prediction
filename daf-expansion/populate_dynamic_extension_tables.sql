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