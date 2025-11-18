-- init/schema.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE accounts (
  account_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  institution TEXT,
  currency TEXT NOT NULL DEFAULT 'INR',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- (paste all the other table definitions: categories, transactions, budgets, recurring_transactions, tags, transaction_tags, indexes, constraints)
