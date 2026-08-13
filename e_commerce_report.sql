-- Objective 1: Profit & Loss by Category and Sub-Category

-- Business Question: Which product categories and sub-categories are the most/least profitable?

Select category,
`Sub-Category`,
	count(*) as total_order,
	Sum(amount) as total_revenue,
    SUM(Profit) AS total_profit,
    ROUND(SUM(Profit) / SUM(Amount) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(Profit), 2) AS avg_profit_per_order
    from retail_sales_master
    GROUP BY Category, `Sub-Category`
	ORDER BY total_profit ASC;
    
    -- Objective 2: State-wise Order Volume, Revenue & Profit
    -- Which states drive the most orders, revenue, and profit — and which underperform?
    
SELECT 
	State,
	count(distinct `order id`) as total_orders,
	round(sum(amount),2) as total_revenue,
	round(sum(profit),2) as total_profit,
	round(sum(profit)/sum(amount) * 100 ,2) as profit_margin
from retail_sales_master
group by State
order by total_revenue ASC;

-- Objective 3: Price-Band Segmentation by State
-- What price range (Budget/Mid/Premium) sells best in each state — are metro states buying premium while others buy budget?

Select 
	State,
	case 
		when amount < 200 then 'Budget'
		when amount between 200 and 800 then 'Mid-Range'
		else 'Premium'
	end as price_band,
    count(*) as total_order,
    round(sum(Amount),2) as total_revenue,
    round(avg(amount),2) as avg_price
from retail_sales_master
group by State,price_band
order by state,
	case price_band
    when 'Budget' then 1
    when 'mid_range' then 2
    else 3
    end;

-- Objective 4: Monthly Actual Sales vs Sales Target
-- Are categories hitting their monthly sales targets — where are we exceeding or falling short?

Select 
	a.month_year,
    a.category,
    round(sum(a.amount),2) as actual_revenue,
    t.target,
    CASE	
		 When sum(amount)>= t.target then'Achieved'
         else 'missed'
	end AS Status
from retail_sales_master a
join sales_target t 
	on a.month_year = t.month_year and a.category = t.category
group by a.month_year,a.Category,t.Target
order by a.month_year;


-- Objective 5: Loss-Making Orders Deep Dive
-- Which specific orders/categories are dragging down profit the most?

SELECT
	`order id` ,
    Category,
    `sub-category`,
    amount,
    profit
	from retail_sales_master
    where profit < 0
    order by profit asc
    limit 20;
    
SELECT 
    Category,
    `Sub-Category`,
    COUNT(*) AS loss_order_count,
    SUM(Profit) AS total_loss
FROM retail_sales_master
WHERE Profit < 0
GROUP BY Category, `Sub-Category`
ORDER BY loss_order_count DESC;

-- Objective 6: Create vw_ecommerce_master View for Power BI
-- A clean, pre-aggregated view that Power BI will connect to directly instead of pulling raw tables.

DROP VIEW IF EXISTS vw_ecommerce_master;

CREATE VIEW vw_ecommerce_master AS
SELECT 
    `Order ID`,
    `Order Date`,
    CustomerName,
    State,
    City,
    Year,
    Month,
    month_year,
    Category,
    `Sub-Category`,
    Amount,
    Profit,
    Quantity,
    ROUND(Profit / NULLIF(Amount, 0) * 100, 2) AS profit_margin_pct,
    CASE 
        WHEN Amount < 200 THEN 'Budget'
        WHEN Amount BETWEEN 200 AND 800 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS price_band
FROM retail_sales_master;

SELECT * FROM vw_ecommerce_master LIMIT 10;