CREATE DATABASE banking_data;
USE banking_data;

SELECT *
FROM banking_data.transactions;

-- Check for missing data
SELECT *
FROM banking_data.transactions
WHERE transaction_amount IS NULL
 OR transaction_date IS NULL;
 
-- Generating Transaction ID for data integrity
ALTER TABLE transactions
ADD COLUMN Transaction_ID INT AUTO_INCREMENT PRIMARY KEY;

-- Remove Duplicate
DELETE FROM transactions
WHERE transaction_id IN (
		SELECT Transaction_ID
        FROM (SELECT Transaction_ID, COUNT(*) as count
			  FROM transactions
              GROUP BY Transaction_ID
              HAVING count > 1) AS duplicates
);

-- Date Setup
UPDATE banking_data.transactions
SET Transaction_Date = STR_TO_DATE (Transaction_Date, "%Y-%m-%d");

UPDATE transactions
SET Account_Type = 
	CASE
		WHEN LOWER(TRIM(Account_Type)) = "current" THEN "Current"
        WHEN LOWER(TRIM(Account_Type)) = "savings" THEN "Savings"
        WHEN LOWER(TRIM(Account_Type)) = "business" THEN "Business"
        ELSE Account_Type -- Other Account types remain unchanged
	END;
    
-- Spending to Income
SELECT 
	Customer_ID,
    Income,
	SUM(Transaction_Amount) AS Total_Spent,
	COUNT(Transaction_ID) AS Transaction_Count,
	ROUND(AVG(Credit_Score), 2) AS Avg_CreditScore,
	Spending_Score,
    ROUND((SUM(Transaction_Amount) / Income) * 100, 2) AS Spending_to_IncomeRatio
FROM banking_data.transactions
WHERE transaction_type = "Debit"
GROUP BY Customer_ID, Income, Spending_Score
ORDER BY Spending_to_IncomeRatio;

-- Customer Segment
WITH customer_spend AS (
		SELECT
			Customer_ID,
            AVG(Transaction_Amount) AS Avg_TotalAmount,
			COUNT(Transaction_ID) AS Transaction_Count,
			SUM(Transaction_Amount) AS Total_Spent
		FROM banking_data.transactions
        GROUP BY Customer_ID)
SELECT Customer_ID,
		CASE
        WHEN total_spent > 5000 THEN "High Spender"
        WHEN total_spent BETWEEN 2000 AND 5000 THEN "Medium Spender"
        ELSE "Low Spender"
	END AS  Customer_Segment,
			Avg_TotalAmount,
            Transaction_Count,
            Total_Spent
FROM customer_spend
ORDER BY total_spent DESC;

-- Approved Loans VS Rejected Loans
-- Method 1
SELECT 
    DATE_FORMAT(Transaction_Date, '%Y-%m') AS YearMonth,
    Credit_Score,
    ROUND(AVG(Debt_to_Income_Ratio), 2) AS Avg_DTI,
    COUNT(Transaction_ID) AS Total_Transactions,
    SUM(CASE WHEN Loan_Status = "Approved" THEN 1 ELSE 0 END) AS Approved_Loans,
    SUM(CASE WHEN Loan_Status = "Rejected" THEN 1 ELSE 0 END) AS Rejected_Loans,
    ROUND(SUM(CASE WHEN Loan_Status = "Rejected" THEN 1 ELSE 0 END) * 100.0 / COUNT(Transaction_ID), 2) AS Rejection_Rate
FROM banking_data.transactions
WHERE Loan_Status IN ("Approved", "Rejected") 
GROUP BY Credit_Score, YearMonth
HAVING Rejection_Rate > 0 
ORDER BY Credit_Score ASC;

-- Method 2 (Segmentation)
SELECT 
    CASE 
        WHEN Credit_Score BETWEEN 300 AND 500 THEN '300-500'
        WHEN Credit_Score BETWEEN 501 AND 650 THEN '501-650'
        WHEN Credit_Score BETWEEN 651 AND 750 THEN '651-750'
        ELSE '751-850'
    END AS Credit_Score_Range,
    ROUND(AVG(Debt_to_Income_Ratio), 2) AS Avg_DTI,
    COUNT(Transaction_ID) AS Total_Transactions,
    SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved_Loans,
    SUM(CASE WHEN Loan_Status = 'Rejected' THEN 1 ELSE 0 END) AS Rejected_Loans,
    ROUND(SUM(CASE WHEN Loan_Status = 'Rejected' THEN 1 ELSE 0 END) * 100.0 / COUNT(Transaction_ID), 2) AS Rejection_Rate
FROM banking_data.transactions
WHERE Loan_Status IN ('Approved', 'Rejected') 
GROUP BY Credit_Score_Range
ORDER BY Credit_Score_Range;


-- Customer Lifetime Value & Retention
WITH Customer_Rev AS (
	SELECT Customer_ID,
		   SUM(Transaction_Amount) AS Total_Revenue,
           COUNT(Transaction_ID) AS Transaction_Count
           FROM banking_data.transactions
           WHERE Transaction_Type = "Credit"
           GROUP BY Customer_ID)
SELECT Customer_ID, 
	   Total_Revenue,
       Transaction_Count,
       ROUND(Total_Revenue/Transaction_Count, 2) AS AvgSpendPerTransaction
FROM Customer_Rev
ORDER BY Total_Revenue DESC
LIMIT 10;

-- Seasonal Trend
SELECT 
    DATE_FORMAT(Transaction_Date, "%Y, %m") AS YearMonth,
    ROUND(SUM(CASE WHEN Transaction_Type = "Credit" THEN Transaction_Amount ELSE 0 END), 2) AS Total_Revenue,
    ROUND(SUM(CASE WHEN Transaction_Type = "Debit" THEN Transaction_Amount ELSE 0 END), 2) AS Total_Expenses,
    ROUND((SUM(CASE WHEN Transaction_Type = "Credit" THEN Transaction_Amount ELSE 0 END) -
     SUM(CASE WHEN Transaction_Type = "Debit" THEN Transaction_Amount ELSE 0 END)), 2) AS Net_Cash_Flow
FROM banking_data.transactions
GROUP BY YearMonth
ORDER BY YearMonth;
