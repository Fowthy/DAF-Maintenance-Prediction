# Transfer document

The purpose of this document is to describe what files we have included in the
final delivery. These files represent work we have done throughout the project -
documentation required by Fontys, experiments, research. These documents would
be mainly relevant for newcomers to the project, say another group if you decide
to continue working with Fontys next semester.

## `docs` folder 

## database-partitions
The database partitioning research is in int's own dedicated folder as it
includes visualizations

### Database alternative research document
The research showcase the different database options that can be used in the
project, instead of MySQL. It contains the different database providers
(CrateDB, QuestDB and InfluxDB), including the pros and cons along them with a
conclusion which alternative fits best for the scope.

### Flexible queries

- [v1](flexible_query.md)
- [v2](flexible_query_v2.md)
- [v3](flexible_query_v3.md)
- [v4](flexible_query_v4.md)
- [v4.1](flexible_query_v4.1.md)
- [v4.2?](flexible_query_summary_tables.md)
- [v5](flexible_query_v5.md)
- [v5.1](flexible_query_v5.1.md)

These represent the progress of our solution to make querying the database more
perormant, flexible and easy to use. The final version is
[v5.1](flexible_query_v5.1.md).

## `daf-expansion` folder
This folder contains all the needed information for the expansion and use of the
alerts tresholds in graphana.

### Expansion diagram
Files with the name DafExpansionERD is the diagram showing the expantion. There
are 3 different types of images depending on preference. The fourth file is a
[ERD](../daf-expansion/DafExpansionERD.drawio) file. This is the file for the
program where the ERD was maid.

### Expansion creation and population files
For the creation all the needed tables and relations we have a single DDL
[Expansion](../daf-expansion/Daf_alarm_expansion.sql) next for the DML that is
used for population we have 2 seperate files
[Base-population](../daf-expansion/populate_base_extension_tables.sql) where you
have static values that don't change a lot. Next we have
[Dinamic-population](../daf-expansion/populate_dynamic_extension_tables.sql)
which populates the more dinamic information into the Data Base. Lastly to be
able to change the treshold values we also have a stored prosidure for that
perpos [Updater](../daf-expansion/alarm_value_changer_v2.sql) this version uses
the names to find which treshold is being changed.

### Alerm queries
The alarm procedures and execution descriptions are documented into the
[AlarmQueries](../daf-expansion/alarmQueries.md) markdown and the corresponding
id's are shortlisted based on the expansion.

## `summary-tables` folder
The summary tables folder contains the create and populate sql statements for
all summery tables. Furthermore, It contains the event updating .sql sripts fro
all the events. Finally the directory contains the research on summary tables. …

## `script` folder
This folder contains the scripts that we used to create the database and the
tables. It also contains the script that we used to insert the data into the
database. Usage of those scripts is described in the [README](../README.md).

- [Database Setup](init-database.sh)
- [Database Insert](insert-data.sh)
- [Export data to CSV](mysqldump_to_csv.py) - this one was used for moving the
data to a time-series database. You generally don't need it if you will work
with MySQL.

## `docker-compose` file

This file is used to start the database and the Grafana instance. It is
described in the [README](../README.md).
