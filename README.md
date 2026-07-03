# E-commerce Data Pipeline

A local, open-source data engineering pipeline that simulates a real-world
e-commerce ETL workflow: from a raw OLTP source database, through
transformation into a dimensional (Star Schema) warehouse, ready for
analytics.

## 🏗️ Architecture

```
┌─────────────┐       ┌───────────────┐       ┌──────────────────┐
│  source_db  │──ETL─▶│  Python ETL   │──────▶│   warehouse_db    │
│ (OLTP, raw) │       │ (Extract/     │       │ (Star Schema,     │
│  Postgres   │       │  Transform/   │       │  OLAP-ready)      │
│             │       │  Load)        │       │  Postgres         │
└─────────────┘       └───────────────┘       └──────────────────┘
```

Two isolated PostgreSQL instances run in Docker containers:
- **`source_db`** — raw transactional data (customers, products, orders, order_items)
- **`warehouse_db`** — dimensional model (dim_date, dim_customer, dim_product, fact_order_items)

A Python ETL script bridges the two, transforming normalized OLTP data into
a denormalized Star Schema optimized for analytical queries.

## 🛠️ Tech Stack

| Component        | Tool                     |
|-------------------|--------------------------|
| Source & Warehouse | PostgreSQL 15           |
| Containerization   | Docker & Docker Compose |
| ETL                | Python (pandas, SQLAlchemy, psycopg2) |
| Orchestration (planned) | Apache Airflow      |
| Transformation (planned) | dbt                |

## 📂 Project Structure

```
.
├── docker/
│   └── docker-compose.yml     # Spins up source_db + warehouse_db
├── source_db/
│   └── init.sql                # OLTP schema + seed data
├── warehouse_db/
│   └── warehouse_schema.sql    # Star Schema DDL (facts + dimensions)
├── etl/
│   ├── etl.py                  # Extract-Transform-Load script
│   └── requirements.txt
└── README.md
```

## 🗂️ Data Model

**Source (OLTP)** — normalized, transactional:
`customers`, `products`, `orders`, `order_items`

**Warehouse (Star Schema)** — grain: one row per order line item

- `fact_order_items` — quantity, unit_price, line_total, FKs to dimensions
- `dim_customer` — SCD Type 2 (tracks customer changes over time via `valid_from`/`valid_to`/`is_current`)
- `dim_product` — SCD Type 1
- `dim_date` — standard date dimension (day, month, quarter, year, weekend flag)

## 🚀 Getting Started

### Prerequisites
- Docker Desktop
- Python 3.10+

### 1. Start the databases
```bash
cd docker
docker compose up -d
```

This creates:
- `source_db` on `localhost:5433`
- `warehouse_db` on `localhost:5434`

### 2. Install ETL dependencies
```bash
cd etl
pip install -r requirements.txt
```

### 3. Run the ETL pipeline
```bash
python etl.py
```

### 4. Verify the results
```bash
docker exec -it ecommerce_warehouse_db psql -U warehouse_user -d ecommerce_warehouse
```
```sql
SELECT * FROM fact_order_items LIMIT 10;
```

## 📈 Roadmap

- [x] Source OLTP database (Dockerized)
- [x] Star Schema warehouse design
- [x] Python ETL (Extract, Transform, Load)
- [ ] Orchestrate with Apache Airflow
- [ ] Add dbt for SQL-based transformations & testing
- [ ] BI dashboard (Metabase / Power BI)

## 📝 Notes

- `order_items.unit_price` is stored separately from `products.unit_price` —
  this preserves the actual price at the time of sale, independent of later
  price changes on the product.
- `dim_customer` is modeled as SCD Type 2 to demonstrate historical tracking
  of customer attribute changes (e.g. city).
