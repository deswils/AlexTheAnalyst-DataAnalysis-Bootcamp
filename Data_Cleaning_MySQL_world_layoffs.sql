-- ***DATA CLEANING***
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Null values or blank values
-- 4. Remove any columns


-- *STAGING*
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;


SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;


WITH duplicate_cte AS
(
SELECT *, ROW_NUMBER()
OVER(PARTITION BY company, location, industry,
total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- **STAGING 2 TO DELETE DUP ROWS**

-- create layoffs staging 2
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- add data to layoffs_staging2 from layoffs_staging

INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER()
OVER(PARTITION BY company, location, industry,
total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- delete dup rows

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- **STANDARDIZING DATA**

-- trim whitespace

UPDATE layoffs_staging2
SET company = TRIM(company);

-- standardize dup industry (crypto & crypto currency -> crypto)

/*
SELECT DISTINCT industry
FROM layoffs_staging2;
*/

UPDATE layoffs_staging2
SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

-- standardize locations (remove '.' from United States)

/*
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY country;
*/ 

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Standardize `date` column (STR_TO_DATE)

/*
SELECT `date`
FROM layoffs_staging2;
*/

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change `date` column data type (text -> date) 

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- ** FIX NULL/BLANK VALUES **

-- Set blanks to nulls (industry)

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Update null fields w/ industry if industry is given by table

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- Deleting rows where total_laid_off & percentage_laid_off are NULL

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Drop row_num column (no longer needed)

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

/*
SELECT *
FROM layoffs_staging2;
*/







