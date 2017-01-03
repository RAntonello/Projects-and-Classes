/* clean up old tables;
   must drop tables with foreign keys first
   due to referential integrity constraints
 */
USE rantonel_db;

DROP TABLE IF EXISTS depositor;
DROP TABLE IF EXISTS borrower;
DROP TABLE IF EXISTS account;
DROP TABLE IF EXISTS branch;
DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS customer;


CREATE TABLE account (
    account_number	VARCHAR(15)	NOT NULL,
    branch_name		VARCHAR(15)	NOT NULL,
    balance		NUMERIC(12,2)	NOT NULL,
    PRIMARY KEY (account_number)
);

CREATE TABLE branch (
    branch_name		VARCHAR(15)	NOT NULL,
    branch_city		VARCHAR(15)	NOT NULL,
    assets		NUMERIC(14,2)	NOT NULL,
    PRIMARY KEY (branch_name)
);

CREATE TABLE customer (
    customer_name 	VARCHAR(15)	NOT NULL,
    customer_street 	VARCHAR(12)	NOT NULL,
    customer_city 	VARCHAR(15)	NOT NULL,
    PRIMARY KEY (customer_name)
);

CREATE TABLE loan (
    loan_number 	VARCHAR(15)	NOT NULL,
    branch_name		VARCHAR(15)	NOT NULL,
    amount 		NUMERIC(12,2)	NOT NULL,
    PRIMARY KEY (loan_number)
);

CREATE TABLE depositor (
    customer_name 	VARCHAR(15)	NOT NULL,
    account_number 	VARCHAR(15)	NOT NULL,
    PRIMARY KEY (customer_name, account_number),
    FOREIGN KEY (account_number) REFERENCES account(account_number),
    FOREIGN KEY (customer_name) REFERENCES customer(customer_name)
);

CREATE TABLE borrower (
    customer_name 	VARCHAR(15)	NOT NULL,
    loan_number 	VARCHAR(15)	NOT NULL,
    PRIMARY KEY (customer_name, loan_number),
    FOREIGN KEY (customer_name) REFERENCES customer(customer_name),
    FOREIGN KEY (loan_number) references loan(loan_number)
);

/* populate relations */

INSERT INTO customer VALUES
	('Jones',	'Main',		'Harrison'),
	('Smith',	'Main',		'Rye'),
	('Hayes',	'Main',		'Harrison'),
	('Curry',	'North',	'Rye'),
	('Lindsay',	'Park',		'Pittsfield'),
	('Turner',	'Putnam',	'Stamford'),
	('Williams',	'Nassau',	'Princeton'),
	('Adams',	'Spring',	'Pittsfield'),
	('Johnson',	'Alma',		'Palo Alto'),
	('Glenn',	'Sand Hill',	'Woodside'),
	('Brooks',	'Senator',	'Brooklyn'),
	('Green',	'Walnut',	'Stamford'),
	('Jackson',	'University',	'Salt Lake'),
	('Majeris',	'First',	'Rye'),
	('McBride',	'Safety',	'Rye'),
	('Brown',	'South',	'Rye'),
	('Davis',	'Ember',	'Stamford'),
	('Miller',	'Willow',	'Brooklyn'),
	('Wilson',	'Second',	'Orangeford'),
	('Moore',	'Green',	'Princeton'),
	('Taylor',	'Shady Cove',	'Palo Alto'),
	('Anderson',	'Coolidge',	'Springfield'),
	('Thomas',	'Smithton',	'Salt Lake'),
	('White',	'Washington',	'Rye'),
	('Harris',	'Broad',	'Rye'),
	('Martin',	'First',	'Orangeford'),
	('Thompson',	'Wilson',	'Stamford'),
	('Garcia',	'Coolidge',	'Hampton'),
	('Martinez',	'East',		'Allentown'),
	('Robinson',	'Main',		'Concord'),
	('Clark',	'Grant',	'Brooklyn'),
	('Rodriguez',	'First',	'Palo Alto'),
	('Lewis',	'Elmer',	'Lakewood'),
	('Lee',		'Bluff',	'Concord'),
	('Walker',	'Garden',	'Hampton'),
	('Hall',	'Hidden Hills',	'Allentown'),
	('Allen',	'Willow',	'Salt Lake'),
	('Young',	'Shady Cove',	'Palo Alto'),
	('Hernandez',	'Grant',	'Salt Lake'),
	('King',	'Leslie',	'Orangeford');

INSERT INTO branch VALUES
	('Downtown',	'Brooklyn',	 900000),
	('Redwood',	'Palo Alto',	2100000),
	('Perryridge',	'Horseneck',	1700000),
	('Mianus',	'Horseneck',	 400200),
	('Round Hill',	'Horseneck',	8000000),
	('Pownal',	'Bennington',	 400000),
	('North Town',	'Rye',		3700000),
	('Brighton',	'Brooklyn',	7000000),
	('Central',	'Rye',		 400280),
	('Deer Park',	'Salt Lake',	1200000),
	('Rock Ridge',	'Woodside',	 700000),
	('Markham',	'Orangeford',	 625000),
	('Belldale',	'Orangeford',	 900000),
	('Stonewell',	'Woodside',	 775000),
	('Greenfield',	'Salt Lake',	2050000),
	('Marks',	'Palo Alto',	1300000),
	('Bretton',	'Stamford',	4550000);


INSERT INTO account VALUES
	('A-233',	'Perryridge',	520),
	('A-106',	'North Town',	2500),
	('A-664',	'Redwood',	790),
	('A-151',	'Greenfield',	92000),
	('A-274',	'Pownal',	470),
	('A-730',	'Pownal',	91000),
	('A-568',	'North Town',	380),
	('A-758',	'Bretton',	59000),
	('A-506',	'Greenfield',	88000),
	('A-890',	'Central',	340),
	('A-123',	'Bretton',	410),
	('A-335',	'Belldale',	60),
	('A-739',	'Redwood',	1000),
	('A-216',	'Deer Park',	640),
	('A-313',	'Rock Ridge',	7800),
	('A-790',	'North Town',	37000),
	('A-777',	'Pownal',	380),
	('A-468',	'Stonewell',	43000),
	('A-751',	'Marks',	2800),
	('A-656',	'Brighton',	5800),
	('A-624',	'Marks',	31000),
	('A-185',	'Perryridge',	82000),
	('A-485',	'Central',	2000),
	('A-638',	'Rock Ridge',	50),
	('A-460',	'Redwood',	560),
	('A-598',	'Mianus',	300),
	('A-959',	'Mianus',	74000),
	('A-855',	'Mianus',	60),
	('A-154',	'Brighton',	1700),
	('A-866',	'Stonewell',	54000),
	('A-931',	'Downtown',	200),
	('A-340',	'Central',	300),
	('A-470',	'Marks',	870),
	('A-917',	'Redwood',	8200),
	('A-752',	'Deer Park',	5900),
	('A-795',	'Rock Ridge',	50000),
	('A-671',	'Pownal',	10),
	('A-446',	'Bretton',	27000),
	('A-559',	'Marks',	1100),
	('A-595',	'Marks',	620),
	('A-131',	'Round Hill',	34000),
	('A-666',	'Stonewell',	580),
	('A-369',	'Perryridge',	3800),
	('A-840',	'Deer Park',	19000),
	('A-240',	'Stonewell',	28000),
	('A-297',	'Rock Ridge',	9500),
	('A-375',	'Perryridge',	870),
	('A-577',	'Bretton',	91000),
	('A-276',	'Greenfield',	190),
	('A-261',	'Brighton',	3700),
	('A-149',	'Pownal',	64000),
	('A-903',	'Rock Ridge',	910),
	('A-587',	'Stonewell',	66000),
	('A-816',	'North Town',	420),
	('A-181',	'Belldale',	67000),
	('A-310',	'Brighton',	24000),
	('A-306',	'Marks',	69000),
	('A-591',	'Greenfield',	90000),
	('A-210',	'Belldale',	9000),
	('A-314',	'Redwood',	340);

INSERT INTO depositor VALUES
	('Johnson',	'A-233'),
	('Hall',	'A-106'),
	('Jackson',	'A-106'),
	('Johnson',	'A-106'),
	('Lewis',	'A-664'),
	('Thompson',	'A-664'),
	('Hernandez',	'A-664'),
	('King',	'A-664'),
	('Thompson',	'A-151'),
	('Hall',	'A-151'),
	('Wilson',	'A-151'),
	('Hayes',	'A-151'),
	('Allen',	'A-274'),
	('Martin',	'A-730'),
	('Allen',	'A-568'),
	('Miller',	'A-568'),
	('Jones',	'A-568'),
	('Wilson',	'A-758'),
	('Majeris',	'A-758'),
	('Martinez',	'A-758'),
	('Taylor',	'A-506'),
	('Moore',	'A-890'),
	('Majeris',	'A-123'),
	('McBride',	'A-335'),
	('Martinez',	'A-335'),
	('Hall',	'A-335'),
	('Robinson',	'A-335'),
	('Green',	'A-739'),
	('Clark',	'A-739'),
	('Smith',	'A-216'),
	('Moore',	'A-216'),
	('Walker',	'A-216'),
	('White',	'A-216'),
	('White',	'A-313'),
	('Anderson',	'A-313'),
	('Moore',	'A-790'),
	('Robinson',	'A-790'),
	('Davis',	'A-777'),
	('Turner',	'A-777'),
	('Turner',	'A-468'),
	('Johnson',	'A-468'),
	('Davis',	'A-751'),
	('Martinez',	'A-751'),
	('Harris',	'A-751'),
	('King',	'A-751'),
	('Hall',	'A-656'),
	('Wilson',	'A-656'),
	('Curry',	'A-656'),
	('Thomas',	'A-656'),
	('Lindsay',	'A-624'),
	('Williams',	'A-624'),
	('Turner',	'A-624'),
	('Lewis',	'A-624'),
	('Brooks',	'A-185'),
	('White',	'A-185'),
	('Brown',	'A-185'),
	('McBride',	'A-185'),
	('Thompson',	'A-485'),
	('Turner',	'A-638'),
	('Taylor',	'A-638'),
	('Thomas',	'A-460'),
	('White',	'A-460'),
	('Walker',	'A-460'),
	('Green',	'A-460'),
	('Curry',	'A-598'),
	('Hall',	'A-598'),
	('Thomas',	'A-598'),
	('Brooks',	'A-959'),
	('Hernandez',	'A-959'),
	('Walker',	'A-855'),
	('White',	'A-855'),
	('White',	'A-154'),
	('Lee',		'A-866'),
	('Brooks',	'A-866'),
	('Smith',	'A-866'),
	('Thompson',	'A-866'),
	('Allen',	'A-931'),
	('Turner',	'A-931'),
	('Williams',	'A-931'),
	('Johnson',	'A-931'),
	('Thomas',	'A-340'),
	('Green',	'A-340'),
	('King',	'A-340'),
	('Anderson',	'A-470'),
	('Davis',	'A-470'),
	('Wilson',	'A-917'),
	('Davis',	'A-917'),
	('Walker',	'A-752'),
	('Davis',	'A-752'),
	('Allen',	'A-752'),
	('Davis',	'A-795'),
	('Thomas',	'A-671'),
	('Clark',	'A-671'),
	('Lindsay',	'A-446'),
	('King',	'A-446'),
	('Brooks',	'A-446'),
	('Garcia',	'A-446'),
	('Turner',	'A-559'),
	('King',	'A-559'),
	('Miller',	'A-559'),
	('Walker',	'A-595'),
	('Curry',	'A-595'),
	('Jones',	'A-595'),
	('Curry',	'A-131'),
	('Turner',	'A-131'),
	('Williams',	'A-666'),
	('Anderson',	'A-369'),
	('Taylor',	'A-369'),
	('Green',	'A-369'),
	('Clark',	'A-369'),
	('Garcia',	'A-840'),
	('Lindsay',	'A-840'),
	('Adams',	'A-240'),
	('Robinson',	'A-240'),
	('Turner',	'A-240'),
	('Robinson',	'A-297'),
	('Moore',	'A-297'),
	('White',	'A-297'),
	('Lindsay',	'A-375'),
	('Brooks',	'A-375'),
	('Glenn',	'A-375'),
	('Curry',	'A-577'),
	('Hall',	'A-577'),
	('Jackson',	'A-577'),
	('Rodriguez',	'A-276'),
	('Jackson',	'A-261'),
	('Majeris',	'A-149'),
	('Lewis',	'A-903'),
	('Moore',	'A-903'),
	('Hayes',	'A-903'),
	('Jackson',	'A-903'),
	('Smith',	'A-587'),
	('Jones',	'A-587'),
	('Wilson',	'A-816'),
	('King',	'A-816'),
	('Curry',	'A-181'),
	('Clark',	'A-181'),
	('Hayes',	'A-181'),
	('Robinson',	'A-310'),
	('Garcia',	'A-310'),
	('Martinez',	'A-310'),
	('Johnson',	'A-310'),
	('Hernandez',	'A-306'),
	('Adams',	'A-306'),
	('Garcia',	'A-306'),
	('Thompson',	'A-306'),
	('King',	'A-591'),
	('White',	'A-210'),
	('Moore',	'A-210'),
	('Glenn',	'A-210'),
	('Davis',	'A-314'),
	('Lindsay',	'A-314'),
	('Walker',	'A-314');

INSERT INTO loan VALUES
	('L-687',	'Markham',	2600),
	('L-634',	'North Town',	16000),
	('L-168',	'Stonewell',	53000),
	('L-440',	'North Town',	8800),
	('L-379',	'Central',	9900),
	('L-722',	'Pownal',	13000),
	('L-493',	'Perryridge',	8300),
	('L-378',	'Redwood',	1800),
	('L-795',	'Stonewell',	42000),
	('L-992',	'Stonewell',	82000),
	('L-626',	'Round Hill',	780000),
	('L-263',	'Deer Park',	140000),
	('L-421',	'Downtown',	780000),
	('L-624',	'Stonewell',	1000),
	('L-803',	'Bretton',	2500),
	('L-547',	'Deer Park',	10000),
	('L-109',	'Central',	550000),
	('L-112',	'Greenfield',	400),
	('L-475',	'Mianus',	220000),
	('L-623',	'North Town',	23000),
	('L-279',	'Markham',	730000),
	('L-729',	'Pownal',	820000),
	('L-246',	'Stonewell',	73000),
	('L-654',	'North Town',	3000),
	('L-579',	'Greenfield',	3200),
	('L-737',	'Mianus',	750000),
	('L-556',	'Stonewell',	1900),
	('L-138',	'Brighton',	31000),
	('L-511',	'Marks',	40000),
	('L-285',	'Stonewell',	3100);

INSERT INTO borrower VALUES
	('Clark',	'L-687'),
	('Jones',	'L-687'),
	('Miller',	'L-634'),
	('Robinson',	'L-634'),
	('Smith',	'L-168'),
	('Brooks',	'L-440'),
	('White',	'L-379'),
	('Rodriguez',	'L-722'),
	('Brown',	'L-493'),
	('Anderson',	'L-493'),
	('Garcia',	'L-493'),
	('Allen',	'L-378'),
	('Lee',		'L-378'),
	('Allen',	'L-795'),
	('Hernandez',	'L-795'),
	('Thomas',	'L-795'),
	('Miller',	'L-992'),
	('Brooks',	'L-992'),
	('Majeris',	'L-626'),
	('Adams',	'L-626'),
	('Rodriguez',	'L-263'),
	('Allen',	'L-263'),
	('Martin',	'L-263'),
	('Harris',	'L-421'),
	('Walker',	'L-421'),
	('Jackson',	'L-421'),
	('Allen',	'L-624'),
	('King',	'L-624'),
	('Walker',	'L-624'),
	('Smith',	'L-803'),
	('Williams',	'L-803'),
	('Adams',	'L-803'),
	('Lee',		'L-547'),
	('Miller',	'L-547'),
	('Hall',	'L-109'),
	('Majeris',	'L-109'),
	('Glenn',	'L-109'),
	('Smith',	'L-112'),
	('Lee',		'L-475'),
	('Adams',	'L-475'),
	('King',	'L-623'),
	('Lindsay',	'L-623'),
	('Garcia',	'L-623'),
	('Clark',	'L-279'),
	('McBride',	'L-279'),
	('Lewis',	'L-279'),
	('Taylor',	'L-729'),
	('Hayes',	'L-729'),
	('Martin',	'L-246'),
	('Brown',	'L-654'),
	('McBride',	'L-579'),
	('Curry',	'L-737'),
	('Garcia',	'L-737'),
	('Turner',	'L-556'),
	('King',	'L-556'),
	('Lewis',	'L-556'),
	('Lewis',	'L-138'),
	('Wilson',	'L-138'),
	('Thomas',	'L-138'),
	('Green',	'L-511'),
	('Davis',	'L-285'),
	('Turner',	'L-285');

