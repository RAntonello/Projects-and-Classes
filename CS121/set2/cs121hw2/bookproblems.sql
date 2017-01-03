-- [Problem 1a]

-- Returns the names of all students who have taken at least one CS course.

SELECT DISTINCT name
FROM takes NATURAL JOIN student 
WHERE (course_id LIKE 'CS-%');

-- [Problem 1c]

-- For each department, find the maximum salary 
-- of instructors in that department.

(SELECT dept_name, MAX(salary) AS max_sal
FROM instructor GROUP BY dept_name);

-- [Problem 1d]

--  Find the lowest, across all departments, 
--  of the per-department maximum salary.

SELECT MIN(max_sal) AS lowest_max_sal
FROM( 
(SELECT dept_name, MAX(salary) AS max_sal
FROM instructor GROUP BY dept_name) AS max_sals);

-- [Problem 2a]

-- Add CS-001 course.

INSERT into course VALUES ('CS-001', 'Weekly Seminar', 'Comp. Sci.', 00);

-- [Problem 2b]

-- Add CS-001 section.

INSERT into section VALUES ('CS-001', '1', 'Fall', '2009', null, null, null);

-- [Problem 2c]
-- Enroll every student in the Comp. Sci. department in the CS-001 section.

 INSERT into takes
 (SELECT ID, 'CS-001' AS course_id, 
             '1' AS sec_id, 
             'Fall' AS semester, 
             '2009' AS year, 
             null AS grade
        FROM student 
        WHERE dept_name = 'Comp. Sci.');
        
-- [Problem 2d]
-- Delete enrollments from the CS-001 seection where the student's name
-- is 'Chavez'.

DELETE FROM takes 
WHERE ID = 
(SELECT ID
FROM student 
WHERE NAME = 'Chavez') AND (course_id = 'CS-001') AND (sec_id = '1');

-- [Problem 2e]

-- Running this before deleting sections will just
-- automatically delete the section anyways because the
-- two tables are foreign-keyed.

-- Delete CS-001 course.

DELETE FROM course
WHERE course_id = 'CS-001';

-- [Problem 2f]

-- Delete all takes tuples with the word "database" as part of the title.

DELETE FROM takes
WHERE course_id = 
(SELECT course_id 
 FROM course
 WHERE LOWER(title) LIKE '%database%');

-- [Problem 3a]

-- Get the names of members who have borrowed any book
-- published by "McGraw-Hill".

SELECT name
FROM member 
WHERE memb_no IN
(SELECT memb_no
FROM borrowed
WHERE isbn IN
(SELECT isbn
FROM book
WHERE publisher = 'McGraw-Hill'));

-- [Problem 3b]
-- Get the names of members who have borrowed all book
-- published by "McGraw-Hill".

SELECT name
FROM member 
WHERE memb_no IN 
(SELECT memb_no
FROM  
(SELECT DISTINCT memb_no, COUNT(MGH.isbn) as numMGH
FROM 
(SELECT borrowed.isbn, memb_no
      FROM borrowed INNER JOIN book ON book.isbn = borrowed.isbn
      WHERE (publisher = 'McGraw-Hill')) AS MGH GROUP BY memb_no) AS MGH2
      WHERE numMGH = (SELECT DISTINCT COUNT(isbn) AS hill_num
FROM book GROUP BY publisher HAVING publisher = 'McGraw-Hill'));


-- [Problem 3c]

-- For each publisher, retrieve the names of members who have
-- borrowed more than 5 books from that publisher. 

SELECT DISTINCT publisher, name, COUNT(borrowed.isbn) AS numPub
      FROM borrowed, book, member
      WHERE (member.memb_no = borrowed.memb_no) AND (borrowed.isbn = book.isbn) 
      GROUP BY borrowed.memb_no, publisher HAVING numPub > 5;

-- [Problem 3d]

-- Computes the average number books borrowed per member.

SELECT
   ((SELECT COUNT(borrowed.date) as numBorrowed 
   FROM borrowed NATURAL JOIN book) 
   / 
   (SELECT COUNT(memb_no) as numBorrowed 
   FROM member))
   as avg;
