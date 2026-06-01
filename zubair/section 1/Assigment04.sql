-- ============================================================
--   ASSIGNMENT 04 — SET OPERATORS, CTEs, CONSTRAINTS & CASES
--   Database  : BikeStores
--   Author    : Zubair
--   Topics    : UNION, INTERSECT, EXCEPT | CTEs | Constraints | CASE
-- ============================================================


-- ============================================================
--  SECTION A — SET OPERATORS
-- ============================================================

-- Q1. Unified contact list of staff and customers (no duplicates)
SELECT 
    first_name + ' ' + last_name AS full_name,
    email
FROM sales.staffs
UNION
SELECT 
    first_name + ' ' + last_name AS full_name,
    email
FROM sales.customers;


-- Q2. States that have both stores and customers
SELECT state 
FROM sales.customers
INTERSECT
SELECT state 
FROM sales.stores;


-- Q3. Stores that received zero orders in 2018
SELECT store_id 
FROM sales.stores
EXCEPT
SELECT store_id
FROM sales.orders
WHERE YEAR(order_date) = 2018;


-- ============================================================
--  SECTION B — CTEs
-- ============================================================

-- Q4. Products more expensive than their category average
WITH CategoryAvg AS (
    SELECT 
        category_id,
        AVG(list_price) AS avg_price
    FROM production.products
    GROUP BY category_id
)
SELECT 
    p.category_id,
    p.product_name,
    p.list_price,
    ca.avg_price AS category_avg_price
FROM production.products p
JOIN CategoryAvg ca ON p.category_id = ca.category_id
WHERE p.list_price > ca.avg_price
ORDER BY p.category_id, p.list_price DESC;


-- Q5. Staff members performing above average in order count
WITH StaffOrders AS (
    SELECT 
        staff_id,
        COUNT(*) AS order_count
    FROM sales.orders
    GROUP BY staff_id
),
AvgOrders AS (
    SELECT AVG(CAST(order_count AS FLOAT)) AS avg_count
    FROM StaffOrders
)
SELECT 
    so.staff_id,
    so.order_count
FROM StaffOrders so
CROSS JOIN AvgOrders ao
WHERE so.order_count > ao.avg_count
ORDER BY so.order_count DESC;


-- Q6. Store performance — years with revenue > $1M
WITH StoreRevenue AS (
    SELECT 
        o.store_id,
        YEAR(o.order_date) AS order_year,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.store_id, YEAR(o.order_date)
)
SELECT 
    store_id,
    order_year,
    ROUND(total_revenue, 2) AS total_revenue
FROM StoreRevenue
WHERE total_revenue > 1000000
ORDER BY store_id, order_year;


-- ============================================================
--  SECTION C — CONSTRAINTS (DDL)
-- ============================================================

-- Q7. Loyalty Cards Table with proper constraints
CREATE TABLE sales.loyalty_cards (
    card_number   INT PRIMARY KEY,
    customer_id   INT NOT NULL,
    points        INT NOT NULL CHECK (points >= 0),
    tier          VARCHAR(10) NOT NULL CHECK (tier IN ('Bronze', 'Silver', 'Gold')),
    join_date     DATE NOT NULL,

    FOREIGN KEY (customer_id) 
        REFERENCES sales.customers(customer_id) 
        ON DELETE CASCADE
);


-- Q8. Prevent illogical shipped_date (earlier than order_date)
ALTER TABLE test_orders
ADD CONSTRAINT chk_shipped_after_order
    CHECK (shipped_date IS NULL OR shipped_date >= order_date);


-- ============================================================
--  SECTION D — CASE EXPRESSIONS
-- ============================================================

-- Q9. Shipping speed categorization
SELECT 
    order_id,
    order_date,
    shipped_date,
    CASE
        WHEN shipped_date IS NULL THEN 'Pending'
        WHEN DATEDIFF(DAY, order_date, shipped_date) <= 2 THEN 'Fast'
        WHEN DATEDIFF(DAY, order_date, shipped_date) BETWEEN 3 AND 5 THEN 'Normal'
        ELSE 'Delayed'
    END AS shipping_speed
FROM sales.orders
ORDER BY order_id;


-- Q10. Stock level labeling
SELECT 
    store_id,
    product_id,
    quantity,
    CASE
        WHEN quantity = 0 THEN 'Out of Stock'
        WHEN quantity BETWEEN 1 AND 10 THEN 'Low Stock'
        WHEN quantity BETWEEN 11 AND 50 THEN 'Sufficient'
        ELSE 'Well Stocked'
    END AS stock_status
FROM production.stocks
ORDER BY store_id, quantity;


-- ============================================================
--  END OF ASSIGNMENT 04
-- ============================================================