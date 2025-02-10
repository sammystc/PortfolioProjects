-- Data Cleaning Project: Data Scientist Jobs on LinkedIn

/* Steps for Data Cleaning: 
 * 
 * 1. Remove Duplicates
 * 2. Fix Structural Errors and Standardize Data
 * 3. Look at null/missing values
 */


SELECT *
FROM datasciencejobs.uncleaned_ds_jobs
LIMIT 500;









-- 1. Check for any Duplicates
/* using window function to partition jobs by their identifiers; 
 	if the title, company name, location, description, and rating are the same, the row number will be >1
 	since each job with a distinct set of identifiers will be given a row_num = 1
*/ 

SELECT * 
FROM (
	SELECT *, 
		ROW_NUMBER () OVER (
			PARTITION BY JobTitle, CompanyName, Location, JobDescription, Rating) AS row_num
	FROM datasciencejobs.uncleaned_ds_jobs 
) duplicates
WHERE row_num>1
;

-- Delete Duplicates
/* Cannot use delete function with window function using MySQL server; must create a new table (staging table) 
 
	Then insert data from original data table into new table (staging_jobs) and add column for row_num.
	
	Delete duplicates (data where row_num>1) and then delete row_num column

*/

CREATE TABLE DATASCIENCEJOBS.STAGING_JOBS (
	job_id INT NULL,
	jobtitle TEXT NULL,
	salaryestimate TEXT NULL,
	jobdescription LONGTEXT NULL,
	rating DECIMAL(10,1) NULL,
	company TEXT NULL,
	location TEXT NULL,
	headquarters TEXT NULL,
	`size` TEXT NULL,
	founded INT NULL,
	ownership TEXT NULL,
	industry TEXT NULL,
	sector TEXT NULL,
	revenue TEXT NULL,
	competitors TEXT NULL,
	row_num INT NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci
;


INSERT INTO DATASCIENCEJOBS.STAGING_JOBS 
SELECT *, 
	ROW_NUMBER () OVER (
			PARTITION BY JobTitle, CompanyName, Location, JobDescription, Rating) AS row_num
FROM datasciencejobs.uncleaned_ds_jobs 

;


DELETE  
FROM DATASCIENCEJOBS.STAGING_JOBS 
WHERE row_num>1
;

-- check that the duplicates are removed (below query should return nothing)

SELECT *
FROM DATASCIENCEJOBS.STAGING_JOBS 
WHERE row_num >1
;

-- drop 'row_num' column

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS DROP COLUMN row_num;











-- 2.Fix Structural Errors and Standardize Data


-- in salary estimate column, get rid of '$', 'K' and keep only numeric range
-- start by removing text at the end of each value (Glassdoor/Employee Est.)

SELECT Company, salaryestimate,
	SUBSTRING_INDEX(salaryestimate,'(',1) AS salarysubstring
FROM DATASCIENCEJOBS.STAGING_JOBS 
;

-- remove '$' and 'K' symbols

SELECT *,
	REPLACE(REPLACE(salarysubstring,'$',''),'K','') AS cleaned_salary
FROM (
	SELECT Company, salaryestimate,
	SUBSTRING_INDEX(salaryestimate,'(',1) AS salarysubstring
	FROM DATASCIENCEJOBS.STAGING_JOBS
) numeric_salary
	 
;

-- update table and drop old column

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
	ADD COLUMN cleaned_salary TEXT
;

-- have to use a self join since MySQL doesn't allow for table updates with subqueries/cte's on the 'set = ' line

WITH salary_cte AS (
	SELECT *,
	REPLACE(REPLACE(salarysubstring,'$',''),'K','') AS cleaned_salary
	FROM (
		SELECT Company, salaryestimate,
		SUBSTRING_INDEX(salaryestimate,'(',1) AS salarysubstring
		FROM DATASCIENCEJOBS.STAGING_JOBS
) numeric_salary
)
UPDATE DATASCIENCEJOBS.STAGING_JOBS 
JOIN salary_cte 
	ON DATASCIENCEJOBS.STAGING_JOBS.company = salary_cte.company
SET DATASCIENCEJOBS.STAGING_JOBS.cleaned_salary = salary_cte.cleaned_salary 
WHERE DATASCIENCEJOBS.STAGING_JOBS.CLEANED_SALARY IS NULL
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
DROP COLUMN salaryestimate
;


-- do the same to 'size' as done to 'salaryestimate'
-- get rid of 'to' and 'employees' and create numeric range

SELECT `size`, REPLACE(numeric_range, ' to ', '-') AS cleaned_size, job_id 
FROM (
	SELECT * , SUBSTRING_INDEX(`Size` , 'employees',1) AS numeric_range
	FROM DATASCIENCEJOBS.STAGING_JOBS 
) subquery
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD COLUMN cleaned_size TEXT NULL
;

WITH size_cte AS (
	SELECT job_id, `size`, REPLACE(numeric_range, ' to ', '-') AS cleaned_size
	FROM (
		SELECT *, SUBSTRING_INDEX(`Size` , 'employees',1) AS numeric_range
		FROM DATASCIENCEJOBS.STAGING_JOBS 
) subquery
)
UPDATE DATASCIENCEJOBS.STAGING_JOBS
JOIN size_cte
	ON DATASCIENCEJOBS.STAGING_JOBS.job_id = size_cte.job_id
SET DATASCIENCEJOBS.STAGING_JOBS.cleaned_size = size_cte.cleaned_size
WHERE DATASCIENCEJOBS.STAGING_JOBS.CLEANED_SIZE IS null
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
DROP COLUMN `size`
;


-- in the ownership column, remove  'company -'

SELECT ownership, SUBSTRING_INDEX(ownership, 'Company - ','-1')
FROM DATASCIENCEJOBS.STAGING_JOBS 
;

UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET OWNERSHIP = SUBSTRING_INDEX(ownership, 'Company - ','-1')
WHERE ownership IS NOT NULL 
;

-- in revenue column, drop the '(USD)' and hyphenate the range (remove 'to')

SELECT *, REPLACE(range_value, ' to $','-') AS cleaned_revenue_range
FROM (
	SELECT job_id, revenue, REPLACE(revenue, '(USD)','') AS range_value
	FROM DATASCIENCEJOBS.STAGING_JOBS 
) numeric_range
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD COLUMN cleaned_revenue_range TEXT NULL
;

WITH revenue_cte AS (
	SELECT *, REPLACE(range_value, ' to $','-') AS cleaned_revenue_range
	FROM (
		SELECT job_id, revenue, REPLACE(revenue, '(USD)','') AS range_value
		FROM DATASCIENCEJOBS.STAGING_JOBS 
	) numeric_range
) 
UPDATE DATASCIENCEJOBS.STAGING_JOBS 
JOIN revenue_cte 
	ON DATASCIENCEJOBS.STAGING_JOBS.job_id = revenue_cte.job_id
SET DATASCIENCEJOBS.STAGING_JOBS.cleaned_revenue_range = revenue_cte.cleaned_revenue_range
WHERE DATASCIENCEJOBS.STAGING_JOBS.cleaned_revenue_range IS NULL
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
DROP COLUMN revenue
;

-- for later EDA, want to conver the cleaned_revenue_range into numeric values (INT)
-- use "case...when" to convert million/billion to numerical value and find the minimum and maximum revenue values


ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD COLUMN min_revenue DECIMAL(18,2) NULL
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD COLUMN max_revenue DECIMAL(18,2) NULL
;

 /* Use "case...when" to identify when the revenue value contains a range '%-%', a single value and above '%+%', 'million', 'billion', and/or a combination of the four
  * Once these are identified, the substring_index() fxn removes the '$' symbol and captures the number that precedes the text (million/billion)
  * Next, the outputted values are converted to decimals using the cast() fxn as the original data type was text and we want a numerical data type
  * Lastly, this entire substring casted as a number is then multiplied by 1e6/1e9 
*/


SELECT
    cleaned_revenue_range,
    CASE 
       CASE 
        WHEN cleaned_revenue_range LIKE '%million%' AND cleaned_revenue_range LIKE '%-%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' AND cleaned_revenue_range LIKE '%-%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        WHEN cleaned_revenue_range LIKE '%million%' AND cleaned_revenue_range LIKE '%+%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' AND cleaned_revenue_range LIKE '%+%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        WHEN cleaned_revenue_range LIKE '%million%' THEN
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' THEN
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        ELSE NULL
    END AS min_revenue
FROM DATASCIENCEJOBS.STAGING_JOBS
;

UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET min_revenue = 
	CASE 
        WHEN cleaned_revenue_range LIKE '%million%' AND cleaned_revenue_range LIKE '%-%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' AND cleaned_revenue_range LIKE '%-%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        WHEN cleaned_revenue_range LIKE '%million%' AND cleaned_revenue_range LIKE '%+%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' AND cleaned_revenue_range LIKE '%+%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        WHEN cleaned_revenue_range LIKE '%million%' THEN
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' THEN
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        ELSE NULL
    END
 WHERE min_revenue IS NULL
 ;

-- do the same with max_revenue (uses 1 instead of -1 in cast to grab the second numerical value)
-- instead of capturing the number after the '$' like in min_revenue, we capture the number that follows the '-' indicating the second half of the range

UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET max_revenue =
	 CASE 
        WHEN cleaned_revenue_range LIKE '%billion%' AND cleaned_revenue_range LIKE '%-%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '-', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
         WHEN cleaned_revenue_range LIKE '%million%' AND cleaned_revenue_range LIKE '%-%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '-', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
       WHEN cleaned_revenue_range LIKE '%million%' AND cleaned_revenue_range LIKE '%+%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' AND cleaned_revenue_range LIKE '%+%' THEN 
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        WHEN cleaned_revenue_range LIKE '%million%' THEN
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' million', 1) AS DECIMAL(18,2)) * 1000000
        WHEN cleaned_revenue_range LIKE '%billion%' THEN
            CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(cleaned_revenue_range, '$', -1), ' billion', 1) AS DECIMAL(18,2)) * 1000000000
        ELSE NULL 
    END 
WHERE max_revenue IS NULL  
;



-- Rating is listed as integer but should show decimal. The correct decimal rating is incorrectly listed after the company name
-- Separate the rating into its own column and fix the company name to not include the rating value


SELECT company, REGEXP_SUBSTR(company, '[0-9]+(\.[0-9]+)') AS cleaned_rating
FROM DATASCIENCEJOBS.STAGING_JOBS 
-- regexp_substr fxn looks for and outputs a numerical value separated by a '.' and then the numerical value following the decimal point
-- '[0-9]' indicates any numerical value, '\.' indicates the period symbol, and '[0-9]+' indicates any numerical values following the '.'
;


ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS  
ADD cleaned_rating TEXT NULL
;


UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET CLEANED_RATING = REGEXP_SUBSTR(company, '[0-9]+(\.[0-9]+)')
WHERE cleaned_rating IS NULL 
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
DROP COLUMN rating
;

-- now to extract the company name we will use regexp_replace (this one is a bit complicated since pilcrow characters register on MySQL as a newline/return character)
/* 
 here we are searching for the pilcrow symbol (as represented by '[\r\n]' since \r = return and \n = newline).
 The '.*' captures everything that follows that newline/return
 and the '' indicates removing that substring (i.e., replacing it with nothing)
 */

SELECT company, REGEXP_REPLACE(company,'[\r\n].*','') AS company_name
FROM DATASCIENCEJOBS.STAGING_JOBS
;


ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS
ADD company_name TEXT NULL
;


UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET company_name = REGEXP_REPLACE(company,'[\r\n].*','')
WHERE company_name IS NULL
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
DROP COLUMN company
;



-- now that we've dealt with structural errors, we can add new columns that detail information from existing columns
-- starting with cleaned salary, we can identify the minimum, maximum, and average salary from the ranges provided


SELECT company_name, cleaned_salary,
	SUBSTRING_INDEX(cleaned_salary,'-',1) AS min_salary,
	SUBSTRING_INDEX(cleaned_salary,'-',-1) AS max_salary
FROM DATASCIENCEJOBS.STAGING_JOBS 
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD min_salary INT NULL
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS  
ADD max_salary INT NULL
;


UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET min_salary = SUBSTRING_INDEX(cleaned_salary,'-',1)
WHERE min_salary IS NULL 
;

UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET max_salary = SUBSTRING_INDEX(cleaned_salary,'-',-1)
WHERE max_salary IS NULL 
;

SELECT company_name, min_salary, max_salary,
	(min_salary + max_salary)/2 AS avg_salary
FROM DATASCIENCEJOBS.STAGING_JOBS 
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD avg_salary DECIMAL(10,1) NULL
;

UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET avg_salary = (min_salary + max_salary)/2 
WHERE avg_salary IS NULL 
;


-- add column to isolate the state that the job is located in
-- normally, would use substring_index() and the comma as a delimiter but for special cases where the original value is the full state name, use "case...when"
-- excluding remote and United States for now but could add additional "case...when" statements as needed

SELECT location, 
	CASE 
		WHEN location = 'Utah' THEN 'UT'
		WHEN location = 'California' THEN 'CA'
		WHEN location = 'New Jersey' THEN 'NJ'
	ELSE SUBSTRING_INDEX(location, ',', -1)
	END AS job_state
FROM DATASCIENCEJOBS.STAGING_JOBS 
;

ALTER TABLE DATASCIENCEJOBS.STAGING_JOBS 
ADD COLUMN job_state TEXT NULL
;

UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET job_state = 
	CASE 
		WHEN location = 'Utah' THEN 'UT'
		WHEN location = 'California' THEN 'CA'
		WHEN location = 'New Jersey' THEN 'NJ'
	ELSE SUBSTRING_INDEX(location, ',', -1)
	END
WHERE job_state IS NULL
;









-- 3. Resolve Null/missing values
-- for columns where the data type is numeric, I'll set missing/unknown values as null to make calculations easier
-- for columns with text, I will change missing/unknown values to 'N/A'


SELECT
	IF(founded = '-1', NULL, founded),
    IF(ownership = '-1', 'N/A', ownership),
    IF(industry = '-1', 'N/A', industry),
	IF(sector = '-1', 'N/A', sector),
    IF(competitors = '-1', 'N/A', competitors),
    IF(cleaned_size = '-1' OR cleaned_size = 'Unknown', 'N/A', cleaned_size),
	IF(cleaned_revenue_range = 'Unknown / Non-Applicable' OR cleaned_revenue_range = '-1', 'N/A', cleaned_revenue_range),
	IF(headquarter = '-1', 'N/A', headquarter)
FROM DATASCIENCEJOBS.STAGING_JOBS 
;


UPDATE DATASCIENCEJOBS.STAGING_JOBS 
SET founded = IF(founded = '-1', NULL, founded),
	ownership = IF(ownership = '-1', 'N/A', ownership),
	industry= IF(industry = '-1', 'N/A', industry),
	sector = IF(sector = '-1', 'N/A', sector),
	competitors = IF(competitors = '-1', 'N/A', competitors),
	cleaned_size = IF(cleaned_size = '-1' OR cleaned_size = 'Unknown', 'N/A', cleaned_size),
	cleaned_revenue_range =	IF(cleaned_revenue_range = 'Unknown / Non-Applicable' OR cleaned_revenue_range = '-1', 'N/A', cleaned_revenue_range),
	headquarter = IF(headquarter = '-1', 'N/A', headquarter)
WHERE 
	founded = '-1' OR
    ownership = '-1' OR
    industry = '-1' OR
    sector = '-1' OR
    competitors = '-1' OR
    cleaned_size = '-1' OR
    cleaned_size = 'Unknown' OR
    cleaned_revenue_range = 'Unknown / Non-Applicable' OR 
    cleaned_revenue_range = '-1' OR 
    headquarter = '-1'
;


SELECT *
FROM DATASCIENCEJOBS.STAGING_JOBS 
;






