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