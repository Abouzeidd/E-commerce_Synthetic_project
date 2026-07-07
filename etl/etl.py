"""
Raw Load Script: source_db -> warehouse_db.staging

الوظيفة الوحيدة هنا: ناخد البيانات "زي ما هي" من الـ source
ونحطها في schema اسمها staging جوه الـ warehouse، من غير أي تحويل.

كل منطق الـ Transform (بناء dim_customer, dim_product, fact_order_items)
بقى مسؤولية dbt، مش بتاع السكريبت ده.
"""

import os
import pandas as pd
from sqlalchemy import create_engine

# ============================================
# Connections
# ============================================
SOURCE_HOST = os.getenv("SOURCE_DB_HOST", "localhost")
SOURCE_PORT = os.getenv("SOURCE_DB_PORT", "5433")
WAREHOUSE_HOST = os.getenv("WAREHOUSE_DB_HOST", "localhost")
WAREHOUSE_PORT = os.getenv("WAREHOUSE_DB_PORT", "5434")

SOURCE_CONN_STR = f"postgresql+psycopg2://source_user:source_pass@{SOURCE_HOST}:{SOURCE_PORT}/ecommerce_source"
WAREHOUSE_CONN_STR = f"postgresql+psycopg2://warehouse_user:warehouse_pass@{WAREHOUSE_HOST}:{WAREHOUSE_PORT}/ecommerce_warehouse"

source_engine = create_engine(SOURCE_CONN_STR)
warehouse_engine = create_engine(WAREHOUSE_CONN_STR)

TABLES = ["customers", "products", "orders", "order_items"]


def extract(table_name: str) -> pd.DataFrame:
    print(f"Extracting {table_name} from source_db...")
    df = pd.read_sql(f"SELECT * FROM {table_name}", source_engine)
    print(f"  {len(df)} rows")
    return df


def load_raw(df: pd.DataFrame, table_name: str):
    with warehouse_engine.begin() as conn:
        conn.exec_driver_sql(f"TRUNCATE TABLE staging.{table_name} RESTART IDENTITY CASCADE;")
    df.to_sql(table_name, warehouse_engine, schema="staging", if_exists="append", index=False)
    print(f"  loaded {len(df)} rows into staging.{table_name}")


def run():
    for table in TABLES:
        df = extract(table)
        load_raw(df, table)
    print("Raw load finished successfully. dbt will handle transformations from here.")


if __name__ == "__main__":
    run()
