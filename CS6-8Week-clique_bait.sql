SET SEARCH_PATH = clique_bait

SELECT * FROM clique_bait.campaign_identifier
SELECT * FROM clique_bait.event_identifier
SELECT * FROM clique_bait.events
SELECT * FROM clique_bait.page_hierarchy
SELECT * FROM clique_bait.users

----2. Digital Analysis
-- Using the available datasets - answer the following questions using a single query for each one:

-- 1. How many users are there?
SELECT 
	 COUNT( DISTINCT user_id) 
FROM 
	users

-- 2. How many cookies does each user have on average?

SELECT 
	COUNT(cookie_id)/count(distinct user_id) avg_cookies_per_user
FROM
	users

-- 3. What is the unique number of visits by all users per month?

SELECT 
	TO_CHAR(EVENT_TIME,'MONTH') _month,
	COUNT(DISTINCT visit_id) UNQ_VISITS
FROM 
	events
GROUP BY _month

-- 4. What is the number of events for each event type?

SELECT
	ei.event_type,
	event_name,
	COUNT(visit_id) NO_OF_EVENTS
FROM
	events e
JOIN
	event_identifier ei on ei.event_type = e.event_type
GROUP BY ei.event_type,	event_name
ORDER BY ei.event_type

-- 5. What is the percentage of visits which have a purchase event?

SELECT
	ROUND((100*COUNT(visit_id))/(SELECT COUNT(DISTINCT visit_id) FROM events)::numeric,2) "Purchase_event_%age"
FROM 
	events
WHERE 
	event_type = 3
	
-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH cte as(
SELECT 
	COUNT( VISIT_ID) total 
FROM 
	EVENTS
WHERE 
	PAGE_ID = 12
),
cte2 as(
SELECT 
	COUNT( VISIT_ID) purchase 
FROM 
	EVENTS
WHERE 
	page_id = 12 AND VISIT_ID not IN (SELECT VISIT_ID FROM EVENTS WHERE event_type = 3)
)
SELECT 
	round(100*purchase/total::numeric,2) as "Purchase_event_%age"
FROM 
	cte,cte2


-- 7. What are the top 3 pages by number of views?

SELECT
	e.page_id,
	ph.page_name,
	SUM(CASE WHEN EVENT_TYPE = 1 THEN 1 ELSE 0 END) AS TOTAL_VIEWS
FROM 
	events e
JOIN
	page_hierarchy ph ON ph.page_id = e.page_id
GROUP BY 
	e.page_id,	ph.page_name
ORDER BY 
	TOTAL_VIEWS DESC
LIMIT 3

-- 8. What is the number of views and cart adds for each product category?


SELECT 
	product_category,
	SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) no_of_views,
	SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) cart_adds
FROM
	events e
JOIN 
	page_hierarchy ph
ON 
	ph.page_id = e.page_id
GROUP BY product_category

-- 9. What are the top 3 products by purchases?

SELECT * FROM clique_bait.page_hierarchy
SELECT * FROM clique_bait.events
SELECT * FROM clique_bait.campaign_identifier
SELECT * FROM clique_bait.event_identifier
SELECT * FROM clique_bait.users

--ONLY PAGE_ID 13 IS THERE

SELECT
	PAGE_NAME,
	EVENT_TYPE,
	(VISIT_ID)
FROM
	events e
JOIN
	page_hierarchy ph 
ON
	ph.page_id = e.page_id
WHERE 
	e.event_type = 3 
GROUP BY 1
ORDER BY
	2 DESC
	
SELECT * FROM EVENTS
WHERE event_type = 3 

LIMIT 3


----3. Product Funnel Analysis
/*
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

Use your 2 new output tables - answer the following questions:

Which product had the most views, cart adds and purchases?
Which product was most likely to be abandoned?
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase?

*/


with cte as(
SELECT 
	visit_id,
	e.cookie_id,
	e.page_id,
	event_type,
	sequence_number,
	event_time,
	page_name,
	product_category,
	product_id,
	first_value(event_type) over (partition by visit_id order by sequence_number desc) c 
FROM
	events e
JOIN 
	page_hierarchy ph
ON ph.page_id = e.page_id)
SELECT * FROM cte

SELECT product_id,
		page_name,
		SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) VIEWS,
		SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) Added_to_Cart,
		SUM(CASE WHEN event_type = 2 AND c != 3  THEN 1 ELSE 0 END) Abandoned,
		SUM(CASE WHEN event_type = 2 AND c = 3  THEN 1 ELSE 0 END)	Purchased
INTO 
	prod_analysis
FROM
	cte
WHERE 
	product_id is not null
GROUP BY
	product_id,page_name
ORDER BY
	product_id

select * from prod_analysis

with cte as(
select 
	visit_id,
	e.cookie_id,
	e.page_id,
	event_type,
	sequence_number,
	event_time,
	page_name,
	product_category,
	product_id,
	first_value(event_type) over (partition by visit_id order by sequence_number desc) c 
FROM
	events e
JOIN 
	page_hierarchy ph
ON 
	ph.page_id = e.page_id)

SELECT 
	product_category,
	SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) VIEWS,
	SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) Added_to_Cart,
	SUM(CASE WHEN event_type = 2 AND c != 3  THEN 1 ELSE 0 END) Abandoned,
	SUM(CASE WHEN event_type = 2 AND c = 3  THEN 1 ELSE 0 END)	Purchased
INTO 
	prod_cat_analysis
FROM
	cte
WHERE
	product_id is not null
GROUP BY
	 product_category

-- Which product had the most views, cart adds and purchases?

-- VIEWS
SELECT 
	product_id,
	page_name,
	views
FROM
	prod_analysis
ORDER BY 
	VIEWS DESC
LIMIT 1

-- CART ADDS

SELECT 
	product_id,
	page_name,
	Added_to_Cart
FROM
	prod_analysis
ORDER BY 
	Added_to_Cart DESC
LIMIT 1

-- PURCHASED

SELECT 
	product_id,
	page_name,
	Purchased
FROM
	prod_analysis
ORDER BY 
	Purchased DESC
LIMIT 1

-- Which product was most likely to be abandoned?

SELECT 
	product_id,
	page_name,
	Abandoned
FROM
	prod_analysis
ORDER BY 
	Abandoned DESC
LIMIT 1

--Russian Caviar

-- Which product had the highest view to purchase percentage?

SELECT 
	*,
	round(purchased/views::numeric,2) view_to_purchase
FROM
	prod_analysis
ORDER BY 
	view_to_purchase DESC
LIMIT 1

-- What is the average conversion rate from view to cart add?
EXPLAIN ANALYSE

SELECT 
	ROUND(AVG(added_to_cart/views::numeric),2) view_to_cart
FROM
	prod_analysis
	

-- What is the average conversion rate from cart add to purchase?

SELECT 
	ROUND(AVG(purchased/added_to_cart::numeric),2) cart_to_purchase
FROM
	prod_analysis

/*
3. Campaigns Analysis
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
*/
	
SELECT 
	user_id,
	visit_id,
	MIN(event_time) as visit_start_time,
	SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END)  page_views,
	SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) cart_adds,
 	SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) as Purchased,
	campaign_name,
	--(CASE WHEN (product_id between 1 and 3) and (event_time between start_date and end_date) and campain_id = 1 THEN campaign_name ELSE NULL END)
	SUM(CASE WHEN event_type = 4 THEN 1 ELSE 0 END) as Ad_Impressions,
	SUM(CASE WHEN event_type = 5 THEN 1 ELSE 0 END) as Ad_Click,
	(SELECT STRING_AGG(PAGE_ID::varchar,',') FROM events e2 WHERE event_type = 2 and e2.visit_id = e.visit_id) cart_products
INTO 
	campaign_analysis
FROM 
	events e
JOIN 
	users u on u.cookie_id = e.cookie_id
JOIN 
	page_hierarchy ph ON ph.page_id = e.page_id 
JOIN 
	campaign_identifier ci ON event_time BETWEEN ci.start_date and ci.end_date
GROUP BY
	user_id,visit_id,campaign_name



-- Some ideas you might want to investigate further include:

-- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event

SELECT SUM(
	CASE WHEN ad_impressions > 0 and page_views > 0 THEN 1 ELSE 0
		 END) views_with_ad,
		SUM(
	CASE WHEN ad_impressions > 0 and cart_Adds > 0 THEN 1 ELSE 0
		 END) addcart_with_ad,
		 SUM(
	CASE WHEN ad_impressions > 0 and purchased > 0 THEN 1 ELSE 0
		 END) purchase_with_ad,
	 	SUM(
	CASE WHEN ad_impressions > 0 and ad_click > 0 THEN 1 ELSE 0
		 END) adclick_with_ad,		
		 sum(
	CASE WHEN ad_impressions = 0 and page_views > 0 THEN 1 ELSE 0
		 END) views,
		sum(
	CASE WHEN ad_impressions = 0 and cart_Adds > 0 THEN 1 ELSE 0
		 END) addcart,
		 SUM(
	CASE WHEN ad_impressions = 0 and purchased > 0 THEN 1 ELSE 0
		 END) purchase,
		 SUM(
	CASE WHEN ad_impressions = 0 and ad_click > 0 THEN 1 ELSE 0
		 END) adclick
from 
	campaign_analysis
	
-- Does clicking on an impression lead to higher purchase rates?

SELECT
	ROUND(SUM(CASE WHEN purchased=1 AND ad_click=1 THEN 1 ELSE 0 END)::NUMERIC/SUM(CASE WHEN ad_click=1 THEN 1 ELSE 0 END)*100,2) AS with_click,
	ROUND(SUM(CASE WHEN purchased=0 AND ad_click=1 THEN 1 ELSE 0 END)::NUMERIC/SUM(CASE WHEN ad_click=1 THEN 1 ELSE 0 END)*100,2) AS without_click
FROM
	campaign_analysis;


-- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? 
-- What if we compare them with users who just an impression but do not click?

SELECT
	ROUND(SUM(CASE WHEN purchased=1 AND ad_click=1 AND ad_impressions=1 THEN 1 ELSE 0 END)::NUMERIC/COUNT(purchased)*100,2) purchased_with_click_impressions   ,
	ROUND(SUM(CASE WHEN ad_impressions=1 AND ad_click=0 AND purchased=1 THEN 1 ELSE 0 END)::NUMERIC/COUNT(purchased)*100,2)  purchased_impressions_withoutclick,
	ROUND(SUM(CASE WHEN purchased=1 AND ad_impressions=0 THEN 1 ELSE 0 END)::NUMERIC/COUNT(purchased)*100,2) purchased_without_ad
FROM
	campaign_analysis;

What metrics can you use to quantify the success or failure of each campaign compared to eachother?

- number of purchases after ad_clicks

