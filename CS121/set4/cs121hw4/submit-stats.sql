-- [Problem 1]

DROP FUNCTION IF EXISTS max_submit_interval;
DROP FUNCTION IF EXISTS min_submit_interval;
DROP FUNCTION IF EXISTS avg_submit_interval;

-- Set the "end of statement" character to ! so that
-- semicolons in the function body won't confuse MySQL.
DELIMITER !
-- Returns the maximum time between submissions 
-- for a particular assignment "sub"
CREATE FUNCTION max_submit_interval(sub INTEGER) RETURNS INTEGER
BEGIN
    DECLARE max_so_far INTEGER DEFAULT 0;
    DECLARE first_sub TIMESTAMP;
    DECLARE second_sub TIMESTAMP;
    DECLARE current_int INTEGER;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        (SELECT sub_date FROM fileset WHERE sub_id = sub ORDER BY sub_date);
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000'
        SET done = 1;
    OPEN cur;
    FETCH cur INTO first_sub;
    WHILE NOT done DO
        FETCH cur INTO second_sub;
        IF NOT done THEN
            SET current_int =  UNIX_TIMESTAMP(second_sub) -
            UNIX_TIMESTAMP(first_sub);
            SET first_sub = second_sub;
            IF current_int > max_so_far
            THEN SET max_so_far = current_int;
            END IF;
        END IF;
    END WHILE;
    RETURN max_so_far;
END !

-- [Problem 2]

-- Returns the mimimum time between submissions 
-- for a particular assignment "sub"
CREATE FUNCTION min_submit_interval(sub INTEGER) RETURNS INTEGER
BEGIN
    DECLARE min_so_far INTEGER DEFAULT 2147483647; -- max value for int
    DECLARE first_sub TIMESTAMP;
    DECLARE second_sub TIMESTAMP;
    DECLARE current_int INTEGER;
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        (SELECT sub_date FROM fileset WHERE sub_id = sub ORDER BY sub_date);
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000'
        SET done = 1;
    OPEN cur;
    FETCH cur INTO first_sub;
    WHILE NOT done DO
        FETCH cur INTO second_sub;
        IF NOT done THEN
            SET current_int =  UNIX_TIMESTAMP(second_sub) - 
                               UNIX_TIMESTAMP(first_sub);
            SET first_sub = second_sub;
            IF current_int < min_so_far
            THEN SET min_so_far = current_int;
            END IF;
        END IF;
    END WHILE;
    RETURN min_so_far;
END !

-- [Problem 3]

-- Returns the average time between submissions 
-- for a particular assignment "sub"
CREATE FUNCTION avg_submit_interval(sub INTEGER) RETURNS DOUBLE
BEGIN
    DECLARE min_so_far INTEGER DEFAULT 2147483647; -- max value for int
    DECLARE first_sub INTEGER;
    DECLARE last_sub INTEGER;
    DECLARE int_num INTEGER;
    SET first_sub = (SELECT UNIX_TIMESTAMP(MIN(sub_date)) 
                     FROM fileset 
                     WHERE sub_id = sub);
    SET last_sub = (SELECT UNIX_TIMESTAMP(MAX(sub_date)) 
                    FROM fileset 
                    WHERE sub_id = sub);
    SET int_num = (SELECT COUNT(sub_date) - 1 FROM fileset WHERE sub_id = sub);
    RETURN ((last_sub - first_sub) / int_num);
END !


-- Back to the standard SQL delimiter
DELIMITER ;


EXPLAIN SELECT MIN(UNIX_TIMESTAMP(sub_date)) FROM fileset WHERE sub_id = 5344;
EXPLAIN SELECT UNIX_TIMESTAMP(MIN(sub_date)) FROM fileset WHERE sub_id = 5344;

-- [Problem 4]

CREATE INDEX idx_sub ON fileset(sub_id, sub_date);

-- Runs in about 0.4 seconds, down from about 2.8 seconds

SELECT sub_id,
 min_submit_interval(sub_id) AS min_interval,
 max_submit_interval(sub_id) AS max_interval,
 avg_submit_interval(sub_id) AS avg_interval
FROM (SELECT sub_id FROM fileset
 GROUP BY sub_id HAVING COUNT(*) > 1) AS multi_subs
ORDER BY min_interval, max_interval;

