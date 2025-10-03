-- 1.Customer Lifetime Value (CLV)
select c.customer_unique_id, SUM(oi.price) As total_spent, COUNT(distinct o.order_id) As total_order,
	   AVG(oi.price) as avg_order_value, o.order_status
from customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE order_status = 'delivered'
GROUP by c.customer_unique_id
ORDER by total_spent DESC
LIMIT 10;

--2.Repeat Purchase Rate
SELECT
    (SELECT COUNT(*)
     FROM (
         SELECT c.customer_unique_id
         FROM customers c
         JOIN orders o ON c.customer_id = o.customer_id
         WHERE o.order_status = 'delivered'
         GROUP BY c.customer_unique_id
         HAVING COUNT(DISTINCT o.order_id) > 1
     )
    ) * 100.0
    /
    (SELECT COUNT(*) FROM customers) AS repeat_purchase_rate;


--3.Most Ordered Products
SELECT 
    p.product_category_name,
    COUNT(oi.product_id) AS total_orders,
    SUM(oi.price) AS revenue_generated
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_orders DESC
LIMIT 10;


--4.New vs. Repeat Customers (Segmentation)
WITH customer_first_order AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN strftime('%Y', o.order_purchase_timestamp) = strftime('%Y', cfo.first_order_date)
         AND strftime('%m', o.order_purchase_timestamp) = strftime('%m', cfo.first_order_date)
        THEN 'New Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN customer_first_order cfo ON c.customer_unique_id = cfo.customer_unique_id
WHERE o.order_status = 'delivered'
GROUP BY customer_type;

--5.RFM Segmentation (Recency, Frequency, Monetary)
WITH customer_metrics AS (
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    DATE('2018-01-01') - DATE(last_order_date) AS recency_days,
    frequency,
    monetary
FROM customer_metrics;



