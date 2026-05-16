use adventure;
show databases;
show tables;

rename table factinternetsales to Sales;
rename table factinternetsales_legacy to sales_New;


-- KPI 0

CREATE TABLE combined_sales AS
SELECT * FROM sales
UNION ALL
SELECT * FROM sales_new;

select * from combined_sales;

-- KPI 1

DESCRIBE dimproduct;

SELECT 
    cs.*,
    p.EnglishProductName
FROM combined_sales cs
LEFT JOIN dimproduct p
    ON cs.ProductKey = p.ProductKey;


-- KPI 2

SELECT
    cs.SalesOrderNumber,
    cs.CustomerKey,
    CONCAT(
        dc.FirstName, ' ',
        IFNULL(dc.MiddleName, ''),
        dc.LastName
    ) AS CustomerFullName,
    cs.ProductKey,
    dp.UnitPrice,
    cs.SalesAmount
FROM combined_sales cs
LEFT JOIN dimcustomer dc
    ON cs.CustomerKey = dc.CustomerKey
LEFT JOIN dimproduct dp
    ON cs.ProductKey = dp.ProductKey;

SELECT
    CustomerKey,
    CONCAT(FirstName, ' ', IFNULL(MiddleName, ''), LastName) AS FullName
FROM dimcustomer
LIMIT 10;

-- KPI 3

SELECT 
    OrderDateKey,
    STR_TO_DATE(OrderDateKey, '%Y%m%d') AS OrderDate
FROM combined_sales
LIMIT 10;

SELECT
    OrderDateKey,

    /* Create Date */
    STR_TO_DATE(OrderDateKey, '%Y%m%d') AS OrderDate,

    /* A. Year */
    YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Year,

    /* B. Month Number */
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthNo,

    /* C. Month Full Name */
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthFullName,

    /* D. Quarter */
    CONCAT('Q', QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d'))) AS Quarter,

    /* E. Year-Month (YYYY-MMM) */
    DATE_FORMAT(STR_TO_DATE(OrderDateKey, '%Y%m%d'), '%Y-%b') AS YearMonth,

    /* F. Weekday Number (Monday=1, Sunday=7) */
    WEEKDAY(STR_TO_DATE(OrderDateKey, '%Y%m%d')) + 1 AS WeekdayNo,

    /* G. Weekday Name */
    DAYNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS WeekdayName,

	-- H. Financial Month (April = FM1 ... March = FM12)
    CASE
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) >= 4
            THEN CONCAT('FM', MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) - 3)
        ELSE CONCAT('FM', MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) + 9)
    END AS FinancialMonth,

     -- I. Financial Quarter 
    CASE
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 4 AND 6 THEN 'FQ1'
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 7 AND 9 THEN 'FQ2'
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 10 AND 12 THEN 'FQ3'
        ELSE 'FQ4'
    END AS FinancialQuarter

FROM combined_sales;

-- KPI 4

-- Formula [ SalesAmount = UnitPrice × OrderQuantity × (1 − UnitPriceDiscountPct) ]

SELECT 
    cs.*,
    (cs.UnitPrice * cs.OrderQuantity * (1 - cs.UnitPriceDiscountPct)) AS SalesAmount
FROM combined_sales cs;

-- KPI 5

-- Formula [ ProductionCost = ProductStandardCost × OrderQuantity ]

SELECT 
    cs.*,
    (cs.ProductStandardCost * cs.OrderQuantity) AS ProductionCost
FROM combined_sales cs;


-- KPI 6

-- Formula [ Profit = Sales Amount − Production Cost ]

SELECT 
    cs.*,
    (cs.UnitPrice * cs.OrderQuantity * (1 - cs.UnitPriceDiscountPct)) 
        - (cs.ProductStandardCost * cs.OrderQuantity) AS Profit
FROM combined_sales cs;

-- KPI 7

-- Formula [ Sales = UnitPrice × OrderQuantity × (1 − UnitPriceDiscountPct) ]

SELECT
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthName,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM combined_sales
WHERE YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) = 2013
GROUP BY 
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')),
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d'))
ORDER BY MonthNo;


-- KPI 8  Year-Wise Sales

SELECT
    YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS SalesYear,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM combined_sales
GROUP BY YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d'))
ORDER BY SalesYear;

-- KPI 9 Month Wise Sales

SELECT
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthName,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM combined_sales
GROUP BY
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')),
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d'))
ORDER BY MonthNo;

-- KPI 10

SELECT
    CONCAT('Q', QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d'))) AS Quarter,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM combined_sales
GROUP BY
    CONCAT('Q', QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d')))
ORDER BY
    Quarter;
    
-- KPI 11

SELECT
    YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Year,
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthName,

    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS SalesAmount,
    SUM(ProductStandardCost * OrderQuantity) AS ProductionCost

FROM combined_sales
GROUP BY
    YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')),
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')),
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d'))

ORDER BY Year, MonthNo;

-- KPI 12

-- PRODUCT PERFORMANCE

SELECT
    p.EnglishProductName,
    ROUND(SUM(cs.UnitPrice * cs.OrderQuantity * (1 - cs.UnitPriceDiscountPct)), 2) AS SalesAmount
FROM combined_sales cs
JOIN dimproduct p
    ON cs.ProductKey = p.ProductKey
GROUP BY p.EnglishProductName
ORDER BY SalesAmount DESC
LIMIT 10;


-- CUSTOMER PERFORMANCE

SELECT
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    ROUND(SUM(cs.UnitPrice * cs.OrderQuantity * (1 - cs.UnitPriceDiscountPct)), 2) AS SalesAmount
FROM combined_sales cs
JOIN dimcustomer c
    ON cs.CustomerKey = c.CustomerKey
GROUP BY CustomerName
ORDER BY SalesAmount DESC
LIMIT 10;

-- Region-wise Sales Performance

SELECT
    t.SalesTerritoryRegion,
    ROUND(SUM(cs.UnitPrice * cs.OrderQuantity * (1 - cs.UnitPriceDiscountPct)) / 1000000, 2) AS SalesInMillions
FROM combined_sales cs
JOIN dimsalesterritory t
    ON cs.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryRegion
ORDER BY SalesInMillions DESC;

DESC dimsalesterritory;






