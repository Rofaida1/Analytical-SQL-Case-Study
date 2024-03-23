# Analytical-SQL-Case-Study
Customers has purchasing transaction that we shall be monitoring to get intuition behind each  customer behavior to target the customers in the most efficient and proactive way, to increase  sales/revenue , improve customer retention and decrease churn. 
Using SQL i'll be answering the following questions to gain useful insights.


Q1- Using OnlineRetail dataset :
- write at least 5 analytical SQL queries that tells a story about the data 
- write small description about the business meaning behind each query 


Q2- After exploring the data now you are required to implement a Monetary model for 
customers behavior for product purchasing and segment each customer based on the below 
groups: (
Champions - Loyal Customers - Potential Loyalists – Recent Customers – Promising -
Customers Needing Attention - At Risk - Cant Lose Them – Hibernating – Lost )

The customers will be grouped based on 3 main values 
• Recency => how recent the last transaction is 
• Frequency => how many times the customer has bought from our store 
• Monetary => how much each customer has paid for our products 
As there are many groups for each of the R, F, and M features, there are also many potential 
permutations, this number is too much to manage in terms of marketing strategies. 
For this, we would decrease the permutations by getting the average scores of the 
frequency and monetary (as both of them are indicative to purchase volume anyway)

Q3-
You are required to answer two questions: 

a- What is the maximum number of consecutive days a customer made purchases? 


b- On average, How many days/transactions does it take a customer to reach a spent 
threshold of 250 L.E? 
