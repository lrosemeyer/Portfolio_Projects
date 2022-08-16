-- Rename FIPS columns to 'FIPS'.
alter table classifications change FIPStxt FIPS bigint;
alter table income change ï»¿FIPS FIPS bigint;
alter table jobs change ï»¿FIPS FIPS bigint;
alter table people change ï»¿FIPS FIPS bigint;
alter table veterans change ï»¿FIPS FIPS bigint;

-- Combine all data columns into one table without state and national averages.
create view alldata as
select * from classifications c
inner join income i using(FIPS, State, County)
inner join jobs j using(FIPS, State, County)
inner join people p using(FIPS, State, County)
inner join veterans v using(FIPS, State, County)

-- Create a view that only has state averages
create view statedata as
select *
from income i
inner join jobs j using(FIPS, State, County)
inner join people p using(FIPS, State, County)
inner join veterans v using(FIPS, State, County)
where FIPS%1000 = 0

-- Now lets look at the smallest table to get an idea of where to start with our data.
-- I am also going to pin the lookup table to have the category descriptions to look at.
select *
from income;
select *
from lookup
where Category = 'Income'

-- I want to use averages over time, so I will start with categories that have a time range of 2015-2019.
select County, State, Poverty_Rate_0_17_ACS
from income
order by Poverty_Rate_0_17_ACS desc

-- This table seems to be very Puerto Rico heavy at the top. Lets look at averages by state.
select County, State, avg(Poverty_Rate_0_17_ACS) as Average_child_poverty
from income
group by State
order by Average_child_poverty desc

-- Now we can see that Puerto Rico has by far the highest average child poverty.
-- This is definitely something to dig into a little deeper.
-- Let's look at some of the poorer counties in the US besides Puerto Rico.
select county, State, Poverty_Rate_0_17_ACS
from income
where State <> 'PR'
order by Poverty_Rate_0_17_ACS desc

-- We could label a county with a child poverty rate of 50% or above as being extremely high.
-- Let's see which states have the most counties with an extremely high child poverty rate.
select State, count(State) as number_of_counties
from income
where county in (select county from income where Poverty_Rate_0_17_ACS>50 and state<>'PR')
group by State
order by number_of_counties desc

-- I think this query is including any counties that have matching names.
-- For example there is a Jackson County in SD that has a child poverty rate over 50%,
-- but the query above is counting all Jackson counties in the US, even if they are below 50%.
-- To fix this, I am going to concatenate the county and state columns into a new column.
alter table income add column county_state varchar(100);
update income set county_state = concat(county,', ',state);
select * from income limit 10;

-- Let's try again...
select State, count(*) as number_of_counties
from income
where county_state in (select county_state from income where Poverty_Rate_0_17_ACS>50 and state<>'PR')
group by State
order by number_of_counties desc

-- Being from Wisconsin, I recognize the one county that has a child poverty rate over 50%.
-- That county is essentially the boundary for the Menominee Indian Reservation (minus 2 square miles).
-- I have a feeling most of these counties are mostly populated by minorities. Let's take a look.

select county_state, poverty_rate_0_17_ACS, whitenonhispanicpct2010, blacknonhispanicpct2010, asiannonhispanicpct2010,
nativeamericannonhispanicpct2010, hispanicpct2010, multipleracepct2010
from income i
inner join people p using (FIPS, state, county)
where poverty_rate_0_17_ACS>50 and state<>'PR'
order by whitenonhispanicpct2010 desc

-- Now let's get a count of how many states have a minority population over 50%.
select count(*)
from income i
inner join people p using (FIPS, state, county)
where poverty_rate_0_17_ACS>50 and state<>'PR' and whitenonhispanicpct2010<50


