-- Drop existing tables if they exist
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS menu;
DROP TABLE IF EXISTS members;

-- Create the sales table
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);



INSERT INTO sales (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  # What is the total amount each customer spent at the restaurant?
  
  
  select customer_id,sum(price) as total_amount
  from sales
  join menu
  on sales.product_id=menu.product_id
  group by customer_id;
  
  
   # How many days has each customer visited the restaurant?
   
   select customer_id,count(distinct order_date) as visit_count
   from sales
   group by customer_id;
   
   # What was the first item from the menu purchased by each customer?
   
With cte as
(
Select S.customer_id, 
       M.product_name, 
       S.order_date,
       DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by S.order_date) as rn
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id, M.product_name,S.order_date
)
Select Customer_id, product_name
From cte
Where rn = 1;

# What is the most purchased item on the menu and how many times was it purchased by all customers?

select M.product_name,count(M.product_name) as most_purchased
from sales S
join menu M
on S.product_id=M.product_id
group by M.product_name
order by most_purchased desc
limit 1;

# Which item was the most popular for each customer?
with cte as 
(
select S.customer_id,
M.product_name,
COUNT(S.product_id) as count,
dense_rank() over(partition by S.customer_id order by count(S.product_id) desc) as rn
from menu  M
join sales S
on M.product_id=S.product_id
group by S.customer_id,S.product_id,M.product_name
)
select customer_id,product_name
from cte
where rn=1;

# Which item was purchased first by the customer after they became a member?
with orders as(
select S.customer_id,M.product_name,S.order_date,Mem.join_date,
dense_rank() over (partition by customer_id order by order_date) as rn
from sales S
join menu M
on S.product_id=M.product_id
join members mem
on s.customer_id=mem.customer_id
where order_date>join_date

)
select customer_id,product_name
from orders
where rn=1;

# Which item was purchased just before the customer became a member?
with items as(
select S.customer_id,M.product_name,S.order_date,Mem.join_date,
row_number() over(partition by customer_id order by order_date) as rn
from sales S 
join menu M
on S.product_id=M.product_id
join members Mem
on S.Customer_id=Mem.customer_id
where order_date < join_date
)
select customer_id,product_name
from items
 where rn=1;
 
# What is the total items and amount spent for each member before they became a member?

Select S.customer_id,count(S.product_id ) as quantity ,Sum(M.price) as total_sales
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date
Group by S.customer_id;

#If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
with CTE as(
select S.customer_id,M.price,
case
when M.product_id= 1 then M.price*10*2
else M.price*10
end as points
from menu M
join sales S
on M.product_id=S.product_id
)
select customer_id,sum(points)
from CTE
group by customer_id;

# In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?




SELECT 
    s.customer_id,
    SUM(
        CASE
            WHEN (DATEDIFF(s.order_date, me.join_date) BETWEEN 0 AND 7) OR (m.product_ID = 1)
                THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS Points
FROM 
    members AS me
    INNER JOIN sales AS s ON s.customer_id = me.customer_id
    INNER JOIN menu AS m ON m.product_id =s.product_id
WHERE 
    
     s.order_date < '2021-01-31'
GROUP BY 
    s.customer_id
LIMIT 50000;

# Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

select S.customer_id,S.order_date,M.product_name,M.price,
case when S.order_date >= mem.join_date then 'Y'
ELSE 'N'
end as member_status
from menu M
LEFT join sales S
on M.product_id=S.product_id
LEFT join members mem
on S.customer_id=mem.customer_id
order by S.customer_id,S.order_date;

#Rank All The Things
with cte as
(
SELECT S.customer_id,S.order_date,M.product_name,M.price,
case when S.order_date>=mem.join_date then 'Y'
else 'n'
end as member_status

from menu M
left join Sales S 
on M.product_id=S.product_id
left join members mem
on S.customer_id=mem.customer_id
)
select *,CASE
    WHEN member_status = 'N' then NULL
    ELSE RANK () OVER(
      PARTITION BY customer_id, member_status
      ORDER BY order_date) END AS ranking
FROM cte;



















