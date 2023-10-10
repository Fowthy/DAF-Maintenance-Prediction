-- Drop events if they exist
DROP EVENT IF EXISTS update_min_summary_a11_a1;
DROP EVENT IF EXISTS update_min_summary_a2_z;
DROP EVENT IF EXISTS update_min_summary_w_q1;
DROP EVENT IF EXISTS update_min_summary_c_b;
DROP EVENT IF EXISTS update_min_summary_x_y;

-- Create min summary tables update events

CREATE EVENT update_min_summary_a11_a1
ON SCHEDULE 
	EVERY 1 MINUTE
DO
	INSERT INTO MIN_SUMMARY_A11_A1 (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A11_Position, DATAPOINT_A11_Current, DATAPOINT_A11_Torque, DATAPOINT_A1_Position, DATAPOINT_A1_Current, DATAPOINT_A1_Torque)
	SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		MIN(DATAPOINT_A11_Position),
		MIN(DATAPOINT_A11_Current),
		MIN(DATAPOINT_A11_Torque),
		MIN(DATAPOINT_A1_Position),
		MIN(DATAPOINT_A1_Current),
		MIN(DATAPOINT_A1_Torque)
	FROM DATASET_A11_Axis_A1_Axis
	WHERE BFC_TIMESTAMP >= (select max(BFC_TIMESTAMP) from MIN_SUMMARY_A11_A1)
	GROUP BY time, BFC_SOURCE_ID
	ORDER BY time
    ON DUPLICATE KEY UPDATE
		DATAPOINT_A11_Position = VALUES(DATAPOINT_A11_Position),
		DATAPOINT_A11_Current = VALUES(DATAPOINT_A11_Current),
		DATAPOINT_A11_Torque = VALUES(DATAPOINT_A11_Torque),
		DATAPOINT_A1_Position = VALUES(DATAPOINT_A1_Position),
		DATAPOINT_A1_Current = VALUES(DATAPOINT_A1_Current),
		DATAPOINT_A1_Torque = VALUES(DATAPOINT_A1_Torque);

-- ////////////////////////////////////////////////////////////////////////////////////

CREATE EVENT update_min_summary_a2_z
ON SCHEDULE 
	EVERY 1 MINUTE
DO
	INSERT INTO MIN_SUMMARY_A2_Z (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_A2_Position, DATAPOINT_A2_Current, DATAPOINT_A2_Torque, DATAPOINT_Z_Position, DATAPOINT_Z_Current, DATAPOINT_Z_Torque)
	SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		MIN(DATAPOINT_A2_Position),
		MIN(DATAPOINT_A2_Current),
		MIN(DATAPOINT_A2_Torque),
		MIN(DATAPOINT_Z_Position),
		MIN(DATAPOINT_Z_Current),
		MIN(DATAPOINT_Z_Torque)
	FROM DATASET_A2_Axis_Z_Axis
  WHERE BFC_TIMESTAMP >= (select max(BFC_TIMESTAMP) from MIN_SUMMARY_A2_Z)
	GROUP BY time, BFC_SOURCE_ID
	ORDER BY time
    ON DUPLICATE KEY UPDATE
		DATAPOINT_A2_Position = VALUES(DATAPOINT_A2_Position),
		DATAPOINT_A2_Current = VALUES(DATAPOINT_A2_Current),
		DATAPOINT_A2_Torque = VALUES(DATAPOINT_A2_Torque),
		DATAPOINT_Z_Position = VALUES(DATAPOINT_Z_Position),
		DATAPOINT_Z_Current = VALUES(DATAPOINT_Z_Current),
		DATAPOINT_Z_Torque = VALUES(DATAPOINT_Z_Torque);

-- ////////////////////////////////////////////////////////////////////////////////////

CREATE EVENT update_min_summary_w_q1
ON SCHEDULE 
	EVERY 1 MINUTE
DO
	INSERT INTO MIN_SUMMARY_W_Q1 (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_W_Position, DATAPOINT_W_Current, DATAPOINT_W_Torque, DATAPOINT_Q1_Position, DATAPOINT_Q1_Current, DATAPOINT_Q1_Torque)
	SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		MIN(DATAPOINT_W_Position),
		MIN(DATAPOINT_W_Current),
		MIN(DATAPOINT_W_Torque),
		MIN(DATAPOINT_Q1_Position),
		MIN(DATAPOINT_Q1_Current),
		MIN(DATAPOINT_Q1_Torque)
	FROM DATASET_W_Axis_Q1_Axis
  WHERE BFC_TIMESTAMP >= (select max(BFC_TIMESTAMP) from MIN_SUMMARY_W_Q1)
	GROUP BY time, BFC_SOURCE_ID
	ORDER BY time
    ON DUPLICATE KEY UPDATE
		DATAPOINT_W_Position = VALUES(DATAPOINT_W_Position),
		DATAPOINT_W_Current = VALUES(DATAPOINT_W_Current),
		DATAPOINT_W_Torque = VALUES(DATAPOINT_W_Torque),
		DATAPOINT_Q1_Position = VALUES(DATAPOINT_Q1_Position),
		DATAPOINT_Q1_Current = VALUES(DATAPOINT_Q1_Current),
		DATAPOINT_Q1_Torque = VALUES(DATAPOINT_Q1_Torque);

-- ////////////////////////////////////////////////////////////////////////////////////

CREATE EVENT update_min_summary_c_b
ON SCHEDULE 
	EVERY 1 MINUTE
DO
	INSERT INTO MIN_SUMMARY_C_B (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_C_Position, DATAPOINT_C_Current, DATAPOINT_C_Torque, DATAPOINT_B_Position, DATAPOINT_B_Current, DATAPOINT_B_Torque)
	SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		MIN(DATAPOINT_C_Position),
		MIN(DATAPOINT_C_Current),
		MIN(DATAPOINT_C_Torque),
		MIN(DATAPOINT_B_Position),
		MIN(DATAPOINT_B_Current),
		MIN(DATAPOINT_B_Torque)
	FROM DATASET_C_Axis_B_Axis
  WHERE BFC_TIMESTAMP >= (select max(BFC_TIMESTAMP) from MIN_SUMMARY_C_B)
	GROUP BY time, BFC_SOURCE_ID
	ORDER BY time
    ON DUPLICATE KEY UPDATE
		DATAPOINT_C_Position = VALUES(DATAPOINT_C_Position),
		DATAPOINT_C_Current = VALUES(DATAPOINT_C_Current),
		DATAPOINT_C_Torque = VALUES(DATAPOINT_C_Torque),
		DATAPOINT_B_Position = VALUES(DATAPOINT_B_Position),
		DATAPOINT_B_Current = VALUES(DATAPOINT_B_Current),
		DATAPOINT_B_Torque = VALUES(DATAPOINT_B_Torque);

-- ////////////////////////////////////////////////////////////////////////////////////

CREATE EVENT update_min_summary_x_y
ON SCHEDULE 
	EVERY 1 MINUTE
DO
	INSERT INTO MIN_SUMMARY_X_Y (BFC_TIMESTAMP, BFC_SOURCE_ID, DATAPOINT_X_Position, DATAPOINT_X_Current, DATAPOINT_X_Torque, DATAPOINT_Y_Position, DATAPOINT_Y_Current, DATAPOINT_Y_Torque)
	SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(BFC_TIMESTAMP) DIV 60 * 60) AS time,
		BFC_SOURCE_ID,
		MIN(DATAPOINT_X_Position),
		MIN(DATAPOINT_X_Current),
		MIN(DATAPOINT_X_Torque),
		MIN(DATAPOINT_Y_Position),
		MIN(DATAPOINT_Y_Current),
		MIN(DATAPOINT_Y_Torque)
	FROM DATASET_X_Axis_Y_Axis
  WHERE BFC_TIMESTAMP >= (select max(BFC_TIMESTAMP) from MIN_SUMMARY_X_Y)
	GROUP BY time, BFC_SOURCE_ID
	ORDER BY time
    ON DUPLICATE KEY UPDATE
		DATAPOINT_X_Position = VALUES(DATAPOINT_X_Position),
		DATAPOINT_X_Current = VALUES(DATAPOINT_X_Current),
		DATAPOINT_X_Torque = VALUES(DATAPOINT_X_Torque),
		DATAPOINT_Y_Position = VALUES(DATAPOINT_Y_Position),
		DATAPOINT_Y_Current = VALUES(DATAPOINT_Y_Current),
		DATAPOINT_Y_Torque = VALUES(DATAPOINT_Y_Torque);

-- ////////////////////////////////////////////////////////////////////////////////////

-- disable events
ALTER EVENT update_min_summary_a2_z
disable;

ALTER EVENT update_min_summary_a11_a1
disable;

ALTER EVENT update_min_summary_c_b
disable;

ALTER EVENT update_min_summary_w_q1
disable;

ALTER EVENT update_min_summary_x_y
disable;

-- show all events
show events