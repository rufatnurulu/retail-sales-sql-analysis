-- Retail Intelligence | PostgreSQL 14+
-- Synthetic demonstration data, not real customer information.
BEGIN;
DROP TABLE IF EXISTS order_items, orders, employees, customers, products, stores CASCADE;
CREATE TABLE stores (store_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, store_name VARCHAR(100) NOT NULL, city VARCHAR(80) NOT NULL);
CREATE TABLE customers (customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, full_name VARCHAR(120) NOT NULL, city VARCHAR(80) NOT NULL, registered_on DATE NOT NULL);
CREATE TABLE products (product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, product_name VARCHAR(120) NOT NULL, category VARCHAR(50) NOT NULL, unit_price NUMERIC(10,2) NOT NULL CHECK(unit_price>0), unit_cost NUMERIC(10,2) NOT NULL CHECK(unit_cost>=0), stock_quantity INT NOT NULL CHECK(stock_quantity>=0));
CREATE TABLE employees (employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, full_name VARCHAR(120) NOT NULL, store_id INT NOT NULL REFERENCES stores(store_id));
CREATE TABLE orders (order_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, customer_id INT NOT NULL REFERENCES customers(customer_id), store_id INT NOT NULL REFERENCES stores(store_id), employee_id INT NOT NULL REFERENCES employees(employee_id), order_date DATE NOT NULL, status VARCHAR(20) NOT NULL DEFAULT 'completed');
CREATE TABLE order_items (order_item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, order_id INT NOT NULL REFERENCES orders(order_id), product_id INT NOT NULL REFERENCES products(product_id), quantity INT NOT NULL CHECK(quantity>0), unit_price NUMERIC(10,2) NOT NULL CHECK(unit_price>0));
INSERT INTO stores(store_name,city) VALUES ('Central Baku','Baku'),('Ganja Branch','Ganja'),('Sumgayit Branch','Sumgayit'),('Nizami Branch','Baku');
INSERT INTO products(product_name,category,unit_price,unit_cost,stock_quantity) VALUES
('Face Cream','Skincare',35,18,120),('Face Serum','Skincare',55,27,80),('Body Lotion','Skincare',25,11,200),('Shampoo','Haircare',18,8,180),('Hair Mask','Haircare',30,14,95),('Perfume','Fragrance',75,39,65),('Hand Cream','Skincare',12,5,240),('Conditioner','Haircare',22,10,135),('Body Mist','Fragrance',40,19,110),('Cleanser','Skincare',28,12,150),('Lip Balm','Skincare',10,4,210),('Hair Oil','Haircare',38,17,75);
INSERT INTO customers(full_name,city,registered_on)
SELECT 'Customer ' || gs, (ARRAY['Baku','Ganja','Sumgayit','Mingachevir'])[1+(gs%4)], DATE '2025-01-01' + (gs%300)
FROM generate_series(1,250) gs;
INSERT INTO employees(full_name,store_id)
SELECT 'Employee ' || gs, 1+((gs-1)%4) FROM generate_series(1,16) gs;
INSERT INTO orders(customer_id,store_id,employee_id,order_date,status)
SELECT 1+((gs*37)%250), 1+((gs-1)%4), 1+((gs-1)%16), DATE '2025-01-01' + ((gs*17)%365), 'completed'
FROM generate_series(1,1500) gs;
INSERT INTO order_items(order_id,product_id,quantity,unit_price)
SELECT o.order_id, 1+((o.order_id*7 + line.n*3)%12), 1+((o.order_id+line.n)%4), p.unit_price
FROM orders o
CROSS JOIN LATERAL generate_series(1, 1+(o.order_id%3)) AS line(n)
JOIN products p ON p.product_id = 1+((o.order_id*7 + line.n*3)%12);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
COMMIT;
-- Verification: 4 stores, 250 customers, 12 products, 16 employees, 1500 orders, 3000 order items.
SELECT 'stores' AS table_name, COUNT(*) AS rows FROM stores
UNION ALL SELECT 'customers',COUNT(*) FROM customers
UNION ALL SELECT 'products',COUNT(*) FROM products
UNION ALL SELECT 'employees',COUNT(*) FROM employees
UNION ALL SELECT 'orders',COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items;
