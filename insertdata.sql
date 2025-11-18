-- SELECT table_schema, table_name
-- FROM information_schema.tables
-- WHERE table_schema NOT IN ('pg_catalog','information_schema')
-- ORDER BY table_schema, table_name;
-- init/seed_full.sql
-- Safe to run multiple times (uses INSERT ... ON CONFLICT for tags)
BEGIN;

-- ACCOUNTS
INSERT INTO accounts (name, institution, currency)
VALUES
  ('Checking', 'MyBank', 'INR'),
  ('Credit Card', 'CardCo', 'INR'),
  ('Cash', 'Pocket', 'INR')
ON CONFLICT DO NOTHING;

-- CATEGORIES (income & expense)
INSERT INTO categories (name, type) VALUES
  ('Salary','income'),
  ('Interest','income'),
  ('Groceries','expense'),
  ('Dining Out','expense'),
  ('Rent','expense'),
  ('Transport','expense'),
  ('Entertainment','expense'),
  ('Utilities','expense')
ON CONFLICT DO NOTHING;

-- TAGS (use unique constraint)
INSERT INTO tags (name) VALUES
  ('work'),
  ('food'),
  ('monthly'),
  ('travel'),
  ('entertainment'),
  ('bills')
ON CONFLICT (name) DO NOTHING;

-- BUDGETS (per month)
-- Example: budgets for November 2025
INSERT INTO budgets (year, month, category_id, amount_cents)
VALUES
  (2025, 11, (SELECT category_id FROM categories WHERE name='Groceries' LIMIT 1), 40000),   -- ₹400.00
  (2025, 11, (SELECT category_id FROM categories WHERE name='Dining Out' LIMIT 1), 10000),  -- ₹100.00
  (2025, 11, NULL, 200000)  -- overall monthly budget ₹2,000.00
ON CONFLICT (year, month, category_id) DO NOTHING;

-- RECURRING TRANSACTIONS
-- Salary (monthly, on day 1)
INSERT INTO recurring_transactions (account_id, category_id, amount_cents, start_date, frequency, day_of_month, next_run, description, active)
VALUES (
  (SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1),
  (SELECT category_id FROM categories WHERE name='Salary' LIMIT 1),
  500000, -- ₹5,000.00 salary
  DATE '2025-01-01',
  'monthly',
  1,
  DATE '2025-12-01',
  'Monthly salary',
  TRUE
)
ON CONFLICT DO NOTHING;

-- Rent (monthly, on day 3)
INSERT INTO recurring_transactions (account_id, category_id, amount_cents, start_date, frequency, day_of_month, next_run, description, active)
VALUES (
  (SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1),
  (SELECT category_id FROM categories WHERE name='Rent' LIMIT 1),
  -200000, -- -₹2,000.00 rent
  DATE '2025-01-01',
  'monthly',
  3,
  DATE '2025-12-03',
  'Monthly rent',
  TRUE
)
ON CONFLICT DO NOTHING;

-- SAMPLE TRANSACTIONS (some income, many expenses)
-- Use subqueries to pick category_id and account_id (keeps file id-agnostic)
INSERT INTO transactions (account_id, category_id, amount_cents, txn_date, description, cleared)
VALUES
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Salary' LIMIT 1), 500000, '2025-11-01', 'November salary', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Rent' LIMIT 1), -200000, '2025-11-03', 'Monthly rent', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Groceries' LIMIT 1), -2345, '2025-11-02', 'Supermarket', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Credit Card' LIMIT 1), (SELECT category_id FROM categories WHERE name='Dining Out' LIMIT 1), -1200, '2025-11-05', 'Cafe with friends', FALSE),
  ((SELECT account_id FROM accounts WHERE name='Cash' LIMIT 1), (SELECT category_id FROM categories WHERE name='Transport' LIMIT 1), -150, '2025-11-04', 'Bus fare', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Utilities' LIMIT 1), -4500, '2025-11-10', 'Electricity bill', FALSE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Entertainment' LIMIT 1), -799, '2025-11-12', 'Movie', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Groceries' LIMIT 1), -5230, '2025-10-25', 'Grocery trip', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Credit Card' LIMIT 1), (SELECT category_id FROM categories WHERE name='Dining Out' LIMIT 1), -950, '2025-10-28', 'Dinner out', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Interest' LIMIT 1), 120, '2025-10-15', 'Bank interest', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Cash' LIMIT 1), (SELECT category_id FROM categories WHERE name='Transport' LIMIT 1), -300, '2025-09-20', 'Taxi', TRUE),
  ((SELECT account_id FROM accounts WHERE name='Checking' LIMIT 1), (SELECT category_id FROM categories WHERE name='Entertainment' LIMIT 1), -1500, '2025-09-05', 'Concert ticket', TRUE)
;

-- LINK SOME TAGS TO A FEW TRANSACTIONS (pick a few rows by matching description)
-- This uses transaction ids found by description; safe if descriptions unique
INSERT INTO transaction_tags (transaction_id, tag_id)
SELECT t.transaction_id, tag.tag_id
FROM transactions t
JOIN tags tag ON tag.name = 'work'
WHERE t.description ILIKE '%salary%'
ON CONFLICT DO NOTHING;

INSERT INTO transaction_tags (transaction_id, tag_id)
SELECT t.transaction_id, tag.tag_id
FROM transactions t
JOIN tags tag ON tag.name = 'food'
WHERE t.description ILIKE '%cafe%' OR t.description ILIKE '%dinner%' OR t.description ILIKE '%restaurant%'
ON CONFLICT DO NOTHING;

INSERT INTO transaction_tags (transaction_id, tag_id)
SELECT t.transaction_id, tag.tag_id
FROM transactions t
JOIN tags tag ON tag.name = 'bills'
WHERE t.description ILIKE '%bill%' OR t.description ILIKE '%electricity%' OR t.description ILIKE '%rent%'
ON CONFLICT DO NOTHING;

COMMIT;
