CREATE SCHEMA pizza_runner1;
SET search_path = pizza_runner1;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;

CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
SELECT * FROM CUSTOMER_ORDERS;
SELECT * FROM PIZZA_NAMES;
SELECT * FROM PIZZA_RECIPES;
SELECT * FROM PIZZA_TOPPINGS;
SELECT * FROM RUNNER_ORDERS;
SELECT * FROM RUNNERS;

SELECT order_id, customer_id, pizza_id, 
  CASE 
    WHEN exclusions IS null OR exclusions LIKE 'null' THEN ' '
    ELSE exclusions
    END AS exclusions,
  CASE 
    WHEN extras IS NULL or extras LIKE 'null' THEN ' '
    ELSE extras 
    END AS extras, 
  order_time
INTO customer_orders1 
FROM customer_orders;

SELECT order_id, runner_id,
  CASE 
    WHEN pickup_time LIKE 'null' THEN null
    ELSE pickup_time 
    END AS pickup_time,
  CASE 
    WHEN distance LIKE 'null' THEN null
    WHEN distance LIKE '%km' THEN TRIM('km' from distance) 
    ELSE distance END AS distance,
  CASE 
    WHEN duration LIKE 'null' THEN null
    WHEN duration LIKE '%mins' THEN TRIM('mins' from duration) 
    WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)        
    WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)       
    ELSE duration END AS duration,
  CASE 
    WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ''
    ELSE cancellation END AS cancellation
INTO runner_orders1
FROM runner_orders;

ALTER TABLE runner_orders1
ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::timestamp without time zone,
ALTER COLUMN distance TYPE FLOAT USING distance::double precision, 
ALTER COLUMN duration TYPE INT USING duration::integer;

-- A. Pizza Metrics
-- 1. How many pizzas were ordered?

SELECT 
	COUNT(ORDER_ID) "TOTAL_ORDERS" 
FROM 
	CUSTOMER_ORDERS;

-- 2. How many unique customer orders were made?

SELECT 
	COUNT(DISTINCT(ORDER_ID)) "UNQ_ORDERS" 
FROM 
	CUSTOMER_ORDERS

-- 3. How many successful orders were delivered by each runner?

SELECT 
	RUNNER_ID,COUNT(ORDER_ID) TOTAL_ORDERS
FROM 
	RUNNER_ORDERS 
WHERE 
	PICKUP_TIME NOT LIKE 'null'
GROUP BY 
	RUNNER_ID;

-- 4. How many of each type of pizza was delivered?

SELECT 
	PIZZA_NAME,COUNT(CO.ORDER_ID) TOTAL
FROM 
	CUSTOMER_ORDERS AS CO
JOIN 
	RUNNER_ORDERS RO 
ON 
	RO.ORDER_ID =  CO.ORDER_ID
JOIN 
	PIZZA_NAMES PN 
ON 
	PN.PIZZA_ID = CO.PIZZA_ID
WHERE 
	PICKUP_TIME NOT LIKE 'null'
GROUP BY 
	PIZZA_NAME
ORDER BY 
	TOTAL DESC;
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
	CUSTOMER_ID,PIZZA_NAME,COUNT(ORDER_ID) TOTAL
FROM 
	CUSTOMER_ORDERS CO
JOIN 
	PIZZA_NAMES PN 
ON 
	PN.PIZZA_ID = CO.PIZZA_ID
GROUP BY 
	CUSTOMER_ID,PN.PIZZA_NAME
ORDER BY 
	CUSTOMER_ID;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT 
	ORDER_ID,COUNT(ORDER_ID) TOTAL 
FROM 
	CUSTOMER_ORDERS
GROUP BY
	ORDER_ID
ORDER BY
	TOTAL DESC
LIMIT 1;
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT 
		CUSTOMER_ID,
		SUM(CASE WHEN (EXCLUSIONS = '' OR EXCLUSIONS = 'null' OR EXCLUSIONS IS NULL) 
			AND (EXTRAS = '' OR EXTRAS = 'null' OR EXTRAS IS NULL) THEN 1 ELSE 0 END) AS NO_CHANGES,
		SUM(CASE WHEN (EXCLUSIONS <> '' and EXCLUSIONS <> 'null' and EXCLUSIONS IS NOT NULL) 
			or (EXTRAS <> '' and EXTRAS <> 'null' and EXTRAS IS NOT NULL) THEN 1 ELSE 0 END) AS CHANGES
FROM 
	CUSTOMER_ORDERS CO
JOIN 
	RUNNER_ORDERS RO 
ON 
	RO.ORDER_ID = CO.ORDER_ID
WHERE 
	PICKUP_TIME NOT LIKE 'null'
GROUP BY 
	CUSTOMER_ID
ORDER BY 
	CUSTOMER_ID;

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT 
	SUM(CASE WHEN (EXCLUSIONS <> '' and EXCLUSIONS <> 'null' and EXCLUSIONS IS NOT NULL) AND 
	(EXTRAS <> '' and EXTRAS <> 'null' and EXTRAS IS NOT NULL) THEN 1 ELSE 0 END) AS PIZZA_WITH_EXTRAS_EXCL
FROM 
	CUSTOMER_ORDERS CO
JOIN 
	RUNNER_ORDERS RO 
ON
	RO.ORDER_ID = CO.ORDER_ID
WHERE 
	PICKUP_TIME NOT LIKE 'null';


-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT 
	EXTRACT(HOUR from ORDER_TIME) "HOUR" ,COUNT(EXTRACT(HOUR from ORDER_TIME)) TOTAL 
FROM 
	CUSTOMER_ORDERS
GROUP BY
	"HOUR" 
ORDER BY
	"HOUR";

-- 10.What was the volume of orders for each day of the week?

SELECT 
	EXTRACT(DOW from ORDER_TIME) "DOW" ,COUNT(EXTRACT(DOW from ORDER_TIME)) "TOTAL" 
FROM
	CUSTOMER_ORDERS
GROUP BY
	"DOW" 
ORDER BY
	"DOW";




-- B. Runner and Customer Experience


-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
	DATE_PART('week', registration_date) AS registration_week,
 	COUNT(runner_id) AS runner_signup
FROM 
	runners
GROUP BY 
	registration_week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
	RUNNER_ID,AVG(pickup_time - order_time) 
FROM 
	CUSTOMER_ORDERS CO
JOIN 
	RUNNER_ORDERS RO 
ON 
	RO.order_id = CO.order_id
GROUP BY
	RUNNER_ID

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH CTE AS(
	SELECT 
		CO.ORDER_ID,COUNT(CO.ORDER_ID) AS PIZZA,CO.ORDER_TIME,RO.PICKUP_TIME,AGE(RO.PICKUP_TIME,CO.ORDER_TIME) AS TIME
	FROM 
		CUSTOMER_ORDERS CO
	JOIN 
		RUNNER_ORDERS RO 
	ON 
		RO.order_id = CO.order_id
	WHERE 
		DISTANCE IS NOT NULL
	GROUP BY 
		CO.ORDER_ID,ORDER_TIME,PICKUP_TIME)
	
SELECT 
	PIZZA,AVG(TIME) 
FROM 
	CTE
GROUP BY 
	PIZZA
ORDER BY 
	PIZZA

--YES, THERE IS A RELATIONSHIP AS MORE PIZZA LEAD TO MORE TIME

-- 4. What was the average distance travelled for each customer?

SELECT 
	CUSTOMER_ID,ROUND(AVG(DISTANCE::INT),2) "AVG_DIST" 
FROM 
	RUNNER_ORDERS RO
JOIN 
	CUSTOMER_ORDERS CO 
ON 
	CO.ORDER_ID = RO.ORDER_ID
GROUP BY 
	CO.CUSTOMER_ID
ORDER BY 
	CO.CUSTOMER_ID

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
	MAX(DURATION) - MIN(DURATION) DURATION 
FROM 
	RUNNER_ORDERS
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
	DISTINCT CO.ORDER_ID,RO.RUNNER_ID,ROUND((DISTANCE/(DURATION/60)),2) SPEED 
FROM 
	CUSTOMER_ORDERS CO
JOIN 
	RUNNER_ORDERS RO 
ON 
	RO.ORDER_ID = CO.ORDER_ID
WHERE 
	DISTANCE IS NOT NULL
ORDER BY 
	CO.ORDER_ID

--YES, RUNNER 2'S SPEED RANGES FROM 35.10 TO 93.60, SO THERE MIGHT BE SOMETHING

-- 7. What is the successful delivery percentage for each runner?
SELECT 
	RUNNER_ID,(100*SUM(CASE WHEN DISTANCE IS NOT NULL THEN 1 ELSE 0 END ))/COUNT(*)
FROM 
	RUNNER_ORDERS
GROUP BY 
	RUNNER_ID
ORDER BY 
	RUNNER_ID

-- C. Ingredient Optimisation


-- 1. What are the standard ingredients for each pizza?

--CREATING CLEANED TABLE
SELECT 
	pizza_id,unnest(string_to_array(toppings,','))::int AS TOPPING_ID 
INTO 
	clean_ingredients 
FROM 
	pizza_recipes

SELECT 
	ci.*,topping_name 
FROM 
	pizza_names pn
JOIN 
	clean_ingredients ci 
ON 
	ci.pizza_id = pn.pizza_id
JOIN 
	PIZZA_TOPPINGS PT 
ON 
	PT.TOPPING_ID = ci.TOPPING_ID
ORDER BY 
	ci.PIZZA_ID,Ci.TOPPING_ID

-- 2. What was the most commonly added extra?

--CREATING CLEANED TABLE


SELECT 
	S_ID,ORDER_ID, CAST(UNNEST(STRING_TO_ARRAY(EXTRAS,',')) AS INT) AS EXTRAS 
INTO 
	C_EXTRAS
FROM 
	CUST_ORDERS
WHERE 
	EXTRAS NOT LIKE ' '

WITH CTE2 AS(
SELECT 
	TOPPING_NAME,COUNT(EXTRAS) AS QUANT 
FROM 
	C_EXTRAS CE
JOIN 
	PIZZA_TOPPINGS PT 
ON 
	PT.TOPPING_ID = CE.EXTRAS
GROUP BY 
	TOPPING_NAME)
SELECT 
	TOPPING_NAME,QUANT 
FROM 
	CTE2
ORDER BY
	QUANT DESC LIMIT 1

-- 3. What was the most common exclusion?


--CREATING CLEAN TABLE
SELECT 
	S_ID,ORDER_ID ,CAST(UNNEST(STRING_TO_ARRAY(EXCLUSIONS,',')) AS INT) AS EXCLUSIONS 
INTO 
	C_EXCLUSIONS
FROM 
	CUST_ORDERS
WHERE 
	EXCLUSIONS NOT LIKE ' '

SELECT * FROM C_EXCLUSIONS

WITH CTE2 AS(
SELECT 
	TOPPING_NAME,COUNT(EXCLUSIONS) AS QUANT 
FROM 
	C_EXCLUSIONS CE
JOIN 
	PIZZA_TOPPINGS PT 
ON 
	PT.TOPPING_ID = CE.EXCLUSIONS
GROUP BY 
	TOPPING_NAME)
SELECT 
	TOPPING_NAME,QUANT 
FROM 
	CTE2
ORDER BY
	QUANT DESC LIMIT 1

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	-- 	  Meat Lovers
	--    Meat Lovers - Exclude Beef
	--    Meat Lovers - Extra Bacon
	--    Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT 
	* 
INTO 
	CUST_ORDERS
FROM 
	CUSTOMER_ORDERS

ALTER TABLE CUST_ORDERS
ADD COLUMN S_ID INT GENERATED ALWAYS AS IDENTITY 

SELECT * FROM CUST_ORDERS

WITH EXTRAS_CTE AS
(
	SELECT
		CE.S_ID,
		ce.ORDER_ID,
		'Extra ' || STRING_AGG(Pt.topping_name, ', ') as Extras_list
	FROM
		C_EXTRAS ce,
		pizza_toppings pt
	WHERE 
		ce.EXTRAS = pt.topping_id
	GROUP BY 
		ce.ORDER_ID, CE.S_ID
),
EXCLUSIONS_CTE AS
(
	SELECT 
		CE.S_ID,
		ce.ORDER_ID,
		'Exclusions ' || STRING_AGG(TOPPING_NAME,', ') AS Exlusions_list
	FROM 
		C_EXCLUSIONS CE
	JOIN 
		PIZZA_TOPPINGS PT
	ON 
		CE.EXCLUSIONS = PT.TOPPING_ID
	GROUP BY 
		CE.ORDER_ID, CE.S_ID
),
UNION_CTE AS
(
	SELECT 
		S_ID,order_id, Extras_list as E_list 
	FROM 
		EXTRAS_CTE
	UNION
	SELECT 
		S_ID,order_id, Exlusions_list AS E_list 
	FROM
		EXCLUSIONS_CTE),
CTE AS (
	SELECT
		UC.S_ID, UC.ORDER_ID, PN.PIZZA_NAME || ' - ' || E_LIST AS ORDER_ITEM 
	FROM 
		UNION_CTE UC
	JOIN 
		CUST_ORDERS CO 
	ON 
		CO.S_ID = UC.S_ID
	JOIN 
		PIZZA_NAMES PN 
	ON 
		PN.PIZZA_ID = CO.PIZZA_ID
	WHERE EXISTS (SELECT S_ID FROM UNION_CTE 
				  WHERE S_ID = UC.S_ID
				  GROUP BY  S_ID
				  HAVING COUNT(S_ID) = 1
				 ) 
	UNION
	SELECT 
		UC.S_ID, UC.ORDER_ID, PN.PIZZA_NAME || ' - ' || EC.Extras_list || ' ' || EX.Exlusions_list  AS ORDER_ITEM 
	FROM 
		UNION_CTE UC
	JOIN 
		CUST_ORDERS CO 
	ON 
		CO.S_ID = UC.S_ID
	JOIN 
		EXTRAS_CTE EC 
	ON 
		EC.S_ID = UC.S_ID
	JOIN 
		EXCLUSIONS_CTE EX 
	ON 
		EX.S_ID = UC.S_ID 
	JOIN 
		PIZZA_NAMES PN 
	ON 
		PN.PIZZA_ID = CO.PIZZA_ID)
SELECT 
	* 
FROM 
	CTE
ORDER BY 
	S_ID

SELECT * FROM CUST_ORDERS
SELECT * FROM CUSTOMER_ORDERS
-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and 
-- 	  add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

EXPLAIN ANALYSE 
WITH CTE AS (
	SELECT 
		S_ID,ORDER_ID, CI.PIZZA_ID, TOPPING_ID 
	FROM
		CLEAN_INGREDIENTS CI
	JOIN 
		CUST_ORDERS CO 
	ON 
		CO.PIZZA_ID = CI.PIZZA_ID
	UNION ALL
	SELECT 
		CE.S_ID, CE.ORDER_ID, CO.PIZZA_ID, CE.EXTRAS 
	FROM 
		C_EXTRAS CE
	JOIN 
		CUST_ORDERS CO 
	ON 
		CO.S_ID = CE.S_ID
	ORDER BY 
		S_ID,PIZZA_ID,TOPPING_ID
),
CTE2 AS
(
	SELECT 
		S_ID, ORDER_ID,TOPPING_ID,PIZZA_ID, COUNT(TOPPING_ID) "2X" 
	FROM 
		CTE
	GROUP BY 
		S_ID,TOPPING_ID,PIZZA_ID,ORDER_ID
	HAVING 
		COUNT(TOPPING_ID) > 1),
	--SELECT * FROM CTE2
CTE3 AS (
	SELECT 
		S_ID,ORDER_ID, PIZZA_ID, (CASE WHEN CTE2."2X"::VARCHAR <> CTE2.TOPPING_ID::VARCHAR THEN '2x'::VARCHAR || TOPPING_NAME 
									ELSE CTE2.TOPPING_ID::VARCHAR END) AS T2
	FROM 
		CTE2
	JOIN 
		PIZZA_TOPPINGS PT 
	ON 
		PT.TOPPING_ID = CTE2.TOPPING_ID),
--SELECT * FROM CTE3
-- CT AS( SELECT S_ID,ORDER_ID,STRING_AGG(T2,',') T2X FROM CTE3
-- 	 	GROUP BY S_ID,ORDER_ID),
CTE4 AS(
	SELECT 
		CO.S_ID,CO.ORDER_ID,CO.PIZZA_ID, TOPPING_NAME AS ITEMS
	FROM 
		CUST_ORDERS CO
	JOIN 
		CLEAN_INGREDIENTS CI 
	ON 
		CI.PIZZA_ID = CO.PIZZA_ID
	JOIN 
		PIZZA_TOPPINGS PT 
	ON 
		PT.TOPPING_ID = CI.TOPPING_ID
	WHERE 
		(CO.S_ID,CI.TOPPING_ID) NOT IN ( SELECT S_ID,CX.EXCLUSIONS FROM C_EXCLUSIONS CX)
    AND  (CO.S_ID,CI.TOPPING_ID) NOT IN ( SELECT S_ID,CE.EXTRAS FROM C_EXTRAS CE) 
	--GROUP BY CO.S_ID,CO.ORDER_ID
	--ORDER BY CO.S_ID,CO.ORDER_ID
	UNION
	SELECT 
		S_ID,ORDER_ID,PIZZA_ID,T2 AS ITEMS
	FROM 
		CTE3
	),
--SELECT * FROM CTE4
R_CTE AS(
	SELECT 
		S_ID,ORDER_ID, PIZZA_NAME || ': ' || STRING_AGG(ITEMS,', ' ORDER BY REPLACE(ITEMS, '2x', '')) AS INGREDIENTS
	FROM 
		CTE4
	JOIN 
		PIZZA_NAMES PN 
	ON 
		PN.PIZZA_ID = CTE4.PIZZA_ID
	GROUP BY 
		S_ID,ORDER_ID,PIZZA_NAME)
SELECT 
	*
FROM
	R_CTE








-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH CTE AS(
	SELECT 
		S_ID,ORDER_ID, CI.PIZZA_ID, CI.TOPPING_ID,TOPPING_NAME 
	FROM 
		CLEAN_INGREDIENTS CI
	JOIN
		PIZZA_TOPPINGS PT 
	ON
		PT.TOPPING_ID = CI.TOPPING_ID 
	JOIN
		succ_CUST_ORDERS CO 
	ON 
		CO.PIZZA_ID = CI.PIZZA_ID
	EXCEPT
	SELECT 
		CX.S_ID, CX.ORDER_ID, CO.PIZZA_ID, CX.EXCLUSIONS, PT.TOPPING_NAME 
	FROM 
		C_EXCLUSIONS CX
	JOIN 
		PIZZA_TOPPINGS PT 
	ON 
		PT.TOPPING_ID = CX.EXCLUSIONS
	JOIN 
		succ_CUST_ORDERS CO 
	ON 
		CO.S_ID = CX.S_ID 
	UNION ALL
	SELECT 
		CE.S_ID, CE.ORDER_ID, CO.PIZZA_ID, CE.EXTRAS, PT.TOPPING_NAME 
	FROM 
		C_EXTRAS CE
	JOIN 
		PIZZA_TOPPINGS PT 
	ON 
		PT.TOPPING_ID = CE.EXTRAS
	JOIN 
		succ_CUST_ORDERS CO 
	ON
		CO.S_ID = CE.S_ID
	ORDER BY
		S_ID,PIZZA_ID)
SELECT 
	TOPPING_ID,TOPPING_NAME , COUNT(TOPPING_ID) QUANT
FROM 
	CTE
GROUP BY 
	TOPPING_ID,TOPPING_NAME
ORDER BY 
	QUANT DESC

SELECT * FROM RUNNER_ORDERS
-- D. Pricing and Ratings

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
--    how much money has Pizza Runner made so far if there are no delivery fees?

SELECT 
	RUNNER_ID,SUM(CASE WHEN PIZZA_ID = 1 THEN 12 ELSE 10 END) BUSINESS
FROM 
	SUCC_CUST_ORDERS SO
JOIN 
	RUNNER_ORDERS RO 
ON 
	RO.ORDER_ID = SO.ORDER_ID
GROUP BY
	RUNNER_ID
ORDER BY
	RUNNER_ID

-- 2. What if there was an additional $1 charge for any pizza extras?
	--   Add cheese is $1 extra
WITH COST_CTE AS(
SELECT 
	*, (CASE WHEN PIZZA_ID = 1 THEN 12 ELSE 10 END) PRICE
FROM 
	SUCC_CUST_ORDERS
)
SELECT 
	CC.S_ID,CC.ORDER_ID,CC.PIZZA_ID,CC.EXCLUSIONS,CC.EXTRAS,PRICE + 1* COUNT(CE.EXTRAS) AS TOTAL_PRICE
FROM 
	COST_CTE CC
LEFT JOIN
	C_EXTRAS CE ON CE.S_ID = CC.S_ID
GROUP BY 
	CC.S_ID,CC.ORDER_ID,CC.PIZZA_ID,CC.EXCLUSIONS,CC.EXTRAS,PRICE
ORDER BY
	S_ID,PIZZA_ID

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
	-- 	 how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data 
	-- 	 for ratings for each successful customer order between 1 to 5.

SET search_path = RUNNER_RATING;

CREATE SCHEMA RUNNER_RATING

SELECT 
	*,abs(ceil(random()*10 - 5)) as RATING 
INTO
	RUNNER_RATING 
FROM 
	pizza_runner.SUCC_CUST_ORDERS

select * from runner_rating


-- 4. Using your newly generated table - can you join all of the information together to form a table 
--    which has the following information for successful deliveries?
	-- 	customer_id
	-- 	order_id
	-- 	runner_id
	-- 	rating
	-- 	order_time
	-- 	pickup_time
	-- 	Time between order and pickup
	-- 	Delivery duration
	-- 	Average speed
	-- 	Total number of pizzas
	
SELECT 
	RR.CUSTOMER_ID,RR.ORDER_ID,RUNNER_ID,RATING, ORDER_TIME, PICKUP_TIME, EXTRACT(MINUTE FROM (PICKUP_TIME - ORDER_TIME)) TIME_TO_PICK,DURATION , ROUND((DISTANCE/(DURATION/60)),2) AS SPEED, COUNT(S_ID) INTO ORDER_DET
FROM 
	RUNNER_RATING RR
JOIN 
	PIZZA_RUNNER.RUNNER_ORDERS RO 
ON
	RO.ORDER_ID = RR.ORDER_ID
GROUP BY
	RR.CUSTOMER_ID,RR.ORDER_ID,RUNNER_ID,RATING, ORDER_TIME, PICKUP_TIME, (PICKUP_TIME::TIME - ORDER_TIME::TIME),DURATION, SPEED

SELECT * FROM RUNNER_RATING.ORDER_DET

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre 
--    traveled - how much money does Pizza Runner have left over after these deliveries?
WITH CTE AS(
SELECT 
		RUNNER_ID,SUM(CASE WHEN PIZZA_ID = 1 THEN 12 - (0.30*DISTANCE)
		ELSE 10 - (0.30*DISTANCE) END) AS TOTAL_LEFT
FROM 
	PIZZA_RUNNER.RUNNER_ORDERS RO
JOIN 
	PIZZA_RUNNER.SUCC_CUST_ORDERS SO ON SO.ORDER_ID  = RO.ORDER_ID 
GROUP BY
	RUNNER_ID,PIZZA_ID,DISTANCE,SO.ORDER_ID
ORDER BY
		RUNNER_ID)
SELECT
	RUNNER_ID, SUM(TOTAL_LEFT) AS TOTAL_LEFT 
FROM
	CTE
GROUP BY
	RUNNER_ID

WITH CTE AS(
SELECT 
	RUNNER_ID,SUM(CASE WHEN PIZZA_ID = 1 THEN 12 
	ELSE 10  END) + DISTANCE*0.3 AS TOTAL_LEFT
FROM 
	PIZZA_RUNNER.RUNNER_ORDERS RO
JOIN 
	PIZZA_RUNNER.SUCC_CUST_ORDERS SO ON SO.ORDER_ID  = RO.ORDER_ID 
GROUP BY
	RUNNER_ID,PIZZA_ID,DISTANCE,SO.ORDER_ID
ORDER BY
	RUNNER_ID)
SELECT
	RUNNER_ID, SUM(TOTAL_LEFT) AS TOTAL_LEFT 
FROM 
	CTE
GROUP BY
	RUNNER_ID



-- E. Bonus Questions

SELECT 
	* FROM RUNNER_ORDERS RO
JOIN 
	SUCC_CUST_ORDERS SO 
ON
	SO.ORDER_ID = RO.ORDER_ID 
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to 
-- demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

--Following changes to be done, add pizza to the pizza_names and recipe to pizza_recipe

INSERT INTO PIZZA_NAMES VALUES(3,'Supreme')
INSERT INTO PIZZA_RECIPES VALUES(3,'1,2,3,4,5,6,7,8,9,10')


