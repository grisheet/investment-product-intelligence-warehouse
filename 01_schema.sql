DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS mart CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;
DROP SCHEMA IF EXISTS raw CASCADE;

CREATE SCHEMA raw;
CREATE SCHEMA staging;
CREATE SCHEMA mart;
CREATE SCHEMA analytics;

CREATE TABLE raw.products (
    product_id           TEXT PRIMARY KEY,
    product_name         TEXT NOT NULL,
    asset_class          TEXT NOT NULL,
    vehicle_type         TEXT NOT NULL,
    inception_date       DATE NOT NULL,
    benchmark_code       TEXT NOT NULL,
    management_fee_bps   NUMERIC(8,2) NOT NULL,
    distribution_fee_bps NUMERIC(8,2) NOT NULL,
    status               TEXT NOT NULL
);

CREATE TABLE raw.clients (
    client_id            TEXT PRIMARY KEY,
    client_name          TEXT NOT NULL,
    client_segment       TEXT NOT NULL,
    region               TEXT NOT NULL,
    onboarding_date      DATE NOT NULL,
    channel              TEXT NOT NULL,
    advisor_id           TEXT NOT NULL
);

CREATE TABLE raw.advisors (
    advisor_id           TEXT PRIMARY KEY,
    advisor_name         TEXT NOT NULL,
    team_name            TEXT NOT NULL,
    region               TEXT NOT NULL
);

CREATE TABLE raw.benchmarks (
    benchmark_code       TEXT PRIMARY KEY,
    benchmark_name       TEXT NOT NULL,
    asset_class          TEXT NOT NULL
);

CREATE TABLE raw.calendar (
    date_day             DATE PRIMARY KEY,
    year_num             INT NOT NULL,
    quarter_num          INT NOT NULL,
    month_num            INT NOT NULL,
    month_start          DATE NOT NULL,
    month_name           TEXT NOT NULL
);

CREATE TABLE raw.subscriptions_redemptions (
    transaction_id       TEXT PRIMARY KEY,
    transaction_date     DATE NOT NULL,
    client_id            TEXT NOT NULL,
    product_id           TEXT NOT NULL,
    transaction_type     TEXT NOT NULL,
    units                NUMERIC(18,4) NOT NULL,
    gross_amount_usd     NUMERIC(18,2) NOT NULL
);

CREATE TABLE raw.daily_nav (
    nav_date             DATE NOT NULL,
    product_id           TEXT NOT NULL,
    nav_per_unit         NUMERIC(18,6) NOT NULL,
    benchmark_return_pct NUMERIC(12,6),
    product_return_pct   NUMERIC(12,6),
    PRIMARY KEY (nav_date, product_id)
);

CREATE TABLE raw.daily_positions (
    position_date        DATE NOT NULL,
    client_id            TEXT NOT NULL,
    product_id           TEXT NOT NULL,
    units_held           NUMERIC(18,4) NOT NULL,
    market_value_usd     NUMERIC(18,2) NOT NULL,
    PRIMARY KEY (position_date, client_id, product_id)
);

ALTER TABLE raw.clients
ADD CONSTRAINT fk_clients_advisor
FOREIGN KEY (advisor_id) REFERENCES raw.advisors(advisor_id);

ALTER TABLE raw.products
ADD CONSTRAINT fk_products_benchmark
FOREIGN KEY (benchmark_code) REFERENCES raw.benchmarks(benchmark_code);

ALTER TABLE raw.subscriptions_redemptions
ADD CONSTRAINT fk_sr_client
FOREIGN KEY (client_id) REFERENCES raw.clients(client_id);

ALTER TABLE raw.subscriptions_redemptions
ADD CONSTRAINT fk_sr_product
FOREIGN KEY (product_id) REFERENCES raw.products(product_id);

ALTER TABLE raw.daily_nav
ADD CONSTRAINT fk_nav_product
FOREIGN KEY (product_id) REFERENCES raw.products(product_id);

ALTER TABLE raw.daily_positions
ADD CONSTRAINT fk_positions_client
FOREIGN KEY (client_id) REFERENCES raw.clients(client_id);

ALTER TABLE raw.daily_positions
ADD CONSTRAINT fk_positions_product
FOREIGN KEY (product_id) REFERENCES raw.products(product_id);