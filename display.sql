-- 1) Counts per table
SELECT 'accounts' AS table_name, count(*) FROM accounts
UNION ALL
SELECT 'categories', count(*) FROM categories
UNION ALL
SELECT 'transactions', count(*) FROM transactions
UNION ALL
SELECT 'budgets', count(*) FROM budgets
UNION ALL
SELECT 'recurring_transactions', count(*) FROM recurring_transactions
UNION ALL
SELECT 'tags', count(*) FROM tags
UNION ALL
SELECT 'transaction_tags', count(*) FROM transaction_tags;

-- 2) Recent transactions (last 20)
SELECT t.transaction_id, a.name AS account, c.name AS category, t.amount_cents/100.0 AS amount, t.txn_date, t.description
FROM transactions t
LEFT JOIN accounts a ON t.account_id = a.account_id
LEFT JOIN categories c ON t.category_id = c.category_id
ORDER BY t.txn_date DESC
LIMIT 20;

-- 3) Sample budgets
SELECT b.year, b.month, COALESCE(cat.name, 'Overall') AS category, b.amount_cents/100.0 AS budget
FROM budgets b
LEFT JOIN categories cat ON b.category_id = cat.category_id
ORDER BY b.year, b.month;
