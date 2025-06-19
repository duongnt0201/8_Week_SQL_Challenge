/* --------------------
   Case Study
   --------------------*/
CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(10),
  order_date DATE,
  product_id INT
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INT,
  product_name VARCHAR(30),
  price INT
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(10),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
/* --------------------
   Case Study Question
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?
Select customer_id, sum(price) as Total_customer_spent
from sales sa
join menu me on sa.product_id=me.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
Select customer_id, count(distinct order_date) as DaysVisisted
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with subtable as(
	select customer_id,
			order_date,
            sa.product_id,
            product_name,
			row_number()  over (partition by customer_id order by order_date ASC) as rownum,
            rank()  over (partition by customer_id order by order_date ASC) as ranked
	from sales sa
    join menu me on sa.product_id = me.product_id
    )
Select customer_id, product_name
from subtable
-- where rownum = 1
where ranked = 1
;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select sa.product_id, product_name, count(sa.product_id)
from sales sa
join menu me on sa.product_id=me.product_id
group by sa.product_id, product_name
order by count(sa.product_id) DESC
limit 1;
-- Most purchased item is 3

-- 5. Which item was the most popular for each customer?
select customer_id, product_name
from(
	select customer_id, 
		   sa.product_id, 
           product_name, 
           count(sa.product_id) as TotalOrders,
		   rank() over (partition by customer_id order by count(sa.product_id) DESC) as ranked,
		   row_number() over (partition by customer_id order by count(sa.product_id) DESC) as rownum
	from sales sa
	join menu me on sa.product_id=me.product_id
	group by sa.product_id, product_name, customer_id
	-- order by count(sa.product_id) DESC;
    ) as Count_item
-- where ranked = 1
where rownum = 1
;
-- 6. Which item was purchased first by the customer after they became a member?
select customer_id, ranked.product_id, product_name, order_date, join_date
from (
	select sa.customer_id, 
			product_id, 
            order_date, 
            join_date,
			rank() over (partition by mem.customer_id order by order_date ASC) as ranked,
			row_number() over (partition by mem.customer_id order by order_date ASC) as rownum

	from sales sa
	left join members mem on mem.customer_id = sa.customer_id
    where order_date >= join_date
	) as Ranked 
join menu me on ranked.product_id = me.product_id
-- where rownum = 1
where ranked = 1
order by customer_id;

-- 7. Which item was purchased just before the customer became a member?
select customer_id, ranked.product_id, product_name, order_date, join_date
from (
	select sa.customer_id, 
			product_id, 
            order_date, 
            join_date,
			rank() over (partition by mem.customer_id order by order_date DESC) as rownum
	from sales sa
	left join members mem on mem.customer_id = sa.customer_id
    where order_date < join_date
	) as Ranked 
join menu me on ranked.product_id = me.product_id
where rownum = 1
order by customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
with memberspend as (
select customer_id, ranked.product_id, product_name, price, order_date, join_date
from (
	select sa.customer_id, 
			product_id, 
            order_date, 
            join_date
	from sales sa
	left join members mem on mem.customer_id = sa.customer_id
    where order_date < join_date
	) as Ranked 
join menu me on ranked.product_id = me.product_id
)
Select customer_id, count(product_id) as ProductCount, sum(price) ProductSpent
from memberspend
group by customer_id
order by customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with memberpoints as (
Select sa.customer_id,
	   sa.order_date,
	   me.product_id,
       me.product_name,
       me.price,
		case
			when LOWER(me.product_name) ='sushi' then price*10*2
            else price*10
		end as points
from menu me
join sales sa on me.product_id = sa.product_id
)
Select customer_id, sum(points) as Total_points
from memberpoints
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with memberpoints as (
select  sa.customer_id, 
		sa.product_id, 
		order_date, 
		join_date,
		product_name,
		price,
        case
			when order_date between join_date and date_add(join_date, INTERVAL 6 day) 
				then price*10*2
            when order_date >= date_add(join_date, INTERVAL 6 day) 
				and LOWER(me.product_name) = 'sushi' 
                then price*10*2
            else price*10
		end as points
from sales sa
join members mem on mem.customer_id = sa.customer_id
join menu me on me.product_id = sa.product_id
where sa.order_date >= join_date and sa.order_date <= '2021-01-31'
)
Select customer_id, sum(points) as Total_member_points
from memberpoints
group by customer_id
order by customer_id;

-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
Select sa.customer_id,
	   sa.order_date,
       me.product_name,
       me.price,
       case
			when order_date >= join_date  then 'Y'
            else 'N'
		end as Members
from sales sa
left join members mem on mem.customer_id = sa.customer_id -- Ensure that if Customer is not member --> null
join menu me on me.product_id = sa.product_id
order by sa.customer_id, sa.order_date;

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
with member_table as(
Select sa.customer_id,
	   sa.order_date,
       me.product_name,
       me.price,
       case
			when order_date >= join_date  then 'Y'
            else 'N'
		end as Memberstatus
from sales sa
left join members mem on mem.customer_id = sa.customer_id -- Ensure that if Customer is not member --> null
join menu me on me.product_id = sa.product_id
-- order by sa.customer_id, sa.order_date;
)
Select *,
		case
			when Memberstatus = 'Y'
				then rank() over (partition by customer_id  order by order_date ASC)
			else null
		end as Ranking
from member_table





