-- ============================================================
--   Muhammad Zubair Jawed 3rd Assignment
--   ASSIGNMENT 03 — GROUP BY, HAVING & SUBQUERIES
--   Database  : BikeStores
--   Topics    : GROUP BY · Aggregate Functions · HAVING
--               Subqueries · JOINs with GROUP BY
-- ============================================================


-- ============================================================
--  SECTION A — GROUP BY & AGGREGATE FUNCTIONS
-- ============================================================

-- Q1.
-- Count total orders placed by each customer.
-- Show customer_id and order_count.
-- Sort by highest orders first.

SELECT 
    o.customer_id,
    COUNT(o.order_id) AS order_count
FROM sales.orders o
GROUP BY o.customer_id
ORDER BY order_count DESC;


-- Q2.
-- Find total orders for every store.
-- Show store_id and total_orders.

SELECT 
    o.store_id,
    COUNT(o.order_id) AS total_orders
FROM sales.orders o
GROUP BY o.store_id;


-- Q3.
-- Calculate revenue generated from each order.
-- Formula: quantity * list_price * (1 - discount)

SELECT 
    order_id,
    SUM(quantity * list_price * (1 - discount)) AS net_revenue
FROM sales.order_items
GROUP BY order_id
ORDER BY net_revenue DESC;


-- Q4.
-- Find average product price in every category.

SELECT 
    category_id,
    ROUND(AVG(list_price), 2) AS avg_price
FROM production.products
GROUP BY category_id;


-- Q5.
-- Count total orders placed each year.

SELECT 
    YEAR(order_date) AS order_year,
    COUNT(order_id) AS total_orders
FROM sales.orders
GROUP BY YEAR(order_date)
ORDER BY order_year ASC;


-- ============================================================
--  SECTION B — HAVING CLAUSE
-- ============================================================

-- Q6.
-- Find customers having more than 5 orders.

SELECT 
    customer_id,
    COUNT(order_id) AS order_count
FROM sales.orders
GROUP BY customer_id
HAVING COUNT(order_id) > 5;


-- Q7
-- Find categories where average product price exceeds 1500.

SELECT 
    category_id,
    AVG(list_price) AS avg_price
FROM production.products
GROUP BY category_id
HAVING AVG(list_price) > 1500;


-- Q8.
-- Find customers who placed at least 2 orders in 2017.

SELECT 
    customer_id,
    YEAR(order_date) AS order_year,
    COUNT(order_id) AS order_count
FROM sales.orders
WHERE YEAR(order_date) = 2017
GROUP BY customer_id, YEAR(order_date)
HAVING COUNT(order_id) >= 2;


-- ============================================================
--  SECTION C — SUBQUERIES
-- ============================================================

-- Q9.
-- Display orders placed by customers from Houston.

SELECT *
FROM sales.orders
WHERE customer_id IN
(
    SELECT customer_id
    FROM sales.customers
    WHERE city = 'Houston'
);


-- Q10.
-- Find products having price greater than overall average price.

SELECT 
    product_name,
    list_price
FROM production.products
WHERE list_price >
(
    SELECT AVG(list_price)
    FROM production.products
);


-- Q11.
-- Find products belonging to Mountain Bikes or Road Bikes.

SELECT 
    product_name,
    list_price
FROM production.products
WHERE category_id IN
(
    SELECT category_id
    FROM production.categories
    WHERE category_name IN ('Mountain Bikes', 'Road Bikes')
);


-- Q12.
-- Find customers who never placed any order.

SELECT 
    customer_id,
    first_name,
    last_name
FROM sales.customers
WHERE customer_id NOT IN
(
    SELECT customer_id
    FROM sales.orders
);


-- ============================================================
--  SECTION D — JOINs WITH GROUP BY
-- ============================================================

-- Q13.
-- Count total orders from each city.

SELECT 
    c.city,
    COUNT(o.order_id) AS total_orders
FROM sales.customers c
INNER JOIN sales.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY total_orders DESC;


-- Q14.
-- Count how many orders each staff member handled.

SELECT 
    s.first_name + ' ' + s.last_name AS staff_name,
    COUNT(o.order_id) AS order_count
FROM sales.staffs s
INNER JOIN sales.orders o
    ON s.staff_id = o.staff_id
GROUP BY s.first_name, s.last_name
ORDER BY order_count DESC;


-- Q15. BONUS
-- Find customers who spent more than 10000 in total.

SELECT 
    c.first_name + ' ' + c.last_name AS customer_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
FROM sales.customers c
INNER JOIN sales.orders o
    ON c.customer_id = o.customer_id
INNER JOIN sales.order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.first_name, c.last_name
HAVING SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 10000
ORDER BY total_spent DESC;


