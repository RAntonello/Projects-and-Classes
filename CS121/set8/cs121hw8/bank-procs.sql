
-- [Problem 1]

DROP PROCEDURE IF EXISTS sp_deposit;
DROP PROCEDURE IF EXISTS sp_withdraw;
DROP PROCEDURE IF EXISTS sp_transfer;

DELIMITER !

-- This procedure deposits amount into account account_number_mod. It
-- is repeatable-read safe.
CREATE PROCEDURE sp_deposit(account_number_mod VARCHAR(15), 
    amount NUMERIC(12, 2), OUT status INTEGER)
BEGIN
    DECLARE current_balance NUMERIC(12, 2);
    SET status = 0;
    -- Status of -1 if amount is negative
    IF amount < 0
    THEN 
        SET status = -1;
    ELSE
        START TRANSACTION;
        SELECT balance INTO current_balance
        FROM account
        WHERE account_number_mod = account_number
            FOR UPDATE; -- Add read lock
        IF (current_balance IS NULL) -- If account does not exist
        THEN
            SET status = -2;
            ROLLBACK; 
        ELSE 
            UPDATE account -- Actually deposit money / update
                SET balance = balance + amount
                WHERE account_number = account_number_mod;
            COMMIT; -- End read lock
        END IF;
    END IF;
END; !




-- [Problem 2]
-- This procedure withdraws amount from account_number_mod. It
-- is repeatable-read safe.
 CREATE PROCEDURE sp_withdraw(account_number_mod VARCHAR(15), 
    amount NUMERIC(12, 2), OUT status INTEGER)
BEGIN
    DECLARE current_balance NUMERIC(12, 2);
    SET status = 0;
    IF amount < 0 -- Can't withdraw negative amount
    THEN 
        SET status = -1;
    ELSE
        START TRANSACTION; 
        SELECT balance INTO current_balance
        FROM account
        WHERE account_number_mod = account_number
            FOR UPDATE; -- Activate read lock
        IF (current_balance IS NULL) -- if account doesn't exist
        THEN
            SET status = -2;
            ROLLBACK;
        ELSE 
            IF (current_balance < amount) -- If overdrafting
            THEN 
                SET status = -3;
                ROLLBACK;
            ELSE 
                UPDATE account 
                    SET balance = current_balance - amount
                    WHERE account_number = account_number_mod;
                COMMIT; -- End read lock
            END IF;
        END IF;
    END IF;
END; !



-- [Problem 3]
-- This procedure transfers amount from account_1_number to
-- account_2_ number. It is repeatable-read safe.
CREATE PROCEDURE sp_transfer(account_1_number VARCHAR(15), 
    amount NUMERIC(12, 2), account_2_number VARCHAR(15),  OUT status INTEGER)
BEGIN
    DECLARE current_balance_1 NUMERIC(12, 2);
    DECLARE current_balance_2 NUMERIC(12, 2);
    SET status = 0;
    IF amount < 0
    THEN 
        SET status = -1;
    ELSE
        START TRANSACTION;
        SELECT balance INTO current_balance_1
        FROM account
        WHERE account_number = account_1_number
            FOR UPDATE;
        SELECT balance INTO current_balance_2
        FROM account
        WHERE account_number = account_2_number
            FOR UPDATE;
        -- Test if accounts exist
        IF (current_balance_1 IS NULL) OR (current_balance_2 IS NULL) 
        THEN
            SET status = -2;
            ROLLBACK;
        ELSE 
            -- Test if first account is overdrawn
            IF (current_balance_1 < amount)
            THEN 
                SET status = -3;
                ROLLBACK;
            ELSE 
            -- Modify account values
                UPDATE account 
                    SET balance = current_balance_1 - amount
                    WHERE account_number = account_1_number;
                IF (ROW_COUNT() < 1) -- If balance wasn't updated for
                -- some concurrency reason
                THEN 
                    SET status = -2;
                    ROLLBACK;
                ELSE
                    UPDATE account 
                        SET balance = current_balance_2 + amount
                        WHERE account_number = account_2_number;
                    COMMIT; -- End read lock
                END IF;
            END IF;
        END IF;
    END IF;
END; !

DELIMITER ;
