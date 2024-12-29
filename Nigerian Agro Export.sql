-- ●	What are the top-selling products?
SELECT product_name, SUM(export_value) AS total_revenue
FROM nigeria_agro_export.agro
GROUP BY product_name
ORDER BY total_revenue DESC;

-- ●	Which company has the highest sales revenue?
SELECT export_country, SUM(export_value) AS total_revenue
FROM nigeria_agro_export.agro
GROUP BY export_country
ORDER BY total_revenue DESC;

-- ●	How do sales vary across different export countries? 
SELECT export_country, product_name, SUM(export_value) AS total_revenue
FROM nigeria_agro_export.agro
GROUP BY Export_country, product_name
ORDER BY Export_country, total_revenue DESC;

-- ○	average revenue per country
SELECT export_country, AVG(export_value) AS average_revenue
FROM nigeria_agro_export.agro
GROUP BY Export_country
ORDER BY average_revenue DESC;

-- ○	Total units sold 
SELECT export_country, SUM(unit_sold) AS total_unit_sold
FROM nigeria_agro_export.agro
GROUP BY Export_country
ORDER BY total_unit_sold DESC;


-- ●	How do sales vary over time (monthly, quarterly, annually)?
SELECT YEAR(date) AS year_, MONTHNAME(date) month_name, SUM(export_value) AS total_revenue
FROM nigeria_agro_export.agro
GROUP BY year_, month_name, MONTH(date)
ORDER BY year_ ASC, MONTH(date) ASC;

-- ●	How do sales vary over time (quarterly, annually)?
SELECT YEAR(date) AS year_, QUARTER(date)  AS qtr, SUM(export_value) AS total_revenue
FROM nigeria_agro_export.agro
GROUP BY year_, qtr
ORDER BY year_ ASC, qtr ASC;

-- ●	How do sales vary over time (annually)?
SELECT YEAR(date) AS year_,  SUM(export_value) AS total_revenue
FROM nigeria_agro_export.agro
GROUP BY year_
ORDER BY year_ ASC;

-- Following up will be our Cost Analysis:

-- ●	What is the cost of goods sold (COGS) as a percentage of revenue?
SELECT total_revenue - profit AS COGS
FROM(
SELECT SUM(export_value) total_revenue, SUM(unit_sold * profit_per_unit) AS profit
FROM nigeria_agro_export.agro) AS cost_;

-- ●	How does the COGS vary across different products?
WITH cost_CTE AS(
SELECT product_name, SUM(export_value) total_revenue, SUM(unit_sold * profit_per_unit) AS profit
FROM nigeria_agro_export.agro
GROUP BY product_name)

SELECT product_name, total_revenue - profit AS cost
FROM cost_CTE
ORDER BY cost DESC;

-- Comparing current year Revenue with previous year Revenue
SELECT YEAR(date) AS year_, SUM(export_value) AS total_revenue, LAG(SUM(export_value)) OVER(ORDER BY YEAR(DATE)) AS prev_yr_rev
FROM nigeria_agro_export.agro
GROUP BY year_;

-- YOY Total_sales
WITH yoy AS(
SELECT YEAR(date) AS year_, SUM(export_value) AS total_revenue, LAG(SUM(export_value)) OVER(ORDER BY YEAR(DATE)) AS prev_yr_rev
FROM nigeria_agro_export.agro
GROUP BY year_)

SELECT year_, total_revenue, prev_yr_rev, total_revenue - prev_yr_rev AS yoy_diff
FROM yoy;

-- We can still work with our geographic data:

-- ●	Which destination ports receive the highest volume of exports?
SELECT destination_port, SUM(unit_sold) AS total_unit_sold
FROM nigeria_agro_export.agro
GROUP BY destination_port
ORDER BY total_unit_sold DESC;

-- ●	What are the transportation modes commonly used for export?
SELECT transportation_mode, COUNT(transportation_mode) AS transport_count
FROM nigeria_agro_export.agro
GROUP BY transportation_mode
ORDER BY transport_count DESC;

-- ●	Rank the destination port by the export value.
SELECT destination_port, SUM(export_value) AS total_revenue, RANK() OVER( ORDER BY SUM(export_value) DESC) AS destination_rank
FROM nigeria_agro_export.agro
GROUP BY destination_port;
-- ●	Show the top export product for each port.
WITH rank_CTE AS (
SELECT destination_port, product_name, SUM(export_value) AS total_revenue, RANK() OVER(PARTITION BY destination_port ORDER BY SUM(export_value) DESC) AS rank_
FROM nigeria_agro_export.agro
GROUP BY destination_port, product_name)

SELECT destination_port, product_name, total_revenue
FROM rank_CTE
WHERE rank_ = 1;

-- ●	How does each product perform in terms of profit margin?
-- profit_margin is the ratio of profit to revenue
WITH profit_margin_CTE AS(
SELECT product_name, SUM(export_value) AS total_revenue, SUM(unit_sold * profit_per_unit) AS profit
FROM nigeria_agro_export.agro
GROUP BY product_name)

SELECT product_name, ROUND((profit/total_revenue) * 100,2) AS profit_margin
FROM profit_margin_CTE;

