-- Classify each plan as either 'Savings' or 'Investment'
-- based on the flags in the plans_plan table
-- Only include active (not deleted or archived) plans
WITH plan_types AS (
  SELECT
    p.id AS plan_id,
    p.owner_id,
    CASE 
      WHEN p.is_regular_savings = 1 THEN 'Savings'
      WHEN p.is_a_fund = 1 THEN 'Investment'
      ELSE NULL  -- Plans that are neither savings nor investment will be excluded later
    END AS type
  FROM plans_plan p
  WHERE p.is_deleted = 0 AND p.is_archived = 0
),

-- For each plan, find the most recent inflow transaction (if any)
-- If a plan has no transaction, last_transaction_date will be NULL
last_transactions AS (
  SELECT
    pt.plan_id,
    pt.owner_id,
    pt.type,
    MAX(s.transaction_date) AS last_transaction_date
  FROM plan_types pt
  LEFT JOIN savings_savingsaccount s ON s.plan_id = pt.plan_id
  GROUP BY pt.plan_id, pt.owner_id, pt.type
),

-- Calculate inactivity in days (based on last transaction date)
-- Only flag plans that have been inactive for 365 days or more
-- Plans with no transactions are excluded by the IS NOT NULL filter
inactivity_alerts AS (
  SELECT
    plan_id,
    owner_id,
    type,
    last_transaction_date,
    DATEDIFF(CURDATE(), last_transaction_date) AS inactivity_days
  FROM last_transactions
  WHERE last_transaction_date IS NOT NULL
    AND DATEDIFF(CURDATE(), last_transaction_date) >= 365
)

-- List of inactive plans sorted by how long they’ve been idle
SELECT *
FROM inactivity_alerts
ORDER BY inactivity_days DESC;
