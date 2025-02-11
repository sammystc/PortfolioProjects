

-- *Exploratory Data Analysis on Data Scientist Jobs*



-- Select data we want to start with

SELECT *
FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
-- ORDER BY job_id
;



-- 1. Which job titles are more/less commonly posted?
 -- Break up job categories into 4 main categories (data analyst, scientist, engineer, manager, other)
 -- count how many listings per category

SELECT
	CASE 
		WHEN jobtitle LIKE '%analyst%' THEN 'Analyst'
		WHEN jobtitle LIKE '%scientist%' THEN 'Scientist'
		WHEN jobtitle LIKE '%engineer%' THEN 'Engineer'
		WHEN jobtitle LIKE '%manager%' THEN 'Manager'
		ELSE 'Other' 
	END AS job_category,
	COUNT(*) AS total_jobs
FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
GROUP BY job_category
;
	/* INSIGHTS: 
		-helps businesses determine which jobs are in highest demand and adjusting hiring strategies accordingly
	 */



-- 2. Which industries are the most/least popular by state?

	-- first, clean data by removing trailing space before each state and standardizing 'Texas' to 'TX'
	UPDATE DATASCIENCEJOBS.CLEANED_DS_JOBS
	SET job_state = LTRIM(job_state)
	WHERE job_state IS NOT NULL 
	;
	
	UPDATE DATASCIENCEJOBS.CLEANED_DS_JOBS 
	SET job_state = 'TX'
	WHERE job_state = 'Texas'
	;

	-- next, look at the count of job listings by industry for each state
	
SELECT job_state, industry, COUNT(industry)
FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
GROUP BY 1,2
ORDER BY 1
;

	-- use CTE to assign rank to industries according to the most listings

WITH industry_cte AS (
	SELECT job_state, industry, COUNT(industry) AS industry_count,
			DENSE_RANK () OVER (PARTITION BY job_state ORDER BY COUNT(*) DESC) AS rank_num 
			-- dense rank in case there are industries with the same # of listings
	FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
	WHERE industry <> 'N/A'
		-- exclude any listings without specified industry
	GROUP BY 1,2
	ORDER BY 1
)
SELECT job_state, industry, rank_num
FROM industry_cte
-- WHERE RANK_NUM = 1 
 	-- to determine most popular industry(s) by state
;


	/* INSIGHTS:
	 	-businesses looking to expand into new states can determine where their hiring needs may be best supported 
	 	
	 	-alternatively, if there are more job postings concentrated in certain areas, there may be more competition for talent; more difficult for recruiters
	 	
	 	-assess which industries are struggling to attract workers (lower job count) regionally
	 	
	 	-if historical data was available:
	 		-determine how industry demands shift over time
	 		-if there is an influx of job postings within an industry, it could indicate growth or an economic shift
	 */

-- 3. Which job category is most popular by state?

WITH category_count AS (
	SELECT job_state, 
		CASE 
			WHEN jobtitle LIKE '%analyst%' THEN 'Analyst'
			WHEN jobtitle LIKE '%scientist%' THEN 'Scientist'
			WHEN jobtitle LIKE '%engineer%' THEN 'Engineer'
			WHEN jobtitle LIKE '%manager%' THEN 'Manager'
			ELSE 'Other' 
		END AS job_category,
		COUNT(*) AS total_jobs,
		DENSE_RANK() OVER (PARTITION BY job_state ORDER BY COUNT(*) DESC) AS rank_order
	FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
	GROUP BY 1, 2
) 
SELECT job_state, job_category
FROM category_count 
WHERE rank_order = 1 
	-- remove this line to see how each category ranks
;




-- 4. Combine above queries to see which job categories are most/least in demand respective to the most popular industry(s) by state

WITH category_count AS (
	SELECT job_state,
		CASE 
			WHEN jobtitle LIKE '%analyst%' THEN 'Analyst'
			WHEN jobtitle LIKE '%scientist%' THEN 'Scientist'
			WHEN jobtitle LIKE '%engineer%' THEN 'Engineer'
			WHEN jobtitle LIKE '%manager%' THEN 'Manager'
			ELSE 'Other' 
		END AS job_category,
		COUNT(*) AS total_jobs,
		DENSE_RANK() OVER (PARTITION BY job_state ORDER BY COUNT(*) DESC) AS category_rank
	FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
	GROUP BY 1, 2
), 
	IndustryCounts AS (
	SELECT job_state, industry, 
		COUNT(*) AS industry_count,
			DENSE_RANK () OVER (PARTITION BY job_state ORDER BY COUNT(*) DESC) AS rank_num 
	FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
	WHERE industry <> 'N/A'
	GROUP BY 1,2
)
SELECT cc.job_state, cc.job_category, cc.category_rank ,  ic.industry
FROM category_count AS cc
JOIN IndustryCounts AS ic
	ON cc.job_state = ic.job_state
WHERE ic.rank_num = 1
ORDER BY cc.job_state
;

	
	/* INSIGHTS:
	 * looking at which job categories are more/less in demand can lend insight into the business stage of these industries:
	 
	 	-for example, in states like Iowa, where analysts are the most in demand, the data may suggest that the lending industry is focusing on
	 	improving their current performance and optimizing operations.
	 	
	 	-for states that seek data engineers, such as Florida, investment banking/asset management companies might be looking to scale up their 
	 	operations and grow their infrastructure to handle larger datasets more efficiently.
	 	
	 	-many states are hiring data scientists, especially tech hubs such as California, and this could indicate businesses that are working 
	 	toward innovative and cutting-edge technology where they may leverage more statistical and machine learning tools to create
	 	predictive models.
	 	
	 	-lastly, companies that may be hiring more managers could be in an organizationl growth stage where they need more people to manage large
	 	teams and align projects with business objectives.
	 */





-- 5. What is the average salary by job category?

-- create a new staging table including job cateogries to omit the use of CTE's in each query

CREATE TABLE datasciencejobs.job_category (
	job_id INTEGER NULL,
	jobtitle VARCHAR(64) NULL,
	jobdescription LONGTEXT NULL,
	location VARCHAR(50) NULL,
	headquarter VARCHAR(50) NULL,
	founded INTEGER NULL,
	ownership VARCHAR(50) NULL,
	industry VARCHAR(50) NULL,
	sector VARCHAR(50) NULL,
	competitors TEXT NULL,
	cleaned_salary VARCHAR(50) NULL,
	cleaned_rating DECIMAL(10,2) NULL,
	company_name VARCHAR(50) NULL,
	min_salary DECIMAL(10,2) NULL,
	max_salary DECIMAL(10,2) NULL,
	avg_salary DECIMAL(10,2) NULL,
	cleaned_size VARCHAR(50) NULL,
	cleaned_revenue_range VARCHAR(50) NULL,
	min_revenue DECIMAL(18,2) NULL,
	max_revenue DECIMAL(18,2) NULL,
	job_state VARCHAR(50) NULL,
	category TEXT NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci
;

INSERT INTO DATASCIENCEJOBS.JOB_CATEGORY 
SELECT *, 
	CASE 
		WHEN jobtitle LIKE '%analyst%' THEN 'Analyst'
		WHEN jobtitle LIKE '%scientist%' THEN 'Scientist'
		WHEN jobtitle LIKE '%engineer%' THEN 'Engineer'
		WHEN jobtitle LIKE '%manager%' THEN 'Manager'
		ELSE 'Other' 
	END AS category
FROM DATASCIENCEJOBS.CLEANED_DS_JOBS 
;


SELECT category, 
	ROUND(AVG(avg_salary),0) AS avg_salary_category
FROM DATASCIENCEJOBS.JOB_CATEGORY 
-- WHERE job_state = 'CA'
GROUP BY 1
;

-- average salary by category values may be less accurate for categories with fewer job listings (e.g., managers, n=4) 
-- more data scientist listings with a wider salary range (entry level to senior)




-- 6. Which industry on average pays the most/least by job category?
	-- NOTE: there are fewer listings for certain job categories, so the calculated salary may have reduced accuracy.
		-- there are only 5 total listings for manager positions, each from a different industry; will omit this data 
		-- salary also can vary drastically geographically
	


SELECT  industry, ROUND(AVG(avg_salary),0) AS avg_ind_salary
FROM DATASCIENCEJOBS.JOB_CATEGORY 
WHERE category = 'Analyst'
AND industry <> 'N/A'
GROUP BY 1
HAVING COUNT(industry) >1
  -- very few analyst listings, so filtering out industries with n=1 makes avg salary slightly more accurate
ORDER BY AVG(avg_salary) DESC 
;


SELECT  industry, ROUND(AVG(avg_salary),0) AS avg_ind_salary
FROM DATASCIENCEJOBS.JOB_CATEGORY 
WHERE category = 'Scientist'
AND industry <> 'N/A'
GROUP BY 1
HAVING COUNT(industry) >2
  -- many more data scientist listings so can increase n>2
ORDER BY AVG(avg_salary) DESC 
;

SELECT  industry, ROUND(AVG(avg_salary),0) AS avg_ind_salary
FROM DATASCIENCEJOBS.JOB_CATEGORY 
WHERE category = 'Engineer'
AND industry <> 'N/A'
GROUP BY 1
HAVING COUNT(industry) >1
  -- fewer listings for data engineers than data scientists
ORDER BY AVG(avg_salary) DESC 
;



/* INSIGHTS:
 
 	-Consulting and Healthcare are the highest paying industries for analysts, while Advertising/Marketing is the lowest paying.
 	-R&D pays data scientists the most, whereas energy and investment banking pay the lowest
 	-Data Engineers are paid the highest in the tech (computer hardware/software) industry, but paid the lowest in biotech
 	
 	
 	*This data can highlight market dynamics within certain industries. For example, industries, such as tech and consulting, that pay higher salaries for DS jobs
 	may value and make more use of data science-related skills compared to low-paying industries like biotech or energy that may not rely on those skills as much.
 	
 	*From a hiring standpoint, consulting, healthcare, and tech companies may need to offer more competitive salary packages or additional benefits to attract top talent 
 	and stand out. On the other side, advertising agencies and biotech may benefit from allocating more resources toward data science and investing in bulding that infrastructure.

 */




-- 7. Average rating by industries

SELECT industry, ROUND(AVG(cleaned_rating),1) AS avg_ind_rating
FROM DATASCIENCEJOBS.JOB_CATEGORY 
WHERE industry <> 'N/A'
GROUP BY 1
HAVING COUNT(industry) >2
ORDER BY 2 DESC 
;


-- 8. Average rating by company size
-- error when importing data: cleaned size converted 1-50 to Jan-50

UPDATE DATASCIENCEJOBS.JOB_CATEGORY
SET cleaned_size = '1-50'
WHERE cleaned_size = 'Jan-50'
;


SELECT cleaned_size, ROUND(AVG(cleaned_rating),1) AS avg_compsize_rating
FROM DATASCIENCEJOBS.JOB_CATEGORY 
WHERE cleaned_size <> 'N/A'
GROUP BY 1
ORDER BY 2 DESC 
;



/* INSIGHTS: 
 	-looking at rating by company size can lend insight into work environment and areas for improvement:
 	
 		Small to mid-size companies(<500) rate higher than mid-size(>500) to large companies. This could suggest that smaller companies 
 		offer more flexible and close-knit team environments that allow for growth while bigger companies may not have as favorable of a
 		work culture. They may experience more challenges with bureaucracy, less flexibility, and less room for advancement. 
 		However, small companies can be high-risk and may have smaller budgets while big companies have more stability/structure and competitive salary packages.
 		
 		When it comes to hiring, small companies may attract talent from emphasizing positive work culture, perks/benefits, and rapid growth whereas 
 		larger companies may want to focus on offering high salaries, more career development opportunities, and implementing WLB policies.
  
*/



-- 9. How does revenue vary by industry?

SELECT industry, ROUND(AVG(max_revenue),0) AS avg_max_rev
FROM DATASCIENCEJOBS.JOB_CATEGORY 
WHERE industry <> 'N/A'
AND max_revenue IS NOT NULL 
GROUP BY 1
HAVING COUNT(industry) > 2
ORDER BY 2 DESC 
;

-- Advertising & marketing agencies have the lowest average revenue. This makes sense as they are also one of the industries on the lower-end of the pay scale.




-- 10. Which state is hiring the most?

SELECT job_state, category, COUNT(*) AS job_count
FROM DATASCIENCEJOBS.JOB_CATEGORY 
-- WHERE category = 'analyst'
GROUP BY 1,2
ORDER BY 1
;










