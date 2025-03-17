create nonclustered index idx_CovidDeaths on [dbo].['CovidDeaths']
([location],date)

create nonclustered index idx_CovidVaccinations on [dbo].['CovidVaccinations']
([location],date)

select 
    *
from 
    dbo.[CovidDeaths]
order by 3,4

select 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
from 
    dbo.[CovidDeaths]
order by 
    location,
    date

--looking at total cases vs total deaths and fully_vaxed vs population

select 
    location, 
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 as death_rate,
    population,
    people_fully_vaccinated, 
    (people_fully_vaccinated/population)*100 as f_vaccination_rate
from 
    dbo.['CovidDeaths']
where 
    location = 'Canada'
order by 
    location, 
    date

--looking at total cases vs population and fully_vaxed vs population
select 
    location, 
    date,
    total_cases,
    total_deaths, 
    (total_cases/population)*100 as sick_percentage,
    (total_deaths/total_cases)*100 as death_percentage,
    population,
    people_fully_vaccinated,
    (people_fully_vaccinated/population)*100 as f_vaccination_rate
from 
    dbo.[CovidDeaths]
where 
    location = 'Canada'
order by 
    location, 
    date

--Looking at countries with highest infection rate
select 
    location, 
    population, 
    MAX (total_cases) as HighestInfectionCount,
    MAX((total_cases/population))*100 as PercentPopulationInfected
from 
    dbo.[CovidDeaths]
where 
    continent is not null
group by 
    location,
    population
order by 
    PercentPopulationInfected DESC

--Showing Countries with the Highest COVID Death Count per population
select 
    location, 
    MAX (cast(total_deaths as int)) as TotalDeathCount
from 
    dbo.[CovidDeaths]
where 
    continent is not null
group by 
    location
order by 
    TotalDeathCount DESC

--CONTINENTS WITH HIGHEST DEATH COUNT
select 
    continent,
    MAX (cast(total_deaths as int)) as TotalDeathCount
from 
    dbo.['CovidDeaths']
where 
    continent is not null
group by 
    continent
order by 
    TotalDeathCount DESC

--GLOBAL NUMBERS BY DATE
select 
    date,
    SUM (new_cases) as total_cases,
    SUM (cast(new_deaths as int)) as total_deaths,
    SUM (cast(new_deaths as int))/SUM (new_cases)*100 as DeathPercentage
from 
    dbo.[CovidDeaths]
where 
    continent IS NOT NULL
Group by 
    date
order by
    date,
    total_cases


--GLOBAL NUMBERS
select 
    SUM (new_cases) as total_cases,
    SUM (cast(new_deaths as int)) as total_deaths,
    SUM (cast(new_deaths as int))/SUM (new_cases)*100 as DeathPercentage
from 
    dbo.[CovidDeaths]
where 
    continent IS NOT NULL
order by
    total_cases,
    total_deaths

--Joining Vaccinations Table and Deaths Table
select 
    dea.*,
    vac.*
from 
    dbo.[CovidDeaths] as dea
join 
    dbo.[CovidVaccinations] as vac
on 
    dea.location=vac.location
    and dea.date=vac.date

--Looking at Total Population vs Vaccination
select 
    dea.continent,
    dea.location,
    dea.date,
    dea.population, 
    vac.new_vaccinations,
    SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.Date) as RollingVaccinationCount
from 
    dbo.[CovidDeaths] as dea
join 
    dbo.['CovidVaccinations'] as vac
on 
    dea.location=vac.location
    and dea.date=vac.date
where 
    dea.continent is not null
order by 
    dea.location,
    dea.date

--USE CTE -- # of columns in CTE needs to be the same as the subquery
with PopvsVax as
(
  select 
      dea.continent,
      dea.location,
      dea.date,
      dea.population,
      vac.new_vaccinations,
      SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.Date) as RollingVaccinationCount
  from 
      dbo.['CovidDeaths'] as dea
  join 
      dbo.['CovidVaccinations'] as vac
  on 
      dea.location=vac.location
      and dea.date=vac.date
where 
      dea.continent is not null
)
select
    *,
    (RollingVaccinationCount/Population)*100
from 
    PopvsVax

--TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
  Continent nvarchar(255),
  Location nvarchar(255),
  Date datetime,
  Population numeric,
  New_Vaccinations numeric,
  RollingVaccinationCount Numeric  )

insert into 
    #PercentPopulationVaccinated
select 
    dea.continent,
    dea.location,
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.Date) as RollingVaccinationCount
from 
    dbo.[CovidDeaths] as dea
join 
    dbo.[CovidVaccinations] as vac
on 
    dea.location=vac.location
    and dea.date=vac.date
where 
    dea.continent is not null

select 
    *, 
    (RollingVaccinationCount/Population)*100
from 
    #PercentPopulationVaccinated


--Creating Views -- can be used for visualization
Create View PercentPopulationVaccinated as 
select 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(convert(bigint,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.Date) as RollingVaccinationCount
from 
    dbo.['CovidDeaths'] as dea
join 
    dbo.['CovidVaccinations'] as vac
on 
    dea.location=vac.location
    and dea.date=vac.date
where 
    dea.continent is not null
