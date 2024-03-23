
/* 
1- Query to get the top 10 most paying customers, Total Money Spent and the count of Ivoices. 

this query helps identify the top-spending customers in the retail business, along with metrics such as their total spending,
 the number of repeat purchases they've made, and their ranking based on total spending.
 This information can be valuable for targeted marketing campaigns, customer segmentation, and overall business strategy

*/ 
select * from (
with Top_cte as (select distinct customer_id, SUM(price*quantity)  over( partition by customer_id)"Total Spent" from tableretail ) 
select distinct tableretail.customer_id,"Total Spent",count( distinct invoice) over( partition by tableretail.customer_id) "Repeated Purchases", dense_rank() over(order by "Total Spent" desc) "Rank"  from tableretail join Top_cte on Top_cte.customer_id= tableretail.customer_id
order by "Rank" )
where "Rank" <= 10; 

/*
2- How many times have customers repeated purchases?
 this query provides valuable information about customer retention and loyalty by revealing which customers are making repeated purchases.
  Understanding this behavior enables businesses to tailor marketing strategies, implement loyalty programs,
  and improve customer relationship management efforts to foster long-term customer engagement and drive revenue growth.
*/

select distinct customer_id,  count( distinct invoice) over( partition by customer_id) "Repeated Purchases" from tableretail
order by "Repeated Purchases"desc ; 

/*
3- Which products have the highest sales volume?
this query helps businesses identify top-selling products based on both total sales revenue and total quantity sold.
 Understanding product performance in this manner can guide inventory management, pricing strategies, and marketing efforts to optimize sales and maximize profitability
*/ 
select distinct  stockcode,sum(quantity*price) over(partition by stockcode)"Total Sales",sum(quantity)over(partition by stockcode) "Total Quantity"  from tableretail
order by "Total Sales" desc;

/* 
4- which day of the week has the highest sales?
 this query allows retail businesses to analyze and understand the patterns of sales activity throughout the week. It enables them to optimize staffing, inventory management, 
 and marketing strategies to capitalize on peak sales days and address any potential fluctuations in demand across different weekdays
*/


select distinct  DayOfWeek, sum(quantity * price) over(partition by DayOfWeek) "TotalSales" from(
select quantity,price,
   to_char(to_date(invoicedate, 'MM/DD/YYYY HH24:MI'), 'day') AS DayOfWeek from tableretail)
    order by "TotalSales" desc;
    
    
    
/*
5- which month of which year made the highest sales?
this query empowers retail businesses to analyze and comprehend the seasonal dynamics of sales activity throughout the year. It assists in optimizing inventory management, marketing campaigns,
 and financial planning efforts to capitalize on peak sales months and address any fluctuations in demand across different seasons
*/

select distinct "MonthOfYear", sum (quantity*price) over(partition by "MonthOfYear") "TotalSales" from (
  select quantity,price,  to_char(to_date(invoicedate, 'MM/DD/YYYY HH24:MI'), 'mm/yyyy') AS "MonthOfYear" from tableretail)
  order by "TotalSales" desc ;
  
  
  
  /*
   6- query to get the top 10 most sold products per month
  this query assists retail businesses in analyzing the sales performance of products over different months, identifying top-selling products for each month,
   and understanding overall product performance across all months.
   This information can guide inventory management, marketing strategies, and product promotions to optimize sales and maximize revenue throughout the year.
  */

 with month_cte as ( select stockcode, quantity,price,  to_char(to_date(invoicedate, 'MM/DD/YYYY HH24:MI'), 'mm/yyyy') AS "MonthOfYear",sum(quantity*price)over(partition by stockcode)"TotalSales" from tableretail)
  ,top_10 as( select distinct stockcode,"MonthOfYear", sum(quantity*price) over(partition by stockcode,"MonthOfYear")"MonthlySales","TotalSales",dense_rank()over(order by "TotalSales" desc) "Rank"from month_cte)
  select * from top_10 where "Rank" <=10
  order by "TotalSales" desc;
   
 
 
 ------------------------------------
 
 /*
7 -monthly sales for top 10 customers
 this query assists retail businesses in analyzing the sales performance of customers over different months, identifying top-spending customers for each month,
 and understanding overall customer behavior across all months.
 This information can inform customer relationship management strategies, targeted marketing efforts, and personalized promotions to enhance customer satisfaction and drive revenue growth
 */
  with month_cte as ( select customer_id, quantity,price,  to_char(to_date(invoicedate, 'MM/DD/YYYY HH24:MI'), 'mm/yyyy') AS "MonthOfYear" , sum(price*quantity) over(partition by customer_id)"TotalSales"from tableretail)
  ,top_10 as( select distinct customer_id,"MonthOfYear", sum(quantity*price) over(partition by customer_id,"MonthOfYear")"MonthlySales" ,"TotalSales"from month_cte),
  ranks as (select top_10.*,dense_rank()over(order by "TotalSales" desc) "Rank" from top_10)
  select * from ranks where "Rank" <=10
  order by "MonthlySales" desc;
   
  ----------------------------------------------------------
  
  --Q2  RFM model 
  with max_date as ( select max(to_date(invoicedate,'mm/dd/yyyy hh24:mi')) "MaxDate" from tableretail),
 rfm as(
 select distinct customer_id , round((select "MaxDate" from max_date ) - max(to_date(invoicedate , 'mm/dd/yyyy hh24:mi'))over(partition by customer_id)) as Recency,
 count(distinct invoice) over(partition by customer_id) as Frequency,
 sum(quantity * price)over(partition by customer_id) as Monetary
 from tableretail
),
rfm_score as(
 select customer_id , recency , frequency , monetary,
 ntile(5) over(order by recency desc) r_score,
 ntile(5) over(order by frequency) f_score,
 ntile(5) over(order by monetary) m_score
 
 from rfm
),
fm_score as (
 select distinct customer_id , recency , frequency , monetary , r_score,f_score,m_score , ntile(5) over(order by
(f_score+m_score)/2) fm_score
 from rfm_score
 group by customer_id , recency , frequency , monetary , r_score , f_score , m_score

 
)
select customer_id , recency , frequency , monetary , r_score , fm_score,
case
 when (r_score = 5 and fm_score = 5) or ( r_score = 5 and fm_score = 4 ) or ( r_score = 4 and fm_score = 5 )  then 'champions'
 when (r_score = 5 and fm_score = 2) or ( r_score = 4 and fm_score = 2) or ( r_score = 3 and fm_score = 3) or ( r_score = 4 and fm_score = 3) then 'potential loyalists'
 when (r_score = 5 and fm_score = 3) or (r_score = 4 and fm_score = 4) or (r_score = 3 and fm_score = 5 ) or (r_score = 3 and fm_score = 4) then 'loyal customers'
 when r_score = 5 and fm_score = 1 then 'recent customers'
 when (r_score = 4 and fm_score = 1) or (r_score = 3 and fm_score = 1) then 'promising'
 when (r_score = 3 and fm_score = 2) or (r_score = 2 and fm_score = 3) or (r_score = 2 and fm_score = 2 ) then 'customers needing attention'
 when (r_score = 2 and fm_score = 5) or ( r_score = 2 and fm_score = 4 ) or ( r_score = 1 and fm_score = 3)then 'at risk'
 when (r_score = 1 and fm_score = 5) or (r_score = 1 and fm_score = 4) then 'cant lose them'
 when (r_score = 1 and fm_score = 2) then 'hibernating'
 when r_score = 1 and fm_score = 1 then 'lost'
 else 'uncategorized'
 end as cust_segment

from fm_score
order by customer_id  desc;
 
-----------------------------------------###------------------------------------
-----------------------------------------###------------------------------------

--  Q3 A- 
WITH  consecutive_groups AS (
  SELECT
    cust_id,
    calendar_dt,
    ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY calendar_dt) AS rn,
    calendar_dt - ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY calendar_dt) AS grp
  FROM transactions
),
max_consecutive_days AS (
  SELECT
    cust_id,
    MAX(count_days) AS max_consecutive_number
  FROM (
    SELECT
      cust_id,
      COUNT(*) AS count_days
    FROM consecutive_groups
    GROUP BY cust_id, grp
  )  temp
  GROUP BY cust_id
)

SELECT * FROM max_consecutive_days;

 ---------------------------------------------###--------------------------------------
 --------------------------------------------###---------------------------------------
 
 --Q3 -B On average, How many days/transactions does it take a customer to reach a spent threshold of 250 L.E?
 WITH trans_info AS (
    SELECT 
      transactions.*,
        SUM(amt_le) OVER (PARTITION BY cust_id ORDER BY calendar_dt) AS RunningTotal,
        ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY calendar_dt) AS "rank"
    FROM 
        transactions
)

SELECT 
    
    ROUND(AVG(num_transactions)) AS Avg_No_Trans
FROM (
    SELECT 
        cust_id,
        MIN("rank") AS num_transactions
    FROM 
        trans_info
    WHERE 
        runningTotal >= 250
    GROUP BY 
        cust_id
)  ;
