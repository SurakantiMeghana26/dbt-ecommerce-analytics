\# dbt E-Commerce Analytics Pipeline



A complete data warehouse implementation using dbt and Snowflake for Brazilian e-commerce analytics. This project demonstrates dimensional modeling, medallion architecture, and modern data engineering best practices.



\---



\## Project Overview



This project transforms raw Brazilian e-commerce data (\~550K rows across 8 source tables) into a business-ready dimensional data warehouse using a 3-layer medallion architecture (Raw → Staging → Marts).



\### Key Achievements



\- Built 14 dbt models with calculated business metrics

\- Implemented Kimball star schema with 4 dimensions and 2 facts

\- Processed 550,000+ rows of real e-commerce data

\- Applied business logic (customer segmentation, seller tiering)

\- Created bilingual product categories (Portuguese/English)

\- Generated comprehensive date dimension (4,000+ dates)

\- Followed software engineering best practices (Git, testing, documentation)



\---



\## Architecture



\### Medallion Architecture (3-Layer)



The project follows a 3-layer medallion architecture:



\*\*Layer 1: RAW (Bronze)\*\*

\- 8 source tables from Kaggle Olist dataset

\- Original CSV data loaded into Snowflake



\*\*Layer 2: STAGING (Silver)\*\*

\- 8 cleaned views with standardization

\- Data type conversions, null handling, calculated columns



\*\*Layer 3: MARTS (Gold)\*\*

\- Star schema for analytics

\- 4 Dimension tables

\- 2 Fact tables (different grains)



\---



\## Star Schema Design



The project implements a Kimball star schema with 4 dimensions and 2 fact tables at different grains.



\### Dimensions



| Table | Description | Rows |

|-------|-------------|------|

| dim\_customers | Customer info with VIP/Repeat segmentation | 99,441 |

| dim\_products | Products with bilingual categories | 32,951 |

| dim\_sellers | Sellers with revenue tiers | 3,095 |

| dim\_dates | Date dimension 2016-2026 | 4,018 |



\### Facts



| Table | Grain | Description | Rows |

|-------|-------|-------------|------|

| fact\_orders | One row per order | Order-level metrics | 99,441 |

| fact\_order\_items | One row per item | Item-level details | 112,650 |



\### Why Two Fact Tables?



The fact\_orders table has one row per order with order-level metrics like total amount, status, and delivery info.



The fact\_order\_items table has one row per item with item-level details like product, seller, and price.



This separation follows Kimball's dimensional modeling best practices for handling header-line item patterns, prevents data duplication, and allows correct counts at each grain.



\---



\## Tech Stack



| Layer | Technology |

|-------|------------|

| Data Warehouse | Snowflake |

| Transformation | dbt (data build tool) |

| Data Loading | Python (snowflake-connector-python) |

| Version Control | Git + GitHub |

| Language | SQL + Jinja templating |



\---



\## Project Structure



```

dbt-ecommerce-analytics/

├── data/                              # Source CSV files (8 datasets)

├── dbt\_project/

│   └── ecommerce\_analytics/

│       ├── models/

│       │   ├── staging/                # 8 staging models

│       │   └── marts/                  # 6 dimensional models

│       ├── macros/                     # Reusable code

│       └── dbt\_project.yml

├── src/                                # Python loading script

│   └── load\_data\_to\_snowflake.py

├── .gitignore

├── LICENSE

└── README.md

```



\---



\## Setup Instructions



\### Prerequisites



\- Python 3.10+

\- Snowflake account

\- dbt-core and dbt-snowflake installed



\### Step 1: Clone the Repository



```

git clone https://github.com/SurakantiMeghana26/dbt-ecommerce-analytics.git

cd dbt-ecommerce-analytics

```



\### Step 2: Install Dependencies



```

pip install snowflake-connector-python pandas

pip install dbt-snowflake

```



\### Step 3: Set Up Snowflake



```

USE ROLE ACCOUNTADMIN;

CREATE DATABASE ECOMMERCE\_ANALYTICS;

CREATE SCHEMA RAW\_DATA;

CREATE SCHEMA STAGING;

CREATE SCHEMA MARTS;

CREATE SCHEMA SNAPSHOTS;

```



\### Step 4: Load Raw Data



Set environment variables for security:



```

export SNOWFLAKE\_USER='your\_username'

export SNOWFLAKE\_PASSWORD='your\_password'

```



Run the loading script:



```

python src/load\_data\_to\_snowflake.py

```



\### Step 5: Run dbt



```

cd dbt\_project/ecommerce\_analytics

dbt debug

dbt run

dbt test

dbt docs generate

dbt docs serve

```



\---



\## Models Documentation



\### Staging Layer (8 models)



| Model | Description |

|-------|-------------|

| stg\_customers | Cleaned customer info with UPPERCASE locations |

| stg\_orders | Orders with proper timestamps, delivery metrics |

| stg\_order\_items | Items with calculated total costs |

| stg\_payments | Payments with categorization |

| stg\_reviews | Reviews with sentiment analysis |

| stg\_products | Products with size categories |

| stg\_sellers | Sellers with clean location data |

| stg\_category\_translations | PT to EN category mappings |



\### Marts Layer (6 models)



| Model | Type | Description |

|-------|------|-------------|

| dim\_customers | Dimension | Customers with segmentation (VIP/Repeat/One-time) |

| dim\_products | Dimension | Products with bilingual categories \& quality scores |

| dim\_sellers | Dimension | Sellers with sales metrics \& tiers |

| dim\_dates | Dimension | Date dimension (2016-2026) |

| fact\_orders | Fact | Order-level metrics with FKs |

| fact\_order\_items | Fact | Item-level details, joins all dimensions |



\---



\## Sample Queries



\### 1. Top Product Categories by Revenue



```

SELECT 

&#x20;   p.category\_en,

&#x20;   COUNT(DISTINCT foi.order\_id) AS total\_orders,

&#x20;   SUM(foi.item\_price) AS total\_revenue,

&#x20;   AVG(foi.item\_price) AS avg\_price

FROM marts.fact\_order\_items foi

JOIN marts.dim\_products p ON foi.product\_key = p.product\_key

GROUP BY p.category\_en

ORDER BY total\_revenue DESC

LIMIT 10;

```



\### 2. Customer Segment Analysis



```

SELECT 

&#x20;   customer\_segment,

&#x20;   COUNT(\*) AS customer\_count,

&#x20;   AVG(total\_orders) AS avg\_orders

FROM marts.dim\_customers

GROUP BY customer\_segment

ORDER BY customer\_count DESC;

```



\### 3. Monthly Sales Trends



```

SELECT 

&#x20;   d.year,

&#x20;   d.month\_name,

&#x20;   COUNT(DISTINCT fo.order\_key) AS orders,

&#x20;   SUM(fo.order\_total) AS revenue

FROM marts.fact\_orders fo

JOIN marts.dim\_dates d ON fo.order\_date\_key = d.date\_key

GROUP BY d.year, d.month\_name, d.month

ORDER BY d.year, d.month;

```



\### 4. Top Sellers by State



```

SELECT 

&#x20;   s.seller\_state,

&#x20;   COUNT(\*) AS seller\_count,

&#x20;   SUM(s.total\_revenue) AS state\_revenue

FROM marts.dim\_sellers s

WHERE s.is\_active = TRUE

GROUP BY s.seller\_state

ORDER BY state\_revenue DESC

LIMIT 10;

```



\---



\## Key Business Insights Enabled



This data warehouse enables answers to questions like:



\- Customer Analytics: Who are our VIP customers? What is our retention rate?

\- Revenue Analysis: Which products/sellers/categories drive the most revenue?

\- Delivery Performance: What is our on-time delivery rate? Where do delays happen?

\- Geographic Insights: Which states/cities are our biggest markets?

\- Product Quality: Which products need better descriptions or photos?

\- Payment Patterns: How do customers prefer to pay? Installment usage?



\---



\## Key Learnings and dbt Features Used



\### dbt Concepts Demonstrated



\- Models - SQL files for transformations

\- Sources - YAML configuration for raw data

\- ref() function - Automatic dependency tracking

\- source() function - Reference raw data

\- Materializations - Views (staging) vs Tables (marts)

\- CTEs - Modular, readable SQL

\- Jinja templating - Dynamic SQL generation

\- Custom Macros - Reusable code (schema generation)

\- YAML configuration - dbt\_project.yml setup

\- Built-in tests - not\_null, unique on source columns



\### Data Engineering Best Practices



\- Medallion Architecture (Raw to Staging to Marts)

\- Dimensional Modeling (Kimball star schema)

\- Surrogate Keys for dimensions

\- Slowly Changing Dimensions (Type 1)

\- Aggregation before joining (avoid row explosion)

\- Business logic in transformation layer

\- Idempotent transformations

\- Version control with Git



\---



\## Data Source



\- Dataset: Brazilian E-Commerce Public Dataset by Olist on Kaggle

\- Provider: Olist (largest Brazilian marketplace)

\- Period: 2016-2018

\- Volume: \~100,000 orders, 550,000+ total rows



\---



\## Future Enhancements



\- Implement Snapshots for SCD Type 2 (track customer location changes)

\- Add Seeds for reference data (state regions, category groupings)

\- Build more custom macros for reusable transformations

\- Add custom data quality tests

\- Implement incremental models for large facts

\- Set up CI/CD with GitHub Actions

\- Create dbt exposures for dashboard documentation

\- Add source freshness checks



\---



\## Author



Surakanti Meghana



