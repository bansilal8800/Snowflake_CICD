DROP TABLE {{ database_name }}.{{ sf_schema }}.CUSTOMER;

INSERT INTO {{ database_name }}.{{ sf_schema }}.CUSTOMER (
    CUSTOMER_ID,
    CUSTOMER_NAME,
    EMAIL,
    PHONE,
    COUNTRY,
    STATE,
    CITY,
    ZIP_CODE,
    CUSTOMER_SEGMENT,
    REGISTRATION_DATE,
    LAST_PURCHASE_DATE,
    TOTAL_LIFETIME_VALUE,
    IS_ACTIVEfff
) VALUES (
    1001,
    'John Michael Smith',
    'john.smith@email.com',
    '+1-555-0101',
    'United States',
    'California',
    'San Francisco',
    '94102',
    'Premium',
    '2022-03-15',
    '2025-12-10',
    15750.50,
    TRUE
);

INSERT INTO {{ database_name }}.{{ sf_schema }}.CUSTOMER (
    CUSTOMER_ID,
    CUSTOMER_NAME,
    EMAIL,
    PHONE,
    COUNTRY,
    STATE,
    CITY,
    ZIP_CODE,
    CUSTOMER_SEGMENT,
    REGISTRATION_DATE,
    LAST_PURCHASE_DATE,
    TOTAL_LIFETIME_VALUE,
    IS_ACTIVE
) VALUES (
    1002,
    'Sarah Jennifer Johnson',
    'sarah.johnson@email.com',
    '+1-555-0102',
    'United States',
    'New York',
    'New York City',
    '10001',
    'VIP',
    '2021-07-22',
    '2025-12-08',
    28450.75,
    TRUE
);

