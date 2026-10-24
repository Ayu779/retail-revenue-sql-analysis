-- Q8. Is growth coming from new customers or from existing ones?
-- An order is "new" if it is the customer's first ever order.
-- Starts Jan 2010 because every Dec 2009 order looks new (data starts then).
WITH flagged AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        order_value,
        CASE WHEN order_date = MIN(order_date) OVER (PARTITION BY customer_id)
             THEN 1 ELSE 0 END AS is_first_order
    FROM customer_orders
)
SELECT
    month,
    SUM(is_first_order)                                          AS new_customers,
    ROUND(SUM(CASE WHEN is_first_order = 1 THEN order_value ELSE 0 END), 0) AS new_revenue,
    ROUND(SUM(CASE WHEN is_first_order = 0 THEN order_value ELSE 0 END), 0) AS returning_revenue,
    ROUND(100.0 * SUM(CASE WHEN is_first_order = 0 THEN order_value ELSE 0 END)
                / SUM(order_value), 1)                           AS returning_share_pct
FROM flagged
WHERE month >= '2010-01'
GROUP BY month
ORDER BY month;
