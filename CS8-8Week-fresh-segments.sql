SET SEARCH_PATH = 'fresh_segments'

SELECT * FROM fresh_segments.interest_map
SELECT * FROM fresh_segments.interest_metrics
SELECT * FROM fresh_segments.json_data


-- Data Exploration and Cleansing
-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE USING TO_DATE(month_year,'MM-YYYY');

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value 
-- 	sorted in chronological order (earliest to latest) with the null values appearing first?

SELECT
	month_year, COUNT(*)
FROM
	interest_metrics
GROUP BY
	1
ORDER BY month_year NULLS FIRST

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics

SELECT 
	* 
FROM
	fresh_segments.interest_metrics DESC 
WHERE _month is null

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

WITH cte as(
SELECT 
	id 
FROM
	interest_map
except
SELECT 
	interest_id 
FROM
	interest_metrics)
SELECT 
	count(*)
FROM 
	cte

WITH cte as(
SELECT 
	interest_id
FROM
	interest_metrics
except
SELECT 
	id 
FROM
	interest_map)
SELECT
	count(*)
FROM
	cte
--null value is there 

--5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

SELECT 
	interest_id,
	count(interest_id)
FROM 
	interest_metrics
GROUP BY
	interest_id 
ORDER BY
	interest_id

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows 
-- where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.


--there are 7 more ids in the interest_metrics table so we can apply left,right or full join so that all ids are included in the result

SELECT * FROM interest_metrics im
LEFT OUTER JOIN interest_map imp on imp.id = im.interest_id
WHERE interest_id = 21246

-- 7. Are there any records in your joined table where the month_year value 	is before the created_at value from the fresh_segments.interest_map table?
-- Do you think these values are valid and why?

SELECT * FROM interest_metrics im
LEFT OUTER JOIN interest_map imp on imp.id = im.interest_id
WHERE month_year < created_at


-- Interest Analysis
-- 1. Which interests have been present in all month_year dates in our dataset?
--doubt--
SELECT * FROM fresh_segments.interest_map
SELECT * FROM fresh_segments.interest_metrics
SELECT * FROM fresh_segments.json_data

SELECT 
	interest_id,count(interest_id)
FROM 
	interest_metrics
GROUP BY
	interest_id
HAVING 
	COUNT(month_year) = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics)
ORDER BY
	interest_id

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - 
--  which total_months value passes the 90% cumulative percentage value?

WITH CTE AS(
SELECT 
	interest_id,
	count(month_year) total_months
FROM 
	interest_metrics
GROUP BY
	interest_id
ORDER BY
	total_months desc),
CTE2 AS(
SELECT 
	total_months,ROUND(100*SUM(COUNT(interest_id)) over(order by total_months DESC)::numeric/(SELECT SUM(COUNT(interest_id)) OVER() FROM cte),2)  CUMU_PERC
FROM 
	cte
GROUP BY 
	total_months
)
SELECT 
	* 
FROM
	cte2
WHERE 
	CUMU_PERC > 90.00

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question 
 -- - how many total data points would we be removing?
DROP TABLE interest_metrics_6

WITH CTE AS(
SELECT 
	interest_id,
	count(month_year) total_months
FROM 
	interest_metrics
GROUP BY 
	interest_id
ORDER BY 
	total_months desc)
	
SELECT 
 	im.*,total_months	
INTO 
	interest_metrics_6
FROM 
	interest_metrics im
JOIN 
	cte on cte.interest_id = im.interest_id
WHERE total_months >=6

SELECT * FROM interest_metrics_6
--4.  Does this decision make sense to remove these data points from a business perspective?  
-- Use an example where there are all 14 months present to a removed interest example for your arguments 
	--  - think about what it means to have less months present from a segment perspective.
	
with cte as(
	SELECT 
		interest_id,count(interest_id)
	FROM 
		interest_metrics
	GROUP BY
		interest_id
	HAVING 
		COUNT(month_year) >=6
),
cte2 as(
SELECT 
	month_year,COUNT(*) INCLUDED
FROM
	interest_metrics_6
WHERE 
	interest_id NOT IN (SELECT interest_id FROM cte)
GROUP BY 
	month_year
),cte3 as(
SELECT 
	month_year,COUNT(*) EXCLUDED 
FROM 
	interest_metrics
WHERE 
	interest_id IN (select interest_id from cte)
GROUP BY 
	month_year)
SELECT 
	cte2.month_year,excluded,included,
	ROUND(100*included::numeric/excluded,2) EXCLUDED_PERCENTAGE from cte2
JOIN 
	cte3 ON cte2.month_year = cte3.month_year
--group by cte2.month_year
ORDER BY cte2.month_year

-- 5. After removing  these interests - how many unique interests are there for each month?

with cte as(
	SELECT 
		interest_id,count(interest_id)
	FROM 
		interest_metrics
	GROUP BY
		interest_id
	HAVING 
		COUNT(month_year) >=6
)
SELECT 
	COUNT(*) 
FROM
	interest_metrics
WHERE
	interest_id in (select interest_id from cte)

WITH cte as(
	SELECT 
		interest_id,count(interest_id)
	FROM 
		interest_metrics
	GROUP BY
		interest_id
	HAVING
		COUNT(month_year) >=6
),
cte2 as(
SELECT 
	month_year,COUNT(*) INCLUDED
FROM
	interest_metrics_6
WHERE 
	interest_id NOT IN (select interest_id from cte)
GROUP BY 
	month_year
),
cte3 as(
SELECT 
	month_year,COUNT(*) EXCLUDED 
FROM 
	interest_metrics
WHERE 
	interest_id IN (select interest_id from cte)
GROUP BY 
	month_year)
SELECT 
	cte2.month_year,(excluded - included) unq_interest_id_total
FROM 
	cte2
JOIN 
	cte3 ON cte2.month_year = cte3.month_year
ORDER BY 
	cte2.month_year

-- Segment Analysis
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, 
	-- which are the top 10 and bottom 10 interests which have the largest composition values in any month_year?
	-- Only use the maximum composition value for each interest but you must keep the corresponding month_year


WITH cte as(
SELECT 
	month_year,interest_id,composition,ROW_NUMBER() OVER (PARTITION BY interest_id ORDER BY composition DESC) rnk 
FROM 
	interest_metrics_6
GROUP BY 
	month_year,interest_id,composition
)
SELECT 
	month_year,interest_id,composition 
FROM 
	CTE 
WHERE 
	rnk = 1 
ORDER 
	BY composition DESC
LIMIT 10


WITH cte as(
SELECT 
	month_year,interest_id,composition,ROW_NUMBER() OVER (PARTITION BY interest_id ORDER BY composition DESC) rnk 
FROM 
	interest_metrics_6
GROUP BY 
	month_year,interest_id,composition
)
SELECT 
	month_year,interest_id,composition 
FROM 
	CTE 
WHERE 
	rnk = 1 
ORDER BY
	composition 
LIMIT 10


--2. Which 5 interests had the lowest average ranking value?

SELECT * FROM interest_mAP

SELECT 
	interest_id,interest_name, ROUND(AVG(ranking),2) avg_ranking
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im ON im.id = im6.interest_id
GROUP BY 
	interest_id,interest_name
ORDER BY 
	avg_ranking DESC LIMIT 5

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?

SELECT 
	interest_id,interest_name,ROUND(STDDEV(percentile_ranking)) std_dev
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im ON im.id = im6.interest_id
GROUP BY 
	interest_id,interest_name
ORDER BY 
	std_dev DESC LIMIT 5
-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value?
	-- 	Can you describe what is happening for these 5 interests?
WITH CTE AS(
SELECT 
	interest_id,interest_name,ROUND(STDDEV(percentile_ranking)) std_dev
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im ON im.id = im6.interest_id
GROUP BY 
	interest_id,interest_name
ORDER BY 
	std_dev DESC LIMIT 5
)
SELECT 
	 DISTINCT im6.interest_id,interest_name,MIN(percentile_ranking) OVER(PARTITION BY im6.interest_id) min_percentile,MAX(percentile_ranking)  OVER(PARTITION BY im6.interest_id) max_percentile 
FROM 
	interest_metrics_6 im6
JOIN cte ON cte.interest_id = im6.interest_id
GROUP BY 
	im6.interest_id,interest_name,percentile_ranking
ORDER BY 1

-- 5. How would you describe our customers in this segment based off their composition and ranking values? 
-- What sort of products or services should we show to these customers and what should we avoid?


-- Index Analysis
--  The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

-- Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
	
--1. What is the top 10 interests by the average composition for each month?
WITH CTE AS(
SELECT 
	interest_id,
	interest_name,
	month_year,
	trunc((composition/index_value)::decimal,2) AS avg_composition,
	ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY composition/index_value DESC) RN
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im
ON 
	im.id = im6.interest_id 
ORDER BY
	MONTH_YEAR,RN 
)
SELECT * FROM cte 
WHERE rn<=10
-- 2. For all of these top 10 interests - which interest appears the most often?

WITH CTE AS(
SELECT 
	interest_id,
	interest_name,
	month_year,
	trunc((composition/index_value)::decimal,2) AS avg_composition,
	RANK() OVER (PARTITION BY month_year ORDER BY composition/index_value DESC) RN
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im
ON im.id = im6.interest_id 
),
cte2 as(
SELECT 
	interest_id,
	interest_name,
	COUNT(*) appearance,
	RANK() OVER(ORDER BY COUNT(*) DESC) RNK
FROM
	cte
WHERE 
	rn<=10 
GROUP BY
	interest_id,interest_name
ORDER BY 
	appearance DESC
)
SELECT 
	interest_id,
	interest_name,
	appearance 
FROM 
	CTE2 
WHERE
	RNK = 1

-- 3. What is the average of the average composition for the top 10 interests for each month?
WITH CTE AS(
SELECT 
	interest_id,
	interest_name,
	month_year,
	trunc((composition/index_value)::decimal,2) AS avg_composition,
	RANK() OVER (PARTITION BY month_year ORDER BY composition/index_value DESC) RN
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im
ON im.id = im6.interest_id 
)
SELECT 
	month_year,ROUND(AVG(avg_composition),2)	
FROM
	cte
WHERE rn<=10 
GROUP BY 1


-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and 
	-- include the previous top ranking interests in the same output shown below.
WITH CTE AS(
SELECT 
	interest_id,
	interest_name,
	month_year,
	trunc((composition/index_value)::decimal,2) AS avg_composition,
	ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY composition/index_value DESC) RN
FROM 
	interest_metrics_6 im6
JOIN 
	interest_map im
ON im.id = im6.interest_id 
),
cte2 as(
SELECT
	month_year,
	interest_id,
	interest_name,
	avg_composition,
	ROUND(AVG(avg_composition) OVER (ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) comp_3_month_moving_avg,
	LAG(interest_name) OVER (ORDER BY month_year) AS interest_1_month_ago,
    LAG(avg_composition) OVER (ORDER BY month_year) AS comp_1_month_ago,
	LAG(interest_name, 2) OVER (ORDER BY month_year) AS interest_2_month_ago,
	LAG(avg_composition) OVER (ORDER BY month_year) AS comp_2_month_ago
FROM 
	cte
WHERE 
	 rn = 1)
SELECT
    month_year,
    interest_name,
    avg_composition AS max_index_compos   ition,
    comp_3_month_moving_avg AS "3_month_moving_avg",
    interest_1_month_ago || ': ' || comp_1_month_ago AS "1_month_ago",
    interest_2_month_ago || ': ' || comp_2_month_ago AS "2_months_ago"
FROM
    cte2
WHERE
    month_year BETWEEN '2018-09-01' and '2019-08-01'



-- 5. Provide a possible reason why the max average composition might change from month to month? 
	-- Could it signal something is not quite right with the overall business model for Fresh Segments?
/*	
ANS
One possible reason based on the previous question is seasonal change. Based on the result, customer interaction on content related to travel/holiday is relatively higher than the other, 
especially during the holiday season or the end of the year. Because of this, the interaction on contents that are other than travel/holiday would be lower outside the holiday season.

*/