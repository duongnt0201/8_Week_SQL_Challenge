use pizza_runner;
/*--------------- 
B. Runner and Customer Experience
----------------------------------*/
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select 
	concat(
    date_format(date_add('2021-01-01', INTERVAL floor(datediff(registration_date, '2021-01-01')/7)*7 day), '%y-%m-%d'),
    ' to ',
    date_format(date_add('2021-01-01', INTERVAL floor(datediff(registration_date, '2021-01-01')/7)*7 + 6 day), '%y-%m-%d')
    ) as week_period,
    count(*) as total
from runners
group by week_period
order by week_period;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_id,
	   avg(cast(regexp_substr(duration, '[0-9]+') as unsigned)) as Averagetime
from runner_orders
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
group by runner_id
;
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with pizza_count as(
Select order_id,
	  count(pizza_id) as count_pizza
from customer_orders
group by order_id
), sub_runner_orders as(
Select
	order_id,
    runner_id,
    cast(regexp_substr(duration, '[0-9]+') as unsigned) as timeduration
from runner_orders
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
)
Select count_pizza,
	   avg(timeduration), 
       count(*) as total_order
from pizza_count pc
join sub_runner_orders sro on pc.order_id = sro.order_id
group by count_pizza
;
-- 4. What was the average distance travelled for each customer?
select co.customer_id,
	     avg(CAST(REPLACE(REPLACE(ro.distance, 'km', ''), ' ', '') AS DECIMAL(5,2)))
         -- (cast(regexp_substr(distance, '[0-9]+\\.[0-9]+|[0-9]+') as DECIMAL(5,2)))
         -- can't use regexp in this case, loss demical
from customer_orders co
join runner_orders ro on co.order_id = ro.order_id
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
group by customer_id
;
-- 5. What was the difference between the longest and shortest delivery times for all orders?
Select (max(timeduration) - min(timeduration)) as delivery_time_diff
from (
select duration,
	   (cast(regexp_substr(duration, '[0-9]+') as unsigned)) as timeduration
from runner_orders
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
      ) as subtable
;
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
with speedinfo as(
select runner_id, order_id,
	   distance,
	   CAST(REPLACE(REPLACE(distance, 'km', ''), ' ', '') AS DECIMAL(5,2)) as distance_km,
       duration,
       (cast(regexp_substr(duration, '[0-9]+') as unsigned)) as minuteduration,
       (cast(regexp_substr(duration, '[0-9]+') as unsigned))/60 as hourduration
from runner_orders
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
)
Select runner_id, order_id, distance_km, minuteduration,
	   round(distance_km/hourduration, 2) as Speed_kmph
from speedinfo
order by runner_id
;
/*--------------
	Trend Summary
	- Runner 1 maintained a consistent speed in orders 1, 2, and 3.
	However, in order 10, the speed increased significantly — this could indicate a data entry error (e.g., incorrect duration or distance).
	- Runner 2 delivered at a reasonable speed in order 4,
	but speeds in orders 7 and 8 were unusually high — potentially due to data inconsistency or anomalies.
	- Runner 3 had only one order (order 5), which showed a reasonable speed — no issues detected.
	- For orders with distance > 20 km, speed values tended to be inconsistent — some very high, some low — suggesting possible inaccuracies in either distance or duration values.
---------------------*/
-- 7. What is the successful delivery percentage for each runner?
with Subtable as(
Select runner_id, order_id,
		case
			when (cancellation is null OR TRIM(LOWER(cancellation)) IN ('', 'null'))
				then 1
			else 0
		end as is_success
from runner_orders
)
Select runner_id,
		sum(is_success) as success_orders,
        count(*) as total_order,
	    round(sum(is_success)/count(*), 2)*100 as succes_rate
from Subtable
group by runner_id



