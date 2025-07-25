--------------q1--------------
DECLARE @CustomerID INT = 1;
DECLARE @TotalSpent DECIMAL(10,2);
DECLARE @CustomerStatus VARCHAR(50);

-- Calculate total amount spent
SELECT @TotalSpent = SUM(order_id)
FROM  sales.orders
WHERE customer_id = @CustomerID;

-- Determine status
IF @TotalSpent > 5000
    SET @CustomerStatus = 'VIP Customer';
ELSE
    SET @CustomerStatus = 'Regular Customer';

-- Output result
SELECT 
    @CustomerID AS CustomerID,
    @TotalSpent AS TotalSpent,
    @CustomerStatus AS StatusMessage;
	--------q2-----------------
	DECLARE @PriceThreshold DECIMAL(10,2) = 1500;
DECLARE @ProductCount INT;
DECLARE @Message NVARCHAR(200);


SELECT @ProductCount = COUNT(*)
FROM production.products
WHERE list_price > @PriceThreshold;

SET @Message = 'Number of products costing more than $' 
               + CAST(@PriceThreshold AS VARCHAR)
               + ' is: ' 
               + CAST(@ProductCount AS VARCHAR);

SELECT @Message AS ResultMessage;
----------q3------
DECLARE @StaffID INT = 2;
DECLARE @Year INT = 2017;
DECLARE @TotalSales DECIMAL(18,2);

-- Calculate total sales
SELECT @TotalSales = SUM(order_id)
FROM sales.orders
WHERE staff_id = @StaffID
  AND YEAR(order_date) = @Year;

-- Display the result
SELECT 
    'Staff ID' AS Label1, @StaffID AS Value1,
    'Year' AS Label2, @Year AS Value2,
    'Total Sales' AS Label3, @TotalSales AS Value3;
	-------------q4---------
SELECT  
    @@SERVERNAME AS [Server Name],
    @@VERSION AS [SQL Server Version],
    @@ROWCOUNT AS [Rows Affected];
	------------q5----------
DECLARE @ProductID INT = 1;
DECLARE @Quantity INT;

SELECT @Quantity = quantity
FROM sales.order_items
WHERE product_id = @ProductID ;

IF @Quantity > 20
    PRINT 'Well stocked';
ELSE IF @Quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE IF @Quantity < 10
    PRINT 'Low stock - reorder needed';
ELSE
    PRINT 'Product not found or quantity is NULL';
	----------q6------------

DECLARE @BatchSize INT = 3;
DECLARE @Counter INT = 0;

DECLARE @LowStock TABLE (
    ProductID INT,
    StoreID INT
);

INSERT INTO @LowStock (ProductID, StoreID)
SELECT product_id
FROM sales.order_items
WHERE quantity < 5;


WHILE EXISTS (SELECT 1 FROM @LowStock)
BEGIN
    UPDATE TOP (@BatchSize) s
    SET s.quantity = s.quantity + 10
    FROM sales.order_items s
    INNER JOIN @LowStock ls
        ON s.product_id = ls.ProductID ;
    DELETE TOP (@BatchSize) FROM @LowStock;

    SET @Counter = @Counter + 1;
    PRINT 'Batch ' + CAST(@Counter AS VARCHAR) + ' processed: 3 products restocked.';
END

PRINT 'All low-stock products have been updated.';
----------------q7---------
SELECT 
    product_id,
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        WHEN list_price > 2000 THEN 'Luxury'
    END AS PriceCategory
FROM production.products;
-----------q8--------
DECLARE @Customer_ID INT = 5;
DECLARE @OrderCount INT;

IF EXISTS (SELECT 1 FROM sales.customers WHERE customer_id = @CustomerID)
BEGIN
    SELECT @OrderCount = COUNT(*) 
    FROM sales.orders
    WHERE customer_id = @CustomerID;

    PRINT 'Customer ID ' + CAST(@CustomerID AS VARCHAR) + ' has placed ' + CAST(@OrderCount AS VARCHAR) + ' orders.';
END
ELSE
BEGIN
    PRINT 'Customer ID ' + CAST(@CustomerID AS VARCHAR) + ' does not exist in the database.';
END
--------------q9-------------
CREATE FUNCTION CalculateShipping (@OrderTotal DECIMAL(10, 2))
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @ShippingCost DECIMAL(10, 2);

    IF @OrderTotal > 100
        SET @ShippingCost = 0.00;
    ELSE IF @OrderTotal BETWEEN 50 AND 99.99
        SET @ShippingCost = 5.99;
    ELSE
        SET @ShippingCost = 12.99;

    RETURN @ShippingCost;
END;
---------------q10-------------
CREATE FUNCTION GetProductsByPriceRange
(
    @MinPrice DECIMAL(10, 2),
    @MaxPrice DECIMAL(10, 2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.product_id,
        p.product_name,
        p.list_price,
        b.brand_name,
        c.category_name
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @MinPrice AND @MaxPrice
);
---------------q11--------------
CREATE FUNCTION GetCustomerYearlySummary
(
    @CustomerID INT
)
RETURNS @Summary TABLE
(
    [Year] INT,
    TotalOrders INT,
    TotalSpent DECIMAL(18, 2),
    AverageOrderValue DECIMAL(18, 2)
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT 
        YEAR(o.order_date) AS [Year],
        COUNT(*) AS TotalOrders,
        SUM(o.order_id) AS TotalSpent
    FROM sales.orders o
    WHERE o.customer_id = @CustomerID
    GROUP BY YEAR(o.order_date)
    
    RETURN
END
--------------q12--------------
CREATE FUNCTION CalculateBulkDiscount
(
    @Quantity INT
)
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @Discount DECIMAL(5, 2)

    IF @Quantity BETWEEN 1 AND 2
        SET @Discount = 0.00
    ELSE IF @Quantity BETWEEN 3 AND 5
        SET @Discount = 5.00
    ELSE IF @Quantity BETWEEN 6 AND 9
        SET @Discount = 10.00
    ELSE IF @Quantity >= 10
        SET @Discount = 15.00
    ELSE
        SET @Discount = 0.00 -- default if invalid quantity

    RETURN @Discount
END
------------q13------------
create or alter proc sp_GetCustomerOrderHistory @customer_id int
as
select max(order_date),min(order_date) from sales.orders
where customer_id=@customer_id
sp_GetCustomerOrderHistory 5
----------q14-------------

create or alter proc  sp_RestockProduct @store_id int,@product_id int,@quantity int
as
select quantity,@quantity from production.stocks
----------q15---------

create or alter proc sp_ProcessNewOrder @customer_id int, @productID int, @quantity int, @storeID int
as
select *
from sales.orders o
join sales.order_items s
on o.order_id=s.order_id
where customer_id=@customer_id
and store_id=@storeID
and quantity=@quantity
and product_id=@productID

---------q16---------
CREATE PROCEDURE sp_SearchProducts
    @SearchTerm NVARCHAR(100) = NULL,
    @CategoryID INT = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @SortColumn NVARCHAR(50) = 'ProductName'  -- Default sort
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @Params NVARCHAR(MAX)

    -- Base query
    SET @SQL = '
    SELECT p.ProductID, p.ProductName, p.ListPrice, c.CategoryName
    FROM Products p
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
    WHERE 1 = 1'

    -- Build dynamic WHERE clauses
    IF @SearchTerm IS NOT NULL
        SET @SQL += ' AND p.ProductName LIKE @SearchPattern'

    IF @CategoryID IS NOT NULL
        SET @SQL += ' AND p.CategoryID = @CategoryID'

    IF @MinPrice IS NOT NULL
        SET @SQL += ' AND p.ListPrice >= @MinPrice'

    IF @MaxPrice IS NOT NULL
        SET @SQL += ' AND p.ListPrice <= @MaxPrice'

    -- Validate sort column to prevent SQL injection
    IF @SortColumn NOT IN ('ProductName', 'ListPrice', 'CategoryName')
        SET @SortColumn = 'ProductName'

    SET @SQL += ' ORDER BY ' + QUOTENAME(@SortColumn)

    -- Define parameters for sp_executesql
    SET @Params = '
        @SearchPattern NVARCHAR(100),
        @CategoryID INT,
        @MinPrice DECIMAL(10,2),
        @MaxPrice DECIMAL(10,2)'

    -- Execute dynamic SQL
    EXEC sp_executesql
        @SQL,
        @Params,
        @SearchPattern = '%' + @SearchTerm + '%',
        @CategoryID = @CategoryID,
        @MinPrice = @MinPrice,
        @MaxPrice = @MaxPrice
END
------------q19------------
SELECT
    c.customer_id,
    c.first_name,
    ISNULL(SUM(s.quantity), 0) AS TotalSpending,

    CASE 
        WHEN SUM(s.quantity) IS NULL THEN 'No Orders'
        WHEN SUM(s.quantity) < 500 THEN 'Bronze'
        WHEN SUM(s.quantity) BETWEEN 500 AND 1999.99 THEN 'Silver'
        WHEN SUM(s.quantity) BETWEEN 2000 AND 4999.99 THEN 'Gold'
        WHEN SUM(s.quantity) >= 5000 THEN 'Platinum'
        ELSE 'No Tier'
    END AS LoyaltyTier

FROM
    sales.customers c
 JOIN
    sales.orders o ON c.customer_id = o.customer_id
	join sales.order_items s
	on s.order_id=o.order_id
GROUP BY
    c.customer_id, c.first_name
ORDER BY
    TotalSpending DESC;
	----------q20------------

