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

