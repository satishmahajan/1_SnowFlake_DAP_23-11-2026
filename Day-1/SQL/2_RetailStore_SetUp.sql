-------- Semi-Structured DATABASE -------

CREATE WAREHOUSE IF NOT EXISTS RetailStore_WH
WAREHOUSE_SIZE = 'XSMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS RetailStore_DB ;

-- Use Database
USE DATABASE RETAILSTORE_DB;

-- Create Schema

CREATE SCHEMA if NOT EXISTS RetailStore_DB.RAW;
USE SCHEMA RetailStore_DB.RAW;

DROP TABLE IF EXISTS RetailStore_DB.RAW.RETAILSTORE;

CREATE Table IF NOT EXISTS RetailStore_DB.RAW.RETAILSTORE
(
    RAW_DATA  VARIANT
);


select * from RetailStore_DB.RAW.RETAILSTORE;

-- Colon Notation -> RAW_DATA:event_id is to Access JSON key.
-- Dot Notation -> RAW_DATA:product.name is to Access nested object.

-- Type Casting
-- ::STRING
-- ::FLOAT
-- Convert VARIANT into SQL datatype.

SELECT
    RAW_DATA:event_id::STRING                       AS EVENT_ID,
    RAW_DATA:event_ts::TIMESTAMP_NTZ                AS EVENT_TS,

    RAW_DATA:store.store_id::NUMBER                 AS STORE_ID,
    RAW_DATA:store.region::STRING                   AS REGION,
    RAW_DATA:store.city::STRING                     AS CITY,

    RAW_DATA:customer.customer_id::NUMBER           AS CUSTOMER_ID,
    RAW_DATA:customer.name::STRING                  AS CUSTOMER_NAME,
    RAW_DATA:customer.loyalty_tier::STRING          AS LOYALTY_TIER,
    RAW_DATA:customer.email_opt_in::BOOLEAN         AS EMAIL_OPT_IN,

    RAW_DATA:product.product_id::NUMBER             AS PRODUCT_ID,
    RAW_DATA:product.name::STRING                   AS PRODUCT_NAME,
    RAW_DATA:product.category::STRING               AS CATEGORY,
    RAW_DATA:product.brand::STRING                  AS BRAND,
    RAW_DATA:product.attributes.color::STRING       AS COLOR,
    RAW_DATA:product.attributes.size::STRING        AS PRODUCT_SIZE,

    RAW_DATA:transaction.qty::NUMBER                AS QUANTITY,
    RAW_DATA:transaction.unit_price::NUMBER(12,2)   AS UNIT_PRICE,
    RAW_DATA:transaction.currency::STRING           AS CURRENCY,
    RAW_DATA:transaction.store_discount::NUMBER(5,4)
                                                     AS STORE_DISCOUNT,
    RAW_DATA:transaction.loyalty_discount::NUMBER(5,4)
                                                     AS LOYALTY_DISCOUNT,
    RAW_DATA:transaction.promo_codes                AS PROMO_CODES,
    RAW_DATA:transaction.review_comments            AS REVIEW_COMMENTS,
    RAW_DATA:transaction.payment_method::STRING     AS PAYMENT_METHOD,
    RAW_DATA:transaction.channel::STRING            AS SALES_CHANNEL,
    RAW_DATA:transaction.tax_rate::NUMBER(5,4)      AS TAX_RATE
FROM RETAILSTORE_DB.RAW.RETAILSTORE;


SELECT
    RAW_DATA:event_id::STRING As EVENT_ID,
    f.value::STRING AS PROMO_CODE
FROM RAW.RETAILSTORE,
LATERAL FLATTEN(
    INPUT => RAW_DATA:transaction.promo_codes
) f;

--------------------------------------------------------------------------------------------------------------

Drop warehouse RETAILSTORE_WH;
DROP Database IF EXISTS RETAILSTORE_DB;