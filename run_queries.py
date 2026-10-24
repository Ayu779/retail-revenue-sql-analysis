"""
Run every query in sql/analysis and save the results to results/.

The queries are written for MySQL 8. So they can also run without a MySQL
server, this script loads the CSVs into SQLite and adds the four MySQL date
functions the queries use (DATE_FORMAT, DATEDIFF, PERIOD_DIFF). The SQL files
are run exactly as written.

Usage:
    python run_queries.py
"""
import sqlite3
from datetime import datetime
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).parent
DATA, SQL, RESULTS = ROOT / "data", ROOT / "sql", ROOT / "results"


def _parse(value):
    return datetime.fromisoformat(str(value)[:19])


def date_format(value, fmt):
    return None if value is None else _parse(value).strftime(fmt)


def datediff(a, b):
    if a is None or b is None:
        return None
    return (_parse(a).date() - _parse(b).date()).days


def period_diff(p1, p2):
    y1, m1 = divmod(int(p1), 100)
    y2, m2 = divmod(int(p2), 100)
    return (y1 * 12 + m1) - (y2 * 12 + m2)


def connect():
    con = sqlite3.connect(ROOT / "retail.db")
    con.create_function("DATE_FORMAT", 2, date_format, deterministic=True)
    con.create_function("DATEDIFF", 2, datediff, deterministic=True)
    con.create_function("PERIOD_DIFF", 2, period_diff, deterministic=True)
    return con


def load(con):
    for table in ["customers", "products", "orders", "order_items"]:
        pd.read_csv(DATA / f"{table}.csv", dtype={"stock_code": str, "invoice_no": str}) \
          .to_sql(table, con, if_exists="replace", index=False)
    con.execute("CREATE INDEX IF NOT EXISTS ix_items_inv ON order_items(invoice_no)")
    con.execute("CREATE INDEX IF NOT EXISTS ix_orders_cust ON orders(customer_id)")
    con.executescript((SQL / "03_views.sql").read_text())


def main():
    con = connect()
    load(con)
    RESULTS.mkdir(exist_ok=True)
    pd.set_option("display.width", 160)
    for path in sorted((SQL / "analysis").glob("*.sql")):
        result = pd.read_sql_query(path.read_text(), con)
        result.to_csv(RESULTS / f"{path.stem}.csv", index=False)
        print(f"\n== {path.stem} ({len(result)} rows)")
        print(result.to_string(index=False, max_rows=30))
    con.close()


if __name__ == "__main__":
    main()
