DROP TABLE IF EXISTS analytics.quality_checks;

CREATE TABLE analytics.quality_checks AS
WITH product_null_checks AS (
    SELECT
        'raw.products' AS check_area,
        'null product_name' AS check_name,
        COUNT(*) AS issue_count
    FROM raw.products
    WHERE product_name IS NULL

    UNION ALL

    SELECT
        'raw.products' AS check_area,
        'null benchmark_code' AS check_name,
        COUNT(*) AS issue_count
    FROM raw.products
    WHERE benchmark_code IS NULL
),
duplicate_transaction_checks AS (
    SELECT
        'raw.subscriptions_redemptions' AS check_area,
        'duplicate transaction_id' AS check_name,
        COUNT(*) AS issue_count
    FROM (
        SELECT transaction_id
        FROM raw.subscriptions_redemptions
        GROUP BY transaction_id
        HAVING COUNT(*) > 1
    ) d
),
nav_gap_checks AS (
    SELECT
        'raw.daily_nav' AS check_area,
        'missing monthly nav observations' AS check_name,
        COUNT(*) AS issue_count
    FROM (
        SELECT p.product_id, c.date_day
        FROM raw.products p
        CROSS JOIN raw.calendar c
        LEFT JOIN raw.daily_nav dn
            ON p.product_id = dn.product_id
           AND c.date_day = dn.nav_date
        WHERE dn.product_id IS NULL
    ) x
),
position_gap_checks AS (
    SELECT
        'raw.daily_positions' AS check_area,
        'clients with no positions after onboarding' AS check_name,
        COUNT(*) AS issue_count
    FROM raw.clients c
    LEFT JOIN raw.daily_positions dp
        ON c.client_id = dp.client_id
    WHERE dp.client_id IS NULL
),
negative_value_checks AS (
    SELECT
        'raw.daily_positions' AS check_area,
        'negative market value' AS check_name,
        COUNT(*) AS issue_count
    FROM raw.daily_positions
    WHERE market_value_usd < 0

    UNION ALL

    SELECT
        'raw.daily_nav' AS check_area,
        'nonpositive nav_per_unit' AS check_name,
        COUNT(*) AS issue_count
    FROM raw.daily_nav
    WHERE nav_per_unit <= 0
),
reconciliation_checks AS (
    SELECT
        'mart.fact_product_monthly_kpis' AS check_area,
        'aum less than redemptions anomaly' AS check_name,
        COUNT(*) AS issue_count
    FROM mart.fact_product_monthly_kpis
    WHERE aum_usd < redemptions_usd

    UNION ALL

    SELECT
        'mart.fact_product_monthly_kpis' AS check_area,
        'null benchmark name in mart' AS check_name,
        COUNT(*) AS issue_count
    FROM mart.fact_product_monthly_kpis
    WHERE benchmark_name IS NULL
),
client_uniqueness_checks AS (
    SELECT
        'raw.clients' AS check_area,
        'duplicate client_id' AS check_name,
        COUNT(*) AS issue_count
    FROM (
        SELECT client_id
        FROM raw.clients
        GROUP BY client_id
        HAVING COUNT(*) > 1
    ) c
),
channel_consistency_checks AS (
    SELECT
        'mart.fact_client_monthly_kpis' AS check_area,
        'null channel in client mart' AS check_name,
        COUNT(*) AS issue_count
    FROM mart.fact_client_monthly_kpis
    WHERE channel IS NULL
)
SELECT * FROM product_null_checks
UNION ALL
SELECT * FROM duplicate_transaction_checks
UNION ALL
SELECT * FROM nav_gap_checks
UNION ALL
SELECT * FROM position_gap_checks
UNION ALL
SELECT * FROM negative_value_checks
UNION ALL
SELECT * FROM reconciliation_checks
UNION ALL
SELECT * FROM client_uniqueness_checks
UNION ALL
SELECT * FROM channel_consistency_checks;