-- [Problem 1]

-- Project attribute A using database r

SELECT DISTINCT A
FROM r;

-- [Problem 2]

-- Select all tuples from r where b=17.

SELECT * 
FROM r
WHERE B=17;

-- [Problem 3]

-- r x s

SELECT *
FROM r, s;

-- [Problem 4]

-- Project attributes A and F for tuples where C=D in database r x s

SELECT DISTINCT A,F
FROM r, s
WHERE C=D;

-- [Problem 5]

-- r1 union r2

(SELECT * FROM r1) UNION (SELECT * FROM r2);

-- [Problem 6]

-- r1 intersection r2

(SELECT * FROM r1) INTERSECT (SELECT * FROM r2);

-- [Problem 7]

-- r1 minus r2

(SELECT * FROM r1) EXCEPT (SELECT * FROM r2);

