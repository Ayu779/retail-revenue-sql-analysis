"""
Clean the UCI Online Retail II workbook into four MySQL-ready tables.

Usage:
    python clean.py path/to/online_retail_II.xlsx

Writes data/orders.csv, data/order_items.csv, data/products.csv,
data/customers.csv and data/cleaning_log.md.
"""
import sys
from pathlib import Path

import pandas as pd

OUT = Path(__file__).parent / "data"

# Stock codes that are fees, postage, adjustments or tests, not products.
NON_PRODUCT_CODES = {
    "POST", "DOT", "C2", "M", "m", "D", "S", "B", "BANK CHARGES", "AMAZONFEE",
    "CRUK", "ADJUST", "ADJUST2", "TEST001", "TEST002",
}


def main(xlsx_path):
    sheets = pd.read_excel(xlsx_path, sheet_name=None,
                           dtype={"Invoice": str, "StockCode": str})
    df = pd.concat(sheets.values(), ignore_index=True)
    df.columns = ["invoice_no", "stock_code", "description", "quantity",
                  "invoice_date", "unit_price", "customer_id", "country"]
    log = [("Raw rows (both sheets)", len(df))]

    df = df.drop_duplicates()
    log.append(("After dropping exact duplicate rows", len(df)))

    # Entry errors: a line of 10,000+ units cancelled in full by the same customer
    # within a day. Only two lines match (74,215 jars and 80,995 paper crafts,
    # both reversed within 20 minutes). Drop the sale and its cancellation.
    big = df[df.quantity >= 10_000]
    errors = big.merge(df, on=["customer_id", "stock_code"], suffixes=("", "_c"))
    errors = errors[(errors.quantity_c == -errors.quantity)
                    & (errors.invoice_date_c - errors.invoice_date).between(pd.Timedelta(0), pd.Timedelta("1D"))]
    error_keys = set(zip(errors.invoice_no, errors.stock_code)) | set(zip(errors.invoice_no_c, errors.stock_code))
    df = df[[k not in error_keys for k in zip(df.invoice_no, df.stock_code)]]
    log.append((f"After dropping {len(errors)} bulk orders cancelled within a day (entry errors) and their reversals", len(df)))

    # 'A' invoices are bad-debt write-offs, not sales.
    df = df[~df.invoice_no.str.startswith("A")]
    log.append(("After dropping bad-debt (A) invoices", len(df)))

    is_fee = df.stock_code.isin(NON_PRODUCT_CODES) | df.stock_code.str.startswith("gift_")
    fee_value = (df.loc[is_fee, "quantity"] * df.loc[is_fee, "unit_price"]).sum()
    df = df[~is_fee]
    log.append((f"After dropping fees, postage, vouchers, tests (net value GBP {fee_value:,.0f})", len(df)))

    df = df[df.unit_price > 0]
    log.append(("After dropping zero or negative prices", len(df)))

    # A non-cancelled line with negative quantity is a stock adjustment.
    df["is_cancellation"] = df.invoice_no.str.startswith("C").astype(int)
    df = df[~((df.is_cancellation == 0) & (df.quantity <= 0))]
    log.append(("After dropping stock adjustments", len(df)))

    df["customer_id"] = df.customer_id.astype("Int64")
    df["description"] = df.description.str.strip()

    # One description per product: the one used most often.
    named = (df.dropna(subset=["description"])
               .groupby(["stock_code", "description"]).size().reset_index(name="n")
               .sort_values(["stock_code", "n"], ascending=[True, False])
               .drop_duplicates("stock_code")[["stock_code", "description"]])
    products = (pd.DataFrame({"stock_code": df.stock_code.unique()})
                  .merge(named, on="stock_code", how="left")
                  .sort_values("stock_code"))

    # Customer home country: the one they order from most.
    customers = (df.dropna(subset=["customer_id"])
                   .groupby(["customer_id", "country"]).size().reset_index(name="n")
                   .sort_values(["customer_id", "n"], ascending=[True, False])
                   .drop_duplicates("customer_id")[["customer_id", "country"]])

    orders = (df.groupby("invoice_no")
                .agg(customer_id=("customer_id", "first"),
                     invoice_date=("invoice_date", "min"),
                     country=("country", "first"),
                     is_cancellation=("is_cancellation", "first"))
                .reset_index())

    items = df[["invoice_no", "stock_code", "quantity", "unit_price"]].reset_index(drop=True)
    items.insert(0, "line_id", items.index + 1)

    OUT.mkdir(exist_ok=True)
    orders["invoice_date"] = orders.invoice_date.dt.strftime("%Y-%m-%d %H:%M:%S")
    for name, table in [("orders", orders), ("order_items", items),
                        ("products", products), ("customers", customers)]:
        table.to_csv(OUT / f"{name}.csv", index=False)

    sales = df[df.is_cancellation == 0]
    lines = ["# Cleaning log", "", "| Step | Rows |", "|---|---:|"]
    lines += [f"| {step} | {rows:,} |" for step, rows in log]
    lines += [
        "",
        f"- Orders: {len(orders):,} ({orders.is_cancellation.sum():,} cancellations)",
        f"- Order lines: {len(items):,}",
        f"- Products: {len(products):,}",
        f"- Customers with an ID: {len(customers):,}",
        f"- Sales lines with no customer ID: {sales.customer_id.isna().mean():.1%}"
        f" of lines, {(sales.customer_id.isna() * sales.quantity * sales.unit_price).sum() / (sales.quantity * sales.unit_price).sum():.1%} of revenue",
        f"- Date range: {df.invoice_date.min():%d %b %Y} to {df.invoice_date.max():%d %b %Y}",
    ]
    (OUT / "cleaning_log.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main(sys.argv[1])
