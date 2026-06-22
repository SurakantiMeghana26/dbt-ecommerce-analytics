# 🛒 dbt E-Commerce Analytics Pipeline

> **A complete data warehouse implementation using dbt and Snowflake**

Building a production-grade dimensional data warehouse for Brazilian e-commerce analytics — transforming 550K+ rows of raw data into business-ready insights.

---

## 🎯 What I Built

### The Numbers

| Metric | Value |
|--------|-------|
| **Total Models** | 14 |
| **Source Rows** | ~550,000 |
| **Dimensions** | 4 |
| **Fact Tables** | 2 |
| **Architecture Layers** | 3 (Bronze → Silver → Gold) |
| **dbt Features Used** | 10+ |

### The Pipeline

**Raw Data (Bronze)** → **Cleaned Staging (Silver)** → **Business Marts (Gold)**

Transforming raw CSV files from Kaggle's Olist dataset into a queryable star schema warehouse, applying business logic at every layer.

---

## 🏗️ Architecture

### 3-Layer Medallion Architecture

**🥉 LAYER 1: RAW (Bronze)**
- 8 source tables loaded from Kaggle CSV files
- Loaded via Python script using snowflake-connector
- ~550,000 total rows
- Schema: `RAW_DATA`

**🥈 LAYER 2: STAGING (Silver)**
- 8 cleaned views with standardization
- Data type conversions (strings → timestamps, decimals)
- Null handling with COALESCE
- Calculated columns (delivery_days, total_costs)
- Schema: `STAGING`

**🥇 LAYER 3: MARTS (Gold)**
- 4 dimension tables + 2 fact tables
- Kimball star schema design
- Surrogate keys for dimensions
- Aggregated business metrics
- Schema: `MARTS`

---
## ⭐ Star Schema Data Model

### Schema Diagram

The star schema connects fact tables in the center to dimension tables around them:

     ┌────────────────────┐
                │   dim_customers    │
                │     (99,441)       │
                └─────────┬──────────┘
                          │
                          │ FK
                          ▼
                          ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐

│   dim_products   │  │ fact_orders  │  │   dim_sellers    │

│     (32,951)     │◄─│   (99,441)   │─►│     (3,095)      │

└─────────┬────────┘  └──────┬───────┘  └─────────┬────────┘

│                  │                    │

│                  │ 1:N                │

│                  ▼                    │

│     ┌─────────────────────┐          │

└────►│  fact_order_items   │◄─────────┘

│      (112,650)      │

└──────────┬──────────┘

│

│ FK

▼

┌────────────────────┐

│    dim_dates       │

│      (4,018)       │

└────────────────────┘

### Relationships

- **fact_orders** → links to dim_customers and dim_dates
- **fact_order_items** → links to dim_products, dim_sellers, dim_dates, and fact_orders
- All foreign keys use surrogate keys (integers) for fast joins

### Dimension Tables

| Dimension | Purpose | Key Features |
|-----------|---------|--------------|
| **dim_customers** | Customer profiles | VIP/Repeat/One-time segmentation, total orders, recency |
| **dim_products** | Product catalog | Bilingual categories (PT/EN), size category, description quality |
| **dim_sellers** | Seller info | Sales metrics, revenue tiers (Top/High/Medium/Low) |
| **dim_dates** | Time dimension | Year, quarter, month, weekday flags, 11 years coverage |

### Fact Tables

| Fact | Grain | Description |
|------|-------|-------------|
| **fact_orders** | One row per order | Order status, total amount, delivery metrics |
| **fact_order_items** | One row per item | Individual items, prices, freight, price tiers |

### Why Two Fact Tables?

Following **Kimball's dimensional modeling**, we separate facts by grain:

- **Order grain** answers: "How many orders? Average order value?"
- **Item grain** answers: "Which products sell best? Top sellers?"

This prevents data duplication and enables correct counting at each level.

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| **Data Warehouse** | ❄️ Snowflake |
| **Transformation** | 🔧 dbt 1.11 |
| **Data Loading** | 🐍 Python + snowflake-connector |
| **Source Data** | 📊 Kaggle Olist E-commerce Dataset |
| **Version Control** | 📚 Git + GitHub |
| **Language** | 💻 SQL + Jinja |

---

## 📊 Business Insights Enabled

This warehouse enables analytics like:

### Customer Insights
- 🎯 **Customer segmentation** by purchase frequency
- 💰 **Lifetime value** calculation
- 📍 **Geographic distribution** of customers
- ⏱️ **Recency analysis** (days since last order)

### Product Insights
- 📈 **Top categories** by revenue
- 📏 **Product size distribution**
- 📝 **Description quality** assessment
- 📸 **Catalog completeness** (photos, descriptions)

### Seller Insights
- 🏆 **Seller tiering** (Top/High/Medium/Low)
- 💵 **Revenue per seller**
- 🌎 **Geographic concentration** of sellers
- 📦 **Items sold per seller**

### Order Insights
- 🚚 **Delivery performance** (on-time vs late)
- 💳 **Payment patterns** (card vs installment)
- 📦 **Order size distribution**
- 📅 **Time-based trends**

---

## 🔍 Sample Analytics Queries

### Top 10 Product Categories by Revenue

```sql
SELECT 
    p.category_en,
    COUNT(DISTINCT foi.order_id) AS total_orders,
    SUM(foi.item_price) AS total_revenue,
    AVG(foi.item_price) AS avg_price
FROM marts.fact_order_items foi
JOIN marts.dim_products p 
    ON foi.product_key = p.product_key
GROUP BY p.category_en
ORDER BY total_revenue DESC
LIMIT 10;
```

### Customer Segment Distribution

```sql
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    AVG(total_orders) AS avg_orders
FROM marts.dim_customers
GROUP BY customer_segment
ORDER BY customer_count DESC;
```

### Delivery Performance by State

```sql
SELECT 
    c.customer_state,
    COUNT(*) AS total_orders,
    AVG(fo.delivery_days) AS avg_delivery_days,
    SUM(CASE WHEN fo.delivered_on_time THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS on_time_pct
FROM marts.fact_orders fo
JOIN marts.dim_customers c 
    ON fo.customer_key = c.customer_key
WHERE fo.delivery_days IS NOT NULL
GROUP BY c.customer_state
ORDER BY total_orders DESC;
```

---

## 🎓 dbt Features Demonstrated

### Core Concepts
- ✅ **Models** - SQL transformations in modular files
- ✅ **Sources** - YAML configuration for raw data references
- ✅ **ref()** function - Automatic dependency tracking
- ✅ **source()** function - Raw data references
- ✅ **Materializations** - Strategic use of views (staging) vs tables (marts)
- ✅ **CTEs** - Modular, readable SQL with WITH clauses
- ✅ **Jinja templating** - Dynamic SQL generation

### Advanced Features
- ✅ **Custom Macros** - Reusable code (custom schema generation)
- ✅ **YAML configuration** - Project-level dbt_project.yml
- ✅ **Built-in tests** - not_null, unique on source columns
- ✅ **Schema management** - Clean schema naming via macros

---

## 🎯 Key Engineering Decisions

### 1. Why Snowflake?
- ✅ Cloud-native, no infrastructure to manage
- ✅ Separation of storage and compute
- ✅ Pay-per-use pricing
- ✅ Industry standard for modern data stack

### 2. Why dbt?
- ✅ SQL-first transformations
- ✅ Built-in testing framework
- ✅ Automatic documentation
- ✅ Git-friendly workflow
- ✅ Industry standard tool

### 3. Why Star Schema?
- ✅ Fast analytical queries
- ✅ Simple for business users to understand
- ✅ Optimized for BI tools
- ✅ Industry standard (Kimball methodology)

### 4. Why Surrogate Keys?
- ✅ Faster joins (integer vs UUID)
- ✅ Independent of source system changes
- ✅ Cleaner relationships
- ✅ Data warehouse best practice

### 5. Why Two Fact Tables?
- ✅ Different grains (order vs item)
- ✅ No data duplication
- ✅ Correct counts at each level
- ✅ Cleaner analytical queries

---

## 📁 Data Source

**[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)**

- 📅 **Period:** 2016-2018
- 📊 **Volume:** ~100,000 orders, 550,000+ total rows
- 🌎 **Geography:** Brazilian e-commerce marketplace
- 🏢 **Provider:** Olist (largest Brazilian marketplace)
- 🎮 **Note:** Anonymized data with Game of Thrones house names

---

## 🔮 Future Enhancements

- [ ] **Snapshots (SCD Type 2)** - Track customer location changes over time
- [ ] **Seeds** - Add reference data (state regions, category groupings)
- [ ] **More Macros** - Reusable transformations across models
- [ ] **Custom Tests** - Beyond not_null/unique
- [ ] **Incremental Models** - For large fact tables
- [ ] **CI/CD Pipeline** - Automated testing with GitHub Actions
- [ ] **dbt Exposures** - Document downstream BI dashboards
- [ ] **Source Freshness** - Monitor data lag
- [ ] **dbt Docs** - Generate beautiful auto-documentation

---

## 👨‍💻 About the Author

**Surakanti Meghana**
- 📍 Dublin, Ohio
- 💼 Data Engineer
- 🎓 Specializing in modern data stack (Snowflake, dbt, Python)

---

