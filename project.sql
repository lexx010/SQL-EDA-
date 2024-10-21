-- DB description:
-- Customers: customer data
-- Employees: all employee information
-- Offices: sales office information
-- Orders: customers' sales orders
-- OrderDetails: sales order line for each sales order
-- Payments: customers' payment records
-- Products: a list of scale model cars
-- ProductLines: a list of product line categories

SELECT 
    'Customers' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('Customers')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    customers

UNION ALL

SELECT 
    'Products' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('Products')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    products

UNION ALL

SELECT 
    'ProductLines' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('ProductLines')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    productlines

UNION ALL

SELECT 
    'Orders' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('Orders')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    orders

UNION ALL

SELECT 
    'OrderDetails' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('OrderDetails')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    orderdetails

UNION ALL

SELECT 
    'Payments' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('Payments')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM
    payments

UNION ALL

SELECT 
    'Employees' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('Employees')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    employees

UNION ALL

SELECT 
    'Offices' AS table_name,
    (SELECT COUNT(*) FROM pragma_table_info('Offices')) AS number_of_attributes,
    COUNT(*) AS number_of_rows
  FROM 
    offices;


-- Question 1: Which Products Should We Order More of or Less of?
-- Low stock
-- The low_stock value represents the percentage of the stock remaining for each product. 
WITH Low_Stock AS (
    SELECT p.productCode, 
           p.productName, 
           p.productLine,
           ROUND(SUM(od.quantityOrdered) * 1.0 / p.quantityInStock, 2) AS low_stock
      FROM products p
      JOIN orderdetails od ON p.productCode = od.productCode 
    GROUP BY p.productCode, p.productName, p.productLine

),
Product_Performance AS ( 
    SELECT p.productCode, 
           SUM(od.quantityOrdered * od.priceEach) AS product_performance
      FROM  orderdetails od
      JOIN products p ON od.productCode = p.productCode
    GROUP BY p.productCode
),
Priority_Products AS (
    SELECT productCode
      FROM Low_Stock
      WHERE low_stock < 0.5
      UNION ALL
    SELECT productCode
      FROM Product_Performance
)

SELECT  p.productCode, 
        p.productName, 
        p.productLine, 
        ls.low_stock
  FROM  Low_Stock ls
  JOIN products p  
    ON p.productCode = ls.productCode
 WHERE ls.productCode IN 
	              (SELECT productCode 
				     FROM Priority_Products)
ORDER BY  ls.low_stock DESC, p.productName
LIMIT 10;


-- Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
-- Compute how much profit each customer generates.
SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
  FROM orders o
  JOIN orderdetails od
    ON o.orderNumber = od.orderNumber
  JOIN products p
    ON p.productCode = od.productCode
  GROUP BY o.customerNumber
  ORDER BY profit DESC;
  
-- Finding the VIP Customers : The Top Five
WITH profit_per_customer AS(
    SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
	  FROM orders o
	  JOIN orderdetails od
		ON o.orderNumber = od.orderNumber
	  JOIN products p
		ON p.productCode = od.productCode
	  GROUP BY o.customerNumber
	  ORDER BY profit DESC
)

SELECT c.contactLastName, c.contactFirstName, c.city, c.country, ppc.profit
  FROM customers c
  JOIN profit_per_customer ppc
    ON c.customerNumber = ppc.customerNumber
  ORDER BY ppc.profit DESC
  LIMIT 5;
  
-- Finding Less Engaged Customers : The top five least-engaged customers
WITH profit_per_customer AS(
    SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
	  FROM orders o
	  JOIN orderdetails od
		ON o.orderNumber = od.orderNumber
	  JOIN products p
		ON p.productCode = od.productCode
	  GROUP BY o.customerNumber
	  ORDER BY profit DESC
)

SELECT c.contactLastName, c.contactFirstName, c.city, c.country, ppc.profit
  FROM customers c
  JOIN profit_per_customer ppc
    ON c.customerNumber = ppc.customerNumber
  ORDER BY ppc.profit ASC
  LIMIT 5;
  
--  Question 3: How Much Can We Spend on Acquiring New Customers?
-- compute the average of customer profits 

WITH profit_per_customer AS(
    SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
	  FROM orders o
	  JOIN orderdetails od
		ON o.orderNumber = od.orderNumber
	  JOIN products p
		ON p.productCode = od.productCode
	  GROUP BY o.customerNumber
	  ORDER BY profit DESC
)

SELECT ROUND(AVG(profit),3) AS avg_profit
  FROM profit_per_customer;

  -- Most profitable countries
WITH profit_per_customer AS(
    SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS profit
	  FROM orders o
	  JOIN orderdetails od
		ON o.orderNumber = od.orderNumber
	  JOIN products p
		ON p.productCode = od.productCode
	  GROUP BY o.customerNumber
	  ORDER BY profit DESC
)

SELECT c.country, SUM(ppc.profit) As total_profit
  FROM customers c
  JOIN profit_per_customer ppc
    ON c.customerNumber = ppc.customerNumber
  GROUP BY c.country
  ORDER BY total_profit DESC
  LIMIT 10;
  
-- The most popular product lines
SELECT pl.productLine, SUM(od.quantityOrdered) AS total_quantity
  FROM productlines as pl
  JOIN products p
    ON p.productLine = pl.productLine
  JOIN orderdetails od
    ON od.productCode = p.productCode
  GROUP BY pl.productLine
  ORDER BY total_quantity DESC;
  
-- Orders Shipped Late
SELECT o.orderNumber, o.orderDate, o.shippedDate, o.requiredDate
  FROM orders o
  WHERE o.shippedDate > o.requiredDate;

  -- Employee Productivity: track the total sales each employee is responsible for by calculating the number of orders and the total revenue generated from these orders.comments
  SELECT e.firstName, e.lastName, 
         COUNT(o.orderNumber) AS total_orders,
		 SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM employees e
	JOIN customers c
	  ON e.employeeNumber = c.salesRepEmployeeNumber
	JOIN orders o
	  ON o.customerNumber = c.customerNumber
	JOIN orderdetails od
	  ON o.orderNumber = od.orderNumber
	GROUP BY e.employeeNumber
	ORDER BY total_sales DESC;
         
 -- Office with the best sales
 WITH EmployeeSales AS (
   SELECT e.firstName, e.lastName, e.officeCode,
         COUNT(o.orderNumber) AS total_orders,
		 SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM employees e
	JOIN customers c
	  ON e.employeeNumber = c.salesRepEmployeeNumber
	JOIN orders o
	  ON o.customerNumber = c.customerNumber
	JOIN orderdetails od
	  ON o.orderNumber = od.orderNumber
	GROUP BY e.employeeNumber,e.officeCode
	)
SELECT o.officeCode, o.city, o.country,
       SUM(es.total_sales) AS office_total_sales
  FROM offices o
  JOIN EmployeeSales es
    ON o.officeCode = es.officeCode
  GROUP BY o.officeCode, o.city, o.state
  ORDER BY office_total_sales DESC;
 
 
--  SELECT o.officeCode, o.city, o.state, SUM(od.quantityOrdered * od.priceEach) AS totalSales
-- FROM Offices o
-- JOIN Employees e ON o.officeCode = e.officeCode
-- JOIN Customers c ON e.employeeNumber = c.salesRepEmployeeNumber
-- JOIN Orders ord ON c.customerNumber = ord.customerNumber
-- JOIN OrderDetails od ON ord.orderNumber = od.orderNumber
-- GROUP BY o.officeCode
-- ORDER BY totalSales DESC;