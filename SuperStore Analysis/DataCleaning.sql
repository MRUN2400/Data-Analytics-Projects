use superstore;
select * from storedata;
-- change data format
update storedata
set Order_data_new = str_to_date(Order_Date,'%m/%d/%Y');
alter table storedata
add Order_data_new date;

alter table storedata
add ship_date_new date;
update storedata
set Ship_date_new = str_to_date(Ship_Date,'%m/%d/%Y');

-- add snake_case_with_underscores
alter table storedata
rename column `Ship Date` to Ship_Date,
rename column `Order Date` to Order_Date,
rename column `Order ID` to Order_ID,
rename column `Ship Mode` to Ship_Mode,
rename column `Customer Name` to Customer_Name,
rename column `Postal Code` to Postal_Code,
rename column `Product ID` to Product_ID,
rename column `Sub-Category` to Sub_Category,
rename column `Product Name` to Product_Name;
alter table storedata
rename column `Order_data_new` to Order_date_new;

-- remove duplicates 
select count(*),Customer_Name,Customer_ID, Order_ID,  Order_date_new,Ship_date_new, Category,Sub_Category
from storedata
group by Customer_ID ,Customer_Name,Order_ID, Category,Sub_Category, Order_date_new,Ship_date_new
having count(*)>1;

with duplicate_cte as(
select *,
row_number() over(partition by Customer_Name, Customer_ID,Category,Sub_Category order by Order_ID ) as row_num
from storedata
)  
select * from duplicate_cte
where row_num>1;

with duplicate_cte as(
select *,
row_number() over(partition by Customer_Name, Customer_ID,Category,Sub_Category order by Order_ID ) as row_num
from storedata
)  
delete from storedata
where order_id in
(select Order_ID from duplicate_cte
where row_num>1);

DELETE s1
FROM storedata s1
JOIN storedata s2
ON s1.Customer_ID = s2.Customer_ID
AND s1.Customer_Name = s2.Customer_Name
AND s1.Category = s2.Category
AND s1.Sub_Category = s2.Sub_Category
AND s1.Order_ID > s2.Order_ID;

-- delete redundant columns
ALTER TABLE storedata
drop column Order_Date;

ALTER TABLE storedata
drop column  ship_Date;

-- null values
select * from storedata
where postal_code is null;

-- avegrage sales per category 
select Category, Sub_Category, round(avg(Sales),2) as AVG_Sales
from storedata
group by Category,Sub_Category;

-- total profit & sales
select Round(sum(Sales),2)as Total_Sales from storedata;
select round(sum(Profit),2) as Total_Profit from storedata;
select count(distinct Customer_Name) as Total_Customers from storedata;
select count(distinct Order_ID) as Total_Orders from storedata;
-- ship_mode analysis
select Ship_Mode,
Round(sum(Sales),2)as Total_Sales, round(sum(Profit),2) as Total_Profit
from storedata
group by Ship_Mode;

-- Top customers analysis: Top , Repeat, segment 
select Customer_ID ,Customer_Name , sales
from storedata
order by sales desc
limit 10;
select Customer_ID ,Customer_Name, Category,Sub_Category
from storedata
where order_id <2
group by  Customer_ID ,Customer_Name, Category,Sub_Category;
SELECT segment,
 Round(sum(Sales),2)as Total_Sales, round(sum(Profit),2) as Total_Profit
FROM storedata
GROUP BY segment;

select Customer_ID ,Customer_Name ,Category , sales,
Rank() Over(Partition by Category order by sales desc ) as Highest_Sales_by_Category
from storedata;

-- Product analysis: Best Selling,Most Profitable,Loss making products
select Category,Sub_Category,round(sum(Sales),3) as Total_sales
from storedata
group by Category,Sub_Category
order by sum(Sales) desc;

select Category,Sub_Category,round(sum(Profit),3) as Total_Profit
from storedata
group by Category,Sub_Category
order by sum(Profit) desc;

select Product_ID,Sub_Category,Profit
from storedata
where Profit<0
group by Product_ID,Sub_Category,Profit;

-- Location analysis: Most & least profitable places
select State,City,sum(Sales) as Total_sales
from storedata
group by State,City
order by sum(Sales) desc;

select State,City,Profit
from storedata
where Profit<0
group by State,City,Profit;

-- Monthly & yearly trends
SELECT 
    YEAR(order_date_new) AS year,
    MONTH(order_date_new) AS month,
Round(sum(Sales),2)as Total_Sales, round(sum(Profit),2) as Total_Profit
FROM storedata
GROUP BY year, month
ORDER BY year, month;