-- init/create_missing.sql
-- Safe: uses IF NOT EXISTS so it won't break existing tables.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- categories
CREATE TABLE IF NOT EXISTS categories (
  category_id    BIGSERIAL PRIMARY KEY,
  name           TEXT NOT NULL,
  type           TEXT NOT NULL CHECK (type IN ('expense','income')),
  parent_id      BIGINT REFERENCES categories(category_id) ON DELETE SET NULL
);

-- transactions
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id BIGSERIAL PRIMARY KEY,
  account_id     BIGINT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
  category_id    BIGINT REFERENCES categories(category_id),
  amount_cents   BIGINT NOT NULL,
  txn_date       DATE NOT NULL,
  description    TEXT,
  created_at     TIMESTAMP WITH TIME ZONE DEFAULT now(),
  cleared        BOOLEAN DEFAULT FALSE
);

-- budgets
CREATE TABLE IF NOT EXISTS budgets (
  budget_id      BIGSERIAL PRIMARY KEY,
  year           INT NOT NULL,
  month          INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  category_id    BIGINT REFERENCES categories(category_id),
  amount_cents   BIGINT NOT NULL CHECK (amount_cents >= 0),
  created_at     TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (year, month, category_id)
);

-- recurring_transactions
CREATE TABLE IF NOT EXISTS recurring_transactions (
  recur_id         BIGSERIAL PRIMARY KEY,
  account_id       BIGINT NOT NULL REFERENCES accounts(account_id),
  category_id      BIGINT REFERENCES categories(category_id),
  amount_cents     BIGINT NOT NULL,
  start_date       DATE NOT NULL,
  end_date         DATE,
  frequency        TEXT NOT NULL,
  day_of_month     INT,
  weekday          INT,
  next_run         DATE,
  description      TEXT,
  active           BOOLEAN DEFAULT TRUE,
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- tags and transaction_tags
CREATE TABLE IF NOT EXISTS tags (
  tag_id    BIGSERIAL PRIMARY KEY,
  name      TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS transaction_tags (
  transaction_id BIGINT REFERENCES transactions(transaction_id) ON DELETE CASCADE,
  tag_id         BIGINT REFERENCES tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (transaction_id, tag_id)
);

-- Indexes (create if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_transactions_txn_date'
  ) THEN
    CREATE INDEX idx_transactions_txn_date ON transactions(txn_date);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_transactions_account'
  ) THEN
    CREATE INDEX idx_transactions_account ON transactions(account_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_transactions_category'
  ) THEN
    CREATE INDEX idx_transactions_category ON transactions(category_id);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_budgets_year_month'
  ) THEN
    CREATE INDEX idx_budgets_year_month ON budgets(year, month);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_recur_next_run'
  ) THEN
    CREATE INDEX idx_recur_next_run ON recurring_transactions(next_run);
  END IF;
END
$$;

-- Helpful check constraints (if not present)
-- Add a check for transactions.amount_cents nonzero
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_amount_nonzero'
  ) THEN
    ALTER TABLE transactions
      ADD CONSTRAINT chk_amount_nonzero CHECK (amount_cents <> 0);
  END IF;
EXCEPTION WHEN undefined_table THEN
  -- if transactions table doesn't exist yet, ignore
  RAISE NOTICE 'transactions table missing when adding chk_amount_nonzero, skip';
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_recur_amount_nonzero'
  ) THEN
    ALTER TABLE recurring_transactions
      ADD CONSTRAINT chk_recur_amount_nonzero CHECK (amount_cents <> 0);
  END IF;
EXCEPTION WHEN undefined_table THEN
  RAISE NOTICE 'recurring_transactions missing when adding chk_recur_amount_nonzero, skip';
END
$$;
