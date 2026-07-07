-- ============================================
-- Staging schema: نسخة خام (raw) من جداول الـ source_db
-- بتتحمل هنا من غير أي تحويل - dbt هو اللي هيحوّلها بعد كده
-- ============================================

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE staging.customers (
    customer_id     INT PRIMARY KEY,
    full_name       VARCHAR(150),
    email           VARCHAR(150),
    city            VARCHAR(100),
    country         VARCHAR(100),
    signup_date     DATE,
    updated_at      TIMESTAMP
);

CREATE TABLE staging.products (
    product_id      INT PRIMARY KEY,
    product_name    VARCHAR(150),
    category        VARCHAR(100),
    unit_price      NUMERIC(10,2),
    updated_at      TIMESTAMP
);

CREATE TABLE staging.orders (
    order_id        INT PRIMARY KEY,
    customer_id     INT,
    order_date      TIMESTAMP,
    status          VARCHAR(30),
    updated_at      TIMESTAMP
);

CREATE TABLE staging.order_items (
    order_item_id   INT PRIMARY KEY,
    order_id        INT,
    product_id      INT,
    quantity        INT,
    unit_price      NUMERIC(10,2)
);
