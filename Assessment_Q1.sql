-- Aggregate total confirmed inflows per plan (converted from kobo to naira)
WITH plan_inflows AS (
    SELECT
        plan_id,
        SUM(confirmed_amount) / 100.0 AS inflow_amount
    FROM savings_savingsaccount
    GROUP BY plan_id
),

-- Classify each plan as 'Savings' or 'Investment' and attach inflow amounts
-- Also exclude deleted or archived plans
classified_plans AS (
    SELECT
        p.id AS plan_id,
        p.owner_id,
        CASE 
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund = 1 THEN 'Investment'
            ELSE NULL  -- Skip plans that are neither
        END AS plan_type,
        COALESCE(pi.inflow_amount, 0) AS inflow_amount
    FROM plans_plan p
    LEFT JOIN plan_inflows pi ON pi.plan_id = p.id
    WHERE p.is_deleted = 0 AND p.is_archived = 0
),

-- For each customer, count distinct funded savings and investment plans
-- and compute their total deposit value
customer_summary AS (
    SELECT 
        owner_id,
        COUNT(DISTINCT CASE WHEN plan_type = 'Savings' THEN plan_id END) AS savings_count,
        COUNT(DISTINCT CASE WHEN plan_type = 'Investment' THEN plan_id END) AS investment_count,
        SUM(inflow_amount) AS total_deposits
    FROM classified_plans
    GROUP BY owner_id
    HAVING 
        COUNT(DISTINCT CASE WHEN plan_type = 'Savings' THEN plan_id END) > 0 AND
        COUNT(DISTINCT CASE WHEN plan_type = 'Investment' THEN plan_id END) > 0
)

-- Join with user details and return final results ordered by deposit amount
SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    cs.savings_count,
    cs.investment_count,
    cs.total_deposits
FROM customer_summary cs
JOIN users_customuser u ON u.id = cs.owner_id
ORDER BY cs.total_deposits DESC;
