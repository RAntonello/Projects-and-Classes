-- [Problem 5]

-- DROP TABLE commands:

-- We drop tables in reverse order to respect referential integrity.
DROP TABLE IF EXISTS buyer;
DROP TABLE IF EXISTS passenger;
DROP TABLE IF EXISTS ticket_seat;
DROP TABLE IF EXISTS flies;
DROP TABLE IF EXISTS phone_numbers;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS purchasers;
DROP TABLE IF EXISTS traveller;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS seats;
DROP TABLE IF EXISTS airplanes;
DROP TABLE IF EXISTS flights;


-- CREATE TABLE commands:

-- Table for documenting company flights and related info.
CREATE TABLE flights (
    flight_id       VARCHAR(10) PRIMARY KEY,
    flight_num      VARCHAR(10) NOT NULL,
    flight_date     DATE NOT NULL,
    flight_time     TIME NOT NULL,
	flight_source   CHAR(3) NOT NULL,
    flight_destination CHAR(3) NOT NULL,
    is_domestic  BOOLEAN NOT NULL
);

INSERT INTO flights VALUES
  ('1', '1', '1000-01-01', '00:00:00', 'AAA', 'ZZZ', 0 );
  
-- Table for documenting the company's fleet of airplanes
CREATE TABLE airplanes (
    airplane_id  VARCHAR(10) PRIMARY KEY,
    manufacturer VARCHAR(20) NOT NULL,
    model        VARCHAR(20) NOT NULL,
    type_code    CHAR(3)     NOT NULL
);

INSERT INTO airplanes VALUES
  ('1', '1', '1', '111');

-- Tabel for representing the seats on each airplane
CREATE TABLE seats (
    airplane_id VARCHAR(10) NOT NULL,
    seat_number VARCHAR(4) NOT NULL,
    class       CHAR(1) NOT NULL,
    seat_type   CHAR(1) NOT NULL,
    isExit      BOOLEAN NOT NULL,
    -- Two airplanes of the same type might have the same seat number
    -- so seat number is only a discriminant.
    PRIMARY KEY (airplane_id, seat_number),
    -- If the plane is gone, so are the seats...
    FOREIGN KEY (airplane_id) REFERENCES airplanes(airplane_id) ON DELETE CASCADE
);

INSERT into seats VALUES
    ('1', '1', '1', '1', 1),
    ('1', '2', '1', '1', 1);

-- Table for representing tickets sold by the company and their cost
CREATE TABLE tickets (
    ticket_id VARCHAR(10) PRIMARY KEY, 
    cost NUMERIC(6,2) NOT NULL
);

INSERT into tickets VALUES
    ('ticket1', 100.00),
    ('ticket2', 200.00);

-- Table for representing basic customer (traveller/purchaser) info
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL
);

INSERT into customers VALUES
    ('cust12345', 'RJ', 'Antonello'),
    ('cust54321', 'RJ2', 'Whoop De Doo');

-- Table for documneting traveller info
-- passport_num, citizen_of, contact_name, contact_number must be
-- filled out to board international flights, but are not required 
-- otherwise. 
-- Only customers who board flights are in this table.
CREATE TABLE traveller (
    customer_id   VARCHAR(10) PRIMARY KEY,
    passport_num  VARCHAR(40),
    citizen_of    VARCHAR(40),
    contact_name  VARCHAR(20),	
    contact_number VARCHAR(15),
    flyer_num CHAR(7),
    -- Should be consistent when we remove a customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

INSERT into traveller VALUES
    ('cust12345', 'pass1', 'USA', '1', '1', '1'),
    ('cust54321', 'pass2', 'USA', NULL, '2', '2');

-- Table for documneting purchaser info. 
-- Credit card info does not have to be stored.
-- Only customers who bought tickets are in this table.
CREATE TABLE purchasers (
    customer_id VARCHAR(10) PRIMARY KEY,
    credit_card_number CHAR(16),
    exp_date CHAR(4),
    verification_code CHAR(3),
    -- Should be consistent when we remove a customer.
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

INSERT into purchasers VALUES
    ('cust12345', 'credit1', '1220', '123'); 

-- Table for documenting purchases by customers in the purchasers table.
CREATE TABLE purchases (
    purchase_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    purchase_timestamp TIMESTAMP NOT NULL,
    confirmation_num CHAR(6) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES purchasers(customer_id)
);

INSERT into purchases VALUES
    ('1', 'cust12345', '1970-01-01 00:00:01', '123456');

-- Since customers can have more than one phone number, we provide a separate
-- table to store them.
CREATE TABLE phone_numbers (
    customer_id VARCHAR(10),
    phone_number VARCHAR(20),
    PRIMARY KEY (customer_id, phone_number),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT into phone_numbers VALUES
    ('cust12345', '5617895827');

-- Table that keeps track of which airplane each flight is on
CREATE TABLE flies (
    flight_id VARCHAR(10) NOT NULL UNIQUE,
    airplane_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (flight_id, airplane_id),
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id),
    FOREIGN KEY (airplane_id) REFERENCES airplanes(airplane_id)
);

INSERT into flies VALUES
    ('1', '1');

-- Table that matches tickets with their associated flight and seat number
CREATE TABLE ticket_seat (
    ticket_id VARCHAR(10) NOT NULL UNIQUE,
    flight_id VARCHAR(10) NOT NULL,
    seat_number VARCHAR(4) NOT NULL,
    PRIMARY KEY (ticket_id, flight_id, seat_number),
    -- If for some reason the company is no longer offering a ticket,
    -- it should no longer be in the database.
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
);

INSERT into ticket_seat VALUES
    ('ticket1', '1', '1'),
    ('ticket2', '1', '2');

-- Table that matches passengers with their tickets
CREATE TABLE passenger (
    ticket_id VARCHAR(10) NOT NULL UNIQUE,
    customer_id VARCHAR(40) NOT NULL,
    -- A passenger can have more than one ticket
    PRIMARY KEY (ticket_id, customer_id),
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    FOREIGN KEY (customer_id) REFERENCES traveller(customer_id)
);

INSERT into passenger VALUES
    ('ticket1', 'cust12345'),
    ('ticket2', 'cust54321');

-- Table that matches purchases with the tickets purchased.
CREATE TABLE buyer (
    ticket_id VARCHAR(10) NOT NULL,
    purchase_id VARCHAR(10) NOT NULL,
    -- A purchase can have more than one ticket.
    PRIMARY KEY (ticket_id, purchase_id),
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id)
);

INSERT into buyer VALUES
    ('ticket1', '1'),
    ('ticket2', '1');

