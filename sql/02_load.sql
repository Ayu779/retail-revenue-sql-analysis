-- Load the CSVs written by clean.py. Run from the project folder with:
--   mysql --local-infile=1 -u root -p < sql/02_load.sql
-- (the server also needs SET GLOBAL local_infile = 1;)
USE retail;

LOAD DATA LOCAL INFILE 'data/customers.csv' INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES
(customer_id, country);

LOAD DATA LOCAL INFILE 'data/products.csv' INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES
(stock_code, @description)
SET description = NULLIF(@description, '');

LOAD DATA LOCAL INFILE 'data/orders.csv' INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES
(invoice_no, @customer_id, invoice_date, country, is_cancellation)
SET customer_id = NULLIF(@customer_id, '');

LOAD DATA LOCAL INFILE 'data/order_items.csv' INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES
(line_id, invoice_no, stock_code, quantity, unit_price);
