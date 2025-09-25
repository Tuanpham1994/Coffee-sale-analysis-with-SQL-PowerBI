CREATE DATABASE coffee_shop_sales_db;
USE coffee_shop_sales_db;

CREATE TABLE coffee_sale (
transaction_id INT,
transaction_date date,
transaction_time TIME,
transaction_qty INT,
store_id INT,
store_location VARCHAR(1000),
product_id INT,
unit_price DOUBLE,
product_category VARCHAR(1000),
product_type VARCHAR(1000),
product_detail VARCHAR(1000));

SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE 'Coffee Shop Sales.csv' INTO TABLE coffee_sale
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

USE coffee_shop_sales_db;

SELECT * FROM coffee_sale;
DESC coffee_sale;

ALTER TABLE coffee_sale
MODIFY COLUMN transaction_date DATE;

ALTER TABLE coffee_sale
CHANGE COLUMN transaction_id transaction_id INT;

ALTER TABLE coffee_sale
MODIFY COLUMN transaction_time TIME;

#I. KPI Requirement
#1. Total sale analysis
#Calculate the total sales for each respective month
SELECT MONTH(transaction_date) AS Month, 
	YEAR(transaction_date) AS Year,
    ROUND(SUM(unit_price * transaction_qty),1) AS Total_sale
FROM coffee_sale
GROUP BY YEAR(transaction_date), MONTH(transaction_date);

#Determine the month-on-month increase or decrease in sales.
SELECT MONTH(transaction_date) AS MONTH,
	SUM(unit_price * transaction_qty) AS Total_sale,
    SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty),1) OVER (ORDER BY MONTH(transaction_date)) AS Monthly_difference
FROM coffee_Sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);


#Calculate the difference in sales between the selected month and the previous month.
SELECT MONTH(transaction_date) AS MONTH,
	ROUND(SUM(unit_price * transaction_qty),1) AS Total_sale,
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty),1) -- monthly difference
    OVER (ORDER BY MONTH(transaction_date)))/ LAG(SUM(unit_price*transaction_qty),1)-- division by previous month sale
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS MOM_percentage -- percentage
FROM coffee_Sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

#2. Total Orders Analysis:
#Calculate the total number of orders for each respective month.
SELECT COUNT(transaction_id) AS Number_order, MONTH(transaction_date) AS Month
FROM coffee_sale
GROUP BY MONTH (transaction_date)
ORDER BY MONTH (transaction_date);

#Determine the month-on-month increase or decrease in the number of orders.
SELECT MONTH(transaction_date) AS Month,
		COUNT(transaction_id) - LAG(COUNT(transaction_id),1) OVER (ORDER BY MONTH(transaction_date)) AS Monthly_difference
FROM coffee_sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

#Determine the month-on-month increase or decrease in the number of orders.
SELECT MONTH(transaction_date) AS Month,
		(COUNT(transaction_id) - LAG(COUNT(transaction_id),1) 
        OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id),1)
        OVER (ORDER BY MONTH(transaction_date)) * 100 AS Monthly_diff_percentage
FROM coffee_sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

#3.Total Quantity Sold Analysis:
#Calculate the total quantity sold for each respective month.

SELECT product_category, product_type, MONTH(transaction_date) AS Month,
		SUM(transaction_qty) AS Total_qty
FROM coffee_sale
GROUP BY product_category, product_type, MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

SELECT MONTH(transaction_date) AS Month,
		SUM(transaction_qty) AS Total_qty
FROM coffee_sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

#Determine the month-on-month increase or decrease in the total quantity sold.
SELECT MONTH(transaction_date) AS Month,
		SUM(transaction_qty) - LAG(COUNT(transaction_qty),1) OVER (ORDER BY MONTH(transaction_date)) AS Monthly_difference
FROM coffee_sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

#Calculate the difference in the total quantity sold between the selected month and the previous month.
SELECT MONTH(transaction_date) AS Month,
		(SUM(transaction_qty) - LAG(SUM(transaction_qty),1) 
        OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty),1)
        OVER (ORDER BY MONTH(transaction_date)) * 100 AS Monthly_diff_percentage
FROM coffee_sale
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

#II. Chart requirements
#1. Calendar Heat Map:
#Implement a calendar heat map that dynamically adjusts based on the selected month from a slicer.
#Each day on the calendar will be color-coded to represent sales volume, with darker shades indicating higher sales.
#Implement tooltips to display detailed metrics (Sales, Orders, Quantity) when hovering over a specific day.
SELECT transaction_date, 
		COUNT(transaction_id) AS Total_order,
        ROUND(SUM(unit_price*transaction_qty)/1000,1) AS Total_sale, -- in thousands
        SUM(transaction_qty) AS Total_qty
FROM coffee_sale
GROUP BY transaction_date
ORDER BY transaction_date;
        
#2. Sales Analysis by Weekdays and Weekends:
#Segment sales data into weekdays and weekends to analyze performance variations.
#Provide insights into whether sales patterns differ significantly between weekdays and weekends.
SELECT CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'weekends'
		ELSE 'weekdays' END AS Day_type,
        ROUND(SUM(unit_price * transaction_qty)/1000,1) AS Total_sale, -- in thousands
        MONTH(transaction_date) AS Month
FROM coffee_sale
GROUP BY MONTH(transaction_date),
		CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'weekends'
		ELSE 'weekdays' END;
              
#3. Sales Analysis by Store Location:
#Visualize sales data by different store locations.
#Include month-over-month (MoM) difference metrics based on the selected month in the slicer.
#Highlight MoM sales increase or decrease for each store location to identify trends.

SELECT store_location, MONTH(transaction_date) AS Month,
		ROUND(SUM(unit_price*transaction_qty)/1000,1) AS Total_sale,
		(SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty),1) -- monthly difference
    OVER (ORDER BY MONTH(transaction_date)))/ LAG(SUM(unit_price*transaction_qty),1)-- division by previous month sale
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS MOM_percentage -- percentage
FROM coffee_sale
GROUP BY store_location, MONTH(transaction_date)
ORDER BY SUM(unit_price * transaction_qty) DESC, store_location, MONTH(transaction_date);

#4. Daily Sales Analysis with Average Line:
#Display daily sales for the selected month with a line chart.
#Incorporate an average line on the chart to represent the average daily sales.
#Highlight bars exceeding or falling below the average sales to identify exceptional sales days.
SELECT transaction_date, MONTH(transaction_date) AS Month,
	ROUND(SUM(unit_price*transaction_qty)/1000,1) AS Daily_sale -- in thousands
FROM coffee_sale
GROUP BY transaction_date, MONTH(transaction_date)
ORDER BY MONTH(transaction_date), transaction_date;

SELECT 
    txn_date,
    Month,
    daily_sales,
    ROUND(AVG(daily_sales) OVER (PARTITION BY Month), 1) AS Average_sale,
    CASE 
        WHEN daily_sales < ROUND(AVG(daily_sales) OVER (PARTITION BY Month), 1) 
            THEN 'Below Average'
        WHEN daily_sales > ROUND(AVG(daily_sales) OVER (PARTITION BY Month), 1) 
            THEN 'Above Average'
        ELSE 'Equal to Average'
    END AS sale_status
FROM (
    SELECT 
        DATE(transaction_date) AS txn_date,
        MONTH(transaction_date) AS Month,
        ROUND(SUM(unit_price * transaction_qty) / 1000, 1) AS daily_sales
    FROM coffee_sale
    GROUP BY DATE(transaction_date), MONTH(transaction_date)
) AS daily
ORDER BY Month, txn_date;

#5. Sales Analysis by Product Category:
#Analyze sales performance across different product categories.
#Provide insights into which product categories contribute the most to overall sales.

SELECT ROUND(SUM(unit_price*transaction_qty)/1000,1) AS Total_sale,
		product_category
FROM coffee_sale
GROUP BY product_category
ORDER BY ROUND(SUM(unit_price*transaction_qty)/1000,1) DESC;

#6. Top 10 Products by Sales:
#Identify and display the top 10 products based on sales volume.
#Allow users to quickly visualize the best-performing products in terms of sales.
#Use PowerBI Filter for each month
SELECT ROUND(SUM(unit_price*transaction_qty)/1000,1) AS Total_sale, product_type, MONTH(transaction_date) AS Month
FROM coffee_sale
GROUP BY product_type, MONTH(transaction_date)
ORDER BY ROUND(SUM(unit_price*transaction_qty)/1000,1) DESC;

#7. Sales Analysis by Days and Hours:
#Utilize a heat map to visualize sales patterns by days and hours.
#Implement tooltips to display detailed metrics (Sales, Orders, Quantity) when hovering over a specific day-hour.

SELECT ROUND(SUM(unit_price * transaction_qty)/1000,1) AS Total_sale,
		SUM(transaction_qty) AS Total_qty, DAYNAME(transaction_date) AS Day, transaction_date,
		 HOUR(transaction_time) AS Hours, MONTH(transaction_date) AS Month,
         COUNT(transaction_id) AS Total_order
FROM coffee_sale
GROUP BY HOUR(transaction_time), DAYNAME(transaction_date),transaction_date, MONTH(transaction_date)
ORDER BY HOUR(transaction_time);
        