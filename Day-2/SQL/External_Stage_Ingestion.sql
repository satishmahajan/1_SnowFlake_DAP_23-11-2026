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

CREATE SCHEMA if NOT EXISTS BLINKIT_DB.S3_SCHEMA;
USE SCHEMA BLINKIT_DB.S3_SCHEMA;

--------------------------- Need to tables for s3-------------------------
CREATE TABLE IF NOT EXISTS S3_SCHEMA.BLINKIT_ORDERS(
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

CREATE TABLE IF NOT EXISTS S3_SCHEMA.BLINKIT_ORDER_ITEMS (
    order_id        NUMBER(12,0) NOT NULL,
    product_id      NUMBER(12,0) NOT NULL,
    quantity        NUMBER(10,0),
    unit_price      NUMBER(10,2),
    total_price     NUMBER(20,2) AS (quantity * unit_price),
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id)
);

CREATE TABLE IF NOT EXISTS S3_SCHEMA.BLINKIT_DELIVERY_PERFORMANCE (
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

CREATE TABLE IF NOT EXISTS S3_SCHEMA.BLINKIT_MARKETING_PERFORMANCE (
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


-----------------------------AWS (S3) INTEGRATION----------------------------------------------
-- A️ Standard CSV Format (Orders, Marketing, Order Items)
CREATE OR REPLACE FILE FORMAT S3_SCHEMA.CSV_FF
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
CREATE OR REPLACE FILE FORMAT S3_SCHEMA.CSV_ISO_FF
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
EMPTY_FIELD_AS_NULL = TRUE
NULL_IF = ('NULL', 'null', '')
TIMESTAMP_FORMAT = 'DD-MM-YYYY HH24:MI'
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

drop STORAGE integration  BlinkIT_External_STAGE;
-- Execute only time
CREATE STORAGE integration BlinkIT_External_STAGE
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::954976308451:role/aws-s3-role-v2'   
STORAGE_ALLOWED_LOCATIONS =('s3://amz-s3-blinkit-data-v2/');


DESC INTEGRATION BlinkIT_External_STAGE;

CREATE OR REPLACE STAGE BLINKIT_STAGE
URL ='s3://amz-s3-blinkit-data-v2'
file_format = S3_SCHEMA.CSV_ISO_FF
storage_integration = BlinkIT_External_STAGE;

SHOW STAGES;

LIST @BLINKIT_DB.S3_SCHEMA.BLINKIT_STAGE;

-----------------------------------snowpipe-------------------------------------------------------

-- It will execute only 1 time
COPY INTO BLINKIT_DB.S3_SCHEMA.BLINKIT_ORDERS
FROM @BLINKIT_DB.S3_SCHEMA.BLINKIT_STAGE
PATTERN = '.*orders.*\\.csv'
FILE_FORMAT = (FORMAT_NAME = 'BLINKIT_DB.S3_SCHEMA.CSV_ISO_FF')
ON_ERROR = 'ABORT_STATEMENT';

drop pipe BLINKIT_DB.S3_SCHEMA.BLINKIT_PIPE_ORDERS;
-- will execute every time whenever file uploded 
CREATE OR REPLACE PIPE BLINKIT_DB.S3_SCHEMA.BLINKIT_PIPE_ORDERS AUTO_INGEST = TRUE AS
COPY INTO BLINKIT_DB.S3_SCHEMA.BLINKIT_ORDERS
FROM @BLINKIT_DB.S3_SCHEMA.BLINKIT_STAGE/blinkitdata/
PATTERN = '.*blinkit_orders[.]csv'
FILE_FORMAT = (FORMAT_NAME = 'BLINKIT_DB.S3_SCHEMA.CSV_ISO_FF') ;

alter pipe BLINKIT_DB.S3_SCHEMA.BLINKIT_PIPE_ORDERS refresh;

select * from BLINKIT_DB.S3_SCHEMA.BLINKIT_ORDERS;

truncate S3_SCHEMA.BLINKIT_ORDERS;
-------------------------------------------------------------------------------------------------------
drop schema s3_schema