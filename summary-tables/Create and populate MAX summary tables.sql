-- Drop tables if they exist
DROP TABLE IF EXISTS MAX_SUMMARY_A11_A1;
DROP TABLE IF EXISTS MAX_SUMMARY_A2_Z;
DROP TABLE IF EXISTS MAX_SUMMARY_W_Q1;
DROP TABLE IF EXISTS MAX_SUMMARY_X_Y;
DROP TABLE IF EXISTS MAX_SUMMARY_C_B;

-- Create MAX summary tables
CREATE TABLE MAX_SUMMARY_A11_A1
(
  `BFC_TIMESTAMP` DATETIME(6) NOT NULL,
  `BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
  `DATAPOINT_A11_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_A11_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_A11_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_A11_Torque` FLOAT DEFAULT NULL,
  `DATAPOINT_A1_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_A1_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_A1_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_A1_Torque` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

CREATE TABLE MAX_SUMMARY_A2_Z
(
  `BFC_TIMESTAMP` DATETIME(6) NOT NULL,
  `BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
  `DATAPOINT_A2_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_A2_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_A2_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_A2_Torque` FLOAT DEFAULT NULL,
  `DATAPOINT_Z_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_Z_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_Z_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_Z_Torque` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

CREATE TABLE MAX_SUMMARY_W_Q1
(
  `BFC_TIMESTAMP` DATETIME(6) NOT NULL,
  `BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
  `DATAPOINT_W_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_W_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_W_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_W_Torque` FLOAT DEFAULT NULL,
  `DATAPOINT_Q1_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_Q1_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_Q1_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_Q1_Torque` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

CREATE TABLE MAX_SUMMARY_X_Y
(
  `BFC_TIMESTAMP` DATETIME(6) NOT NULL,
  `BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
  `DATAPOINT_X_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_X_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_X_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_X_Torque` FLOAT DEFAULT NULL,
  `DATAPOINT_Y_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_Y_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_Y_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_Y_Torque` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

CREATE TABLE MAX_SUMMARY_C_B
(
  `BFC_TIMESTAMP` DATETIME(6) NOT NULL,
  `BFC_SOURCE_ID` SMALLINT UNSIGNED NOT NULL,
  `DATAPOINT_C_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_C_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_C_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_C_Torque` FLOAT DEFAULT NULL,
  `DATAPOINT_B_Position` FLOAT DEFAULT NULL,
  `DATAPOINT_B_Current` FLOAT DEFAULT NULL,
  `DATAPOINT_B_MotorTemp` FLOAT DEFAULT NULL,
  `DATAPOINT_B_Torque` FLOAT DEFAULT NULL,
  PRIMARY KEY (`BFC_TIMESTAMP`, `BFC_SOURCE_ID`)
);

-- Populate MAX summary tables
INSERT INTO MAX_SUMMARY_C_B (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_C_Position, DATAPOINT_C_Current, DATAPOINT_C_MotorTemp, DATAPOINT_C_Torque, DATAPOINT_B_Position, DATAPOINT_B_Current, DATAPOINT_B_MotorTemp, DATAPOINT_B_Torque)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
BFC_SOURCE_ID,
MAX(DATAPOINT_C_Position),
MAX(DATAPOINT_C_Current),
MAX(DATAPOINT_C_MotorTemp),
MAX(DATAPOINT_C_Torque),
MAX(DATAPOINT_B_Position),
MAX(DATAPOINT_B_Current),
MAX(DATAPOINT_B_MotorTemp),
MAX(DATAPOINT_B_Torque)
FROM DATASET_C_Axis_B_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

INSERT INTO MAX_SUMMARY_X_Y (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_X_Position, DATAPOINT_X_Current, DATAPOINT_X_MotorTemp, DATAPOINT_X_Torque, DATAPOINT_Y_Position, DATAPOINT_Y_Current, DATAPOINT_Y_MotorTemp, DATAPOINT_Y_Torque)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
BFC_SOURCE_ID,
MAX(DATAPOINT_X_Position),
MAX(DATAPOINT_X_Current),
MAX(DATAPOINT_X_MotorTemp),
MAX(DATAPOINT_X_Torque),
MAX(DATAPOINT_Y_Position),
MAX(DATAPOINT_Y_Current),
MAX(DATAPOINT_Y_MotorTemp),
MAX(DATAPOINT_Y_Torque)
FROM DATASET_X_Axis_Y_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

INSERT INTO MAX_SUMMARY_W_Q1 (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_W_Position, DATAPOINT_W_Current, DATAPOINT_W_MotorTemp, DATAPOINT_W_Torque, DATAPOINT_Q1_Position, DATAPOINT_Q1_Current, DATAPOINT_Q1_MotorTemp, DATAPOINT_Q1_Torque)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
BFC_SOURCE_ID,
MAX(DATAPOINT_W_Position),
MAX(DATAPOINT_W_Current),
MAX(DATAPOINT_W_MotorTemp),
MAX(DATAPOINT_W_Torque),
MAX(DATAPOINT_Q1_Position),
MAX(DATAPOINT_Q1_Current),
MAX(DATAPOINT_Q1_MotorTemp),
MAX(DATAPOINT_Q1_Torque)
FROM DATASET_W_Axis_Q1_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

INSERT INTO MAX_SUMMARY_A2_Z (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A2_Position, DATAPOINT_A2_Current, DATAPOINT_A2_MotorTemp, DATAPOINT_A2_Torque, DATAPOINT_Z_Position, DATAPOINT_Z_Current, DATAPOINT_Z_MotorTemp, DATAPOINT_Z_Torque)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
BFC_SOURCE_ID,
MAX(DATAPOINT_A2_Position),
MAX(DATAPOINT_A2_Current),
MAX(DATAPOINT_A2_MotorTemp),
MAX(DATAPOINT_A2_Torque),
MAX(DATAPOINT_Z_Position),
MAX(DATAPOINT_Z_Current),
MAX(DATAPOINT_Z_MotorTemp),
MAX(DATAPOINT_Z_Torque)
FROM DATASET_A2_Axis_Z_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;

INSERT INTO MAX_SUMMARY_A11_A1 (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A11_Position, DATAPOINT_A11_Current, DATAPOINT_A11_MotorTemp, DATAPOINT_A11_Torque, DATAPOINT_A1_Position, DATAPOINT_A1_Current, DATAPOINT_A1_MotorTemp, DATAPOINT_A1_Torque)
SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) as time,
BFC_SOURCE_ID,
MAX(DATAPOINT_A11_Position),
MAX(DATAPOINT_A11_Current),
MAX(DATAPOINT_A11_MotorTemp),
MAX(DATAPOINT_A11_Torque),
MAX(DATAPOINT_A1_Position),
MAX(DATAPOINT_A1_Current),
MAX(DATAPOINT_A1_MotorTemp),
MAX(DATAPOINT_A1_Torque)
FROM DATASET_A11_Axis_A1_Axis
GROUP BY time, BFC_SOURCE_ID
ORDER BY time;