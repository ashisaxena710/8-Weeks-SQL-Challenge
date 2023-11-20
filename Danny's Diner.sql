CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as 'total spent' from sales a, menu b
where a.product_id=b.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) 'Num of days visited the resturant' 
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT DISTINCT
    s.customer_id,
    FIRST_VALUE(m.product_name) OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS first_item
FROM
    sales s
JOIN
    menu m 
ON s.product_id = m.product_id;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top(1) b.product_name, count(a.product_id) as 'num of times purchased' from sales a, menu b
where a.product_id=b.product_id
group by a.product_id , b.product_name
order by count(a.product_id) desc

-- 5. Which item was the most popular for each customer?

select distinct customer_id, product_id from (
select 
	customer_id, 
	product_id, 
	COUNT(product_id) as total_purchased,
    RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) as r
FROM sales s
group by customer_id, product_id) temp
where r = 1

-- 6. Which item was purchased first by the customer after they became a member?

select customer_id, product_id from (
select
	s.customer_id,
	order_date,
	product_id,
	rank() over (partition by s.customer_id order by order_date asc) as r
from sales s
join members m
on s.customer_id = m.customer_id
where s.order_date >= m.join_date
) temp
where r = 1;

-- 7. Which item was purchased just before the customer became a member?

select customer_id, product_id from (
select
	s.customer_id,
	order_date,
	product_id,
	rank() over (partition by s.customer_id order by order_date desc) as r
from sales s
join members m
on s.customer_id = m.customer_id
where s.order_date < m.join_date
) temp
where r = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select customer_id, total_items, total_amount
from (
	select 
		s.customer_id, 
		count(s.product_id) total_items, 
		sum(price) total_amount
	from sales s
	join menu m
	on s.product_id = m.product_id
	join members mm
	on s.customer_id = mm.customer_id
	where s.order_date < mm.join_date
	group by s.customer_id) temp

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(points) as total_points from sales s join (
select product_id, product_name, case when product_name = 'sushi' then price*10*2 else price*10 end as points
from menu) m
on s.product_id = m.product_id
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
    s.customer_id, 
    sum(CASE 
        WHEN s.order_date BETWEEN mm.join_date AND DATEADD(DAY, 6, mm.join_date) THEN price * 10 * 2
        WHEN m.product_name = 'sushi' THEN price * 10 * 2
        ELSE price
    END) AS new_points
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
JOIN 
    members mm ON s.customer_id = mm.customer_id
where DATEPART(month,s.order_date)='01'
group by s.customer_id;

