DROP TABLE IF EXISTS mart.fact_product_monthly_kpis;
DROP TABLE IF EXISTS mart.fact_client_monthly_kpis;
DROP TABLE IF EXISTS mart.fact_channel_monthly_kpis;
DROP TABLE IF EXISTS mart.fact_product_rankings;

CREATE TABLE mart.fact_product_monthly_kpis AS
WITH flows AS (
    SELECT
        month_start,
        product_id,
        product_name,
        asset_class,
        SUM(subscriptions_usd) AS subscriptions_usd,
        SUM(redemptions_usd) AS redemptions_usd,
        SUM(net_flows_usd) AS net_flows_usd
    FROM staging.stg_monthly_flows
    GROUP BY 1, 2, 3, 4
),
performance AS (
    SELECT
        month_start,
        product_id,
        product_name,
        asset_class,
        benchmark_name,
        nav_per_unit,
        product_return_pct,
        benchmark_return_pct,
        excess_return_pct
    FROM staging.stg_product_monthly_performance
),
aum AS (
    SELECT
        month_start,
        product_id,
        product_name,
        asset_class,
        aum_usd,
        client_count
    FROM staging.stg_product_aum
)
SELECT
    a.month_start,
    a.product_id,
    a.product_name,
    a.asset_class,
    p.benchmark_name,
    a.aum_usd,
    a.client_count,
    COALESCE(f.subscriptions_usd, 0) AS subscriptions_usd,
    COALESCE(f.redemptions_usd, 0) AS redemptions_usd,
    COALESCE(f.net_flows_usd, 0) AS net_flows_usd,
    p.nav_per_unit,
    p.product_return_pct,
    p.benchmark_return_pct,
    p.excess_return_pct,
    LAG(a.aum_usd) OVER (PARTITION BY a.product_id ORDER BY a.month_start) AS prior_month_aum_usd,
    a.aum_usd - LAG(a.aum_usd) OVER (PARTITION BY a.product_id ORDER BY a.month_start) AS aum_change_usd,
    CASE
        WHEN LAG(a.aum_usd) OVER (PARTITION BY a.product_id ORDER BY a.month_start) IS NULL THEN NULL
        WHEN LAG(a.aum_usd) OVER (PARTITION BY a.product_id ORDER BY a.month_start) = 0 THEN NULL
        ELSE
            (a.aum_usd - LAG(a.aum_usd) OVER (PARTITION BY a.product_id ORDER BY a.month_start))
            / LAG(a.aum_usd) OVER (PARTITION BY a.product_id ORDER BY a.month_start)
    END AS aum_growth_pct
FROM aum a
LEFT JOIN flows f
    ON a.month_start = f.month_start
   AND a.product_id = f.product_id
LEFT JOIN performance p
    ON a.month_start = p.month_start
   AND a.product_id = p.product_id;

CREATE TABLE mart.fact_client_monthly_kpis AS
SELECT
    cpp.month_start,
    cpp.client_id,
    cpp.client_name,
    cpp.client_segment,
    cpp.region,
    cpp.channel,
    cpp.advisor_id,
    cpp.advisor_name,
    COUNT(DISTINCT cpp.product_id) AS products_held_count,
    SUM(cpp.market_value_usd) AS total_client_aum_usd,
    MAX(COALESCE(cr.retained_flag, 0)) AS retained_flag
FROM staging.stg_client_product_positions cpp
LEFT JOIN staging.stg_client_retention cr
    ON cpp.month_start = cr.month_start
   AND cpp.client_id = cr.client_id
GROUP BY 1,2,3,4,5,6,7,8;

CREATE TABLE mart.fact_channel_monthly_kpis AS
SELECT
    cpp.month_start,
    cpp.channel,
    cpp.region,
    COUNT(DISTINCT cpp.client_id) AS active_clients,
    COUNT(DISTINCT cpp.product_id) AS active_products,
    SUM(cpp.market_value_usd) AS channel_aum_usd,
    AVG(cpp.market_value_usd) AS avg_position_size_usd
FROM staging.stg_client_product_positions cpp
GROUP BY 1,2,3;

CREATE TABLE mart.fact_product_rankings AS
SELECT
    month_start,
    product_id,
    product_name,
    asset_class,
    aum_usd,
    net_flows_usd,
    product_return_pct,
    excess_return_pct,
    RANK() OVER (PARTITION BY month_start ORDER BY aum_usd DESC) AS aum_rank,
    RANK() OVER (PARTITION BY month_start ORDER BY net_flows_usd DESC) AS net_flow_rank,
    RANK() OVER (PARTITION BY month_start ORDER BY excess_return_pct DESC) AS excess_return_rank
FROM mart.fact_product_monthly_kpis;