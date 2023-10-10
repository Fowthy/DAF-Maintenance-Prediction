# Flexible Query Version 5.1

```sql
DROP PROCEDURE IF EXISTS get_axis_for_query;
DELIMITER //
CREATE PROCEDURE get_axis_for_query(
    IN axes JSON,
    IN query_no INT,
    OUT current_axis VARCHAR(255),
    OUT twin_axis VARCHAR(255),
	OUT leave_procedure INT

)
this_procedure:
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE axis VARCHAR(255);
    DECLARE done INT DEFAULT FALSE;
    DECLARE cursor_i CURSOR FOR SELECT value
                                FROM JSON_TABLE(axes, '$[*]' COLUMNS (
                                    value VARCHAR(255) PATH '$'
                                    )) AS jt;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_i;

    SET @axis_count = JSON_LENGTH(axes);
    IF query_no > @axis_count THEN
        SET leave_procedure = 1;
        LEAVE this_procedure;
    END IF;

    SET @cursor_index = 0;

    read_axis_loop:
    LOOP
        FETCH cursor_i INTO current_axis;
        IF done THEN
            LEAVE read_axis_loop;
        END IF;

        SET @cursor_index = @cursor_index + 1;

        IF @cursor_index < query_no THEN
            ITERATE read_axis_loop;
        ELSE
            LEAVE read_axis_loop;
        END IF;
    END LOOP;

    CLOSE cursor_i;

    SET @axis_table_name := (SELECT TABLE_NAME
                             FROM INFORMATION_SCHEMA.TABLES
                             WHERE TABLE_NAME REGEXP CONCAT(current_axis, "_Axis"));

    SET twin_axis = REGEXP_REPLACE(@axis_table_name, "DATASET_(.+)_Axis_(.+)_Axis", "$1");
    IF twin_axis = current_axis THEN
        SET twin_axis = REGEXP_REPLACE(@axis_table_name, "DATASET_(.+)_Axis_(.+)_Axis", "$2");
    END IF;
END //
DELIMITER ;

/* generate_sensor_columns_and_main_union_selections
 This stored procedure generates the sensor columns and main union selections.
 */

DROP PROCEDURE IF EXISTS generate_sensor_columns_and_main_union_selections;
DELIMITER //

CREATE PROCEDURE generate_sensor_columns_and_main_union_selections(
    IN axes JSON,
    IN sensors JSON,
    IN current_axis VARCHAR(255),
    IN twin_axis VARCHAR(255),
    IN func TEXT,
    OUT sensor_columns TEXT,
    OUT main_union_selections TEXT
)
this_procedure:
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    DECLARE axis VARCHAR(255);
    DECLARE sensor VARCHAR(255);

    SET sensor_columns := ''; -- Initialize sensor_columns with an empty string
    SET main_union_selections := ''; -- Initialize main_union_selections with an empty string

    SET @axis_array := JSON_ARRAY(current_axis);

    IF LOCATE(CONCAT('"', twin_axis, '"'), axes) THEN
        SET @twin_axis_position = LOCATE(CONCAT('"', twin_axis, '"'), axes);
        SET @cursor_index = LOCATE(CONCAT('"', current_axis, '"'), axes);

        IF @cursor_index > @twin_axis_position THEN
            LEAVE this_procedure;
        ELSE
            SET @axis_array := JSON_ARRAY(current_axis, twin_axis);
        END IF;
    END IF;

    WHILE i < JSON_LENGTH(@axis_array) DO
        SET axis = JSON_EXTRACT(@axis_array, CONCAT('$[', i, ']'));
        SET j = 0;
        WHILE j < JSON_LENGTH(sensors) DO
            SET sensor = JSON_EXTRACT(sensors, CONCAT('$[', j, ']'));
            SET sensor_columns = CONCAT(
                sensor_columns,
                func, '(DATAPOINT_', REPLACE(axis, '"', ''), '_',
                REPLACE(sensor, '"', ''), ') as ', REPLACE(axis, '"', ''), '_',
                REPLACE(sensor, '"', ''), ','
            );
            SET main_union_selections = CONCAT(
                main_union_selections,
                "(SELECT time, '", REPLACE(axis, '"', ''), '_', REPLACE(sensor, '"', ''),
                "' as 'As', CONVERT(machine, CHAR) as machine, ", REPLACE(axis, '"', ''), '_', REPLACE(sensor, '"', ''),
                " as __value FROM table_",
                current_axis, twin_axis, ") UNION ALL "
            );
            SET j = j + 1;
        END WHILE;
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

/* generate_table_for_current_and_twin_axes
This stored procedure generates the table clause for the current and twin axes based on the provided parameters.
*/

DROP PROCEDURE IF EXISTS generate_table_for_current_and_twin_axes;
DELIMITER //
CREATE PROCEDURE generate_table_for_current_and_twin_axes(
    IN machines TEXT,
    IN time_group TEXT,
    IN time_filter TEXT,
    IN current_axis VARCHAR(255),
    IN twin_axis VARCHAR(255),
    IN sensor_columns TEXT,
    OUT table_clause TEXT
)
BEGIN
    SET table_clause = CONCAT(
            "table_", current_axis, twin_axis, " AS (SELECT ",
            sensor_columns,
            " BFC_SOURCE_ID as machine, ",
            time_group,
            " FROM ",
            @axis_table_name, " as data"
            " WHERE ",
            time_filter,
            " AND data.BFC_SOURCE_ID IN (", machines, ") ",
            "GROUP BY time, BFC_SOURCE_ID), "
        );
END //
DELIMITER ;

/* get_multiple_sensors_for_multiple_axes_multiple_machines_v5
 This is the main stored procedure that retrieves multiple sensors for multiple axes and multiple machines based on the provided parameters.
*/

DROP PROCEDURE IF EXISTS get_multiple_sensors_for_multiple_axes_multiple_machines_v5_1;
DELIMITER //
CREATE PROCEDURE get_multiple_sensors_for_multiple_axes_multiple_machines_v5_1(
    /* Set parameters */
    IN axes JSON,
    IN sensors JSON,
    IN machines TEXT,
    IN func TEXT,
    IN time_group TEXT,
    IN time_filter TEXT,
    IN query_no INT
)
this_procedure:
BEGIN
    DECLARE current_axis VARCHAR(255);
    DECLARE twin_axis VARCHAR(255);
    DECLARE sensor_columns TEXT DEFAULT '';
    DECLARE main_union_selections TEXT DEFAULT '';
    DECLARE leave_procedure_completely INT DEFAULT 0;

    /* Call the first stored procedure to get the axis for the query */
    CALL get_axis_for_query(axes, query_no, current_axis, twin_axis, leave_procedure_completely);
    
    /* If leave the get_axis_for_query, don't continue */
	IF leave_procedure_completely > 0 THEN
		LEAVE this_procedure;
        END IF;

    /* Call the second stored procedure to generate sensor columns and main union selections */
    CALL generate_sensor_columns_and_main_union_selections(axes, sensors, current_axis, twin_axis, func, sensor_columns, main_union_selections);
   --  SELECT axes, sensors, current_axis, main_union_selections;
    /* Construct the final query */
     SET @_query = CONCAT(
        "WITH ",
        "table_", current_axis, twin_axis, " AS (SELECT ",
        sensor_columns,
        " BFC_SOURCE_ID as machine, ",
        time_group,
        " FROM DATASET_", current_axis, "_Axis_", twin_axis, "_Axis as data"
        " WHERE ",
        time_filter,
        " AND data.BFC_SOURCE_ID IN (", machines, ") ",
        "GROUP BY time, BFC_SOURCE_ID), "
    );

    SET @_query = CONCAT(
        @_query,
        "MAIN_UNION AS ( ",
        SUBSTRING(main_union_selections, 1, LENGTH(main_union_selections) - 10),
        ") ",
        "SELECT time, `As`, __value, BFC_CLIENT_ID FROM MAIN_UNION INNER JOIN bfc_sources on MAIN_UNION.machine = bfc_sources.ID ORDER BY time"
    );
    /* Execute the final query */
    PREPARE stmt FROM @_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

```

The first function is getting the axis for the query.

The generate_sensor_columns_and_main_union_selections function is generating the sensor columns and main union selections. The query looks like this:

```sql

(SELECT time, \'A11_Position\' as \'As\', CONVERT(machine, CHAR) as machine, A11_Position as __value FROM table_A11A1) UNION ALL (SELECT time, \'A1_Position\' as \'As\', CONVERT(machine, CHAR) as machine, A1_Position as __value FROM table_A11A1) UNION ALL

```

The final function is constructing the following query:

```sql
WITH table_A11A1 AS (
  SELECT
    AVG(DATAPOINT_A11_Position) AS A11_Position,
    AVG(DATAPOINT_A1_Position) AS A1_Position,
    BFC_SOURCE_ID AS machine,
    UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 900 * 900 AS time
  FROM
    DATASET_A11_Axis_A1_Axis AS data
  WHERE
    data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669676400) AND FROM_UNIXTIME(1670367598)
    AND data.BFC_SOURCE_ID IN (3)
  GROUP BY
    time, BFC_SOURCE_ID
),
MAIN_UNION AS (
  (SELECT
    time, 'A11_Position' AS 'As', CONVERT(machine, char) AS machine, A11_Position AS __value
  FROM
    table_A11A1)
  UNION ALL
  (SELECT
    time, 'A1_Position' AS 'As', CONVERT(machine, char) AS machine, A1_Position AS __value
  FROM
    table_A11A1)
)
SELECT
  *
FROM
  MAIN_UNION
ORDER BY
  time;
```

