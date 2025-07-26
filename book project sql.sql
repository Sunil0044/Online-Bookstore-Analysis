select * from `books`;
select * from `customers`;
select * from `orders`;
-- Retrieve all books in the "Fiction" genre
select * from books where genre = "fiction"; 

-- 2) Find books published after the year 1950:
select * from books where `Published_Year` > 1950;

-- 3) List all customers from the Canada:
select * from `customers` where `Country` = 'Canada';

-- 4) Show orders placed in November 2023:
select * from orders where monthname(order_date) = 'November' and year(order_date) = '2023' ;

-- 5) Retrieve the total stock of books available:
select sum(stock) from books;

-- 6) Find the details of the most expensive book:
select * from books order by price desc limit 1;

-- 7) Show all customers who ordered more than 1 quantity of a book:
select * from orders where Quantity>'1';

-- 8) Retrieve all orders where the total amount exceeds $20:
select * from orders where Total_Amount > 20;

-- 9) List all genres available in the Books table:
select distinct Genre from books;

-- 10) Find the book with the lowest stock:
select * from books order by stock limit 1;

-- 11) Calculate the total revenue generated from all orders:
select sum(total_amount) from orders;

-- Advance Questions : 
-- 1) Retrieve the total number of books sold for each genre:
select Genre,sum(quantity) from books join orders on books.Book_ID = orders.Order_ID group by Genre;

-- 2) Find the average price of books in the "Fantasy" genre:
select avg(`Price`) from books where `Genre` = 'Fantasy' ;

-- 3) List customers who have placed at least 2 orders:
select `Name`, count(`Order_ID`) orders from customers join orders on customers.Customer_ID = orders.Customer_ID  group by `Name` having count(`Order_ID`) > '2';

-- 4) Show the top 3 most expensive books of 'Fantasy' Genre :
select * from books where Genre = 'Fantasy' order by Price desc limit 3;

-- 5) Retrieve the total quantity of books sold by each author:
select Author, sum(Quantity) from books join orders on books.Book_ID = orders.Book_ID group by Author;

-- 6) List the cities where customers who spent over $30 are located:
select distinct city from orders join customers on orders.Customer_ID = customers.Customer_ID where Total_Amount > 30 ;


-- extra Question 
select * from books;
select * from customers;
select * from orders;

 -- 1.Which books had the largest month-over-month sales increase?
 

WITH monthly_sales AS (
    SELECT 
        Book_ID,
        DATE_FORMAT(Order_Date, '%Y-%m') AS year_months,
        SUM(Total_Amount) AS total_sales
    FROM orders
    GROUP BY Book_ID, DATE_FORMAT(Order_Date, '%Y-%m')
),
sales_with_diff AS (
    SELECT 
        Book_ID,
        year_months,
        total_sales,
        LAG(total_sales) OVER (PARTITION BY Book_ID ORDER BY year_months) AS prev_month_sales,
        (total_sales - LAG(total_sales) OVER (PARTITION BY Book_ID ORDER BY year_months)) AS sales_increase
    FROM monthly_sales
)
SELECT *
FROM sales_with_diff
ORDER BY sales_increase DESC
LIMIT 5;

-- 2.Which customers consistently placed orders every month for the last 3 months?
 
 WITH month_orders AS (
    SELECT 
        Customer_ID, 
        DATE_FORMAT(Order_Date, '%Y-%m') AS order_month
    FROM orders
    WHERE DATE_FORMAT(Order_Date, '%Y-%m') IN ('2024-12', '2024-11', '2024-10')
),
customer_month_count AS (
    SELECT 
        Customer_ID, 
        COUNT(DISTINCT order_month) AS months_active
    FROM month_orders
    GROUP BY Customer_ID
)
SELECT Customer_ID
FROM customer_month_count
WHERE months_active = 3;

-- 3. Rank books by total revenue within each genre.

 WITH Total_sales AS (
    SELECT 
        Book_ID, 
        SUM(Total_Amount) AS sales
    FROM orders
    GROUP BY Book_ID
)

SELECT 
    b.Book_ID,
    b.Title,
    b.Genre,
    ts.sales,
    DENSE_RANK() OVER (
        PARTITION BY b.Genre 
        ORDER BY ts.sales DESC
    ) AS revenue_rank
FROM Total_sales ts
JOIN books b ON ts.Book_ID = b.Book_ID;

-- 4. Which books have been sold at prices lower than their listed price (Price column)?

WITH sell_price AS (
    SELECT 
        o.Order_ID,
        o.Book_ID,
        o.Quantity,
        o.Total_Amount,
        (o.Total_Amount / o.Quantity) AS Selling_Price
    FROM orders o
)

SELECT 
    b.Book_ID,
    b.Title,
    b.Author,
    b.Genre,
    b.Price AS Listed_Price,
    sp.Selling_Price,
    sp.Order_ID
FROM sell_price sp
JOIN books b ON sp.Book_ID = b.Book_ID
WHERE sp.Selling_Price < b.Price;

 -- 5. Which genre has the highest average revenue per book sold?
SELECT 
    b.Genre,
    AVG(o.Total_Amount / o.Quantity) AS avg_revenue_per_book
FROM orders o
JOIN books b ON o.Book_ID = b.Book_ID
GROUP BY b.Genre
ORDER BY avg_revenue_per_book DESC
LIMIT 1;

-- 6.   Use a CTE to find books that have sold more than the average quantity sold across all books.
 
 WITH book_sales AS (
    SELECT 
        Book_ID,
        SUM(Quantity) AS total_quantity
    FROM orders
    GROUP BY Book_ID
),
overall_avg AS (
    SELECT AVG(total_quantity) AS avg_quantity_sold
    FROM book_sales
)
SELECT 
    bs.Book_ID,
    bs.total_quantity
FROM book_sales bs
JOIN overall_avg oa ON 1=1
WHERE bs.total_quantity > oa.avg_quantity_sold;

-- 7. Use a CTE to get total sales per customer, then list only those above the overall customer average.

WITH Total_sales AS (
    SELECT 
        Customer_ID, 
        SUM(Total_Amount) AS total_sales
    FROM orders
    GROUP BY Customer_ID
),
overall_avg AS (
    SELECT 
        AVG(total_sales) AS avg_sales_per_customer
    FROM Total_sales
)
SELECT 
    ts.Customer_ID,
    ts.total_sales,
    avg_sales_per_customer
FROM Total_sales ts
JOIN overall_avg oa ON 1=1
WHERE ts.total_sales > oa.avg_sales_per_customer;

-- 8. Create a view showing book title, total quantity sold, remaining stock, and stock status (e.g., ‘In Stock’, ‘Low Stock’, ‘Out of Stock’).
CREATE VIEW book_inventory_status AS
WITH total_sold AS (
    SELECT 
        Book_ID, 
        SUM(Quantity) AS quantity_sold
    FROM orders
    GROUP BY Book_ID
)
SELECT 
    b.Book_ID,
    b.Title,
    COALESCE(ts.quantity_sold, 0) AS quantity_sold,
    b.Stock AS remaining_stock,
    
    CASE 
        WHEN b.Stock = 0 THEN 'Out of Stock'
        WHEN b.
        Stock <= 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status

FROM books b
LEFT JOIN total_sold ts ON b.Book_ID = ts.Book_ID;

-- 9.Write a stored procedure that takes a customer ID and returns
--  Number of orders
--  Total quantity ordered
--  Total amount spent

DELIMITER $$

CREATE PROCEDURE get_customer_summary(IN cust_id INT)
BEGIN
    SELECT 
        COUNT(Order_ID) AS total_orders,
        SUM(Quantity) AS total_quantity,
        SUM(Total_Amount) AS total_spent
    FROM orders
    WHERE Customer_ID = cust_id;
END$$


 -- 10. Write a stored procedure that accepts a genre and returns the top 3 selling books in that genre.
DELIMITER $$
CREATE PROCEDURE top_3_books_by_genre(IN gen VARCHAR(50))
BEGIN
    -- Get top 3 books by total sales in the specified genre
    SELECT 
        b.Book_ID,
        b.Title,
        b.Genre,
        SUM(o.Total_Amount) AS total_sales
    FROM books b
    JOIN orders o ON b.Book_ID = o.Book_ID
    WHERE b.Genre = gen
    GROUP BY b.Book_ID, b.Title, b.Genre
    ORDER BY total_sales DESC
    LIMIT 3;
END$$

DELIMITER ;


-- 12. Identify peak order days of the week using DAYNAME(Order_Date) and COUNT(*).
SELECT 
    DAYNAME(Order_Date) AS order_day,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_day
ORDER BY total_orders DESC;







 1. Which books had the largest month-over-month sales increase?
 Which customers consistently placed orders every month for the last 3 months?
🔷 3. Rank books by total revenue within each genre.
4. Which books have been sold at prices lower than their listed price (Price column)?
 5. Which genre has the highest average revenue per book sold?
  Use a CTE to find books that have sold more than the average quantity sold across all books.
🔷 7. Use a CTE to get total sales per customer, then list only those above the overall customer average.
👁️‍🗨️ View-Based Question
🔷 8. Create a view showing book title, total quantity sold, remaining stock, and stock status (e.g., ‘In Stock’, ‘Low Stock’, ‘Out of Stock’).
🧠 Stored Procedure Questions
🔷 9. Write a stored procedure that takes a customer ID and returns:

    Number of orders

    Total quantity ordered

    Total amount spent

🔷 10. Write a stored procedure that accepts a genre and returns the top 3 selling books in that genre.
🕓 Time & Trend Analysis
🔷 11. Calculate the average time gap between two orders for each customer.

Use window function LAG() or DATEDIFF().
🔷 12. List books that haven’t been sold in the last 6 months.
🔷 13. Identify peak order days of the week using DAYNAME(Order_Date) and COUNT(*).






