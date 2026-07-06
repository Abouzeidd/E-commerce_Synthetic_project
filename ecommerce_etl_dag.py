"""
DAG بسيط: يشغّل سكريبت الـ ETL بتاعنا (source_db -> warehouse_db) مرة كل يوم.
"""
from datetime import datetime
import sys

from airflow import DAG
from airflow.operators.python import PythonOperator

# نضيف مسار الـ etl عشان نقدر نستورد الدالة run() من etl.py
sys.path.insert(0, "/opt/airflow/etl")
from etl import run as run_etl  # noqa: E402


default_args = {
    "owner": "abdelrahman",
    "retries": 1,
}

with DAG(
    dag_id="ecommerce_etl_pipeline",
    description="Extract from source_db, transform to Star Schema, load into warehouse_db",
    default_args=default_args,
    start_date=datetime(2026, 1, 1),
    schedule="@daily",   # يتشغل مرة كل يوم - تقدر تغيرها لـ None عشان تشغله يدويًا بس
    catchup=False,       # منشغّلش كل الأيام اللي فاتت، بس من دلوقتي
    tags=["ecommerce", "etl"],
) as dag:

    run_etl_task = PythonOperator(
        task_id="run_etl",
        python_callable=run_etl,
    )
