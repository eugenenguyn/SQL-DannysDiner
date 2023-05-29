-- 1/ What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_amout
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id

-- 2/ How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT (order_date)) AS time_visit
FROM sales
GROUP BY customer_id

-- What was the first item from the menu purchased by each customer?
WITH cte AS(
SELECT customer_id
    , product_name
    , order_date
    , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as first_item
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
)
SELECT customer_id, product_name
FROM cte
WHERE first_item = 1
GROUP BY customer_id, product_name

-- 3/ What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 product_name, count(m.product_id) AS most_puchased
FROM menu AS m
JOIN sales AS s
ON s.product_id = m.product_id  
GROUP BY product_name
ORDER BY most_puchased DESC

-- 4/ Which item was the most popular for each customer?
with cte1 AS
(
    SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS count_product, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank_popular
    FROM sales AS s
    JOIN menu AS m
    ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name
FROM cte1
WHERE rank_popular = 1

-- 5/ Which item was purchased first by the customer after they became a member?
WITH cte3 AS
(
SELECT s.customer_id, s.order_date, join_date, me.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ) AS rank_no
FROM sales AS s
JOIN members AS m ON s.customer_id = m.customer_id
JOIN menu AS me ON me.product_id = s.product_id 
WHERE order_date >= join_date
)

SELECT customer_id, product_name AS first_puchased_after_member
FROM cte3
WHERE rank_no = 1 

-- 6/ Which item was purchased just before the customer became a member?
WITH cte4 AS
(
SELECT s.customer_id, s.order_date, join_date, me.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC ) AS rank_no
FROM sales AS s
JOIN members AS m ON s.customer_id = m.customer_id
JOIN menu AS me ON me.product_id = s.product_id 
WHERE order_date < join_date
)

SELECT customer_id, product_name AS last_puchased_before_member
FROM cte4
WHERE rank_no = 1 

-- 7/ What is the total items and amount spent for each member before they became a member?
WITH cte5 AS
(
SELECT s.customer_id, s.order_date, join_date, me.product_name, price
FROM sales AS s
JOIN members AS m ON s.customer_id = m.customer_id
JOIN menu AS me ON me.product_id = s.product_id 
WHERE order_date < join_date
)

SELECT customer_id, COUNT(product_name) AS total_item, SUM(price) AS total_spent
FROM cte5
GROUP BY customer_id

-- 8/ If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH campaign AS 
(
SELECT product_id, price, 
    (CASE WHEN product_name = 'Sushi' THEN price*2*10 ELSE price*10 END) AS points  
FROM menu
)
SELECT s.customer_id, SUM(points) AS total_points
FROM sales AS s
JOIN campaign 
ON s.product_id = campaign.product_id
GROUP BY s.customer_id

-- 9/ In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT m.customer_id
    , SUM(CASE 
        WHEN order_date BETWEEN join_date AND DATEADD(DAY,6,join_date) THEN price*2*10
        WHEN product_name = 'Sushi' THEN price*2*10 ELSE price*10 
        END) AS total_points
FROM members AS m
JOIN sales AS s ON s.customer_id = m.customer_id
JOIN menu AS mn ON mn.product_id = s.product_id
WHERE order_date < '2021-01-31'
GROUP BY m.customer_id
