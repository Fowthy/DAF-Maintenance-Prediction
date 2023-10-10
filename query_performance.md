
Take the following grafana query:

```sql

WITH sources as (
  SELECT * FROM bfc_sources
  WHERE ID in (3)
),

BC AS (
  SELECT
    $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
    sources.BFC_CLIENT_ID as machine,
    AVG(DATAPOINT_B_Current) as B,
    AVG(DATAPOINT_C_Current) as C
  FROM
    DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
  WHERE
    $__timeFilter(data.BFC_TIMESTAMP) and
    data.BFC_SOURCE_ID IN (3,5,6)
  GROUP BY time, machine
  ORDER BY time
), 

XY AS (SELECT
  $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_X_Current) as X,
  AVG(DATAPOINT_Y_Current) as Y
FROM
  DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  $__timeFilter(data.BFC_TIMESTAMP) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

MAIN_UNION AS (
	(SELECT time, "B" as "As", machine, B as __value FROM BC)
)

SELECT *
FROM MAIN_UNION
ORDER BY time
```


1 sensor - multiple axes - multiple machines

```sql
CALL get_sensor_for_multiple_axes_multiple_machines(
  '["X"]',
  "Current",
  "3",
  "UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time",
  "data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669852800) AND FROM_UNIXTIME(1670352998)"
);
DROP PROCEDURE IF EXISTS get_sensor_for_multiple_axes_multiple_machines; 
DELIMITER //
CREATE PROCEDURE get_sensor_for_multiple_axes_multiple_machines(
    IN axes JSON,
    IN sensor TEXT,
    IN machines TEXT,
    IN time_group TEXT,
    IN time_filter TEXT
)
BEGIN
    DECLARE current_axis VARCHAR(255);
    DECLARE done INT DEFAULT FALSE;
    DECLARE cursor_i CURSOR FOR SELECT value FROM JSON_TABLE(axes, '$[*]' COLUMNS(
        value VARCHAR(255) PATH '$'
      )) AS jt;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_i;

    SET @_query = CONCAT(
        "WITH sources AS (SELECT * FROM bfc_sources WHERE ID in (", machines, ")), "
    );

    read_axis_loop: LOOP
        FETCH cursor_i INTO current_axis;
        IF done THEN
			LEAVE read_axis_loop;
        END IF;

        SET @axis_table_name := (
            SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME REGEXP CONCAT(current_axis, "_Axis")
        );

      SET @_query = CONCAT(
        @_query,
        "table_", current_axis, " AS (SELECT ",
        time_group, ", "
        "sources.BFC_CLIENT_ID as machine, ",
        "AVG(DATAPOINT_", current_axis ,"_", sensor, ") as ", current_axis, " ",
        "FROM ",
        @axis_table_name, " as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.id ",
        "WHERE ",
        time_filter,
        " AND data.BFC_SOURCE_ID IN (3) ",
        "GROUP BY time, machine ",
        "ORDER BY time), "
      );
      

        
    END LOOP;
    CLOSE cursor_i;
    
    SET @_query = CONCAT(
        @_query,
        "MAIN_UNION AS ( ",
        "(SELECT time, 'X' as 'As',machine, X as __value FROM table_X) ",
        ") ",
        "SELECT * FROM MAIN_UNION ORDER BY time"
	);
    
  PREPARE stmt FROM @_query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

END //
DELIMITER ;
```


----------------
```sql
DROP PROCEDURE IF EXISTS get_sensor_for_multiple_axes_multiple_machines; 
DELIMITER //
CREATE PROCEDURE get_sensor_for_multiple_axes_multiple_machines(
    IN axes JSON,
    IN sensor TEXT,
    IN machines TEXT,
    IN time_group TEXT,
    IN time_filter TEXT
)
BEGIN
    DECLARE current_axis VARCHAR(255);
    DECLARE done INT DEFAULT FALSE;
    DECLARE cursor_i CURSOR FOR SELECT value FROM JSON_TABLE(axes, '$[*]' COLUMNS(
        value VARCHAR(255) PATH '$'
      )) AS jt;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_i;

    SET @_query = CONCAT(
        "WITH sources AS (SELECT * FROM bfc_sources WHERE ID in (", machines, ")), "
    );

    read_axis_loop: LOOP
        FETCH cursor_i INTO current_axis;
        IF done THEN
			LEAVE read_axis_loop;
        END IF;

        SET @axis_table_name := (
            SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME REGEXP CONCAT(current_axis, "_Axis")
        );

      SET @_query = CONCAT(
        @_query,
        current_axis, " AS (SELECT ",
        time_group, ", "
        "sources.BFC_CLIENT_ID as machine, ",
        "AVG(DATAPOINT_", current_axis ,"_", sensor, ") as axis ",
        "FROM ",
        @axis_table_name, " as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.id ",
        "WHERE ",
        time_filter,
        " AND data.BFC_SOURCE_ID IN (3) ",
        "GROUP BY time, machine ",
        "ORDER BY time)"
      );
      

        
    END LOOP;
    CLOSE cursor_i;
    
    SET @_query = CONCAT(
        @_query,
        "MAIN_UNION AS ( ",
        "(SELECT time, 'X' as 'As',machine, X as __value FROM X) ",
        ") ",
        "SELECT * FROM MAIN_UNION ORDER BY time"
	);
    SELECT @_query;
    
--   PREPARE stmt FROM @_query;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;

END //
DELIMITER ;
```

CALL get_sensor_for_multiple_axes_multiple_machines(
  '["X"]',
  "Current",
  "3",
  "$__timeGroup(data.BFC_TIMESTAMP,$__interval) as time",
  "$__timeFilter(data.BFC_TIMESTAMP)"
)