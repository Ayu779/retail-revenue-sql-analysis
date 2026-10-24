"""
Draw the README charts from the query results in results/.

Usage:
    python make_charts.py
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).parent
RESULTS, CHARTS = ROOT / "results", ROOT / "charts"

BLUE, ORANGE, GREY = "#2a78d6", "#eb6834", "#b4b2a9"
INK, INK_2 = "#0b0b0b", "#52514e"
plt.rcParams.update({
    "figure.facecolor": "#fcfcfb", "axes.facecolor": "#fcfcfb",
    "axes.edgecolor": "#d3d1c7", "axes.labelcolor": INK_2,
    "xtick.color": INK_2, "ytick.color": INK_2, "text.color": INK,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.grid": True, "grid.color": "#ecebe6", "grid.linewidth": 0.8,
    "axes.axisbelow": True, "font.size": 10, "axes.titlesize": 12,
    "axes.titlelocation": "left",
})


def read(name):
    return pd.read_csv(RESULTS / f"{name}.csv")


def save(fig, name):
    fig.tight_layout()
    fig.savefig(CHARTS / f"{name}.png", dpi=160)
    plt.close(fig)


def monthly_trend():
    t = read("q1_monthly_trend")
    t["year"], t["m"] = t.month.str[:4], t.month.str[5:].astype(int)
    fig, ax = plt.subplots(figsize=(8, 3.8))
    for year, color, width in [("2010", GREY, 1.8), ("2011", BLUE, 2.2)]:
        d = t[t.year == year]
        ax.plot(d.m, d.revenue / 1000, color=color, lw=width, marker="o", ms=4, label=year)
    last = t[t.month == "2011-12"]
    ax.annotate("Dec 2011 runs\nto the 9th only", (12, last.revenue.iloc[0] / 1000),
                xytext=(9.3, 380), fontsize=9, color=INK_2,
                arrowprops=dict(arrowstyle="-", color="#888780", lw=0.8))
    ax.set_xticks(range(1, 13))
    ax.set_xticklabels(["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
    ax.set_ylabel("Revenue (GBP thousands)")
    ax.set_ylim(0, None)
    ax.set_title("Monthly revenue: flat year on year, with a big Q4 peak")
    ax.legend(frameon=False, loc="upper left")
    save(fig, "monthly_revenue")


def concentration():
    t = read("q2_customer_concentration")
    fig, ax = plt.subplots(figsize=(7, 3.6))
    colors = [ORANGE] + [BLUE] * (len(t) - 1)
    ax.bar(t.decile.astype(str), t.revenue_share_pct, color=colors, width=0.6)
    for x, v in zip(range(len(t)), t.revenue_share_pct):
        ax.text(x, v + 1, f"{v:.0f}%", ha="center", fontsize=9, color=INK_2)
    ax.set_xticks(range(len(t)))
    ax.set_xticklabels(["Top 10%"] + [f"{10 * d - 9}-{10 * d}%" for d in t.decile[1:]], fontsize=8)
    ax.set_ylabel("Share of revenue (%)")
    ax.set_xlabel("Customers ranked by lifetime revenue, in groups of 10%")
    ax.set_title("The top 10% of customers bring in most of the revenue")
    save(fig, "customer_concentration")


def cohorts():
    t = read("q5_cohort_retention").set_index("cohort")
    cols = ["m1_pct", "m2_pct", "m3_pct", "m6_pct", "m12_pct"]
    grid = t[cols].values
    fig, ax = plt.subplots(figsize=(6.4, 5))
    ax.grid(False)
    im = ax.imshow(grid, cmap=plt.matplotlib.colors.LinearSegmentedColormap.from_list(
        "blue", ["#f1f6fd", "#9ec5f4", "#2a78d6", "#104281"]), vmin=0, vmax=35, aspect="auto")
    for i in range(grid.shape[0]):
        for j in range(grid.shape[1]):
            v = grid[i, j]
            ax.text(j, i, f"{v:.0f}%", ha="center", va="center", fontsize=8.5,
                    color="#ffffff" if v > 22 else INK)
    ax.set_xticks(range(len(cols)))
    ax.set_xticklabels(["Month 1", "Month 2", "Month 3", "Month 6", "Month 12"])
    ax.set_yticks(range(len(t)))
    ax.set_yticklabels([f"{c} ({n})" for c, n in zip(t.index, t.cohort_size)], fontsize=8.5)
    ax.set_ylabel("First-order month (customers)")
    ax.set_title("Share of each 2010 cohort ordering again")
    for spine in ax.spines.values():
        spine.set_visible(False)
    save(fig, "cohort_retention")


def rfm():
    t = read("q6_rfm_segments").iloc[::-1]
    y = np.arange(len(t))
    fig, ax = plt.subplots(figsize=(7.5, 4))
    ax.barh(y + 0.2, t.customer_share_pct, height=0.36, color=GREY, label="Share of customers")
    ax.barh(y - 0.2, t.revenue_share_pct, height=0.36, color=BLUE, label="Share of revenue")
    for yi, v in zip(y, t.revenue_share_pct):
        ax.text(v + 0.8, yi - 0.2, f"{v:.0f}%", va="center", fontsize=8.5, color=INK_2)
    ax.set_yticks(y)
    ax.set_yticklabels(t.segment)
    ax.set_xlabel("%")
    ax.set_title("RFM segments: a quarter of customers, 70% of revenue")
    ax.legend(frameon=False, loc="lower right")
    save(fig, "rfm_segments")


def new_customers():
    t = read("q8_new_vs_returning")
    t["year"], t["m"] = t.month.str[:4], t.month.str[5:].astype(int)
    t = t[t.m.between(6, 11)]
    labels = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
    x = np.arange(len(labels))
    fig, ax = plt.subplots(figsize=(7, 3.6))
    for offset, (year, color) in zip([-0.2, 0.2], [("2010", GREY), ("2011", BLUE)]):
        d = t[t.year == year]
        ax.bar(x + offset, d.new_customers, width=0.38, color=color, label=year)
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.set_ylabel("First-time customers")
    ax.set_title("Fewer first-time customers each month in 2011")
    ax.legend(frameon=False, loc="upper left")
    save(fig, "new_customers")


if __name__ == "__main__":
    CHARTS.mkdir(exist_ok=True)
    monthly_trend()
    concentration()
    cohorts()
    rfm()
    new_customers()
    print("charts written to", CHARTS)
