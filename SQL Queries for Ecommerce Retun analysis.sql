CREATE DATABASE Ecommerce_Return_Analysis;

USE Ecommerce_Return_Analysis;
	
CREATE TABLE Customers
(
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_age INT,
    customer_gender VARCHAR(20),
    region VARCHAR(50)
);

CREATE TABLE Products
(
    product_id VARCHAR(20) PRIMARY KEY,
    category VARCHAR(100)
);

CREATE TABLE Orders
(
    order_id VARCHAR(20) PRIMARY KEY,

    customer_id VARCHAR(20) NOT NULL,

    product_id VARCHAR(20) NOT NULL,

    price DECIMAL(10,2),

    quantity INT,

    discount DECIMAL(5,2),

    payment_method VARCHAR(50),

    order_date DATE,

    delivered_date DATE,

    total_amount DECIMAL(10,2),

    shipping_cost DECIMAL(10,2),

    profit_margin DECIMAL(10,2),

    CONSTRAINT FK_Customer
        FOREIGN KEY(customer_id)
        REFERENCES Customers(customer_id),

    CONSTRAINT FK_Product
        FOREIGN KEY(product_id)
        REFERENCES Products(product_id)
);

CREATE TABLE Returns
(
    order_id VARCHAR(20) PRIMARY KEY,

    returned VARCHAR(10),

    request_date DATE,

    return_reason VARCHAR(255),

    CONSTRAINT FK_Return
        FOREIGN KEY(order_id)
        REFERENCES Orders(order_id)
);

INSERT INTO Customers
SELECT
    customer_id,
    MAX(CAST(customer_age AS UNSIGNED)),
    MAX(customer_gender),
    MAX(region)
FROM Ecommerce_Staging
GROUP BY customer_id;

INSERT INTO Products
SELECT
    product_id,
    MAX(category)
FROM Ecommerce_Staging
GROUP BY product_id;

SELECT COUNT(*) as total_Customers FROM Customers;
SELECT COUNT(*) as Total_products  FROM Products;

INSERT INTO Orders
(
    order_id,
    customer_id,
    product_id,
    price,
    quantity,
    discount,
    payment_method,
    order_date,
    delivered_date,
    total_amount,
    shipping_cost,
    profit_margin
)
SELECT
    TRIM(order_id),
    TRIM(customer_id),
    TRIM(product_id),
    CAST(NULLIF(TRIM(price), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(quantity), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(discount), '') AS DECIMAL(5,2)),
    NULLIF(TRIM(payment_method), ''),
    STR_TO_DATE(NULLIF(TRIM(order_date), ''), '%Y-%m-%d'),
    STR_TO_DATE(NULLIF(TRIM(delivered_date), ''), '%Y-%m-%d'),
    CAST(NULLIF(TRIM(total_amount), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(shipping_cost), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(profit_margin), '') AS DECIMAL(10,2))
FROM Ecommerce_Staging
WHERE order_id IS NOT NULL
  AND TRIM(order_id) <> '';
  
INSERT INTO Returns
(
    order_id,
    returned,
    request_date,
    return_reason
)
SELECT
    TRIM(order_id),
    NULLIF(TRIM(returned), ''),
    STR_TO_DATE(NULLIF(TRIM(request_date), ''), '%Y-%m-%d'),
    NULLIF(TRIM(return_reason), '')
FROM Ecommerce_Staging
WHERE order_id IS NOT NULL
  AND TRIM(order_id) <> '';
  
INSERT INTO Returns
(
    order_id,
    returned,
    request_date,
    return_reason
)
SELECT
    TRIM(order_id),
    NULLIF(TRIM(returned), ''),
    STR_TO_DATE(NULLIF(TRIM(request_date), ''), '%Y-%m-%d'),
    NULLIF(TRIM(return_reason), '')
FROM Ecommerce_Staging
WHERE order_id IS NOT NULL
  AND TRIM(order_id) <> '';
  
SELECT
    (SELECT COUNT(*) FROM Ecommerce_Staging) AS staging_rows,
    (SELECT COUNT(*) FROM Customers) AS customers,
    (SELECT COUNT(*) FROM Products) AS products,
    (SELECT COUNT(*) FROM Orders) AS orders,
    (SELECT COUNT(*) FROM Returns) AS return_records,
    (
        SELECT COUNT(*)
        FROM Returns
        WHERE returned = 'Yes'
    ) AS actual_returns;
    
    SELECT COUNT(*) AS missing_customers
FROM Orders o
LEFT JOIN Customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_products
FROM Orders o
LEFT JOIN Products p
    ON o.product_id = p.product_id
WHERE p.product_id IS NULL;
------------------------------------------------------------------------
--- Overall Business KPIs. ---
------------------------------------------------------------------------
--- Total Orders ---
Select count(*) as Total_orders from orders;

-- Total Customers --
select count(*) as Total_Customers from customers;

-- Total Products --
Select count(*) as Total_products from Products;

-- Total Revenue --
Select ROUND(SUM(total_amount),2) as Total_Revenue from orders;

-- Total Profit --
Select ROUND(SUM(Profit_margin),2) as Total_profit from orders;

-- Average Order Value -- 
Select ROUND(AVG(total_amount),2) as Avg_Order_Value From Orders;

-- Total Returned Orders --
select COUNT(*) As Returned_orders
	from Returns
where Returned = 'Yes';

-- Return Rate --
SELECT
    COUNT(CASE WHEN returned = 'Yes' THEN 1 END) AS returned_orders,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(CASE WHEN returned = 'Yes' THEN 1 END)
        * 100.0 / COUNT(*),
        2
    ) AS return_rate_percentage
FROM Returns;

-- Non-Returned Orders --
select COUNT(*) As Returned_orders
	from Returns
where Returned = 'No';

-- Total Quantity Sold --
Select SUM(Quantity) as Total_quantity_Sold
from orders;

-- Average Discount --
Select ROUND(AVG(Discount),2) As Avg_discount 
from orders;

-- Total Shipping Cost --
Select ROUND(SUM(Shipping_cost),2 )AS Total_Shipping_Cost
from orders;

-- Average Shipping Cost Per Order --
Select ROUND(AVG(Shipping_Cost),2) as Avg_Shipping_Cost
from orders;

-- Profit Margin Percentage --
Select ROUND(SUM(Profit_Margin) * 100.0
	/ sum(total_amount) ,2) As profit_Margin_Percentage
from Orders;

-- Revenue Per Customer -- 
Select ROUND(SUM(total_amount)/
		COUNT(DISTINCT customer_id) ,2) as Revenue_Per_Customer
	from Orders;
    
-- Orders Per Customer --
select ROUND(COUNT(*) /COUNT(DISTINCT customer_id),2)
	as Orders_Per_customer
from orders;

--- Return Summary --
SELECT
    returned,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM Returns
GROUP BY returned;

-- Revenue by Return Status ---
Select R.returned,
	count(*) as Total_Orders,
    ROUND(SUM(o.Total_Amount),2) as Revenue 
from Orders o
JOIN Returns R 
ON O.order_id = R.order_id
GROUP BY Returned;

-- Estimated Revenue From Returned Orders --
Select
	ROUND(SUM(o.Total_Amount),2) as Revenue_From_Returned_Orders 
from Orders o
JOIN Returns R 
ON O.order_id = R.order_id
where R.returned ='Yes';

-- Estimated Profit Associated With Returns --
Select
    ROUND(SUM(o.Profit_Margin),2) As Profit_Associated_With_returns 
from Orders o
JOIN Returns R 
ON O.order_id = R.order_id
where R.returned ='Yes';

-- Combined KPI's Query -- 
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(DISTINCT o.product_id) AS total_products,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(SUM(o.profit_margin), 2) AS total_profit,
    ROUND(AVG(o.total_amount), 2) AS average_order_value,
    SUM(o.quantity) AS total_quantity_sold,
    COUNT(
        DISTINCT CASE
            WHEN r.returned = 'Yes'
            THEN o.order_id
        END
    ) AS returned_orders,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN r.returned = 'Yes'
                THEN o.order_id
            END
        ) * 100.0
        / COUNT(DISTINCT o.order_id),
        2
    ) AS return_rate_percentage
FROM Orders o
LEFT JOIN Returns r
    ON o.order_id = r.order_id;
------------------------------------------------
----------- Product Analysis --------------
----------------------------------------------
-- category generates the highest revenue
 Select P.Product_id,
	p.Category,
    ROUND(SUM(Total_Amount),2) As Revenue
From Orders O
JOIN Products p
ON O.product_id = P.Product_id 
GROUP BY P.Product_id,
	p.Category
Order By Revenue Desc Limit 1;

-- Category generating the lowest revenue 
 Select P.Product_id,
	p.Category,
    ROUND(SUM(Total_Amount),2) As Revenue
From Orders O
JOIN Products p
ON O.product_id = P.Product_id 
GROUP BY P.Product_id,
	p.Category
Order By Revenue Limit 1;
	
-- Category with the highest return rate -- 
Select p.category,
	COUNT(*) as total_orders,
    SUM(case when R.Returned = 'Yes' Then 1 else 0 end) As Returned_orders,
    ROUND(Sum(Case when R.Returned = 'Yes' Then 1 else 0 end)*100.0
			/COUNT(*) ,2) as Return_Rate 
	From
		Products P JOIN Orders O 
	ON p.Product_id = O.Product_Id 
Join Returns R
	ON R.order_id = O.order_id 
Group By P.Category
Order BY return_Rate desc
Limit 1;

-- Category with the lowest return rate -- 
Select p.category,
	COUNT(*) as total_orders,
    SUM(case when R.Returned = 'Yes' Then 1 else 0 end) As Returned_orders,
    ROUND(Sum(Case when R.Returned = 'Yes' Then 1 else 0 end)*100.0
			/COUNT(*) ,2) as Return_Rate 
	From
		Products P JOIN Orders O 
	ON p.Product_id = O.Product_Id 
Join Returns R
	ON R.order_id = O.order_id 
Group By P.Category
Order BY return_Rate 
Limit 1;

-- Top 10 revenue-generating products --
Select P.Product_Id,
	   P.Category,
       ROUND(SUM(O.Total_amount),2) as Revenue
	FROM
Orders O JOIN products p
ON O.Product_id = P.Product_id 
GROUP BY P.Product_Id,
			P.Category
Order BY Revenue DESC
LIMIT 10;
	
-- Bottom 10 revenue-generating products --
Select P.Product_Id,
	   P.Category,
       ROUND(SUM(O.Total_amount),2) as Revenue
	FROM
Orders O JOIN products p
ON O.Product_id = P.Product_id 
GROUP BY P.Product_Id,
			P.Category
Order BY Revenue 
LIMIT 10;

-- Top 10 most returned products --
Select O.Product_id,
	P.Category,
	Count(*) As Returned_Orders 
From Products P 
JOIN Orders O
ON p.Product_Id = O.product_id 
JOIN returns r
ON R.Order_id = O.Order_id 
Where R.Returned = 'YES'
Group by O.Product_id,
		P.category 
Order By returned_Orders Desc 
LIMIT 10 ;

-- Products that were never returned --
Select O.Product_id,
	P.Category,
	Count(*) As total_orders
From Products P 
JOIN Orders O
ON p.Product_Id = O.product_id 
JOIN returns r
ON R.Order_id = O.Order_id 
Group by O.Product_id,
		P.category 
HAVING
	SUM(Case When r.Returned = 'YES' Then 1 else 0 END ) = 0 
Order by total_orders Desc;

-- Average selling price by category -- 
Select P.category,
	ROUND(AVG(O.Total_Amount),2 ) As Avg_Selling_Price
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By p.Category 
Order By Avg_Selling_Price Desc;

-- Average quantity sold by category --
Select P.category,
	ROUND(AVG(O.Quantity),2) As Avg_Quantity_Sold
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By p.Category 
Order By Avg_Quantity_Sold Desc;

-- Category generating the highest profit -- 
Select P.category,
	ROUND(SUM(O.Profit_Margin),2) As Highest_Profit
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By p.Category 
Order By Highest_Profit Desc
Limit 1;

-- Category generating the lowest profit
Select P.category,
	ROUND(SUM(O.Profit_Margin),2 ) As Lowest_Profit
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By p.Category 
Order By Lowest_Profit
Limit 1;

-- Products with the highest discounts -- 
Select P.Product_Id,
		P.category,
	ROUND(AVG(O.Discount)* 100.0,2 ) As Avg_Discount
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By P.Product_Id, p.Category 
Order By Avg_Discount Desc
Limit 10;

-- Products with the lowest discounts -- 
Select P.Product_Id,
		P.category,
	ROUND(AVG(O.Discount)* 100.0,2 ) As Avg_Discount
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By P.Product_Id, p.Category 
Order By Avg_Discount 
Limit 10;

-- Category with the highest average shipping cost --
Select P.category,
	ROUND(AVG(O.Shipping_Cost),2 ) As Highest_Avg_Shipping_Cost
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By P.Product_Id, p.Category 
Order By Highest_Avg_Shipping_Cost Desc
Limit 1;

-- Category with the lowest average shipping cost --
Select P.category,
	ROUND(AVG(O.Shipping_Cost),2 ) As Lowest_Avg_Shipping_Cost
From Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By P.Product_Id, p.Category 
Order By Lowest_Avg_Shipping_Cost
Limit 1;

-- Revenue contribution percentage by category --
Select P.Category,
	ROUND(SUM(O.Total_Amount), 2) As Revenue,
    ROUND(Sum(O.Total_amount)*100.0/
    Sum(Sum(Total_amount)) Over() ,2) As Revenue_contribution_percentage
From 
 Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By p.Category
Order By Revenue_contribution_percentage Desc;

-- Profit contribution percentage by category
Select P.Category,
	ROUND(SUM(O.Profit_Margin), 2) As category_profit,
    ROUND(Sum(O.Profit_Margin)*100.0/
    Sum(Sum(o.Profit_Margin)) Over() ,2) As Profit_contribution_percentage
From 
 Orders O
JOIN Products P
ON P.Product_id = O.Product_Id 
Group By p.Category
Order By Profit_contribution_percentage Desc;

-- Products having above-average revenue -- 
With Product_Revenue As
( Select Product_id,
		SUM(Total_Amount) As Total_Revenue 
	From Orders 
Group By product_Id) 
Select Pr.Product_id,
		P.Category,
        ROUND(Pr.Total_Revenue,2) As Total_Revenue
From Product_Revenue Pr
JOIN Products P
ON P.Product_Id = Pr.Product_Id 
WHERE Pr.Total_Revenue >
(Select AVG(Total_Revenue) From Product_Revenue)
Order By Pr.Total_Revenue Desc;

--- Products having below-average revenue --- 
With Product_Revenue As
( Select Product_id,
		SUM(Total_Amount) As Total_Revenue 
	From Orders 
Group By product_Id) 
Select Pr.Product_id,
		P.Category,
        ROUND(Pr.Total_Revenue,2) As Total_Revenue
From Product_Revenue Pr
JOIN Products P
ON P.Product_Id = Pr.Product_Id 
WHERE Pr.Total_Revenue >
(Select AVG(Total_Revenue) From Product_Revenue)
Order By Pr.Total_Revenue;

----------------------------------------------------------------------------
-------------------- Customer Analysis -------------------------------------
----------------------------------------------------------------------------
-- Top 10 Customers by Revenue
Select C.Customer_id,
	ROUND(SUM(O.Total_Amount),2) As Revenue
From Orders O 
Join 
Customers c
ON C.Customer_id = o.Customer_id
Group by C.Customer_id 
Order by Revenue desc
limit 10;

-- Top 10 Customers by Profit
Select Customer_id,
	ROUND(SUM(Profit_margin),2) As Profit
From Orders 
Group by Customer_id 
Order by Profit desc
limit 10;

-- Top 10 Customers by Number of Orders
Select Customer_id,
	COUNT(Order_ID) As Total_orders
From Orders
Group by Customer_id 
Order by Total_orders desc
limit 10;

-- Top 10 Customers by Quantity Purchased 
Select Customer_id,
	SUM(Quantity) As Total_Quantity
From Orders
Group by Customer_id 
Order by Total_Quantity desc
limit 10;

-- Customer with Highest Average Order Value 
Select Customer_id,
	ROUND(AVG(Total_Amount),2) As Average_Order_value
From Orders 
Group by Customer_id 
Order by Average_Order_value desc
limit 1;

-- Customers with Highest Number of Returned Orders -- 
Select O.Customer_id,
	Count(*) as Returned_orders
From orders o 
JOIN Returns r
ON R.Order_id = O.Order_id
Where R.Returned = 'Yes'
Group by o.customer_id
order by Returned_orders Desc
limit 10;

-- Customers Who Never Returned an Order --
Select O.Customer_id,
	Count(*) as total_orders
From orders o 
JOIN Returns r
ON R.Order_id = O.Order_id
Group by o.customer_id
Having 
	SUM(Case when Returned = 'Yes' Then 1 Else 0 END ) = 0 
order by total_orders Desc;

-- Customers with Return Rate Above 20%
Select 
	o.customer_id, 
	Count(*) As Total_order,
	SUM(Case when Returned = 'Yes' then 1 else 0 End) As Returned_Orders,
    Round(Sum(Case when Returned = 'Yes' then 1 else 0 End) *100.0
		/count(*) ,2) as Return_rate
	From Orders O
JOIN Returns r
ON O.order_id = R.order_id 
Group by O.Customer_Id 
Having Return_Rate > 20
order by Returned_Orders desc ;

-- Average Revenue of Customers Who Returned Products 
Select ROUND(AVG(Customer_Revenue),2) as Avg_Customer_Revnue
FROM 
( Select O.Customer_id,
		Sum(O.Total_amount) As Customer_Revenue
from Orders O 
JOIN Returns R 
ON O.Order_id = R.order_id 
Where Returned = 'Yes'
Group by o.customer_id)x;

-- Average Revenue of Customers Who Never Returned Products 
Select 
	ROUND(AVG(Customer_Revenue),2) as Avg_Customer_Revnue
FROM 
( Select O.Customer_id,
		Sum(O.Total_amount) As Customer_Revenue
from Orders O 
JOIN Returns R 
ON O.Order_id = R.order_id 
Group by o.customer_id
Having Sum(Case when Returned = 'Yes' Then 1 Else 0 End ) = 0
)x;

-- High, Medium and Low Value Customers 
Select Customer_id ,
	Sum(Total_amount) As Revenue,
    Case
		When Sum(Total_amount) >=5000 Then 'High Value'
        When Sum(Total_amount) >=2500 Then 'Medium Value'
        Else 'Low Value'
        END as Customer_Segment
	From Orders 
    Group by Customer_Id
    Order By Revenue Desc;
    
-- Top 5% VIP Customers -- 
With CustomerRevenue As 
( Select Customer_id,
	Sum(Total_amount) as Revenue
From Orders 
Group By Customer_id)
Select * from 
(Select *, 
	NTILE(20) Over(Order By revenue Desc) as Grp 
from CustomerRevenue )x 
Where Grp = 1;

-- Inactive Customers (Only One Order) --
Select Customer_id,
	Count(Order_id) as Orders 
from Orders 
Group By customer_id
Having Count(Order_id) =1 ;

-- Repeat Customers ---
Select Customer_id,
	Count(Order_id) as Orders 
from Orders 
Group By customer_id
Having Count(Order_id) >1 
ORDER BY orders DESC;

-- Customers Spending Above Average --
WITH CustomerRevenue AS
(
SELECT
    customer_id,
    SUM(total_amount) revenue
FROM Orders
GROUP BY customer_id
)
SELECT *
FROM CustomerRevenue
WHERE revenue>
(
SELECT AVG(revenue)
FROM CustomerRevenue
)
ORDER BY revenue DESC;

-- Revenue by Gender --
SELECT
    c.customer_gender,
    ROUND(SUM(o.total_amount),2) revenue
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
GROUP BY c.customer_gender;

-- Profit by Gender --
SELECT
    c.customer_gender,
    ROUND(SUM(o.profit_margin),2) profit
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
GROUP BY c.customer_gender;

-- Revenue by Age Group --
SELECT
CASE
WHEN customer_age<25 THEN '18-24'
WHEN customer_age<35 THEN '25-34'
WHEN customer_age<45 THEN '35-44'
WHEN customer_age<55 THEN '45-54'
ELSE '55+'
END AS Age_Group,
ROUND(SUM(total_amount),2) Revenue
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
GROUP BY Age_Group
ORDER BY Revenue DESC;

-- Return Rate by Age Group---
SELECT

CASE
WHEN c.customer_age<25 THEN '18-24'
WHEN c.customer_age<35 THEN '25-34'
WHEN c.customer_age<45 THEN '35-44'
WHEN c.customer_age<55 THEN '45-54'
ELSE '55+'
END Age_Group,

ROUND(
SUM(CASE WHEN r.returned='Yes' THEN 1 ELSE 0 END)
*100.0/COUNT(*),2) Return_Rate

FROM Customers c

JOIN Orders o
ON c.customer_id=o.customer_id

JOIN Returns r
ON o.order_id=r.order_id

GROUP BY Age_Group
ORDER BY Return_Rate DESC;

-- Average Order Value by Age Group --
SELECT

CASE
WHEN c.customer_age<25 THEN '18-24'
WHEN c.customer_age<35 THEN '25-34'
WHEN c.customer_age<45 THEN '35-44'
WHEN c.customer_age<55 THEN '45-54'
ELSE '55+'
END Age_Group,

ROUND(AVG(o.total_amount),2) Average_Order_Value

FROM Customers c

JOIN Orders o
ON c.customer_id=o.customer_id

GROUP BY Age_Group
ORDER BY Average_Order_Value DESC;	

-------------------------------------------------------------------------------
----------------------- Regional Analysis ------------------------------------
--------------------------------------------------------------------------------
-- Total Revenue by Region
Select C.region,
	ROUND(SUM(O.Total_amount), 2) as Revenue
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Revenue desc;

-- Total Profit by Region 
Select C.region,
	ROUND(SUM(O.profit_Margin), 2) as Profit 
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Profit desc;

-- Total Orders by Region
Select C.region,
	COUNT(o.order_id) as Total_orders
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Total_orders desc;

-- Total Quantity Sold by Region
Select C.region,
	SUM(O.Quantity) as Total_quantity
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Total_quantity desc;

-- Average Order Value by Region
Select C.region,
	ROUND(AVG(O.Total_amount), 2) as Avg_order_value
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Avg_order_value desc;

-- Average Shipping Cost by Region
Select C.region,
	ROUND(AVG(O.Shipping_cost), 2) as Avg_Shipping_cost
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Avg_Shipping_cost desc;

-- Average Discount by Region
Select C.region,
	ROUND(AVG(O.Discount)*100, 2) as Avg_Discount
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Avg_Discount desc;

-- Return Rate by Region 
Select C.region,
	Count(*) as total_orders,
    SUM(Case when r.returned= 'Yes' then 1 else 0 End ) As Returned_orders,
    ROUND
		(Sum(case when r.Returned = 'Yes' then 1 else 0 End)*100.0
			/ Count(*),2 ) As Return_Rate
From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
JOIN Returns r
ON r.Order_id = O.order_id
Group By C.region
Order by Return_Rate Desc;

-- Region with Highest Revenue
Select C.region,
	ROUND(SUM(O.Total_amount), 2) as Revenue
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Revenue desc
limit 1;

-- Region with Lowest Revenue
Select C.region,
	ROUND(SUM(O.Total_amount), 2) as Revenue
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Revenue
limit 1;

-- Region with Highest Profit
Select C.region,
	ROUND(SUM(O.profit_Margin), 2) as Profit 
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Profit desc
limit 1;

-- Region with Lowest Profit
Select C.region,
	ROUND(SUM(O.profit_Margin), 2) as Profit 
from orders o
JOIN Customers c
ON C.customer_id = O. Customer_id 
Group By C.region 
Order by Profit
limit 1;

-- Region with Highest Return Rate
Select C.region,
	Count(*) as total_orders,
    SUM(Case when r.returned= 'Yes' then 1 else 0 End ) As Returned_orders,
    ROUND
		(Sum(case when r.Returned = 'Yes' then 1 else 0 End)*100.0
			/ Count(*),2 ) As Return_Rate
From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
JOIN Returns r
ON r.Order_id = O.order_id
Group By C.region
Order by Return_Rate Desc
limit 1;

-- Region with Lowest Return Rate
Select C.region,
	Count(*) as total_orders,
    SUM(Case when r.returned= 'Yes' then 1 else 0 End ) As Returned_orders,
    ROUND
		(Sum(case when r.Returned = 'Yes' then 1 else 0 End)*100.0
			/ Count(*),2 ) As Return_Rate
From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
JOIN Returns r
ON r.Order_id = O.order_id
Group By C.region
Order by Return_Rate 
limit 1;

-- Revenue Contribution (%) by Region
Select C.region,
	Round(Sum(O.Total_amount),2) as Total_revenue,
    ROUND(
    SUM(o.total_Amount)*100.0/
		SUM(SUM(o.Total_amount)) Over(), 2
	) Revenue_Percentage
    From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
Group By C.region
Order by Revenue_Percentage Desc;

-- Profit Contribution (%) by Region 
Select C.region,
	Round(Sum(O.profit_margin),2) as Total_Profit,
    ROUND(
    SUM(o.profit_margin)*100.0/
		SUM(SUM(o.profit_margin)) Over(), 2
	) Profit_Percentage
    From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
Group By C.region
Order by Profit_Percentage Desc;

-- Rank Regions by Revenue
Select 	
	C.region,
	ROUND(Sum(O.Total_Amount),2) as Revenue,
    DENSE_RANK() OVER(order by Sum(O.Total_Amount) desc) As Ranking
From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
Group By C.region;

-- Rank Regions by Profit
Select 	
	C.region,
	ROUND(Sum(O.profit_margin),2) as Profit,
    DENSE_RANK() OVER(order by Sum(O.profit_margin) desc) As Ranking
From Customers C
JOIN Orders o 
ON o.Customer_id = c.Customer_id
Group By C.region;

-- Top Selling Category in Each Region
WITH RegionCategory AS
(
SELECT
    c.region,
    p.category,
    SUM(o.total_amount) revenue,
    ROW_NUMBER() OVER(
    PARTITION BY c.region
    ORDER BY SUM(o.total_amount) DESC
    ) rn
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
JOIN Products p
ON o.product_id=p.product_id
GROUP BY
    c.region,
    p.category
)
SELECT *
FROM RegionCategory
WHERE rn=1;

---------------------------------------------------------
-------------- Delivery & Return Analysis ---------------
--------------------------------------------------------
-- Average delivery time 
Select ROUND(AVG(datediff(delivered_date, Order_date)),2) As Avg_Deleivery_days
	from Orders;
    
-- Maximum delivery time
Select MAX(datediff(delivered_date, Order_date)) As MAX_Deleivery_days
	from Orders;
    
-- Minimum delivery time
Select Min(datediff(delivered_date, Order_date)) As MAX_Deleivery_days
	from Orders;
    
-- Average delivery time by region
Select C.region,
ROUND(AVG(datediff(o.delivered_date, o.Order_date)),2) 
		As Avg_delivery_days
	from Orders o
JOIN Customers c
ON O.customer_id = C.Customer_id 
Group By C.region 
Order by Avg_delivery_days desc;

-- Average delivery time by Category
Select p.category,
ROUND(AVG(datediff(o.delivered_date, o.Order_date)),2) 
		As Avg_delivery_days
	from Orders o
JOIN products p
ON O.product_id = p.product_id 
Group By p.category
Order by Avg_delivery_days desc;

-- Category with the longest average delivery time 
Select p.category,
ROUND(AVG(datediff(o.delivered_date, o.Order_date)),2) 
		As Avg_delivery_days
	from Orders o
JOIN products p
ON O.product_id = p.product_id 
Group By p.category
Order by Avg_delivery_days desc
limit 1;

-- Region with the longest average delivery time
Select C.region,
ROUND(AVG(datediff(o.delivered_date, o.Order_date)),2) 
		As Avg_delivery_days
	from Orders o
JOIN Customers c
ON O.customer_id = C.Customer_id 
Group By C.region 
Order by Avg_delivery_days desc
limit 1;

-- Orders delivered after more than 7 days 
Select 
	Order_id,
    Product_id,
    Customer_id,
    Order_date,
    Delivered_date,
	datediff(delivered_date, Order_date) as Delivery_days 
From Orders
Where datediff(delivered_date, Order_date) > 7
order by Delivery_days;

-- Average return request delay
SELECT
    ROUND(AVG(DATEDIFF(r.request_date,o.delivered_date)),2)
    AS average_return_delay
FROM Orders o
JOIN Returns r
ON o.order_id = r.order_id
WHERE r.returned='Yes';

-- Most Common Return Reason
SELECT
    return_reason,
    COUNT(*) AS total_returns
FROM Returns
WHERE returned='Yes'
GROUP BY return_reason
ORDER BY total_returns DESC;

-- Return Reason by Category
SELECT
    p.category,
    r.return_reason,
    COUNT(*) AS total_returns
FROM Orders o
JOIN Products p
ON o.product_id=p.product_id
JOIN Returns r
ON o.order_id=r.order_id
WHERE r.returned='Yes'
GROUP BY
    p.category,
    r.return_reason
ORDER BY
    p.category,
    total_returns DESC;

-- Return Reasons by Region
SELECT
    c.region,
    r.return_reason,
    COUNT(*) AS total_returns
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
JOIN Returns r
ON o.order_id=r.order_id
WHERE r.returned='Yes'
GROUP BY
    c.region,
    r.return_reason
ORDER BY
    c.region,
    total_returns DESC;

-- Payment Method with Highest Return Rate
SELECT
    o.payment_method,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN r.returned='Yes' THEN 1 ELSE 0 END) returned_orders,
ROUND(SUM(CASE WHEN r.returned='Yes'THEN 1 ELSE 0 END)
        *100.0/COUNT(*),2
    ) AS return_rate
FROM Orders o
JOIN Returns r
ON o.order_id=r.order_id
GROUP BY o.payment_method
ORDER BY return_rate DESC;

-- Top 10 Most Returned Products
SELECT o.product_id,
	   p.category,
	COUNT(*) Returned_Orders
FROM Orders o
JOIN Products p
ON o.product_id=p.product_id
JOIN Returns r
ON o.order_id=r.order_id
WHERE returned='Yes'
GROUP BY
o.product_id,
p.category
ORDER BY Returned_Orders DESC
LIMIT 10;

-- Products Never Returned
SELECT
	o.product_id,
	p.category,
	COUNT(*) Total_Orders
FROM Orders o
JOIN Products p
ON o.product_id=p.product_id
JOIN Returns r
ON o.order_id=r.order_id
GROUP BY
o.product_id,
p.category
HAVING
SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END)=0
ORDER BY Total_Orders DESC;

---------------------------------------------------------------------------
---------------------------Time Series Analysis ---------------------------
---------------------------------------------------------------------------
-- Monthly Revenue Trend
SELECT
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    ROUND(SUM(total_amount),2) AS total_revenue
FROM Orders
GROUP BY
    YEAR(order_date), MONTH(order_date)
ORDER BY year, month;

-- Monthly Profit Trend
SELECT
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    ROUND(SUM(profit_margin),2) AS total_profit
FROM Orders
GROUP BY
    YEAR(order_date), MONTH(order_date)
ORDER BY
    year, month;

-- Monthly Orders
SELECT
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    COUNT(order_id) AS total_orders
FROM Orders
GROUP BY
    YEAR(order_date), MONTH(order_date)
ORDER BY
    year, month;

-- Monthly Return Rate
SELECT	
	YEAR(o.order_date) AS year,
	MONTH(o.order_date) AS month,
	COUNT(*) total_orders,
	SUM(CASE WHEN r.returned='Yes' THEN 1 ELSE 0 END) returned_orders,
ROUND(SUM(CASE WHEN r.returned='Yes'THEN 1 ELSE 0 END)*100.0/COUNT(*),2) return_rate
FROM Orders o
JOIN Returns r
ON o.order_id=r.order_id
GROUP BY
YEAR(order_date), MONTH(order_date)
ORDER BY
	year,month;

-- Best Sales Month
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
ROUND(SUM(total_amount),2) revenue
FROM Orders
GROUP BY
	YEAR(order_date),MONTH(order_date)
ORDER BY revenue DESC
LIMIT 1;

-- Worst Sales Month
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
ROUND(SUM(total_amount),2) revenue
FROM Orders
GROUP BY
	YEAR(order_date),
	MONTH(order_date)
ORDER BY revenue
LIMIT 1;

-- Average Order Value by Month
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
	ROUND(AVG(total_amount),2) average_order_value
FROM Orders
GROUP BY
	YEAR(order_date),
	MONTH(order_date)
ORDER BY
	year,
	month;

-- Monthly Quantity Sold
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
SUM(quantity) quantity_sold
FROM Orders
GROUP BY
	YEAR(order_date),
	MONTH(order_date)
ORDER BY
	year,
	month;

-- Monthly Shipping Cost
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
ROUND(SUM(shipping_cost),2) shipping_cost
FROM Orders
GROUP BY
	YEAR(order_date),
	MONTH(order_date)
ORDER BY
	year,
	month;

-- Monthly Profit Margin %
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
ROUND(
	SUM(profit_margin)*100/SUM(total_amount),2
) profit_margin_percentage
FROM Orders
GROUP BY
YEAR(order_date),
MONTH(order_date)
ORDER BY
year,
month;

-- Rank Customers by Revenue
SELECT
customer_id,
SUM(total_amount) revenue,
RANK() OVER(
ORDER BY SUM(total_amount) DESC
) revenue_rank
FROM Orders
GROUP BY customer_id;

-- Dense Rank Regions by Profit
SELECT
c.region,
SUM(o.profit_margin) profit,
DENSE_RANK() OVER(
ORDER BY SUM(o.profit_margin) DESC
) profit_rank
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
GROUP BY c.region;

-- Top Product in Each Category
WITH ProductSales AS
(
SELECT
	p.category,
	o.product_id,
	SUM(o.total_amount) revenue,
ROW_NUMBER() OVER(
PARTITION BY p.category
ORDER BY SUM(o.total_amount) DESC
) rn
FROM Orders o
JOIN Products p
ON o.product_id=p.product_id
GROUP BY
	p.category,
	o.product_id
)
SELECT *
FROM ProductSales
WHERE rn=1;

-- Top 3 Products in Every Category
WITH ProductSales AS
(
SELECT
	p.category,
	o.product_id,
	SUM(o.total_amount) revenue,
ROW_NUMBER() OVER(
PARTITION BY p.category
ORDER BY SUM(o.total_amount) DESC
) rn
FROM Orders o
JOIN Products p
ON o.product_id=p.product_id
GROUP BY
	p.category,
	o.product_id
)
SELECT *
FROM ProductSales
WHERE rn<=3;

-- Top 5% Customers
WITH CustomerRevenue AS
(
SELECT
	customer_id,
	SUM(total_amount) revenue
FROM Orders
GROUP BY customer_id
)
SELECT *
FROM
(
SELECT *,
NTILE(20) OVER(
ORDER BY revenue DESC
) grp
FROM CustomerRevenue
)x
WHERE grp=1;

-- Previous Month Revenue (LAG)
WITH MonthlyRevenue AS
(
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
	SUM(total_amount) revenue
FROM Orders
GROUP BY
	YEAR(order_date),
	MONTH(order_date)
)
SELECT*,
	LAG(revenue) OVER(
ORDER BY year,month)previous_month_revenue
FROM MonthlyRevenue;

-- Month-over-Month Growth %
WITH MonthlyRevenue AS
(
SELECT
	YEAR(order_date) year,
	MONTH(order_date) month,
	SUM(total_amount) revenue
FROM Orders
GROUP BY
	YEAR(order_date),
	MONTH(order_date)
)
SELECT
	year,
	month,
	revenue,
	LAG(revenue) OVER(
ORDER BY year,month
) previous_revenue,
ROUND(
(revenue-
LAG(revenue) OVER(
ORDER BY year,month))
*100/
LAG(revenue) OVER(
ORDER BY year,month),2)
AS growth_percentage
FROM MonthlyRevenue;

-- Running Revenue
SELECT
	order_date,
	SUM(total_amount) revenue,
	SUM(SUM(total_amount))
OVER(
ORDER BY order_date
) running_revenue
FROM Orders
GROUP BY order_date;

-- Running Profit
SELECT
	order_date,
	SUM(profit_margin) profit,
	SUM(SUM(profit_margin))
OVER(
ORDER BY order_date
) running_profit
FROM Orders
GROUP BY order_date;

-- Revenue Contribution %
SELECT
customer_id,
SUM(total_amount) revenue,
ROUND(
SUM(total_amount)
*100/
SUM(SUM(total_amount))
OVER()
,2)
revenue_percentage
FROM Orders
GROUP BY customer_id
ORDER BY revenue DESC;