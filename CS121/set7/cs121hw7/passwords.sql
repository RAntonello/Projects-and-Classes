DROP TABLE IF EXISTS user_info;
DROP PROCEDURE IF EXISTS sp_add_user;
DROP PROCEDURE IF EXISTS sp_change_password;
DROP FUNCTION IF EXISTS authenticate;


-- [Problem 1a]

-- Create table to hold user accounts
CREATE TABLE user_info (
  -- The username of the user
  username VARCHAR(20) PRIMARY KEY,

  -- The salt for the hash
  salt CHAR(6),

  -- The hash of the specified user's password
  password_hash CHAR(64)
);

-- [Problem 1b]

DELIMITER !

-- Create a new account, with username new_username and password password
CREATE PROCEDURE sp_add_user(
IN new_username VARCHAR(20),
IN password VARCHAR(20)
)
BEGIN
    DECLARE salt_val CHAR(6);
    DECLARE hash_pass CHAR(64);
    SET salt_val = make_salt(6);
    SET hash_pass = SHA2(CONCAT(salt_val, password), 256);
    INSERT INTO user_info
        VALUES (new_username, salt_val, hash_pass)
    ON DUPLICATE KEY 
        UPDATE salt = salt_val, 
			   password_hash = hash_pass;
END; ! 


-- [Problem 1c]

-- Change the password of username's account
CREATE PROCEDURE sp_change_password(
IN username VARCHAR(20),
IN new_password VARCHAR(20)
)
BEGIN
    DECLARE salt_val CHAR(6);
    DECLARE hash_pass CHAR(64);
    SET salt_val = make_salt(6);
    -- Hash the password with the salt
    SET hash_pass = SHA2(CONCAT(salt_val, new_password), 256);
    UPDATE user_info
        SET password_hash = hash_pass,
            salt = salt_val
		WHERE user_info.username = username;
END; ! 

-- [Problem 1d]

-- Returns TRUE if the username exists in user_info and the password
-- is correct, and false otherwise.
CREATE FUNCTION authenticate(username VARCHAR(20), password VARCHAR(20)) RETURNS BOOLEAN
BEGIN
    DECLARE hashed_pass VARCHAR(64);
    DECLARE actual_hash VARCHAR(64);
    DECLARE salt_val CHAR(6);
    -- Check to see if the username is a real username
    IF username NOT IN (SELECT user_info.username FROM user_info)
        THEN
        RETURN FALSE;
        ELSE
        SET actual_hash = (SELECT password_hash 
                           FROM user_info 
                           WHERE username = user_info.username);
        SET salt_val = (SELECT salt 
                        FROM user_info
                        WHERE username = user_info.username);
		-- Check to see if the password is correct
        RETURN SHA2(CONCAT(salt_val, password), 256) = actual_hash;
	END IF;
END !

DELIMITER ;
