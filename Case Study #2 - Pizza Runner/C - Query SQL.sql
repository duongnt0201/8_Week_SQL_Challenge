use pizza_runner;
/*--------------- 
C. Ingredient Optimisation
----------------------------------*/
-- 1. What are the standard ingredients for each pizza?
-- Method 1: create temporaty table
CREATE TEMPORARY TABLE numbers (n INT);
INSERT INTO numbers (n)
VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12);

SELECT 
  pr.pizza_id,
  CAST(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(pr.toppings, ',', numbers.n), 
      ',', -1
    ) AS UNSIGNED
  ) AS topping_id,
  topping_name
FROM pizza_recipes pr
JOIN numbers
	 ON numbers.n <= LENGTH(pr.toppings) - LENGTH(REPLACE(pr.toppings, ',', '')) + 1
join pizza_toppings pt on numbers.n = pt.topping_id
ORDER BY pr.pizza_id, numbers.n
;
-- Method 2: replace space ' ' and find_in_set
select
  pn.pizza_name,
  GROUP_CONCAT(pt.topping_name order by pt.topping_id) as ingredients
from pizza_recipes pr
join pizza_names pn on pr.pizza_id = pn.pizza_id
join pizza_toppings pt on FIND_IN_SET(
       pt.topping_id, 
       replace(pr.toppings, ' ', '')
     )
group by pn.pizza_name
;
-- 2. What was the most commonly added extra?
with Count_extras as(
SELECT 
  CAST(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(co.extras, ',', numbers.n), 
      ',', -1
    ) AS UNSIGNED
  ) AS count_extra
FROM customer_orders co
JOIN numbers
	 ON numbers.n <= LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', '')) + 1
where (extras is not null 
	and trim(lower(extras)) not in ('','null'))
)
Select count_extra, count(count_extra) as total_extras
from Count_extras
group by count_extra
order by count_extra
;
-- 
-- 3. What was the most common exclusion?    
with Count_exclusions as(
SELECT 
	order_id,
  CAST(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(co.exclusions, ',', numbers.n), 
      ',', -1
    ) AS UNSIGNED
  ) AS count_exclusion
FROM customer_orders co
JOIN numbers
	 ON numbers.n <= LENGTH(co.exclusions) - LENGTH(REPLACE(co.exclusions, ',', '')) + 1
where (exclusions is not null 
	and trim(lower(exclusions)) not in ('','null'))
)
Select count_exclusion, count(count_exclusion) as total_exclusions
from Count_exclusions
group by count_exclusion
order by count_exclusion
;
-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	-- Meat Lovers
	-- Meat Lovers - Exclude Beef
	-- Meat Lovers - Extra Bacon
	-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
/*----------------------------------------
WITH RECURSIVE numbers AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1
  FROM numbers
  WHERE n < 20
),
 Count_exclusions as(
SELECT 
	order_id,
  CAST(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(co.exclusions, ',', numbers.n), 
      ',', -1
    ) AS UNSIGNED
  ) AS topping_id
FROM customer_orders co
JOIN numbers
	 ON numbers.n <= LENGTH(co.exclusions) - LENGTH(REPLACE(co.exclusions, ',', '')) + 1
where (exclusions is not null 
	and trim(lower(exclusions)) not in ('','null'))
   -- --------------------
), Count_extras as(
SELECT 
	order_id,
  CAST(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(co.extras, ',', numbers.n), 
      ',', -1
    ) AS UNSIGNED
  ) AS topping_id
FROM customer_orders co
JOIN numbers
	 ON numbers.n <= LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', '')) + 1
where (extras is not null 
	and trim(lower(extras)) not in ('','null'))
), exclusions_text as(
select
	order_id,
    group_concat(pt.topping_name order by pt.topping_id) as topping_exclusion
from Count_exclusions cexc
join pizza_toppings pt on pt.topping_id = cexc.topping_id
group by order_id
)
, extras_text as(
select
	order_id,
    group_concat(pt.topping_name order by pt.topping_id) as topping_extras
from Count_extras cext
join pizza_toppings pt on pt.topping_id = cext.topping_id
group by order_id
)
-- -----------------------------------------------------
select co.order_id, pizza_name, topping_exclusion, topping_extras
from customer_orders co
join pizza_names pn       on co.pizza_id = pn.pizza_id
LEFT join exclusions_text exc on co.order_id = exc.order_id
LEFT join extras_text ext 	  on co.order_id = ext.order_id
;

-- ------------------------*/
-- Method 2:
select co.order_id,
	   pn.pizza_name,
       concat(
       pn.pizza_name,
       ifnull(concat( ' - Exclude ',(
			select group_concat(pt.topping_name)
			from pizza_toppings pt
			where find_in_set(pt.topping_id, replace(co.exclusions, ' ', ''))
       )), ''),
	   ifnull(concat(' - Extra ',(
			select group_concat(pt.topping_name)
			from pizza_toppings pt
			where find_in_set(pt.topping_id, replace(co.extras, ' ', ''))
       )), '')
       ) as order_item_for_each_record
from customer_orders co
join pizza_names pn on co.pizza_id = pn.pizza_id
;
-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH RECURSIVE numbers AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n < 20
), pizza_toppings_count as(
SELECT 
	order_id,
  pr.pizza_id,
  CAST(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(pr.toppings, ',', numbers.n), 
      ',', -1
    ) AS UNSIGNED
  ) AS topping_id
FROM customer_orders co
join pizza_recipes pr on co.pizza_id = pr.pizza_id
join  numbers
	 ON numbers.n <= LENGTH(pr.toppings) - LENGTH(REPLACE(pr.toppings, ',', '')) + 1
ORDER BY order_id, pr.pizza_id
), count_topping as (
select order_id, 
		topping_id, 
		count(*) as count_toppings
from pizza_toppings_count
group by order_id, topping_id
order by order_id
), count_topping_names as(
select ctp.order_id,
		case
			when count_toppings > 1 then concat(count_toppings,'x',pt.topping_name)
            else pt.topping_name
		end as count_topping_name
from count_topping ctp
join pizza_toppings pt on  ctp.topping_id = pt.topping_id
), ingredient_list as(
select order_id,
	   group_concat(count_topping_name ORDER BY count_topping_name SEPARATOR ', ') as ingredient_list
from count_topping_names
group by order_id
)
Select il.order_id, 
	   pn.pizza_name,
	   concat(pizza_name,': ', ingredient_list) AS order_ingredient_list
from customer_orders co
join ingredient_list il on co.order_id = il.order_id
join pizza_names pn on pn.pizza_id = co.pizza_id
group by il.order_id, pizza_name, ingredient_list
;
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
	-- total quantity - each ingredient used
	-- in all delivered pizzas
	-- sorted by most frequent first
with RECURSIVE numbers AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM numbers WHERE n <= 20
),
runner_customer_order as(
select ro.order_id, pizza_id
from runner_orders ro
join customer_orders co on ro.order_id = co.order_id
where (cancellation is null 
	  OR TRIM(LOWER(cancellation)) IN ('', 'null'))
-- -------------------
), topping_split as(
SELECT 
	rco.order_id,
     pr.pizza_id,
    CAST(
       SUBSTRING_INDEX(
          SUBSTRING_INDEX(pr.toppings, ',', numbers.n), 
		  ',', -1
		) AS UNSIGNED
  ) AS topping_id
FROM runner_customer_order rco
join pizza_recipes pr on rco.pizza_id = pr.pizza_id
join  numbers
	 ON numbers.n <= LENGTH(pr.toppings) - LENGTH(REPLACE(pr.toppings, ',', '')) + 1
ORDER BY rco.order_id, pr.pizza_id
)
-- -----------------
select 
	   	ts.topping_id,
        topping_name,
        count(ts.topping_id) as totaltopping
from topping_split ts
join pizza_toppings pt on pt.topping_id = ts.topping_id
group by ts.topping_id, topping_name
order by count(ts.topping_id) DESC
