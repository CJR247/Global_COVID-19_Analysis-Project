
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * FROM covid_deaths
WHERE continent IS NOT null
ORDER BY 3,4

-- Select Datat to start with
SELECT country, date, total_cases, new_cases, total_deaths, population
From covid_deaths
WHERE continent IS NOT null 
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT country,date, total_cases, total_deaths, ROUND((NULLIF(total_deaths,0)/NULLIF(total_cases,0)*100),2) AS deathpercentage 
FROM covid_deaths
WHERE (ROUND((NULLIF(total_deaths,0)/NULLIF(total_cases,0)*100),2) IS NOT null) 
AND (NOT total_deaths>total_cases) 
AND (country LIKE 'India%')
ORDER BY 1,2 DESC

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT country,date, total_cases, new_cases,total_deaths, population, (NULLIF(total_cases,0)/NULLIF(population,0)*100) AS  casepercentage FROM covid_deaths
WHERE (ROUND((NULLIF(total_deaths,0)/NULLIF(total_cases,0)*100),2) IS NOT null) AND (NOT total_deaths>total_cases) AND (country LIKE 'India%')
ORDER BY 6

-- Countries with Highest Infection Rate compared to Population

SELECT country,MAX(total_cases) AS HighestInfectionCount, population, MAX((NULLIF(total_cases,0)/NULLIF(population,0)*100)) AS  PercentPopulationInfected 
FROM covid_deaths
WHERE ROUND((NULLIF(total_cases,0)/NULLIF(population,0)*100),2) IS NOT null
GROUP BY 1,3
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT country,MAX(total_deaths) AS  deathcount , population FROM covid_deaths
WHERE continent IS NOT null AND population IS NOT null AND total_deaths IS NOT null
GROUP BY country,population
ORDER BY deathcount DESC


-- BREAKING THINGS DOWN BY CONTINENT

--total population of people died BY continent
SELECT continent,
MAX(total_deaths) AS  TotalDeathCount 
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--total population of people got covid BY continent
SELECT continent,
MAX(total_cases) AS  infection_percentage 
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY MAX(total_cases) DESC

-- GLOBAL NUMBER
SELECT
SUM(new_cases) AS global_total_cases,
SUM(new_deaths) AS global_total_deaths, 
(MAX(new_deaths)/MAX(new_cases))*100 AS DeathPercentage 
FROM covid_deaths
WHERE continent IS NOT null
--GROUP BY date

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT 
dea.continent,
dea.country, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.country,dea.date) AS rolling_count
FROM covid_vaccinations vac
JOIN covid_deaths dea
ON dea.country = vac.country AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
WITH POPvsVAC(continent, country, date, population,NEWvaccinations, rolling_count)
AS
(
SELECT 
dea.continent,
dea.country, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.country
,dea.date) AS rolling_count
FROM covid_vaccinations vac
JOIN covid_deaths dea
ON dea.country = vac.country AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3
)
SELECT *,(rolling_count/population)*100 FROM POPvsVAC

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMP TABLE PercentPopulationVaccinated(
continent VARCHAR(250),
country VARCHAR(250),
date date,
population BIGINT,
new_vaccinations NUMERIC,
rolling_count NUMERIC
)

INSERT INTO PercentPopulationVaccinated
SELECT 
dea.continent,
dea.country, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.country
,dea.date) AS rolling_count
FROM covid_vaccinations vac
JOIN covid_deaths dea
ON dea.country = vac.country AND dea.date = vac.date
--WHERE dea.continent IS NOT null
--ORDER BY 2,3

SELECT *, (rolling_count/population)*100
FROM PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
dea.continent,
dea.country, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.country ORDER BY dea.country
,dea.date) AS rolling_count
--(rolling_count/population)*100
FROM covid_vaccinations vac
JOIN covid_deaths dea
ON dea.country = vac.country AND dea.date = vac.date
--WHERE dea.continent IS NOT null
--ORDER BY 2,3
