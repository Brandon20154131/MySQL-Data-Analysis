/*
===============================================================================
Corporate Layoffs Exploratory Data Analysis (EDA)
===============================================================================
Description:
    - This script performs exploratory data analysis on the 'layoffs_staging2' staging table we created in the cleaning phase.
    - It includes analytic queries such as ranking, rolling totals, outlier detection using Interquartile Range (IQR) and parameterized stored procedures for country-industry breakdowns.
===============================================================================
*/


-- Step 0: Preview the data
SELECT *
FROM layoffs_staging2;

-----------------------------------------------------------
-- Basic Queries
-----------------------------------------------------------

-- Total layoffs across all companies
SELECT 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2;

-- Total layoffs by year
SELECT 
  YEAR(`date`) AS year, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY year;

-- Total layoffs by month
SELECT 
  SUBSTRING(`date`,1,7) AS month, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY month
ORDER BY month;

-- Total layoffs by company
SELECT 
  company, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY total_layoffs DESC;

-- Total layoffs by company each year
SELECT 
  company, 
  YEAR(`date`) AS year, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY company ASC;

-----------------------------------------------------------
-- Aggregation
-----------------------------------------------------------

-- Total layoffs by country
SELECT 
  country, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY total_layoffs DESC;

-- Total layoffs by industry
SELECT 
  industry, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC;

-- Total layoffs by company stage
SELECT 
  stage, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY total_layoffs DESC;

-- Average percentage laid off by industry
SELECT 
  industry, 
  AVG(percentage_laid_off) AS avg_percentage
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY avg_percentage DESC;

-- Top 5 companies with highest layoffs overall
SELECT 
  company, 
  SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE company IS NOT NULL
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 5;

-- Rank industries by total layoffs
SELECT 
  industry, 
  SUM(total_laid_off) AS total_layoffs,
  DENSE_RANK() OVER (ORDER BY SUM(total_laid_off) DESC) AS ranking
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry;

-----------------------------------------------------------
-- Analytics
-----------------------------------------------------------

-- Rolling total of layoffs by month
WITH Rolling_total AS (
    SELECT SUBSTRING(`date`,1,7) AS month, SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`,1,7) IS NOT NULL
    GROUP BY month
    ORDER BY month
)
SELECT month, total_layoffs,
       SUM(total_layoffs) OVER(ORDER BY month) AS rolling_total
FROM Rolling_total;

-- Top 5 companies with most layoffs per year
WITH Company_Year AS (
    SELECT company, YEAR(`date`) AS year, SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
), Company_rank AS (
    SELECT *,
           DENSE_RANK() OVER(PARTITION BY year ORDER BY total_layoffs DESC) AS ranking
    FROM Company_Year
    WHERE year IS NOT NULL
)
SELECT *
FROM Company_rank
WHERE ranking <= 5;

-- Layoff profile by combining stage, industry and layoff size
WITH scale AS (
    SELECT *,
           CASE
               WHEN percentage_laid_off = 1 THEN 'Full Layoff'
               WHEN percentage_laid_off < 1 AND percentage_laid_off >= 0.66 THEN 'Large Layoff'
               WHEN percentage_laid_off < 0.66 AND percentage_laid_off >= 0.33 THEN 'Medium Layoff'
               WHEN percentage_laid_off < 0.33 AND percentage_laid_off > 0 THEN 'Small Layoff'
               WHEN percentage_laid_off IS NULL THEN 'Unknown'
           END AS layoff_bracket
    FROM layoffs_staging2
)
SELECT company,
       CONCAT(stage, ' - ', industry, ' with ', layoff_bracket) AS layoff_profile
FROM scale;

-- Interquartile Range (IQR) analysis to identify outliers by industry
WITH ranked AS (
    SELECT industry, company,
           CAST(total_laid_off AS UNSIGNED) AS total_laid_off,
           ROW_NUMBER() OVER (PARTITION BY industry ORDER BY CAST(total_laid_off AS UNSIGNED) ASC) AS rn,
           COUNT(*) OVER (PARTITION BY industry) AS total_count
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
),
quartiles AS (
    SELECT industry,
           AVG(CASE WHEN rn = FLOOR((total_count + 1)/4.0) OR rn = CEIL((total_count + 1)/4.0) THEN total_laid_off END) AS Q1,
           AVG(CASE WHEN rn = FLOOR(3*(total_count + 1)/4.0) OR rn = CEIL(3*(total_count + 1)/4.0) THEN total_laid_off END) AS Q3
    FROM ranked
    GROUP BY industry
),
bounds AS (
    SELECT industry, Q1, Q3,
           (Q3 - Q1) AS IQR,
           Q1 - 1.5*(Q3 - Q1) AS lower_bound,
           Q3 + 1.5*(Q3 - Q1) AS upper_bound
    FROM quartiles
)
SELECT r.industry, r.company, r.total_laid_off, b.Q1, b.Q3, b.lower_bound, b.upper_bound,
       CASE WHEN r.total_laid_off < b.lower_bound OR r.total_laid_off > b.upper_bound THEN 'Outlier'
            ELSE 'Normal' END AS outlier_status
FROM ranked r
JOIN bounds b ON r.industry = b.industry
ORDER BY r.industry, r.total_laid_off ASC;

-----------------------------------------------------------
-- Stored Procedure: Top layoffs by country and industry
-----------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE CountryIndustryBreakdown(country_param VARCHAR(255), ranking_param INT)
BEGIN
    WITH country_layoffs AS (
        SELECT country, industry, SUM(total_laid_off) AS total_laid_off
        FROM layoffs_staging2
        WHERE total_laid_off IS NOT NULL AND industry IS NOT NULL
        GROUP BY country, industry
    ),
    ranking AS (
        SELECT *,
               DENSE_RANK() OVER(PARTITION BY country ORDER BY total_laid_off DESC) AS ranking
        FROM country_layoffs
    )
    SELECT *
    FROM ranking
    WHERE country = country_param
      AND ranking <= ranking_param
    GROUP BY country, industry;
END$$
DELIMITER ;

-- Example call: Top 5 industries by layoffs in the United States
CALL CountryIndustryBreakdown('United States', 5);
