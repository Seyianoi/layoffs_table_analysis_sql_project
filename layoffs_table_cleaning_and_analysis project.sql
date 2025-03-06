/* Data cleaning process which involves:
   1. Removing duplicates.
   2.Standardize the data.
   3.Remove NULL and BLANK values.
*/

/* 1. Removing duplicates*/
SELECT *, COUNT(*)
FROM layoffs
GROUP BY company,location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
HAVING COUNT(*) >1;

/*2.Standardize the data*/
UPDATE layoffs
SET company = UPPER(TRIM(company))
WHERE company IS NOT NULL AND company <> '';

/*3.Find NULL values and replace them Blanks with NULLS.*/
--Find NULL values
SELECT * FROM layoffs 
WHERE 
    company = '' OR company IS NULL 
    OR location = '' OR location IS NULL
    OR industry = '' OR industry IS NULL
    OR stage = '' OR stage IS NULL
    OR country = '' OR country IS NULL
    OR date IS NULL  
    OR percentage_laid_off IS NULL  
    OR total_laid_off IS NULL  
    OR funds_raised_millions IS NULL;  

--Replacing blanks with NULL values.
DO $$ 
DECLARE 
    col_name TEXT;
    sql_query TEXT := 'UPDATE layoffs SET ';
BEGIN 
    FOR col_name IN 
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'layoffs' AND data_type IN ('character varying', 'text') -- Only text columns
    LOOP
        sql_query := sql_query || col_name || ' = NULLIF(' || col_name || ', ''''), ';
    END LOOP;

    sql_query := LEFT(sql_query, LENGTH(sql_query) - 2); 
   
    EXECUTE sql_query;
END $$;

/* Query to identify companies with high layoff percentages*/
WITH Industry_percentage_average AS(
     SELECT industry, AVG( percentage_laid_off) AS avg_layoff_rate
	 FROM layoffs
	 WHERE percentage_laid_off IS NOT NULL
	 GROUP BY industry
)
SELECT company, percentage_laid_off
FROM layoffs
INNER JOIN industry_percentage_average ON layoffs.industry=industry_percentage_average.industry
WHERE layoffs.percentage_laid_off >industry_percentage_average.avg_layoff_rate
ORDER BY percentage_laid_off DESC;

/*Query to rank companies by layoffs per country*/
SELECT company,country,total_laid_off,
RANK() OVER(PARTITION BY country ORDER BY total_laid_off) AS rank
FROM layoffs
WHERE total_laid_off IS NOT NULL;

/*Query to compare layoff trends in Tech VS Non-tech industries*/
SELECT DISTINCT(industry)
FROM layoffs;

SELECT 
       CASE WHEN industry IN('Fintech','Crypto','Cryptocurrency','Data') THEN 'Tech'
	   ELSE 'Non-tech'
	   END AS category,
COUNT(*) AS num_companies,
SUM(total_laid_off)AS total_layoffs,
AVG(percentage_laid_off) AS avg_layoffs
FROM layoffs
GROUP BY category;

/*Query to identify countrieswhere funding raised did not prevent layoffs*/
WITH country_funding AS(
         SELECT country, SUM(total_laid_off) AS total_layoffs, SUM(funds_raised_millions) AS total_funding
		 FROM layoffs
		 WHERE total_laid_off IS NOT NULL AND funds_raised_millions IS NOT NULL
		 GROUP BY country
)
SELECT country, total_layoffs, total_funding,(total_layoffs/total_funding) AS layoff_to_funding_ratio
FROM country_funding
WHERE total_layoffs >5000 AND total_funding >1000
ORDER BY layoff_to_funding_ratio DESC;

/*Query to return the most affected stage of companies*/
WITH StageAvgLayoffs AS (
    SELECT stage,AVG(percentage_laid_off) AS avg_layoff_rate
    FROM layoffs
    WHERE percentage_laid_off IS NOT NULL
    GROUP BY stage
)
SELECT stage 
FROM StageAvgLayoffs 
ORDER BY avg_layoff_rate DESC 
LIMIT 1;
    






















