-----------------------------
-- 1️⃣ Table: Customers
-----------------------------
CREATE TABLE dim_customers (
    customer_key INT PRIMARY KEY,
    customer_id VARCHAR(10),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    gender VARCHAR(10),
    marital_status VARCHAR(20),
    birthdate DATE,
    create_date DATE
);

DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO dim_customers
    (customer_key, customer_id, first_name, last_name, country, city, gender, marital_status, birthdate, create_date)
    VALUES
    (
        @i,
        CONCAT('CUST', RIGHT('0000'+CAST(@i AS VARCHAR),4)),
        CONCAT('First', @i),
        CONCAT('Last', @i),
        CASE WHEN @i % 5 = 0 THEN 'USA'
             WHEN @i % 5 = 1 THEN 'India'
             WHEN @i % 5 = 2 THEN 'UK'
             WHEN @i % 5 = 3 THEN 'Canada'
             ELSE 'Australia' END,
        CONCAT('City', @i % 100),
        CASE WHEN @i % 2 = 0 THEN 'Male' ELSE 'Female' END,
        CASE WHEN @i % 3 = 0 THEN 'Married' ELSE 'Single' END,
        DATEADD(DAY, -1 * (20*365 + @i % 365), GETDATE()),
        DATEADD(DAY, -1 * (@i % 1000), GETDATE())
    );
    SET @i = @i + 1;
END

-----------------------------
-- 2️⃣ Table: Products
-----------------------------
CREATE TABLE dim_products (
    product_key INT PRIMARY KEY,
    product_id VARCHAR(10),
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT
);

SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO dim_products
    (product_key, product_id, product_name, category, price, stock_quantity)
    VALUES
    (
        @i,
        CONCAT('PROD', RIGHT('0000'+CAST(@i AS VARCHAR),4)),
        CONCAT('Product', @i),
        CASE WHEN @i % 4 = 0 THEN 'Electronics'
             WHEN @i % 4 = 1 THEN 'Furniture'
             WHEN @i % 4 = 2 THEN 'Clothing'
             ELSE 'Sports' END,
        ROUND(50 + (RAND()*9950),2), -- price between 50 and 10000
        10 + (@i % 100) -- stock between 10 and 109
    );
    SET @i = @i + 1;
END

-----------------------------
-- 3️⃣ Table: Orders
-----------------------------
CREATE TABLE fact_orders (
    order_key INT PRIMARY KEY,
    order_id VARCHAR(10),
    customer_key INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    payment_method VARCHAR(20)
);

SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO fact_orders
    (order_key, order_id, customer_key, order_date, total_amount, payment_method)
    VALUES
    (
        @i,
        CONCAT('ORD', RIGHT('0000'+CAST(@i AS VARCHAR),4)),
        1 + (@i % 1000), -- random customer
        DATEADD(DAY, -1 * (@i % 365), GETDATE()),
        ROUND(100 + (RAND()*9900),2), -- total amount between 100 and 10000
        CASE WHEN @i % 3 = 0 THEN 'Credit Card'
             WHEN @i % 3 = 1 THEN 'Net Banking'
             ELSE 'UPI' END
    );
    SET @i = @i + 1;
END

-----------------------------
-- 4️⃣ Table: Order Details
-----------------------------
CREATE TABLE fact_order_details (
    order_detail_key INT PRIMARY KEY,
    order_key INT,
    product_key INT,
    quantity INT,
    price DECIMAL(10,2)
);

SET @i = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO fact_order_details
    (order_detail_key, order_key, product_key, quantity, price)
    VALUES
    (
        @i,
        1 + (@i % 1000), -- random order
        1 + (@i % 1000), -- random product
        1 + (@i % 5), -- quantity 1-5
        ROUND(50 + (RAND()*9950),2)
    );
    SET @i = @i + 1;
END

select * from dim_customers;
select * from dim_products
select * from fact_orders 
select * from fact_order_details

SELECT TOP 10 * FROM dim_customers
select top 10 * from dim_products
select top 10 * from fact_orders 
select top 10 * from fact_order_details

SELECT COUNT(*) AS Total_Customers FROM dim_customers;
SELECT COUNT(*) AS Total_Products FROM dim_products;
SELECT COUNT(*) AS Total_Orders FROM fact_orders;
SELECT COUNT(*) AS Total_OrderDetails FROM fact_order_details;


-- Customers table
SELECT COUNT(*) AS Null_FirstName FROM dim_customers WHERE first_name IS NULL;
SELECT COUNT(*) AS Null_Birthdate FROM dim_customers WHERE birthdate IS NULL;

-- Products table
SELECT COUNT(*) AS Null_ProductName FROM dim_products WHERE product_name IS NULL;

-- Orders table
SELECT COUNT(*) AS Null_TotalAmount FROM fact_orders WHERE total_amount IS NULL;

-- OrderDetails table
SELECT COUNT(*) AS Null_Quantity FROM fact_order_details WHERE quantity IS NULL;

-- Example: Replace null marital_status with 'Unknown'
UPDATE dim_customers
SET marital_status = 'Unknown'
WHERE marital_status IS NULL;

-- Example: Replace null product price with 0
UPDATE dim_products
SET price = 0
WHERE price IS NULL;

-- Check min/max values for numeric fields
SELECT MIN(price), MAX(price) FROM dim_products;
SELECT MIN(total_amount), MAX(total_amount) FROM fact_orders;
SELECT MIN(quantity), MAX(quantity) FROM fact_order_details;

ALTER TABLE dim_customers
ADD age AS DATEDIFF(YEAR, birthdate, GETDATE());

ALTER TABLE fact_orders
ADD order_year AS YEAR(order_date),
    order_month AS MONTH(order_date);

    ALTER TABLE fact_order_details
ADD line_total AS quantity * price;

SELECT order_year, order_month, SUM(total_amount) AS total_sales
FROM fact_orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

SELECT c.customer_id, c.first_name, c.last_name, SUM(o.total_amount) AS total_revenue
FROM fact_orders o
JOIN dim_customers c ON o.customer_key = c.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

SELECT c.country, SUM(o.total_amount) AS revenue
FROM fact_orders o
JOIN dim_customers c ON o.customer_key = c.customer_key
GROUP BY c.country
ORDER BY revenue DESC;


SELECT payment_method, COUNT(order_id) AS total_orders, SUM(total_amount) AS revenue
FROM fact_orders
GROUP BY payment_method
ORDER BY revenue DESC;


-- View: Monthly Sales
CREATE VIEW vw_monthly_sales AS
SELECT order_year, order_month, SUM(total_amount) AS total_sales
FROM fact_orders
GROUP BY order_year, order_month;

-- View: Top Customers
CREATE VIEW vw_top_customers AS
SELECT c.customer_id, c.first_name, c.last_name, SUM(o.total_amount) AS total_revenue
FROM fact_orders o
JOIN dim_customers c ON o.customer_key = c.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name;


