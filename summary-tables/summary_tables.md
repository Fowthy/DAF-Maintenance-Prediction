# Report: MySQL Summary Tables and Continuous Updating Methods

## Introduction

MySQL summary tables are precomputed tables that store aggregated data derived from the original data in a database. They are used to enhance query performance by reducing the need for complex calculations during query execution. This report, explores the concept of summary tables and discuss various methods to continuously update them in MySQL, including MySQL insert triggers, MySQL event schedulers, and other related techniques.

## Summary Tables in MySQL

Summary tables are created by aggregating data from one or more source tables. They are commonly used when there is a need to generate complex queries or reports on a regular basis, and the speed of these queries is crucial. By precalculating and storing aggregated data in summary tables, the database can retrieve the results more efficiently. This approach helps save computational resources and reduces the time required for query execution.

Example:

Creating and populating the summary table with agregated average value for every minute from the regular table

```sql
-- create summary table
CREATE TABLE `avg_summary_a11_a1` (
  `BFC_TIMESTAMP` datetime(6) NOT NULL,
  `BFC_SOURCE_ID` smallint unsigned NOT NULL,
  `DATAPOINT_A11_Speed` float DEFAULT NULL,
  `DATAPOINT_A11_Position` float DEFAULT NULL,
  `DATAPOINT_A11_Current` float DEFAULT NULL,
  `DATAPOINT_A11_Torque` float DEFAULT NULL,
  `DATAPOINT_A11_DevPos` float DEFAULT NULL,
  `DATAPOINT_A1_Speed` float DEFAULT NULL,
  `DATAPOINT_A1_Position` float DEFAULT NULL,
  `DATAPOINT_A1_Current` float DEFAULT NULL,
  `DATAPOINT_A1_Torque` float DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);
```

```sql
-- Populate table AVG_SUMMARY_A11_A1
INSERT INTO AVG_SUMMARY_A11_A1 (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A11_Speed, DATAPOINT_A11_Position, DATAPOINT_A11_Current, DATAPOINT_A11_Torque, DATAPOINT_A11_DevPos, DATAPOINT_A1_Speed, DATAPOINT_A1_Position, DATAPOINT_A1_Current, DATAPOINT_A1_Torque)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
	BFC_SOURCE_ID,
	AVG(DATAPOINT_A11_Speed),
	AVG(DATAPOINT_A11_Position),
	AVG(DATAPOINT_A11_Current),
	AVG(DATAPOINT_A11_Torque),
	AVG(DATAPOINT_A11_DevPos),
	AVG(DATAPOINT_A1_Speed),
	AVG(DATAPOINT_A1_Position),
	AVG(DATAPOINT_A1_Current),
	AVG(DATAPOINT_A1_Torque)
FROM DATASET_A11_Axis_A1_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;
```

## Continuous Updating of Summary Tables

To ensure the accuracy and relevancy of the data in summary tables, it is necessary to continuously update them as the source tables change. Several methods can be employed to achieve this:

### 1. MySQL Insert Triggers

MySQL triggers are database objects that can be associated with specific events, such as INSERT, UPDATE, or DELETE operations on a table. Summary tables can be automatically updated using INSERT triggers whenever new records are inserted. The trigger can be defined to perform the necessary calculations and update the corresponding values in the summary table.

Example:

```sql
CREATE TRIGGER trigger_name AFTER INSERT ON source_table
FOR EACH ROW
BEGIN
-- Update summary table based on new data
-- Perform calculations and update relevant columns
END;
```

The problem with insert triggers is that the trigger executes the query on each inserted row and in a system that supports many inserts every second they are not a viable option. This is because the insert trigger turns what would otherwise be a quick insert querry into a querry that takes several seconds to execute which acts as a huge bottleneck.

### 2. MySQL Events

MySQL event schedulers enable the automatic execution of predefined actions at specific intervals. By utilizing event schedulers, summary tables can be updated automatically periodically without manual intervention. An event can be scheduled to execute an SQL statement or a stored procedure that performs the required calculations and updates the summary table.

Example:

```sql

CREATE EVENT update_avg_summary_a11_a1
ON SCHEDULE
    EVERY 1 MINUTE
DO
	INSERT INTO avg_summary_a11_a1 (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A11_Speed, DATAPOINT_A11_Position, DATAPOINT_A11_Current, DATAPOINT_A11_Torque, DATAPOINT_A11_DevPos, DATAPOINT_A1_Speed, DATAPOINT_A1_Position, DATAPOINT_A1_Current, DATAPOINT_A1_Torque)
	SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		AVG(DATAPOINT_A11_Speed),
		AVG(DATAPOINT_A11_Position),
		AVG(DATAPOINT_A11_Current),
		AVG(DATAPOINT_A11_Torque),
		AVG(DATAPOINT_A11_DevPos),
		AVG(DATAPOINT_A1_Speed),
		AVG(DATAPOINT_A1_Position),
		AVG(DATAPOINT_A1_Current),
		AVG(DATAPOINT_A1_Torque)
	FROM dataset_a11_axis_a1_axis
	GROUP BY time, BFC_SOURCE_ID
	ORDER BY time
	ON DUPLICATE KEY UPDATE
		DATAPOINT_A11_Speed = VALUES(DATAPOINT_A11_Speed),
		DATAPOINT_A11_Position = VALUES(DATAPOINT_A11_Position),
		DATAPOINT_A11_Current = VALUES(DATAPOINT_A11_Current),
		DATAPOINT_A11_Torque = VALUES(DATAPOINT_A11_Torque),
		DATAPOINT_A11_DevPos = VALUES(DATAPOINT_A11_DevPos),
		DATAPOINT_A1_Speed = VALUES(DATAPOINT_A1_Speed),
		DATAPOINT_A1_Position = VALUES(DATAPOINT_A1_Position),
		DATAPOINT_A1_Current = VALUES(DATAPOINT_A1_Current),
		DATAPOINT_A1_Torque = VALUES(DATAPOINT_A1_Torque);

```

### 3. Combined Approach: Triggers and Event Schedulers

In some cases, it may be beneficial to use a combination of triggers and event schedulers to update summary tables. Triggers can handle immediate updates when new data is inserted, while event schedulers can perform periodic updates to reflect any changes that occurred in the source tables between trigger executions. This combined approach ensures both real-time and regular updates.

### 4. Manual Updates

Continuous updating methods offer automated solutions for data management. However, there are certain scenarios where manual updates become essential. For instance, if there is a notable modification in the source data or the structure of the summary table, manual intervention becomes necessary to guarantee the accuracy of the information. In such situations, manual SQL statements or scripts can be employed to update the summary table according to the specific requirements.

## Considerations and Best Practices

- **Data Integrity**: Ensure that the updates to the summary tables maintain data integrity and consistency with the source tables. This can be done by checking weather the agregations are correct, by manually executing a query that will aggregate a row in the summary table in the same way that the events will but using a different method. Then after comparing the results they should be identical.

Example:

```sql
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		AVG(DATAPOINT_A11_Speed),
		AVG(DATAPOINT_A11_Position),
		AVG(DATAPOINT_A11_Current),
		AVG(DATAPOINT_A11_Torque),
		AVG(DATAPOINT_A11_DevPos),
		AVG(DATAPOINT_A1_Speed),
		AVG(DATAPOINT_A1_Position),
		AVG(DATAPOINT_A1_Current),
		AVG(DATAPOINT_A1_Torque)
	FROM dataset_a11_axis_a1_axis
  WHERE BFC_TIMESTAMP BETWEEN 12:00:00 AND 12:01:00
```

- **Performance Impact**: Evaluate the performance impact of updating summary tables. Frequent updates or complex calculations may introduce overhead, affecting overall database performance.

- **Optimization**: Employ indexing and query optimization techniques to further enhance the performance of summary tables and queries that utilize them.

- **Monitoring and Maintenance**: Regularly monitor the performance and accuracy of summary tables. Perform routine maintenance tasks such as index rebuilds, statistics updates, and data purging to keep the summary tables optimized.

## Conclusion

MySQL summary tables provide a valuable technique for improving query performance by storing precomputed aggregated data. Continuous updating methods, such as MySQL insert triggers, MySQL event schedulers, and a combined approach, ensure that summary tables stay up-to-date with the changes in the source tables. By employing these methods and following best practices, organizations can significantly enhance the performance of their database queries and reports.

## References

Summary Tables in MySQL. (n.d.). [Online]. Available: [http://mysql.rjweb.org/doc.php/summarytables](http://mysql.rjweb.org/doc.php/summarytables)

Francis, A. D., & Francis, A. D. (2023). Summary tables. PlanetScale, Inc. [Online]. Available: [https://planetscale.com/courses/mysql-for-developers/examples/summary-tables](https://planetscale.com/courses/mysql-for-developers/examples/summary-tables)

MySQL AFTER INSERT Trigger By Practical Examples. (2020, April 11). MySQL Tutorial. [Online]. Available: [https://www.mysqltutorial.org/mysql-triggers/mysql-after-insert-trigger/](https://www.mysqltutorial.org/mysql-triggers/mysql-after-insert-trigger/)

Technologies, S. (2023, March 7). MySql Event Scheduler. Surekha Technologies. [Online]. Available: [https://www.surekhatech.com/blog/mysql-event-scheduler#:~:text=What%20is%20MySql%20Event%20Scheduler,multiple%20times%20at%20specified%20intervals](https://www.surekhatech.com/blog/mysql-event-scheduler#:~:text=What%20is%20MySql%20Event%20Scheduler,multiple%20times%20at%20specified%20intervals)
