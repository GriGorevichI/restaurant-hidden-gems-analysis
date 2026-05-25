--CREATE TABLE SCHEMA
CREATE TABLE zomato_restaurant (
    restaurant_id SERIAL PRIMARY KEY, 
    url TEXT,  
    address TEXT, 
    name TEXT,
    online_order BOOL, 
    book_table BOOL,   
    rate VARCHAR(10),       --NOT UNIFIED VALUES
    votes INT,
    phone TEXT,         
    location TEXT,
    rest_type TEXT,
    dish_liked TEXT,
    cuisines TEXT,
    approx_cost_for_two_people VARCHAR(10), 
    reviews_list TEXT,    
    menu_item TEXT,
    listed_in_type VARCHAR(50),
    listed_in_city VARCHAR(50)
);

--LOAD ACTUAL ZOMATO DATASET
COPY zomato_restaurant(
    url, 
    address,  
    name,
    online_order,  
    book_table,    
    rate,      
    votes,
    phone,           
    location,
    rest_type,
    dish_liked,
    cuisines,
    approx_cost_for_two_people,  
    reviews_list,   
    menu_item,
    listed_in_type,
    listed_in_city)
FROM '/Users/grigorijgorevic/Desktop/SQL_PROJECTS/zomato.csv'
DELIMITER ','
CSV HEADER;