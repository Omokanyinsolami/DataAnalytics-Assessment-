-- Pull all active customers
WITH active_customers AS (
    SELECT id AS customer_id
    FROM users_customuser
    WHERE is_active = 1
),

-- Get all valid inflow transactions per customer with formatted year-month
valid_transactions AS (
    SELECT 
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS ym
    FROM savings_savingsaccount s
    WHERE s.confirmed_amount > 0
),

-- Aggregate transaction stats per customer
customer_txn_stats AS (
    SELECT 
        a.customer_id,
        COUNT(v.owner_id) AS total_transactions,
        COUNT(DISTINCT v.ym) AS active_months
    FROM active_customers a
	JOIN valid_transactions v ON a.customer_id = v.owner_id  
    GROUP BY a.customer_id
),

-- Compute average transactions per month and classify each customer
classified_customers AS (
    SELECT 
        customer_id,
        ROUND(total_transactions / NULLIF(active_months, 0), 2) AS avg_txn_per_month,
        CASE
            WHEN total_transactions / NULLIF(active_months, 0) >= 10 THEN 'High Frequency'
            WHEN total_transactions / NULLIF(active_months, 0) >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM customer_txn_stats
)

-- Final summary by frequency category
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_txn_per_month), 2) AS avg_transactions_per_month
FROM classified_customers
GROUP BY frequency_category
ORDER BY FIELD(frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency');
