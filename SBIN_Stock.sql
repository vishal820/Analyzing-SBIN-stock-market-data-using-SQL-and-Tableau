select * from public."SBI";

--1.First Trading Day
select date as first_day from public."SBI"
order by date
limit 1;

--2.Last Trading Day
select date as last_day from public."SBI"
order by date desc
limit 1;

--3.Total trading days(Working days) in dataset
select count(date) from public."SBI" as Total_trading_days;

--4. Total Market Holidays
WITH dates AS(
select generate_series(date'2000-01-03',date'2021-04-30','1 day') as a
)
SELECT date(d.a) 
FROM  dates d
left join public."SBI" sbi ON
sbi.date = d.a
where sbi.symbol is null

--5. Avg close price, Avg volume *considering no stock split/bonus
select avg(close) as Avg_Close_price, avg(volume) as Avg_volume from public."SBI";

--6. Max volume, Min volume 
select max(volume) as max_volume, min(volume) as min_volume from public."SBI";

--7. All data of min & max Volume days
select * from public."SBI" --max
where volume = ( SELECT max(volume) from public."SBI" )
select * from public."SBI" --min
where volume = ( SELECT min(volume) from public."SBI" )

--8. Low and high of selected year
select min(close) from public."SBI"
where date_part('year',date) = '2010';

select max(close) from public."SBI"
where date_part('year',date) = '2010';


--9. low and high of last six month
select * from public."SBI"
where date > CURRENT_DATE - INTERVAL '6 months'-- data of last 6 months from current date

select * from public."SBI"
where date > (select date as last_day from public."SBI"
order by date desc
limit 1) - INTERVAL '6 months' -- data of last 6 months of dataset

select * from public."SBI"
where date between '2020-11-02' and '2020-11-04' --date range

--10.Moving averages and crossovers
WITH SBI (Date, Close, RowNumber, MA5, MA20, MA50, MA100)
AS(
SELECT Date,
       Close,
       ROW_NUMBER() OVER (ORDER BY Date ASC) RowNumber,
       AVG(Close) OVER (ORDER BY Date ASC ROWS 4 PRECEDING) AS MA5,
	   AVG(Close) OVER (ORDER BY Date ASC ROWS 19 PRECEDING) AS MA20,
	   AVG(Close) OVER (ORDER BY Date ASC ROWS 49 PRECEDING) AS MA50,
       AVG(Close) OVER (ORDER BY Date ASC ROWS 99 PRECEDING) AS MA100
FROM public."SBI"
)
SELECT Date,
       RowNumber,
       Close,
       CASE
          WHEN RowNumber > 19 AND MA20 > MA100 THEN 'Over'
          WHEN RowNumber > 49 AND MA20 < MA100 THEN 'Below'
          ELSE NULL
       END as Signal
FROM  SBI
ORDER BY Date


---Select high,low, avg volume as signal when volume on a day is high, low or equal to avg volume of last 10 days
--OR
--Volume More than Past 10 days'''

select date from (
WITH SBI (Date)
AS(
SELECT Date,
       Close,volume,
       ROW_NUMBER() OVER (ORDER BY Date ASC) RowNumber,
       avg(volume) OVER (ORDER BY Date ASC ROWS 10 PRECEDING) AS past_volume
FROM public."SBI"
)
SELECT Date,
       RowNumber,
       CASE
          WHEN RowNumber > 10 AND volume > past_volume THEN 'HIGH VOL' 
		  WHEN RowNumber > 10 AND volume = past_volume THEN 'Avg Vol'
          ELSE 'LOW VOL'
       END as Signal
FROM   SBI
ORDER BY Date) as a
where signal = 'HIGH VOL'