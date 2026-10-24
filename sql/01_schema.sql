-- MySQL 8 schema for the cleaned Online Retail II data.
CREATE DATABASE IF NOT EXISTS retail;
USE retail;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id  INT          PRIMARY KEY,
    country      VARCHAR(40)  NOT NULL
);

CREATE TABLE products (
    stock_code   VARCHAR(20)  PRIMARY KEY,
    description  VARCHAR(255)
);

CREATE TABLE orders (
    invoice_no       VARCHAR(10)  PRIMARY KEY,
    customer_id      INT          NULL,          -- NULL = guest checkout, no ID recorded
    invoice_date     DATETIME     NOT NULL,
    country          VARCHAR(40)  NOT NULL,
    is_cancellation  TINYINT(1)   NOT NULL,      -- 1 when the invoice number starts with C
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_date (invoice_date)
);

CREATE TABLE order_items (
    line_id      INT            PRIMARY KEY,
    invoice_no   VARCHAR(10)    NOT NULL,
    stock_code   VARCHAR(20)    NOT NULL,
    quantity     INT            NOT NULL,       -- negative on cancellations
    unit_price   DECIMAL(10,2)  NOT NULL,
    FOREIGN KEY (invoice_no) REFERENCES orders (invoice_no),
    FOREIGN KEY (stock_code) REFERENCES products (stock_code),
    INDEX idx_items_invoice (invoice_no),
    INDEX idx_items_product (stock_code)
);
