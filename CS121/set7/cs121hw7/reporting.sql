-- [Problem 6a]


-- Returns the top 10 protocols by request number
SELECT protocol, SUM(num_requests) AS total_requests
FROM resource_dim NATURAL JOIN resource_fact
GROUP BY protocol
ORDER BY total_requests DESC 
LIMIT 10;

SELECT * FROM resource_dim NATURAL JOIN resource_fact where response >= 400;

-- [Problem 6b]

-- returns the top 20 error responses by request number
SELECT resource, response, SUM(num_requests) AS total_requests
FROM resource_dim NATURAL JOIN resource_fact
WHERE response >= 400 
GROUP BY resource, response
ORDER BY total_requests DESC 
LIMIT 20;

-- [Problem 6c]

-- Returns the top clients by number of bytes sent (also gives numbe of
-- requests by that client, and number of visits)
SELECT ip_addr, COUNT(DISTINCT visit_val) AS total_visits, 
    SUM(num_requests) AS num_requests, SUM(total_bytes) AS total_client_bytes
FROM visitor_fact NATURAL JOIN visitor_dim
GROUP BY ip_addr
ORDER BY total_client_bytes DESC
LIMIT 20;


-- [Problem 6d]

-- The website notes that there was no traffic from  01/Aug/1995:14:52:01 to 03/Aug/1995:04:36:13
-- due to Hurricane Erin. So that's why there are no requests on August 2nd.

-- The gap from July 29th to July 31st has no explanation.

-- Computes the number of requests per day from July 23rd to August 12th
SELECT date_val, SUM(num_requests) AS total_requests_this_day	, 
    SUM(total_bytes) AS bytes_served_this_day
FROM datetime_dim LEFT OUTER JOIN visitor_fact 
    ON datetime_dim.date_id = visitor_fact.date_id
WHERE date_val BETWEEN '1995-07-23' AND '1995-08-12'
GROUP BY date_val
ORDER BY date_val;


-- [Problem 6e]

-- Computes the reource that sent the most bytes for each day, and returns
-- it along with the day, number of requests it received, and number of bytes
-- it sent.
SELECT date_val, resource, total_requests_for_resource, total_bytes_for_resource
FROM (SELECT date_val, resource, SUM(num_requests) AS total_requests_for_resource,
    SUM(total_bytes) AS total_bytes_for_resource
     FROM resource_dim NATURAL JOIN resource_fact NATURAL JOIN datetime_dim
     GROUP BY date_val, resource) AS resource_use_by_day
WHERE (date_val, total_bytes_for_resource) IN 
    (SELECT date_val, MAX(total_bytes_for_resource) AS max_bytes
    FROM (SELECT date_val, resource, SUM(num_requests) AS total_requests_for_resource,
             SUM(total_bytes) AS total_bytes_for_resource
          FROM resource_dim NATURAL JOIN resource_fact NATURAL JOIN datetime_dim
          GROUP BY date_val, resource) AS temp
          GROUP BY date_val)
ORDER BY date_val;


-- [Problem 6f]

-- We can see from these results that the average weekend visits are smaller
-- that the average weekend visits almost across the board.
-- This is probably because most people didn't have at-home Internet
-- so the most common place to surf the web was at work!

-- Computes the average number of visits in a given hour, for
-- weekdays and weekends
SELECT weekends.hour_val, avg_weekday_visits, avg_weekend_visits
FROM
    -- Count the weekend visits (note 24 hours in a day)
	(SELECT hour_val, COUNT(visit_val) / ((SELECT COUNT(DISTINCT date_id) 
		FROM datetime_dim NATURAL JOIN visitor_fact 
						  NATURAL JOIN visitor_dim 
		WHERE weekend) / 24) AS avg_weekend_visits
	FROM datetime_dim NATURAL JOIN visitor_fact 
					  NATURAL JOIN visitor_dim
	WHERE weekend
	GROUP BY hour_val) AS weekends
INNER JOIN
    -- Count the weekday visits
	(SELECT hour_val, COUNT(visit_val) / ((SELECT COUNT(DISTINCT date_id) 
		FROM datetime_dim NATURAL JOIN visitor_fact 
						  NATURAL JOIN visitor_dim 
		WHERE NOT weekend) / 24) AS avg_weekday_visits
	FROM datetime_dim NATURAL JOIN visitor_fact 
					  NATURAL JOIN visitor_dim
	WHERE NOT weekend
	GROUP BY hour_val) AS weekdays
ON weekends.hour_val = weekdays.hour_val
;



