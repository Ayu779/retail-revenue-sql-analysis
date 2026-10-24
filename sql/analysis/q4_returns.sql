-- Q4. Which products get returned or cancelled most?
-- Return rate = units cancelled / units sold, for products with at least 500 units sold.
WITH sold AS (
    SELECT stock_code, SUM(quantity) AS units_sold, SUM(line_revenue) AS revenue
    FROM sales_lines
    GROUP BY stock_code
),
cancelled AS (
    SELECT oi.stock_code,
           -SUM(oi.quantity)               AS units_cancelled,
           -SUM(oi.quantity * oi.unit_price) AS value_cancelled
    FROM order_items oi
    JOIN orders o ON o.invoice_no = oi.invoice_no
    WHERE o.is_cancellation = 1
    GROUP BY oi.stock_code
)
SELECT
    p.stock_code,
    p.description,
    s.units_sold,
    COALESCE(c.units_cancelled, 0)                                  AS units_cancelled,
    ROUND(100.0 * COALESCE(c.units_cancelled, 0) / s.units_sold, 1) AS return_rate_pct,
    ROUND(COALESCE(c.value_cancelled, 0), 0)                        AS value_cancelled,
    ROUND(s.revenue, 0)                                             AS revenue
FROM sold s
JOIN products p ON p.stock_code = s.stock_code
LEFT JOIN cancelled c ON c.stock_code = s.stock_code
WHERE s.units_sold >= 500
ORDER BY value_cancelled DESC
LIMIT 15;
