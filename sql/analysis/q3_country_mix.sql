-- Q3. Where do customers come from, and are international customers worth more?
-- Uses each customer's home country (the one they order from most).
WITH customer_revenue AS (
    SELECT
        s.customer_id,
        c.country,
        COUNT(DISTINCT s.invoice_no)  AS orders,
        SUM(s.line_revenue)           AS revenue
    FROM sales_lines s
    JOIN customers c ON c.customer_id = s.customer_id
    GROUP BY s.customer_id, c.country
)
SELECT
    country,
    COUNT(*)                                          AS customers,
    ROUND(SUM(revenue), 0)                            AS revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS revenue_share_pct,
    ROUND(SUM(revenue) / COUNT(*), 0)                 AS revenue_per_customer,
    ROUND(SUM(revenue) / SUM(orders), 0)              AS avg_order_value,
    ROUND(1.0 * SUM(orders) / COUNT(*), 1)            AS orders_per_customer
FROM customer_revenue
GROUP BY country
HAVING COUNT(*) >= 20
ORDER BY revenue DESC;
