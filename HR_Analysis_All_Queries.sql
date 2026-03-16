-- -- -- -- -- -- -- -- -- -- -- -- -- --
-- MI PRIMER PROJECTO DOMO DATA ANLYST --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- --




-- -- -- -- -- -- --
-- DATA EXTRACCION --
-- -- -- -- -- -- --

CREATE DATABASE BD_HR;
USE BD_HR;
/*
QUIERO QUECREES UNA TABLA EN SQL SERVER PARA PODER CAR MI CSV DE MI PROYECTO EL CUAL TIENE LAS SIGUIENTES 
COLUMNAS Y TE DOY LAS 4 PRIMERAS FILAS PARA QUE INFIERAS EL MEJOR TIPO DE DATO PERO A LA VES TENGA FEXIBILIDAD :

*/
---------------------------------
-- CARGA EMPLEADOS
---------------------------------
IF OBJECT_ID('Employee', 'U') IS NOT NULL
    DROP TABLE Employee;

CREATE TABLE Employee (
    -- Alfanumérico por el formato '3012-1A41'
    EmployeeID              NVARCHAR(50) PRIMARY KEY, 
    FirstName               NVARCHAR(100),
    LastName                NVARCHAR(100),
    Gender                  NVARCHAR(50),
    Age                     INT,
    BusinessTravel          NVARCHAR(100),
    Department              NVARCHAR(100),
    [DistanceFromHome (KM)] INT, -- Entre corchetes por el espacio y paréntesis
    State                   NVARCHAR(10), 
    Ethnicity               NVARCHAR(100),
    Education               INT, -- Es un nivel (1-5)
    EducationField          NVARCHAR(100),
    JobRole                 NVARCHAR(100),
    MaritalStatus           NVARCHAR(50),
    Salary                  DECIMAL(18, 2), -- Para manejar montos grandes con decimales
    StockOptionLevel        INT,
    OverTime                NVARCHAR(10),
    HireDate                DATE, -- El formato YYYY-MM-DD es nativo de SQL
    Attrition               NVARCHAR(10),
    YearsAtCompany          INT,
    YearsInMostRecentRole   INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager    INT
);

BULK INSERT Employee
FROM 'G:\Mi unidad\HOME\CURSO\PROYECTOS\SQL-Project-HR-Analytics-Attrition-and-Performance-main\SQL-Project-HR-Analytics\Employee.csv' -- Reemplaza con la ruta real
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,           -- Ignora el encabezado del CSV
    FIELDTERMINATOR = ',',  -- Cambia por ';' si tu CSV usa punto y coma
    ROWTERMINATOR = '\n' -- Salto de línea estándar (LF) o '\n'
   -- ENCODING = 'UTF-8'      -- Importante si tienes acentos o tildes
 
);

SELECT *
FROM Employee
IF OBJECT_ID('Employee', 'U') IS NOT NULL
    DROP TABLE PerformanceRating;
    


-- Crear la tabla con tipos de datos adecuados
CREATE TABLE PerformanceRating (
    PerformanceID                 NVARCHAR(20) PRIMARY KEY, -- Ej: 'PR01'
    EmployeeID                    NVARCHAR(50),             -- Debe coincidir con el formato de tu otra tabla
    ReviewDate                    DATE,                     -- SQL Server maneja formato YYYY-MM-DD
    EnvironmentSatisfaction       INT,
    JobSatisfaction               INT,
    RelationshipSatisfaction      INT,
    TrainingOpportunitiesWithinYear INT,
    TrainingOpportunitiesTaken    INT,
    WorkLifeBalance               INT,
    SelfRating                    INT,
    ManagerRating                 INT
);

BULK INSERT PerformanceRating
FROM 'G:\Mi unidad\HOME\CURSO\PROYECTOS\SQL-Project-HR-Analytics-Attrition-and-Performance-main\SQL-Project-HR-Analytics\PerformanceRating.csv' -- Reemplaza con la ruta real
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,           -- Ignora el encabezado del CSV
    FIELDTERMINATOR = ',',  -- Cambia por ';' si tu CSV usa punto y coma
    ROWTERMINATOR = '\n' -- Salto de línea estándar (LF) o '\n'
       -- Importante si tienes acentos o tildes
 
);

-- -- -- -- -- -- --
-- DATA CLEANING --
-- -- -- -- -- -- --
-- Verificar valores duplicados en la tabla Employe --

SELECT EmployeeID, COUNT(*)
FROM Employee
GROUP BY EmployeeID
HAVING COUNT(*) > 1;

-- Verificar valores duplicados en la tabla PerformanceRating --

SELECT PerformanceID, COUNT(*)
FROM PerformanceRating
GROUP BY PerformanceID
HAVING COUNT(*) > 1;

----------------------
-- Duplicate Values --
----------------------



-- Check for duplicate values in PerformanceRating table --

SELECT PerformanceID, COUNT(*)
FROM PerformanceRating
GROUP BY PerformanceID
HAVING COUNT(*) > 1;

-- Standardization --

-- Change DistanceFromHome (KM) measurement from kilometers (KM) to miles (MI) --

--UPDATE Employee
--SET `DistanceFromHome (KM)` = ROUND(`DistanceFromHome (KM)` * 0.621371, 0);

-- Change column name to DistanceFromHome(MI) --

--ALTER TABLE Employee CHANGE COLUMN `DistanceFromHome (KM)` `DistanceFromHome (MI)` INT;

-- Change ReviewDate to standard date format --
-- (due to Safe Updates being on in MySQL, I had to momentarily turn them off to perform this query) --

--SET SQL_SAFE_UPDATES = 0;
	/*
UPDATE PerformanceRating
SET ReviewDate = CASE
	WHEN LENGTH(ReviewDate) = 10 THEN DATE_FORMAT(STR_TO_DATE(ReviewDate, '%m/%d/%Y'), '%Y-%m-%d')
	ELSE DATE_FORMAT(STR_TO_DATE(ReviewDate, '%m/%d/%Y'), '%Y-%m-%d')
END
WHERE ReviewDate IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;
*/
-- Miscellaneous --

-- Check # of rows vs. # of employees in Employee table --

SELECT COUNT(*) AS AllRows,
	COUNT(DISTINCT EmployeeID) AS UniqueEmployees
FROM employee;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- EXPLORATORY DATA ANALYSIS AND INSIGHTS --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Question #1: What is the average tenure for employees within each department?

-- Average tenure by department --

SELECT Department,
	ROUND(AVG(YearsAtCompany), 2) AS AvgTenure_Years
FROM Employee
GROUP BY Department
ORDER BY AvgTenure_Years DESC;

-- Question #2: How many employees in each department are still working at the company?

-- # of Active Employees and % of Total --

SELECT Department,
	COUNT(*) AS ActiveEmployees,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*)
							FROM Employee
							WHERE Attrition = 'No'), 0
                            ) AS PercentageOfActive
FROM Employee
WHERE Attrition = 'No'
GROUP BY Department
ORDER BY ActiveEmployees DESC;

-- Question #3: How does job satisfaction for employees compare with different tenure levels?

-- Average job satisfaction by tenure category --
WITH Employee_segmentado AS (
    SELECT 
        CASE 
            WHEN YearsAtCompany < 3 THEN '< 3 years'
            WHEN YearsAtCompany BETWEEN 3 AND 5 THEN '3-5 years'
            ELSE '> 5 years' 
        END AS TenureCategory
        ,*
    FROM Employee
)
SELECT 
   TenureCategory,
    ROUND(AVG(p.JobSatisfaction), 3) AS AvgJobSatisfaction
FROM Employee_segmentado e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY TenureCategory
ORDER BY AvgJobSatisfaction DESC;

-- Question #4: What percentage of employees who work overtime have left the company?

-- Overtime attrition percentage --

SELECT OverTime, 
	ROUND(COUNT(CASE
					WHEN Attrition = 'Yes' THEN EmployeeID
				END) * 100.0 / COUNT(EmployeeID), 0) AS OverTimeAttritionPercentage
FROM Employee
GROUP BY OverTime
ORDER BY OverTime DESC;

-- Question #5: Rank departments by average manager ratings, separated by business travel.

-- Average manager ratings by department and travel --

SELECT e.Department,
    e.BusinessTravel,
    ROUND(AVG(p.ManagerRating), 2) AS AvgManagerRating,
    RANK() OVER (PARTITION BY e.BusinessTravel
		ORDER BY AVG(p.ManagerRating) DESC) AS DepartmentRank
FROM Employee e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY Department,
	BusinessTravel;

-- Average ManagerRating by Department --

SELECT e.Department,
	ROUND(AVG(p.ManagerRating), 2) AS AvgManagerRating
FROM Employee e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY Department
ORDER BY AvgManagerRating DESC;

-- Average manager rating by travel type --

SELECT e.BusinessTravel,
	ROUND(AVG(p.ManagerRating), 2) AS AvgManagerRating
FROM Employee e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY BusinessTravel
ORDER BY AvgManagerRating DESC;

-- Question #6: Is there a positive correlation between the number of training opportunities an employee has taken and their job satisfaction?

-- Average job satisfaction rating by training opportunities taken --

SELECT TrainingOpportunitiesTaken,
    ROUND(AVG(JobSatisfaction), 2) AS AvgJobSatisfaction
FROM PerformanceRating
GROUP BY TrainingOpportunitiesTaken
ORDER BY TrainingOpportunitiesTaken DESC;

-- Question #7: Identify the top three employees by their manager rating in each department.

-- Random top three employees by department, manager rating, and training opportunities taken --

WITH RandomTop3Performers AS (
    SELECT 
        CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
        e.Department,
        p.ManagerRating,
        p.TrainingOpportunitiesTaken,
        ROW_NUMBER() OVER (PARTITION BY e.Department
			ORDER BY p.ManagerRating,
				p.TrainingOpportunitiesTaken,
                RAND()) AS RowNum
    FROM Employee e
    JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
    WHERE p.ManagerRating = 5
        AND p.TrainingOpportunitiesTaken = 3
        AND e.Attrition = 'No'
)
SELECT FullName,
    Department
FROM RandomTop3Performers
WHERE RowNum <= 3;

-- Question #8: Categorize employees based on their distance from work and show average job satisfaction in each category.

-- Longest distance from work --

SELECT MAX([DistanceFromHome (KM)]) AS LongestDistance
FROM Employee;

-- Employee count and average job satisfaction by distance category --
WITH Employee_segmentado AS (
    SELECT 
        CASE 
            WHEN [DistanceFromHome (KM)] BETWEEN 1 AND 4 THEN '< 5 mi.'
            WHEN [DistanceFromHome (KM)] BETWEEN 5 AND 19 THEN '5-20 mi.'
            ELSE '20+ mi.' 
        END AS DistanceCategory
        ,*
    FROM Employee
)
SELECT
	DistanceCategory,
    COUNT(DISTINCT e.EmployeeID) AS EmployeeCount,
    ROUND(AVG(p.JobSatisfaction), 2) AS AvgJobSatisfaction
FROM Employee_segmentado e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY DistanceCategory
ORDER BY DistanceCategory;

-- Question #9: Is there a relationship between the number of promotions and the years an employee has spent with their current manager?

-- Average years since last promotion by years with current manager --

SELECT YearsWithCurrManager, ROUND(AVG(YearsSinceLastPromotion), 0) AS AvgYearsSinceLastPromotion
FROM Employee
GROUP BY YearsWithCurrManager
ORDER BY YearsWithCurrManager;

-- Question #10: For each department, identify the percentage of employees who have left the company and had a job satisfaction score below 3.

-- Percentage of former employees who had low job satisfaction rating --

SELECT e.Department,
	ROUND(COUNT(CASE
					WHEN e.Attrition = 'Yes'
						AND p.AvgJobSatisfaction < 3
					THEN 1
				END) * 100.0 / COUNT(*), 2) AS LowSatisfactionAttritionRate
FROM Employee e
JOIN (
	SELECT EmployeeID,
		AVG(JobSatisfaction) AS AvgJobSatisfaction
    FROM PerformanceRating
    GROUP BY EmployeeID
) p ON e.EmployeeID = p.EmployeeID
GROUP BY e.Department
ORDER BY LowSatisfactionAttritionRate DESC;