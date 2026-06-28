DROP TABLE IF EXISTS staging.stg_product_monthly_performance;
DROP TABLE IF EXISTS staging.stg_monthly_flows;
DROP TABLE IF EXISTS staging.stg_client_product_positions;
DROP TABLE IF EXISTS staging.stg_client_retention;
DROP TABLE IF EXISTS staging.stg_product_aum;

CREATE TABLE staging.stg_product_monthly_performance AS
SELECT
    dn.nav_date,
    date_trunc('month', dn.nav_date)::date AS month_start,
    dn.product_id,
    p.product_name,
    p.asset_class,
    p.vehicle_type,
    p.benchmark_code,
    b.benchmark_name,
    dn.nav_per_unit,
    dn.product_return_pct,
    dn.benchmark_return_pct,
    dn.product_return_pct - dn.benchmark_return_pct AS excess_return_pct
FROM raw.daily_nav dn
JOIN raw.products p
    ON dn.product_id = p.product_id
JOIN raw.benchmarks b
    ON p.benchmark_code = b.benchmark_code;

CREATE TABLE staging.stg_monthly_flows AS
SELECT
    date_trunc('month', sr.transaction_date)::date AS month_start,
    sr.product_id,
    p.product_name,
    p.asset_class,
    sr.transaction_type,
    COUNT(*) AS transaction_count,
    SUM(sr.gross_amount_usd) AS gross_amount_usd,
    SUM(
        CASE
            WHEN sr.transaction_type = 'SUBSCRIPTION' THEN sr.gross_amount_usd
            ELSE 0
        END
    ) AS subscriptions_usd,
    SUM(
        CASE
            WHEN sr.transaction_type = 'REDEMPTION' THEN sr.gross_amount_usd
            ELSE 0
        END
    ) AS redemptions_usd,
    SUM(
        CASE
            WHEN sr.transaction_type = 'SUBSCRIPTION' THEN sr.gross_amount_usd
            ELSE -sr.gross_amount_usd
        END
    ) AS net_flows_usd
FROM raw.subscriptions_redemptions sr
JOIN raw.products p
    ON sr.product_id = p.product_id
GROUP BY 1, 2, 3, 4, 5;

CREATE TABLE staging.stg_client_product_positions AS
SELECT
    dp.position_date,
    date_trunc('month', dp.position_date)::date AS month_start,
    dp.client_id,
    c.client_name,
    c.client_segment,
    c.region,
    c.channel,
    c.advisor_id,
    a.advisor_name,
    dp.product_id,
    p.product_name,
    p.asset_class,
    dp.units_held,
    dp.market_value_usd
FROM raw.daily_positions dp
JOIN raw.clients c
    ON dp.client_id = c.client_id
JOIN raw.products p
    ON dp.product_id = p.product_id
JOIN raw.advisors a
    ON c.advisor_id = a.advisor_id;

CREATE TABLE staging.stg_product_aum AS
SELECT
    month_start,
    product_id,
    product_name,
    asset_class,
    SUM(market_value_usd) AS aum_usd,
    COUNT(DISTINCT client_id) AS client_count
FROM staging.stg_client_product_positions
GROUP BY 1, 2, 3, 4;

CREATE TABLE staging.stg_client_retention AS
WITH monthly_client_activity AS (
    SELECT DISTINCT
        month_start,
        client_id,
        client_name,
        client_segment,
        region,
        channel,
        advisor_id,
        advisor_name
    FROM staging.stg_client_product_positions
),
client_months AS (
    SELECT
        client_id,
        month_start,
        LAG(month_start) OVER (PARTITION BY client_id ORDER BY month_start) AS prev_month_start
    FROM monthly_client_activity
)
SELECT
    month_start,
    client_id,
    CASE
        WHEN prev_month_start = (month_start - INTERVAL '1 month')::date THEN 1
        ELSE 0
    END AS retained_flag
FROM client_months;