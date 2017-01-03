-- [Problem 3]

-- Drop tables in right order to maintain referential integrity
DROP TABLE IF EXISTS resource_fact;
DROP TABLE IF EXISTS visitor_fact;
DROP TABLE IF EXISTS resource_dim;
DROP TABLE IF EXISTS visitor_dim;
DROP TABLE IF EXISTS datetime_dim;

-- datetime dimension, holds computed values about each date
-- in the year
CREATE TABLE datetime_dim (
date_id INTEGER NOT NULL AUTO_INCREMENT,
date_val DATE NOT NULL,
hour_val INTEGER NOT NULL,
weekend BOOLEAN NOT NULL, -- if date is a weekend or not
holiday BOOLEAN, -- if date is a holiday or not
PRIMARY KEY (date_id),
UNIQUE (date_val, hour_val) -- candiate key constraint
);

-- visitor dimension, holds values computed from 
-- raw data about particular visits
CREATE TABLE visitor_dim (
visitor_id INTEGER NOT NULL AUTO_INCREMENT, 
ip_addr VARCHAR(200) NOT NULL,
visit_val INTEGER NOT NULL, -- unique identifier for visits
PRIMARY KEY (visitor_id),
UNIQUE (visit_val) 
);


-- resource dimension, stores each set of (resource, method, protocol,
-- response) in the raw data
CREATE TABLE resource_dim (
resource_id INTEGER NOT NULL AUTO_INCREMENT,
resource VARCHAR(200) NOT NULL,
method VARCHAR(15),
protocol VARCHAR(200),
response INTEGER NOT NULL,
PRIMARY KEY (resource_id),
UNIQUE (resource, method, protocol, response) -- also a candidate key
);

-- fact table for visitors and dates, stores the traffic data
-- for each visitor by day
CREATE TABLE visitor_fact (
date_id INTEGER,
visitor_id INTEGER,
num_requests INTEGER NOT NULL,
total_bytes INTEGER,
PRIMARY KEY (date_id, visitor_id),
FOREIGN KEY (date_id) REFERENCES datetime_dim(date_id),
FOREIGN KEY (visitor_id) REFERENCES visitor_dim(visitor_id)
);

-- fact table for resources and dates, stotes the traffic data
-- for each resource combination by day
CREATE TABLE resource_fact ( 
date_id INTEGER,
resource_id INTEGER, 
num_requests INTEGER NOT NULL,
total_bytes BIGINT(19),
PRIMARY KEY (date_id, resource_id),
FOREIGN KEY (date_id) REFERENCES datetime_dim(date_id),
FOREIGN KEY (resource_id) REFERENCES resource_dim(resource_id)
);
