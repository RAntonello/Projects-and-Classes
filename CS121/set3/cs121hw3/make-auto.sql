-- [Problem 1]

DROP TABLE IF EXISTS owns;
DROP TABLE IF EXISTS participated;
DROP TABLE IF EXISTS person;
DROP TABLE IF EXISTS car;
DROP TABLE IF EXISTS accident;


-- Contains ID, name and address of all persons in database
CREATE TABLE person (
driver_id CHAR(10) PRIMARY KEY,
name VARCHAR(20) NOT NULL,
address VARCHAR(30) NOT NULL
);

-- Contains license, model and year for all cars in database
CREATE TABLE car (
license CHAR(7) PRIMARY KEY,
model VARCHAR(20) NOT NULL,
year YEAR NOT NULL
);

-- Contains information about accidents
-- Report number auto increments as reports are added
-- Also contains date of occurance, location information, and an optional description of the accident 
CREATE TABLE accident (
report_number int AUTO_INCREMENT PRIMARY KEY,
date_occurred timestamp NOT NULL,
location VARCHAR(20) NOT NULL,
description VARCHAR(10000)
);

-- Ownership table for cars. Associates drivers by their ID with the license of the car(s) they own.
CREATE TABLE owns (
    driver_id	CHAR(10)	NOT NULL,
    license CHAR(7)	NOT NULL,
    PRIMARY KEY (driver_id, license),
    FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (license) references car(license) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Refers to the participants in accidents
-- Associated drivers and their cars with a report number in the accident table
-- Also has optional field for the monetary cost of the accident
CREATE TABLE participated (
    driver_id	CHAR(10)	NOT NULL,
    license CHAR(7)	NOT NULL,
    report_number int AUTO_INCREMENT NOT NULL,
    damage_amount NUMERIC(8,2) NOT NULL,
    PRIMARY KEY (driver_id, license, report_number),
    FOREIGN KEY(report_number) REFERENCES accident(report_number) ON UPDATE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON UPDATE CASCADE,
    FOREIGN KEY (license) REFERENCES car(license) ON UPDATE CASCADE
);