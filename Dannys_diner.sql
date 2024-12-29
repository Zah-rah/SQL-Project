CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
	  customer_id VARCHAR (1) NOT NULL,
	  order_date DATE NOT NULL,
	  product_id INT NOT NULL
);      

INSERT INTO sales (customer_id, order_date, product_id)
VALUES ("A","2021-01-01",1),
	   ("A","2021-01-01",2),
	   ("A","2021-01-07",2),
	   ("A","2021-01-10",3),
	   ("A","2021-01-11",3),
	   ("A","2021-01-11",3),
	   ("B","2021-01-01",2),
	   ("B","2021-01-02",2),
	   ("B","2021-01-04",1),
	   ("B","2021-01-11",1),
	   ("B","2021-01-16",3),
	   ("B","2021-02-01",3),
	   ("C","2021-01-01",3),
	   ("C","2021-01-01",3),
	   ("C","2021-01-07",3);
       
CREATE TABLE menu (
			 product_id INT NOT NULL,
             product_name VARCHAR(15),
             price INT NOT NULL
);

INSERT INTO menu (price, product_name, product_id)
VALUE (10, "sushi", 1),
	  (15, "curry", 2),
      (12, "ramen", 3);
      
CREATE TABLE members(
			 customer_id VARCHAR (1),
             join_date DATE NOT NULL
);

INSERT INTO members ( customer_id, join_date)
VALUE ("A", "2021-01-07"),
	  ("B", "2021-01-09");
      
UPDATE dannys_diner.sales 
SET order_date = STR_TO_DATE(order_date, "%Y-%m-%d");

UPDATE dannys_diner.members
SET join_date = STR_TO_DATE(join_date, "%Y-%m-%d");

-- What is the total amount each customer spent at the restaurant?
SELECT customer_id, ROUND(SUM(price)) AS total_amount
FROM dannys_diner.sales
JOIN dannys_diner.menu
USING (product_id)
GROUP BY customer_id;

-- How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM dannys_diner.sales
GROUP BY customer_id;

-- What was the first item from the menu purchased by each customer?
WITH first_item AS(
SELECT customer_id, product_name, RANK() OVER(PARTITION BY customer_id ORDER BY product_name) AS rank_
FROM dannys_diner.sales
JOIN dannys_diner.menu
USING (product_id)
GROUP BY customer_id, product_name
)

SELECT customer_id, product_name
FROM first_item
WHERE rank_ = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(product_name) AS no_purchased
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
USING (product_id)
GROUP BY product_name
ORDER BY no_purchased DESC
LIMIT 1;

-- Which item was the most popular for each customer?
WITH  mp AS(
			SELECT customer_id, product_name, COUNT(product_id) AS product_count, 
			RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id)DESC) AS rank_
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
USING (product_id)
GROUP BY customer_id, product_name
ORDER BY  customer_id 
)

SELECT customer_id, product_name, product_count
FROM mp
WHERE rank_ = 1;

-- Which item was purchased first by the customer after they became a member?
WITH firstpurchaseitem AS(
							SELECT customer_id,  product_id, product_name, order_date AS first_purchase,
							RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rank_
FROM dannys_diner.sales AS ds
INNER JOIN dannys_diner.members AS dm
USING (customer_id) 
INNER JOIN dannys_diner.menu
USING (product_id)
WHERE  order_date > join_date
ORDER BY first_purchase
)

SELECT customer_id, product_name, first_purchase
FROM firstpurchaseitem
WHERE rank_ = 1;

-- Which item was purchased just before the customer became a member?
WITH itempurc AS(
					SELECT customer_id,  product_id, product_name, order_date AS last_purchase,
					RANK() OVER(PARTITION BY customer_id ORDER BY  order_date DESC) AS rank_
FROM dannys_diner.sales AS ds
INNER JOIN dannys_diner.members AS dm
USING (customer_id) 
INNER JOIN dannys_diner.menu
USING (product_id)
WHERE  order_date < join_date
ORDER BY last_purchase 
)

SELECT customer_id, product_name, last_purchase
FROM itempurc
WHERE rank_ = 1;

-- What is the total items and amount spent for each member before they became a member?
WITH itempurc AS(
					SELECT customer_id, COUNT(product_id) AS tot_item, 
                    SUM(price) AS spent
FROM dannys_diner.sales AS ds
INNER JOIN dannys_diner.members AS dm
USING (customer_id) 
INNER JOIN dannys_diner.menu
USING (product_id)
WHERE  order_date < join_date
GROUP BY  customer_id
ORDER BY customer_id
)

SELECT customer_id, tot_item, spent
FROM itempurc;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,  
	   Sum(CASE 
		   WHEN product_name = "sushi" THEN price * 20
		   ELSE price * 10
           END 
           ) AS total_points 
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
USING (product_id)
GROUP BY customer_id;

-- In the first week after a customer joins the program (including their join date),
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH jan_points AS(
					SELECT customer_id, (SUM(price)*20) AS total_points, MIN(join_date) AS jd, MONTHNAME(order_date) AS m,
                    RANK() OVER(ORDER BY MONTH(order_date)) AS rank_
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
USING (product_id)
LEFT JOIN dannys_diner.members
USING (customer_id)
WHERE order_date >= join_date
GROUP BY customer_id, MONTHNAME(order_date), MONTH(order_date)
ORDER BY customer_id, MONTH(order_date)
)

SELECT customer_id, m, total_points
FROM jan_points
WHERE rank_ = 1;



WITH jan_points AS(
					SELECT customer_id, SUM(price)*20 AS total_points, MONTHNAME(order_date) AS m
FROM dannys_diner.sales  
INNER JOIN dannys_diner.menu 
USING (product_id)
INNER JOIN dannys_diner.members 
USING (customer_id)
WHERE order_date >= join_date
	  AND MONTH(order_date) = 1 
	  AND DATEDIFF(order_date, join_date) <= 7
GROUP BY customer_id, MONTHNAME(order_date), MONTH(order_date)
ORDER BY customer_id, MONTH(order_date)
)

SELECT customer_id, m, total_points
FROM jan_points















