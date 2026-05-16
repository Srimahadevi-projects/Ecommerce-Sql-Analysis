create database E_commerce

-- use E_commerce

select * from Sellers -- seller_id, seller_city, seller_state

select * from Customers -- customer_id, Customer_city, Customer_state

select * from Order_items -- order_id, product_id, Seller_id, Order_item_id , items_id(pk)   

select * from Orders -- Order_id, Customer_id      

select * from Products -- product_id

select * from Payments -- Order_id	, payment_id(pk)	

select * from Reviews -- review_id, Order_id, review_unique_id(pk)		

select * from Product_category; -- product_category_id(pk),product_category_name_english

exec sp_rename 'Product_category.column1','product_category_name','column';
exec sp_rename 'Product_category.column2','product_category_name_english','column';

alter table Product_category
add product_category_id int identity(1,1);

delete from product_category
where product_category_id = 1;

alter table product_category
drop column product_category_id

alter table product_category
add constraint pk_category_id primary key(product_category_id);
-----------------------------------------------------
select count(*), seller_id from Sellers
group by seller_id
having count(*) > 1			-- 0 records no duplicates

SELECT customer_id, COUNT(*) 
FROM Customers
GROUP BY customer_id
HAVING COUNT(*) > 1;		-- 0 records no duplicates

SELECT Order_item_id, COUNT(*) 
FROM Order_items
GROUP BY Order_item_id
HAVING COUNT(*) > 1;

SELECT review_id, COUNT(*) 
FROM Reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

----------------------------------------------

alter table Order_items
add items_id INT identity(1,1);

alter table Order_items
add constraint pk_items_id primary key (items_id);

select * from Order_items

-----------------------------------------------
alter table Payments
add payment_id int identity(1,1);

alter table Payments
add constraint pk_payment_id primary key (payment_id)

select * from Payments

---------------------------------------------------------
alter table Reviews
add review_unique_id INT Identity(1,1);

alter table Reviews
add constraint pk_review_Unique_id primary key (review_unique_id);

select * from Reviews

----------------------------------------------------------------------------------
select * from Order_items -- order_id, product_id, Seller_id, Order_item_id , items_id(pk)   

alter table Order_items
add constraint fk_order_id_items foreign key(order_id) references Orders;

alter table Order_items
add constraint fk_product_id foreign key(product_id) references Products;

alter table Order_items
add constraint fk_seller_id foreign key(seller_id) references Sellers;

--------------------------------------------------------------------------------------
select * from Orders -- Order_id, Customer_id      

alter table Orders
add constraint fk_customer_id foreign key (customer_id) references Customers;
--------------------------------------------------------------------------------------------
select * from Payments -- Order_id	, payment_id(pk)	

alter table Payments
add constraint fk_order_id foreign key(order_id)references Orders;
--------------------------------------------------------------------------------------------
select * from Reviews -- review_id, Order_id, review_unique_id(pk)		

alter table Reviews
add constraint fk_order_id_review foreign key(order_id)references Orders;
----------------------------------------------------------------------------------------------------------------------------------------

-- ANALYSIS
-- •	Total number of orders

select count(*) as total_orders from Orders -- 99441

--•	Total number of customers
select count(*) as total_customers from Customers -- 99441

--•	Total revenue

select Order_id, payment_value from Payments;

select * from Payments;

select sum(payment_value) as sum_of_payments from Payments;

select ROUND(sum(payment_value),2)  as sum_of_payments from Payments;

select * from Payments
where payment_installments is null;

-- •	Orders by month
select * from Orders 

select YEAR(order_purchase_timestamp) as year_wise_orders,
MONTH(order_purchase_timestamp) as month_wies_orders, count(order_id) as total_orders
from Orders
group by YEAR(order_purchase_timestamp),MONTH(order_purchase_timestamp)
order by YEAR(order_purchase_timestamp) desc, MONTH(order_purchase_timestamp) desc;

-- •	Revenue by month
select * from Payments

select count(o.order_id) as total_orders,
round(sum(p.payment_value),2) as revenue,
MONTH(o.order_purchase_timestamp) as month_wise_revenue
from Payments as p join Orders as o
on p.order_id = o.order_id
group by MONTH(o.order_purchase_timestamp)
order by month_wise_revenue

-- •	Top sellers by revenue
select * from Sellers ;
select * from Payments ;
select * from Order_items;

select top(10) s.seller_id,
round(sum(p.payment_value),2) as revenue
from Order_items o join Sellers s
on o.seller_id = s.seller_id
join Payments p
on p.order_id = o.order_id
group by s.seller_id 
order by round(sum(p.payment_value),2) desc

--•	Top product categories by sales
-- select * from Product_category; -- product_category_name_english, product_category_id
select * from Order_items
select * from Products

select top(10) p.product_category_name,
sum(o.price + o.freight_value) as total_sales
from Order_items o join Products p
on o.product_id = p.product_id
group by p.product_category_name
order by sum(o.price+o.freight_value)

-- •	Most used payment methods
select * from Payments;
select distinct payment_type from Payments

select payment_type,count(*) as usage_methods from Payments
group by payment_type
order by count(*) desc

-- •	Average review score
select * from Reviews
select AVG(review_score) as avg_score from Reviews

-- •	Delayed deliveries or late orders
select * from Orders

select order_id,
order_delivered_customer_date,
order_estimated_delivery_date from Orders
where order_delivered_customer_date > order_estimated_delivery_date

SELECT COUNT(*) AS delayed_orders
FROM Orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

-- Find customers with more than one order.
select * from Customers
select * from Orders

select customer_id,
count(order_id) as orders
from Orders
group by customer_id
having count(order_id) > 1

--Rank sellers based on total revenue.
select * from Order_items

select seller_id, 
sum(price + freight_value) as revenue,
DENSE_RANK() over(order by sum(price + freight_value) desc) as seller_rank
from Order_items
group by seller_id;
go 
--------------------------------------------------------------------------------------
-- cte
-- Find top 5 customers by total spending
select * from Customers
select * from Orders -- customer_id
select * from Payments ;

with cte as 
(
select c.customer_id,
round(sum(p.payment_value),2) as total_spent
from Payments as p join Orders as o
on o.order_id = p.order_id
join Customers as c
on c.customer_id = o.customer_id
group by c.customer_id
)
select top(10)* from cte
order by total_spent desc
---------------------------------------------------------------
-- subqueries
-- Find orders where payment is above average payment
select * from Payments

select order_id, payment_value from payments
where payment_value >
(select avg(payment_value) from Payments);
go
-----------------------------------------------------------
-- views
-- Create a view showing total orders per customer
create view v_cust_orders
as
select customer_id,count(order_id) as total_orders
from Orders
group by customer_id
go
select * from v_cust_orders
go

-- Create a view for seller total revenue
create view seller_revenue
as 
select seller_id, sum(price + freight_value) as total_revenue
from Order_items
group by seller_id
go
select * from seller_revenue
go

-- Create a view combining order + customer + payment
create view v_order_details
as
select o.order_id, c.customer_id,c.customer_city,p.payment_value
from orders o join Customers c
on o.customer_id = c.customer_id
left join Payments p
on o.order_id = p.order_id;

go
select * from v_order_details
go

-- Improve join performance between Orders and Customers
CREATE INDEX idx_orders_customer_id
ON Orders(customer_id);

-- Optimize queries for revenue and joins
CREATE INDEX idx_order_items_seller
ON Order_items(seller_id);


select * from Products
select * from Order_items 
select * from Orders

select top 1 p.product_category_name,
count(o.order_id) as total_orders
from Products as p join Order_items as o
on p.product_id = o.product_id
where p.product_category_name is not null
group by p.product_category_name
order by count(o.order_id) desc

