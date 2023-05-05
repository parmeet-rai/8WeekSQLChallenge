SET search_path = data_mart;


-- 1. Data Cleansing Steps
/*
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format

Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

Add a month_number with the calendar month for each week_date value as the 3rd column

Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees
Add a new demographic column using the following mapping for the first letter in the segment values:
segment	demographic
C	Couples
F	Families
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
*/

SELECT * FROM CLEAN_WEEKLY_SALES

SELECT 
	week_date::DATE,
	DATE_PART('week',week_date::date) AS WEEK,
	DATE_PART('month',week_date::date) AS MONTH,
	DATE_PART('year',week_date::date) AS YEAR,
	region,
	platform,
	(CASE WHEN segment = 'null' THEN 'unknown'
		ELSE segment END) AS SEGMENT,
	(CASE WHEN segment like '%1' THEN 'Young Adults'
			WHEN segment like '%2' THEN 'Middle Aged'
			WHEN segment like '%3%' OR segment like '%4' THEN 'Retirees' 
			WHEN segment = 'null' THEN 'unknown' END) as Age_band,
	(CASE WHEN segment like 'C%' THEN 'Couples'
			WHEN segment like 'F%' THEN 'Families'
			WHEN segment = 'null' THEN 'unknown' END ) AS Demographic,
	customer_type,
	transactions,
	sales,
	ROUND(sales/transactions::numeric,2) AS avg_transactions
INTO 
	clean_weekly_sales
FROM 
	data_mart.weekly_sales		


------------------2. Data Exploration
-- 1. What day of the week is used for each week_date value?

SELECT 
	DISTINCT(TO_CHAR(week_date, 'day')) AS DAY_OF_WEEK
FROM 
	clean_weekly_sales

-- 2. What range of week numbers are missing from the dataset?

explain analyse

WITH CTE AS(
	SELECT 
		generate_series(1,52) AS WEEK)
SELECT 
	cte.WEEK 
FROM
	CTE
LEFT JOIN 
	clean_weekly_sales cws on cws.week = cte.week
WHERE 
	cws.week is null


-- 3. How many total transactions were there for each year in the dataset?

SELECT 
	YEAR, COUNT(TRANSACTIONS) TOTAL_TRANSACTIONS
FROM 
	clean_weekly_sales  
GROUP BY
	YEAR

-- 4. What is the total sales for each region for each month?

SELECT 
	REGION, to_char(WEEK_DATE,'MONTH') as _month, SUM(SALES) TOTAL_SALES
FROM 
	CLEAN_weekly_sales
GROUP BY
	REGION,_MONTH
ORDER BY
	REGION,_MONTH

-- 5. What is the total count of transactions for each platform

SELECT 
	PLATFORM, COUNT(WEEK_DATE) TOTAL_TXN
FROM 
	clean_weekly_sales
GROUP BY
	PLATFORM

-- 6. What is the percentage of sales for Retail vs Shopify for each month?

SELECT 
	to_char(WEEK_DATE,'MONTH') _MONTH,
	round((100*SUM(CASE WHEN platform = 'Shopify' THEN SALES ELSE 0 END))/sum(SALES)::numeric,2) AS "Shopify_%age" ,
	round((100*SUM(CASE WHEN platform = 'Retail' THEN SALES ELSE 0 END))/sum(SALES)::numeric,2) AS "Retail_%age"
FROM
 	clean_weekly_sales
GROUP BY _MONTH


-- 7. What is the percentage of sales by demographic for each year in the dataset?

SELECT 
	DEMOGRAPHIC,YEAR,ROUND((100*SUM(SALES))/(SELECT SUM(SALES) FROM clean_weekly_sales)::NUMERIC,2) AS REGION_WISE_SALES_PERCENTAGE
FROM 
	clean_weekly_sales
GROUP BY
	DEMOGRAPHIC,YEAR
ORDER BY
	DEMOGRAPHIC,YEAR


-- 8. Which age_band and demographic values contribute the most to Retail sales?

SELECT 
	AGE_BAND,DEMOGRAPHIC, SUM(SALES) TOTAL
FROM 
	clean_weekly_sales
WHERE 
	platform = 'Retail' 
GROUP BY
	AGE_BAND,DEMOGRAPHIC
ORDER BY
	TOTAL DESC
LIMIT 1

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?


SELECT 
	YEAR,
	PLATFORM,
	ROUND(avg(avg_transactions),2) avg_transaction_size
FROM  
	clean_weekly_sales
GROUP BY 
	YEAR,PLATFORM
ORDER BY 
	YEAR,PLATFORM

--another way is

SELECT
	year,
	PLATFORM,
	ROUND(SUM(sales)::NUMERIC/SUM(transactions),2) avg_transaction_size
FROM
	clean_weekly_sales
GROUP BY 
	1,2
ORDER BY
	1,2
-------------------------------------3. Before & After Analysis

/*
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
What about the entire 12 weeks before and after?
How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

*/

-- 4 WEEKS BEFORE AND AFTER 2020-06-15

WITH weeks4 AS(
SELECT 
	SUM(CASE WHEN week between 21 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 28 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE year = 2020)
SELECT 
	ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks4

--12  WEEKS BEFORE AND AFTER 2020-06-15

WITH weeks12 AS(
SELECT 
	SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE 
		YEAR = 2020)
SELECT 
	ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12

--  4 WEEKS BEFORE AND AFTER 2020-06-15 AND COMPARE WITH OTHER YEARS

 
WITH weeks4 AS(
SELECT 
	YEAR,SUM(CASE WHEN week between 21 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 28 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
GROUP BY
	YEAR)
SELECT 
	YEAR,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks4
ORDER BY
	YEAR

--  12 WEEKS BEFORE AND AFTER 2020-06-15 AND COMPARE WITH OTHER YEARS


WITH weeks12 AS(
SELECT 
	YEAR,SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
GROUP BY
	YEAR)
SELECT 
	YEAR,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12
ORDER BY
	YEAR

/*
4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type


Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
*/

--REGION

WITH weeks12 AS(
SELECT 
	REGION,SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE 
	YEAR = 2020
GROUP BY
	REGION)
SELECT 
	*,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12
ORDER BY 
	Rate_of_Change
LIMIT 1

-- ASIA has the maximum negative impact of -3.26 -- 

--PLATFORM

WITH weeks12 AS(
SELECT 
	PLATFORM,SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE 
	YEAR = 2020
GROUP BY
	PLATFORM)
SELECT 
	*,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12
ORDER BY
	Rate_of_Change
LIMIT 1

--Retail has maximum negative impact of -2.43 --

--AGE_BAND

WITH weeks12 AS(
SELECT 
	AGE_BAND,SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE 
	YEAR = 2020
GROUP BY
	AGE_BAND)
SELECT 
	*,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12
ORDER BY
	Rate_of_Change
LIMIT 1

-- UNKNOWN AGE_BAND has maximum negative impact of -3.34 --

--DEMOGRAPHIC


WITH weeks12 AS(
SELECT 
	DEMOGRAPHIC,SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE 
	YEAR = 2020
GROUP BY
	DEMOGRAPHIC)
SELECT
	*,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12
ORDER BY
	Rate_of_Change
LIMIT 1

-- Unknown dempgraphic has maximum negative impact of -3.34 --


--CUSTOMER_TYPE

WITH weeks12 AS(
SELECT 
	CUSTOMER_TYPE,SUM(CASE WHEN week between 13 and 24 THEN SALES ELSE 0 END) AS BEFORE_CHANGES,
	SUM(CASE WHEN week between 25 and 36 THEN SALES ELSE 0 END) AS AFTER_CHANGES
FROM 
	clean_weekly_sales
WHERE 
	YEAR = 2020
GROUP BY
	CUSTOMER_TYPE)
SELECT 
	*,ROUND(100*(AFTER_CHANGES-before_changes)/before_changes::numeric,2) as Rate_of_Change
FROM 
	weeks12
ORDER BY
	Rate_of_Change
LIMIT 1

--Guest has maximum negative impact of -3.00 --


-- Suggestions to Danny

-- I think he should review the changes that he has implemented as the sales have went down post those changes
-- So, he should revisit them and if needed then change them