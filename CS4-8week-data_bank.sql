SET SEARCH_PATH = DATA_BANK
SELECT * FROM data_bank.customer_nodes order by customer_id
SELECT * FROM data_bank.customer_transactions
SELECT * FROM data_bank.regions
----------------------------------------------A. Customer Nodes Exploration


-- 1. How many unique nodes are there on the Data Bank system?

SELECT 
	COUNT(distinct node_id) "TOTAL_NODES"
FROM 
	customer_nodes

-- 2. What is the number of nodes per region?

SELECT 
	r.region_id,
	region_name,
	count(distinct node_id) node,
	count(node_id) no_of_nodes
FROM
	customer_nodes c
JOIN
	regions r on r.region_id = c.region_id
GROUP BY 
	region_name,r.region_id
ORDER BY
	r.region_id
-- 3. How many customers are allocated to each region?

SELECT 
	c.region_id,
	region_name,
	count(distinct customer_id) relocated_customers
FROM 
	customer_nodes c
JOIN 
	regions r
ON
	r.region_id = c.region_id	
GROUP BY 
	c.region_id,region_name
	
	

-- 4. How many days on average are customers reallocated to a different node?

SELECT 
	round(AVG(END_DATE - START_DATE))
FROM 
	CUSTOMER_NODES 
WHERE 
	END_DATE <> '9999-12-31' 

select  from customer_nodes


-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

SELECT 
   	REGION_ID,
	percentile_disc(0.5) within group(order by (end_date - start_date)) median,
	percentile_disc(0.8) within group(order by (end_date - start_date)) "80th_precentile",
	percentile_disc(0.95) within group(order by (end_date - start_date)) "95th_precentile"
FROM 
	CUSTOMER_NODES
WHERE end_date != '9999-12-31' 
GROUP BY
	region_ID

----------------------------------------------B. Customer Transactions


-- 1. What is the unique count and total amount for each transaction type?

SELECT 
	TXN_TYPE,
	COUNT(DISTINCT CUSTOMER_ID),
	SUM(TXN_AMOUNT) TOTAL_AMT
FROM 
	customer_transactions
GROUP BY
	txn_type

-- 2. What is the average total historical deposit counts and amounts for all customers?

SELECT
	FLOOR(COUNT(CUSTOMER_ID)::NUMERIC/(SELECT COUNT(DISTINCT CUSTOMER_ID) FROM customer_transactions)) ,
	ROUND(AVG(TXN_AMOUNT),2)
FROM
	customer_transactions
	
-- 3. For each month - how many Data Bank customers make more than 1 deposit and 
	-- either 1 purchase or 1 withdrawal in a single month?

with cte as( 
	SELECT
		ct.customer_id,
	    to_char(txn_date,'Month') as month,
		sum(case when txn_type = 'deposit' then 1 else 0 end)deposit,
		sum(case when txn_type = 'purchase' then 1 else 0 end) purchase,
		sum(case when txn_type = 'withdrawal' then 1 else 0 end)  withdrawal
	FROM customer_transactions ct
	GROUP BY ct.customer_id,month
	ORDER BY ct.customer_id,month
)
SELECT 
	month, count(distinct customer_id) 
FROM 
	cte
WHERE 
	deposit >1 and (purchase >=1 or withdrawal >=1) 
GROUP BY
	month
ORDER BY
	to_date(month,'Month')
	
				
-- 4. What is the closing balance for each customer at the end of the month?

WITH cte as(
SELECT 
	customer_id,
	to_char(txn_date,'month') "month",
	SUM(CASE WHEN txn_type = 'deposit' then TXN_AMOUNT else -TXN_AMOUNT END) balance
FROM 
	customer_transactions
GROUP BY
	customer_id,month
ORDER BY
	customer_id, "month"
),
cte2 as(
SELECT 
	customer_id,
	month,
	balance,	
	sum(balance) over (partition by customer_id order by to_date(month,'Month') rows between unbounded preceding and current row) as closing_balance
	--row_number() over (partition by customer_id, month order by to_date(month,'Month') desc)	as rn
FROM cte)
SELECT 
	customer_id,
	month,
	balance,
	closing_balance
FROM cte2
-- where rn = 1


-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
---ANSWER WRONG

with cte as(
SELECT 
	customer_id,
	to_char(txn_date,'month') "month",
	sum(CASE WHEN txn_type = 'deposit' then TXN_AMOUNT else -TXN_AMOUNT END) balance
FROM 
	customer_transactions
GROUP BY
	customer_id,month
ORDER BY
	customer_id, "month"
),
cte2 as(
SELECT customer_id,
	month,
	balance,	
	sum(balance) over (partition by customer_id order by to_date(month,'Month') rows between unbounded preceding and current row) as closing_balance, 
	row_number() over (partition by customer_id, month order by to_date(month,'Month') desc)	as rn
FROM cte),
cte3 as(
SELECT 
	*,(100*(closing_balance - lag(closing_balance) over(partition by customer_id)))/nullif(lag(closing_balance) over (partition by customer_id),0) as growth 
FROM cte2
)
SELECT
	round((100*count(customer_id))/(select count( customer_id) from customer_transactions)::numeric,2)
FROM 
	cte3 WHERE growth > 5
AND rn =1

----------------------------------------------C. Data Allocation Challenge

/*
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank 
team estimate how much data will need to be provisioned for each option:

*running customer balance column that includes the impact each transaction
*customer balance at the end of each month
*minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?
*/

SELECT * FROM CUSTOMER_TRANSACTIONS ORDER BY CUSTOMER_ID, TXN_DATE

WITH CTE AS(
SELECT customer_id,
	TXN_DATE,
	TXN_TYPE,	
	sum(CASE WHEN txn_type = 'deposit' then TXN_AMOUNT else -TXN_AMOUNT END) TXN_AMOUNT
FROM 
	customer_transactions
GROUP BY 1,2,3
ORDER BY customer_id)
SELECT CUSTOMER_ID,
	TXN_DATE,
	TXN_TYPE,
	TXN_AMOUNT,
	SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RUNNING_BALANCE
FROM CTE

-- 2ND
with cte as( --LABELEING TRANSACTIONS WITH IMPACT AS + OR -
SELECT 
	customer_id,
	to_char(txn_date,'month') "month",
	sum(CASE WHEN txn_type = 'deposit' then TXN_AMOUNT else -TXN_AMOUNT END) balance
FROM 
	customer_transactions
GROUP BY 
	customer_id,month
ORDER BY
	customer_id, "month"
)
SELECT customer_id,
	month,
	balance,	
	sum(balance) over (partition by customer_id order by to_date(month,'Month') rows between unbounded preceding and current row) as closing_balance
	--row_number() over (partition by customer_id, month order by to_date(month,'Month') desc)	as rn
FROM 
	cte


-- 3RD

WITH CTE AS(
SELECT customer_id,
	TXN_DATE,
	TXN_TYPE,	
	sum(CASE WHEN txn_type = 'deposit' then TXN_AMOUNT else -TXN_AMOUNT END) TXN_AMOUNT
FROM 
	customer_transactions
GROUP BY 1,2,3
ORDER BY customer_id),
CTE2 AS(
SELECT CUSTOMER_ID,
	TXN_DATE,
	TXN_TYPE,
	TXN_AMOUNT,
	SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) RUNNING_BALANCE
FROM CTE)
SELECT CUSTOMER_ID,
	MIN(RUNNING_BALANCE) OVER(PARTITION BY CUSTOMER_ID) MIN_BAL,
	ROUND(AVG(RUNNING_BALANCE) OVER(PARTITION BY CUSTOMER_ID),2) AVG_BAL,
	MAX(RUNNING_BALANCE) OVER(PARTITION BY CUSTOMER_ID) MAX_BAL
FROM CTE2



-- D. Extra Challenge
/*
Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

Special notes:

Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
Extension Request
The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.

*/

WITH CTE AS(
SELECT 
	customer_id,
	TXN_DATE,
	TXN_TYPE,	
	sum(CASE WHEN txn_type = 'deposit' then TXN_AMOUNT else -TXN_AMOUNT END) TXN_AMOUNT
FROM 
	customer_transactions
GROUP BY
	1,2,3
ORDER BY customer_id),
CTE2 AS
(SELECT
 	CUSTOMER_ID,
	TXN_DATE,
	SUM(TXN_AMOUNT) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) RUNNING_BALANCE
FROM 
 	CTE
ORDER BY
 	CUSTOMER_ID,TXN_DATE)
SELECT 
	CUSTOMER_ID,RUNNING_BALANCE,TXN_DATE,
	(CASE WHEN LAG(RUNNING_BALANCE) OVER() > 0 THEN
	(RUNNING_BALANCE + ROUND(LAG(RUNNING_BALANCE) OVER (PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE)*(TXN_DATE - LAG(TXN_DATE) OVER(PARTITION BY CUSTOMER_ID ORDER BY TXN_DATE))*(6/365::NUMERIC),2))
		ELSE RUNNING_BALANCE END)
	 "bal+interest"
FROM 
	CTE2
ORDER BY
	CUSTOMER_ID,TXN_DATE

SELECT * FROM CUSTOMER_TRANSACTIONS
ORDER BY 1,2



SELECT * FROM CUSTOMER_TRANSACTIONS
ORDER BY 1,2

SELECT (TXN_DATE - LAG(TXN_DATE) OVER())
FROM CTE2


