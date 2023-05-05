SET SEARCH_PATH = balanced_tree

-- High Level Sales Analysis
-- 1. What was the total quantity sold for all products?
-- 2. What is the total generated revenue for all products before discounts?
-- 3. What was the total discount amount for all products?

--all questions attempted in 1 query as it is stated in the case study
SELECT prod_id,
	product_name,
	SUM(qty)::INT TOTAL_QTY,
	SUM(QTY*S.price)::INT TOTAL_revenue,
	ROUND(SUM((qty*discount/100::numeric)*S.price),2) TOTAL_DISCOUNT
FROM
	sales S
JOIN 
	product_details P
ON
	p.product_id = s.prod_id
GROUP BY 
	prod_id,
	product_name

-----------------Transaction Analysis
-- How many unique transactions were there?
-- What is the average unique products purchased in each transaction?
-- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
-- What is the average discount value per transaction?
-- What is the percentage split of all transactions for members vs non-members?
-- What is the average revenue for member transactions and non-member transactions?

SELECT 
	COUNT(DISTINCT txn_id) unique_transactions,
	COUNT(prod_id)/COUNT(DISTINCT TXN_ID) avg_unq_prod_per_txn,
	ROUND(SUM((qty*discount/100::numeric)*price)/COUNT(DISTINCT txn_id),2) AVG_DISCOUNT_PER_TXN,
	PERCENTILE_DISC(0.25) WITHIN GROUP(order by qty*price) "25th_revenue_percentile",
	PERCENTILE_DISC(0.5) WITHIN GROUP(order by qty*price) "50th_revenue_percentile",
	PERCENTILE_DISC(0.75) WITHIN GROUP(order by qty*price) "75th_revenue_percentile",
	ROUND(SUM(CASE WHEN member = true THEN 1 ELSE 0 END)::numeric/COUNT(txn_id),2)*100 member_txn_split,
	ROUND(SUM(CASE WHEN member = false THEN 1 ELSE 0 END)::numeric/COUNT(txn_id),2)*100 non_member_txn_split,
	ROUND(SUM(CASE WHEN member = true THEN qty*price ELSE 0 END)::numeric/SUM(CASE WHEN member = true THEN 1 ELSE 0 END)) avg_revenue_member,
	ROUND(SUM(CASE WHEN member = false THEN qty*price ELSE 0 END)::numeric/SUM(CASE WHEN member = false THEN 1 ELSE 0 END)) avg_revenue_non_member
FROM
	sales
	
------------Product Analysis


-- What are the top 3 products by total revenue before discount?

SELECT 
	prod_id,
	product_name,
	SUM(qty*S.price) as total_revenue
FROM
	sales s
JOIN 
	product_details pd 
ON pd.product_id = s.prod_id
GROUP BY 
	prod_id,product_name
ORDER BY total_revenue desc
LIMIT 3 

-- What is the total quantity, revenue and discount for each segment?

SELECT * FROM balanced_tree.product_details
SELECT * FROM balanced_tree.product_hierarchy-
SELECT * FROM balanced_tree.product_prices-
SELECT * FROM balanced_tree.sales

SELECT 
	segment_id,
	segment_name,
	SUM(qty) total_qty,
	SUM(qty*S.price) as total_revenue,
	ROUND(SUM((qty*discount/100::numeric)*s.price),2) AS total_discount
FROM
	sales s
JOIN 
	product_details pd 
ON 
	pd.product_id = s.prod_id
GROUP BY 
	segment_id,segment_name
ORDER BY
	segment_id
-- What is the top selling product for each segment?

WITH CTE AS(
SELECT
	product_id,
	product_name,
	segment_id,
	segment_name,
	ROW_NUMBER() over (PARTITION BY segment_id ORDER BY SUM(qty) DESC) rn,
	SUM(qty) as total_qty
FROM
	sales s
JOIN 
	product_details pd 
ON 
	pd.product_id = s.prod_id
GROUP BY 
	product_id,
	product_name,
	segment_id,
	segment_name
)
SELECT
	segment_id,
	segment_name,
	product_id,
	product_name,	
	total_qty
FROM 
	CTE
WHERE RN = 1
	
-- What is the total quantity, revenue and discount for each category?
SELECT 
	category_id,
	category_name,
	SUM(qty) total_qty,
	SUM(qty*S.price) as total_revenue,
	ROUND(SUM((qty*discount/100::numeric)*s.price),2) AS total_discount
FROM
	sales s
JOIN 
	product_details pd 
ON 
	pd.product_id = s.prod_id
GROUP BY 
	category_id,category_name
ORDER BY
	category_id

-- What is the top selling product for each category?

WITH CTE AS(
SELECT
	product_id,
	product_name,
	category_id,
	category_name,
	ROW_NUMBER() over (PARTITION BY category_id ORDER BY SUM(qty) DESC) rn,
	SUM(qty) as total_qty
FROM
	sales s
JOIN 
	product_details pd 
ON 
	pd.product_id = s.prod_id
GROUP BY 
	product_id,
	product_name,
	category_id,
	category_name
)
SELECT
	category_id,
	category_name,
	product_id,
	product_name,	
	total_qty
FROM CTE
WHERE RN = 1
-- What is the percentage split of revenue by product for each segment?

SELECT 
	prod_id,
	product_name,
	segment_id,
	segment_name,
	100*SUM(s.qty*s.price)::numeric/(SELECT SUM(s.qty*s.price) FROM sales s JOIN product_details pd2 ON pd2.product_id = s.prod_id WHERE pd2.segment_id = pd1.segment_id GROUP BY segment_id) as total_revenue_split
FROM
	sales s
JOIN 
	product_details pd1 
ON 
	pd1.product_id = s.prod_id
GROUP BY prod_id,product_name,segment_id,segment_name
ORDER BY segment_id,total_revenue_split DESC


-- What is the percentage split of revenue by segment for each category?

SELECT 
	segment_id,
	segment_name,
	category_id,
	category_name,
	100*SUM(s.qty*s.price)::numeric/(SELECT SUM(s.qty*s.price) FROM sales s JOIN product_details pd2 ON pd2.product_id = s.prod_id WHERE pd2.category_id = pd1.category_id GROUP BY category_id) as total_revenue_split
FROM
	sales s
JOIN 
	product_details pd1 
ON 
	pd1.product_id = s.prod_id
GROUP BY 
	segment_id,segment_name,category_id,category_name
ORDER BY
	category_id,total_revenue_split DESC

-- What is the percentage split of total revenue by category?

SELECT
	category_id,
	category_name,
	ROUND(100*SUM(qty*S.price)::numeric/(SELECT SUM(qty*price) FROM sales),2) as total_revenue
FROM 
	sales s
JOIN 
	product_details pd
ON 
	pd.product_id = s.prod_id
GROUP BY 
	category_id,category_name

-- What is the total transaction “penetration” for each product? 
--(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

SELECT 
	prod_id,
	product_name,
	ROUND(COUNT(txn_id)::numeric/(SELECT count(txn_id) FROM sales),4) penetration
FROM
	sales s
JOIN 
	product_details pd
ON 
	pd.product_id = s.prod_id
GROUP BY 
	prod_id,
	product_name


-- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH cte AS (
    SELECT
        s1.prod_id AS prod1,
        s2.prod_id AS prod2,
		s3.prod_id AS prod3,
		count(*) times,
        RANK() OVER (ORDER BY COUNT(*) DESC) rnk
    FROM sales s1
    INNER JOIN sales s2
        ON s1.prod_id < s2.prod_id AND s1.txn_id = s2.txn_id
	INNER JOIN sales s3
		ON s2.prod_id < s3.prod_id AND s2.txn_id = s3.txn_id
	
    GROUP BY
        prod1,prod2,prod3
	ORDER BY 
		rnk 
	LIMIT 1
),
--SELECT ARRAY[prod1,prod2,prod3] from cte
cte2 as(
	SELECT array_agg(array[prod1,prod2,prod3]) as products, times from CTE

GROUP BY times
),
cte3  as (
SELECT 
	unnest(products) as products,times
FROM cte2
)
SELECT
	string_agg(product_name,', ') PRODUCTS, times::smallint 
FROM
	cte3
JOIN
	product_details pd ON cte3.products = product_id
GROUP BY
	TIMES

/*
Reporting Challenge
Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)
*/

CREATE OR REPLACE PROCEDURE G(month int)
LANGUAGE PLPGSQL
AS $$
BEGIN
WITH cte AS (
    SELECT
        s1.prod_id AS prod1,
        s2.prod_id AS prod2,
		s3.prod_id AS prod3,
		count(*) times,
        RANK() OVER (ORDER BY COUNT(*) DESC) rnk
    FROM sales s1
    INNER JOIN sales s2
        ON s1.prod_id < s2.prod_id AND s1.txn_id = s2.txn_id
	INNER JOIN sales s3
		ON s2.prod_id < s3.prod_id AND s2.txn_id = s3.txn_id
	
    GROUP BY
        prod1,prod2,prod3
	ORDER BY 
		rnk 
	LIMIT 1
),
--SELECT ARRAY[prod1,prod2,prod3] from cte
cte2 as(
	SELECT array_agg(array[prod1,prod2,prod3]) as products, times from CTE

GROUP BY times
),cte3  as (
select unnest(products) as products,times from cte2
)
select string_agg(product_name,', ') PRODUCTS, times::smallint FROM cte3
JOIN product_details pd ON cte3.products = product_id
GROUP BY TIMES;
END;
$$

CALL G(2)

/*
Bonus Challenge
Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!

*/

SELECT
	product_id,
	price,
	(ph1.level_text||' '||ph2.level_text||' '||ph3.level_text) AS product_name,
	ph3.id AS category_id,
	ph2.id AS segment_id,
	ph1.id AS style_id,
	ph3.level_text AS category_name,
    ph2.level_text AS segment_name,
    ph1.level_text AS style_name
FROM
  product_hierarchy AS ph1
  LEFT JOIN product_hierarchy AS ph2 on ph1.parent_id = ph2.id
  LEFT JOIN product_hierarchy AS ph3 on ph2.parent_id = ph3.id
  LEFT JOIN product_prices AS pp on ph1.id = pp.id
WHERE product_id IS NOT NULL

SELECT * FROM product_hierarchy
select * from product_prices
select * from product_details

