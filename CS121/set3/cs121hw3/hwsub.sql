-- [Problem 1a]

-- Returns the perfect score for the course
SELECT SUM(perfectscore) FROM assignment;

-- [Problem 1b]

-- Returns table with section name and the number of students in that section
SELECT sec_name, COUNT(username)
FROM student NATURAL JOIN section
GROUP BY sec_name;

-- [Problem 1c]

DROP VIEW IF EXISTS totalscores;

-- Creates a view called totalscores that associates each username 
-- with its total score in the class

CREATE VIEW totalscores AS
SELECT username, SUM(score) as score
FROM student NATURAL JOIN submission
WHERE graded = 1 GROUP BY username;


-- [Problem 1d]

DROP VIEW IF EXISTS passing;

CREATE VIEW passing AS
SELECT username, score
FROM totalscores 
WHERE score >= 40;

-- [Problem 1e]

DROP VIEW IF EXISTS failing;

CREATE VIEW failing AS
SELECT username, score
FROM totalscores 
WHERE score < 40;

-- [Problem 1f]

-- Returns all students that passed the course but did not submit all labs
SELECT DISTINCT username
FROM submission
WHERE asn_id IN (SELECT asn_id FROM assignment WHERE shortname LIKE 'lab%') 
      AND submission.sub_id NOT IN (SELECT sub_id FROM fileset)
      AND username IN (SELECT username FROM passing);

-- Returns harris, ross, miller, turner, edwards, murphy, simmons, tucker, coleman, flores, gibson

-- [Problem 1g]

-- Returns all students that passed the course but did not submit either the midterm or final
SELECT DISTINCT username
FROM submission
WHERE asn_id IN (SELECT asn_id FROM assignment WHERE shortname = 'midterm' OR shortname = 'final') 
      AND submission.sub_id NOT IN (SELECT sub_id FROM fileset)
      AND username IN (SELECT username FROM passing);
	
-- Returns only collins (who did not take the final). What a boss.


-- [Problem 2a]

-- Returns a list of usernames of students who submitted their midterm after it was due.

SELECT DISTINCT username
FROM submission INNER JOIN fileset ON fileset.sub_id = submission.sub_id
WHERE (asn_id = (SELECT asn_id FROM assignment WHERE shortname = 'midterm')) 
AND (sub_date > (SELECT due FROM assignment WHERE shortname = 'midterm'));

-- [Problem 2b]

-- Returns how many lab assignments were submitted in each hour of the day

SELECT hour, COUNT(sub_id) as num_submits
FROM (SELECT sub_id, EXTRACT(HOUR from sub_date) as hour FROM fileset) as hours
GROUP BY hour;


-- [Problem 2c]

-- Reports the number of final exams that were submitted less than 30 minutes before it was due.

SELECT COUNT(sub_id) as num_submits
FROM fileset, (SELECT due FROM assignment WHERE shortname = 'final') as too_close
WHERE fileset.sub_date BETWEEN (too_close.due - INTERVAL 30 MINUTE) AND too_close.due;

-- [Problem 3a]

ALTER TABLE student 
ADD COLUMN email VARCHAR(200);

UPDATE student SET email = CONCAT(student.username, '@school.edu');

ALTER TABLE student CHANGE COLUMN email email VARCHAR(200) NOT NULL;

-- [Problem 3b]

ALTER TABLE assignment
ADD COLUMN submit_files BOOLEAN DEFAULT True;

UPDATE assignment SET submit_files = NOT (shortname LIKE 'dq%');

-- [Problem 3c]

CREATE TABLE gradescheme (
scheme_id INTEGER PRIMARY KEY,
scheme_desc VARCHAR(100) NOT NULL
);

INSERT INTO gradescheme(scheme_id, scheme_desc) VALUES (0, 'Lab assignment with min-grading'); 
INSERT INTO gradescheme(scheme_id, scheme_desc) VALUES (1, 'Daily Quiz');
INSERT INTO gradescheme(scheme_id, scheme_desc) VALUES (2, 'Midterm or final exam');

ALTER TABLE assignment
CHANGE COLUMN gradescheme scheme_id INTEGER NOT NULL;

ALTER TABLE assignment
ADD FOREIGN KEY (scheme_id) REFERENCES gradescheme(scheme_id);

DROP FUNCTION IF EXISTS is_weekend;
DROP FUNCTION IF EXISTS is_holiday;
-- [Problem 4a]

-- Set the "end of statement" character to ! so that
-- semicolons in the function body won't confuse MySQL.
DELIMITER !
-- Given a date value, returns TRUE if it is a weekend,
-- or FALSE if it is a weekday.
CREATE FUNCTION is_weekend(d DATE) RETURNS BOOLEAN
BEGIN
    DECLARE day_index INTEGER;
    SET day_index = DAYOFWEEK(d);
    RETURN (day_index = 1 OR day_index = 7);
END !
-- Back to the standard SQL delimiter
DELIMITER ;

-- [Problem 4b]

-- Set the "end of statement" character to ! so that
-- semicolons in the function body won't confuse MySQL.
DELIMITER !
-- Given a date value, returns the holiday that it occurs on, from the list
-- [New Year's Day, Memorial Day, Independence Day, Labor Day, Thanksgiving]
-- and returns null if it does not occur on any of those days.
CREATE FUNCTION is_holiday(d DATE) RETURNS VARCHAR(20)
BEGIN
    DECLARE day_of_week INTEGER;
    DECLARE day_num INTEGER;
    DECLARE month_num INTEGER;
    SET day_of_week = DAYOFWEEK(d);
    SET day_num = EXTRACT(DAY FROM d);
    SET month_num = EXTRACT(MONTH FROM d);
    IF day_num = 1 AND month_num = 1 
    THEN RETURN 'New Year\'s Day';
    ELSEIF (day_num BETWEEN 25 AND 31) AND (month_num = 5) AND (day_of_week = 2)
    THEN RETURN 'Memorial Day';
    ELSEIF day_num = 4 AND month_num = 7
    THEN RETURN 'Independence Day';
    ELSEIF (day_num BETWEEN 1 AND 7) AND (month_num = 9) AND (day_of_week = 2)
    THEN RETURN 'Labor Day';
    ELSEIF (day_num BETWEEN 22 AND 28) AND (month_num = 11) AND (day_of_week = 5)
    THEN RETURN 'Thanksgiving';
    ELSE RETURN NULL;
    END IF;
END !
-- Back to the standard SQL delimiter
DELIMITER ;

-- [Problem 5a]

-- Returns a count of how many submissions happened on each holiday

SELECT is_holiday(sub_date) as hol, COUNT(is_holiday(sub_date))
FROM (SELECT sub_date FROM fileset) as sub_times 
GROUP BY hol;

-- [Problem 5b]

-- Returns the number of submissions that occurred on weekdays
-- and the number that returned on weekends.

SELECT (CASE is_weekend(sub_date) WHEN 0 THEN 'weekday' 	
                                 WHEN 1 THEN 'weekend' END) AS day_or_end,
	   COUNT(sub_date)
FROM (SELECT sub_date FROM fileset) as sub_times 
GROUP BY day_or_end;
