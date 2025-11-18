-- Monthly summary for a month (change the date to the month you want)
WITH month_bounds AS (
  SELECT date_trunc('month', DATE '2025-11-01')::date AS start_date,
         (date_trunc('month', DATE '2025-11-01') + INTERVAL '1 month')::date AS end_date
)
SELECT
  SUM(CASE WHEN amount_cents > 0 THEN amount_cents ELSE 0 END)/100.0 AS income,
  SUM(CASE WHEN amount_cents < 0 THEN -amount_cents ELSE 0 END)/100.0 AS expense,
  (SUM(amount_cents))/100.0 AS net
FROM transactions, month_bounds
WHERE txn_date >= month_bounds.start_date
  AND txn_date < month_bounds.end_date;
