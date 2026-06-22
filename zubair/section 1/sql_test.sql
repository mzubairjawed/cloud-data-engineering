-- Q1. List top 5 customers by total order amount.
-- Retrieve the top 5 customers who have spent the most across all sales orders. Show CustomerID, CustomerName, and TotalSpent.

SELECT TOP 5
    c.CustomerID,
    c.Name AS CustomerName,
    SUM(so.TotalAmount) AS TotalSpent
FROM dbo.Customer c
JOIN dbo.SalesOrder so
    ON c.CustomerID = so.CustomerID
GROUP BY c.CustomerID, c.Name
ORDER BY TotalSpent DESC;

-- Q2. Find the number of products supplied by each supplier.
-- Display SupplierID, SupplierName, and ProductCount. Only include suppliers that have more than 10 products.
 
SELECT
    s.SupplierID,
    s.Name AS SupplierName,
    COUNT(DISTINCT pod.ProductID) AS ProductCount
FROM dbo.Supplier s
JOIN dbo.PurchaseOrder po
    ON s.SupplierID = po.SupplierID
JOIN dbo.PurchaseOrderDetail pod
    ON po.OrderID = pod.OrderID
GROUP BY s.SupplierID, s.Name
HAVING COUNT(DISTINCT pod.ProductID) > 10;

--Q3. Identify products that have been ordered but never returned.
-- Show ProductID, ProductName, and total order quantity.


SELECT
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.Quantity) AS TotalOrderQuantity
FROM dbo.Product p
JOIN dbo.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
LEFT JOIN dbo.ReturnDetail rd
    ON p.ProductID = rd.ProductID
WHERE rd.ProductID IS NULL
GROUP BY p.ProductID, p.Name;

-- Q4. For each category, find the most expensive product.
-- Display CategoryID, CategoryName, ProductName, and Price. Use a subquery to get the max price per category.
SELECT
    c.CategoryID,
    c.Name AS CategoryName,
    p.Name AS ProductName,
    p.Price
FROM dbo.Product p
JOIN dbo.Category c
    ON p.CategoryID = c.CategoryID
WHERE p.Price =
(
    SELECT MAX(p2.Price)
    FROM dbo.Product p2
    WHERE p2.CategoryID = p.CategoryID
);

--Q5. List all sales orders with customer name, product name, category, and supplier.
-- For each sales order, display:
-- OrderID, CustomerName, ProductName, CategoryName, SupplierName, and Quantity.

SELECT
    so.OrderID,
    c.Name AS CustomerName,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    s.Name AS SupplierName,
    sod.Quantity
FROM dbo.SalesOrder so
JOIN dbo.Customer c
    ON so.CustomerID = c.CustomerID
JOIN dbo.SalesOrderDetail sod
    ON so.OrderID = sod.OrderID
JOIN dbo.Product p
    ON sod.ProductID = p.ProductID
JOIN dbo.Category cat
    ON p.CategoryID = cat.CategoryID
JOIN dbo.PurchaseOrderDetail pod
    ON p.ProductID = pod.ProductID
JOIN dbo.PurchaseOrder po
    ON pod.OrderID = po.OrderID
JOIN dbo.Supplier s
    ON po.SupplierID = s.SupplierID;

-- Q6. Find all shipments with details of warehouse, manager, and products shipped.
-- Display:
--ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.

SELECT
    sh.ShipmentID,
    l.Name AS WarehouseName,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    sd.Quantity AS QuantityShipped,
    sh.TrackingNumber
FROM dbo.Shipment sh
JOIN dbo.Warehouse w
    ON sh.WarehouseID = w.WarehouseID
JOIN dbo.Location l
    ON w.LocationID = l.LocationID
JOIN dbo.Employee e
    ON w.ManagerID = e.EmployeeID
JOIN dbo.ShipmentDetail sd
    ON sh.ShipmentID = sd.ShipmentID
JOIN dbo.Product p
    ON sd.ProductID = p.ProductID;


-- Q7. Find the top 3 highest-value orders per customer using RANK(). Display CustomerID, CustomerName, OrderID, and TotalAmount.

WITH RankedOrders AS
(
    SELECT
        c.CustomerID,
        c.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER
        (
            PARTITION BY c.CustomerID
            ORDER BY so.TotalAmount DESC
        ) AS OrderRank
    FROM dbo.Customer c
    JOIN dbo.SalesOrder so
        ON c.CustomerID = so.CustomerID
)
SELECT
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM RankedOrders
WHERE OrderRank <= 3;

-- Q8. For each product, show its sales history with the previous and next sales quantities (based on order date). Display ProductID, ProductName, OrderID, OrderDate, Quantity, PrevQuantity, and NextQuantity.
SELECT
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,
    LAG(sod.Quantity) OVER
    (
        PARTITION BY p.ProductID
        ORDER BY so.OrderDate
    ) AS PrevQuantity,
    LEAD(sod.Quantity) OVER
    (
        PARTITION BY p.ProductID
        ORDER BY so.OrderDate
    ) AS NextQuantity
FROM dbo.Product p
JOIN dbo.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
JOIN dbo.SalesOrder so
    ON sod.OrderID = so.OrderID;

--Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
-- CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.
DROP VIEW IF EXISTS vw_CustomerOrderSummary;
GO

CREATE VIEW vw_CustomerOrderSummary
AS
SELECT
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(so.OrderID) AS TotalOrders,
    ISNULL(SUM(so.TotalAmount),0) AS TotalAmountSpent,
    MAX(so.OrderDate) AS LastOrderDate
FROM Customer c
LEFT JOIN SalesOrder so
    ON c.CustomerID = so.CustomerID
GROUP BY
    c.CustomerID,
    c.Name;
select * from vw_CustomerOrderSummary;


-- Q10. Write a stored procedure sp_GetSupplierSales that takes a SupplierID as input and returns the total sales amount for all products supplied by that supplier.

CREATE PROCEDURE sp_GetSupplierSales (@p_SupplierID INT)
AS
BEGIN
    SELECT
        SUM(sod.TotalAmount) AS TotalSalesAmount
    FROM dbo.Supplier s
    JOIN dbo.PurchaseOrder po ON po.SupplierID = s.SupplierID
    JOIN dbo.PurchaseOrderDetail pod ON pod.OrderID = po.OrderID
    JOIN dbo.Product p ON p.ProductID = pod.ProductID
    JOIN dbo.SalesOrderDetail sod ON sod.ProductID = p.ProductID
    WHERE s.SupplierID = @p_SupplierID;
END;
GO

EXEC sp_GetSupplierSales @p_SupplierID = 1;
GO