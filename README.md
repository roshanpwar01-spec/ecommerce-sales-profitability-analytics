# Indian E-Commerce Sales & Profitability Analytics

An end-to-end Business/Data Analytics project analyzing profitability, regional performance, and pricing trends for a simulated Indian e-commerce business — built with **MySQL, Python, and Power BI**, and backed by statistical hypothesis testing.

---

## Business Problem

An Indian e-commerce company wants to understand which products are profitable vs loss-making, which states drive the most orders and revenue, and how pricing tiers vary regionally — to guide inventory, pricing, and marketing decisions for the next quarter.

**Stakeholders:**
- **Category Manager** — wants product/category-wise profit-loss visibility
- **Regional Sales Head** — wants state-wise order volume and price sensitivity
- **Finance** — wants to know where the business is making vs losing money

**Key Business Questions:**
1. Which products/categories generate the most profit vs loss?
2. Which state places the highest number of orders, and drives the most profit?
3. What price range sells best in each state?
4. Is profitability variation across categories/states statistically meaningful, or random?
5. What actions should the business take next quarter?

---

## Dataset & Data Augmentation

Built on the *India E-Commerce Sales* dataset (Orders, Order Details, Sales Target). The original dataset (560 orders, 1,500 line items, 36 monthly targets) was too small to realistically showcase analytics at scale, so it was synthetically expanded in Python (pandas + NumPy) while preserving referential integrity and realistic business distributions.

| Table | Original Rows | Expanded Rows | Method |
|---|---|---|---|
| Orders | 560 | 10,000 | Randomly generated unique Order IDs, customer names, and geographically accurate state-city pairs; order dates spanning **April 2018 – December 2025** |
| Order Details | 1,500 | 5,000 | Order IDs sampled from the Orders table (referential integrity enforced — zero orphaned foreign keys); Amount/Profit generated via log-normal distributions calibrated per category |
| Sales Target | 36 | 1,000 | Extended monthly targets across the full 2018–2025 range, with an added Region dimension |

**Design decisions:**
- Realistic loss distribution preserved — ~44% of individual line items carry negative profit, consistent with the source data's pattern
- Random seed fixed for reproducibility
- Data intentionally left "messy" (nulls, whitespace, inconsistent casing, mixed date formats) to practice real-world data cleaning

---

## Data Cleaning (Python)

Cleaning performed in `Sales_performance_analysis.ipynb`:
- Removed duplicate rows across all 3 tables
- Converted `Order Date` to proper datetime (day-first format)
- Standardized text fields — `.str.title().str.strip()` on State, City, Category, Sub-Category to fix casing/whitespace inconsistencies
- Validated referential integrity between Order Details and Orders (checked for orphaned Order IDs)
- Engineered new features: `Year`, `Month`, `Month Number`, `Day` (from Order Date)
- Merged Orders + Order Details into a single transactional table (`Retail_Sales_Cleaned.csv`, **5,000 rows × 16 columns**)
- Derived business metrics: `Profit Margin (%)` and `Average Price`

Cleaned outputs: `Orders_Cleaned.csv`, `Order_Details_Cleaned.csv`, `Retail_Sales_Cleaned.csv`

---

## SQL Analysis (MySQL Workbench)

Database: `ecommerce_india`. Six core objectives covering profitability, regional performance, pricing segmentation, target tracking, and loss analysis. Full queries in `e_commerce_report.sql`.

**Objective 1 — Profit & Loss by Category/Sub-Category**
Aggregated revenue, profit, and margin% per sub-category, sorted ascending to surface weakest performers first.

**Objective 2 — State-wise Performance**
Order volume, revenue, and profit by state using `COUNT(DISTINCT)` and `GROUP BY`.

**Objective 3 — Price-Band Segmentation**
`CASE WHEN` logic classifying transactions into Budget (<₹200) / Mid-Range (₹200–800) / Premium (>₹800) tiers by state.

**Objective 4 — Target vs Actual**
`JOIN` between transactional and target tables on a derived `month_year` key, with `CASE WHEN` status flagging (Achieved/Missed).

**Objective 5 — Loss-Making Orders Deep Dive**
Isolated negative-profit transactions and aggregated loss frequency by sub-category to distinguish systemic issues from one-off outliers.

**Objective 6 — `vw_ecommerce_master` View**
A pre-calculated view (with margin% and price-band already computed) built specifically for Power BI to connect to — decoupling the dashboard layer from raw table structure, mirroring how production BI teams structure the SQL-to-dashboard handoff.

```sql
CREATE VIEW vw_ecommerce_master AS
SELECT 
    `Order ID`, `Order Date`, CustomerName, State, City, Year, Month, month_year,
    Category, `Sub-Category`, Amount, Profit, Quantity,
    ROUND(Profit / NULLIF(Amount, 0) * 100, 2) AS profit_margin_pct,
    CASE 
        WHEN Amount < 200 THEN 'Budget'
        WHEN Amount BETWEEN 200 AND 800 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS price_band
FROM retail_sales_master;
```

---

## Statistical Validation (Python)

To validate that observed patterns were genuine rather than random noise, two hypothesis tests were run on `vw_ecommerce_master` (`ecommerce_report_test_s.ipynb`, using `mysql-connector-python` + `scipy.stats`):

**1. Welch's T-test — Furniture vs Clothing Profit**
```
t = 3.445, p = 0.0006
```
Statistically significant (p < 0.05). Furniture generates significantly higher profit per transaction than Clothing — not due to random variation.

**2. Chi-square Test of Independence — State vs Price Band**
```
χ² = 346.454, p < 0.0001
```
Statistically significant. Price-band preference (Budget/Mid-Range/Premium) genuinely varies by state rather than being randomly distributed — supporting a region-specific pricing strategy.

---

## Power BI Dashboard

A 4-page interactive dashboard (`e_commerce_report.pbix`) connected directly to `vw_ecommerce_master`, with slicers, cross-filtering, and page-navigation buttons.

**Page 1 — Executive Summary**
KPI cards (Total Revenue ₹92,26,064.78 | Total Profit ₹4,53,853.81 | Total Orders 3,339 | Profit Margin 4.92%), Revenue by Category donut chart, Revenue Trend by Year line chart.

**Page 2 — Regional Analysis**
Revenue by State bar chart, State-wise Performance Summary table, Price Band Distribution by State (stacked bar).

**Page 3 — Product Analysis**
Profit by Sub-Category bar chart (sorted ascending), Category Performance Details table with margin%, Top Loss-Making Orders table.

**Page 4 — Recommendations**
Key findings paired with actionable business recommendations, e.g.:
- *Finding:* Kurti generates the lowest profit (₹6,730, 1.99% margin) despite high order volume (178 orders) → *Recommendation:* review pricing/cost structure
- *Finding:* Premium price-band dominates nearly every state's revenue mix → *Recommendation:* test a budget-tier push in top-performing states
- *Finding:* Kerala shows a notably higher margin (~7.6%) than high-revenue states like Delhi (~3.5%) → *Recommendation:* study Kerala's mix as a model for other states

---

## Key Business Insights

- All 17 sub-categories remain net profitable in aggregate, despite ~44% of individual transactions being loss-making — indicating losses are concentrated in specific order conditions rather than being a structural sub-category problem
- Furniture is statistically confirmed as more profitable than Clothing (t=3.445, p=0.0006), despite Clothing having higher order volume
- Premium-tier pricing dominates almost every state's revenue mix, with a statistically confirmed regional variation (χ²=346.454, p<0.0001) — supporting targeted, region-specific pricing strategy
- Revenue peaked in 2018–19 (~₹1.4M) before declining through 2020–21, with partial recovery from 2022 onward

---

## Tech Stack
`Python (Pandas, NumPy, SciPy)` · `MySQL / MySQL Workbench` · `Power BI (DAX, Data Modeling)` · `Statistical Testing (T-test, Chi-square)`

## Files
- `Sales_performance_analysis.ipynb` — data cleaning & feature engineering
- `e_commerce_report.sql` — all 6 SQL objectives + view creation
- `ecommerce_report_test_s.ipynb` — statistical hypothesis testing
- `e_commerce_report.pbix` — 4-page Power BI dashboard
- `Orders_Cleaned.csv`, `Order_Details_Cleaned.csv`, `Retail_Sales_Cleaned.csv` — cleaned datasets
