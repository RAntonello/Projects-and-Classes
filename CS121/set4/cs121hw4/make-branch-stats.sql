-- [Problem 1]

CREATE INDEX idx_bal ON account(branch_name, balance);

-- [Problem 2]

DROP TABLE IF EXISTS mv_branch_account_stats;
DROP TABLE IF EXISTS depositor;
DROP TABLE IF EXISTS borrower;
DROP TABLE IF EXISTS branch;
DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS customer;

CREATE TABLE mv_branch_account_stats (
    branch_name     VARCHAR(15) NOT NULL,
    total_deposits  INTEGER NOT NULL,
    avg_balance     NUMERIC(12, 2) NOT NULL,
    min_balance     NUMERIC(12, 2) NOT NULL,
    max_balance     NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (branch_name)
);

-- [Problem 3]

INSERT INTO mv_branch_account_stats
SELECT branch_name, COUNT(balance), AVG(balance), MIN(balance), MAX(balance)
FROM account GROUP BY branch_name; 

-- [Problem 4]

DROP VIEW IF EXISTS branch_account_stats;

CREATE VIEW branch_account_stats AS
    SELECT branch_name,
    COUNT(*) AS num_accounts,
    SUM(balance) AS total_deposits,
    AVG(balance) AS avg_balance,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance
    FROM account GROUP BY branch_name;



-- [Problem 5]

DROP TRIGGER IF EXISTS trg_insert;
DROP TRIGGER IF EXISTS trg_delete;
DROP TRIGGER IF EXISTS trg_update;
DROP PROCEDURE IF EXISTS add_bal;
DROP PROCEDURE IF EXISTS delete_bal;

DELIMITER !

CREATE PROCEDURE add_bal(
IN ins_bal NUMERIC(12, 2),
IN branch_name VARCHAR(15)
)
BEGIN
    INSERT INTO mv_branch_account_stats 
        VALUES (branch_name, 1, ins_bal, ins_bal, ins_bal)
    ON DUPLICATE KEY 
        UPDATE total_deposits = total_deposits + 1, 
               avg_balance = avg_balance + 
                   ((ins_bal - avg_balance) / total_deposits),
               min_balance = LEAST(min_balance, ins_bal),
               max_balance = GREATEST(max_balance, ins_bal);
END; ! 


CREATE TRIGGER trg_insert AFTER INSERT ON account FOR EACH ROW
BEGIN
    CALL add_bal(NEW.balance, NEW.branch_name);
END; ! 

-- [Problem 6]

CREATE PROCEDURE delete_bal(
IN del_bal NUMERIC(12, 2),
IN del_branch VARCHAR(15)
)
BEGIN
    IF (SELECT total_deposits 
        FROM mv_branch_account_stats 
        WHERE branch_name = del_branch) = 1
    THEN 
    DELETE FROM mv_branch_account_stats 
           WHERE branch_name = del_branch;
    ELSE 
        UPDATE mv_branch_account_stats 
            SET total_deposits = total_deposits - 1,
                avg_balance = avg_balance - 
                    ((del_bal - avg_balance) / total_deposits),
                min_balance = (SELECT MIN(balance) 
                               FROM account 
                               WHERE branch_name = del_branch),
                max_balance = (SELECT MAX(balance) 
                               FROM account 
                               WHERE branch_name = del_branch)
                WHERE branch_name = del_branch;
    END IF;
END; !

CREATE TRIGGER trg_delete AFTER DELETE ON account FOR EACH ROW
BEGIN
    CALL delete_bal(OLD.balance, OLD.branch_name);
END; ! 


-- [Problem 7]

CREATE TRIGGER trg_update AFTER UPDATE ON account FOR EACH ROW
BEGIN
    CALL add_bal(NEW.balance, NEW.branch_name);
    CALL delete_bal(OLD.balance, OLD.branch_name);
END; ! 

DELIMITER ;