WITH spent AS (
  SELECT category_id, SUM(CASE WHEN amount_cents < 0 THEN -amount_cents ELSE 0 END) AS spent_cents
  FROM transactions
  WHERE txn_date >= DATE '2025-11-01' AND txn_date < DATE '2025-12-01'
  GROUP BY category_id
)
SELECT
  b.year, b.month,
  COALESCE(cat.name, 'Overall') AS category,
  b.amount_cents/100.0 AS budget,
  COALESCE(s.spent_cents,0)/100.0 AS spent,
  (b.amount_cents - COALESCE(s.spent_cents,0))/100.0 AS remaining
FROM budgets b
LEFT JOIN spent s ON b.category_id = s.category_id
LEFT JOIN categories cat ON b.category_id = cat.category_id
WHERE b.year = 2025 AND b.month = 11
ORDER BY COALESCE(cat.name, 'Overall');
