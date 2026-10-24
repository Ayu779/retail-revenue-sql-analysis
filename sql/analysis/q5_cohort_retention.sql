-- Q5. Do new customers come back? Monthly cohort retention.
-- A cohort is every customer whose first order fell in that month.
-- Retention in month N = share of the cohort that ordered again N months later.
-- The Dec 2009 cohort is inflated: the data starts that month, so it holds
-- every existing customer, not just new ones. It is left out here.
WITH first_order AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM customer_orders
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT
        co.customer_id,
        DATE_FORMAT(f.first_date, '%Y-%m') AS cohort,
        PERIOD_DIFF(DATE_FORMAT(co.order_date, '%Y%m'),
                    DATE_FORMAT(f.first_date, '%Y%m')) AS months_since_first
    FROM customer_orders co
    JOIN first_order f ON f.customer_id = co.customer_id
)
SELECT
    cohort,
    COUNT(DISTINCT customer_id) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first = 1  THEN customer_id END)
                / COUNT(DISTINCT customer_id), 1) AS m1_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first = 2  THEN customer_id END)
                / COUNT(DISTINCT customer_id), 1) AS m2_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first = 3  THEN customer_id END)
                / COUNT(DISTINCT customer_id), 1) AS m3_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first = 6  THEN customer_id END)
                / COUNT(DISTINCT customer_id), 1) AS m6_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN months_since_first = 12 THEN customer_id END)
                / COUNT(DISTINCT customer_id), 1) AS m12_pct
FROM activity
WHERE cohort BETWEEN '2010-01' AND '2010-12'
GROUP BY cohort
ORDER BY cohort;
