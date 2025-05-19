# Cowrywise SQL Assessment

This repository contains solutions to the Cowrywise Data Analyst SQL Proficiency Assessment.  
Each question was solved using clean, modular SQL with business logic in mind. The queries are optimized for clarity, correctness, and real-world readability.

---

## Question 1: High-Value Customers with Multiple Products

**Scenario:**  
The business wants to identify customers who have at least a **funded savings plan** and a **funded investment plan** — to assess cross-selling opportunities.

**Approach:**
- Aggregated `confirmed_amount` from the `savings_savingsaccount` table (converted from **kobo to naira**).
- Classified each plan as either **Savings** or **Investment** using `is_regular_savings` and `is_a_fund` flags.
- Joined inflow data with plan metadata (`plans_plan`) while filtering out deleted or archived plans.
- For each customer, counted how many funded plans they had of each type.
- Returned only those customers with at least **one of each** plan type.
- Joined with the user table to include customer names.

**Challenges:**
- Ensured proper plan classification by avoiding assumptions about `plan_type_id`.
- Used `COALESCE(...)` to handle plans that had no recorded inflows.
- Grouped and filtered customers cleanly using `HAVING` on aggregated values.

---

## Question 2: Transaction Frequency Analysis

**Scenario:**  
The finance team wants to segment customers based on how often they transact.

**Frequency buckets:**
- **High Frequency**: ≥ 10 transactions/month  
- **Medium Frequency**: 3–9 transactions/month  
- **Low Frequency**: ≤ 2 transactions/month

**Approach:**
- Pulled all **active customers** (`is_active = 1`) from `users_customuser`.
- Extracted valid inflow transactions (`confirmed_amount > 0`) and grouped them by customer and month.
- Calculated total transactions and active months per customer.
- Used this to compute the **average transactions per month**.
- Classified each user into frequency buckets based on their average.
- Aggregated the total count of users and average frequency per category.

**Challenges:**
- Excluded users with no transactions to keep segmentation meaningful.
- Used `NULLIF(active_months, 0)` to avoid divide-by-zero errors.
- Made sure to maintain order of categories using `FIELD()` in `ORDER BY`.

---

##  Question 3: Account Inactivity Alert

**Scenario:**  
The operations team wants to identify accounts that have had no inflow for **365 days or more**.

**Approach:**
- Classified each plan as **Savings** or **Investment** using flag columns.
- Excluded deleted or archived plans.
- Left joined each plan with `savings_savingsaccount` to get the **most recent transaction date**.
- Calculated **inactivity_days** using `DATEDIFF(CURDATE(), last_transaction_date)`.
- Filtered to only return plans that were inactive for 365+ days.

**Challenges:**
- Carefully handled NULL transaction dates and excluded them to avoid false alerts.
- Ensured only funded and valid plans were considered by excluding irrelevant plan types.

---

## Question 4: Customer Lifetime Value (CLV) Estimation

**Scenario:**  
Marketing wants to estimate CLV for each customer using a simplified formula:  
> `CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction`  
Where:
- `avg_profit_per_transaction = 0.1%` of transaction value  
- All monetary values are stored in **kobo**, so they were converted to **naira**

**Approach:**
- Filtered valid inflows (`confirmed_amount > 0`) and converted them to naira.
- Joined each user with their transactions to calculate:
  - `tenure_months`: how long they’ve been a customer
  - `total_transactions`: number of valid deposits
  - `avg_profit_per_transaction`: 0.1% of the average inflow
- Applied the CLV formula using the metrics above.
- Filtered out users who joined this month (to avoid divide-by-zero).
- Returned the top customers sorted by highest CLV.

**Challenges:**
- The schema stores amounts in **kobo**, so failing to convert to naira would overestimate CLV by 100x.
- Avoided new users skewing the results by using a `HAVING tenure_months > 0` filter.
- Made sure calculations remained interpretable with rounded, clean results.

---

## SQL Design Notes

- Used **CTEs** extensively for clean, step-by-step logic.
- Applied filters as early as possible for efficiency.
- Used meaningful aliases and column names for readability.
- Included comments in each SQL file to explain non-obvious logic.
- Avoided hardcoding or guesswork — relied on schema flags and business meaning.

---

## Repository Structure

```text
DataAnalytics-Assessment/
├── Assessment_Q1.sql   -- Customers with at least one savings and investment plans
├── Assessment_Q2.sql   -- Frequency segmentation based on monthly transactions
├── Assessment_Q3.sql   -- Flag inactive accounts (365+ days without inflow)
├── Assessment_Q4.sql   -- Estimate customer lifetime value (CLV)
└── README.md           -- This file: approach + challenges for each solution
