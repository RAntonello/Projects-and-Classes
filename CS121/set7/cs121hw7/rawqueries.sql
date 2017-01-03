

-- [Problem 2a]

-- Compute number of rows in raw_web_log
SELECT COUNT(ip_addr) AS total_rows FROM raw_web_log;

-- Returns 3461612

-- [Problem 2b]

-- Finds the IP addresses with the highest number of requests (top 20), sorted
-- by number of requests
SELECT ip_addr, COUNT(logtime) as total_requests
FROM raw_web_log
GROUP BY ip_addr
ORDER BY total_requests DESC
LIMIT 20;

-- [Problem 2c]

-- Finds the resources with the highest number of bytes served
-- sorted by bytes served (top 20)
SELECT resource, COUNT(*) AS total_requests, 
    SUM(bytes_sent) AS bytes_served
FROM raw_web_log
GROUP BY resource
ORDER BY bytes_served DESC
LIMIT 20;


-- [Problem 2d]
-- Finds the visits with the most requests, sorted by number of requests (top 20)
-- Also includes the ip address of the visiting user, and the start and end dates
-- of the visit
SELECT visit_val, ip_addr, COUNT(*) AS total_requests, 
    MIN(logtime) AS visit_start, MAX(logtime) AS visit_end
FROM raw_web_log
GROUP BY visit_val
ORDER BY total_requests DESC
LIMIT 20;