/* 
COVID-19 Exploratory Data Analysis

Skills Used: Joins, CTE's, Window functions, Aggregate functions

*/

-- Select Data that we are starting with

SELECT country, date_year, total_vaccinations, people_vaccinated, 
	people_fully_vaccinated, daily_vaccinations,
    people_vaccinated_per_hundred, people_fully_vaccinated_per_hundred
FROM country_vax
ORDER BY 1, 2
;

-- Total # people fully vaccinated vs. # all people vaccinated by country
-- Shows percentage of people fully vaccinated out of entire vaccinated population per country

SELECT country, MAX(people_fully_vaccinated), MAX(people_vaccinated),
	 ROUND(MAX(people_fully_vaccinated)/MAX(people_vaccinated)*100,2) AS FullyVaxPercentage
FROM country_vax
GROUP BY 1
-- ORDER BY 4 
-- to see which countries had the lowest over fully vaccinated %
;


-- Using window function to caluculate rolling sum of daily vaccinations per country

SELECT country, date_year, daily_vaccinations, 
	SUM(daily_vaccinations) OVER(PARTITION BY country ORDER BY country, date_year) AS RollingVaccinations
FROM country_vax
;


-- Total population of country
-- Using % of population fully vaccinated and # of people fully vaccinated to determine country population

SELECT country, MAX(people_fully_vaccinated),
   MAX(people_fully_vaccinated_per_hundred),
   ROUND((MAX(people_fully_vaccinated)*100)/ MAX(people_fully_vaccinated_per_hundred),0) AS Population
FROM country_vax
GROUP BY 1
;


-- Using CTE and Join to calculate rolling % of population that is fully vaccinated

WITH PopData AS (

SELECT country, MAX(people_fully_vaccinated),
   MAX(people_fully_vaccinated_per_hundred),
   ROUND((MAX(people_fully_vaccinated)*100)/ MAX(people_fully_vaccinated_per_hundred),0) AS Population
FROM country_vax
GROUP BY 1
)

SELECT t1.country, t1.date_year, t1.people_fully_vaccinated, t2.Population, 
	ROUND((t1.people_fully_vaccinated/t2.Population)*100,2) AS RollingPopulation
FROM country_vax AS t1
JOIN PopData AS t2
	ON t1.country = t2.country
ORDER BY 1,2
;

-- Using a window function to determine when countries administered their first vaccination(s)

WITH firstvaxdata AS (

SELECT country, date_year, people_vaccinated,
	ROW_NUMBER() OVER (PARTITION BY country ORDER BY people_vaccinated) AS rank_num
FROM country_vax
WHERE people_vaccinated >0
)

SELECT country, date_year, people_vaccinated
FROM firstvaxdata
WHERE rank_num = 1
ORDER BY 2
;

-- View overall popularity of each vaccine

SELECT vaccine, SUM(total_vaccinations) AS total_vaccines
FROM manufacturer
GROUP BY 1
ORDER BY 2
;


-- Using window function and CTE to rank which vaccines were most/least popular by country

WITH vax_data AS (

SELECT location, vaccine, SUM(total_vaccinations) AS totalvaxcount
FROM manufacturer
GROUP BY 1,2
ORDER BY 1,2
)

SELECT location, vaccine, totalvaxcount, 
	DENSE_RANK() OVER (PARTITION BY location ORDER BY totalvaxcount DESC) AS rank_num
FROM vax_data
;

-- Rolling sum of vaccinations per brand per country 

SELECT location, date, vaccine, 
	SUM(total_vaccinations) OVER (PARTITION BY location, vaccine ORDER BY location, date, vaccine) AS RollingVax
FROM manufacturer
;

