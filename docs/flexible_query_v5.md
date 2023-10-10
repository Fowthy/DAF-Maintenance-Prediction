```sql
DROP PROCEDURE IF EXISTS get_multiple_sensors_for_multiple_axes_multiple_machines_v6;
DELIMITER //
CREATE PROCEDURE get_multiple_sensors_for_multiple_axes_multiple_machines_v6(
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
    DECLARE i INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    DECLARE sensor_columns TEXT DEFAULT '';
    DECLARE main_union_selections TEXT DEFAULT '';
    DECLARE axis VARCHAR(255);
    DECLARE sensor VARCHAR(255);

    /* Holds current axis that is being iterated over. */
    DECLARE current_axis VARCHAR(255);
    /* Describes whether iterating over the axes is done. */
    DECLARE done INT DEFAULT FALSE;
    /*
    Transform provided axes JSON array to a table of one column with many rows.
    For example, if ["X", "C", "Z"] is provided as axes, the cursor will iterate over this table:
    +-----+
    |value|
    +-----+
    |X    |
    |C    |
    |Z    |
    +-----+
    */
    DECLARE cursor_i CURSOR FOR SELECT value
                                FROM JSON_TABLE(axes, '$[*]' COLUMNS (
                                    value VARCHAR(255) PATH '$'
                                    )) AS jt;
    /* Set `done` to `TRUE` when the loop is over (there are no more rows to loop over). */
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_i;

    /*
    If the query number is bigger than the amount of axes passed, exit the procedure. We do not need that query.
    */
    SET @axis_count = JSON_LENGTH(axes);
    IF query_no > @axis_count THEN
        LEAVE this_procedure;
    END IF;

    /* Stores tore the final query that is executed from the procedure. */
    SET @_query = CONCAT(
#            "WITH sources AS (SELECT ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in (", machines, ")), "
            "WITH "
        );

    SET @cursor_index = 0;

    /*
    Loop over the axis until we land on the one this query should be responsible for.
    For example, if the axes are ["X", "B", "Q"] and the query number is 2, the loop will set `current_axis` to "B".
    This means that this query is responsible for retrieving data for the "B" axis and (if provided) its twin axis.
    */
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

    /* Close cursor iterating over axes. */
    CLOSE cursor_i;

    /* Find table name for the current axis. For example `DATASET_X_Axis_Y_Axis`. */
    SET @axis_table_name := (SELECT TABLE_NAME
                             FROM INFORMATION_SCHEMA.TABLES
                             WHERE TABLE_NAME REGEXP CONCAT(current_axis, "_Axis"));

    /* Derive the twin axis name from the table name. */
    SET @twin_axis = REGEXP_REPLACE(@axis_table_name, "DATASET_(.+)_Axis_(.+)_Axis", "$1");
    IF @twin_axis = current_axis THEN
        SET @twin_axis = REGEXP_REPLACE(@axis_table_name, "DATASET_(.+)_Axis_(.+)_Axis", "$2");
    END IF;

    /* Stores the main union. */
    SET @main_union = "";

    SET @axis_array := JSON_ARRAY(current_axis);


    /* If twin axis is also in the selected axes. */
    IF LOCATE(CONCAT("\"", @twin_axis, "\""), axes) THEN
        SET @twin_axis_position = LOCATE(CONCAT("\"", @twin_axis, "\""), axes);
        SET @cursor_index = LOCATE(CONCAT("\"", current_axis, "\""), axes);
        /*
        If current axis is after its twin axis, abort procedure and leave it up to the other query to take care of both
        axes. For example, since X and Y are in a single table, if the axes ["X", "Y"] are provided, the query for Y
        will abort and leave it up to the query for X to take care of both axes.
        Else add the twin axis to the selected columns and main union.
        */
        IF @cursor_index > @twin_axis_position THEN
            LEAVE this_procedure;
        ELSE
            SET @axis_array := JSON_ARRAY(current_axis, @twin_axis);
        END IF;
    END IF;


    WHILE i < JSON_LENGTH(@axis_array)
        DO
            SET axis = JSON_EXTRACT(@axis_array, CONCAT('$[', i, ']'));
            SET j = 0;
            WHILE j < JSON_LENGTH(sensors)
                DO
                    SET sensor = JSON_EXTRACT(sensors, CONCAT('$[', j, ']'));
                    SET sensor_columns = CONCAT(sensor_columns, func,'(DATAPOINT_', REPLACE(axis, '"', ''), '_',
                                                REPLACE(sensor, '"', ''), ') as ', REPLACE(axis, '"', ''), '_',
                                                REPLACE(sensor, '"', ''), ',');
                    SET main_union_selections = CONCAT(
                            main_union_selections,
                            "(SELECT time, '", REPLACE(axis, '"', ''), '_', REPLACE(sensor, '"', ''),
                            "' as 'As', CONVERT(machine,char) as machine, ", REPLACE(axis, '"', ''), '_', REPLACE(sensor, '"', ''),
                            " as __value FROM table_",
                            current_axis, @twin_axis, ") UNION ALL "
                        );
                    SET j = j + 1;
                END WHILE;
            SET i = i + 1;
        END WHILE;

    /* Construct query for selected axes, sensor, machine(s) and time range. */
    SET @_query = CONCAT(
            @_query,
            "table_", current_axis, @twin_axis, " AS (SELECT ",
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


    /* Build the final query. */
    SET @_query = CONCAT(
            @_query,
            "MAIN_UNION AS ( ",
            SUBSTRING(main_union_selections, 1, LENGTH(main_union_selections) - 10),
            ") ",
            "SELECT time, `As`, __value, BFC_CLIENT_ID FROM MAIN_UNION INNER JOIN bfc_sources on MAIN_UNION.machine = bfc_sources.ID ORDER BY time"
        );


    /* Execute the final query. */
    PREPARE stmt FROM @_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;
```