# Flexible query

This query is the exact same one that you provided us to look into. Since we believe it is as good
as it gets (in terms of performance) with the current knowledge we have, we have made it more
usable.

Please make a separate dashboard so it does not interfere with your current setup.

## Variables

### Machine

Go to `Dashboard settings` -> `Variables` -> `Add variable` and use the following settings:
- **Variable type**: `Query`
- **Name**: `machines`
- **Query**:

    ```sql
    /*
    Select all bfc sources which are an `iotclient`.

    `__text` will be the value the user sees in the dropdown and `__value` is the value that Grafana
    will pass to the queries when using this variable.

    +----------+-------+
    |__text    |__value|
    +----------+-------+
    |45kvdyex3r|316    |
    |M19408    |373    |
    |M22837    |6      |
    |M22838    |3      |
    |M23098    |5      |
    +----------+-------+

    */
    SELECT
        BFC_CLIENT_ID as __text,
        ID as __value
    FROM bfc_sources
    WHERE BFC_APPLICATION_TYPE = "iotclient"
    ```
- **Multi-value**: `Checked`

`Run query` and make sure the preview of values is there: `45kvdyex3r` `M19408` `M22837` `M22838`
`M23098`

### Axis

Go to `Dashboard settings` -> `Variables` -> `Add variable` and use the following settings:
- **Variable type**: `Query`
- **Name**: `axes`
- **Query**:

    ```sql
    /*
    Select all table names that have two axes in the name and split axes names in two columns.

    +-----+-----+
    |axis1|axis2|
    +-----+-----+
    |A11  |A1   |
    |A2   |Z    |
    |C    |B    |
    |W    |Q1   |
    |X    |Y    |
    +-----+-----+

    Grafana provides regex functionality when creating a variable, but it is limited to extracting
    only one capture group per value therefore we cannot extract two axes from a single value (table
    name). This is why we use `REGEXP_REPLACE()`.
    */
    SELECT
        REGEXP_REPLACE(TABLE_NAME, "DATASET_(.+)_Axis_(.+)_Axis", "$1") as axis1,
        REGEXP_REPLACE(TABLE_NAME, "DATASET_(.+)_Axis_(.+)_Axis", "$2") as axis2
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME REGEXP "DATASET_.+_Axis_.+_Axis"
    ```
- **Multi-value**: `Checked`

`Run query` and make sure the preview of values is there: `A11` `A1` `A2` `C` `W` `X` `Y` `Z` `Q1`
`B`

### Sensor

Go to `Dashboard settings` -> `Variables` -> `Add variable` and use the following settings:

- **Variable type**: `Query`
- **Name**: `sensors`
- **Query**:
    ```sql
    /*
    Select all columns that have:
        - two axis in the table name.
        - two words in the column name.

    +-----------------------+
    |COLUMN_NAME            |
    +-----------------------+
    |DATAPOINT_A11_Speed    |
    |DATAPOINT_A11_Position |
    |DATAPOINT_A11_Current  |
    |DATAPOINT_A11_MotorTemp|
    |DATAPOINT_A11_Torque   |
    |DATAPOINT_A1_Speed     |
    |DATAPOINT_A1_Position  |
    |DATAPOINT_A1_Current   |
    |DATAPOINT_A1_MotorTemp |
    |DATAPOINT_A1_Torque    |
    |...                    |
    +-----------------------+
    */
    SELECT DISTINCT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
        COLUMN_NAME REGEXP "DATAPOINT_.+_.+"
        AND TABLE_NAME REGEXP "DATASET_.+_Axis_.+_Axis"
    ```
- **Regex**:

    ```
    # Extract the sensor name from the column names.
    /DATAPOINT_.+_(.*)/
    ```

`Run query` and make sure the preview of values is there: `Speed` `Position` `Current` `MotorTemp`
`Torque` `DevPos` `PosDev` `Lag` `ControlDev` `ContourDev`

## Stored procedure

Next step is to add this store procedure to the database. You can copy-paste and execute it in the
database design tool you are using (_MySQL Workbench_, _DataGrip_, ...).

The built query retrieves single sensor data for multiple axes and multiple machines within a
specific time range. It dynamically constructs a query using the provided input parameters and
executes it at the end. This stored procedure simplifies the process of retrieving sensor data for
multiple axes and machines by allowing users to provide parameters for the axes, sensor, machines,
time grouping, and filtering.

The procedure accepts five input parameters: 
- axes (JSON)
- sensor (TEXT)
- machines (TEXT)
- time_group (TEXT)
- time_filter (TEXT)

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
    /* Declare variable for iterating over the provided axes. */
    DECLARE current_axis VARCHAR(255);
    /* Declare variable for when iterating over the provided axes is done. */
    DECLARE done INT DEFAULT FALSE;
    /*
    Transform provided axes to a one column with many rows.

    For example, if ["X", "C", "Z"] is provided as axes, the cursor will iterate over this table:

    +-----+
    |value|
    +-----+
    |X    |
    |C    |
    |Z    |
    +-----+

    */
    DECLARE cursor_i CURSOR FOR SELECT value FROM JSON_TABLE(axes, '$[*]' COLUMNS(
        value VARCHAR(255) PATH '$'
    )) AS jt;
    /* Sets `done` to true when the loop is over (no more rows). */
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_i;

    /* Stores tore the final query that is executed from the procedure. */
    SET @_query = CONCAT(
        "WITH sources AS (SELECT * FROM bfc_sources WHERE ID in (", machines, ")), "
    );
    
    /* Stores everything after `MAIN_UNION AS`.   */
    SET @main_union = "";
    /*
    Stores the axes that have already been iterated over.
    
    We use `--` as a delimiter, so for example, when X, Y and Z have already been iterated over, the
    string would look like `--X----Y----Z--`.
    */
    SET @already_iterated_over = "";

    /* Start iterating over the axes. */
    read_axis_loop: LOOP
        FETCH cursor_i INTO current_axis;
        IF done THEN
            LEAVE read_axis_loop;
        END IF;

        /* If already iterated over this axis. */
        IF LOCATE(CONCAT("--", current_axis, "--"), @already_iterated_over) THEN
            /* Skip and go to the next one. */
            ITERATE read_axis_loop;
        END IF;

        /* Find table name for the current axis. */
        SET @axis_table_name := (
            SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME REGEXP CONCAT(current_axis, "_Axis")
        );

        /* Derive the twin axis name from the table name. */
        SET @twin_axis = REGEXP_REPLACE(@axis_table_name, "DATASET_(.+)_Axis_(.+)_Axis", "$1");
        IF @twin_axis = current_axis THEN
            SET @twin_axis = REGEXP_REPLACE(@axis_table_name, "DATASET_(.+)_Axis_(.+)_Axis", "$2");
        END IF;
        
        /* Stores the selected columns. */
        SET @sensor_values = CONCAT(
            "AVG(DATAPOINT_", current_axis ,"_", sensor, ") as ", current_axis, ", "
        );

        /* If twin axis is selected too, add it to the select statement. */
        IF LOCATE(@twin_axis, axes) THEN
            SET @sensor_values = CONCAT(
                @sensor_values,
                "AVG(DATAPOINT_", @twin_axis ,"_", sensor, ") as ", @twin_axis, ", "
            );
            /* Mark it as already iterated over. */
            SET @already_iterated_over = CONCAT(
                @already_iterated_over,
                "--", @twin_axis, "--"
            );
        END IF;
        
        /* Construct query for selected axes, sensor, machine(s) and time range. */
        SET @_query = CONCAT(
            @_query,
            "table_", current_axis, @twin_axis, " AS (SELECT ",
            @sensor_values,
            time_group, ", "
            "sources.BFC_CLIENT_ID as machine ",
            "FROM ",
            @axis_table_name, " as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.id ",
            "WHERE ",
            time_filter,
            " AND data.BFC_SOURCE_ID IN (", machines, ") ",
            "GROUP BY time, machine ",
            "ORDER BY time), "
        );
      
        /* Add the selected axes table to the main union so it will be pivoted to what Grafana wants. */
        SET @main_union = CONCAT(
            @main_union,
            "(SELECT time, '", current_axis, "' as 'As', machine, ", current_axis, " as __value FROM table_", current_axis, @twin_axis, ") ",
            "UNION ALL "
        );

        /* If twin axis is selected too, add it to the union statement. */
        IF LOCATE(@twin_axis, axes) THEN
            SET @main_union = CONCAT(
                @main_union,
                "(SELECT time, '", @twin_axis, "' as 'As', machine, ", @twin_axis, " as __value FROM table_", current_axis, @twin_axis, ") ",
                "UNION ALL "
            );
        END IF;
        
        /* Mark current axis as already iterated over. */
        SET @already_iterated_over = CONCAT(
            @already_iterated_over,
            "--", current_axis, "--"
        );

    /* Exit loop. */   
    END LOOP;

    /* Close cursor iterating over axes. */
    CLOSE cursor_i;

    /* Remove trailing ' UNION ALL  ' from main_union variable */
    SET @main_union = TRIM(TRAILING ' UNION ALL ' FROM @main_union); 
    
    /* Build the final query. */
    SET @_query = CONCAT(
        @_query,
        "MAIN_UNION AS ( ",
        @main_union,
        ") ",
        "SELECT * FROM MAIN_UNION ORDER BY time"
    );


    /* Execute the final query. */  
    PREPARE stmt FROM @_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

/* End stored procedure. */
END //

/* Set delimiter back to default ';'. */
DELIMITER ;
```

For instance, if we choose `X` and `Y` axes, `Current` sensor and `3` machine from the dropdowns,
the executed query would look like this:

```sql
WITH sources AS (SELECT * FROM bfc_sources WHERE ID in (3)),
    table_XY AS  (
        SELECT
            AVG(DATAPOINT_X_Current) as X,
            AVG(DATAPOINT_Y_Current) as Y,
            UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time,
            sources.BFC_CLIENT_ID as machine
        FROM DATASET_X_Axis_Y_Axis as data
        INNER JOIN sources on data.BFC_SOURCE_ID = sources.id
        WHERE data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669852800) AND FROM_UNIXTIME(1670352998)
            AND data.BFC_SOURCE_ID IN (3)
        GROUP BY time, machine
        ORDER BY time
    ),
    MAIN_UNION AS (
        (SELECT time, 'X' as 'As', machine, X as __value FROM table_XY)
        UNION ALL
        (SELECT time, 'Y' as 'As', machine, Y as __value FROM table_XY)
    )

SELECT * FROM MAIN_UNION ORDER BY time
```

## Call from Grafana
If all variables are set and the procedure is created, the procedure can be called from Grafana via:

```sql
/* Only 1 sensor must be selected for this query, otherwise it will cause errors. */
CALL get_sensor_for_multiple_axes_multiple_machines(
  '${axes:json}', -- Single quotes are important because JSON format already makes use of them.
  "${sensors:raw}",
  "${machines:csv}",
  "$__timeGroup(data.BFC_TIMESTAMP,$__interval) as time",
  /* Though we pass it as a string, Grafana sees that and still converts it to `data.BFC_TIMESTAMP
  BETWEEN FROM_UNIXTIME(1669852800)...` */
  "$__timeFilter(data.BFC_TIMESTAMP)" 
);
```
