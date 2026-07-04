"""
ETL Script: Source (OLTP) -> Warehouse (Star Schema)

Extract  : يقرأ الجداول الخام من source_db
Transform: يحول البيانات لشكل الـ Star Schema (dim_date, dim_customer, dim_product, fact_order_items)
Load     : يفضي جداول الـ warehouse ويحمّل البيانات المحوّلة فيها

يشتغل من جهازك مباشرة (مش جوه container)، فبيتواصل مع الـ databases
عن طريق البورتات اللي معمولة لهم expose في docker-compose.yml (5433 و 5434).
"""

import pandas as pd
from sqlalchemy import create_engine

# ============================================
# Connections
# ============================================
SOURCE_CONN_STR = "postgresql+psycopg2://source_user:source_pass@localhost:5433/ecommerce_source"
WAREHOUSE_CONN_STR = "postgresql+psycopg2://warehouse_user:warehouse_pass@localhost:5434/ecommerce_warehouse"

source_engine = create_engine(SOURCE_CONN_STR)
warehouse_engine = create_engine(WAREHOUSE_CONN_STR)


# ============================================
# EXTRACT
# ============================================
def extract():
    print("Extracting from source_db...")
    customers = pd.read_sql("SELECT * FROM customers", source_engine)
    products = pd.read_sql("SELECT * FROM products", source_engine)
    orders = pd.read_sql("SELECT * FROM orders", source_engine)
    order_items = pd.read_sql("SELECT * FROM order_items", source_engine)
    print(f"  customers={len(customers)}, products={len(products)}, "
          f"orders={len(orders)}, order_items={len(order_items)}")
    return customers, products, orders, order_items


# ============================================
# TRANSFORM
# ============================================
def build_dim_date(orders: pd.DataFrame) -> pd.DataFrame:
    dates = pd.to_datetime(orders["order_date"]).dt.date.unique()
    df = pd.DataFrame({"full_date": dates})
    df["full_date"] = pd.to_datetime(df["full_date"])
    df["date_key"] = df["full_date"].dt.strftime("%Y%m%d").astype(int)
    df["day"] = df["full_date"].dt.day
    df["month"] = df["full_date"].dt.month
    df["month_name"] = df["full_date"].dt.strftime("%B")
    df["quarter"] = df["full_date"].dt.quarter
    df["year"] = df["full_date"].dt.year
    df["day_of_week"] = df["full_date"].dt.strftime("%A")
    df["is_weekend"] = df["full_date"].dt.dayofweek.isin([4, 5])  # Fri/Sat weekend (Egypt)
    return df[["date_key", "full_date", "day", "month", "month_name",
               "quarter", "year", "day_of_week", "is_weekend"]]


def build_dim_customer(customers: pd.DataFrame) -> pd.DataFrame:
    # First load: كل عميل بياخد صف واحد "current" بيبدأ من تاريخ الـ signup بتاعه
    df = customers.copy()
    df["valid_from"] = df["signup_date"]
    df["valid_to"] = None
    df["is_current"] = True
    return df[["customer_id", "full_name", "email", "city", "country",
               "signup_date", "valid_from", "valid_to", "is_current"]]


def build_dim_product(products: pd.DataFrame) -> pd.DataFrame:
    df = products.rename(columns={"unit_price": "current_price"})
    return df[["product_id", "product_name", "category", "current_price"]]


def build_fact(orders, order_items, dim_customer_loaded, dim_product_loaded) -> pd.DataFrame:
    # نضم order_items مع orders عشان ناخد التاريخ والحالة والعميل
    df = order_items.merge(orders, on="order_id", how="left")

    df["date_key"] = pd.to_datetime(df["order_date"]).dt.strftime("%Y%m%d").astype(int)
    df["line_total"] = df["quantity"] * df["unit_price"]

    # نربط بالـ surrogate keys اللي اتعملوا فعليًا في الـ warehouse بعد اللود
    df = df.merge(
        dim_customer_loaded[["customer_id", "customer_sk"]],
        on="customer_id", how="left"
    )
    df = df.merge(
        dim_product_loaded[["product_id", "product_sk"]],
        on="product_id", how="left"
    )

    df = df.rename(columns={"status": "order_status"})
    return df[["order_id", "date_key", "customer_sk", "product_sk",
               "order_status", "quantity", "unit_price", "line_total"]]


# ============================================
# LOAD
# ============================================
def truncate_warehouse():
    print("Truncating warehouse tables (fresh load)...")
    with warehouse_engine.begin() as conn:
        conn.exec_driver_sql("TRUNCATE TABLE fact_order_items RESTART IDENTITY CASCADE;")
        conn.exec_driver_sql("TRUNCATE TABLE dim_customer RESTART IDENTITY CASCADE;")
        conn.exec_driver_sql("TRUNCATE TABLE dim_product RESTART IDENTITY CASCADE;")
        conn.exec_driver_sql("TRUNCATE TABLE dim_date RESTART IDENTITY CASCADE;")


def load_dim(df: pd.DataFrame, table_name: str):
    df.to_sql(table_name, warehouse_engine, if_exists="append", index=False)
    print(f"  loaded {len(df)} rows into {table_name}")


def read_loaded(table_name: str, cols: str) -> pd.DataFrame:
    return pd.read_sql(f"SELECT {cols} FROM {table_name}", warehouse_engine)


# ============================================
# MAIN
# ============================================
def run():
    customers, products, orders, order_items = extract()

    dim_date = build_dim_date(orders)
    dim_customer = build_dim_customer(customers)
    dim_product = build_dim_product(products)

    truncate_warehouse()

    load_dim(dim_date, "dim_date")
    load_dim(dim_customer, "dim_customer")
    load_dim(dim_product, "dim_product")

    # نقرأ تاني بعد اللود عشان ناخد الـ surrogate keys اللي Postgres ولّدها (SERIAL)
    dim_customer_loaded = read_loaded("dim_customer", "customer_sk, customer_id")
    dim_product_loaded = read_loaded("dim_product", "product_sk, product_id")

    fact = build_fact(orders, order_items, dim_customer_loaded, dim_product_loaded)
    load_dim(fact, "fact_order_items")

    print("ETL finished successfully.")


if __name__ == "__main__":
    run()
