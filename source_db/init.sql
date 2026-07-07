-- ============================================
-- OLTP Source Schema: E-commerce
-- ============================================

CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    city            VARCHAR(100),
    country         VARCHAR(100),
    signup_date     DATE NOT NULL,
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(100),
    unit_price      NUMERIC(10,2) NOT NULL,
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INT REFERENCES customers(customer_id),
    order_date      TIMESTAMP NOT NULL,
    status          VARCHAR(30) NOT NULL, -- e.g. completed, cancelled, refunded
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        INT REFERENCES orders(order_id),
    product_id      INT REFERENCES products(product_id),
    quantity        INT NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL -- price at time of order (important for SCD-like history)
);

-- ============================================
-- Seed Data
-- ============================================

INSERT INTO customers (full_name, email, city, country, signup_date) VALUES
('Ahmed Hassan', 'ahmed.hassan@example.com', 'Cairo', 'Egypt', '2024-01-15'),
('Mona Adel', 'mona.adel@example.com', 'Giza', 'Egypt', '2024-02-10'),
('Youssef Kamal', 'youssef.kamal@example.com', 'Alexandria', 'Egypt', '2024-03-05'),
('Sara Ibrahim', 'sara.ibrahim@example.com', 'Cairo', 'Egypt', '2024-03-20'),
('Omar Nabil', 'omar.nabil@example.com', 'Mansoura', 'Egypt', '2024-04-01');

INSERT INTO products (product_name, category, unit_price) VALUES
('Wireless Mouse', 'Electronics', 350.00),
('Mechanical Keyboard', 'Electronics', 1200.00),
('Running Shoes', 'Sportswear', 900.00),
('Yoga Mat', 'Sportswear', 400.00),
('Coffee Maker', 'Home Appliances', 1500.00),
('Backpack', 'Accessories', 600.00);

INSERT INTO orders (customer_id, order_date, status) VALUES
(1, '2024-05-01 10:15:00', 'completed'),
(2, '2024-05-02 14:30:00', 'completed'),
(1, '2024-05-10 09:00:00', 'cancelled'),
(3, '2024-05-12 16:45:00', 'completed'),
(4, '2024-05-15 11:20:00', 'refunded'),
(5, '2024-05-18 13:10:00', 'completed'),
(2, '2024-05-20 17:00:00', 'completed');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 350.00),
(1, 3, 1, 900.00),
(2, 2, 1, 1200.00),
(3, 4, 2, 400.00),
(4, 5, 1, 1500.00),
(4, 6, 1, 600.00),
(5, 3, 1, 900.00),
(6, 1, 2, 350.00),
(7, 2, 1, 1200.00),
(7, 4, 1, 400.00);
