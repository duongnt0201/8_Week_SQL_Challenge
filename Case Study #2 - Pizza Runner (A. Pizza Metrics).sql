CREATE SCHEMA pizza_runner;
use pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
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