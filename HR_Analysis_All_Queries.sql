
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

-----------------------------------
-- Verificar valores duplicados  --
-----------------------------------



-- Verificar valores duplicados en la tabla Employe --

SELECT EmployeeID, COUNT(*)
FROM Employee
GROUP BY EmployeeID
HAVING COUNT(*) > 1;

-- Verificar valores duplicados en la tabla PerformanceRating --

SELECT PerformanceID, COUNT(*)
FROM PerformanceRating
GROUP BY PerformanceID


-- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- EXPLORATORY DATA ANALYSIS AND INSIGHTS --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- --

--Pregunta #1: ¿Cuál es la antigüedad promedio de los empleados en cada departamento?

-- Antigüedad promedio por departamento  --

SELECT Department,
	ROUND(AVG(YearsAtCompany), 2) AS AvgTenure_Years
FROM Employee
GROUP BY Department
ORDER BY AvgTenure_Years DESC;

-- Pregunta #2: ¿Cuántos empleados en cada departamento siguen trabajando en la empresa?
-- Empleados Activos --

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

-- Promedio de satisfacción laboral por categoría de antigüedad--
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
    ROUND(AVG(CAST(p.JobSatisfaction AS FLOAT)), 2) AS AvgJobSatisfaction
FROM Employee_segmentado e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY TenureCategory
ORDER BY AvgJobSatisfaction DESC;


-- Pregunta #4: Examinar cuántos empleados que trabajaron horas extras han dejado la empresa frente a los que no trabajaron horas extras. --

SELECT OverTime, 
	ROUND(COUNT(CASE
					WHEN Attrition = 'Yes' THEN EmployeeID
				END) * 100/ COUNT(EmployeeID),2) AS OverTimeAttritionPercentage
FROM Employee
GROUP BY OverTime
ORDER BY OverTime DESC;

-- Pregunta #5: Clasificar los departamentos por calificaciones promedio de los gerentes, separados por viajes de negocios.
-- Calificaciones promedio de gerentes por departamento y viajes --

SELECT e.Department,
    e.BusinessTravel,
    ROUND(AVG(CAST(p.ManagerRating AS FLOAT)), 2) AS AvgManagerRating,
    RANK() OVER (PARTITION BY e.BusinessTravel
		ORDER BY AVG(p.ManagerRating) DESC) AS DepartmentRank
FROM Employee e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY Department,
	BusinessTravel;

-- promedio total de ManagerRating  por Departamento y  BusinessTravel. --

SELECT e.Department,
	ROUND(AVG(CAST(p.ManagerRating AS FLOAT)), 2) AS AvgManagerRating
FROM Employee e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY Department
ORDER BY AvgManagerRating DESC;

-- Calificación promedio del gerente por departamento --

SELECT e.BusinessTravel,
	ROUND(AVG(CAST(p.ManagerRating AS FLOAT)), 2) AS AvgManagerRating
FROM Employee e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY BusinessTravel
ORDER BY AvgManagerRating DESC;

-- Pregunta #6: ¿Existe una correlación positiva entre el número de oportunidades de capacitación que ha tomado un empleado y su satisfacción laboral?

-- Satisfacción laboral promedio por oportunidades de capacitación tomadas --

SELECT TrainingOpportunitiesTaken,
    ROUND(AVG(CAST(JobSatisfaction AS FLOAT)), 2) AS AvgJobSatisfaction
FROM PerformanceRating
GROUP BY TrainingOpportunitiesTaken
ORDER BY TrainingOpportunitiesTaken DESC;

-- Pregunta #7: Identificar a los tres mejores empleados según la calificación de su gerente en cada departamento.
--Top tres empleados aleatorios por departamento, calificación de gerente y capacitación tomad
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

-- Pregunta #8: Categorizar a los empleados según su distancia al trabajo y mostrar la satisfacción laboral promedio en cada categoría.

-- Distancia maxima a su centro de trabajo Max--

SELECT MAX([DistanceFromHome (KM)]) AS LongestDistance
FROM Employee;

-- Employee count and average job satisfaction by distance category --
WITH Employee_segmentado AS (
    SELECT 
        CASE 
            WHEN [DistanceFromHome (KM)] BETWEEN 1 AND 9 THEN '< 10 KM'
            WHEN [DistanceFromHome (KM)] BETWEEN 10 AND 30 THEN '10-30 KM'
            ELSE '30K +' 
        END AS DistanceCategory
        ,*
    FROM Employee
)
SELECT
	DistanceCategory,
    COUNT(DISTINCT e.EmployeeID) AS EmployeeCount,
    ROUND(AVG(CAST(p.JobSatisfaction AS FLOAT)), 2) AS AvgJobSatisfaction
FROM Employee_segmentado e
JOIN PerformanceRating p ON e.EmployeeID = p.EmployeeID
GROUP BY DistanceCategory
ORDER BY DistanceCategory;

-- ### Pregunta #9: ¿Existe una relación entre el número de promociones y los años que un empleado ha pasado con su gerente actual?
-- Promedio de años desde la última promoción por años con el gerente actual --
SELECT YearsWithCurrManager, ROUND(AVG(YearsSinceLastPromotion), 0) AS AvgYearsSinceLastPromotion
FROM Employee
GROUP BY YearsWithCurrManager
ORDER BY YearsWithCurrManager;

-- Pregunta #10: Para cada departamento, identificar el porcentaje de empleados que han dejado la empresa y tenían una puntuación de satisfacción laboral inferior a 3.
-- Percentage of former employees who had low job satisfaction rating --

WITH JobSatisfaction_Avg AS (
    
    SELECT 
        EmployeeID,
        AVG(JobSatisfaction * 1.0) AS AvgJobSatisfaction
    FROM PerformanceRating
    GROUP BY EmployeeID
)
SELECT 
    e.Department,
    -- Aplicamos CAST al final para limpiar la visualización
    CAST(
        SUM(CASE WHEN e.Attrition = 'Yes' AND p.AvgJobSatisfaction < 3 THEN 1.0 ELSE 0 END) 
        * 100.0 / COUNT(1) 
    AS DECIMAL(10, 2)) AS LowSatisfactionAttritionRate
FROM Employee e
JOIN JobSatisfaction_Avg p ON e.EmployeeID = p.EmployeeID
GROUP BY e.Department
ORDER BY LowSatisfactionAttritionRate DESC;
