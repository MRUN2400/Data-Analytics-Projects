use superstore;
select * from storedata;
select Customer_Name, sum(Sales),
case
  when sum(Sales)>1000 then 'High Profit'
  when sum(Sales) between 500 and 1000 then "Medium Profit"
  else 'Low Profit'
end as customer_segment
from storedata
group by Customer_Name;

select City , round(avg(Profit),2) as Total_Revenue
from storedata
group by City
order by round(avg(Profit),2) desc;

select row_number() over(order by round(avg(Profit),2) desc) as Serial_No,
City , round(avg(Profit),2) as Total_Revenue,
case 
 when round(avg(Profit),2)>300 then "High Revenue"
 when round(avg(Profit),2) between 100 and 300 then "Medium Revenue"
 else "Low Revenue"
end as City_Revenue
from storedata
group by City;

SELECT
    order_id,
    sales,
    profit,
	sales - profit AS difference,
    CASE
        WHEN profit > 0 THEN 'Profitable'
        WHEN profit = 0 THEN 'Break Even'
        ELSE 'Loss Making'
    END AS order_status
FROM storedata;

-- 5.Find customers whose spending is above average customer spending.
with customer_spending as (
 select Customer_Name ,  round(sum(Sales),2) as Total_Spending
 from storedata
 group by Customer_Name
)
select * from customer_spending
where Total_Spending>(
 select  avg(Total_Spending) from customer_spending
);

-- 6.Find cities whose profit is above overall average city profit.
with city_profit as(
 select City , round(sum(Profit),2) as Total_Profit
 from storedata
 group by City 
)
select *,
row_number() over(order by Total_Profit desc) as Serial_No from  city_profit
where Total_Profit>
(
select  avg(Total_Profit) from city_profit
);

with product_profit as(
 select Product_Name , round(sum(Profit),2) as Total_Profit
 from storedata
 group by Product_Name
),
revenue_rank as(
 select  Product_Name,Total_Profit,
 round(sum(Total_Profit) over( order by Total_Profit desc),2)as Rolling_total,
 round(sum(Total_Profit) over(),2) as Total_revenue
 from product_profit
)
select Product_Name,Total_Profit,Rolling_total,Total_revenue
from revenue_rank
where Rolling_total<=0.5*Total_revenue;

-- 8.Find top customer in every city.
with customer_sales as(
 select Customer_Name ,City, round(sum(Sales),2) as Total_Sales
 from storedata
 group by City,Customer_Name
),
ranked_customers as(
select Customer_Name ,City,Total_Sales,
rank() over(partition by city order by Total_Sales desc ) as the_rank
from customer_sales
)
select Customer_Name ,City,Total_Sales,the_rank
from ranked_customers
where the_rank=1;

-- 12.Compare current order sales with previous order.
select Customer_Name,Sales,Order_date_new,
lag(Order_ID) over (partition by Customer_Name order by Order_date_new)  as pervious_order
from storedata;
-- 13.Find month-over-month sales growth.
select Customer_Name,Sales,Order_date_new,
lag(Sales) over ( order by Order_date_new)  as month_over_sales
from storedata;

-- 15.Find top 3 products in each category.
with top_products as(
select Sub_Category,Product_Name, round(sum(Sales),2) as Total_Sales
from storedata
group by Sub_Category,Product_Name
),
ranked_products as(
 select Sub_Category,Product_Name,Total_Sales,
 dense_rank() over (partition by Sub_Category order by Total_Sales) as The_rank
 from top_products
)
select * from ranked_products
where The_rank<=3;

-- 14.Create customer loyalty score.
with customer_loyalty as(
 select Customer_ID,Customer_Name, COUNT(DISTINCT order_id) AS total_orders,SUM(sales) AS total_sales
 from storedata
 group by Customer_ID,Customer_Name
 order by COUNT(DISTINCT order_id) desc
),
categories as(
 select Customer_ID,Customer_Name, total_orders,total_sales,
 case
  when total_orders>=4 then 'Golden'
  when total_orders between 2 and 4 then 'silver'
  else  'Brozen'
 end as sub_ranking
  from customer_loyalty
)
select * from categories;

-- 16.Ientify rising and declining products.
WITH monthly_sales AS
(
    SELECT
        product_name,
        YEAR(order_date_new) AS yr,
        MONTH(order_date_new) AS mn,
        SUM(sales) AS total_sales

    FROM storedata

    GROUP BY
        product_name,
        YEAR(order_date_new),
        MONTH(order_date_new)
),

sales_comparison AS
(
    SELECT
        product_name,
        yr,
        mn,
        total_sales,

        LAG(total_sales)
        OVER
        (
            PARTITION BY product_name
            ORDER BY yr, mn
        ) AS previous_month_sales

    FROM monthly_sales
)

SELECT
    product_name,
    yr,
    mn,
    total_sales,
    previous_month_sales,

CASE
 WHEN previous_month_sales IS NULL THEN 'No Previous Data'
 WHEN total_sales > previous_month_sales THEN 'Rising'
 WHEN total_sales < previous_month_sales THEN 'Declining'
 ELSE 'Stable'
    END AS product_trend
FROM sales_comparison;

-- 19. Find Top 5 products contributing most revenue.
with top_products as (
select Product_Name,Sub_Category, round(sum(Profit),2) as Total_Profit
from storedata
group by Product_Name,Sub_Category
),
revenue_rank as (
select Product_Name,Sub_Category, Total_Profit,
dense_rank() over(order by Total_Profit desc) as The_Rank
from top_products
)
select Product_Name,Sub_Category, Total_Profit,The_Rank
from revenue_rank
where The_Rank<=5;

-- 20. Find customers contributing to top 50% of revenue.(Pareto Analysis)
with top_products as (
select Product_Name,Sub_Category, round(sum(Profit),2) as Total_Profit
from storedata
group by Product_Name,Sub_Category
),
revenue_rank as (
select Product_Name,Sub_Category, Total_Profit,
round(sum(Total_Profit) over( order by Total_Profit desc),2) as Rolling_total,
round(sum(Total_Profit) over(),2) as Total_revenue
from top_products
)
select Product_Name,Sub_Category,Total_revenue ,Rolling_total
from revenue_rank
where Total_revenue*0.5 >Rolling_total;

-- 22. Find most profitable product in each category.
with Product as (
select Product_Name,Sub_Category, round(sum(Profit),2) as Total_Profit
from storedata
group by Product_Name,Sub_Category
),
top_product as (
select Product_Name,Sub_Category, Total_Profit , 
dense_rank() over( partition by Sub_Category order by Total_Profit desc) as The_rank
from Product
)
select Product_Name,Sub_Category, Total_Profit , The_rank
from top_product 
where The_rank=1;

-- 23. Find cities whose profit rank improved over time.
with city_rank as(
 select City, round(sum(Profit),2) as Total_Profit , date_format(Order_date_new, '%Y-%m') as monthly
 from storedata
 group by City,monthly
),
ranked_city as(
 select  City, Total_Profit , monthly, dense_rank() over (partition by monthly order by Total_Profit desc) as city_rankk
 from city_rank
),
rank_changed as(
 select  City, Total_Profit , monthly, city_rankk, lag(city_rankk) over(partition by city order by monthly) as perv_rank
 from ranked_city
)
select * from rank_changed
where city_rankk>perv_rank;

-- High sales but low profit products
WITH customer_data AS (
    SELECT
        Customer_Name,
        SUM(Sales) AS total_sales,
        SUM(Profit) AS total_profit
    FROM storedata
    GROUP BY Customer_Name
)

SELECT
    Customer_Name,
    total_sales,
    total_profit,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
    RANK() OVER (ORDER BY total_profit ASC) AS low_profit_rank
FROM customer_data;