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

-- Product Dimension Table
CREATE TABLE IF NOT EXISTS {{ database_name }}.{{ sf_schema }}.PRODUCT (
    PRODUCT_ID NUMBER(10,0) NOT NULL PRIMARY KEY,
    PRODUCT_NAME VARCHAR(255) NOT NULL,
    CATEGORY VARCHAR(100),
    SUBCATEGORY VARCHAR(100),
    BRAND VARCHAR(100),
    UNIT_PRICE NUMBER(12,2) NOT NULL,
    COST_PRICE NUMBER(12,2),
    SUPPLIER_ID NUMBER(10,0),
    SKU VARCHAR(50) UNIQUE,
    DESCRIPTION VARCHAR(1000),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    IS_ACTIVE BOOLEAN DEFAULT TRUE
)
COMMENT = 'Product dimension table - contains product master data'
CLUSTER BY (CATEGORY, SUBCATEGORY);

-- ============================================================================
-- FACT TABLES
-- ============================================================================

-- Order Fact Table
CREATE TABLE IF NOT EXISTS {{ database_name }}.{{ sf_schema }}.ORDER (
    ORDER_ID NUMBER(15,0) NOT NULL PRIMARY KEY,
    CUSTOMER_ID NUMBER(10,0) NOT NULL,
    ORDER_DATE DATE NOT NULL,
    ORDER_TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    DELIVERY_DATE DATE,
    ORDER_STATUS VARCHAR(50),
    TOTAL_AMOUNT NUMBER(15,2) NOT NULL,
    TAX_AMOUNT NUMBER(15,2),
    DISCOUNT_AMOUNT NUMBER(15,2),
    SHIPPING_AMOUNT NUMBER(15,2),
    NET_AMOUNT NUMBER(15,2) NOT NULL,
    PAYMENT_METHOD VARCHAR(50),
    PAYMENT_STATUS VARCHAR(50),
    SHIPPING_ADDRESS VARCHAR(500),
    NOTES VARCHAR(1000),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (CUSTOMER_ID) REFERENCES {{ database_name }}.{{ sf_schema }}.CUSTOMER(CUSTOMER_ID)
)
COMMENT = 'Order fact table - contains transactional order data'
CLUSTER BY (CUSTOMER_ID, ORDER_DATE);

-- Order Line Items Table
CREATE TABLE IF NOT EXISTS {{ database_name }}.{{ sf_schema }}.ORDER_LINE_ITEM (
    LINE_ITEM_ID NUMBER(15,0) NOT NULL PRIMARY KEY,
    ORDER_ID NUMBER(15,0) NOT NULL,
    PRODUCT_ID NUMBER(10,0) NOT NULL,
    QUANTITY NUMBER(10,2) NOT NULL,
    UNIT_PRICE NUMBER(12,2) NOT NULL,
    LINE_TOTAL NUMBER(15,2) NOT NULL,
    DISCOUNT_PERCENT NUMBER(5,2),
    DISCOUNT_AMOUNT NUMBER(15,2),
    NET_LINE_AMOUNT NUMBER(15,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (ORDER_ID) REFERENCES {{ database_name }}.{{ sf_schema }}.ORDER(ORDER_ID),
    FOREIGN KEY (PRODUCT_ID) REFERENCES {{ database_name }}.{{ sf_schema }}.PRODUCT(PRODUCT_ID)
)
COMMENT = 'Order line items - contains detailed product items per order'
CLUSTER BY (ORDER_ID, PRODUCT_ID);

-- ============================================================================
-- ANALYTICS VIEWS
-- ============================================================================

-- Customer Summary View
CREATE OR REPLACE VIEW {{ database_name }}.{{ sf_schema }}.V_CUSTOMER_SUMMARY AS
SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.EMAIL,
    C.COUNTRY,
    C.CUSTOMER_SEGMENT,
    COUNT(DISTINCT O.ORDER_ID) AS TOTAL_ORDERS,
    SUM(O.NET_AMOUNT) AS TOTAL_SPEND,
    AVG(O.NET_AMOUNT) AS AVERAGE_ORDER_VALUE,
    MAX(O.ORDER_DATE) AS LAST_ORDER_DATE,
    MIN(O.ORDER_DATE) AS FIRST_ORDER_DATE,
    DATEDIFF(DAY, MIN(O.ORDER_DATE), MAX(O.ORDER_DATE)) AS CUSTOMER_TENURE_DAYS,
    C.IS_ACTIVE
FROM
    {{ database_name }}.{{ sf_schema }}.CUSTOMER C
    LEFT JOIN {{ database_name }}.{{ sf_schema }}.ORDER O ON C.CUSTOMER_ID = O.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.EMAIL,
    C.COUNTRY,
    C.CUSTOMER_SEGMENT,
    C.IS_ACTIVE
COMMENT = 'Customer summary view with order metrics and spending analysis';

-- Product Performance View
CREATE OR REPLACE VIEW {{ database_name }}.{{ sf_schema }}.V_PRODUCT_PERFORMANCE AS
SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY,
    P.SUBCATEGORY,
    P.BRAND,
    P.UNIT_PRICE,
    COUNT(DISTINCT OLI.ORDER_ID) AS ORDERS_COUNT,
    SUM(OLI.QUANTITY) AS TOTAL_QUANTITY_SOLD,
    SUM(OLI.LINE_TOTAL) AS TOTAL_REVENUE,
    AVG(OLI.UNIT_PRICE) AS AVERAGE_SELLING_PRICE,
    SUM(OLI.QUANTITY) * P.COST_PRICE AS TOTAL_COST,
    (SUM(OLI.LINE_TOTAL) - (SUM(OLI.QUANTITY) * P.COST_PRICE)) AS TOTAL_PROFIT,
    ROUND(((SUM(OLI.LINE_TOTAL) - (SUM(OLI.QUANTITY) * P.COST_PRICE)) / SUM(OLI.LINE_TOTAL) * 100), 2) AS PROFIT_MARGIN_PERCENT
FROM
    {{ database_name }}.{{ sf_schema }}.PRODUCT P
    LEFT JOIN {{ database_name }}.{{ sf_schema }}.ORDER_LINE_ITEM OLI ON P.PRODUCT_ID = OLI.PRODUCT_ID
WHERE
    P.IS_ACTIVE = TRUE
GROUP BY
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    P.CATEGORY,
    P.SUBCATEGORY,
    P.BRAND,
    P.UNIT_PRICE,
    P.COST_PRICE
COMMENT = 'Product performance view with sales and profitability metrics';

-- Order Summary View
CREATE OR REPLACE VIEW {{ database_name }}.{{ sf_schema }}.V_ORDER_SUMMARY AS
SELECT
    O.ORDER_ID,
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.COUNTRY,
    O.ORDER_DATE,
    O.ORDER_STATUS,
    O.TOTAL_AMOUNT,
    O.DISCOUNT_AMOUNT,
    O.TAX_AMOUNT,
    O.NET_AMOUNT,
    O.PAYMENT_METHOD,
    O.PAYMENT_STATUS,
    COUNT(DISTINCT OLI.PRODUCT_ID) AS PRODUCT_COUNT,
    SUM(OLI.QUANTITY) AS TOTAL_QUANTITY,
    DATEDIFF(DAY, O.ORDER_DATE, O.DELIVERY_DATE) AS DELIVERY_DAYS
FROM
    {{ database_name }}.{{ sf_schema }}.ORDER O
    INNER JOIN {{ database_name }}.{{ sf_schema }}.CUSTOMER C ON O.CUSTOMER_ID = C.CUSTOMER_ID
    LEFT JOIN {{ database_name }}.{{ sf_schema }}.ORDER_LINE_ITEM OLI ON O.ORDER_ID = OLI.ORDER_ID
GROUP BY
    O.ORDER_ID,
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.COUNTRY,
    O.ORDER_DATE,
    O.ORDER_STATUS,
    O.TOTAL_AMOUNT,
    O.DISCOUNT_AMOUNT,
    O.TAX_AMOUNT,
    O.NET_AMOUNT,
    O.PAYMENT_METHOD,
    O.PAYMENT_STATUS,
    O.DELIVERY_DATE
COMMENT = 'Order summary view with customer and product details';

-- Sales by Category View
CREATE OR REPLACE VIEW {{ database_name }}.{{ sf_schema }}.V_SALES_BY_CATEGORY AS
SELECT
    P.CATEGORY,
    P.SUBCATEGORY,
    COUNT(DISTINCT O.ORDER_ID) AS ORDER_COUNT,
    COUNT(DISTINCT C.CUSTOMER_ID) AS CUSTOMER_COUNT,
    SUM(OLI.QUANTITY) AS TOTAL_UNITS_SOLD,
    SUM(OLI.LINE_TOTAL) AS TOTAL_REVENUE,
    AVG(OLI.LINE_TOTAL) AS AVERAGE_ITEM_VALUE,
    O.ORDER_DATE
FROM
    {{ database_name }}.{{ sf_schema }}.PRODUCT P
    INNER JOIN {{ database_name }}.{{ sf_schema }}.ORDER_LINE_ITEM OLI ON P.PRODUCT_ID = OLI.PRODUCT_ID
    INNER JOIN {{ database_name }}.{{ sf_schema }}.ORDER O ON OLI.ORDER_ID = O.ORDER_ID
    INNER JOIN {{ database_name }}.{{ sf_schema }}.CUSTOMER C ON O.CUSTOMER_ID = C.CUSTOMER_ID
GROUP BY
    P.CATEGORY,
    P.SUBCATEGORY,
    O.ORDER_DATE
COMMENT = 'Sales metrics by product category and subcategory';

-- Monthly Sales Trends View
CREATE OR REPLACE VIEW {{ database_name }}.{{ sf_schema }}.V_MONTHLY_SALES_TRENDS AS
SELECT
    DATE_TRUNC('MONTH', O.ORDER_DATE) AS MONTH,
    COUNT(DISTINCT O.ORDER_ID) AS ORDER_COUNT,
    COUNT(DISTINCT O.CUSTOMER_ID) AS UNIQUE_CUSTOMERS,
    SUM(O.NET_AMOUNT) AS TOTAL_SALES,
    AVG(O.NET_AMOUNT) AS AVERAGE_ORDER_VALUE,
    SUM(O.DISCOUNT_AMOUNT) AS TOTAL_DISCOUNTS,
    SUM(SUM(O.NET_AMOUNT)) OVER (ORDER BY DATE_TRUNC('MONTH', O.ORDER_DATE)) AS CUMULATIVE_SALES
FROM
    {{ database_name }}.{{ sf_schema }}.ORDER O
WHERE
    O.ORDER_STATUS IN ('COMPLETED', 'DELIVERED')
GROUP BY
    DATE_TRUNC('MONTH', O.ORDER_DATE)
COMMENT = 'Monthly sales trends with cumulative analysis';

-- Customer Segmentation View
CREATE OR REPLACE VIEW {{ database_name }}.{{ sf_schema }}.V_CUSTOMER_SEGMENTATION AS
SELECT
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.CUSTOMER_SEGMENT,
    COUNT(DISTINCT O.ORDER_ID) AS PURCHASE_FREQUENCY,
    SUM(O.NET_AMOUNT) AS LIFETIME_VALUE,
    AVG(O.NET_AMOUNT) AS AVERAGE_ORDER_VALUE,
    MAX(O.ORDER_DATE) AS RECENCY_DAYS,
    CASE
        WHEN SUM(O.NET_AMOUNT) > 10000 THEN 'VIP'
        WHEN SUM(O.NET_AMOUNT) > 5000 THEN 'Premium'
        WHEN SUM(O.NET_AMOUNT) > 1000 THEN 'Regular'
        ELSE 'New'
    END AS CUSTOMER_VALUE_TIER
FROM
    {{ database_name }}.{{ sf_schema }}.CUSTOMER C
    LEFT JOIN {{ database_name }}.{{ sf_schema }}.ORDER O ON C.CUSTOMER_ID = O.CUSTOMER_ID
GROUP BY
    C.CUSTOMER_ID,
    C.CUSTOMER_NAME,
    C.CUSTOMER_SEGMENT
COMMENT = 'Customer segmentation and value tier classification';
