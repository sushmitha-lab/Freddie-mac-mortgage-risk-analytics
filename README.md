# Freddie Mac Mortgage Risk Analytics
**🔗 [Live App](https://freddie-mac-mortgage-risk-analytics.streamlit.app/) · [GitHub Repo](https://github.com/sushmitha-lab/Freddie-mac-mortgage-risk-analytics)**

An end-to-end analytics engineering project that transforms Freddie Mac's public Single-Family Loan-Level Dataset into a dimensional data warehouse, with a Streamlit application for portfolio-level and loan-level risk exploration.

**Pipeline:** Freddie Mac SFLLD → Snowflake (raw landing) → dbt (staging → marts) → Streamlit app

## What this project does

Mortgage loan defaults are one of the central risk questions in consumer lending. This project builds the infrastructure to answer it at scale: ingesting raw loan-level data, modeling it into a proper star schema, and applying a default-detection rule consistent with how credit risk teams actually define default — *the earlier of first severe delinquency (90+ days past due) or a recognized loss event*.

**Scope:** 150,000 loans and ~6.2 million monthly performance records across 2018–2020 origination vintages, sourced directly from Freddie Mac's official public dataset.

## Architecture

```
Freddie Mac SFLLD (pipe-delimited text files)
        │
        ▼
  Snowflake RAW schema       (setup/01_snowflake_infrastructure.sql)
   - 6 landing tables, all VARCHAR, loaded via PUT + COPY INTO
        │
        ▼
  dbt staging layer          (models/staging/)
   - stg_loan_originations: unions & type-casts 3 vintage years
   - stg_loan_performance:  unions & type-casts 3 vintage years
        │
        ▼
  dbt marts layer            (models/marts/)
   - dim_date            — calendar dimension, 1999–2026
   - dim_borrower         — credit score & DTI bands at loan grain
   - dim_loan_terms       — loan purpose, occupancy, channel (decoded)
   - fct_loan_originations — 1 row per loan, origination-time measures
   - fct_loan_payments    — 1 row per loan per month, incl. default flags
        │
        ▼
  Streamlit app               (app/streamlit_app.py)
   - Portfolio Overview: default rate by credit band, vintage, purpose, occupancy
   - Loan Explorer: filterable search + individual loan payment history
```

## Key design decisions

- **Raw data lands as text, typed downstream.** Every raw column is loaded as `VARCHAR`; type casting (`try_to_number`, `try_to_date`) happens in the dbt staging layer using `TRY_TO_*` functions, so malformed values become `NULL` instead of failing the entire load.
- **Default detection follows industry convention**, not an arbitrary threshold: a loan is flagged as a default event in a given month if it is severely delinquent (delinquency status ≥ 3, i.e. 90+ days past due) **or** if it exits with a loss-bearing zero balance code (short sale/charge-off or REO disposition). Ordinary prepayment and refinance are explicitly excluded from this flag.
- **Dimensional grain is explicit and tested.** `dim_borrower`, `dim_loan_terms`, and `fct_loan_originations` are all tested for uniqueness on `loan_sequence_number` (one row per loan). `fct_loan_payments` is intentionally *not* unique on that column — it's one row per loan per reporting month — and is tested for not-null integrity instead.
- **11 dbt data tests** enforce primary key uniqueness and required-field completeness across the model. All passing.

## Findings

- **Overall loan-level default rate: 4.31%** across the full 150,000-loan sample.
- **Credit score is strongly predictive of default**, as expected from credit risk theory — the lowest credit score band shows a default rate several multiples higher than the top band.
- **Vintage year shows a meaningful difference** in default rates between the 2018/2019 cohorts and the 2020 cohort, which is worth investigating further (likely reflects shorter performance history for 2020 originations rather than genuinely lower risk — a good example of survivorship/seasoning bias to account for in real credit risk modeling).

## Tech stack

`Snowflake` · `dbt-core` · `dbt-snowflake` · `Python` · `Streamlit` (Streamlit in Snowflake + Streamlit Community Cloud) · `Altair`

## Project structure

```
setup/      Snowflake infrastructure SQL (database, schemas, stage, raw tables)
models/
  staging/  Source-conformed, typed staging models
  marts/    Dimension and fact tables (the star schema) + schema.yml tests
app/        Streamlit application
```

## Data source

Freddie Mac Single-Family Loan-Level Dataset (SFLLD), public sample files (50,000 loans per vintage year). Free for non-commercial/academic use. [Source & terms](https://www.freddiemac.com/research/datasets/sf-loanlevel-dataset)

## Running this project

1. Set up Snowflake objects: run `setup/01_snowflake_infrastructure.sql`
2. Download SFLLD sample files for desired vintage years, load via `PUT` + `COPY INTO` (see comments in setup script)
3. Install dbt: `pip install dbt-snowflake`
4. Configure `~/.dbt/profiles.yml` with your Snowflake credentials
5. `dbt deps && dbt run && dbt test`
6. Run the Streamlit app via Streamlit in Snowflake, or locally with Snowflake connector credentials in `.streamlit/secrets.toml`
