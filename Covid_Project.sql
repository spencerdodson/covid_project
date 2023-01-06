  -- EXPLORE DATASETS
  --- understand table schemas, and data variables/records

SELECT
  TABLE_NAME,
  COLUMN_NAME,
  ORDINAL_POSITION,
  IS_NULLABLE,
  DATA_TYPE
FROM
  `portfolio-projects-2022.covid_project.INFORMATION_SCHEMA.COLUMNS`
ORDER BY
  TABLE_NAME,
  ORDINAL_POSITION;

SELECT
  location,
  date,
  new_cases,
  total_cases,
  total_deaths
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
ORDER BY
  location,
  date;


  -- DATA ANALYSIS
  -- Total Cases vs Total Deaths
  --- perecentage of cases that ended in death

SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 AS death_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
ORDER BY
  location,
  date;
  
  --- location specific data

SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 AS death_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  location LIKE "%tates"
ORDER BY
  location,
  date;

SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 AS death_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  location = "United States"
  OR location = "South Korea"
ORDER BY
  date;
  
  
  -- Total Cases vs Population
  --- percentage of the population that has gotten COVID

SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 AS case_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
ORDER BY
  location,
  date;
  
  
  -- Infection Rate
  --- top countries with highest infection rate per population

SELECT
  location,
  population,
  MAX(total_cases) AS max_infection_count,
  MAX((total_cases/population))*100 AS infection_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
GROUP BY
  location,
  population
ORDER BY
  infection_percent DESC
  
  --- top 20 countries worldwide (add limit)

SELECT
  location,
  population,
  MAX(total_cases) AS max_infection_count,
  MAX((total_cases/population))*100 AS infection_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
GROUP BY
  location,
  population
ORDER BY
  infection_percent DESC
LIMIT
  20;
 
  --- top 5 countries in asia
SELECT
  location,
  population,
  MAX(total_cases) AS max_infection_count,
  MAX((total_cases/population))*100 AS infection_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent = "Asia"
GROUP BY
  location,
  population
ORDER BY
  infection_percent DESC
LIMIT
  5;
  
  --- top 5 countries in europe
SELECT
  location,
  population,
  MAX(total_cases) AS max_infection_count,
  MAX((total_cases/population))*100 AS infection_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent = "Europe"
GROUP BY
  location,
  population
ORDER BY
  infection_percent DESC
LIMIT
  5;
  
  
  -- Highest Death Count per Population
  --- countries with the highest covid related deaths per population
SELECT
  location,
  MAX(total_deaths) AS max_death_count
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
GROUP BY
  location
ORDER BY
  max_death_count DESC;
  
  --- top death count (without continent)

SELECT
  location,
  population,
  MAX(total_deaths) AS max_death_count
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent IS NOT NULL
GROUP BY
  location,
  population
ORDER BY
  max_death_count DESC;
  
  -- top death percent (without continent data) --

SELECT
  location,
  MAX(total_deaths) AS max_death_count
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent IS NOT NULL
GROUP BY
  location
ORDER BY
  max_death_count DESC;
  
  -- CONTINENT ANALYSIS --
  
  -- Highest Death Count per Population
  --- continent with the highest covid related deaths per population
  
  --- incorrect numbers

SELECT
  continent,
  MAX(total_deaths) AS max_death_count
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent IS NOT NULL
GROUP BY
  continent
ORDER BY
  max_death_count DESC;
 
  --- why?

SELECT
  DISTINCT continent,
  location
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
LIMIT
  100;
  
  --- more accurate numbers, after noticing issue in dataset where continent data that IS NULL
  --- has location data that is actually the continent, and not the country
  --- rerun query where contintent IS NULL

SELECT
  location,
  MAX(total_deaths) AS max_death_count
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent IS NULL
GROUP BY
  location
ORDER BY
  max_death_count DESC;
  
  -- GLOBAL ANALYSIS --
  
  -- Worldwide total cases, total deaths and death percentage
  --- have to set continent as IS NOT NULL or get error that its not divisible by zero

SELECT
  date,
  SUM(new_cases) AS total_cases,
  SUM(new_deaths) AS total_deaths,
  SUM(new_deaths)/SUM(new_cases)*100 AS death_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent IS NOT NULL
GROUP BY
  date
ORDER BY
  date;
  
  -- COVID VACCINATION --
  
  -- Table Joins
  --- join data from covid death and covid vax tables together

SELECT
  *
FROM
  `portfolio-projects-2022.covid_project.covid_deaths` AS cd
JOIN
  `portfolio-projects-2022.covid_project.covid_vax` AS cv
ON
  cd.location = cv.location
  AND cd.date = cv.date;
  
  -- Total Population vs Vaccinations
  --- Using CTE (common table expression) method

WITH
  pops_vax AS (
  SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_ppl_vaxxed,
  FROM
    `portfolio-projects-2022.covid_project.covid_deaths` AS cd
  JOIN
    `portfolio-projects-2022.covid_project.covid_vax` AS cv
  ON
    cd.location = cv.location
    AND cd.date = cv.date
  WHERE
    cd.continent IS NOT NULL )
SELECT
  *,
  (rolling_ppl_vaxxed/population)*100 AS perc_ppl_vaxxed
FROM
  pops_vax;
  
  --- Using TEMP Table method

DROP TABLE IF EXISTS
  perc_pop_vaxxed
  --- use if needing to make a change
  CREATE TEMP TABLE perc_pop_vaxxed ( continent string,
    location string,
    date datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_ppl_vaxxed numeric );
INSERT
  perc_pop_vaxxed
SELECT
  cd.continent,
  cd.location,
  cd.date,
  cd.population,
  cv.new_vaccinations,
  SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_ppl_vaxxed
FROM
  `portfolio-projects-2022.covid_project.covid_deaths` AS cd
JOIN
  `portfolio-projects-2022.covid_project.covid_vax` AS cv
ON
  cd.location = cv.location
  AND cd.date = cv.date
WHERE
  cd.continent IS NOT NULL;
SELECT
  *,
  (rolling_ppl_vaxxed/population)*100 AS perc_pop_vaxxed
FROM
  perc_pop_vaxxed
ORDER BY
  date;
  
  -- CREATE VIEWS FOR DATA VISUALIZATIONS
  
  -- Death Percent, continent
CREATE VIEW
  `portfolio-projects-2022.covid_project.death_percent_continent` AS
SELECT
  date,
  SUM(new_cases) AS total_case,
  SUM(new_deaths) AS total_deaths,
  SUM(new_deaths)/SUM(new_cases)*100 AS death_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
WHERE
  continent IS NOT NULL
GROUP BY
  date
ORDER BY
  date;
  
  -- Population and Vaccines
CREATE VIEW
  `portfolio-projects-2022.covid_project.pops_vax` AS
WITH
  pops_vax AS (
  SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_ppl_vaxxed,
  FROM
    `portfolio-projects-2022.covid_project.covid_deaths` AS cd
  JOIN
    `portfolio-projects-2022.covid_project.covid_vax` AS cv
  ON
    cd.location = cv.location
    AND cd.date = cv.date
  WHERE
    cd.continent IS NOT NULL )
SELECT
  *,
  (rolling_ppl_vaxxed/population)*100 AS perc_ppl_vaxxed
FROM
  pops_vax;

  -- Infection Rate
CREATE VIEW
  `portfolio-projects-2022.covid_project.infection_rate` AS
SELECT
  location,
  population,
  MAX(total_cases) AS max_infection_count,
  MAX((total_cases/population))*100 AS infection_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
GROUP BY
  location,
  population
ORDER BY
  infection_percent DESC;

  -- Max death, country
CREATE VIEW
  `portfolio-projects-2022.covid_project.max_death_country` AS
SELECT
  location,
  MAX(total_deaths) AS max_death_count
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
GROUP BY
  location
ORDER BY
  max_death_count DESC;

  -- Death Percent, country
CREATE VIEW
  `portfolio-projects-2022.covid_project.death_percent_country` AS
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 AS death_percent
FROM
  `portfolio-projects-2022.covid_project.covid_deaths`
ORDER BY
  location,
  date;

  -- Test view (preview)

SELECT
  *
FROM
  `portfolio-projects-2022.covid_project.death_percent_continent`;
  
  --- PROJECT FINISHED!!!!
