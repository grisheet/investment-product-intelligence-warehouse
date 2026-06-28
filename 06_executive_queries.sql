-- 1. Monthly executive product scorecard
SELECT
    month_start,
    product_name,
    asset_class,
    aum_usd,
    net_flows_usd,
    product_return_pct,
    benchmark_return_pct,
    excess_return_pct,
    client_count,
    aum_growth_pct
FROM mart.fact_product_monthly_kpis
ORDER BY month_start, aum_usd DESC;

-- 2. Top products by latest AUM
WITH latest_month AS (
    SELECT MAX(month_start) AS month_start
    FROM mart.fact_product_monthly_kpis
)
SELECT
    k.month_start,
    k.product_name,
    k.asset_class,
    k.aum_usd,
    k.net_flows_usd,
    k.excess_return_pct,
    k.client_count,
    r.aum_rank
FROM mart.fact_product_monthly_kpis k
JOIN mart.fact_product_rankings r
    ON k.month_start = r.month_start
   AND k.product_id = r.product_id
JOIN latest_month lm
    ON k.month_start = lm.month_start
ORDER BY r.aum_rank
LIMIT 5;

-- 3. Top products by latest net flows
WITH latest_month AS (
    SELECT MAX(month_start) AS month_start
    FROM mart.fact_product_monthly_kpis
)
SELECT
    k.month_start,
    k.product_name,
    k.asset_class,
    k.net_flows_usd,
    k.aum_usd,
    k.excess_return_pct,
    r.net_flow_rank
FROM mart.fact_product_monthly_kpis k
JOIN mart.fact_product_rankings r
    ON k.month_start = r.month_start
   AND k.product_id = r.product_id
JOIN latest_month lm
    ON k.month_start = lm.month_start
ORDER BY r.net_flow_rank
LIMIT 5;

-- 4. Products with strongest benchmark-relative performance
WITH latest_month AS (
    SELECT MAX(month_start) AS month_start
    FROM mart.fact_product_monthly_kpis
)
SELECT
    k.month_start,
    k.product_name,
    k.asset_class,
    k.product_return_pct,
    k.benchmark_return_pct,
    k.excess_return_pct,
    r.excess_return_rank
FROM mart.fact_product_monthly_kpis k
JOIN mart.fact_product_rankings r
    ON k.month_start = r.month_start
   AND k.product_id = r.product_id
JOIN latest_month lm
    ON k.month_start = lm.month_start
ORDER BY r.excess_return_rank
LIMIT 5;

-- 5. Channel economics view
SELECT
    month_start,
    channel,
    region,
    active_clients,
    active_products,
    channel_aum_usd,
    avg_position_size_usd
FROM mart.fact_channel_monthly_kpis
ORDER BY month_start, channel_aum_usd DESC;

-- 6. Client retention summary by segment
SELECT
    month_start,
    client_segment,
    COUNT(*) AS client_records,
    SUM(retained_flag) AS retained_clients,
    AVG(retained_flag::numeric) AS retention_rate
FROM mart.fact_client_monthly_kpis
GROUP BY month_start, client_segment
ORDER BY month_start, client_segment;

-- 7. Products with positive performance but negative net flows
SELECT
    month_start,
    product_name,
    asset_class,
    net_flows_usd,
    product_return_pct,
    excess_return_pct,
    aum_growth_pct
FROM mart.fact_product_monthly_kpis
WHERE net_flows_usd < 0
  AND product_return_pct > 0
ORDER BY month_start, net_flows_usd;

-- 8. Products with negative excess return but positive net flows
SELECT
    month_start,
    product_name,
    asset_class,
    net_flows_usd,
    product_return_pct,
    benchmark_return_pct,
    excess_return_pct
FROM mart.fact_product_monthly_kpis
WHERE net_flows_usd > 0
  AND excess_return_pct < 0
ORDER BY month_start, net_flows_usd DESC;