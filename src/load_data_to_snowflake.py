"""
Load Kaggle E-commerce CSV files to Snowflake
==============================================
Loads all 8 CSV files into Snowflake RAW_DATA schema.
"""

import os
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas

# Snowflake credentials
SNOWFLAKE_CONFIG = {
    'user': 'SURAKANTIMEGHANA',           # CHANGE if different!
    'password': 'YOUR_PASSWORD_HERE',     # CHANGE THIS!
    'account': 'ii34460.us-east-2.aws',
    'warehouse': 'COMPUTE_WH',
    'database': 'ECOMMERCE_ANALYTICS',
    'schema': 'RAW_DATA',
    'role': 'ACCOUNTADMIN'
}

# Path to data folder
DATA_FOLDER = r'C:\Users\kirit\Desktop\dbt-ecommerce-analytics\data'

# File to table name mapping
FILES_TO_LOAD = {
    'olist_customers_dataset.csv': 'raw_customers',
    'olist_orders_dataset.csv': 'raw_orders',
    'olist_order_items_dataset.csv': 'raw_order_items',
    'olist_order_payments_dataset.csv': 'raw_payments',
    'olist_order_reviews_dataset.csv': 'raw_reviews',
    'olist_products_dataset.csv': 'raw_products',
    'olist_sellers_dataset.csv': 'raw_sellers',
    'product_category_name_translation.csv': 'raw_category_translations'
}


def load_csv_to_snowflake(csv_path, table_name, conn):
    """Load a CSV file to Snowflake table."""
    print(f"\n📂 Loading {csv_path}...")
    
    # Read CSV
    df = pd.read_csv(csv_path)
    print(f"   ✅ Read {len(df)} rows, {len(df.columns)} columns")
    
    # Clean column names (uppercase for Snowflake)
    df.columns = [col.upper() for col in df.columns]
    
    # Write to Snowflake
    success, num_chunks, num_rows, _ = write_pandas(
        conn=conn,
        df=df,
        table_name=table_name.upper(),
        auto_create_table=True,
        overwrite=True
    )
    
    if success:
        print(f"   ✅ Loaded {num_rows} rows into {table_name}")
    else:
        print(f"   ❌ Failed to load {table_name}")
    
    return success


def main():
    """Main function to load all CSV files."""
    print("=" * 60)
    print("🚀 LOADING KAGGLE DATA TO SNOWFLAKE")
    print("=" * 60)
    
    # Connect to Snowflake
    print("\n🔌 Connecting to Snowflake...")
    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    print("   ✅ Connected!")
    
    # Load each file
    success_count = 0
    for filename, table_name in FILES_TO_LOAD.items():
        csv_path = os.path.join(DATA_FOLDER, filename)
        
        if os.path.exists(csv_path):
            if load_csv_to_snowflake(csv_path, table_name, conn):
                success_count += 1
        else:
            print(f"\n⚠️ File not found: {csv_path}")
    
    # Summary
    print("\n" + "=" * 60)
    print(f"✅ COMPLETE! Loaded {success_count}/{len(FILES_TO_LOAD)} files")
    print("=" * 60)
    
    conn.close()


if __name__ == "__main__":
    main()