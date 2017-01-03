-- [Problem a]

-- Orders the customers by the number of loans they have received, in descending order

-- Decorrelated:

SELECT customer_name, COUNT(loan_number) AS num_loans
FROM customer NATURAL LEFT JOIN borrower
GROUP BY customer_name ORDER BY num_loans DESC;

-- [Problem b]

-- Returns the branches that have loans in excess of their current assets

SELECT branch_name FROM branch b
WHERE assets < (SELECT SUM(amount) FROM loan l
 WHERE l.branch_name = b.branch_name);

-- Decorrelated:

SELECT branch_name
FROM branch NATURAL LEFT JOIN 
       (SELECT branch_name, SUM(amount) as total_loans 
       FROM loan l 
       GROUP BY branch_name) as totals
WHERE branch.assets < total_loans;


-- [Problem c]

-- Using correlated subqueries, write a SQL query that computes the
-- number of accounts and the number of	loans at each branch. The result schema should be
-- (branch_name, num_accounts, num_loans). Order the results by increasing branch name.

-- Corellated:

SELECT branch_name, 
	(SELECT COUNT(account_number) FROM account
 WHERE account.branch_name = branch.branch_name) AS num_accounts,
	(SELECT COUNT(loan_number) FROM loan
 WHERE loan.branch_name = branch.branch_name) AS num_loans
 FROM branch;

-- [Problem d]

-- Decorrelated:

SELECT branch_name, 
       COUNT(DISTINCT account_number) AS num_accounts, 
       COUNT(DISTINCT loan_number)    AS num_loans
FROM (branch NATURAL LEFT JOIN loan) NATURAL LEFT JOIN account
GROUP BY branch_name;