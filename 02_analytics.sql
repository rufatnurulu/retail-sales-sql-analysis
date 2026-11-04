-- Retail Intelligence: PostgreSQL Analytics
-- Run after 01_database_setup.sql in retail_intelligence.
-- Synthetic data; all monetary values are illustrative.

-- 01 Revenue and units
SELECT ROUND(SUM(quantity * unit_price),2) AS revenue, SUM(quantity) AS units_sold FROM order_items;

-- 02 Completed orders
SELECT COUNT(*) AS completed_orders FROM orders WHERE status='completed';

-- 03 Average order value
SELECT ROUND(AVG(order_total),2) AS avg_order_value FROM (SELECT order_id,SUM(quantity*unit_price) AS order_total FROM order_items GROUP BY order_id) t;

-- 04 Monthly revenue
SELECT DATE_TRUNC('month',o.order_date)::date AS month,COUNT(DISTINCT o.order_id) AS orders,ROUND(SUM(i.quantity*i.unit_price),2) AS revenue FROM orders o JOIN order_items i USING(order_id) GROUP BY 1 ORDER BY 1;

-- 05 Product revenue ranking
SELECT p.product_name,SUM(i.quantity) AS units,ROUND(SUM(i.quantity*i.unit_price),2) AS revenue FROM products p JOIN order_items i USING(product_id) GROUP BY p.product_id,p.product_name ORDER BY revenue DESC;

-- 06 Category revenue
SELECT p.category,ROUND(SUM(i.quantity*i.unit_price),2) AS revenue FROM products p JOIN order_items i USING(product_id) GROUP BY p.category ORDER BY revenue DESC;

-- 07 Store performance
SELECT s.store_name,COUNT(DISTINCT o.order_id) AS orders,ROUND(SUM(i.quantity*i.unit_price),2) AS revenue FROM stores s JOIN orders o USING(store_id) JOIN order_items i USING(order_id) GROUP BY s.store_id,s.store_name ORDER BY revenue DESC;

-- 08 Customer lifetime spend
SELECT c.customer_id,c.full_name,COUNT(DISTINCT o.order_id) AS orders,ROUND(SUM(i.quantity*i.unit_price),2) AS lifetime_spend FROM customers c JOIN orders o USING(customer_id) JOIN order_items i USING(order_id) GROUP BY c.customer_id,c.full_name ORDER BY lifetime_spend DESC LIMIT 20;

-- 09 Product gross profit (illustrative; excludes other expenses)
SELECT p.product_name,ROUND(SUM(i.quantity*(i.unit_price-p.unit_cost)),2) AS gross_profit FROM products p JOIN order_items i USING(product_id) GROUP BY p.product_id,p.product_name ORDER BY gross_profit DESC;

-- 10 Low-stock products
SELECT product_name,category,stock_quantity FROM products WHERE stock_quantity<100 ORDER BY stock_quantity;

-- 11 Revenue share by category (window function)
WITH category_sales AS (SELECT p.category,SUM(i.quantity*i.unit_price) AS revenue FROM products p JOIN order_items i USING(product_id) GROUP BY p.category)
SELECT category,ROUND(revenue,2) AS revenue,ROUND(100*revenue/NULLIF(SUM(revenue) OVER(),0),2) AS revenue_pct FROM category_sales ORDER BY revenue DESC;

-- 12 Ranked customers (CTE + dense_rank)
WITH spending AS (SELECT c.customer_id,c.full_name,SUM(i.quantity*i.unit_price) AS total FROM customers c JOIN orders o USING(customer_id) JOIN order_items i USING(order_id) GROUP BY c.customer_id,c.full_name)
SELECT full_name,ROUND(total,2) AS total_spend,DENSE_RANK() OVER(ORDER BY total DESC) AS spend_rank FROM spending ORDER BY spend_rank LIMIT 25;

-- 13 Monthly revenue growth
WITH monthly AS (SELECT DATE_TRUNC('month',o.order_date)::date AS month,SUM(i.quantity*i.unit_price) AS revenue FROM orders o JOIN order_items i USING(order_id) GROUP BY 1), lagged AS (SELECT month,revenue,LAG(revenue) OVER(ORDER BY month) AS previous_revenue FROM monthly)
SELECT month,ROUND(revenue,2) AS revenue,ROUND(100*(revenue-previous_revenue)/NULLIF(previous_revenue,0),2) AS mom_growth_pct FROM lagged ORDER BY month;

-- 14 Orders per customer distribution
WITH order_counts AS (SELECT customer_id,COUNT(*) AS orders FROM orders GROUP BY customer_id)
SELECT orders,COUNT(*) AS customers FROM order_counts GROUP BY orders ORDER BY orders;

-- 15 Employee-associated sales
SELECT e.full_name,s.store_name,COUNT(DISTINCT o.order_id) AS orders,ROUND(SUM(i.quantity*i.unit_price),2) AS revenue FROM employees e JOIN stores s ON e.store_id=s.store_id JOIN orders o ON o.employee_id=e.employee_id JOIN order_items i USING(order_id) GROUP BY e.employee_id,e.full_name,s.store_name ORDER BY revenue DESC;

-- 16 Average basket size
SELECT ROUND(AVG(units),2) AS avg_units_per_order FROM (SELECT order_id,SUM(quantity) AS units FROM order_items GROUP BY order_id) t;

-- 17 Sales by city
SELECT s.city,ROUND(SUM(i.quantity*i.unit_price),2) AS revenue FROM stores s JOIN orders o USING(store_id) JOIN order_items i USING(order_id) GROUP BY s.city ORDER BY revenue DESC;

-- 18 Customer segmentation by spend quartile
WITH spend AS (SELECT c.customer_id,SUM(i.quantity*i.unit_price) AS total FROM customers c JOIN orders o USING(customer_id) JOIN order_items i USING(order_id) GROUP BY c.customer_id),segments AS (SELECT customer_id,total,NTILE(4) OVER(ORDER BY total DESC) AS spend_quartile FROM spend)
SELECT spend_quartile,COUNT(*) AS customers,ROUND(AVG(total),2) AS avg_spend FROM segments GROUP BY spend_quartile ORDER BY spend_quartile;

-- 19 Product gross margin percentage
SELECT p.product_name,ROUND(100*SUM(i.quantity*(i.unit_price-p.unit_cost))/NULLIF(SUM(i.quantity*i.unit_price),0),2) AS gross_margin_pct FROM products p JOIN order_items i USING(product_id) GROUP BY p.product_id,p.product_name ORDER BY gross_margin_pct DESC;

-- 20 Monthly running revenue
WITH monthly AS (SELECT DATE_TRUNC('month',o.order_date)::date AS month,SUM(i.quantity*i.unit_price) AS revenue FROM orders o JOIN order_items i USING(order_id) GROUP BY 1)
SELECT month,ROUND(revenue,2) AS monthly_revenue,ROUND(SUM(revenue) OVER(ORDER BY month),2) AS cumulative_revenue FROM monthly ORDER BY month;

-- 21 Top products per category
WITH ranked AS (SELECT p.category,p.product_name,SUM(i.quantity*i.unit_price) AS revenue,DENSE_RANK() OVER(PARTITION BY p.category ORDER BY SUM(i.quantity*i.unit_price) DESC) AS category_rank FROM products p JOIN order_items i USING(product_id) GROUP BY p.category,p.product_id,p.product_name)
SELECT category,product_name,ROUND(revenue,2) AS revenue,category_rank FROM ranked WHERE category_rank<=3 ORDER BY category,category_rank;

-- 22 Reusable view for order totals
CREATE OR REPLACE VIEW vw_order_totals AS SELECT o.order_id,o.order_date,o.customer_id,o.store_id,ROUND(SUM(i.quantity*i.unit_price),2) AS order_total FROM orders o JOIN order_items i USING(order_id) GROUP BY o.order_id,o.order_date,o.customer_id,o.store_id;
SELECT * FROM vw_order_totals ORDER BY order_total DESC LIMIT 10;
