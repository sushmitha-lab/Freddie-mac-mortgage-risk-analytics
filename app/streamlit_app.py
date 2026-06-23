import streamlit as st
import pandas as pd
import altair as alt

st.set_page_config(page_title="Mortgage Risk Explorer", layout="wide")

conn = st.connection("snowflake")

st.title("🏠 Mortgage Risk Explorer")
st.caption("Freddie Mac Single-Family Loan-Level Dataset · 2018–2020 vintages · 150,000 loans")

page = st.sidebar.radio("Navigate", ["Portfolio Overview", "Loan Explorer"])

# ---------- PORTFOLIO OVERVIEW ----------
if page == "Portfolio Overview":

    summary = conn.query("""
        select
            count(distinct f.loan_sequence_number) as total_loans,
            sum(o.original_upb) as total_upb,
            count(distinct case when f.is_default_event then f.loan_sequence_number end) as defaulted_loans
        from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments f
        join CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_originations o
            on f.loan_sequence_number = o.loan_sequence_number
    """)

    total_loans = int(summary["TOTAL_LOANS"][0])
    total_upb = float(summary["TOTAL_UPB"][0])
    defaulted_loans = int(summary["DEFAULTED_LOANS"][0])
    default_rate = defaulted_loans / total_loans * 100

    col1, col2, col3 = st.columns(3)
    col1.metric("Total Loans", f"{total_loans:,}")
    col2.metric("Total UPB", f"${total_upb/1e9:.2f}B")
    col3.metric("Loan-Level Default Rate", f"{default_rate:.2f}%")

    st.divider()

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Default Rate by Credit Score Band")
        df = conn.query("""
            select
                b.credit_score_band,
                count(distinct f.loan_sequence_number) as total_loans,
                count(distinct case when f.is_default_event then f.loan_sequence_number end) as defaulted_loans
            from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments f
            join CAPITAL_MARKETS_DM.STAGING_marts.dim_borrower b
                on f.loan_sequence_number = b.loan_sequence_number
            group by 1
        """)
        df["DEFAULT_RATE"] = df["DEFAULTED_LOANS"] / df["TOTAL_LOANS"] * 100
        chart = alt.Chart(df).mark_bar().encode(
            x=alt.X("CREDIT_SCORE_BAND:N", sort="-y", title="Credit Score Band"),
            y=alt.Y("DEFAULT_RATE:Q", title="Default Rate (%)"),
            color=alt.Color("CREDIT_SCORE_BAND:N", legend=None)
        )
        st.altair_chart(chart, use_container_width=True)

    with col2:
        st.subheader("Default Rate by Vintage Year")
        df = conn.query("""
            select
                o.source_vintage_year as vintage_year,
                count(distinct f.loan_sequence_number) as total_loans,
                count(distinct case when f.is_default_event then f.loan_sequence_number end) as defaulted_loans
            from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments f
            join CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_originations o
                on f.loan_sequence_number = o.loan_sequence_number
            group by 1
            order by 1
        """)
        df["DEFAULT_RATE"] = df["DEFAULTED_LOANS"] / df["TOTAL_LOANS"] * 100
        chart = alt.Chart(df).mark_bar().encode(
            x=alt.X("VINTAGE_YEAR:O", title="Vintage Year"),
            y=alt.Y("DEFAULT_RATE:Q", title="Default Rate (%)"),
            color=alt.Color("VINTAGE_YEAR:O", legend=None)
        )
        st.altair_chart(chart, use_container_width=True)

    st.divider()

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Default Rate by Loan Purpose")
        df = conn.query("""
            select
                t.loan_purpose_description,
                count(distinct f.loan_sequence_number) as total_loans,
                count(distinct case when f.is_default_event then f.loan_sequence_number end) as defaulted_loans
            from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments f
            join CAPITAL_MARKETS_DM.STAGING_marts.dim_loan_terms t
                on f.loan_sequence_number = t.loan_sequence_number
            group by 1
        """)
        df["DEFAULT_RATE"] = df["DEFAULTED_LOANS"] / df["TOTAL_LOANS"] * 100
        chart = alt.Chart(df).mark_bar().encode(
            x=alt.X("LOAN_PURPOSE_DESCRIPTION:N", sort="-y", title="Loan Purpose"),
            y=alt.Y("DEFAULT_RATE:Q", title="Default Rate (%)"),
            color=alt.Color("LOAN_PURPOSE_DESCRIPTION:N", legend=None)
        )
        st.altair_chart(chart, use_container_width=True)

    with col2:
        st.subheader("Default Rate by Occupancy Type")
        df = conn.query("""
            select
                t.occupancy_status_description,
                count(distinct f.loan_sequence_number) as total_loans,
                count(distinct case when f.is_default_event then f.loan_sequence_number end) as defaulted_loans
            from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments f
            join CAPITAL_MARKETS_DM.STAGING_marts.dim_loan_terms t
                on f.loan_sequence_number = t.loan_sequence_number
            group by 1
        """)
        df["DEFAULT_RATE"] = df["DEFAULTED_LOANS"] / df["TOTAL_LOANS"] * 100
        chart = alt.Chart(df).mark_bar().encode(
            x=alt.X("OCCUPANCY_STATUS_DESCRIPTION:N", sort="-y", title="Occupancy Type"),
            y=alt.Y("DEFAULT_RATE:Q", title="Default Rate (%)"),
            color=alt.Color("OCCUPANCY_STATUS_DESCRIPTION:N", legend=None)
        )
        st.altair_chart(chart, use_container_width=True)

    st.divider()
    st.subheader("Default Events Over Time")
    df = conn.query("""
        select
            monthly_reporting_period,
            count(distinct case when is_default_event then loan_sequence_number end) as defaulted_loans
        from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments
        group by 1
        order by 1
    """)
    chart = alt.Chart(df).mark_line(point=True).encode(
        x=alt.X("MONTHLY_REPORTING_PERIOD:T", title="Month"),
        y=alt.Y("DEFAULTED_LOANS:Q", title="Loans in Default State")
    )
    st.altair_chart(chart, use_container_width=True)

# ---------- LOAN EXPLORER ----------
else:
    st.subheader("Search & Filter Loans")

    states_df = conn.query("""
        select distinct property_state
        from CAPITAL_MARKETS_DM.STAGING_marts.dim_loan_terms
        where property_state is not null
        order by 1
    """)
    state_options = ["All"] + states_df["PROPERTY_STATE"].tolist()

    col1, col2, col3 = st.columns(3)
    with col1:
        selected_state = st.selectbox("State", state_options)
    with col2:
        selected_band = st.selectbox(
            "Credit Score Band",
            ["All", "Excellent (740+)", "Good (670-739)", "Fair (580-669)", "Poor (<580)", "Unknown"]
        )
    with col3:
        selected_vintage = st.selectbox("Vintage Year", ["All", "2018", "2019", "2020"])

    where_clauses = []
    if selected_state != "All":
        where_clauses.append(f"t.property_state = '{selected_state}'")
    if selected_band != "All":
        where_clauses.append(f"b.credit_score_band = '{selected_band}'")
    if selected_vintage != "All":
        where_clauses.append(f"o.source_vintage_year = {selected_vintage}")

    where_sql = "where " + " and ".join(where_clauses) if where_clauses else ""

    results = conn.query(f"""
        select
            o.loan_sequence_number,
            t.property_state,
            b.credit_score,
            b.credit_score_band,
            t.loan_purpose_description,
            t.occupancy_status_description,
            o.original_upb,
            o.original_interest_rate,
            o.source_vintage_year as vintage_year
        from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_originations o
        join CAPITAL_MARKETS_DM.STAGING_marts.dim_borrower b
            on o.loan_sequence_number = b.loan_sequence_number
        join CAPITAL_MARKETS_DM.STAGING_marts.dim_loan_terms t
            on o.loan_sequence_number = t.loan_sequence_number
        {where_sql}
        limit 200
    """, ttl=0)

    st.write(f"Showing {len(results)} loans (max 200)")
    st.dataframe(results, use_container_width=True)

    st.divider()
    st.subheader("Inspect a Specific Loan")
    loan_id = st.text_input("Enter a Loan Sequence Number (e.g. F18Q10000028)")

    if loan_id:
        history = conn.query(f"""
            select
                monthly_reporting_period,
                current_actual_upb,
                delinquency_months,
                is_severely_delinquent,
                is_default_event
            from CAPITAL_MARKETS_DM.STAGING_marts.fct_loan_payments
            where loan_sequence_number = '{loan_id}'
            order by monthly_reporting_period
        """, ttl=0)

        if len(history) == 0:
            st.warning("No loan found with that sequence number.")
        else:
            st.write(f"Payment history for **{loan_id}** ({len(history)} months)")
            col1, col2 = st.columns(2)
            with col1:
                chart = alt.Chart(history).mark_line(point=True).encode(
                    x=alt.X("MONTHLY_REPORTING_PERIOD:T", title="Month"),
                    y=alt.Y("CURRENT_ACTUAL_UPB:Q", title="Balance ($)")
                )
                st.altair_chart(chart, use_container_width=True)
            with col2:
                chart = alt.Chart(history).mark_line(point=True, color="red").encode(
                    x=alt.X("MONTHLY_REPORTING_PERIOD:T", title="Month"),
                    y=alt.Y("DELINQUENCY_MONTHS:Q", title="Months Delinquent")
                )
                st.altair_chart(chart, use_container_width=True)
            st.dataframe(history, use_container_width=True)
