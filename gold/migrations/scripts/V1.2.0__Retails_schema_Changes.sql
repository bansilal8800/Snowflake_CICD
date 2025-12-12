-- ============================================================================
-- Snowflake DDL: Domain Tables (Order, Customer, Product) with Views
-- ============================================================================
-- Database and Schema Setup
-- ============================================================================

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

-- Customer Dimension Table
CREATE TABLE IF NOT EXISTS {{ database_name }}.{{ sf_schema }}.CUSTOMER (
    CUSTOMER_ID NUMBER(10,0) NOT NULL PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(255) NOT NULL,
    EMAIL VARCHAR(255),
    PHONE VARCHAR(20),
    COUNTRY VARCHAR(100),
    STATE VARCHAR(100),
    CITY VARCHAR(100),
    ZIP_CODE VARCHAR(20),
    CUSTOMER_SEGMENT VARCHAR(50),
    REGISTRATION_DATE DATE,
    LAST_PURCHASE_DATE DATE,
    TOTAL_LIFETIME_VALUE NUMBER(15,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    IS_ACTIVE BOOLEAN DEFAULT TRUE
)
COMMENT = 'Customer dimension table - contains customer master data'
CLUSTER BY (CUSTOMER_SEGMENT);
