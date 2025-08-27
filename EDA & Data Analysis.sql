/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers (
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Users\Localadmin\Desktop\Data with Baara\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Users\Localadmin\Desktop\Data with Baara\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Users\Localadmin\Desktop\Data with Baara\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO



/*
=============================================================
EXPLORATORY DATA ANALYSIS
=============================================================
*/

---Explore all objects in the DB
SELECT *
FROM INFORMATION_SCHEMA.TABLES

--Explore all columns in the DB
SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'dim_customers'

--=========================
--DIMESNSION EXPLORATION
--Explore all countries our customers are from
SELECT DISTINCT country
FROM gold.dim_customers;

--Explore all categories in The Major Divisons
SELECT DISTINCT 
	category,
	subcategory,
	product_name
FROM gold.dim_products
ORDER BY 1, 2, 3;


/* DATE EXPLORATION */
--Identify the earliest and the latest dates (boundaries)
SELECT 
	MIN (order_date) AS first_order_date,
	MAX (order_date) AS last_order_date
FROM gold.fact_sales;


--Number of years & months of sales is available
SELECT 
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_month_range,
	DATEDIFF(year, MIN(order_date), MAX(order_date)) As order_year_range
FROM gold.fact_sales;


--the youngest and the oldest customer
SELECT 
	MIN(birthdate) AS oldest_birthdate,
	MAX(birthdate) AS youngest_birthdate,
	DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
	DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;



/*
MEASURES EXPLORATION
Aggregate functions
--total sales
--number of items are sold
--avg selling price
--total number of orders
--total number of products
--total number of customers
--total number of customers that has placed an order
--Generate report that shows all key metrics of the business
*/

SELECT 
	'Total Sales' as measure_name,
	SUM(sales_amount) as measure_value
FROM gold.fact_sales

UNION ALL

SELECT 
	'Total Quantity' as measure_name,
	SUM(quantity) as measure_value
FROM gold.fact_sales

UNION ALL

SELECT 
	'Average Price' as measure_name,
	AVG(price) as measure_value
FROM gold.fact_sales

UNION ALL

SELECT 
	'Total # of Orders' as measure_name,
	COUNT (DISTINCT order_number) as measure_value
FROM gold.fact_sales

UNION ALL

SELECT 
	'Total # of Customers' as measure_name,
	COUNT(customer_key) as measure_value
FROM gold.dim_customers

UNION ALL

SELECT 
	'Total # of Products' as measure_name,
	COUNT(product_key) as measure_value
FROM gold.dim_products

UNION ALL

SELECT 
	'Total # of Customers with Orders' as measure_name,
	COUNT(customer_key) as measure_value
FROM gold.fact_sales


---===============================
--MAGNITUDE ANALYSIS

-- total customers by country

SELECT 
	country,
	COUNT (customer_id) AS total_customers
	FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;



-- total customers by gender
SELECT
	gender,
	COUNT (customer_id) AS total_customer_by_gender
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customer_by_gender;



-- total products by category
SELECT
	category,
	subcategory,
	COUNT (product_key) AS total_products_in_category
FROM gold.dim_products
GROUP BY category, subcategory
ORDER BY total_products_in_category DESC, category, subcategory;


-- average costs in each category
SELECT 
	category,
	AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;


-- total revenue generated for each category
SELECT
	p.category,
	SUM(f.sales_amount) as total_revenue
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as p
	ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;


-- list of customers with total revenue
SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) as total_revenue
FROM gold.fact_sales as f
LEFT JOIN gold.dim_customers as c
	ON f.customer_key =  c.customer_key
GROUP BY 
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC;



-- distribution of sold items across countries
SELECT
	c.country,
	SUM(f.quantity) as total_units_sold
FROM gold.fact_sales as f
LEFT JOIN gold.dim_customers as c
	ON f.customer_key =  c.customer_key
GROUP BY 
	c.country
ORDER BY total_units_sold DESC;


---=======================================
/* RANKING ANALYSIS
Order the values of dimensions based on measures.*/

--1.  5 products that generate the highest revenue
--option 1
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) as total_revenue
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as p
	ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

--option 2
SELECT *
FROM (
	SELECT 
		p.product_name,
		SUM(f.sales_amount) as total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) as rank_products 
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_products as p
		ON f.product_key = p.product_key
	GROUP BY p.product_name
	) as t
WHERE rank_products <= 5




--2. the 5 worst-performing products in terms of sales
--option 1
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) as total_revenue
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as p
	ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;


--option 2
SELECT *
FROM (
	SELECT
		p.product_name,
		SUM(f.sales_amount) as total_revenue,
		ROW_NUMBER () OVER (ORDER BY SUM(f.sales_amount) ASC) as rank_products
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_products as p
		ON f.product_key = p.product_key
	GROUP BY p.product_name
	) as w
WHERE rank_products <= 5;



/*
=====================================================
**ADVANCED ANALYTICS**
=====================================================
*/

-- TREND ANALYSIS
--Change over time trends

--Analyzing sales performance (on yearly and monthly basis)
--option1: with YEAR(), MONTH()
SELECT
	YEAR(order_date) as order_year,
	MONTH(order_date) as order_month,
	SUM(sales_amount) as total_sales,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

--option2: with FORMAT
SELECT
	FORMAT(order_date, 'yyyy-MMM') as order_date,
	SUM(sales_amount) as total_sales,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM');

--option 3: with DATETRUNC
SELECT
	DATETRUNC(MONTH, order_date) as order_date,
	SUM(sales_amount) as total_sales,
	COUNT(DISTINCT customer_key) as total_customers,
	SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date);

------------------------------------------------
--CUMULATIVE ANALYSIS
--Aggregating the data progressively over time
--helps understand whether our business is growing/decling over time
-- examplaes: running total, moving averages
--Using WINDOW FUNCTIONS

--total sales per month and the running total of sales 
--average price and moving average of price over time

SELECT
	order_date,
	total_sales,
	avg_price,
	--window function of SUM partitioned over year means, every year the running total resets
	SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS moving_avg_price
FROM (
	SELECT
		DATETRUNC(MONTH, order_date) AS order_date,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
		FROM gold.fact_sales
		WHERE order_date IS NOT NULL
		GROUP BY DATETRUNC(MONTH, order_date)
		) AS t


-----------------------------------
--Performance Analysis
--comparing the current value to a target value
--use WINDOW FUNCTION

--Analyzing the yearly performance of products by comparing their sales to both the avergae sales of the product and the previous year sales

--using CTE 
WITH yearly_product_sales AS (     
SELECT
	YEAR(order_date) as order_year,
	p.product_name,
	SUM(f.sales_amount) as current_total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY
	YEAR(order_date),
	p.product_name
	)

SELECT
	order_year,
	product_name,
	current_total_sales,
	AVG(current_total_sales) OVER (PARTITION BY product_name) as avg_sales,
	current_total_sales - AVG(current_total_sales) OVER (PARTITION BY product_name) as diff_avg,
	CASE 
		WHEN current_total_sales - AVG(current_total_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_total_sales - AVG(current_total_sales) OVER (PARTITION BY product_name) <0 THEN 'Below Avg'
		ELSE 'Avg'
	END AS avg_change,
	LAG(current_total_sales) OVER (PARTITION BY product_name ORDER BY order_year) as prev_year_sales,
	current_total_sales - LAG(current_total_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_YoY,
	CASE 
		WHEN current_total_sales - LAG(current_total_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Higher than prev year'
		WHEN current_total_sales - LAG(current_total_sales) OVER (PARTITION BY product_name ORDER BY order_year) <0 THEN 'Lower than prev year'
		ELSE 'No Change'
	END AS YoY_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

------------------------------------------
-- Part-to-Whole Analysis / Proportional Analysis
 --contribution of categories to the total sales
WITH category_sales as (
	SELECT
		p.category,
		SUM(f.sales_amount) as total_sales
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_products as p
		ON p.product_key = f.product_key
	GROUP BY p.category
	)

SELECT
	category,
	total_sales,
	SUM(total_sales) OVER () as overall_sales,
	CONCAT(ROUND((CAST (total_sales AS FLOAT)/SUM(total_sales) OVER ())*100, 2), '%') as percentage_of_total
FROM category_sales
ORDER BY percentage_of_total DESC;

/* 
DATA SEGMENTATION
use CASE WHEN statements
*/
--Segment products into cost ranges and count how many products fall into each segment
WITH product_segments AS (
	SELECT
		product_key,
		product_name,
		cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'Above 1000'
	END as cost_range
	FROM gold.dim_products
)

SELECT
	cost_range,
	COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into three segments based on their spending behavior:
	-VIP: Customers with at least 12 months of history and spending more than $5,000.
	-Regular: Customers with at least 12 months of hisotry but spending $5,000 or less.
	-New: Customers with a lifespan less than 12 months.
	And, total number of customer by each group
*/

WITH customer_spending AS (
	SELECT 
		c.customer_key,
		SUM(f.sales_amount) as total_spending,
		MIN(order_date) as first_order,
		MAX(order_date) as last_order,
		DATEDIFF(month, MIN(order_date), MAX(order_date)) as lifespan
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_customers as c
		ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)


SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM( 
	SELECT 
		customer_key,
		total_spending,
		lifespan,
	CASE WHEN total_spending >5000 AND lifespan >= 12 THEN 'VIP'
		 WHEN total_spending <= 5000 AND lifespan> 12 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment
	FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;

