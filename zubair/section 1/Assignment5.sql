-- ============================================================
--   ASSIGNMENT 05 — INDEXES, VIEWS & WINDOW FUNCTIONS
--   Student Name : Zubair Jawed
--   Program      : BS Computer Science / Software Engineering
--   Database     : BikeStores
--   Focus        : Indexes | Views | Window Functions
--                  ROW_NUMBER / RANK / DENSE_RANK
--                  LAG / LEAD / COALESCE
-- ============================================================


-- ============================================================
--  SECTION A — INDEXES (Performance Optimization)
-- ============================================================

-- Q1: Improve product search by brand (marketing queries)
CREATE INDEX idx_products_brand_id
ON production.products (brand_id);

-- Test Query:
SELECT product_id, product_name, list_price
FROM production.products
WHERE brand_id = 3;


-- Q2: Speed up order filtering by date range (finance reports)
CREATE INDEX idx_orders_order_date
ON sales.orders (order_date);

-- Test Query:
SELECT order_id, customer_id, order_date
FROM sales.orders
WHERE order_date BETWEEN '2018-01-01' AND '2018-06-30';



-- ============================================================
--  SECTION B — VIEWS (Reusable Business Logic)
-- ============================================================

-- ============================================================
-- Q3: Active Orders View
-- ============================================================

IF OBJECT_ID('sales.vw_active_orders', 'V') IS NOT NULL
    DROP VIEW sales.vw_active_orders;
GO

CREATE VIEW sales.vw_active_orders AS
SELECT
    o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.phone,
    c.email,
    o.order_date,
    CASE o.order_status
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Processing'
        ELSE 'Other'
    END AS order_status
FROM sales.orders o
JOIN sales.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status IN (1, 2);
GO


-- View usage
SELECT *
FROM sales.vw_active_orders
ORDER BY order_date DESC;
GO



-- ============================================================
-- Q4: Store Stock View
-- ============================================================

IF OBJECT_ID('production.vw_store_stock', 'V') IS NOT NULL
    DROP VIEW production.vw_store_stock;
GO

CREATE VIEW production.vw_store_stock AS
SELECT
    st.store_name,
    p.product_name,
    b.brand_name,
    c.category_name,
    sk.quantity
FROM production.stocks sk
JOIN sales.stores st
    ON st.store_id = sk.store_id
JOIN production.products p
    ON p.product_id = sk.product_id
JOIN production.brands b
    ON b.brand_id = p.brand_id
JOIN production.categories c
    ON c.category_id = p.category_id;
GO
-- Low stock check
SELECT *
FROM production.vw_store_stock
WHERE quantity < 3
ORDER BY quantity ASC;



-- ============================================================
--  SECTION C — WINDOW FUNCTIONS (Ranking & Duplicate Handling)
-- ============================================================

-- Q5: Top 2 best-selling products per store
WITH store_sales AS (
    SELECT
        o.store_id,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        RANK() OVER (
            PARTITION BY o.store_id
            ORDER BY SUM(oi.quantity) DESC
        ) AS sales_rank
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.store_id, oi.product_id
)
SELECT *
FROM store_sales
WHERE sales_rank <= 2
ORDER BY store_id, sales_rank;


-- Q6: 2nd most expensive product per category
WITH price_ranked AS (
    SELECT
        category_id,
        product_name,
        list_price,
        DENSE_RANK() OVER (
            PARTITION BY category_id
            ORDER BY list_price DESC
        ) AS price_rank
    FROM production.products
)
SELECT *
FROM price_ranked
WHERE price_rank = 2
ORDER BY category_id;


-- Q7: Detect duplicate customers (based on name + phone)
WITH duplicate_check AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, phone
            ORDER BY customer_id
        ) AS rn
    FROM test_customers
)
SELECT
    customer_id,
    first_name,
    last_name,
    phone,
    city
FROM duplicate_check
WHERE rn > 1
ORDER BY last_name, first_name;



-- ============================================================
--  SECTION D — LAG / LEAD / COALESCE (Time Series & Data Cleaning)
-- ============================================================

-- Q8: Monthly revenue trend with comparison (2017)
WITH monthly_sales AS (
    SELECT
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS net_sales
    FROM sales.orders o
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    WHERE YEAR(o.order_date) = 2017
    GROUP BY MONTH(o.order_date)
)
SELECT
    month,
    ROUND(net_sales, 2) AS net_sales,
    ROUND(LAG(net_sales) OVER (ORDER BY month), 2) AS previous_month_sales,
    ROUND(net_sales - LAG(net_sales) OVER (ORDER BY month), 2) AS month_difference
FROM monthly_sales
ORDER BY month;


-- Q9: Next lower priced product in same category
SELECT
    category_id,
    product_name,
    list_price,
    LEAD(list_price) OVER (
        PARTITION BY category_id
        ORDER BY list_price DESC
    ) AS next_lower_price
FROM production.products
ORDER BY category_id, list_price DESC;


-- Q10: Clean customer contact info using COALESCE
SELECT
    first_name + ' ' + last_name AS full_name,
    COALESCE(phone, email, 'No Contact Info') AS contact_number,
    email
FROM sales.customers
ORDER BY last_name, first_name;



-- ============================================================
--  END OF ASSIGNMENT 05
-- ============================================================