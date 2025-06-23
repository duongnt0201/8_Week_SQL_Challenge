# [8-Week SQL Challenge](https://github.com/duongnt0201/8_Week_SQL_Challenge.git) 
# 🍜 Case Study #1 - Danny's Diner

<p align="center">
  <a href="https://postimg.cc/8FBfpJ9J">
    <img src="https://i.postimg.cc/TPBVcnc9/org-1.png" alt="org-1.png"width=40% height=40% >
  </a>
</p>

## 📕 Table Of Contents
* 🛠️ [Problem Statement](#problem-statement)
* 📂 [Dataset](#dataset)
* 🧙‍♂️ [Case Study Questions](#case-study-questions)
* 🚀 [Solutions](#solutions)
  ## 📕 Table Of Contents
* [Problem Statement](#problem-statement)
* [Dataset](#dataset)
* [Case Study Questions](#case-study-questions)
* [Solutions](#solutions)
* [Limitations](#limitations)

---

## 🛠️ Problem Statement

> Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

 <br /> 

---

## 📂 Dataset
Danny has shared with you 3 key datasets for this case study:

### **```sales```**

<details>
<summary>
View table
</summary>

The sales table captures all ```customer_id``` level purchases with an corresponding ```order_date``` and ```product_id``` information for when and what menu items were ordered.

|customer_id|order_date|product_id|
|-----------|----------|----------|
|A          |2021-01-01|1         |
|A          |2021-01-01|2         |
|A          |2021-01-07|2         |
|A          |2021-01-10|3         |
|A          |2021-01-11|3         |
|A          |2021-01-11|3         |
|B          |2021-01-01|2         |
|B          |2021-01-02|2         |
|B          |2021-01-04|1         |
|B          |2021-01-11|1         |
|B          |2021-01-16|3         |
|B          |2021-02-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-07|3         |

 </details>

### **```menu```**

<details>
<summary>
View table
</summary>

The menu table maps the ```product_id``` to the actual ```product_name``` and price of each menu item.

|product_id |product_name|price     |
|-----------|------------|----------|
|1          |sushi       |10        |
|2          |curry       |15        |
|3          |ramen       |12        |

</details>

### **```members```**

<details>
<summary>
View table
</summary>

The final members table captures the ```join_date``` when a ```customer_id``` joined the beta version of the Danny’s Diner loyalty program.

|customer_id|join_date |
|-----------|----------|
|A          |1/7/2021  |
|B          |1/9/2021  |

 </details>

 ## Entity Relationship Diagram

![изображение](https://user-images.githubusercontent.com/98699089/156034410-8775d5d2-eda5-4453-9e33-54bfef253084.png)

## 🧙‍♂️ Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

 <br /> 

## 🚀 Solutions

### **Q1. What is the total amount each customer spent at the restaurant?**
```sql
Select customer_id, 
	   sum(price) as Total_customer_spent
from sales sa
join menu me 
on sa.product_id=me.product_id
group by customer_id;
```

| customer_id | Total_customer_spent|
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |


---

### **Q2. How many days has each customer visited the restaurant?**
```sql
Select customer_id, 
	   count(distinct order_date) as DaysVisisted
from sales
group by customer_id;
```

|customer_id|DaysVisisted|
|-----------|------------|
|A          |4           |
|B          |6           |
|C          |2           |


---

### **Q3. What was the first item from the menu purchased by each customer?**

```sql
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
```

**Result:**
when rownum = 1
| customer_id | product_name | 
| ----------- | ------------ | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        | 

**or** when ranked = 1

| customer_id | product_name |
| ----------- | ------------ | 
| A           | sushi        |
| A           | curry        | 
| B           | curry        |
| C           | ramen        |
| C           | ramen        |
---

### **Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```sql
select sa.product_id, 
	   product_name, 
       count(sa.product_id) as total_count
from sales sa
join menu me on sa.product_id=me.product_id
group by sa.product_id, product_name
order by count(sa.product_id) DESC
limit 1;
```

|product_id|product_name|Total_count|
|----------|------------|-----------|
|3         |ramen       |8          |

---

### **Q5. Which item was the most popular for each customer?**
```sql
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
```
**Result:**
when rownum = 1
| customer_id | product_name | 
| ----------- | ------------ | 
| A           | ramen        | 
| B           | curry        | 
| C           | ramen        | 

**or** when ranked = 1

| customer_id | product_name |
| ----------- | ------------ | 
| A           | ramen        |
| B           | curry        | 
| B           | sushi        |
| B           | ramen        |
| C           | ramen        |

---

### **Q6. Which item was purchased first by the customer after they became a member?**

```sql
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
```
**Result:**

| customer_id | product_id| product_name | order_date     | join_date   |
| ----------- | ----------| -------------| -------------- |-------------|
| A           | 2         | curry        | 2021-01-07     |  2021-01-07 |
| B           | 1         | sushi        | 2021-01-11     |  2021-01-09 |

---

### **Q7. Which item was purchased just before the customer became a member?**

```sql
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
```

| customer_id | product_id | product_name | order_date | join_date |
|-------------|------------|--------------|------------|-----------|
| A           | 1          | sushi        | 1/1/2021   | 1/7/2021  |
| A           | 2          | curry        | 1/1/2021   | 1/7/2021  |
| B           | 1          | sushi        | 1/4/2021   | 1/9/2021  |

---

### **Q8. What is the total items and amount spent for each member before they became a member?**
```sql
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
```

| customer_id | ProductCount | ProductSpent |
| ----------- | ------------ | -----------  |
| A           | 2            | 25           |
| B           | 3            | 40           |


---

### **Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
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
group by customer_id
;

```

| customer_id | Total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| B           | 360          |

---

### **Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```sql
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

```

| customer_id | Total_member_points |
| ----------- | ------------------- |
| A           | 1020                |
| B           | 320                 |




