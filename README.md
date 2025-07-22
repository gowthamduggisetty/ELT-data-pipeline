# ELT Pipeline with dbt, Snowflake, and Airflow

This project demonstrates how to build an **Extract, Load, Transform (ELT)** data pipeline from scratch. It leverages **Snowflake** for data warehousing, **dbt (data build tool)** for data transformation, and **Apache Airflow** for orchestration.

The ELT approach is favored in modern data architectures due to the reduced cost of cloud storage, allowing raw data to be loaded into a data warehouse first and transformed later.

## 🚀 Key Technologies Used

*   **Snowflake**: A cloud data platform used as the data warehouse for storing and analyzing data.
*   **dbt (data build tool)**: Utilized for defining and executing data transformations within Snowflake, enabling modular and testable data models. We specifically use **dbt Core** for local development.
*   **Apache Airflow**: An open-source platform to programmatically author, schedule, and monitor workflows. It orchestrates the dbt models in this pipeline.
*   **Astronomer Cosmos**: A library that simplifies running dbt Core projects within Airflow DAGs and task groups.
*   **dbt-utils**: A common dbt package used for utility functions like creating surrogate keys.

## ✨ Project Features

This pipeline covers:
*   **ELT Process**: Extracting data, loading it into Snowflake, and then transforming it using dbt.
*   **Basic Data Modeling**: Building `staging` models, `marts` models, and `fact tables`.
*   **Snowflake RBAC**: Setting up roles and permissions within Snowflake for secure access.
*   **Data Transformation**: Applying business logic and aggregations to raw data.
*   **Reusable Logic with Macros**: Creating dbt macros to template and reuse SQL logic across multiple models.
*   **Data Testing**: Implementing both **generic tests** (e.g., `unique`, `not_null`, `relationships`, `accepted_values`) and **singular tests** (custom SQL queries) to ensure data quality.
*   **Pipeline Orchestration**: Deploying and scheduling the dbt models using Airflow with Astronomer Cosmos.

## 🛠️ Setup and Installation

Follow these steps to set up the project locally.

### Prerequisites

*   A **Snowflake personal account**.
*   **Python 3.x** and `pip` for dbt Core installation.
*   **Astro CLI** for Airflow local development (`brew install astro` on macOS).
*   A code editor (VS Code).

### 1. Configure Snowflake Environment

First, set up your Snowflake warehouse, database, and role. You will need to use the `accountadmin` role initially for these setup steps.

1.  **Log in to Snowflake** with `accountadmin` role.
2.  **Create a Warehouse**:
    ```sql
    USE ROLE ACCOUNTADMIN;
    CREATE WAREHOUSE DBT_WAREHOUSE WITH WAREHOUSE_SIZE = 'XSMALL';
    ```
   
3.  **Create a Database**:
    ```sql
    CREATE DATABASE DBT_DB;
    ```
   
4.  **Create a Role**:
    ```sql
    CREATE ROLE DBT_ROLE;
    ```
   
5.  **Grant Usage on Warehouse to Role**:
    ```sql
    GRANT USAGE ON WAREHOUSE DBT_WAREHOUSE TO ROLE DBT_ROLE;
    ```
   
6.  **Grant Access on Database to Role**:
    ```sql
    GRANT ALL ON DATABASE DBT_DB TO ROLE DBT_ROLE;
    ```
   
7.  **Grant Role to Your User**: Replace `YOUR_SNOWFLAKE_USER` with your actual Snowflake username.
    ```sql
    GRANT ROLE DBT_ROLE TO USER YOUR_SNOWFLAKE_USER;
    ```
   
8.  **Create a Schema**: Switch to the new role and database, then create the schema.
    ```sql
    USE ROLE DBT_ROLE;
    USE DATABASE DBT_DB;
    CREATE SCHEMA DBT_SCHEMA;
    ```
   

    *(Optional: To avoid re-creation errors, you can use `CREATE WAREHOUSE IF NOT EXISTS`, `CREATE DATABASE IF NOT EXISTS`, etc.)*

### 2. Set Up dbt Project

1.  **Install dbt Core**:
    ```bash
    pip install dbt-core dbt-snowflake
    ```
    *(You can also use `pip install dbt-snowflake` directly or Homebrew)*
2.  **Initialize dbt Project**:
    Navigate to your desired project directory and run:
    ```bash
    dbt init data_pipeline
    cd data_pipeline
    ```
   
3.  **Configure dbt Profile**: During `dbt init`, you'll be prompted to configure your Snowflake profile. Use the following details:
    *   **Database**: `snowflake`
    *   **Account**: Your Snowflake account locator (e.g., `xyz1234.us-east-1`).
    *   **User**: Your Snowflake username.
    *   **Password**: Your Snowflake password.
    *   **Role**: `DBT_ROLE`.
    *   **Warehouse**: `DBT_WAREHOUSE`.
    *   **Database**: `DBT_DB`.
    *   **Schema**: `DBT_SCHEMA`.
    *   **Threads**: `10` (recommended).

4.  **Configure `dbt_project.yml`**:
    Open the `dbt_project.yml` file in your `data_pipeline` directory.
    *   Set up model materialization: `staging` models as `views` and `marts` models as `tables`.
    *   Define the Snowflake warehouse for models (e.g., `DBT_WAREHOUSE`).
    *   Delete the example models and create `staging` and `marts` folders inside `models/`.

5.  **Install dbt Packages**:
    Create a `packages.yml` file at the root of your `data_pipeline` directory:
    ```yaml
    # packages.yml
    packages:
      - package: dbt-labs/dbt_utils
        version: 1.1.1 # Use the latest stable version
    ```
    Then, install the packages:
    ```bash
    dbt deps
    ```
   

### 3. Set Up Airflow for Orchestration

1.  **Initialize Astro Project**:
    Outside your `data_pipeline` directory, create a new directory for your Airflow project and initialize it:
    ```bash
    mkdir dbt_dag
    cd dbt_dag
    astro dev init
    ```
   
2.  **Update Dockerfile**:
    Add `pip install dbt-snowflake` to the `Dockerfile` in your `dbt_dag` directory (e.g., at the bottom).
3.  **Update `requirements.txt`**:
    Add the following lines to `requirements.txt` in your `dbt_dag` directory:
    ```
    astronomer-cosmos
    apache-airflow-providers-snowflake
    ```
4.  **Start Airflow (Astro Dev)**:
    ```bash
    astro dev start
    ```
   
    This will start Airflow and its components in Docker containers. Access the Airflow UI at `http://localhost:8080` (username: `admin`, password: `admin`).
5.  **Copy dbt Project to Airflow DAGs Folder**:
    Copy your `data_pipeline` dbt project folder into the `dags` folder of your `dbt_dag` Airflow project.
    ```bash
    cp -r ../data_pipeline ./dags/
    ```
    *(Adjust path based on your project structure)*
6.  **Create Airflow DAG File**:
    Inside the `dags` folder (or a subfolder), create a Python file (e.g., `dbt_pipeline_dag.py`) for your Airflow DAG. This file will use Astronomer Cosmos to define your dbt tasks. The provided code snippet in the source sets up the connection and points to the dbt project directory.

7.  **Configure Airflow Snowflake Connection**:
    In the Airflow UI (`http://localhost:8080`):
    *   Go to **Admin > Connections**.
    *   Click **+ New record**.
    *   Set **Conn Id**: `snowflake_con`.
    *   Set **Conn Type**: `Snowflake`.
    *   Fill in your Snowflake **Account**, **Warehouse** (`DBT_WAREHOUSE`), **Database** (`DBT_DB`), **Role** (`DBT_ROLE`), **Login** (username), and **Password**.
    *   Click **Save**.


## 📊 Data Sources and Modeling

This project utilizes the **Snowflake TPCH data set**, a free dataset provided by Snowflake, specifically the `orders` and `lineitem` tables from `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1`.

### Staging Models
Staging models (`staging/`) are directly mapped to source tables with minimal transformations, primarily focused on renaming columns for clarity and consistency. They are materialized as **views**.

### Fact Tables and Dimensional Modeling
The project builds a `fact table` (`fct_orders`) which is a core concept in dimensional modeling. Fact tables store numeric measures produced by operational measurements and contain foreign keys to associated dimensional tables. **Surrogate keys** are used to connect fact and dimensional tables effectively. For instance, `dbt_utils.surrogate_key` is used to create unique identifiers for joins.

## ✅ Testing

dbt supports two main types of tests to ensure data quality:

*   **Generic Tests**: Pre-defined, parameterized tests often used in `.yml` files. Examples include:
    *   `unique`: Checks for uniqueness of a column.
    *   `not_null`: Checks for non-null values.
    *   `relationships`: Validates foreign key relationships between models.
    *   `accepted_values`: Ensures a column contains only a specific set of values.
*   **Singular Tests**: Custom SQL queries written in `.sql` files that return failing rows if a condition is met. If the query returns any rows, the test fails. Examples include checking if a `discount_amount` is always greater than zero or if `order_date` falls within an acceptable range.

Tests can be run with `dbt test`.

## ⚙️ Running the Project

### Running dbt Models and Tests

To run all your dbt models and tests locally:
```bash
dbt run
dbt test
```


You can also run specific models or tests:
```bash
dbt run --select staging_tpch_line_items # Run a specific model
dbt test --select fact_orders_discount # Run a specific test
```

### Running Airflow DAG

1.  Ensure Airflow is running: `astro dev start`.
2.  Access the Airflow UI at `http://localhost:8080`.
3.  Locate the `DBT_DAG_ID` (or whatever you named your dbt DAG in the Python file).
4.  Toggle the DAG to "On" and then click the "Trigger DAG" button to initiate a run.
5.  Monitor the execution and logs in the Airflow UI. You can observe how Cosmos creates a graph showing the dependencies between your dbt models.


## 🙏 Acknowledgments

This project is based on the "ELT Pipeline(dbt, Snowflake, Airflow)" tutorial by "jayzern" on YouTube. The tutorial provides a comprehensive, hands-on guide for setting up and deploying an ELT pipeline
