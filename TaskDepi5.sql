----------q1
SELECT 
  product_id,
  product_name,
  list_price,
  CASE 
    WHEN list_price < 300 THEN 'Economy'
    WHEN list_price >= 300 AND list_price <= 999 THEN 'Standard'
    WHEN list_price >= 1000 AND list_price <= 2499 THEN 'Premium'
    WHEN list_price >= 2500 THEN 'Luxury'
  END AS price_category
FROM 
  production.products;
  --q2-------
  SELECT
  order_id,
  customer_id,
  order_date,
  order_status,
  -- Friendly status description
  CASE order_status
    WHEN 1 THEN 'Order Received'
    WHEN 2 THEN 'In Preparation'
    WHEN 3 THEN 'Order Cancelled'
    WHEN 4 THEN 'Order Delivered'
    ELSE 'Unknown Status'
  END AS status_description

FROM
 sales.orders;
 --q3------
 SELECT 
  s.staff_id,
  s.first_name,
  COUNT(o.order_id) AS total_orders,
  
  CASE 
    WHEN COUNT(o.order_id) = 0 THEN 'New Staff'
    WHEN COUNT(o.order_id) BETWEEN 1 AND 10 THEN 'Junior Staff'
    WHEN COUNT(o.order_id) BETWEEN 11 AND 25 THEN 'Senior Staff'
    ELSE 'Expert Staff'
  END AS staff_category

FROM 
  sales.staffs s
 JOIN 
  sales.orders o ON s.staff_id = o.staff_id
GROUP BY 
  s.staff_id, s.first_name;
  --q4-----
  SELECT 
  customer_id,
 first_name,
  ISNULL(phone, 'Phone Not Available') AS phone,
  email,
  
  COALESCE(phone, email, 'No Contact Method') AS preferred_contact

FROM 
  sales.customers;
  ---q5--------
  SELECT
  product_name,
  list_price,
  quantity,
  ISNULL(list_price / NULLIF(quantity, 0), 0) AS price_per_unit,
  
  CASE 
    WHEN quantity = 0 THEN 'Out of Stock'
    WHEN quantity <= 10 THEN 'Low Stock'
    ELSE 'In Stock'
  END AS stock_status

FROM
 production.products p
 join 
 production.stocks s
 on p.product_id= s.product_id
WHERE
  store_id = 1;
  ----q6---------
  SELECT
  customer_id,
  COALESCE(street, '') AS street,
  COALESCE(city, '') AS city,
  COALESCE(state, '') AS state,
  COALESCE(zip_code, '') AS zip_code,
  
  CONCAT(
    COALESCE(street, ''),
    CASE WHEN street IS NOT NULL THEN ', ' ELSE '' END,
    COALESCE(city, ''),
    CASE WHEN city IS NOT NULL THEN ', ' ELSE '' END,
    COALESCE(state, ''),
    CASE 
      WHEN zip_code IS NOT NULL THEN CONCAT(', ', zip_code)
      ELSE ''
    END
  ) AS formatted_address

FROM
 sales.customers;
 ----q7-----------
 WITH customer_spending AS (
  SELECT
    customer_id,
    SUM(order_id) AS total_spent
  FROM
    sales.orders
  GROUP BY
    customer_id
)

SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.email,
  cs.total_spent
FROM
  customer_spending cs
JOIN
  sales.customers c ON c.customer_id = cs.customer_id
WHERE
  cs.total_spent > 1500
ORDER BY
  cs.total_spent DESC;
  ---q9-----------
  WITH monthly_sales AS (
    SELECT
        FORMAT(order_date, 'yyyy-MM') AS month,
        SUM(order_id) AS total_sales
    FROM
       sales.orders
    GROUP BY
        FORMAT(order_date, 'yyyy-MM')
),
monthly_comparison AS (
    SELECT
        month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales
    FROM
        monthly_sales
)

SELECT
    month,
    total_sales,
    previous_month_sales,
    CASE 
        WHEN previous_month_sales IS NULL THEN NULL
        WHEN previous_month_sales = 0 THEN NULL
        ELSE ROUND(((total_sales - previous_month_sales) * 100.0) / previous_month_sales, 2)
    END AS growth_percentage
FROM
    monthly_comparison
ORDER BY
    month;
	---q10------------
	WITH ranked_products AS (
    SELECT
        product_id,
        product_name,
        category_id,
        list_price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS row_num,
        RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS price_rank,
        DENSE_RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS dense_price_rank
    FROM
      production. products
)

SELECT
    product_id,
    product_name,
    category_id,
    list_price,
    row_num,
    price_rank,
    dense_price_rank
FROM
    ranked_products
WHERE
    row_num <= 3
ORDER BY
    category_id,
    row_num;
--q11--------------
	WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(order_id) AS total_spent
    FROM
       sales.orders
    GROUP BY
        customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank,
        NTILE(5) OVER (ORDER BY total_spent DESC) AS spending_group
    FROM
        customer_spending
)
SELECT
    c.customer_id,
    c.total_spent,
    c.spending_rank,
    c.spending_group,
    CASE spending_group
        WHEN 1 THEN 'VIP'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
        WHEN 5 THEN 'Standard'
    END AS spending_tier
FROM
    ranked_customers c
ORDER BY
    c.spending_rank;
	----q12-------
	WITH store_stats AS (
    SELECT
        s.store_id,
        s.store_name,
        SUM(o.order_id) AS total_revenue,
        COUNT(o.order_id) AS total_orders
    FROM
       sales.stores s
    LEFT JOIN sales.orders o ON s.store_id = o.store_id
    GROUP BY
        s.store_id, s.store_name
),
ranked_stores AS (
    SELECT
        store_id,
        store_name,
        total_revenue,
        total_orders,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY total_orders DESC) AS order_count_rank,
        PERCENT_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_percentile,
        PERCENT_RANK() OVER (ORDER BY total_orders DESC) AS orders_percentile
    FROM
        store_stats
)
SELECT
    store_id,
    store_name,
    total_revenue,
    total_orders,
    revenue_rank,
    order_count_rank,
    ROUND(revenue_percentile * 100, 2) AS revenue_percentile_pct,
    ROUND(orders_percentile * 100, 2) AS orders_percentile_pct
FROM
    sales.stores
ORDER BY
    revenue_rank;
	-----q13--------------
	SELECT 
  *
FROM (
    SELECT 
        s.category_name,
        c.brand_name
    FROM 
       production.products p
	   join 
	   production.categories s on p.category_id=s.category_id
    JOIN production.brands c ON p.brand_id = c.brand_id
    WHERE 
         c.brand_name IN ('Electra', 'Haro', 'Trek', 'Surly')
) AS source_data
PIVOT (
    COUNT(brand_name)
    FOR brand_name IN ([Electra], [Haro], [Trek], [Surly])
) AS pivot_table;
----q14--------
SELECT 
    store_name,
    ISNULL([Jan], 0) AS Jan,
    ISNULL([Feb], 0) AS Feb,
    ISNULL([Mar], 0) AS Mar,
    ISNULL([Apr], 0) AS Apr,
    ISNULL([May], 0) AS May,
    ISNULL([Jun], 0) AS Jun,
    ISNULL([Jul], 0) AS Jul,
    ISNULL([Aug], 0) AS Aug,
    ISNULL([Sep], 0) AS Sep,
    ISNULL([Oct], 0) AS Oct,
    ISNULL([Nov], 0) AS Nov,
    ISNULL([Dec], 0) AS Dec,
    -- Total column
    ISNULL([Jan], 0) + ISNULL([Feb], 0) + ISNULL([Mar], 0) + ISNULL([Apr], 0) +
    ISNULL([May], 0) + ISNULL([Jun], 0) + ISNULL([Jul], 0) + ISNULL([Aug], 0) +
    ISNULL([Sep], 0) + ISNULL([Oct], 0) + ISNULL([Nov], 0) + ISNULL([Dec], 0)
    AS Total
FROM (
    SELECT 
        s.store_name,
        DATENAME(MONTH, o.order_date) AS month_name,
        o.order_id
    FROM 
       sales.orders o
    JOIN sales.stores s ON o.store_id = s.store_id
) AS source_data
PIVOT (
    SUM(order_id)
    FOR month_name IN ([Jan], [Feb], [Mar], [Apr], [May], [Jun], 
                       [Jul], [Aug], [Sep], [Oct], [Nov], [Dec])
) AS pivot_table
ORDER BY store_name;
---q15-------
SELECT 
    store_name,
    ISNULL([Pending], 0) AS Pending,
    ISNULL([Processing], 0) AS Processing,
    ISNULL([Completed], 0) AS Completed,
    ISNULL([Rejected], 0) AS Rejected
FROM (
    SELECT 
        s.store_name,
        o.order_status
    FROM 
       sales.orders o
    JOIN sales.stores s ON o.store_id = s.store_id
) AS source_data
PIVOT (
    COUNT(order_status)
    FOR order_status IN ([Pending], [Processing], [Completed], [Rejected])
) AS pivot_table
ORDER BY store_name;
---q16-----------
WITH yearly_sales AS (
    SELECT 
        b.brand_name,
        YEAR(o.order_date) AS sales_year,
        SUM(od.quantity * od.list_price) AS total_revenue
    FROM 
         sales.order_items od
    JOIN sales. orders o ON od.order_id = o.order_id
    JOIN production.products p ON od.product_id = p.product_id
    JOIN production.brands  b ON p.brand_id = b.brand_id
    WHERE YEAR(o.order_date) IN (2016, 2017, 2018)
    GROUP BY b.brand_name, YEAR(o.order_date)
),
pivoted_sales AS (
    SELECT 
        brand_name,
        ISNULL([2016], 0) AS Revenue_2016,
        ISNULL([2017], 0) AS Revenue_2017,
        ISNULL([2018], 0) AS Revenue_2018
    FROM 
        yearly_sales
    PIVOT (
        SUM(total_revenue)
        FOR sales_year IN ([2016], [2017], [2018])
    ) AS pvt
)
SELECT 
    brand_name,
    Revenue_2016,
    Revenue_2017,
    Revenue_2018,
    CASE 
        WHEN Revenue_2016 = 0 THEN NULL
        ELSE ROUND(((Revenue_2017 - Revenue_2016) * 100.0) / Revenue_2016, 2)
    END AS Growth_2017_vs_2016,
    CASE 
        WHEN Revenue_2017 = 0 THEN NULL
        ELSE ROUND(((Revenue_2018 - Revenue_2017) * 100.0) / Revenue_2017, 2)
    END AS Growth_2018_vs_2017
FROM 
    pivoted_sales
ORDER BY 
    brand_name;
	--q18------------
	-- العملاء اللي اشتروا في 2017
SELECT DISTINCT customer_id
FROM sales.orders

WHERE YEAR(order_date) = 2017

INTERSECT

-- العملاء اللي اشتروا في 2018
SELECT DISTINCT customer_id
FROM sales.orders
WHERE YEAR(order_date) = 2018;
---q19----------------

WITH in_all_stores AS (
    SELECT product_id
    FROM sales.stores s
	join production.products p
	on p.product_id=s.store_id
    WHERE store_id IN (1, 2, 3)
    GROUP BY product_id
    HAVING COUNT(DISTINCT store_id) = 3
),


only_in_store1 AS (
    SELECT product_id
    FROM sales.stores s
	join production.products p
	on p.product_id=s.store_id
    WHERE store_id = 1

    EXCEPT

    SELECT product_id 
    FROM sales.stores s
	join production.products p
	on p.product_id=s.store_id
    WHERE store_id = 2
)

SELECT product_id, 'Available in All Stores' AS status
FROM production.products

UNION

SELECT product_id, 'Only in Store 1 (Not in 2)' AS status
FROM production.products