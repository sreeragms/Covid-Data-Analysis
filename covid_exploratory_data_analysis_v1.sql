
use CovidProject

--select first few rows
select top 20 * 
from CovidProject..covid_deaths
order by 3,4

select top 20 * 
from CovidProject..covid_vaccinations
order by 3,4

-- checking how many countries we have data of 
select distinct(location) from covid_deaths
order by 1
-- 244 locations

--Checking the count
select count(distinct(location)) from covid_deaths
--244 distinct locations

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_to_case_percent
from covid_deaths
order by 1,2

-- total deaths and total cases
--testsave


select location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as death_to_case_percent
from covid_deaths
--where location = 'India'
order by date 


--select date, total_deaths ,death_to_case_percent
--from cte where total_deaths in (select MAX(total_deaths) from cte)


--selecting top 25 locations with most cases
select top 25 location , MAX(total_cases) as total_cases
from covid_deaths
group by location -- cannot use literals in group by as in order by
order by 2 desc


select location, max(total_deaths) as total
from covid_deaths
group by location
order by 2 desc

-- A datatype issue with the previous query so casting it as int 

select location, max(cast(total_deaths as bigint)) as total_deaths
from covid_deaths
where continent is not null
group by location
order by 2 desc


--Grouping by continent

select continent, max(cast(total_deaths as bigint)) as total_deaths
from covid_deaths
where continent is not null
group by continent
order by 2 desc


--Group by not continent
select location, max(cast(total_deaths as bigint)) as total_deaths
from covid_deaths
where continent is null
group by location
order by 2 desc

--Most deaths in a day
select max(cast(new_deaths as bigint)) 
from covid_deaths
where continent is null


-- Selecting location and date with most deaths using a subquery->Highest death spike
select location, date, new_deaths
from covid_deaths
where new_deaths in(select max(cast(new_deaths as bigint)) 
from covid_deaths
where continent is not null)
--India 18 May 2021 4529(valid as per few news reports)


 select * from covid_deaths
 where location = 'India'


 --Total death percentage by date from all the locations
 SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as bigint)) as total_deaths, SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100 as death_percentage
 FROM covid_deaths
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY 1,2

 -- Trying to get the date with maximum death percentage from the previous query using a CTE 

 WITH cte as(
  SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as bigint)) as total_deaths, SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100 as death_percentage
 FROM covid_deaths
 WHERE continent IS NOT NULL
 GROUP BY date
 )
 SELECT * FROM cte
 WHERE death_percentage IN (SELECT MAX(death_percentage) FROM cte)

 --This could be helpful if more than one date had the same death percentage,
 --Otherwise just order by death% desc and limit 1 or get top 1 value
 --Trying that case with top 10 dates with most death%
  SELECT TOP 10 date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as bigint)) as total_deaths, SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100 as death_percentage
 FROM covid_deaths
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY 4 desc
 

  --Total death percentage by date from all the locations
 SELECT  SUM(new_cases) as total_cases, SUM(CAST(new_deaths as bigint)) as total_deaths, SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100 as death_percentage
 FROM covid_deaths
 WHERE continent IS NOT NULL
 ORDER BY 1,2
 --Matches with data on google


 --JOINING COVID deaths and COVID vaccinations tables
 --Finding new vaccinations in India on each day

 SELECT d.continent, d.location, d.date, CAST(v.population AS bigint) AS total_population, CAST(v.new_vaccinations AS bigint) AS new_vaccinations
 FROM covid_deaths d
 JOIN covid_vaccinations v 
 ON d.location = v.location 
 AND d.date = v.date
 WHERE d.continent IS NOT NULL AND d.location = 'India'
 ORDER BY 1,2,3

 --Results tell that Vaccination started on Jan 16,2021 - verified correct

 --Getting top 10 new vaccinations from previous query

 SELECT TOP 10 d.continent, d.location, d.date, CAST(v.population AS bigint) AS total_population, CAST(v.new_vaccinations AS bigint) AS new_vaccinations
 FROM covid_deaths d
 JOIN covid_vaccinations v 
 ON d.location = v.location 
 AND d.date = v.date
 WHERE d.continent IS NOT NULL AND d.location = 'India'
 ORDER BY new_vaccinations DESC 

 --Not able to verify 25,000,000 as per news report but  18,627,269 from data

 -- Taking Cumulative Sum or Running Total of the new vaccinations and creating a new column for it by partitioning over the location and ordering it by location and date for showing the increase as the date moves forward.

  SELECT d.continent, d.location, d.date, CAST(v.population AS bigint) AS total_population, CAST(v.new_vaccinations AS bigint) AS new_vaccinations, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS new_vacc_cumulative
 FROM covid_deaths d
 JOIN covid_vaccinations v 
 ON d.location = v.location 
 AND d.date = v.date
 WHERE d.continent IS NOT NULL
 ORDER BY 1,2,3


 -- Running the above query for India

  SELECT d.continent, d.location, d.date, CAST(v.population AS bigint) AS total_population, CAST(v.new_vaccinations AS bigint) AS new_vaccinations, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS new_vacc_cumulative
 FROM covid_deaths d
 JOIN covid_vaccinations v 
 ON d.location = v.location 
 AND d.date = v.date
 WHERE d.continent IS NOT NULL AND d.location = 'India'
 ORDER BY 1,2,3


 --Using a CTE for using a newly created column 'new_vacc_cumulative' from the previous query

 --Use the column names gives in the below brackets while using the CTE not the name inside it
 WITH vaccVsPopulation (Continent, Location, Date,Total_Population, New_Vaccinations, New_Vaccinations_Cumulative) AS
 (
	 SELECT d.continent, d.location, d.date, CAST(v.population AS bigint) AS total_population, CAST(v.new_vaccinations AS bigint) AS new_vaccinations, SUM(CONVERT(bigint,new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS new_vacc_cumulative
	 FROM covid_deaths d
	 JOIN covid_vaccinations v 
	 ON d.location = v.location 
	 AND d.date = v.date
	 WHERE d.continent IS NOT NULL
	 --ORDER BY 1,2,3
 )
 SELECT *, (New_Vaccinations_Cumulative/Total_Population)*100 AS Cumulative_Percent
 FROM vaccVsPopulation
 
 DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3
SELECT * ,(RollingPeopleVaccinated/Population)*100 AS VaccinatedPerPopulationPercent
FROM #PercentPopulationVaccinated

--View For visualizing later
Create View PercentPopulationVaccinatedView 
AS 
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


SELECT * FROM PercentPopulationVaccinatedView
ORDER BY location,date