The purpose of this project is to explore the job market for data science roles in the U.S. and identify any trends that may lend insight to prospective applicants, companies interested in hiring for such positions, etc. The focus is exploring possible relationships between geographical regions, industry, salary, and several other factors. 

## I. Data Cleaning

- Start by identifying, then removing duplicate job listings using a window function since each listing had a unique job ID.
- Then fix any structural errors and standardized the data (removing non-numerical values within a string, converting data types, separating values into new columns).
- Lastly, resolve any missing/null values and standardized the formatting ('N/A' or NULL)

## II. Exploratory Data Analysis

### Approach

Categorize each job listing into one of five categories (Analyst, Engineer, Scientist, Manager, Other) and use these identifiers as a variable in the EDA.

Take a look at factors that may impact salary (geographical location, revenue, industry, role type) as well as identify the most/least common listings by state, industry, role type, etc. Observe how company ratings vary across company size or industry.


### EDA Summary

- The most sought after position nationwide is a data scientist role.
- Small to mid-size (lower end) companies have higher ratings compared to mid-size (higher end) to large companies.
- Industrial manufacturing is the industry with the highest revenue, whereas advertising/marketing brings in the lowest revenue
- Iowa, Florida, and California are the states hiring the most for data analyst, engineer, and scientist roles, respectively.
- Average salaries for analysts, engineers, and scientists are highest in the consulting, tech, and R&D industries, respectively.


## Insights/Conclusions

These findings can help businesses determine demand and adjust their hiring strategies accordingly; Furthermore, they are able to assess where their hiring needs may be best supported and determine the competitive landscape if looking to expand to a new state. 

The data can also help to determine what stage of business certain companies/industries are in depending on what types of roles they are hiring for the most/least. For example, hiring more analysts may indicate focusing their efforts on optimization and performance improvements. Businesses/industries hiring more data engineers may be working toward scaling up operations and reinforcing their infrastructure to support larger datasets. Those looking to hire data scientists could point to goals of innovation and predictive modeling. Companies seeking managers may be at an organizational growth stage where they need more leadership to support larger teams.

From a hiring standpoint, companies at different organizational stages can determine what they need to focus on to attract/maintain top talent. For example, bigger corporations should continue to offer competitive salary packages, but also emphasize WLB or career development opportunities. On the other hand, smaller companies should market their flexible and favorable work environments where tight-knit teams have more potential for growth.

## III. Visualizations

All visualizations were made in Tableau Public and the interactive dashboard can be found [here](https://public.tableau.com/app/profile/samantha.chan2412/viz/Tableau_17394760713740/Dashboard1).


## Source Data

Uncleaned data was derived from [Kaggle](https://www.kaggle.com/datasets/rashikrahmanpritom/data-science-job-posting-on-glassdoor?select=Cleaned_DS_Jobs.csv).
