# Query Performance Research

The purpose of this document is to investigate reducing query times on the _DAF_ database, document the results and
provide a recommendation.

<!-- TOC -->
* [Query Performance Research](#query-performance-research)
  * [Constraints](#constraints)
    * [Measurement constraints](#measurement-constraints)
    * [Technical constraints](#technical-constraints)
    * [Grafana constraints](#grafana-constraints)
      * [Grafana setup](#grafana-setup)
  * [Baseline](#baseline)
    * [Baseline query](#baseline-query)
    * [Baseline query results](#baseline-query-results)
  * [Optimizations](#optimizations)
    * [Check indexes](#check-indexes)
    * [Add indexes on aggregated columns](#add-indexes-on-aggregated-columns)
      * [Results from adding indexes on aggregated columns](#results-from-adding-indexes-on-aggregated-columns)
    * [Select specific columns from `bfc_sources`](#select-specific-columns-from-bfcsources)
      * [Results from selecting specific columns from `bfc_sources`](#results-from-selecting-specific-columns-from-bfcsources)
    * [Remove seemingly redundant `ORDER BY` from subqueries](#remove-seemingly-redundant-order-by-from-subqueries)
      * [Results from removing seemingly redundant `ORDER BY` from subqueries](#results-from-removing-seemingly-redundant-order-by-from-subqueries)
    * [Remove redundant `WHERE` clause](#remove-redundant-where-clause)
      * [Results from removing redundant `WHERE` clause](#results-from-removing-redundant-where-clause)
    * [Summary tables](#summary-tables)
      * [Results from using summary tables](#results-from-using-summary-tables)
    * [Multithreading](#multithreading)
      * [Thread per table](#thread-per-table)
        * [Results from thread per table](#results-from-thread-per-table)
      * [Thread per axis](#thread-per-axis)
        * [Results from thread per axis](#results-from-thread-per-axis)
  * [Overall results](#overall-results)
  * [Discussion](#discussion)
  * [Conclusion](#conclusion)
    * [Proposed solution](#proposed-solution)
  * [References](#references)
<!-- TOC -->

## Constraints

### Measurement constraints

Each query measurement is done 3 times and the average is taken.

The measurement is done using the `Query Inspector` tool in `Grafana`. Grafana documentation states that it shows
response data [[1]](#reference1). Part of the response data is the query time.

To ensure that only the query is being executed and no others are running, the process list is checked before and during
the query execution via:

```mysql
SHOW FULL PROCESSLIST;
```

### Technical constraints

The measurement is done on a `ASUSTeK COMPUTER INC. ZenBook UX434FLC_UX434FL` laptop with `8 GB LPDDR3` of ram memory
and `Intel® Core™ i5-10210U CPU @ 1.60GHz × 8` processor on a `512GB M.2 NVMe™ PCIe® 3.0 SSD` disk. The operating system
is `Ubuntu 22.04 LTS` and the browser is `Firefox 113.0 (64-bit)`.

Only a single tab with `Grafana` is open and the only other application running is `DataGrip`.

To make sure that the results are not affected by the network, the `Grafana` server is running locally.

### Grafana constraints

All chart panels are located in one dashboard to ensure that the charts match visually.

In order to ensure a big enough query time so that differences in query times can be measured, all charts should query
the following data:

- 3 machines(ids `3`, `5` and `6` / `M22837` `M22838` `M2098`)
- all axes
- `Current` sensor
- `2022-12-02 00:00:00` to `2022-12-05 23:59:59` time range
- Query options are `MD = auto = 1328 Interval = 5m`

#### Grafana setup

A variable is created for the machines selected:

- **Variable type**: `Query`
- **Name**: `machines`
- **Multi-value**: `Checked`
- **Query**:

```mysql
SELECT BFC_CLIENT_ID as __text,
       ID            as __value
FROM bfc_sources
WHERE BFC_APPLICATION_TYPE = 'iotclient'
```

## Baseline

### Baseline query

The baseline query is as follows:
<details>
<summary>Click to see query</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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

</details>

### Baseline query results

The chart was loaded 3 times with an average query execution time of **83 seconds**.

| Run     | Time in [seconds].[milliseconds] |
|---------|----------------------------------|
| 1       | 81.0                             |
| 2       | 83.4                             |
| 3       | 84.6                             |
| Average | **83.0**                         |

## Optimizations

### Check indexes

The official MySQL 8.0 documentation[[2,3]](#reference2) states:
> To make a slow `SELECT ... WHERE` query faster, the first thing to check is whether you can add an index. Set up
> indexes on columns used in the WHERE clause, to speed up evaluation, filtering, and the final retrieval of results.

Indexes should be used on columns which are included in `WHERE` and used for `JOIN` operations. In DAF's case, both
operations are performed on the following columns:

- `bfc_sources.ID`
- `data.BFC_SOURCE_ID`
- `data.BFC_TIMESTAMP`

> Note: `data` in this case refers to all tables which contain machine data in a time series
> (e.g. `DATASET_C_Axis_B_Axis`).

An initial check confirms that indexes are already set on all columns of interest.

```mysql
SHOW INDEX FROM bfc_sources;
```

```
+-----------+----------+-------------+------------+--------------------+---------+-----------+----------+-------+
|Table      |Non_unique|Key_name     |Seq_in_index|Column_name         |Collation|Cardinality|Index_type|Visible|
+-----------+----------+-------------+------------+--------------------+---------+-----------+----------+-------+
|bfc_sources|0         |PRIMARY      |1           |ID                  |A        |27         |BTREE     |YES    |
|bfc_sources|0         |BFC_CLIENT_ID|1           |BFC_CLIENT_ID       |A        |17         |BTREE     |YES    |
|bfc_sources|0         |BFC_CLIENT_ID|2           |BFC_APPLICATION_TYPE|A        |27         |BTREE     |YES    |
+-----------+----------+-------------+------------+--------------------+---------+-----------+----------+-------+
```

```mysql
SHOW INDEX FROM DATASET_X_Axis_Y_Axis;
```

```
+---------------------+----------+-------------+------------+-------------+---------+-----------+----------+-------+
|Table                |Non_unique|Key_name     |Seq_in_index|Column_name  |Collation|Cardinality|Index_type|Visible|
+---------------------+----------+-------------+------------+-------------+---------+-----------+----------+-------+
|DATASET_X_Axis_Y_Axis|0         |BFC_SOURCE_ID|1           |BFC_SOURCE_ID|A        |1169       |BTREE     |YES    |
|DATASET_X_Axis_Y_Axis|0         |BFC_SOURCE_ID|2           |BFC_TIMESTAMP|A        |6808024    |BTREE     |YES    |
+---------------------+----------+-------------+------------+-------------+---------+-----------+----------+-------+
```

### Add indexes on aggregated columns

A user claims that adding index on the `AVG()` column and the one in the `WHERE` clause reduced the query execution time
from 83 seconds to 0.125 seconds[[4]](#reference4). To test this, indexes on all `Current` columns on all 5 tables of
interest are created:

```
daf> CREATE INDEX test_x_y ON DATASET_X_Axis_Y_Axis(BFC_SOURCE_ID, BFC_TIMESTAMP, DATAPOINT_X_Current, DATAPOINT_Y_Current)
[2023-05-12 19:19:07] completed in 1 m 23 s 192 ms
daf> CREATE INDEX test_a2_z ON DATASET_A2_Axis_Z_Axis(BFC_SOURCE_ID, BFC_TIMESTAMP, DATAPOINT_A2_Current, DATAPOINT_Z_Current)
[2023-05-12 19:21:48] completed in 1 m 25 s 387 ms
daf> CREATE INDEX test_a11_a1 ON DATASET_A11_Axis_A1_Axis(BFC_SOURCE_ID, BFC_TIMESTAMP, DATAPOINT_A11_Current, DATAPOINT_A1_Current)
[2023-05-12 19:23:46] completed in 1 m 24 s 652 ms
daf> CREATE INDEX test_c_b ON DATASET_C_Axis_B_Axis(BFC_SOURCE_ID, BFC_TIMESTAMP, DATAPOINT_C_Current, DATAPOINT_B_Current)
[2023-05-12 19:25:34] completed in 1 m 20 s 403 ms
daf> CREATE INDEX test_c_b ON DATASET_W_Axis_Q1_Axis(BFC_SOURCE_ID, BFC_TIMESTAMP, DATAPOINT_W_Current, DATAPOINT_Q1_Current)
[2023-05-12 19:27:16] completed in 1 m 23 s 766 ms
```

It takes **approximately 7 minutes** to create all indexes on a dataset of 15 days. The volume size of the MySQL
container grew by **1.5 GB**.

```bash
$ sudo du -sh $(docker volume inspect --format '{{ .Mountpoint }}' daf-maintenance-prediction_daf)
6.3G	/var/lib/docker/volumes/daf-maintenance-prediction_daf/_data
```

```bash
$ sudo du -sh $(docker volume inspect --format '{{ .Mountpoint }}' daf-maintenance-prediction_daf)
7.8G	/var/lib/docker/volumes/daf-maintenance-prediction_daf/_data
```

#### Results from adding indexes on aggregated columns

An increase of **1.19%** in the chart loading time was observed along with a **19.23%** increase in the volume size of
the database.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 84.6                             |
| 2       |          | 84.0                             |
| 3       |          | 81.6                             |
| Average | 83.0     | **83.4**                         |

### Select specific columns from `bfc_sources`

The query selects all columns from `bfc_sources` although only the `ID` and `BFC_CLIENT_ID` columns are used.

```mysql
WITH sources as (select * FROM bfc_sources WHERE ID in (3, 5, 6)), ...
      sources.BFC_CLIENT_ID as machine,
      ...
      DATASET_C_Axis_B_Axis as data INNER JOIN sources
on data.BFC_SOURCE_ID = sources.ID
```

According to numerous articles, Selecting only columns of interest is claimed to be more performant since less data is
transferred around[[5,6]](#reference5). Therefore, the query can be changed as follows:

```diff
-WITH sources as (select * FROM bfc_sources WHERE ID in (3, 5, 6)), ...
+WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in (3, 5, 6)), ...
```

<details>
<summary>Click to see query after changes</summary>

```
WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in ($machines)),

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

</details>

#### Results from selecting specific columns from `bfc_sources`

A decrease of **1.93%** is observed from the baseline query.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 81.6                             |
| 2       |          | 81.0                             |
| 3       |          | 81.6                             |
| Average | 83.0     | **81.4**                         |

### Remove seemingly redundant `ORDER BY` from subqueries

The `ORDER BY` clause in the subqueries seems redundant as the final selection from `MAIN_UNION` sorts them.

```mysql
    GROUP BY time, machine
    ORDER BY time),
    .
..
    GROUP BY time, machine
    ORDER BY time),
    .
..

SELECT *
FROM MAIN_UNION
ORDER BY time
```

Therefore, the query can be changed as follows:

```diff
-    GROUP BY time, machine
-    ORDER BY time),
+    GROUP BY time, machine),
     ...
```

The above patch is applied 5 times to the query, once for each subquery.

<details>
<summary>Click to see query after changes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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
    GROUP BY time, machine), 

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
    GROUP BY time, machine),

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
    GROUP BY time, machine),

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
    GROUP BY time, machine),

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
    GROUP BY time, machine),

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

</details>

#### Results from removing seemingly redundant `ORDER BY` from subqueries

A decrease of **1.93%** is observed from the baseline query.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 81.6                             |
| 2       |          | 81.0                             |
| 3       |          | 81.6                             |
| Average | 83.0     | **81.4**                         |

### Remove redundant `WHERE` clause

The `WHERE` clause in the subqueries is redundant as each subquery is being joined with the `sources` subquery which
already filters the results to only include the `bfc_source` IDs of interest.

Removing the `WHERE` is applied 5 times to the query, once for each subquery:

```diff
     WHERE
-      $__timeFilter(data.BFC_TIMESTAMP) and
-      data.BFC_SOURCE_ID IN (3,5,6)
+      $__timeFilter(data.BFC_TIMESTAMP)
     GROUP BY time, machine
```

<details>
<summary>Click to see query after changes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    BC AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_B_Current) as B,
      AVG(DATAPOINT_C_Current) as C
    FROM
      DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP)
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
      $__timeFilter(data.BFC_TIMESTAMP)
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
      $__timeFilter(data.BFC_TIMESTAMP)
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
      $__timeFilter(data.BFC_TIMESTAMP)
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
      $__timeFilter(data.BFC_TIMESTAMP)
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

</details>

#### Results from removing redundant `WHERE` clause

A decrease of **2.22%** is observed from the baseline query.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 81.6                             |
| 2       |          | 80.4                             |
| 3       |          | 81.6                             |
| Average | 83.0     | **81.2**                         |

### Summary tables

At _DAF_, data is being constantly collected and stored in the database without ever changing. Moreover, the team is
only interested in aggregations of the data - averages, minimums and maximums.

This poses an opportunity to create summary tables that will be updated every minute.

The majority of literature shows that summary tables are beneficial for queries that are executed on a regular basis
on large tables[[7, 8]](#reference7)

For this experiment, a summary table is created for each of the 5 tables that are being queried. The summary
table will contain data only from `2022-12-02 00:00:00` (`1669935600` unix time) to `2022-12-05 23:59:59` (`1670281199`
unix time) since this is the time range constraint for this research.

<details>
<summary>Click to see query for A2 and Z axes</summary>

```mysql
CREATE TABLE AVG_SUMMARY_A2_Z_Current
(
    BFC_TIMESTAMP        DATETIME(6)       NOT NULL,
    BFC_SOURCE_ID        SMALLINT UNSIGNED NOT NULL,
    DATAPOINT_A2_Current FLOAT DEFAULT NULL,
    DATAPOINT_Z_Current  FLOAT DEFAULT NULL
);

INSERT INTO AVG_SUMMARY_A2_Z_Current (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A2_Current, DATAPOINT_Z_Current)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
       BFC_SOURCE_ID,
       AVG(DATAPOINT_A2_Current),
       AVG(DATAPOINT_Z_Current)
FROM DATASET_A2_Axis_Z_Axis
WHERE BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669935600) AND FROM_UNIXTIME(1670281199)
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;
```

</details>

<details>
<summary>Click to see query for A11 and A1 axes</summary>

```mysql
CREATE TABLE AVG_SUMMARY_A11_A1_Current
(
    BFC_TIMESTAMP         DATETIME(6)       NOT NULL,
    BFC_SOURCE_ID         SMALLINT UNSIGNED NOT NULL,
    DATAPOINT_A11_Current FLOAT DEFAULT NULL,
    DATAPOINT_A1_Current  FLOAT DEFAULT NULL
);

INSERT INTO AVG_SUMMARY_A11_A1_Current (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A11_Current, DATAPOINT_A1_Current)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
       BFC_SOURCE_ID,
       AVG(DATAPOINT_A11_Current),
       AVG(DATAPOINT_A1_Current)
FROM DATASET_A11_Axis_A1_Axis
WHERE BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669935600) AND FROM_UNIXTIME(1670281199)
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;
```

</details>

<details>
<summary>Click to see query for W and Q1 axes</summary>

```mysql
CREATE TABLE AVG_SUMMARY_W_Q1_Current
(
    BFC_TIMESTAMP        DATETIME(6)       NOT NULL,
    BFC_SOURCE_ID        SMALLINT UNSIGNED NOT NULL,
    DATAPOINT_W_Current  FLOAT DEFAULT NULL,
    DATAPOINT_Q1_Current FLOAT DEFAULT NULL
);

INSERT INTO AVG_SUMMARY_W_Q1_Current (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_W_Current, DATAPOINT_Q1_Current)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
       BFC_SOURCE_ID,
       AVG(DATAPOINT_W_Current),
       AVG(DATAPOINT_Q1_Current)
FROM DATASET_W_Axis_Q1_Axis
WHERE BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669935600) AND FROM_UNIXTIME(1670281199)
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;
```

</details>

<details>
<summary>Click to see query for X and Y axes</summary>

```mysql
CREATE TABLE AVG_SUMMARY_X_Y_Current
(
    BFC_TIMESTAMP       DATETIME(6)       NOT NULL,
    BFC_SOURCE_ID       SMALLINT UNSIGNED NOT NULL,
    DATAPOINT_X_Current FLOAT DEFAULT NULL,
    DATAPOINT_Y_Current FLOAT DEFAULT NULL
);

INSERT INTO AVG_SUMMARY_X_Y_Current (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_X_Current, DATAPOINT_Y_Current)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
       BFC_SOURCE_ID,
       AVG(DATAPOINT_X_Current),
       AVG(DATAPOINT_Y_Current)
FROM DATASET_X_Axis_Y_Axis
WHERE BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669935600) AND FROM_UNIXTIME(1670281199)
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;
```

</details>

<details>
<summary>Click to see query for C and B axes</summary>

```mysql
CREATE TABLE AVG_SUMMARY_C_B_Current
(
    BFC_TIMESTAMP       DATETIME(6)       NOT NULL,
    BFC_SOURCE_ID       SMALLINT UNSIGNED NOT NULL,
    DATAPOINT_C_Current FLOAT DEFAULT NULL,
    DATAPOINT_B_Current FLOAT DEFAULT NULL
);

INSERT INTO AVG_SUMMARY_C_B_Current (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_C_Current, DATAPOINT_B_Current)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
       BFC_SOURCE_ID,
       AVG(DATAPOINT_C_Current),
       AVG(DATAPOINT_B_Current)
FROM DATASET_C_Axis_B_Axis
WHERE BFC_TIMESTAMP BETWEEN FROM_UNIXTIME(1669935600) AND FROM_UNIXTIME(1670281199)
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;
```

</details>

The creation of the tables takes `56.7s`.

After creating the tables, the following query is used to query the data. It is similar to the baseline query, but
instead of querying the raw data, it queries the summary tables.

<details>
<summary>Click to see query for summary tables</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    BC AS (SELECT $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
    sources.BFC_CLIENT_ID as machine,
    DATAPOINT_B_Current as B,
    DATAPOINT_C_Current as C
    FROM AVG_SUMMARY_C_B_Current as data
     INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
     WHERE $__timeFilter(data.BFC_TIMESTAMP)
    and data.BFC_SOURCE_ID IN (3, 5, 6)),
    
    
    XY AS (SELECT $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
    sources.BFC_CLIENT_ID as machine,
    DATAPOINT_X_Current as X,
    DATAPOINT_Y_Current as Y
    FROM AVG_SUMMARY_X_Y_Current as data
     INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
     WHERE $__timeFilter(data.BFC_TIMESTAMP)
    and data.BFC_SOURCE_ID IN (3, 5, 6)),
    
    
    A11A1 AS (SELECT $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
    sources.BFC_CLIENT_ID as machine,
    DATAPOINT_A1_Current as A1,
    DATAPOINT_A11_Current as A11
    FROM AVG_SUMMARY_A11_A1_Current as data
     INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
     WHERE $__timeFilter(data.BFC_TIMESTAMP)
    and data.BFC_SOURCE_ID IN (3, 5, 6)),
    
    
    A2Z AS (SELECT $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
    sources.BFC_CLIENT_ID as machine,
    DATAPOINT_A2_Current as A2,
    DATAPOINT_Z_Current as Z
    FROM AVG_SUMMARY_A2_Z_Current as data
     INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
     WHERE $__timeFilter(data.BFC_TIMESTAMP)
    and data.BFC_SOURCE_ID IN (3, 5, 6)),
    
    
    WQ1 AS (SELECT $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
    sources.BFC_CLIENT_ID as machine,
    DATAPOINT_W_Current as W,
    DATAPOINT_Q1_Current as Q1
    FROM AVG_SUMMARY_W_Q1_Current as data
     INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
     WHERE $__timeFilter(data.BFC_TIMESTAMP)
    and data.BFC_SOURCE_ID IN (3, 5, 6)),
    
    
    MAIN_UNION AS ((SELECT time, "B" as "As", machine, B as __value FROM BC)
    UNION ALL
     (SELECT time, "C" as "As", machine, C FROM BC)
    UNION ALL
     (SELECT time, "X" as "As", machine, X FROM XY)
    UNION ALL
     (SELECT time, "Y" as "As", machine, Y FROM XY)
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
     (SELECT time, "Q1" as "As", machine, Q1 FROM WQ1))


SELECT *
FROM MAIN_UNION
ORDER BY time;
```

</details>

#### Results from using summary tables

A decrease of **98.14%** is observed from the baseline query. Though, insertion times for the summary tables have to be
taken into account as well. Especially when there are years of data to be summarized.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 1.53                             |
| 2       |          | 1.66                             |
| 3       |          | 1.44                             |
| Average | 83.0     | **1.54**                         |

### Multithreading

_MySQL 8.0_ and above support multithreading and is able to use multiple cores to execute queries as long as each query
is a separate session.[[9]](#reference9)

> MySQL is fully multithreaded, and makes use of all CPUs made available to it.

> Use of multiple cores may be seen in these ways:

> A single core is usually used to service the commands issued from one session.


_Grafana_ supports 26 queries per panel and each query is a separate session[[10]](#reference10). Therefore, it is
possible to use multiple cores to execute queries.

A question occurs - `What is the optimal amount of queries that the query should be split into?`.

#### Thread per table

The query is split into 5 queries, each querying a separate table.

<details>
<summary>Click to see query for A2 and Z axes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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

    MAIN_UNION AS (
        (SELECT time, "A2" as "As", machine, A2 as __value FROM A2Z)
        UNION ALL
        (SELECT time, "Z" as "As", machine, Z FROM A2Z)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for A11 and A1 axes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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

    MAIN_UNION AS (
        (SELECT time, "A1" as "As", machine, A1 as __value FROM A11A1)
        UNION ALL
        (SELECT time, "A11" as "As", machine, A11 FROM A11A1)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for W and Q1 axes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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
        (SELECT time, "W" as "As", machine, W as __value FROM WQ1)
        UNION ALL
        (SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for X and Y axes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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
        (SELECT time, "X" as "As", machine, X as __value FROM XY)
        UNION ALL
        (SELECT time, "Y" as "As",  machine, Y FROM XY)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for C and B axes</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

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

    MAIN_UNION AS (
        (SELECT time, "B" as "As",machine, B as __value FROM BC)
        UNION ALL
        (SELECT time, "C" as "As",  machine, C FROM BC)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

##### Results from thread per table

A decrease of **50.6%** is observed from the baseline query.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 41.0                             |
| 2       |          | 41.0                             |
| 3       |          | 41.0                             |
| Average | 83.0     | **41.0**                         |

#### Thread per axis

The query is split into 10 queries, each querying a single axis.

<details>
<summary>Click to see query for A2 axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    A2Z AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_A2_Current) as A2
    FROM
      DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "A2" as "As", machine, A2 as __value FROM A2Z
```

</details>

<details>
<summary>Click to see query for Z axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    A2Z AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_Z_Current) as Z
    FROM
      DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "Z" as "As", machine, Z as __value FROM A2Z
```

</details>

<details>
<summary>Click to see query for A11 axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    A11A1 AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_A11_Current) as A11
    FROM
      DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "A11" as "As", machine, A11 as __value FROM A11A1
```

</details>

<details>
<summary>Click to see query for A1 axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    A11A1 AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_A1_Current) as A1
    FROM
      DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "A1" as "As", machine, A1 as __value FROM A11A1)
```

</details>

<details>
<summary>Click to see query for W axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    WQ1 AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_W_Current) as W
    FROM
      DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "W" as "As", machine, W as __value FROM WQ1
```

</details>

<details>
<summary>Click to see query for Q1 axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    WQ1 AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_Q1_Current) as Q1
    FROM
      DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "Q1" as "As", machine, Q1 as __value FROM WQ1
```

</details>

<details>
<summary>Click to see query for X axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    XY AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_X_Current) as X
    FROM
      DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "X" as "As", machine, X as __value FROM XY
```

</details>

<details>
<summary>Click to see query for Y axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    XY AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_Y_Current) as Y
    FROM
      DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "Y" as "As",  machine, Y as __value FROM XY
```

</details>

<details>
<summary>Click to see query for C axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    BC AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_C_Current) as C
    FROM
      DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "C" as "As",  machine, C as __value FROM BC
```

</details>

<details>
<summary>Click to see query for B axis</summary>

```
WITH sources as (select * FROM bfc_sources WHERE ID in ($machines)),

    BC AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_B_Current) as B
    FROM
      DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP) and
      data.BFC_SOURCE_ID IN (3,5,6)
    GROUP BY time, machine
    ORDER BY time)

SELECT time, "B" as "As",machine, B as __value FROM BC
```

</details>

##### Results from thread per axis

A decrease of **3.37%** is observed from the baseline query. Even though the query execution time change is minimal, the
amount of cores the processor used is only 4. Processors with more cores might benefit more from this query
optimization.

| Run     | Baseline | Current [seconds].[milliseconds] |
|---------|----------|----------------------------------|
| 1       |          | 79.8                             |
| 2       |          | 79.8                             |
| 3       |          | 80.2                             |
| Average | 83.0     | **80.0**                         |

## Overall results

| Optimization                                          | Percentage improvement from baseline query |
|-------------------------------------------------------|--------------------------------------------|
| Add indexes on aggregated columns                     | + 1.19                                     |
| Select specific columns from `bfc_sources`            | + 1.93                                     |
| Remove seemingly redundant `ORDER BY` from subqueries | + 1.93                                     |
| Remove redundant `WHERE` clause                       | + 2.22                                     |
| Summary tables                                        | + 98.14                                    |
| Multithreading (thread per table)                     | + 50.60                                    |
| Multithreading (thread per axis)                      | - 3.37                                     |

## Discussion

The purpose of this experimental study is to investigate potential performance improvements of the baseline query that
is used at _DAF_. Test machine was a `ASUSTeK COMPUTER INC. ZenBook UX434FLC_UX434FL` laptop. The study followed
pre-test post-test design, with first measurement taken as a baseline, and the following measurements as potential
optimizations.

The results showed that the most significant improvement was achieved by using summary tables. The query execution time
was reduced by **98.14%**. The second most significant improvement was achieved by using multithreading with a **50.6%**
reduction in query execution time. The rest of the optimizations had a minimal but noticeable effect on the query
execution time.

However, it should be noted that the study only focused on the query execution time and metrics such as network traffic
and memory usage were not measured. The study also did not investigate the effect of the optimizations when the database
is under constant load which is the case in production - the database is constantly being written to and read from.

Additionally, the study did not take into account the size of the database. The database used in the study contained
data for only 2 weeks - 1 December 2022 until 15 December 2022. The database in production contains data for more than
4 years.

## Conclusion

In conclusion, this study found significant impact on the query execution time by using summary tables and
multithreading. However, summary tables come at a tradeoff of increased storage space and aggregation time when the old
data has to be aggregated.

A solution consisting of the following optimizations would be most optimal:

- Multithreading (thread per table)
- Remove redundant `WHERE` clause
- Remove seemingly redundant `ORDER BY` from subqueries
- Select specific columns from `bfc_sources`

### Proposed solution

<details>
<summary>Click to see query for A2 and Z axes</summary>

```
WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in ($machines)),

    A2Z AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_A2_Current) as A2,
      AVG(DATAPOINT_Z_Current) as Z
    FROM
      DATASET_A2_Axis_Z_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP)
    GROUP BY time, machine),

    MAIN_UNION AS (
        (SELECT time, "A2" as "As", machine, A2 as __value FROM A2Z)
        UNION ALL
        (SELECT time, "Z" as "As", machine, Z FROM A2Z)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for A11 and A1 axes</summary>

```
WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in ($machines)),

    A11A1 AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_A1_Current) as A1,
      AVG(DATAPOINT_A11_Current) as A11
    FROM
      DATASET_A11_Axis_A1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP)
    GROUP BY time, machine),

    MAIN_UNION AS (
        (SELECT time, "A1" as "As", machine, A1 as __value FROM A11A1)
        UNION ALL
        (SELECT time, "A11" as "As", machine, A11 FROM A11A1)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for W and Q1 axes</summary>

```
WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in ($machines)),

    WQ1 AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_W_Current) as W,
      AVG(DATAPOINT_Q1_Current) as Q1
    FROM
      DATASET_W_Axis_Q1_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP)
    GROUP BY time, machine),

    MAIN_UNION AS (
        (SELECT time, "W" as "As", machine, W as __value FROM WQ1)
        UNION ALL
        (SELECT time, "Q1" as "As", machine, Q1 FROM WQ1)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for X and Y axes</summary>

```
WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in ($machines)),

    XY AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_X_Current) as X,
      AVG(DATAPOINT_Y_Current) as Y
    FROM
      DATASET_X_Axis_Y_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP)
    GROUP BY time, machine),

    MAIN_UNION AS (
        (SELECT time, "X" as "As", machine, X as __value FROM XY)
        UNION ALL
        (SELECT time, "Y" as "As",  machine, Y FROM XY)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

<details>
<summary>Click to see query for C and B axes</summary>

```
WITH sources as (select ID, BFC_CLIENT_ID FROM bfc_sources WHERE ID in ($machines)),

    BC AS (SELECT
      $__timeGroup(data.BFC_TIMESTAMP,$__interval) as time,
      sources.BFC_CLIENT_ID as machine,
      AVG(DATAPOINT_B_Current) as B,
      AVG(DATAPOINT_C_Current) as C
    FROM
      DATASET_C_Axis_B_Axis as data INNER JOIN sources on data.BFC_SOURCE_ID = sources.ID
    WHERE
      $__timeFilter(data.BFC_TIMESTAMP)
    GROUP BY time, machine), 

    MAIN_UNION AS (
        (SELECT time, "B" as "As",machine, B as __value FROM BC)
        UNION ALL
        (SELECT time, "C" as "As",  machine, C FROM BC)
    )

SELECT *
FROM MAIN_UNION
ORDER BY time
```

</details>

## References

<a id="reference1"></a>

1. Grafana Community. _Inspect query request and response data_. (2022). Obtained from
   URL: https://grafana.com/docs/grafana/latest/panels-visualizations/panel-inspector/#inspect-query-request-and-response-data (
   10 May 2023)

<a id="reference2"></a>

2. Oracle. _Optimizing SELECT Statements_. (2023). Obtained
   from URL: https://dev.mysql.com/doc/refman/8.0/en/select-optimization.html (10 May 2023)

<a id="reference3"></a>

3. Oracle. _How MySQL Uses Indexes_. (2023). Obtained
   from URL: https://dev.mysql.com/doc/refman/8.0/en/mysql-indexes.html (10 May 2023)

<a id="reference4"></a>

4. Jee, S.Y. _Average Function performance?_. (2013). Obtained
   from URL: https://stackoverflow.com/questions/19477311/average-function-performance (10 May 2023)

<a id="reference5"></a>

5. Evans, L. _Supercharge Your SQL Queries for Production Databases_. (2019). Obtained from URL:
   https://www.sisense.com/blog/8-ways-fine-tune-sql-queries-production-databases/ (10 May 2023)

<a id="reference6"></a>

6. dbForge Team. _How to Tune Performance of SQL Queries_. (2021). Obtained from URL:
   https://blog.devart.com/how-to-optimize-sql-query.html (10 May 2023)

<a id="reference7"></a>

7. James, R. _Summary Tables_. (2015). Obtained from URL: https://mysql.rjweb.org/doc.php/summarytables (12 May 2023)

<a id="reference8"></a>

8. Francis, A. _Using a summary table to optimize your data_. (2023) Obtained from
   URL: https://planetscale.com/courses/mysql-for-developers/examples/summary-tables (12 May 2023)

<a id="reference9"></a>

9. Oracle. _MySQL 8.0 FAQ: General_. (2023). Obtained from URL:
   https://dev.mysql.com/doc/refman/8.0/en/faqs-general.html#faq-mysql-support-multi-core (14 May 2023)

<a id="reference10"></a>

10. Grafana Community. _About queries_. (2022). Obtained from URL:
    https://grafana.com/docs/grafana/latest/panels-visualizations/query-transform-data/#about-queries (14 May 2023)
