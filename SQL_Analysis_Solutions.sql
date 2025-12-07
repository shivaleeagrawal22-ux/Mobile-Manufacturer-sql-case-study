--SQL Advance Case Study

SELECT TOP 1 * FROM DIM_CUSTOMER 
SELECT TOP 1 * FROM DIM_DATE 
SELECT TOP 1 * FROM DIM_LOCATION 
SELECT TOP 1 * FROM DIM_MANUFACTURER 
SELECT TOP 1 * FROM DIM_MODEL 
SELECT TOP 1 * FROM FACT_TRANSACTIONS 

--Q1--BEGIN 

select a.State from DIM_LOCATION as a
inner join FACT_TRANSACTIONS as b
on a.IDLocation = b.IDLocation 
where b.Date between '2005-01-01' and GETDATE()
group by a.State 

--Q1--END

--Q2--BEGIN
	
select top 1 a.State from DIM_LOCATION as a
inner join FACT_TRANSACTIONS as b
on a.IDLocation = b.IDLocation 
inner join DIM_MODEL as c
on b.IDModel = c.IDModel 
inner join DIM_MANUFACTURER as d
on c.IDManufacturer = d.IDManufacturer 
where a.Country = 'US' and d.Manufacturer_Name = 'Samsung'
group by a.State
order by count(*) desc

--Q2--END

--Q3--BEGIN      
	
select b.Model_Name, c.State, c.ZipCode, count(*) as no_of_tran from FACT_TRANSACTIONS as a
inner join DIM_MODEL as b
on a.IDModel = b.IDModel 
inner join DIM_LOCATION as c
on a.IDLocation = c.IDLocation 
group by b.Model_Name, c.State, c.ZipCode 
order by b.Model_Name
			  
--Q3--END

--Q4--BEGIN

select top 1 b.Manufacturer_Name, a.Model_Name, a.Unit_price from DIM_MODEL as a
inner join DIM_MANUFACTURER as b
on a.IDManufacturer = b.IDManufacturer 
order by a.Unit_price asc

--Q4--END

--Q5--BEGIN

select b.Manufacturer_Name, a.Model_Name, avg(a.Unit_price) as avg_price from DIM_MODEL as a
inner join DIM_MANUFACTURER as b
on a.IDManufacturer = b.IDManufacturer 
where b.Manufacturer_Name in (select top 5 c.Manufacturer_Name from DIM_MANUFACTURER as c
                              inner join DIM_MODEL as d
                              on c.IDManufacturer = d.IDManufacturer 
                              inner join FACT_TRANSACTIONS as e
                              on d.IDModel = e.IDModel 
                              group by c.Manufacturer_Name 
                              order by sum(e.Quantity) desc
                             )
group by b.Manufacturer_Name,a.Model_Name 
order by avg(a.Unit_price)

--Q5--END

--Q6--BEGIN

select a.Customer_Name, avg(b.TotalPrice) as avg_amt from DIM_CUSTOMER as a
inner join FACT_TRANSACTIONS as b
on a.IDCustomer = b.IDCustomer 
inner join DIM_DATE as c
on b.Date = c.DATE 
where c.YEAR = '2009' 
group by a.Customer_Name 
having avg(b.TotalPrice) > 500

--Q6--END
	
--Q7--BEGIN  
	
select final_tbl.Model_Name
from (
          (select * from (select top 5 c.YEAR, b.Model_Name from FACT_TRANSACTIONS as a
                          inner join DIM_MODEL as b
                          on a.IDModel = b.IDModel 
                          inner join DIM_DATE as c
                          on a.Date = c.DATE 
                          where c.YEAR = '2008'
                          group by c.YEAR,b.Model_Name
                          order by sum(a.Quantity) desc
                         ) as tbl_2008
           )

           union all

           (select * from (select top 5 c.YEAR, b.Model_Name from FACT_TRANSACTIONS as a
                           inner join DIM_MODEL as b
                           on a.IDModel = b.IDModel 
                           inner join DIM_DATE as c
                           on a.Date = c.DATE 
                           where c.YEAR = '2009'
                           group by c.YEAR, b.Model_Name 
                           order by sum(a.Quantity) desc
                          ) as tbl_2009
           )

           union all

           (select * from (select top 5 c.YEAR, b.Model_Name from FACT_TRANSACTIONS as a
                           inner join DIM_MODEL as b
                           on a.IDModel = b.IDModel
                           inner join DIM_DATE as c
                           on a.Date = c.DATE 
                           where c.YEAR = '2010'
                           group by c.YEAR, b.Model_Name 
                           order by sum(a.Quantity) desc
                          ) as tbl_2010
           )
     ) as final_tbl
group by final_tbl.Model_Name 
having count(distinct final_tbl.YEAR) = 3

--Q7--END	

--Q8--BEGIN

(select * from (select top 1 * from (select top 2 a.YEAR, d.Manufacturer_Name, 
                                    sum(b.TotalPrice) as ttl_sales from DIM_DATE as a
                                    inner join FACT_TRANSACTIONS as b
                                    on a.DATE = b.Date 
                                    inner join DIM_MODEL as c
                                    on b.IDModel = c.IDModel 
                                    inner join DIM_MANUFACTURER as d
                                    on c.IDManufacturer = d.IDManufacturer 
                                    where a.YEAR = '2009'
                                    group by a.YEAR, d.Manufacturer_Name 
                                    order by ttl_sales desc
                                   ) as tbl_
               order by tbl_.ttl_sales 
              )as g
)

union all

(select * from (select top 1 * from (select top 2 a.YEAR, d.Manufacturer_Name,
                                     sum(b.TotalPrice) as ttl_sales from DIM_DATE as a
                                     inner join FACT_TRANSACTIONS as b
                                     on a.DATE = b.Date 
                                     inner join DIM_MODEL as c
                                     on b.IDModel = c.IDModel 
                                     inner join DIM_MANUFACTURER as d
                                     on c.IDManufacturer = d.IDManufacturer 
                                     where a.YEAR = '2010'
                                     group by a.YEAR, d.Manufacturer_Name 
                                     order by ttl_sales desc
                                    ) as tbl_
                order by tbl_.ttl_sales 
               )as g
)

--Q8--END

--Q9--BEGIN

select a.Manufacturer_Name from DIM_MANUFACTURER as a
inner join DIM_MODEL as b
on a.IDManufacturer = b.IDManufacturer 
inner join FACT_TRANSACTIONS as c
on b.IDModel = c.IDModel 
inner join DIM_DATE as d
on c.Date = d.DATE 
where d.YEAR = '2010' and d.YEAR != '2009'
group by a.Manufacturer_Name 

--Q9--END

--Q10--BEGIN
	
select tbl2.IDCustomer, tbl2.YEAR, tbl2.current_yr_avg_spend, tbl2.avg_qty,
((tbl2.current_yr_avg_spend - tbl2.prev_yr_avg_spend) / tbl2.prev_yr_avg_spend)*100 as perc_change
from (
       select *,lag(tbl1.current_yr_avg_spend,1) over(partition by tbl1.IDCustomer order by tbl1.Year) as prev_yr_avg_spend
       from (
              select a.IDCustomer,b.YEAR, avg(a.TotalPrice) as current_yr_avg_spend, avg(a.Quantity) as avg_qty             
              from FACT_TRANSACTIONS as a
              inner join DIM_DATE as b
              on a.Date = b.DATE
              where a.IDCustomer in (select top 100 a.IDCustomer from FACT_TRANSACTIONS as a
                                     group by a.IDCustomer 
                                     order by sum(a.TotalPrice) desc
                                    )
              group by a.IDCustomer, b.YEAR                
            ) as tbl1
     ) as tbl2

--Q10--END