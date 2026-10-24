-- Q6. Which customers should marketing treat differently? RFM segmentation.
-- Recency: days from last order to the last day in the data.
-- Frequency: number of orders. Monetary: revenue.
-- Each is scored 1 (worst) to 5 (best) with NTILE, then mapped to a segment.
WITH snapshot AS (
    SELECT MAX(order_date) AS as_of
    FROM customer_orders
),
base AS (
    SELECT
        co.customer_id,
        DATEDIFF(s.as_of, MAX(co.order_date))  AS recency_days,
        COUNT(*)                               AS frequency,
        SUM(co.order_value)                    AS monetary
    FROM customer_orders co
    CROSS JOIN snapshot s
    GROUP BY co.customer_id, s.as_of
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m
    FROM base
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN r >= 4 AND f >= 4                THEN 'Champions'
            WHEN r >= 3 AND f >= 3                THEN 'Loyal'
            WHEN r >= 4 AND f <= 2                THEN 'New or promising'
            WHEN r <= 2 AND f >= 4                THEN 'At risk, high value'
            WHEN r <= 2 AND f >= 2                THEN 'At risk'
            WHEN r = 3                            THEN 'Needs attention'
            ELSE                                       'Lost'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                                     AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS customer_share_pct,
    ROUND(SUM(monetary), 0)                                      AS revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS revenue_share_pct,
    ROUND(AVG(recency_days), 0)                                  AS avg_recency_days,
    ROUND(AVG(frequency), 1)                                     AS avg_orders,
    ROUND(AVG(monetary), 0)                                      AS avg_revenue
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;
