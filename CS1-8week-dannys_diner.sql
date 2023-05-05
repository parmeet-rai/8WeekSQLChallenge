--Schema SQL Query SQL ResultsEdit on DB Fiddle
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
SELECT * FROM menu;
SELECT * FROM members;
SELECT * FROM sales;

-- QUESTIONS

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
	S.customer_id, SUM(M.PRICE) "Total Amount"
FROM 
	MENU M
JOIN 
	SALES S 
ON 
	S.product_id = M.product_id
GROUP BY 
	S.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
	CUSTOMER_ID, COUNT(DISTINCT(ORDER_DATE)) DAYS
FROM
	SALES
GROUP BY CUSTOMER_ID;


-- 3. What was the first item from the menu purchased by each customer?

WITH CTE AS(
SELECT 
	*, RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE) RN
FROM 
	SALES)
SELECT 
	CUSTOMER_ID, PRODUCT_ID 
FROM 
	CTE
WHERE 
	RN=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	M.PRODUCT_NAME,COUNT(S.PRODUCT_ID) TIMES 
FROM
	SALES S
JOIN 
	MENU M 
ON 
	M.PRODUCT_ID = S.PRODUCT_ID 
GROUP BY 
	M.PRODUCT_NAME
ORDER BY 
	TIMES DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH CTE AS(
SELECT 
	CUSTOMER_ID,M.PRODUCT_NAME,COUNT(S.PRODUCT_ID) TOTAL_ORDER ,
	DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(CUSTOMER_ID) DESC) TOtal
FROM
	SALES S
JOIN 
	MENU M 
ON 
	M.PRODUCT_ID = S.PRODUCT_ID 
GROUP BY 
	s.customer_id,M.product_name
)
SELECT 
	CUSTOMER_ID,PRODUCT_NAME,TOTAL_ORDER 
FROM 
	CTE
WHERE 
	CTE.TOTAL = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS(
SELECT 
	S.CUSTOMER_ID, S.PRODUCT_ID,M1.PRODUCT_NAME,S.ORDER_dATE,
	RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE) RN FROM SALES S
JOIN 
	MEMBERS M 
ON 
	M.CUSTOMER_ID = S.CUSTOMER_ID
JOIN 
	MENU M1 
ON 
	M1.PRODUCT_ID = S.PRODUCT_ID
WHERE 
	S.ORDER_DATE >= M.JOIN_dATE)
SELECT 
	CUSTOMER_ID, PRODUCT_ID,PRODUCT_NAME,ORDER_DATE  
FROM 
	CTE
WHERE 
	CTE.RN = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH CTE AS(
SELECT 
	S.CUSTOMER_ID, S.PRODUCT_ID,M1.PRODUCT_NAME,S.ORDER_dATE, DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE DESC) RN 
FROM 
	SALES S
JOIN 
	MEMBERS M 
ON 
	M.CUSTOMER_ID = S.CUSTOMER_ID
JOIN 
	MENU M1 
ON 
	M1.PRODUCT_ID = S.PRODUCT_ID
WHERE 
	S.ORDER_DATE < M.JOIN_dATE)
SELECT 
	CUSTOMER_ID, PRODUCT_ID,PRODUCT_NAME,ORDER_DATE  
FROM 
	CTE
WHERE 
	CTE.RN = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
	S.CUSTOMER_ID, COUNT(S.PRODUCT_ID), SUM(PRICE) 
FROM 
	SALES S
JOIN 
	MENU M 
ON 
	M.PRODUCT_ID = S.PRODUCT_ID
JOIN 
	MEMBERS M1 
ON 
	M1.CUSTOMER_ID = S.CUSTOMER_ID
WHERE 
	S.ORDER_DATE < M1.JOIN_dATE
GROUP BY 
	S.CUSTOMER_ID;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH CTE AS(
SELECT 
	CUSTOMER_ID,SUM(
	CASE WHEN PRODUCT_NAME = 'sushi' then 20*price else 0 END ) AS sushi_p,
	SUM(CASE WHEN PRODUCT_NAME <> 'sushi' then 10*price else 0 END
	) AS POINTS
FROM 
	SALES S
JOIN 
	MENU M 
ON 
	M.PRODUCT_ID = S.PRODUCT_ID 
GROUP BY 
	CUSTOMER_ID)
SELECT 
	CUSTOMER_ID, sushi_p+points as Points 
FROM 
	cte
ORDER BY
	CUSTOMER_ID;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?

WITH CTE AS(
SELECT 
	S.CUSTOMER_ID,
	SUM(CASE WHEN (ORDER_DATE BETWEEN JOIN_DATE AND JOIN_DATE + INTERVAL '6 DAYS') OR PRODUCT_NAME = 'sushi' THEN 20*price ELSE 0 END ) "2X_POINTS",
	SUM(CASE WHEN PRODUCT_NAME <> 'sushi' AND ORDER_DATE NOT BETWEEN JOIN_DATE AND JOIN_DATE + INTERVAL '6 DAYS' THEN 10*price ELSE 0 END) AS POINTS
FROM 
	SALES S
JOIN 
	MENU M 
ON 
	M.PRODUCT_ID = S.PRODUCT_ID
JOIN 
	MEMBERS M1 
ON 
	M1.CUSTOMER_ID = S.CUSTOMER_ID
WHERE 
	ORDER_DATE < '2021-02-01'
GROUP BY
	S.CUSTOMER_ID)
SELECT
	CUSTOMER_ID, "2X_POINTS"+POINTS POINTS 
FROM 
	CTE;
