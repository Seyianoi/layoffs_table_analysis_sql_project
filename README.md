# Layoff Data Analysis Project

## Introduction

This project analyzes global layoff trends using SQL and PostgreSQL. The dataset contains information on layoffs across various industries, company stages, and countries. The goal is to derive insights into factors influencing layoffs, such as industry type, funding levels, and company growth stages. The results will help stakeholders understand workforce reduction patterns and potential risk factors.

## Background

The dataset consists of records detailing layoffs from different companies worldwide. It includes key attributes such as company name, location, industry, total layoffs, percentage layoffs, funding raised, and company stage. Data cleaning was necessary to handle missing values and inconsistencies before conducting in-depth analysis.

## Tools Used

- **SQL**: For querying and analyzing the layoff dataset.
- **PostgreSQL**: As the relational database management system for executing queries.
- **Git**: For version control and tracking query modifications.
- **GitHub**: For storing and sharing project files.

## Analysis

### **1. Data Cleaning**

**Query:**

```sql
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
```

**What I Learned:**

- Many records had missing industry values, which were filled with the most common industry in the same country.
- Cleaning the data improved the accuracy of further analysis.

**Conclusion:**
Cleaning the dataset ensured consistency and improved reliability for deeper analysis of layoff trends.

### **2. Identifying Companies with High Layoff Percentages**

**Query:**

```sql
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
```

**What I Learned:**

- Some companies laid off employees at rates significantly higher than their industry’s average.
- These high-percentage layoffs suggest financial instability or restructuring efforts.
- Find attached in the repository the query results.

**Conclusion:**
Industries experiencing high layoff percentages may be more volatile and require closer monitoring.

### **3. Ranking Companies by Layoffs per Country**

**Query:**

```sql
SELECT company, country, total_laid_off,
       RANK() OVER (PARTITION BY country ORDER BY total_laid_off DESC) AS rank
FROM layoffs
WHERE total_laid_off IS NOT NULL;
```

**What I Learned:**

- Certain companies within each country had significantly higher layoffs compared to others.
- Ranking layoffs per country helps identify companies and regions most affected.
- Find attached in the repository the query results.


**Conclusion:**
Layoffs are concentrated in specific companies and regions, indicating economic or industry-specific downturns.

### **4. Comparing Layoff Trends in Tech vs. Non-Tech Industries**

**Query:**

```sql
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

```

**What I Learned:**

- Non-tech industries faced significant layoffs despite high funding levels.
- Tech industries also suffered but with lower layoff percentages overall.
- Find attached in the repository the query results.


**Conclusion:**
Layoffs in non-tech industries indicate volatility, possibly due to market corrections or overhiring during growth periods.

### **5. Countries Where Funding Raised Did Not Prevent Layoffs**

**Query:**

```sql
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
```

**What I Learned:**

- Some countries with high funding still had large layoffs, proving that funding alone does not ensure job security.
- High layoff-to-funding ratios suggest poor financial management or external economic pressures.
- Find attached in the repository the query results.


**Conclusion:**
Funding alone is not a safeguard against layoffs. Other economic factors play a significant role.

### **6. Most Affected Layoff Stage in Companies**

**Query:**

```sql
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
    
```

**What I Learned:**

-Seed stage is the most affected.
- Find attached in the repository the query results.



**Conclusion:**
The starting stage of a company is the most crucial of all

## What I Learned

- **Both tech and non_tech companies, despite high funding, still faced significant layoffs, challenging the assumption that strong financial backing ensures stability.**
- **Certain industries had consistently higher layoff rates, indicating they are more vulnerable to economic downturns.**
- **Funding raised does not always prevent layoffs, as some companies with significant capital still had large-scale workforce reductions.**

## Conclusion

This project provided valuable insights into workforce reduction trends. The findings suggest that while funding and industry type influence layoffs, external economic conditions and company decisions play a crucial role. Future research could explore the relationship between layoffs and stock performance, profitability, and external economic indicators.

