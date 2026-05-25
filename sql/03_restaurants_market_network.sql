/*
=========================================
 Zomato Restaurant Market Network Analysis
=========================================

Business Questions:
1. Restaurant segmentation (Hidden Gems vs Revision Needed)
2. Cuisine popularity & price analysis  
3. Location competitive scoring

Author: Grigorii Gorevich
Date: 2026
*/

--QUERY1.1 "Which restaurants are 'Hidden Gems' 
CREATE VIEW restaurants_analytics AS;
SELECT
	restaurant_id,
	name,
	location,
	rating,
	votes,
	cuisines,
	approx_cost_for_two_people,
	CASE
    WHEN rating >= 4.0 AND votes < 100 THEN 'HIDDEN GEM'
    WHEN rating >= 3.5 AND rating < 4.0 AND votes >= 500 THEN 'POPULAR FAVORITE'
    WHEN rating < 3.5 AND votes >= 500 THEN 'OVERRATED'
    WHEN rating < 3.5 THEN 'NEEDS ATTENTION'
    ELSE 'REGULAR'
END AS restaurant_segments
FROM zomato_restaurant
WHERE rating IS NOT NULL
	AND votes IS NOT NULL
ORDER BY rating DESC;

--QUERY1.2 SEGMENT DISTRIBUTION
CREATE VIEW segment_distribution AS
SELECT 
   CASE
    WHEN rating >= 4.0 AND votes < 100 THEN 'HIDDEN GEM'
    WHEN rating >= 3.5 AND rating < 4.0 AND votes >= 500 THEN 'POPULAR FAVORITE'
    WHEN rating < 3.5 AND votes >= 500 THEN 'OVERRATED'
    WHEN rating < 3.5 THEN 'NEEDS ATTENTION'
    ELSE 'REGULAR'
END AS restaurant_segments,
    COUNT(*) as count,
    ROUND(AVG(rating), 2) as avg_rating,
    ROUND(AVG(votes), 0) as avg_votes
FROM zomato_restaurant
GROUP BY restaurant_segments
ORDER BY avg_rating DESC;

/*QUERY2 "Which cuisines are most popular, and how does their
average cost compare to city average?"*/
CREATE VIEW cuisines_analytics AS
WITH separated_cuisines AS(
	SELECT restaurant_id,
		name,
		listed_in_city AS city,
		rating,
		approx_cost_for_two_people,
	--convert comma separated values into array and split them into rows
		UNNEST(STRING_TO_ARRAY(cuisines, ', ')) AS individual_cuisines --
	FROM zomato_restaurant
	WHERE cuisines IS NOT NULL
		AND rating IS NOT NULL
),
	 cuisine_stats AS(
	SELECT 
		individual_cuisines,
		COUNT(*) AS restaurant_count,
		ROUND(AVG(rating), 1) AS avg_cuisine_rating,
		ROUND(AVG(approx_cost_for_two_people), 0) AS avg_cost_cuisine_USD
	FROM separated_cuisines
	GROUP BY individual_cuisines
),
	 city_stats AS(
	SELECT city,
		ROUND(AVG(approx_cost_for_two_people), 0) AS avg_cost_city_USD
	FROM separated_cuisines
	GROUP BY city
)
SELECT sep.city,
	c.individual_cuisines,
	c.restaurant_count,
	c.avg_cuisine_rating,
	c.avg_cost_cuisine_USD,
	city.avg_cost_city_USD,
	ROUND(100.0 * c.avg_cost_cuisine_USD / city.avg_cost_city_USD)
		AS cost_vs_city_avg_percent,
	RANK() OVER(ORDER BY c.restaurant_count DESC) AS popularity_rank
FROM separated_cuisines sep
LEFT JOIN cuisine_stats c ON sep.individual_cuisines = c.individual_cuisines
LEFT JOIN city_stats city ON sep.city = city.city
ORDER BY popularity_rank ASC;

/*QUERY3 Which locations have the strongest restaurant competition
and best value for customers?*/
CREATE VIEW location_analytics AS
WITH location_stats AS(
	SELECT listed_in_city AS city,
		COUNT(name) AS restaurant_count,
		ROUND(AVG(rating), 1) AS avg_rating,
		ROUND(AVG(approx_cost_for_two_people), 0) AS avg_price,
		ROUND(AVG(votes), 1) AS avg_votes,
		ROUND(1000 * AVG(rating) / AVG(approx_cost_for_two_people), 1)
			AS value_score
	FROM zomato_restaurant
	WHERE listed_in_city IS NOT NULL
	GROUP BY listed_in_city
)
SELECT city,
	restaurant_count,
	avg_rating,
	avg_price,
	avg_votes,
	value_score,
	NTILE(3) OVER(ORDER BY restaurant_count DESC) AS percentile_rank,
	CASE 
		WHEN NTILE(3) OVER(ORDER BY restaurant_count DESC) = 1 THEN 'HIGH'
		WHEN NTILE(3) OVER(ORDER BY restaurant_count DESC) = 2 THEN 'MEDIUM'
		ELSE 'LOW'
	END AS competitive_tier
FROM location_stats
WHERE restaurant_count > 10
	AND value_score IS NOT NULL
ORDER BY value_score DESC;


