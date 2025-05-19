-- Extract all valid deposit transactions (inflows)
-- Only include transactions with a confirmed_amount > 0 and convert from kobo to naira
WITH valid_transactions AS (
  SELECT
    owner_id,
    confirmed_amount / 100.0 AS amount_naira
  FROM savings_savingsaccount
  WHERE confirmed_amount > 0
),

-- For each customer, calculate:
-- - Their account tenure (in months since date_joined)
-- - Total number of valid transactions they've made
-- - Average profit per transaction (0.1% of transaction value)
customer_summary AS (
  SELECT
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months,
    COUNT(vt.amount_naira) AS total_transactions,
    AVG(vt.amount_naira * 0.001) AS avg_profit_per_transaction
  FROM users_customuser u
  LEFT JOIN valid_transactions vt ON vt.owner_id = u.id
  GROUP BY u.id, u.first_name, u.last_name, u.date_joined
  -- Remove customers who joined this month to avoid divide-by-zero when calculating CLV
  HAVING tenure_months > 0
),

-- Estimate CLV using the provided formula:
-- (total_transactions / tenure) * 12 * avg_profit_per_transaction
-- This gives projected annual value based on average monthly activity
clv_calc AS (
  SELECT
    customer_id,
    name,
    tenure_months,
    total_transactions,
    ROUND((total_transactions / tenure_months) * 12 * avg_profit_per_transaction, 2) AS estimated_clv
  FROM customer_summary
)
SELECT *
FROM clv_calc
ORDER BY estimated_clv DESC;
