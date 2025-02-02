---------------------------   Ecommerce Target Sales   -------------------------
#Drop Database if exists target_sales ;
Create Database target_sales;
Use target_sales;

--- Create Tables to import Data from CSV  Files

#drop table if exists customers;
CREATE TABLE customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INT,
    customer_city TEXT,
    customer_state TEXT
);

#drop table if exists geolocation;
CREATE TABLE geolocation 
( 
    geolocation_zip_code_prefix INT,
    geolocation_lat DOUBLE,
    geolocation_lng DOUBLE,
    geolocation_city TEXT,
    geolocation_state TEXT
);

#drop table if exists order_items;
CREATE TABLE order_items (
    order_id TEXT,
    order_item_id INT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date datetime,
    price DOUBLE,
    freight_value DOUBLE
);

#drop table if exists orders;
CREATE TABLE orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp datetime null,
    order_approved_at datetime null,
    order_delivered_carrier_date datetime null,
    order_delivered_customer_date datetime null,
    order_estimated_delivery_date datetime null
);

#drop table if exists payments;
CREATE TABLE payments (
    order_id TEXT,
    payment_sequential INT,
    payment_type TEXT,
    payment_installments INT,
    payment_value DOUBLE
);

drop table if exists products;
CREATE TABLE products (
    product_id TEXT,
    product_category TEXT NULL,
    product_name_length int NULL,
    product_description_length int NULL,
    product_photos_qty int NULL,
    product_weight_g int NULL,
    product_length_cm int NULL,
    product_height_cm int NULL,
    product_width_cm int NULL
);

#drop table if exists sellers;
CREATE TABLE sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT NULL,
    seller_city TEXT NULL,
    seller_state TEXT NULL
);

--- import Data from CSV files

show variables like 'secure-file-priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

--- Check that Data is imported successfully

SELECT * FROM customers;
SELECT * FROM geolocation;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM payments;
SELECT * FROM products;
SELECT * FROM sellers;

-------------------------------------------------------------------------

--- Task-1.	Retrieve all customer information about customers.

SELECT 
    *
FROM
    customers;
    
--- Task-2 What is the total revenue genereted?

SELECT 
    ROUND(SUM(payment_value), 2) AS total_Revenue_in_$
FROM
    payments;
    
--- Task -3 calculate Total orders placed.

SELECT 
    COUNT(order_id) AS Total_orders
FROM
    orders;

--- Task-4	Calculate the average order value across all orders.

SELECT 
    ROUND(AVG(payment_value), 2) AS average_order_value
FROM
    payments p
        JOIN
    orders o ON p.order_id = o.order_id;
    
--- Task-5	List the number of orders placed from Top 5 states.

SELECT 
    c.customer_state, COUNT(o.order_id) AS no_of_orders
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY customer_state
ORDER BY no_of_orders DESC
limit 5;

--- Task-6	Identify the sellers located in a sao paulo city.

SELECT 
    seller_id, seller_city
FROM
    sellers
WHERE
    seller_city = 'sao paulo';
    
    
--- Task-7	Count the total number of unique products listed.

SELECT DISTINCT
    COUNT(product_id) AS T_no_of_unique_products
FROM
    products;
    
--- Task-8	Determine Top 5 products by Revenue.
    
SELECT 
    p.product_id,
    ROUND(SUM(py.payment_value), 2) AS t_revenue_by_product
FROM
    payments py
        JOIN
    order_items oi ON py.order_id = oi.order_id
        JOIN
    products p ON p.product_id = oi.product_id
GROUP BY product_id
ORDER BY t_revenue_by_product DESC LIMIT 5;

--- Task-9.	Determine the average delivery time for orders 

SELECT 
    ROUND(AVG(TIMESTAMPDIFF(DAY,
                order_purchase_timestamp,
                order_delivered_customer_date)),
            2) AS avg_delivery_time_Days
FROM
    orders;

--- Task-10	Analyze the top 5 customers based orders report

SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) AS no_of_repeat_orders
FROM
    orders o
        JOIN
    customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY no_of_repeat_orders DESC
limit 5;

--- Task-11 How many unique customers have made purchases in each top 5 state?

CREATE INDEX idx_customer_zip_code_prefix ON customers(customer_zip_code_prefix);
CREATE INDEX idx_geolocation_zip_code_prefix ON geolocation(geolocation_zip_code_prefix);
SELECT 
    geolocation_state,
    COUNT(DISTINCT c.customer_id) AS num_unique_customers
FROM
    customers c
        JOIN
    geolocation g ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
GROUP BY geolocation_state
ORDER BY num_unique_customers DESC LIMIT 5 ;

--- Task-12 Which product categories have the highest average order values (including both product price and freight cost)?

SELECT 
    p.product_category,
    round(AVG(oi.price + oi.freight_value),2) AS avg_order_value
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
        JOIN
    orders o ON oi.order_id = o.order_id
WHERE
    o.order_status = 'delivered'
GROUP BY p.product_category
ORDER BY avg_order_value DESC;

--- Task-13 Calculate RFM Metrics

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATEDIFF(NOW(), MAX(order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'  -- Consider only delivered orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    CASE
        WHEN recency >= 0 AND recency <= 30 THEN 'Active'
        WHEN recency > 30 AND recency <= 90 THEN 'Inactive'
        ELSE 'Lost'
    END AS customer_segment
FROM customer_rfm
ORDER BY recency DESC, frequency DESC, monetary DESC;


--- Task-14 Create Function to calculate Average Processing Time

drop function if exists avg_processing_time;
DELIMITER $$
CREATE FUNCTION avg_processing_time()
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE avg_time DECIMAL(10, 2);

    SELECT AVG(TIMESTAMPDIFF(DAY, order_approved_at, order_delivered_customer_date))
    INTO avg_time
    FROM orders
    WHERE order_status = 'delivered'
      AND order_approved_at IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL;

    RETURN avg_time;
END$$

DELIMITER ;

select  avg_processing_time();


			----------------------------- THANK YOU ---------------------------



    

