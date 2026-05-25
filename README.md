![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811)
![VS Code](https://img.shields.io/badge/VS%20Code-Editor-007ACC)

![zomato dash](/image/Zomato_dash.png)

# Introduction 
**The Problem:** Restaurant aggregators like Zomato show popularity, but popularity doesn't always mean quality. A restaurant with 2,000 votes and 3.2 stars might disappoint, while a hidden gem with 50 votes and 4.5 stars goes undiscovered.
For this purpose this project uses PostgreSQL to analyze Zomato restaurant data and PowerBI for interactive performance, answering three business questions:
- Which restaurants are hidden gems vs. need revision?
- What cuisines drive the most engagement?
- Which locations offer the best value for diners?

### 🔗 Dashboard Access

🔗 **[View Dashboard on Power BI Service](https://app.powerbi.com/links/01bmvYIHgT?ctid=d5cbab6e-6db4-407a-b5fe-10287f99ad43&pbi_source=linkShare)

> *Power BI Pro license required.* 

Check out SQL queries here: [restaurant-hidden-gems-analysis folder](/sql/)
# Tools I used
For my deep dive into the data restaurants market, I harnessed the power of several key tools:

- **PostgreSQL** - Data cleaning, transformation, and analysis
- **Power BI** - Interactive dashboard and visualization
- **VS Code** - SQL development and version control
- **Git & GitHub** - Version control and project hosting
# The analysis
Three queries examine restaurant segmentation, cuisine popularity with city price comparisons, and location-based value scoring. Each aims to identify hidden gems, overrated spots, and areas offering the best value for customers.

### 1. Which restaurants are Hidden Gems
Categorized 21,000+ restaurants into five segments based on rating and vote count:
- **Hidden Gems** (4.0+⭐, <100 votes) - High quality, undiscovered
- **Popular Favorites** (4.0+⭐, 500+ votes) - Trusted by many
- **Overrated** (<3.5⭐, 500+ votes) - Popular but disappointing
- **Needs Attention** (<3.5⭐, <500 votes) - Improvement required
- **Mid Range** - All others

```sql
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
```

| Segment | Count | Avg Rating | Avg Votes | Business Implication |
|---------|-------|------------|-----------|---------------------|
| Popular Favorite | 2,630 | 4.25 | 1,683 | Loyalty program candidates |
| Hidden Gem | 732 | 4.07 | 63 | Promotion opportunities |
| Mid Range | 11,871 | 3.81 | 156 | Baseline market |
| Needs Attention | 5,995 | 3.14 | 52 | Operational review needed |
| Overrated | 60 | 3.07 | 770 | Investigate rating disparity |

### 2. Which cuisines are most popular, and how does their average cost compare to city average?
Each cuisine ranked by restaurant count and compared average cuisine cost to city benchmarks. North Indian emerged as most popular (4,892 restaurants), while Japanese and Continental showed highest premium pricing (+35-42% above city average).

```sql
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
```

| Cuisine | Restaurants | Avg Rating | Avg Cost | vs City Avg |
|---------|-------------|------------|----------|-------------|
| North Indian | 4,892 | 4.2 | $850 | +6% |
| Chinese | 3,456 | 4.0 | $780 | -3% |
| Fast Food | 2,891 | 3.8 | $450 | -44% |
| South Indian | 2,234 | 4.1 | $620 | -22% |
| Continental | 1,567 | 4.3 | $1,150 | +35% |
| Japanese | 892 | 4.4 | $1,280 | +42% |

### 3. Which locations have the strongest restaurant competitionand best value for customers?
Aggregated restaurant metrics by city, created a value score (rating divided by cost × 1000) to identify best-value areas, and applied NTILE(3) window function to segment locations into High, Medium, and Low competitive tiers based on restaurant count. Locations with fewer than 10 restaurants were excluded for statistical significance.

```sql
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
```

| Location | Restaurants | Value Score | Competitive Tier | Insight |
|----------|-------------|-------------|------------------|---------|
| Banashankari | 78 | 6.0 | Medium | Best value |
| Koramangala | 312 | 5.1 | High | Most competitive |
| Indiranagar | 245 | 4.8 | High | Premium pricing |
| Whitefield | 142 | 4.2 | High | Lowest value |

Banashankari delivers the best value (6.0 score) with medium competition (78 restaurants), while high-density locations like Koramangala (312 restaurants) show lower value scores due to premium pricing. Only 15 cities met the minimum 10-restaurant threshold for analysis.

# Challenges 
| Challenge | Solution |
|-----------|----------|
| Rating as text ('4.1/5') | SPLIT_PART() + regex validation |
| Comma-separated cuisines in one column | STRING_TO_ARRAY() + UNNEST() |
| Thousand separators in cost | REPLACE(',' , '') + integer cast |
| Invalid values ('NEW', '-') | WHERE rate ~ '^\d+\.?\d*/5$' |

# Conclusions
1. **Key takeaways:**
- Hidden Gems (732) represent untapped promotion opportunities
- Overrated segment (60) reveals marketing-quality disconnect
- Banashankari offers best value (6.0 score) for diners
- North Indian, Chinese, and Fast Food dominate market

**Next steps:** Promote Hidden Gems, audit Overrated restaurants, expand value analysis to user review sentiment.

2. **Closing thoughts:**
Thanks for exploring this project. The code and methodology are documented to help other analysts navigate similar data challenges. Questions or suggestions? Open an issue or reach out.