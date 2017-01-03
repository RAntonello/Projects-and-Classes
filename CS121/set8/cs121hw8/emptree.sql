
-- [Problem 1]

-- Drop tables/functions

DROP TABLE IF EXISTS emps;
DROP TABLE IF EXISTS depths;
DROP FUNCTION IF EXISTS total_salaries_adjlist;
DROP FUNCTION IF EXISTS total_salaries_nestset;
DROP FUNCTION IF EXISTS tree_depth;
DROP FUNCTION IF EXISTS emp_reports;

CREATE TABLE emps
( emp_id VARCHAR(30) NOT NULL
 );

DELIMITER !
-- Computes the salaries of all employees at or below the specified
-- node. Assumes that emps is empty.
CREATE FUNCTION total_salaries_adjlist(emp_id1 INTEGER) RETURNS INTEGER
BEGIN
    DECLARE sum INTEGER;
    INSERT INTO emps VALUES (emp_id1);
    WHILE (ROW_COUNT() > 0) DO -- As long as iterations
        INSERT INTO emps       -- continue to add values
            SELECT emp_id FROM employee_adjlist -- Go down the subtree
                WHERE manager_id IN (SELECT * FROM emps)
                    AND emp_id NOT IN (SELECT * FROM emps);
    END WHILE;
    -- Sum the salaries of all employees in the subtree
    SET sum = (SELECT SUM(salary) FROM employee_adjlist 
        WHERE emp_id IN (SELECT emp_id FROM emps));
    RETURN sum;
END !




-- [Problem 2]

-- Computes the salaries of all employees at or below the specified
-- node.
CREATE FUNCTION total_salaries_nestset(emp_id1 INTEGER) RETURNS INTEGER
BEGIN
    DECLARE emp_low INTEGER;
    DECLARE emp_high INTEGER;
    DECLARE sum INTEGER;
    -- Get the low and high range values for the employee
    SET emp_low = (SELECT low FROM employee_nestset WHERE emp_id = emp_id1);
    SET emp_high = (SELECT high FROM employee_nestset WHERE emp_id = emp_id1);
    -- Get the sum of the salaries of all employees in that range
    SET sum = (SELECT SUM(salary) FROM employee_nestset 
        WHERE emp_low <= low AND emp_high >= high);
    RETURN sum;
END !

DELIMITER ;

-- [Problem 3]

-- Selects all leaves in the hierarchy using the adjacency list
SELECT emp_id, name, salary
FROM employee_adjlist
WHERE emp_id NOT IN -- Anyone who is not a manager is a leaf
    (SELECT DISTINCT manager_id 
     FROM employee_adjlist 
     WHERE manager_id IS NOT NULL);

-- [Problem 4]

-- Selects all leaves in the hierarchy using the nested set
SELECT emp_id, name, salary
FROM employee_nestset AS test1
WHERE NOT EXISTS -- Its a leaf if it there isn't any employee 
    (SELECT *    -- between its low and high
    FROM employee_nestset AS test2 
    WHERE test1.low < test2.low AND test1.high > test2.high);

-- [Problem 5]

CREATE TABLE depths
( emp_id VARCHAR(30) NOT NULL,
  depth  INTEGER 
 );


DELIMITER !


-- The function uses the adjacency table because the relationships
-- between nodes are much more obvious which is useful for
-- a function that examines the structure of the tree.

-- Returns the depth of the hierarchy table. Assumes depths is empty.
CREATE FUNCTION tree_depth() RETURNS INTEGER
BEGIN
    DECLARE root INTEGER;
    DECLARE current_depth INTEGER DEFAULT 0;
    SET root = (SELECT emp_id  -- The root is the person without a manager
                FROM employee_adjlist 
                WHERE manager_id IS NULL);
    INSERT INTO depths VALUES (root, current_depth);
    WHILE (ROW_COUNT() > 0) DO -- Iterate through layers of tree
        SET current_depth =  current_depth + 1; --  one layer deeper
        INSERT INTO depths       -- continue to add values until layers are done
            SELECT emp_id, current_depth
            FROM employee_adjlist 
            WHERE manager_id IN (SELECT emp_id FROM depths)
                AND emp_id NOT IN (SELECT emp_id FROM depths);
    END WHILE;
    RETURN current_depth; -- Return lowest layer number
END !


-- [Problem 6]

-- To count the number of children of a particular parent node,
-- we want to count the number of nodes for which there is
-- no other node with a low between its low and the parent low 
-- and a high between its high and the parent high

-- Computes the number of direct reports for employee emp_id1
CREATE FUNCTION emp_reports(emp_id1 INTEGER) RETURNS INTEGER
BEGIN
    DECLARE emp_low INTEGER;
    DECLARE emp_high INTEGER;
    DECLARE child_count INTEGER;
    -- Get the low and high range values for the employee being considered
    SET emp_low = (SELECT low FROM employee_nestset WHERE emp_id = emp_id1);
    SET emp_high = (SELECT high FROM employee_nestset WHERE emp_id = emp_id1);
    SET child_count = 
    -- Find all the descendants that don't have intermediate nodes 
    -- between the parent and the potential child
    (SELECT COUNT(emp_id)
        FROM employee_nestset as potential_child
        WHERE NOT EXISTS
            (SELECT *
            FROM employee_nestset as other_tables
            WHERE other_tables.low 
                BETWEEN emp_low + 1 AND potential_child.low - 1
            AND other_tables.high 
                BETWEEN potential_child.high + 1 AND emp_high - 1)
            AND emp_low < potential_child.low 
            AND emp_high > potential_child.high);
    RETURN child_count;
END !

DELIMITER ;


SELECT total_salaries_nestset(100699);


INSERT INTO depths VALUES (100001, 1);

SELECT emp_reports(100105);

