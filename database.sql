
-- RETAIL SALES & BUSINESS INTELLIGENCE
-- Database Schema
-- SQL dialect: SQLite

PRAGMA foreign_keys = ON;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    city TEXT NOT NULL,
    registration_date TEXT NOT NULL
);

CREATE TABLE stores (
    store_id INTEGER PRIMARY KEY,
    store_name TEXT NOT NULL,
    city TEXT NOT NULL
);

CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    store_id INTEGER NOT NULL,
    position TEXT NOT NULL,
    FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit_price REAL NOT NULL,
    cost_price REAL NOT NULL,
    stock_quantity INTEGER NOT NULL
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    store_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    FOREIGN KEY (store_id)
        REFERENCES stores(store_id),
    FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id)
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- SAMPLE DATA (FICTIONAL)

INSERT INTO customers VALUES
(1, 'Aylin Mammadova', 'Baku', '2025-01-10'),
(2, 'Murad Aliyev', 'Ganja', '2025-02-12'),
(3, 'Nigar Hasanli', 'Baku', '2025-03-15'),
(4, 'Elvin Karimov', 'Sumgayit', '2025-04-20'),
(5, 'Leyla Ismayilova', 'Baku', '2025-05-05');

INSERT INTO stores VALUES
(1, 'Central Store', 'Baku'),
(2, 'Ganja Branch', 'Ganja'),
(3, 'Sumgayit Branch', 'Sumgayit');

INSERT INTO employees VALUES
(1, 'Employee A', 1, 'Sales Consultant'),
(2, 'Employee B', 2, 'Sales Consultant'),
(3, 'Employee C', 3, 'Store Manager');

INSERT INTO products VALUES
(1, 'Face Cream', 'Skincare', 35, 18, 150),
(2, 'Shampoo', 'Haircare', 18, 8, 200),
(3, 'Perfume', 'Fragrance', 75, 40, 80),
(4, 'Body Lotion', 'Skincare', 25, 12, 120),
(5, 'Face Serum', 'Skincare', 55, 28, 90),
(6, 'Hair Mask', 'Haircare', 30, 14, 110);

INSERT INTO orders VALUES
(1, 1, 1, 1, '2026-01-05'),
(2, 2, 2, 2, '2026-01-10'),
(3, 3, 1, 1, '2026-02-02'),
(4, 4, 3, 3, '2026-02-15'),
(5, 5, 1, 1, '2026-03-03'),
(6, 1, 1, 1, '2026-03-20');

INSERT INTO order_items VALUES
(1, 1, 1, 2, 35),
(2, 1, 3, 1, 75),
(3, 2, 2, 3, 18),
(4, 3, 5, 2, 55),
(5, 4, 4, 4, 25),
(6, 5, 3, 2, 75),
(7, 6, 6, 3, 30),
(8, 6, 1, 1, 35);

