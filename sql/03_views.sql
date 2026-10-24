-- One row per sold line (cancellations excluded), with order context attached.
-- Every analysis query starts from this view.
DROP VIEW IF EXISTS sales_lines;
CREATE VIEW sales_lines AS
SELECT
    oi.invoice_no,
    oi.stock_code,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_revenue,
    o.customer_id,
    o.invoice_date,
    o.country
FROM order_items oi
JOIN orders o ON o.invoice_no = oi.invoice_no
WHERE o.is_cancellation = 0;

-- One row per customer order, for customer-level questions.
DROP VIEW IF EXISTS customer_orders;
CREATE VIEW customer_orders AS
SELECT
    invoice_no,
    customer_id,
    MIN(invoice_date)  AS order_date,
    SUM(line_revenue)  AS order_value
FROM sales_lines
WHERE customer_id IS NOT NULL
GROUP BY invoice_no, customer_id;
