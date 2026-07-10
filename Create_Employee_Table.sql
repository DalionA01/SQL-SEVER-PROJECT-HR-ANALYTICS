USE [master];
GO

-- Crear base de datos si no existe
IF DB_ID('HRAnalytics') IS NULL
BEGIN
    CREATE DATABASE HRAnalytics;
END
GO

USE HRAnalytics;
GO

-- Eliminar tabla si ya existe
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Employee;
END
GO

-- Crear tabla para importar el archivo Employee.csv
CREATE TABLE dbo.Employee (
    EmployeeID              NVARCHAR(50) NOT NULL,
    FirstName               NVARCHAR(100) NULL,
    LastName                NVARCHAR(100) NULL,
    Gender                  NVARCHAR(20) NULL,
    Age                     INT NULL,
    BusinessTravel          NVARCHAR(100) NULL,
    Department              NVARCHAR(100) NULL,
    [DistanceFromHome (KM)] INT NULL,
    State                   NVARCHAR(10) NULL,
    Ethnicity               NVARCHAR(100) NULL,
    Education               INT NULL,
    EducationField          NVARCHAR(100) NULL,
    JobRole                 NVARCHAR(100) NULL,
    MaritalStatus           NVARCHAR(50) NULL,
    Salary                  DECIMAL(18,2) NULL,
    StockOptionLevel        INT NULL,
    OverTime                NVARCHAR(10) NULL,
    HireDate                DATE NULL,
    Attrition               NVARCHAR(10) NULL,
    YearsAtCompany          INT NULL,
    YearsInMostRecentRole   INT NULL,
    YearsSinceLastPromotion INT NULL,
    YearsWithCurrManager    INT NULL,
    CONSTRAINT PK_Employee PRIMARY KEY (EmployeeID)
);
GO

-- Importar el CSV
BULK INSERT dbo.Employee
FROM 'C:\Users\isaia\OneDrive\Escritorio\SQL\SQL-SEVER-PROJECT-HR-ANALYTICS\Data\Employee.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    DATAFILETYPE = 'char'
);
GO

-- Verificar datos cargados
SELECT TOP 10 *
FROM dbo.Employee;
GO
