-- [Problem 6a]

-- Query that returns purchase history for customer with ID 12345.

-- We would like to omit purchaser info, which is why we explicitly
-- write out the fields that we want. 
SELECT DISTINCT purchases.purchase_id, passenger.ticket_id, 
    purchase_timestamp, flight_date, first_name,
    last_name, flight_num, flight_date, flight_time, flight_source,
    flight_destination, is_domestic
FROM (purchasers NATURAL JOIN purchases NATURAL JOIN ticket_seat)
    INNER JOIN buyer ON purchases.purchase_id = buyer.purchase_id
    INNER JOIN passenger ON buyer.ticket_id = passenger.ticket_id
    INNER JOIN customers ON passenger.customer_id = customers.customer_id
    NATURAL JOIN flights
WHERE purchasers.customer_id = 'cust12345'
ORDER BY purchase_timestamp DESC, flight_date, last_name, first_name;

-- [Problem 6b]

-- Query that returns the total revenue of each type of airplane.
SELECT type_code, SUM(cost) as total_type_revenue
FROM tickets NATURAL JOIN ticket_seat 
    NATURAL JOIN flights NATURAL JOIN airplanes
GROUP BY type_code;

-- [Problem 6c]

-- This query finds all the travellers booked for an international flight
-- that have not yet filled out all the required data to take that flight.

-- Specifically, a traveller must have added a passport number, country 
-- of citizenship, and an emergency contact name and number.

SELECT customer_id 
FROM traveller
WHERE passport_num IS NULL OR citizen_of IS NULL OR
    contact_name IS NULL OR contact_number IS NULL AND
    customer_id IN 
        (SELECT customer_id
        FROM flights
        WHERE NOT is_domestic);

