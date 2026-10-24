-- Q7. How long does it take a customer to place a second order?
-- Only customers whose first order was at least 12 months before the data ends,
-- so everyone had a full year to come back.
WITH numbered AS (
    SELECT
        customer_id,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, invoice_no) AS n
    FROM customer_orders
),
pairs AS (
    SELECT
        f.customer_id,
        DATEDIFF(s.order_date, f.order_date) AS days_to_second
    FROM numbered f
    LEFT JOIN numbered s ON s.customer_id = f.customer_id AND s.n = 2
    WHERE f.n = 1
      AND f.order_date >= '2010-01-01'
      AND f.order_date <  '2010-12-01'
),
bucketed AS (
    SELECT
        CASE
            WHEN days_to_second IS NULL  THEN '6. Never (so far)'
            WHEN days_to_second <= 30    THEN '1. Within 30 days'
            WHEN days_to_second <= 60    THEN '2. 31 to 60 days'
            WHEN days_to_second <= 90    THEN '3. 61 to 90 days'
            WHEN days_to_second <= 180   THEN '4. 91 to 180 days'
            ELSE                              '5. After 180 days'
        END AS time_to_second_order
    FROM pairs
)
SELECT
    time_to_second_order,
    COUNT(*)                                            AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS share_pct,
    ROUND(100.0 * SUM(COUNT(*)) OVER (ORDER BY time_to_second_order)
                / SUM(COUNT(*)) OVER (), 1)             AS cumulative_pct
FROM bucketed
GROUP BY time_to_second_order
ORDER BY time_to_second_order;
