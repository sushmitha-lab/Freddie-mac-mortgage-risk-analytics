-- =============================================================
-- Freddie Mac Mortgage Risk Project — Snowflake Infrastructure Setup
-- =============================================================
-- This script provisions the database, schemas, file format, stage,
-- and raw landing tables for the Single-Family Loan-Level Dataset
-- (SFLLD) sample files (2018, 2019, 2020 vintages).
--
-- Source data: https://www.freddiemac.com/research/datasets/sf-loanlevel-dataset
-- =============================================================

-- ---------- Database & Schemas ----------

CREATE DATABASE IF NOT EXISTS CAPITAL_MARKETS_DM;
USE DATABASE CAPITAL_MARKETS_DM;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS MARTS;

USE SCHEMA RAW;

-- ---------- File Format & Stage ----------

CREATE OR REPLACE FILE FORMAT pipe_delimited_format
  TYPE = 'CSV'
  FIELD_DELIMITER = '|'
  SKIP_HEADER = 0
  NULL_IF = ('')
  EMPTY_FIELD_AS_NULL = TRUE;

CREATE OR REPLACE STAGE raw_stage
  FILE_FORMAT = pipe_delimited_format;

-- ---------- Raw Landing Tables ----------
-- All columns land as VARCHAR by design — type casting and cleaning
-- happens downstream in the dbt staging layer (models/staging/).
-- This keeps raw ingestion resilient to unexpected/malformed values.

-- Origination tables (1 row per loan, ~50,000 rows per vintage sample)

CREATE OR REPLACE TABLE RAW_ORIG_2018 (
    credit_score                  VARCHAR,
    first_payment_date            VARCHAR,
    first_time_homebuyer_flag     VARCHAR,
    maturity_date                 VARCHAR,
    msa_or_metro_division         VARCHAR,
    mi_percent                    VARCHAR,
    number_of_units               VARCHAR,
    occupancy_status               VARCHAR,
    original_cltv                  VARCHAR,
    original_dti                   VARCHAR,
    original_upb                   VARCHAR,
    original_ltv                   VARCHAR,
    original_interest_rate        VARCHAR,
    channel                         VARCHAR,
    ppm_flag                       VARCHAR,
    amortization_type             VARCHAR,
    property_state                  VARCHAR,
    property_type                   VARCHAR,
    postal_code                    VARCHAR,
    loan_sequence_number           VARCHAR,
    loan_purpose                    VARCHAR,
    original_loan_term             VARCHAR,
    number_of_borrowers            VARCHAR,
    seller_name                    VARCHAR,
    servicer_name                   VARCHAR,
    super_conforming_flag          VARCHAR,
    pre_harp_loan_sequence_number  VARCHAR,
    program_indicator               VARCHAR,
    harp_indicator                   VARCHAR,
    property_valuation_method      VARCHAR,
    interest_only_indicator        VARCHAR,
    mi_cancellation_indicator      VARCHAR
);

CREATE OR REPLACE TABLE RAW_ORIG_2019 LIKE RAW_ORIG_2018;
CREATE OR REPLACE TABLE RAW_ORIG_2020 LIKE RAW_ORIG_2018;

-- Monthly performance tables (1 row per loan per reporting month)

CREATE OR REPLACE TABLE RAW_SVCG_2018 (
    loan_sequence_number              VARCHAR,
    monthly_reporting_period          VARCHAR,
    current_actual_upb                VARCHAR,
    current_loan_delinquency_status   VARCHAR,
    loan_age                          VARCHAR,
    remaining_months_to_maturity      VARCHAR,
    defect_settlement_date            VARCHAR,
    modification_flag                 VARCHAR,
    zero_balance_code                 VARCHAR,
    zero_balance_effective_date       VARCHAR,
    current_interest_rate             VARCHAR,
    current_deferred_upb              VARCHAR,
    ddlpi                             VARCHAR,
    mi_recoveries                     VARCHAR,
    net_sales_proceeds                VARCHAR,
    non_mi_recoveries                 VARCHAR,
    expenses                          VARCHAR,
    legal_costs                       VARCHAR,
    maintenance_preservation_costs    VARCHAR,
    taxes_and_insurance               VARCHAR,
    miscellaneous_expenses            VARCHAR,
    actual_loss_calculation           VARCHAR,
    modification_cost                 VARCHAR,
    step_modification_flag            VARCHAR,
    deferred_payment_plan             VARCHAR,
    estimated_ltv                     VARCHAR,
    zero_balance_removal_upb          VARCHAR,
    delinquent_accrued_interest       VARCHAR,
    delinquency_due_to_disaster       VARCHAR,
    borrower_assistance_status_code   VARCHAR,
    current_month_modification_cost   VARCHAR,
    interest_bearing_upb              VARCHAR
);

CREATE OR REPLACE TABLE RAW_SVCG_2019 LIKE RAW_SVCG_2018;
CREATE OR REPLACE TABLE RAW_SVCG_2020 LIKE RAW_SVCG_2018;

-- ---------- Data Loading ----------
-- Files are uploaded to the stage via SnowSQL PUT, then loaded with COPY INTO.
-- Example (run once per file, after uploading via PUT):
--
-- PUT file:///path/to/sample_orig_2018.txt @RAW_STAGE;
--
-- COPY INTO RAW_ORIG_2018
-- FROM @RAW_STAGE/sample_orig_2018.txt.gz
-- FILE_FORMAT = (FORMAT_NAME = 'PIPE_DELIMITED_FORMAT')
-- ON_ERROR = 'ABORT_STATEMENT';
--
-- Repeat for each of the 6 raw tables (3 origination + 3 performance years).

-- ---------- Verification ----------
-- Expected row counts after a full load:
--   RAW_ORIG_2018: 50,000        RAW_SVCG_2018: 1,998,728
--   RAW_ORIG_2019: 50,000        RAW_SVCG_2019: 1,847,477
--   RAW_ORIG_2020: 50,000        RAW_SVCG_2020: 2,340,586
