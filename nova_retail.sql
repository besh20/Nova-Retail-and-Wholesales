CREATE TABLE raw_retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),  -- text is processed from disk not memory thus make the dashboard late if not use ALTER TABLE products MODIFY COLUMN description TEXT 
    Quantity INT,
    InvoiceDate VARCHAR(20),     
    InvoiceTime VARCHAR(20),      
    UnitPrice DECIMAL(10,2),
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
);
SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/online_retail.csv' 
INTO TABLE raw_retail
CHARACTER SET latin1  -- ALTER TABLE raw_retail CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; convert to utf-8 later if needed 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;	


SELECT InvoiceNo, Description, Quantity, UnitPrice 
FROM raw_retail 
WHERE InvoiceNo LIKE 'C%' 
LIMIT 5;

SELECT InvoiceDate, InvoiceTime 
FROM raw_retail 
LIMIT 5;

SELECT * FROM raw_retail 
WHERE Description IS NULL OR UnitPrice = 0 
LIMIT 10;

-- Scripting 

-- copy of the raw file  
CREATE TABLE retail AS 
SELECT * FROM raw_retail;

-- Turn off safe mode
SET SQL_SAFE_UPDATES = 0;

UPDATE retail SET InvoiceTime = STR_TO_DATE(InvoiceTime, '%h:%i:%s %p');

ALTER TABLE retail
MODIFY COLUMN InvoiceDate DATE,
MODIFY COLUMN InvoiceTime TIME;

-- Turn safe mode back on (Good practice)
SET SQL_SAFE_UPDATES = 1;


-- Guest Customer 

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 1 ELSE 0 END) AS missing_id_count,
    ROUND(SUM(CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS percent_missing
FROM retail;

UPDATE retail 
SET CustomerID = 'Guest' 
WHERE CustomerID IS NULL OR CustomerID = ''; 


-- Add a flag column to solve the C problem in invoice 

ALTER TABLE retail ADD COLUMN TransactionStatus VARCHAR(20);

UPDATE retail 
SET TransactionStatus = 'Cancelled' 
WHERE InvoiceNo LIKE 'C%';

UPDATE retail 
SET TransactionStatus = 'Completed' 
WHERE TransactionStatus IS NULL;

SELECT TransactionStatus, COUNT(*) AS total_count
FROM retail
GROUP BY TransactionStatus;

-- Find rows where there is no value and deleting them cuz have no financial value or no items. why? Warehouse Adjustments, Gifts.
SELECT * FROM retail 
WHERE UnitPrice = 0 OR Quantity = 0;

DELETE FROM retail 
WHERE UnitPrice <= 0 OR Quantity = 0;

-- Discovery search
SELECT DISTINCT StockCode, Description
FROM retail
WHERE StockCode NOT REGEXP '^[0-9]';


ALTER TABLE retail ADD COLUMN ItemType VARCHAR(50);

-- set the default
UPDATE retail SET ItemType = 'Product';

-- override for the specific Administrative codes I found
UPDATE retail 
SET ItemType = 'Fees/Adjustments'
WHERE StockCode IN ('POST', 'D', 'C2', 'M', 'BANK CHARGES', 'AMAZONFEE', 'B', 'CRUK', 'DOT');

-- handle the Vouchers (They are revenue, but not 'physical' stock)
UPDATE retail 
SET ItemType = 'Voucher'
WHERE StockCode LIKE 'gift_0001%';

SET SQL_SAFE_UPDATES = 1;

SELECT Description, ROUND(SUM(Quantity * UnitPrice), 2) AS TotalLost
FROM retail
WHERE StockCode = 'B'
GROUP BY Description;


-- Create a clean, final table for all your analysis
CREATE TABLE retail_analytics AS
SELECT 
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    InvoiceTime,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS LineTotal,
    CustomerID,
    Country,
    TransactionStatus,
    ItemType
FROM retail
WHERE UnitPrice > 0 AND Quantity != 0;

select *
from retail_analytics;

-- Grand Totals
SELECT 
    ItemType,
    TransactionStatus,
    COUNT(*) AS Row_Count,
    ROUND(SUM(LineTotal), 2) AS Final_Value
FROM retail_analytics
GROUP BY ItemType, TransactionStatus
ORDER BY ItemType, TransactionStatus;

-- Top 10 Customers 
SELECT 
    CustomerID, 
    COUNT(DISTINCT InvoiceNo) AS NumOrders,
    SUM(Quantity * UnitPrice) AS TotalSpent
FROM retail
WHERE TransactionStatus = 'Completed' 
  AND CustomerID != 'Guest'
GROUP BY CustomerID
ORDER BY TotalSpent DESC
LIMIT 10;

-- Sales Seasonality (When do people shop?)
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS MonthlyRevenue
FROM retail
WHERE TransactionStatus = 'Completed'
GROUP BY Month
ORDER BY Month;

 --  Loss(How much is being returned?)
 
 SELECT 
    Country,
    ROUND(SUM(CASE WHEN TransactionStatus = 'Cancelled' THEN LineTotal ELSE 0 END), 2) AS TotalReturns,
    ROUND(SUM(CASE WHEN TransactionStatus = 'Completed' THEN LineTotal ELSE 0 END), 2) AS TotalSales 
FROM retail_analytics
GROUP BY Country
ORDER BY TotalReturns ASC -- Since returns are negative, the "lowest" number is the biggest loss
LIMIT 10;
 
SELECT 
    ROUND(SUM(CASE WHEN TransactionStatus = 'Cancelled' THEN 1 ELSE 0 END) 
          / COUNT(*) * 100, 2) AS Cancelled_Percentage,
    
    ROUND(SUM(CASE WHEN TransactionStatus = 'Completed' THEN 1 ELSE 0 END) 
          / COUNT(*) * 100, 2) AS Completed_Percentage
FROM retail;
