-- ============================================================
-- Snowflake Setup Script for Blinkit Analytics Dashboard
-- Run this script in Snowflake to create the database, schema,
-- tables, and load synthetic data.
-- ============================================================

-----------------Semi-Structured--------------


-- CREATE WAREHOUSE 
CREATE WAREHOUSE IF NOT EXISTS BLINKIT_WH
WAREHOUSE_SIZE = 'XSMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;

-- Create Database
CREATE DATABASE IF NOT EXISTS BLINKIT_DB;

-- Use Database
USE DATABASE BLINKIT_DB;

-- Create Schema

CREATE SCHEMA if NOT EXISTS BLINKIT_DB.RAW;
USE SCHEMA BLINKIT_DB.RAW;

-- Create Internal Stage

CREATE STAGE IF NOT EXISTS BLINKIT_DB.RAW.CSV_STAGE
COMMENT = 'Stage for CSV Files';

-- To list all stage names
LIST @BLINKIT_DB.RAW.CSV_STAGE;

-- A️ Standard CSV Format (Orders, Marketing, Order Items)
CREATE OR REPLACE FILE FORMAT BLINKIT_DB.RAW.CSV_FF
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
EMPTY_FIELD_AS_NULL = TRUE
NULL_IF = ('NULL', 'null', '')
DATE_FORMAT = 'YYYY-MM-DD'
TIMESTAMP_FORMAT = 'DD-MM-YYYY HH24:MI'
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- ISO Timestamp Format (Delivery Performance)
CREATE OR REPLACE FILE FORMAT BLINKIT_DB.RAW.CSV_ISO_FF
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
EMPTY_FIELD_AS_NULL = TRUE
NULL_IF = ('NULL', 'null', '')
TIMESTAMP_FORMAT = 'DD-MM-YYYY HH24:MI'
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE TABLE IF NOT EXISTS RAW.BLINKIT_ORDERS (
    order_id                 NUMBER(12,0) NOT NULL,
    customer_id              NUMBER(12,0) NOT NULL,
    order_date               TIMESTAMP_NTZ,
    promised_delivery_time   TIMESTAMP_NTZ,
    actual_delivery_time     TIMESTAMP_NTZ,
    delivery_status          VARCHAR(50),
    order_total              NUMBER(12,2),
    payment_method           VARCHAR(30),
    delivery_partner_id      NUMBER(12,0),
    store_id                 NUMBER(12,0),
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);

CREATE TABLE IF NOT EXISTS RAW.BLINKIT_ORDER_ITEMS (
    order_id        NUMBER(12,0) NOT NULL,
    product_id      NUMBER(12,0) NOT NULL,
    quantity        NUMBER(10,0),
    unit_price      NUMBER(10,2),
    total_price     NUMBER(20,2) AS (quantity * unit_price),
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id)
);

CREATE TABLE IF NOT EXISTS RAW.BLINKIT_DELIVERY_PERFORMANCE (
    order_id                NUMBER(12,0) NOT NULL,
    delivery_partner_id     NUMBER(12,0),
    promised_time           TIMESTAMP_NTZ,
    actual_time             TIMESTAMP_NTZ,
    delivery_time_minutes   NUMBER(18,0)
        AS (DATEDIFF('minute', promised_time, actual_time)),
    distance_km             NUMBER(6,2),
    delivery_status         VARCHAR(50),
    reasons_if_delayed      VARCHAR(200),
    CONSTRAINT pk_delivery PRIMARY KEY (order_id)
);

CREATE TABLE IF NOT EXISTS RAW.BLINKIT_MARKETING_PERFORMANCE (
    campaign_id        NUMBER(10,0),
    campaign_name      VARCHAR(200),
    date               DATE,
    target_audience    VARCHAR(100),
    channel            VARCHAR(50),
    impressions        NUMBER(12,0),
    clicks             NUMBER(12,0),
    conversions        NUMBER(12,0),
    spend              NUMBER(12,2),
    revenue_generated  NUMBER(12,2),
    roas               NUMBER(5,2),
    CONSTRAINT pk_campaign PRIMARY KEY (campaign_id, date)
);
-- Query---

COPY INTO RAW.BLINKIT_ORDERS
FROM @RAW.CSV_STAGE/blinkit_orders.csv
FILE_FORMAT = CSV_FF
ON_ERROR = 'CONTINUE';

select * from RAW.BLINKIT_ORDERS;

COPY INTO RAW.BLINKIT_ORDER_ITEMS
FROM @RAW.CSV_STAGE/blinkit_order_items.csv
FILE_FORMAT = CSV_FF
ON_ERROR = 'CONTINUE';

-- perform through query
COPY INTO RAW.BLINKIT_DELIVERY_PERFORMANCE
FROM @RAW.CSV_STAGE/blinkit_delivery_performance.csv
FILE_FORMAT = CSV_ISO_FF
ON_ERROR = 'CONTINUE';

COPY INTO RAW.BLINKIT_MARKETING_PERFORMANCE
FROM @RAW.CSV_STAGE/blinkit_marketing_performance.csv
FILE_FORMAT = CSV_FF
ON_ERROR = 'CONTINUE';
------------------------------------------------------------------------------------


