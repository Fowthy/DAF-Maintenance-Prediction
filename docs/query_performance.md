
Take the following grafana query:

```sql

WITH sources as (select * FROM bfc_sources WHERE ID in ($machine2)),

BC AS (SELECT
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
ORDER BY time), 

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

A11A1 AS (SELECT
  $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A1_Current) as A1,
  AVG(DATAPOINT_A11_Current) as A11
FROM
  DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  $__timeFilter(data.BFC_TIMESTAMP) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A2Z AS (SELECT
  $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A2_Current) as A2,
  AVG(DATAPOINT_Z_Current) as Z
FROM
  DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  $__timeFilter(data.BFC_TIMESTAMP) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

WQ1 AS (SELECT
  $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_W_Current) as W,
  AVG(DATAPOINT_Q1_Current) as Q1
FROM
  DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  $__timeFilter(data.BFC_TIMESTAMP) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

MAIN_UNION AS (
	(SELECT time, "B" as "As",machine, B as __value FROM BC)
	UNION ALL
	(SELECT time, "C" as "As",  machine, C FROM BC)
	UNION ALL
	(SELECT time, "X" as "As", machine, X FROM XY)
	UNION ALL
	(SELECT time, "Y" as "As",  machine, Y FROM XY)
	UNION ALL
	(SELECT time, "A1" as "As", machine, A1 FROM A11A1)
	UNION ALL
	(SELECT time, "A11" as "As", machine, A11 FROM A11A1)
	UNION ALL
	(SELECT time, "A2" as "As", machine, A2 FROM A2Z)
	UNION ALL
	(SELECT time, "Z" as "As", machine, Z FROM A2Z)
	UNION ALL
	(SELECT time, "W" as "As", machine, W FROM WQ1)
	UNION ALL
	(SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
)

SELECT *
FROM MAIN_UNION
ORDER BY time
```
In the first CTE we select a subset of the 3 machines (ID 3, 5, 6)
In the following 5 CTE's we inner join the former, to narrow down the BFC_SOURCE_ID, which proves faster than using a subquery in the where statement.
Omitting the where clause on BFC_SOURCE_ID hits the performance hard, since we're not binding the primary key.

finally, we union everything, to get an unpivoted result in the format Grafana expects.

This results in a nice graph of the currents of all axes, and we can select a big timespan when we have a single machine selected.
However, a problem arises when we select multiple machines. It looks like it works perfectly.
Responses are fast, almost instantanious. Until we specify a timespan greater than about 175 minutes.
Then the time it takes to retreive the query result jumps from *(mili)seconds* to ***hours***

In the queries below, I've chosen times that are present in the dataset we've provided.
This one works perfectly, 2 machines, timespan of 2 hours: (2022-12-06 00:00 - 02:00)
You should be able to copy-paste these all queries below and run them against your DB instance.
*I'd be curious to know how to improve these queries to get the results we want in a reasonable time.*

```sql
WITH sources as (select * FROM bfc_sources WHERE ID in ('3','6')),

BC AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_B_Current) as B,
  AVG(DATAPOINT_C_Current) as C
FROM
  DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670288400) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time), 

XY AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_X_Current) as X,
  AVG(DATAPOINT_Y_Current) as Y
FROM
  DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670288400) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A11A1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A1_Current) as A1,
  AVG(DATAPOINT_A11_Current) as A11
FROM
  DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670288400) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A2Z AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A2_Current) as A2,
  AVG(DATAPOINT_Z_Current) as Z
FROM
  DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670288400) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

WQ1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_W_Current) as W,
  AVG(DATAPOINT_Q1_Current) as Q1
FROM
  DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670288400) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

MAIN_UNION AS (
(SELECT time, "B" as "As",machine, B as __value FROM BC)
UNION ALL
(SELECT time, "C" as "As",  machine, C FROM BC)
UNION ALL
(SELECT time, "X" as "As", machine, X FROM XY)
UNION ALL
(SELECT time, "Y" as "As",  machine, Y FROM XY)
UNION ALL
(SELECT time, "A1" as "As", machine, A1 FROM A11A1)
UNION ALL
(SELECT time, "A11" as "As", machine, A11 FROM A11A1)
UNION ALL
(SELECT time, "A2" as "As", machine, A2 FROM A2Z)
UNION ALL
(SELECT time, "Z" as "As", machine, Z FROM A2Z)
UNION ALL
(SELECT time, "W" as "As", machine, W FROM WQ1)
UNION ALL
(SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
)

SELECT *
FROM MAIN_UNION
ORDER BY time
```
As does this: 3 machines 1 hour (2022-12-06 00:00 -- 2022-12-06 01:00)
```sql
WITH sources as (select * FROM bfc_sources WHERE ID in ('3','5','6')),

BC AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 2 * 2 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_B_Current) as B,
  AVG(DATAPOINT_C_Current) as C
FROM
  DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670284800) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time), 

XY AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 2 * 2 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_X_Current) as X,
  AVG(DATAPOINT_Y_Current) as Y
FROM
  DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670284800) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A11A1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 2 * 2 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A1_Current) as A1,
  AVG(DATAPOINT_A11_Current) as A11
FROM
  DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670284800) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A2Z AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 2 * 2 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A2_Current) as A2,
  AVG(DATAPOINT_Z_Current) as Z
FROM
  DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670284800) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

WQ1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 2 * 2 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_W_Current) as W,
  AVG(DATAPOINT_Q1_Current) as Q1
FROM
  DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670284800) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

MAIN_UNION AS (
(SELECT time, "B" as "As",machine, B as __value FROM BC)
UNION ALL
(SELECT time, "C" as "As",  machine, C FROM BC)
UNION ALL
(SELECT time, "X" as "As", machine, X FROM XY)
UNION ALL
(SELECT time, "Y" as "As",  machine, Y FROM XY)
UNION ALL
(SELECT time, "A1" as "As", machine, A1 FROM A11A1)
UNION ALL
(SELECT time, "A11" as "As", machine, A11 FROM A11A1)
UNION ALL
(SELECT time, "A2" as "As", machine, A2 FROM A2Z)
UNION ALL
(SELECT time, "Z" as "As", machine, Z FROM A2Z)
UNION ALL
(SELECT time, "W" as "As", machine, W FROM WQ1)
UNION ALL
(SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
)

SELECT *
FROM MAIN_UNION
ORDER BY time
```

And this, 1 machine 7 days (2022-12-06 00:00 -- 2022-12-12 23:59), takes 17 seconds:
```sql
WITH sources as (select * FROM bfc_sources WHERE ID in ('3')),

BC AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_B_Current) as B,
  AVG(DATAPOINT_C_Current) as C
FROM
  DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670885999) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time), 

XY AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_X_Current) as X,
  AVG(DATAPOINT_Y_Current) as Y
FROM
  DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670885999) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A11A1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A1_Current) as A1,
  AVG(DATAPOINT_A11_Current) as A11
FROM
  DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670885999) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A2Z AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A2_Current) as A2,
  AVG(DATAPOINT_Z_Current) as Z
FROM
  DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670885999) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

WQ1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 300 * 300 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_W_Current) as W,
  AVG(DATAPOINT_Q1_Current) as Q1
FROM
  DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670885999) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

MAIN_UNION AS (
(SELECT time, "B" as "As",machine, B as __value FROM BC)
UNION ALL
(SELECT time, "C" as "As",  machine, C FROM BC)
UNION ALL
(SELECT time, "X" as "As", machine, X FROM XY)
UNION ALL
(SELECT time, "Y" as "As",  machine, Y FROM XY)
UNION ALL
(SELECT time, "A1" as "As", machine, A1 FROM A11A1)
UNION ALL
(SELECT time, "A11" as "As", machine, A11 FROM A11A1)
UNION ALL
(SELECT time, "A2" as "As", machine, A2 FROM A2Z)
UNION ALL
(SELECT time, "Z" as "As", machine, Z FROM A2Z)
UNION ALL
(SELECT time, "W" as "As", machine, W FROM WQ1)
UNION ALL
(SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
)

SELECT *
FROM MAIN_UNION
ORDER BY time
```

Contrasting, a query over 3 machines, 2 hours, or 2 machines, 3 hours, does not return a result timely enough for grafana to even tell me the raw query it sent to the DB.
So I'm manually editing the unix times in one of the above queries:
(2 machines, 2022-12-06 00:00 -- 2022-12-06 03:00)
(1 machine with the same timespan does also get the `DIV 5 * 5` parts, so I'm confident that the query below is the same one Grafana is generating)
```sql
WITH sources as (select * FROM bfc_sources WHERE ID in ('3','5')),

BC AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_B_Current) as B,
  AVG(DATAPOINT_C_Current) as C
FROM
  DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670292000) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time), 

XY AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_X_Current) as X,
  AVG(DATAPOINT_Y_Current) as Y
FROM
  DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670292000) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A11A1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A1_Current) as A1,
  AVG(DATAPOINT_A11_Current) as A11
FROM
  DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670292000) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

A2Z AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_A2_Current) as A2,
  AVG(DATAPOINT_Z_Current) as Z
FROM
  DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670292000) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

WQ1 AS (SELECT
  UNIX_TIMESTAMP(data.BFC_TIMESTAMP) DIV 5 * 5 as time,
  sources.BFC_CLIENT_ID as machine,
  AVG(DATAPOINT_W_Current) as W,
  AVG(DATAPOINT_Q1_Current) as Q1
FROM
  DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
WHERE
  data.BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1670281200) AND FROM_UNIXTIME(1670292000) and
  data.BFC_SOURCE_ID IN (3,5,6)
GROUP BY time, machine
ORDER BY time),

MAIN_UNION AS (
(SELECT time, "B" as "As",machine, B as __value FROM BC)
UNION ALL
(SELECT time, "C" as "As",  machine, C FROM BC)
UNION ALL
(SELECT time, "X" as "As", machine, X FROM XY)
UNION ALL
(SELECT time, "Y" as "As",  machine, Y FROM XY)
UNION ALL
(SELECT time, "A1" as "As", machine, A1 FROM A11A1)
UNION ALL
(SELECT time, "A11" as "As", machine, A11 FROM A11A1)
UNION ALL
(SELECT time, "A2" as "As", machine, A2 FROM A2Z)
UNION ALL
(SELECT time, "Z" as "As", machine, Z FROM A2Z)
UNION ALL
(SELECT time, "W" as "As", machine, W FROM WQ1)
UNION ALL
(SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
)

SELECT *
FROM MAIN_UNION
ORDER BY time
```