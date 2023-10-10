update  bfc_alarms_values
set alarm_value = 70
where alarm_type_id in (select id
						from alarm_type
						where alarm_name = 'Max_Temperature');