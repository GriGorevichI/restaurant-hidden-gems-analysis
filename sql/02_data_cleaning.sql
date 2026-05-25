--HANDLING INT DATA WITH COMMA SEPARATED THOUSANDS
UPDATE zomato_restaurant
SET approx_cost_for_two_people = REPLACE(approx_cost_for_two_people, ',', '');

ALTER TABLE zomato_restaurant
ALTER COLUMN approx_cost_for_two_people TYPE INT 
USING approx_cost_for_two_people::INT;

--NEW RATING COLUMN WITH UNICODE INTEGER VALUES
ALTER TABLE zomato_restaurant 
ADD COLUMN rating DECIMAL(3,1);

UPDATE zomato_restaurant 
SET rating = SPLIT_PART(rate, '/', 1)::DECIMAL(3,1)
WHERE rate ~ '^\d+\.?\d*/5$';