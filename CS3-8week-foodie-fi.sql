SET SEARCH_PATH = 'foodie_fi'

-- A
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT 
	customer_id,
	s.plan_id,
	plan_name,
	price,
	start_date
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id
WHERE customer_id < 9;


/*
Above query produce result which contains 8 customer's on boarding journey,
i'll describe subcription journey for 2 customers in brief.
customer 2 - has started his subscription on 2020-09-27 by opting-in trial plan
of 7 days, after completion of trial plan customer has opted for "pro annual"
which costs around $199.0 / annualy and plan includes no watch time limits and 
are able to download videos for offline viewing.
customer 4 - has started his subscription on 2020-01-17 by opting-in trial plan
of 7 days, after completion of trial plan customer has enrolled for "basic"
which costs around $9.90 / monthly and plan have limited access and 
can only stream their videos, after around 3 months of subscription customer 
has cancelled his subscription on 2020-04-21.
*/

------------------ B. Data Analysis Questions-----------------------------

-- 1. How many customers has Foodie-Fi ever had?

SELECT 
	Count(distinct customer_id) 
FROM 
	Subscriptions

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT 
	Extract(Month from start_date) as _Month, Count(Extract(Month from start_date)) 
FROM 
	subscriptions
WHERE 
	plan_id = 0
Group by 
	_Month
ORDER BY
	_MONTH

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT * FROM subscriptions
SELECT * FROM PLANS

SELECT 
	plan_name,
	COUNT(customer_id) Events_Total 
FROM 
	subscriptions s
JOIN 
	plans p 
ON 
	p.plan_id = s.plan_id
Where 
	Start_date > '31-12-2020'
Group by 
	plan_name

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
	PLAN_ID,COUNT(customer_id) ,
	(100*(COUNT(customer_id)))/(SELECT COUNT(DISTINCT customer_id)
								FROM subscriptions) as Percent 
From 
	subscriptions
WHERE 
	PLAN_ID = 4
GROUP BY
	PLAN_ID

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH CTE AS(
	SELECT 
		CUSTOMER_ID,
		PLAN_ID, 
		LAG(PLAN_ID) OVER (PARTITION BY CUSTOMER_ID ORDER BY PLAN_ID) PREV
	FROM 
		SUBSCRIPTIONS)
SELECT 
	COUNT(CUSTOMER_ID),
	ROUND((100*COUNT(CUSTOMER_ID)::NUMERIC)/(SELECT COUNT(DISTINCT CUSTOMER_ID) 
								  FROM SUBSCRIPTIONS),2) AS PERCENT 
FROM 
	CTE
WHERE 
	PLAN_ID = 4 AND PREV = 0

-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH CTE AS(
	SELECT 
		CUSTOMER_ID,
		PLAN_ID,
		LEAD(PLAN_ID) OVER (PARTITION BY CUSTOMER_ID ORDER BY PLAN_ID) NEXT 
	FROM SUBSCRIPTIONS)
SELECT 
	NEXT,
	COUNT(CUSTOMER_ID),
	ROUND((100*COUNT(CUSTOMER_ID)::NUMERIC)/(SELECT COUNT(DISTINCT CUSTOMER_ID) 
								  FROM SUBSCRIPTIONS),2) AS PERCENT 
FROM 
	CTE
WHERE 
	PLAN_ID = 0 AND NEXT IS NOT NULL
GROUP BY
	NEXT
ORDER BY
	NEXT

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH CTE AS(
	SELECT 
		*,ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY START_DATE DESC) AS LATEST_PLAN
	FROM 
		SUBSCRIPTIONS
	WHERE 
		START_DATE <= '2020-12-31')
	
SELECT 
	PLAN_ID, COUNT(CUSTOMER_ID),
	ROUND((100*COUNT(CUSTOMER_ID)::NUMERIC)/(SELECT COUNT(DISTINCT CUSTOMER_ID) 
								  FROM SUBSCRIPTIONS),2) AS PERCENT
FROM 
	CTE
WHERE 
	LATEST_PLAN = 1
GROUP BY
	PLAN_ID

-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT 
	COUNT(CUSTOMER_ID) 
FROM 
	SUBSCRIPTIONS
WHERE 
	PLAN_ID = 3 AND START_DATE BETWEEN '01-01-2020' AND '31-12-2020'

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH CTE AS
  (SELECT 
   		*,
        first_value(start_date) over(PARTITION BY customer_id
                                       ORDER BY start_date) AS trial_plan_start_date
   FROM 
   	subscriptions)
SELECT 
	round(avg((start_date - trial_plan_start_date)), 2)AS avg_conversion_days
FROM 
	CTE
WHERE
  	plan_id =3 AND START_DATE BETWEEN '01-01-2020' AND '31-12-2020' ;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH cte AS 
(SELECT 
  customer_id, 
  start_date AS trial_date
FROM foodie_fi.subscriptions
WHERE plan_id = 0
),
cte2 AS
(SELECT 
  customer_id, 
  start_date AS annual_date
FROM foodie_fi.subscriptions
WHERE plan_id = 3
),

diff AS (SELECT
	ROUND((annual_date-trial_date),0) AS datediff
FROM
	cte tp
JOIN cte2 an
	ON tp.customer_id=an.customer_id)
	
SELECT 
CAST((30 * FLOOR(datediff / 30)) AS VARCHAR) || '-' || CAST((30 * (FLOOR(datediff/ 30) + 1)) AS VARCHAR) day_range,
count(*) AS no_of_times
FROM diff
GROUP BY 30 * FLOOR(datediff/ 30), 30 * (FLOOR(datediff / 30) + 1)
ORDER BY MIN(datediff);

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH CTE AS(
	SELECT 
		CUSTOMER_ID,
		PLAN_ID,
		START_DATE, 
		LEAD(PLAN_ID) OVER (PARTITION BY CUSTOMER_ID) AS NEXT_PLAN
	FROM 
		SUBSCRIPTIONS)
SELECT 
	COUNT(CUSTOMER_ID) DOWNGRADED
FROM 
	CTE
WHERE 
	PLAN_ID = 2 AND NEXT_PLAN = 1 AND START_DATE BETWEEN '01-01-2020' AND '31-12-2020'

SELECT * FROM PLANS

--------------------- C. Challenge Payment Question---------------------------------

/*
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

-monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-once a customer churns they will no longer make payments
*/


WITH CTE AS(
	SELECT 
		CUSTOMER_ID,
		S.PLAN_ID,
		generate_series(start_date, 
					case when S.plan_id = 3 then start_date 
						when S.plan_id = 4 then NULL 
						when lead(start_date)over(partition by customer_id order by start_date) is not null 
							then lead(start_date)over(partition by customer_id order by start_date) 
						else '2020-12-31'::date end, '1 month'::interval) as payment_date,
		PRICE,
		PLAN_NAME
	FROM 
		SUBSCRIPTIONS S
	JOIN 
		PLANS P ON S.PLAN_ID = P.PLAN_ID 
	WHERE 
		S.PLAN_ID <> 0 AND S.PLAN_ID <> 4
	AND START_DATE BETWEEN '01-01-2020' AND '31-12-2020'
),
CTE2 AS(
	SELECT 
		*,LEAD(PLAN_ID,1) OVER(PARTITION BY CUSTOMER_ID ORDER BY PAYMENT_DATE) NEXT_PLAN,
		LAG(PLAN_ID,1) OVER(PARTITION BY CUSTOMER_ID ORDER BY PAYMENT_DATE
							 RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) PREV_PLAN,
		LAG(PRICE,1) OVER(PARTITION BY CUSTOMER_ID ORDER BY PAYMENT_DATE
							 RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) PREV_P,
		LAG(PAYMENT_DATE) OVER() X
	FROM 
		CTE
),
CTE3 AS
(SELECT 
 	CUSTOMER_ID,
	PLAN_ID,
	PLAN_NAME,
	PAYMENT_DATE,
	 (CASE WHEN PREV_PLAN = 1 AND PLAN_ID !=1 THEN PRICE - PREV_P 
			ELSE PRICE END) AS AMOUNT,
	 ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY PAYMENT_DATE) AS PAYMENT_ORDER
FROM 
 	CTE2)
SELECT 
	*
INTO 
	PAYMENT
FROM 
	CTE3
 
SELECT * FROM PAYMENT

-- D. Outside The Box Questions

-- How would you calculate the rate of growth for Foodie-Fi?

WITH CTE AS(
SELECT
  DATE_TRUNC('month', start_date) AS month,
  COUNT(customer_id) AS current_number_of_customers,
  LAG(COUNT(customer_id), 1) over (ORDER BY DATE_TRUNC('month', start_date)) AS past_customer_num,
  (100 * (COUNT(customer_id) 
  - LAG(COUNT(customer_id), 1) over (ORDER BY DATE_TRUNC('month', start_date))) 
   / LAG(COUNT(customer_id), 1) over (ORDER BY DATE_TRUNC('month', start_date))) || '%' AS growth
FROM
  subscriptions AS s
JOIN 
	plans AS p ON s.plan_id = p.plan_id
GROUP BY
  1
ORDER BY
  1)
SELECT 
	EXTRACT(MONTH FROM MONTH), 
	current_number_of_customers,
	past_customer_num,
	growth
FROM 
	CTE

-- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
	
	-- No of customer month by month
	-- How many customers buy the plan after trial ends
	-- Why are customers ending subscription
	-- Financial growth and costs


-- What are some key customer journeys or experiences that you would analyse further to improve customer retention?

	-- How many customers buy the plan after trial ends
	-- How many buy the annual plan (as it shows their commitment)
	-- reason of churning
	-- Are the customers feeling the subscriptions worth it
	
-- If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

	--Why are you ending the subscriptions?
	-- Where can we improve in User Experience?
	-- How would you rate our content?
	-- Would you again be our customer?
	
-- What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

	-- Make more content which is liked by the audience
	-- Ask for rating which will help in knowing customer interest
	-- Have a referral programme which incentivizes the customer
	-- Provide them offers after few months of churn
	
