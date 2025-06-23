-- Example Query:
SELECT
	runners.runner_id,
    runners.registration_date,
	COUNT(DISTINCT runner_orders.order_id) AS orders
FROM pizza_runner.runners
INNER JOIN pizza_runner.runner_orders
	ON runners.runner_id = runner_orders.runner_id
WHERE runner_orders.cancellation IS NOT NULL
GROUP BY
	runners.runner_id,
    runners.registration_date;
    
/*----------------
 A. Pizza Metrics
 -------------------*/
-- 1. How many pizzas were ordered?
select count(*) as total_pizzas_orders
from customer_orders
;
-- 2. How many unique customer orders were made?
select count(distinct customer_id) as Total_customers
from customer_orders
;
-- 3. How many successful orders were delivered by each runner?
select runner_id, count(*) as Succes_orders
from runner_orders
where cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null')
group by runner_id
;
-- 4. How many of each type of pizza was delivered?
select
	   co.pizza_id,
       pn.pizza_name,
 
       count(*) as total
from customer_orders co
join pizza_names pn on co.pizza_id = pn.pizza_id
join runner_orders ro on co.order_id = ro.order_id
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
group by co.pizza_id,
       pn.pizza_name
;
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select co.customer_id, pizza_name, count(co.pizza_id)
from customer_orders co
join pizza_names pn on co.pizza_id = pn.pizza_id
group by co.customer_id, pizza_name
;
-- 6. What was the maximum number of pizzas delivered in a single order?
select order_id, count(pizza_id) total
from customer_orders
group by order_id
order by count(pizza_id) DESC
limit 1
;
Select max(pizza_count) as MaxPizzaperOrder
from(
	select count(pizza_id) pizza_count
	from customer_orders
	group by order_id
    ) as PizzaCount
;
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with countchange as(
select co.customer_id, 
	case
        when(TRIM(LOWER(co.exclusions)) IN ('', 'null') OR co.exclusions IS NULL)
			and (TRIM(LOWER(co.extras)) IN ('', 'null') OR co.extras IS NULL)
		then 0 -- no changes
		else 1 -- at least 1 change
	end as has_change
from customer_orders co
join runner_orders ro on ro.order_id = co.order_id
where ro.cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null')
)
select customer_id,
	   sum(case when has_change = 1 then 1 else 0  end) as pizzachangescount,
       sum(case when has_change = 0 then 1 else 0 end) as pizzeno_changescount
from countchange
group by customer_id
order by customer_id
;
-- 8. How many pizzas were delivered that had both exclusions and extras?
Select count(*) as pizzas_delivered_both
from customer_orders co
join runner_orders ro on ro.order_id = co.order_id
where (
	(ro.cancellation is null OR TRIM(LOWER(ro.cancellation)) IN ('', 'null'))
	and (co.exclusions is not null and TRIM(LOWER(co.exclusions)) not IN ('', 'null'))
    and (co.extras is not null and TRIM(LOWER(co.extras)) not IN ('', 'null'))
    )
;
-- 9. What was the total volume of pizzas ordered for each hour of the day?
select hour(order_time) as hours,
	   count(pizza_id) as totalorders
from customer_orders
group by hour(order_time)
order by hour(order_time)
;
-- 10. What was the volume of orders for each day of the week?
select dayname(order_time) as weekday,
	   count(pizza_id) totalorders
from customer_orders
group by weekday
order by field(weekday, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');
;