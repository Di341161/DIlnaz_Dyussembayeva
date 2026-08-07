CREATE DATABASE final_project_di;
USE final_project_di;
UPDATE customer_final SET Gender = NULL WHERE Gender ='';
UPDATE customer_final SET Age = NULL WHERE Age ='';
ALTER TABLE customer_final MODIFY AGE INT NULL;

SELECT * FROM customer_final;

CREATE TABLE Transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2));

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS_final.csv" 
INTO TABLE Transactions 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

SELECT Id_check, COUNT(*) AS rows_in_check
FROM transactions 
GROUP BY Id_check 
HAVING COUNT(*) > 1
LIMIT 20;

#1
SELECT
    t.ID_client,
    AVG(t.Sum_payment) AS avg_check,
    m.avg_month_sum,
    COUNT(t.Id_check) AS operation_count
FROM Transactions t
JOIN (
    SELECT
        ID_client
    FROM Transactions
    GROUP BY ID_client
    HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12
) c
ON t.ID_client = c.ID_client
JOIN (
    SELECT
        ID_client,
        AVG(month_sum) AS avg_month_sum
    FROM (
        SELECT
            ID_client,
            DATE_FORMAT(date_new, '%Y-%m') AS month,
            SUM(Sum_payment) AS month_sum
        FROM Transactions
        GROUP BY
            ID_client,
            DATE_FORMAT(date_new, '%Y-%m')
    )  monthly_sum
    GROUP BY ID_client
) m
ON t.ID_client = m.ID_client
GROUP BY
    t.ID_client,
    m.avg_month_sum;

#2
#a средняя сумма чека в месяц
SELECT
	DATE_FORMAT(date_new, '%Y-%m') AS month,
    AVG(Sum_payment) AS avg_check
FROM Transactions
GROUP BY DATE_FORMAT(date_new, '%Y-%m');

#b среднее количество операций в месяц
SELECT 
	DATE_FORMAT(date_new, '%Y-%m') AS month, 
    COUNT(Id_check) AS operation_count
FROM Transactions
GROUP BY DATE_FORMAT(date_new, '%Y-%m');

#c среднее количество клиентов, которые совершали операции
SELECT 
	DATE_FORMAT(date_new, '%Y-%m') AS month, 
    COUNT(DISTINCT ID_client) as id_client_count
FROM Transactions
GROUP BY DATE_FORMAT(date_new, '%Y-%m');

#d долю от общего количества операций за год и долю в месяц от общей суммы операций;
SELECT
    m.month,
    m.operation_count,
    m.month_sum,
    (m.operation_count * 100.0 / y.total_operations) AS operation_share,
    (m.month_sum * 100.0 / y.total_sum) AS payment_share
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(Id_check) AS operation_count,
        SUM(Sum_payment) AS month_sum
    FROM Transactions
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')) m
CROSS JOIN (
    SELECT
        COUNT(Id_check) AS total_operations,
        SUM(Sum_payment) AS total_sum
    FROM Transactions) y;
    
#e вывести % соотношение M/F/NA в каждом месяце с их долей затрат
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    CASE
        WHEN c.Gender IS NULL THEN 'NA'
        ELSE c.Gender
    END AS Gender,
    COUNT(DISTINCT t.ID_client) AS client_count,
    SUM(t.Sum_payment) AS total_spent,
    ROUND(
        COUNT(DISTINCT t.ID_client) * 100.0 /
        m.total_clients, 2
    ) AS client_percent,
    ROUND(
        SUM(t.Sum_payment) * 100.0 /
        m.total_spent, 2
    ) AS spending_percent
FROM transactions t
JOIN customer_final c
    ON t.ID_client = c.ID_client
JOIN (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT ID_client) AS total_clients,
        SUM(Sum_payment) AS total_spent
    FROM transactions
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
) m
ON DATE_FORMAT(t.date_new, '%Y-%m') = m.month
GROUP BY
    DATE_FORMAT(t.date_new, '%Y-%m'),
    CASE
        WHEN c.Gender IS NULL THEN 'NA'
        ELSE c.Gender
    END,
    m.total_clients,
    m.total_spent
ORDER BY
    month,
    Gender;
    
#3 
#за весь период
SELECT
    CASE
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 20 THEN '0-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS age_group,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(t.Id_check) AS operation_count
FROM Transactions t
JOIN customer_final c
ON t.ID_client = c.ID_client
GROUP BY age_group
ORDER BY age_group;

#поквартально
SELECT
    QUARTER(t.date_new) AS quarter,
    CASE
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS age_group,
    AVG(t.Sum_payment) AS avg_check,
    COUNT(t.Id_check) AS operation_count,
    ROUND(
        SUM(t.Sum_payment) * 100.0 / q.total_sum,
        2
    ) AS percent_sum
FROM Transactions t
JOIN customer_final c
ON t.ID_client = c.ID_client
JOIN (
    SELECT
        QUARTER(date_new) AS quarter,
        SUM(Sum_payment) AS total_sum
    FROM Transactions
    GROUP BY QUARTER(date_new)
) q
ON QUARTER(t.date_new) = q.quarter
GROUP BY
    QUARTER(t.date_new),
    age_group,
    q.total_sum
ORDER BY
    quarter,
    age_group;