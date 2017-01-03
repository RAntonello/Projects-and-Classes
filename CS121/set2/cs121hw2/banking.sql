-- [Problem 1a]

-- Retrieve loans with amounts between 1000 and 2000.

SELECT loan_number, amount
FROM loan
WHERE amount BETWEEN 1000 AND 2000;


-- [Problem 1b]

-- Retrieve loans owned by Smith, ordered by increasing loan number.

SELECT loan.loan_number, amount
FROM loan NATURAL JOIN borrower
WHERE (customer_name = 'Smith')
ORDER BY loan_number;



-- [Problem 1c]

-- Retrieve the branch city where account 'A-446' is open.

SELECT branch_city 
FROM branch 
WHERE branch_name = 
(SELECT branch_name
FROM account
WHERE account_number = 'A-446');

-- [Problem 1d]

-- Retrieve accounts starting with "J", ordered by increasing customer name.

SELECT account.account_number, branch_name, balance, customer_name 
FROM account NATURAL JOIN depositor
WHERE (customer_name LIKE 'J%')
ORDER BY customer_name;

-- [Problem 1e]

-- Retrieve names of all customers with more than five bank accounts. 

SELECT customer_name
FROM (SELECT customer_name, COUNT(customer_name) as acct_num
      FROM depositor
      GROUP BY customer_name) as acct_nums
WHERE acct_num > 5;


-- [Problem 2a]

-- Create a view called pownal_customers with the account numbers
-- and customer names for all accounts in the Pownal branch.

CREATE VIEW pownal_customers AS
    (SELECT account.account_number, customer_name
     FROM account NATURAL JOIN depositor
     WHERE (branch_name = 'Pownal'));

-- [Problem 2b]

-- Creates a view called onlyacct_customers with the name, 
-- street, and city of all customers that have an account but
-- not a loan with the bank. 

CREATE VIEW onlyacct_customers AS
SELECT *
FROM customer
WHERE customer.customer_name IN 
(SELECT depositor.customer_name 
 FROM   depositor
 WHERE (customer_name NOT IN (SELECT customer_name FROM borrower)));

-- Check to see if table is updatable as expected.

SELECT table_name, is_updatable
FROM information_schema.views;

-- [Problem 2c]

-- Creates a view called branch_deposits that lists all branches along
-- with their total account balance and average account balance. 

CREATE VIEW branch_deposits AS
SELECT branch.branch_name, IFNULL(SUM(balance), 0) AS total_bal, 
       AVG(balance) AS avg_bal
FROM branch LEFT OUTER JOIN account ON branch.branch_name = account.branch_name
GROUP BY branch.branch_name;

-- [Problem 3a]

-- Returns all cities that customers live in, 
-- where there are no bank branches in that city.

SELECT DISTINCT customer_city
FROM customer
WHERE customer_city NOT IN 
     (SELECT branch_city FROM branch) ORDER BY customer_city;

-- [Problem 3b]

-- Returns all customers that have neither an account nor a loan.

SELECT customer_name
FROM customer
WHERE customer_name NOT IN (SELECT customer_name FROM borrower)
AND customer_name NOT IN (SELECT customer_name FROM depositor);

-- [Problem 3c]

-- Make a $50 gift-deposit to all customers in Horseneck.

UPDATE account
SET balance = balance + 50
WHERE branch_name IN 
     (SELECT branch_name FROM branch WHERE branch_city = 'Horseneck'); 

-- [Problem 3d]

-- Make a $50 gift-deposit to all customers in Horseneck.

UPDATE account, 
   (SELECT branch_name FROM branch WHERE branch_city = 'Horseneck') 
        as HN_branches
SET balance = balance + 50;

-- [Problem 3e]

-- Retrieve all details for the largest account at each bank branch.

SELECT account.account_number, account.branch_name, balance
FROM account NATURAL JOIN 
        (SELECT branch_name, MAX(balance) AS max_bal
        FROM account 
        GROUP BY branch_name) 
AS top_accts
WHERE balance = max_bal;

-- [Problem 3f]

-- Retrieve all details for the largest account at each bank branch.

SELECT account.account_number, branch_name, balance
FROM account
WHERE (branch_name, balance) IN 
      (SELECT branch_name, MAX(balance) 
      FROM account 
      GROUP BY branch_name);

-- [Problem 4]

-- Computes the rank of all bank branches by asset amount.
-- Order the results by decreasing rank and then by increasing branch name.

SELECT branch.branch_name, branch.assets, COUNT(branch.branch_name) AS rank
FROM branch, branch AS test
WHERE branch.assets < test.assets
GROUP BY branch_name
ORDER BY rank desc, branch_name;