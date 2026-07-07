-- ============================================
-- Star Schema: E-commerce Warehouse (OLAP)
-- Grain of fact_order_items: one row per product line within an order
-- ============================================

-- ---------- DIM: Date ----------
CREATE TABLE dim_date (
    date_key        INT PRIMARY KEY,        -- format: YYYYMMDD
    full_date       DATE NOT NULL,
    day             INT NOT NULL,
    month           INT NOT NULL,
    month_name      VARCHAR(20) NOT NULL,
    quarter         INT NOT NULL,
    year            INT NOT NULL,
    day_of_week     VARCHAR(20) NOT NULL,
    is_weekend      BOOLEAN NOT NULL
);

-- ---------- DIM: Customer (SCD Type 2) ----------
CREATE TABLE dim_customer (
    customer_sk     SERIAL PRIMARY KEY,     -- surrogate key (internal to warehouse)
    customer_id     INT NOT NULL,           -- natural/business key (from source)
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL,
    city            VARCHAR(100),
    country         VARCHAR(100),
    signup_date     DATE NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,                   -- NULL = current active record
    is_current      BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------- DIM: Product (SCD Type 1) ----------
CREATE TABLE dim_product (
    product_sk      SERIAL PRIMARY KEY,
    product_id      INT NOT NULL UNIQUE,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(100),
    current_price   NUMERIC(10,2) NOT NULL
);

-- ---------- FACT: Order Items ----------
CREATE TABLE fact_order_items (
    fact_id         SERIAL PRIMARY KEY,
    order_id        INT NOT NULL,           -- degenerate dimension (no separate dim_order needed)
    date_key        INT NOT NULL REFERENCES dim_date(date_key),
    customer_sk     INT NOT NULL REFERENCES dim_customer(customer_sk),
    product_sk      INT NOT NULL REFERENCES dim_product(product_sk),
    order_status    VARCHAR(30) NOT NULL,
    quantity        INT NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL, -- price at time of sale
    line_total      NUMERIC(10,2) NOT NULL  -- quantity * unit_price
);

-- Helpful indexes for typical analytical queries
CREATE INDEX idx_fact_customer ON fact_order_items(customer_sk);
CREATE INDEX idx_fact_product ON fact_order_items(product_sk);
CREATE INDEX idx_fact_date ON fact_order_items(date_key);
