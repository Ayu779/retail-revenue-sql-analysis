# Cleaning log

| Step | Rows |
|---|---:|
| Raw rows (both sheets) | 1,067,371 |
| After dropping exact duplicate rows | 1,033,036 |
| After dropping 2 bulk orders cancelled within a day (entry errors) and their reversals | 1,033,032 |
| After dropping bad-debt (A) invoices | 1,033,026 |
| After dropping fees, postage, vouchers, tests (net value GBP 75,749) | 1,027,233 |
| After dropping zero or negative prices | 1,021,268 |
| After dropping stock adjustments | 1,021,268 |

- Orders: 46,918 (7,404 cancellations)
- Order lines: 1,021,268
- Products: 4,909
- Customers with an ID: 5,875
- Sales lines with no customer ID: 22.6% of lines, 13.3% of revenue
- Date range: 01 Dec 2009 to 09 Dec 2011
