## Flexible query v2

This query is a better version of the flexible query in terms of performance.

While the previous one would build and throw one big query at the database, this one will build and pass multiple
smaller ones to take advantage
of [MySQL's multithreading](https://dev.mysql.com/doc/refman/8.0/en/faqs-general.html#faq-mysql-support-multi-core).
> MySQL is fully multithreaded, and makes use of all CPUs made available to it.

> Use of multiple cores may be seen in these ways:
> - A single core is usually used to service the commands issued from one session.

This split showed a **50.6%** reduction in execution time for our local runs:

| Query             | Execution time |
|-------------------|----------------|
| Flexible query v1 | 83.0s          |
| Flexible query v2 | 41.0s          |

The constraints were:

- 3 machines(ids `3`, `5` and `6` / `M22837` `M22838` `M2098`)
- all 10 axes
- `Current` sensor
- `2022-12-02 00:00:00` to `2022-12-05 23:59:59` time range
- Query options are `MD = auto = 1328 Interval = 5m`

> Note: Each result in the table is the average of 3 runs. The largest deviation observed between 3 runs was 1.8s so we
> can be certain that the query is more performant.

## Setup

The setup is the same as before. `machines`, `axes` and `sensors` variables are expected to be present in the dashboard.
You can select multiple machines and axes, but only one sensor.

Create the stored procedure in your database:

```mysql
DROP PROCEDURE IF EXISTS get_sensor_for_multiple_axes_multiple_machines_v2;
DELIMITER //
CREATE PROCEDURE get_sensor_for_multiple_axes_multiple_machines_v2(
    IN axes JSON,
    IN sensor TEXT,
    IN machines TEXT,
    IN time_group TEXT,
    IN time_filter TEXT,
    IN query_no INT
)
this_procedure:
BEGIN
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

    /* Stores the final query that is executed from the procedure. */
    SET @_query = CONCAT(
            "WITH sources AS (SELECT ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in (", machines, ")), "
        );

    /* Stores the main union. */
    SET @main_union = "";

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

    /* Stores the selected columns. */
    SET @sensor_values = CONCAT(
            "AVG(DATAPOINT_", current_axis, "_", sensor, ") as ", current_axis, ", "
        );

    /* Stores the main union. */
    SET @main_union = CONCAT(
            @main_union,
            "(SELECT time, '", current_axis, "' as 'As', machine, ", current_axis, " as __value FROM table_",
            current_axis, @twin_axis, ") "
        );


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
            SET @sensor_values = CONCAT(
                    @sensor_values,
                    "AVG(DATAPOINT_", @twin_axis, "_", sensor, ") as ", @twin_axis, ", "
                );
            SET @main_union = CONCAT(
                    @main_union,
                    "UNION ALL",
                    "(SELECT time, '", @twin_axis, "' as 'As', machine, ", @twin_axis, " as __value FROM table_",
                    current_axis, @twin_axis, ") "
                );
        END IF;
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
            "GROUP BY time, machine), "
        );

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

Create 5 queries in the `Query` panel in `Grafana`. The last parameter of the `CALL` function should be the query
number, starting from 1. Please refer to `Setup.png` attached to this email for a visual:

```sql
CALL get_sensor_for_multiple_axes_multiple_machines_v2(
  '${axes:json}', -- Single quotes are important.
  "${sensors:raw}",
  "${machines:csv}",
  "$__timeGroup(data.BFC_TIMESTAMP,$__interval) as time",
  "$__timeFilter(data.BFC_TIMESTAMP)",
  1 -- 1 for first query. Next query, this parameter should be 2, and so on.
);
```

5 queries is enough. If you add more it wouldn't make a difference since they would not be utilized. A query
queries either one or two axes from a table. Our database has 5 tables - one for each combination of axes, so 5 queries
is enough to query all the axes. If you have more pairs of axes than 5 in your production environment, then you should
add more queries.

> Note: [Grafana supports up to `26` queries per panel](https://grafana.com/docs/grafana/latest/panels-visualizations/query-transform-data/#about-queries)

