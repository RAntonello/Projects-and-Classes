-- PLEASE DO NOT INCLUDE date-udfs HERE!!!

-- [Problem 4a]

-- Populate resource_dim
INSERT INTO resource_dim(resource, method, protocol, response)
SELECT DISTINCT resource, method, protocol, response
FROM raw_web_log;

-- [Problem 4b]

-- Populate visitor_dim
INSERT INTO visitor_dim(ip_addr, visit_val)
SELECT DISTINCT ip_addr, visit_val
FROM raw_web_log;

-- [Problem 4c]

DROP PROCEDURE IF EXISTS populate_dates;

DELIMITER !

-- This function populates the datetime_dim table with the dates
-- from d_start to d_end, computing whether each day is a holiday
-- and whether it is a weekend.
CREATE PROCEDURE populate_dates(d_start DATE, d_end DATE)
BEGIN
    DECLARE d DATE;
    DECLARE h INTEGER;
    DELETE FROM datetime_dim WHERE date_val BETWEEN d_start AND d_end;
	SET d = d_start;
    WHILE d <= d_end DO 
        SET h = 0;
        WHILE h <= 23 DO
            INSERT INTO datetime_dim(date_val, hour_val, weekend, holiday) 
			SELECT d, h, is_weekend(d), is_holiday(d) IS NOT NULL;
            SET h = h + 1;
	    END WHILE;
    SET d = d + INTERVAL 1 DAY;
    END WHILE;
END !
DELIMITER ;

-- Populate the datetime_dim table with relevant dates
CALL populate_dates('1995-01-01', '1995-12-31');

-- [Problem 5a]

-- Populate resource_fact by computing each value
-- for each pair of dates and resources
INSERT INTO resource_fact(date_id, resource_id, num_requests, total_bytes)
SELECT date_id, resource_id, COUNT(*), SUM(bytes_sent) 
FROM (raw_web_log JOIN datetime_dim ON 
         (DATE(raw_web_log.logtime) <=> datetime_dim.date_val AND
         HOUR(raw_web_log.logtime) <=> datetime_dim.hour_val))
    JOIN resource_dim ON 
        (raw_web_log.resource <=> resource_dim.resource AND
         raw_web_log.method   <=> resource_dim.method AND
         raw_web_log.protocol <=> resource_dim.protocol AND
         raw_web_log.response <=> resource_dim.response)
GROUP BY date_id, resource_id;

-- [Problem 5b]

-- Populates visitor_fact by computing each value for
-- each pair of dates and visitors
INSERT INTO visitor_fact(date_id, visitor_id, num_requests, total_bytes)
SELECT date_id, visitor_id, COUNT(*), SUM(bytes_sent) 
FROM (raw_web_log JOIN datetime_dim ON 
         (DATE(raw_web_log.logtime) <=> datetime_dim.date_val AND
         HOUR(raw_web_log.logtime) <=> datetime_dim.hour_val))
    JOIN visitor_dim ON 
        raw_web_log.visit_val <=> visitor_dim.visit_val
GROUP BY date_id, visitor_id;