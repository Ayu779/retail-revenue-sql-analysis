-- Q2. How dependent is revenue on a small group of customers?
-- Customers split into ten equal groups (deciles) by lifetime revenue.
WITH customer_revenue AS (
    SELECT customer_id, SUM(line_revenue) AS revenue
    FROM sales_lines
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM customer_revenue
),
by_decile AS (
    SELECT
        decile,
        COUNT(*)      AS customers,
        SUM(revenue)  AS revenue
    FROM ranked
    GROUP BY decile
)
SELECT
    decile,
    customers,
    ROUND(revenue, 0)                                              AS revenue,
    ROUND(revenue / customers, 0)                                  AS revenue_per_customer,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)               AS revenue_share_pct,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY decile)
                / SUM(revenue) OVER (), 1)                         AS cumulative_share_pct
FROM by_decile
ORDER BY decile;
