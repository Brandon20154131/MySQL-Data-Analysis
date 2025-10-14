/*
===============================================================================
Corporate Layoffs Data Cleaning
===============================================================================
Description:
    - This script performs a comprehensive data cleaning process on the 'layoffs' dataset.
    - This script is designed to ensure the raw data remains untouched.
    - Always work on a copy of raw data (staging table) to preserve original datasets.
    - The steps include:
        1. Creating a staging table to work on a copy of the raw data.
        2. Removing duplicate records.
        3. Standardizing text fields such as company names, industries, and countries.
        4. Handling NULL and blank values.
        5. Formatting dates for time series analysis.
        6. Removing irrelevant rows and unnecessary columns.
===============================================================================
*/


-- Step 0: Preview raw data
SELECT *
FROM layoffs;

-- Step 1: Create a staging table to work on a copy of the raw data
CREATE TABLE layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- Step 2: Identify duplicate rows using ROW_NUMBER
WITH cte_duplicate AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, 
                            percentage_laid_off, `date`, stage, country, 
                            funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM cte_duplicate
WHERE row_num > 1;  -- Rows with row_num > 1 are duplicates

-- Step 3: Remove duplicates by creating a new staging table with row numbers
CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off TEXT,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions TEXT,
    row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, 
                        percentage_laid_off, `date`, stage, country, 
                        funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Verify duplicates removed
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Step 4: Standardize text fields
-- Remove leading/trailing whitespace from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize industry names (e.g., 'Crypto', 'Cryptocurrency', 'Crypto currency' -> 'Crypto')
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names by removing trailing periods
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Step 5: Format date column for time series analysis
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

-- Replace blank or 'NULL' strings with actual NULLs
UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` = 'NULL' OR `date` = '';

-- Convert date column type to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Step 6: Handle missing or NULL values
-- Update blank industry values to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing industries using other records of the same company
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Step 7: Remove rows where both total_laid_off and percentage_laid_off are NULL
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Step 8: Remove unnecessary columns
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final data check
SELECT *
FROM layoffs_staging2;

WHERE industry IS NULL;
-- only entry with no industry
