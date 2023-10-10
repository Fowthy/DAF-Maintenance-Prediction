
-- Drop tables if they exist
DROP TABLE IF EXISTS AVG_SUMMARY_A11_A1;
DROP TABLE IF EXISTS AVG_SUMMARY_A2_Z;
DROP TABLE IF EXISTS AVG_SUMMARY_W_Q1;
DROP TABLE IF EXISTS AVG_SUMMARY_X_Y;
DROP TABLE IF EXISTS AVG_SUMMARY_C_B;

-- Create table AVG_SUMMARY_A11_A1
CREATE TABLE `AVG_SUMMARY_A11_A1` (
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

-- Create table AVG_SUMMARY_A2_Z
CREATE TABLE `AVG_SUMMARY_A2_Z` (
	`BFC_TIMESTAMP` DATETIME(6) NOT NULL,
	`BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
	`DATAPOINT_A2_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_A2_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_A2_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_A2_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_A2_PosDev` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_PosDev` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_Lag` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_ControlDev` FLOAT DEFAULT NULL,
	`DATAPOINT_Z_ContourDev` FLOAT DEFAULT NULL,
	PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

-- Create table AVG_SUMMARY_W_Q1
CREATE TABLE `AVG_SUMMARY_W_Q1` (
	`BFC_TIMESTAMP` DATETIME(6) NOT NULL,
	`BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
	`DATAPOINT_W_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_W_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_W_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_W_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_W_PosDev` FLOAT DEFAULT NULL,
	`DATAPOINT_Q1_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_Q1_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_Q1_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_Q1_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_Q1_PosDev` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

-- Create table AVG_SUMMARY_X_Y
CREATE TABLE `AVG_SUMMARY_X_Y` (
	`BFC_TIMESTAMP` DATETIME(6) NOT NULL,
	`BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
	`DATAPOINT_X_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_X_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_X_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_X_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_X_PosDev` FLOAT DEFAULT NULL,
	`DATAPOINT_X_Lag` FLOAT DEFAULT NULL,
	`DATAPOINT_X_ControlDev` FLOAT DEFAULT NULL,
	`DATAPOINT_X_DontourDev` FLOAT DEFAULT NULL,
	`DATAPOINT_Y_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_Y_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_Y_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_Y_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_Y_PosDev` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

-- Create table AVG_SUMMARY_C_B
CREATE TABLE `AVG_SUMMARY_C_B` (
	`BFC_TIMESTAMP` DATETIME(6) NOT NULL,
	`BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
	`DATAPOINT_C_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_C_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_C_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_C_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_B_Speed` FLOAT DEFAULT NULL,
	`DATAPOINT_B_Position` FLOAT DEFAULT NULL,
	`DATAPOINT_B_Current` FLOAT DEFAULT NULL,
	`DATAPOINT_B_Torque` FLOAT DEFAULT NULL,
	`DATAPOINT_B_PosDev` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

-- POPULATE THE TABLES

-- Populate table AVG_SUMMARY_A11_A1
INSERT INTO `avg_summary_a11_a1` (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`, `DATAPOINT_A11_Speed`, `DATAPOINT_A11_Position`, `DATAPOINT_A11_Current`, `DATAPOINT_A11_Torque`, `DATAPOINT_A11_DevPos`, `DATAPOINT_A1_Speed`, `DATAPOINT_A1_Position`, `DATAPOINT_A1_Current`, `DATAPOINT_A1_Torque`)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(`BFC_TIMESTAMP`) DIV 60 * 60) as time,
    `BFC_SOURCE_ID`,
    AVG(`DATAPOINT_A11_Speed`),
    AVG(`DATAPOINT_A11_Position`),
    AVG(`DATAPOINT_A11_Current`),
    AVG(`DATAPOINT_A11_Torque`),
    AVG(`DATAPOINT_A11_DevPos`),
    AVG(`DATAPOINT_A1_Speed`),
    AVG(`DATAPOINT_A1_Position`),
    AVG(`DATAPOINT_A1_Current`),
    AVG(`DATAPOINT_A1_Torque`)
FROM `DATASET_A11_Axis_A1_Axis`
GROUP BY time, `BFC_SOURCE_ID`
ORDER BY time;

-- Populate table AVG_SUMMARY_A2_Z
INSERT INTO `AVG_SUMMARY_A2_Z` (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A2_Speed, DATAPOINT_A2_Position, DATAPOINT_A2_Current, DATAPOINT_A2_Torque, DATAPOINT_A2_PosDev, DATAPOINT_Z_Speed, DATAPOINT_Z_Position, DATAPOINT_Z_Current, DATAPOINT_Z_Torque, DATAPOINT_Z_PosDev, DATAPOINT_Z_Lag, DATAPOINT_Z_ControlDev, DATAPOINT_Z_ContourDev)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
	BFC_SOURCE_ID,
	AVG(DATAPOINT_A2_Speed),
	AVG(DATAPOINT_A2_Position),
	AVG(DATAPOINT_A2_Current),
	AVG(DATAPOINT_A2_Torque),
	AVG(DATAPOINT_A2_PosDev),
	AVG(DATAPOINT_Z_Speed),
	AVG(DATAPOINT_Z_Position),
	AVG(DATAPOINT_Z_Current),
	AVG(DATAPOINT_Z_Torque),
	AVG(DATAPOINT_Z_PosDev),
	AVG(DATAPOINT_Z_Lag),
	AVG(DATAPOINT_Z_ControlDev),
	AVG(DATAPOINT_Z_ContourDev)
FROM DATASET_A2_Axis_Z_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

-- Populate table AVG_SUMMARY_W_Q1
INSERT INTO `AVG_SUMMARY_W_Q1` (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_W_Speed, DATAPOINT_W_Position, DATAPOINT_W_Current, DATAPOINT_W_Torque, DATAPOINT_W_PosDev, DATAPOINT_Q1_Speed, DATAPOINT_Q1_Position, DATAPOINT_Q1_Current, DATAPOINT_Q1_Torque, DATAPOINT_Q1_PosDev)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
	BFC_SOURCE_ID,
	AVG(DATAPOINT_W_Speed),
	AVG(DATAPOINT_W_Position),
	AVG(DATAPOINT_W_Current),
	AVG(DATAPOINT_W_Torque),
	AVG(DATAPOINT_W_PosDev),
	AVG(DATAPOINT_Q1_Speed),
	AVG(DATAPOINT_Q1_Position),
	AVG(DATAPOINT_Q1_Current),
	AVG(DATAPOINT_Q1_Torque),
	AVG(DATAPOINT_Q1_PosDev)
FROM DATASET_W_Axis_Q1_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

-- Populate table AVG_SUMMARY_X_Y
INSERT INTO `AVG_SUMMARY_X_Y` (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_X_Speed, DATAPOINT_X_Position, DATAPOINT_X_Current, DATAPOINT_X_Torque, DATAPOINT_X_PosDev, DATAPOINT_X_Lag, DATAPOINT_X_ControlDev, DATAPOINT_X_DontourDev, DATAPOINT_Y_Speed, DATAPOINT_Y_Position, DATAPOINT_Y_Current, DATAPOINT_Y_Torque, DATAPOINT_Y_PosDev)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
	BFC_SOURCE_ID,
	AVG(DATAPOINT_X_Speed),
	AVG(DATAPOINT_X_Position),
	AVG(DATAPOINT_X_Current),
	AVG(DATAPOINT_X_Torque),
	AVG(DATAPOINT_X_PosDev),
	AVG(DATAPOINT_X_Lag),
	AVG(DATAPOINT_X_ControlDev),
	AVG(DATAPOINT_X_ContourDev),
	AVG(DATAPOINT_Y_Speed),
	AVG(DATAPOINT_Y_Position),
	AVG(DATAPOINT_Y_Current),
	AVG(DATAPOINT_Y_Torque),
	AVG(DATAPOINT_Y_PosDev)
FROM DATASET_X_Axis_Y_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

-- Populate table AVG_SUMMARY_C_B
INSERT INTO `AVG_SUMMARY_C_B` (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_C_Speed, DATAPOINT_C_Position, DATAPOINT_C_Current, DATAPOINT_C_Torque, DATAPOINT_B_Speed, DATAPOINT_B_Position, DATAPOINT_B_Current, DATAPOINT_B_Torque, DATAPOINT_B_PosDev)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
	BFC_SOURCE_ID,
	AVG(DATAPOINT_C_Speed),
	AVG(DATAPOINT_C_Position),
	AVG(DATAPOINT_C_Current),
	AVG(DATAPOINT_C_Torque),
	AVG(DATAPOINT_B_Speed),
	AVG(DATAPOINT_B_Position),
	AVG(DATAPOINT_B_Current),
	AVG(DATAPOINT_B_Torque),
	AVG(DATAPOINT_B_PosDev)
FROM DATASET_C_Axis_B_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;




