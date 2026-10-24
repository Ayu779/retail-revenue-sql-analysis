-- Q1. How is the business trending month by month?
-- Revenue, orders and average order value, with year-on-year growth.
-- Note: December 2011 only runs to the 9th, so it is a partial month.
WITH monthly AS (
    SELECT
        DATE_FORMAT(invoice_date, '%Y-%m')  AS month,
        COUNT(DISTINCT invoice_no)          AS orders,
        COUNT(DISTINCT customer_id)         AS active_customers,
        SUM(line_revenue)                   AS revenue
    FROM sales_lines
    GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
)
SELECT
    month,
    orders,
    active_customers,
    ROUND(revenue, 0)                    AS revenue,
    ROUND(revenue / orders, 2)           AS avg_order_value,
    ROUND(100.0 * (revenue - LAG(revenue, 12) OVER (ORDER BY month))
                / LAG(revenue, 12) OVER (ORDER BY month), 1) AS revenue_yoy_pct
FROM monthly
ORDER BY month;
