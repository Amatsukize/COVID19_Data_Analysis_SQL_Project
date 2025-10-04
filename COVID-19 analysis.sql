
select * from [dbo].[CovidDeaths];

select * from [dbo].[CovidVaccinations];

--fix the type field date to be data type
alter table dbo.CovidDeaths
  alter column [date] date; 
  
--fix the type field date to be data type
alter table [dbo].[CovidVaccinations]
  alter column [date] date;  

--fix the empty string to be null val which field is continent.
  UPDATE dbo.CovidDeaths
SET continent = NULL
WHERE LTRIM(RTRIM(continent)) = '';



select location,date,total_cases,new_cases,total_deaths,population 
from [dbo].[CovidDeaths] order by 1,2;

--Daily COVID-19 Cases, Deaths, and Death Rate (%)
select 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    (cast(total_deaths as float) / nullif(cast(total_cases as float),0)) * 100 as death_rate
from [dbo].[CovidDeaths]
where location like '%states%'
order by date,location;


-- what the percentage of peopole get affected by covid?
select 
    location,
    date,
	population,
    total_cases,
    (cast(total_cases as float) / nullif(cast(population as float),0)) * 100 as affect_rate
from [dbo].[CovidDeaths]
where location like '%states%'
order by date,location;



-- what country has the most  affect rate?
select 
    location,
	population,
    MAX(total_cases) as HighestCaseCount,
    MAX((cast(total_cases as float) / nullif(cast(population as float),0))) * 100 as PercentPopulationAffected
from [dbo].[CovidDeaths]
group by location,population
order by PercentPopulationAffected desc;


--Showing Highest deathcount per Population
select 
    location,
    MAX(cast(total_deaths as int)) as TotalDeathCount
from [dbo].[CovidDeaths]
Where continent is not null
group by location
order by TotalDeathCount desc;


--Showing Highest deathcount group by continent
select 
    continent,
    MAX(cast(total_deaths as int)) as TotalDeathCount
from [dbo].[CovidDeaths]
Where continent is not null
group by continent
order by TotalDeathCount desc;




--Showing date time by time death percentage
SELECT
    SUM(TRY_CONVERT(int, total_deaths)) AS TotalDeathCount,
    SUM(TRY_CONVERT(int, new_cases))    AS TotalCase,
    (
      SUM(TRY_CONVERT(float, total_deaths))
      / NULLIF(SUM(TRY_CONVERT(float, total_cases)), 0)
    ) * 100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;




--Percentage of population which get vaccianted
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(TRY_CONVERT(bigint, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM [dbo].[CovidDeaths] dea
    JOIN [dbo].[CovidVaccinations] vac
      ON dea.location = vac.location 
     AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (CAST(RollingPeopleVaccinated AS float) / NULLIF(CAST(Population AS float),0)) * 100 AS PercentVaccinated
FROM PopvsVac
ORDER BY Location, Date;



-- temp table
-- create temp table to match the schema
DROP TABLE IF EXISTS #PercentagePopulationVaccinated; --when want to delete the table
CREATE TABLE #PercentagePopulationVaccinated (
    Continent               nvarchar(100) NULL,
    Location                nvarchar(200) NOT NULL,
    Date                    date          NOT NULL,
    Population              float         NULL,
    New_Vaccinations        float         NULL,
    RollingPeopleVaccinated bigint        NULL,
    PercentVaccinated       float         NULL
);

-- 2) ประกาศ CTE แล้วค่อย INSERT
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent,
        dea.location,
        TRY_CONVERT(date, dea.date, 101) AS date,   -
        TRY_CONVERT(float, dea.population)          AS population,
        TRY_CONVERT(float, vac.new_vaccinations)    AS new_vaccinations,
        SUM(TRY_CONVERT(bigint, vac.new_vaccinations))
            OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(date, dea.date, 101))
            AS RollingPeopleVaccinated
    FROM dbo.CovidDeaths dea
    JOIN dbo.CovidVaccinations vac
      ON dea.location = vac.location
     AND dea.date     = vac.date
    WHERE NULLIF(LTRIM(RTRIM(dea.continent)),'') IS NOT NULL
)
INSERT INTO #PercentagePopulationVaccinated
(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated, PercentVaccinated)
SELECT
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    RollingPeopleVaccinated,
    (CAST(RollingPeopleVaccinated AS float) / NULLIF(CAST(Population AS float),0)) * 100
FROM PopvsVac;




--create view for visualization

CREATE VIEW dbo.vw_PercentagePopulationVaccinated
AS
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(TRY_CONVERT(bigint, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM dbo.CovidDeaths AS dea
    JOIN dbo.CovidVaccinations AS vac
      ON dea.location = vac.location 
     AND dea.date     = vac.date
    WHERE NULLIF(LTRIM(RTRIM(dea.continent)), '') IS NOT NULL
)
SELECT
    Continent,
    Location,
    TRY_CONVERT(date, Date, 101) AS ReportDate,
    Population,
    TRY_CONVERT(float, New_Vaccinations) AS New_Vaccinations,
    RollingPeopleVaccinated,
    (CAST(RollingPeopleVaccinated AS float) / NULLIF(CAST(Population AS float),0)) * 100 AS PercentVaccinated
FROM PopvsVac;






--view the table PercentagePopulationVaccinated
select * from #PercentagePopulationVaccinated;
