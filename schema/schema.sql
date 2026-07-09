-- ============================================================
-- BANK LEDGER + FRAUD FLAGGING SYSTEM
-- ============================================================

-- ---------- 1. CUSTOMERS ----------
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------- 2. ACCOUNTS ----------
CREATE TABLE accounts (
    account_id      SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES customers(customer_id),
    account_type    VARCHAR(20) NOT NULL CHECK (account_type IN ('savings','checking')),
    balance         NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accounts_customer ON accounts(customer_id);

-- ---------- 3. TRANSACTIONS (the ledger) ----------
CREATE TABLE transactions (
    transaction_id  BIGSERIAL PRIMARY KEY,
    account_id      INT NOT NULL REFERENCES accounts(account_id),
    txn_type        VARCHAR(15) NOT NULL CHECK (txn_type IN ('deposit','withdrawal','transfer_in','transfer_out')),
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    related_account INT REFERENCES accounts(account_id),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_txn_account_time ON transactions(account_id, created_at);

-- ---------- 4. FLAGGED TRANSACTIONS ----------
CREATE TABLE flagged_transactions (
    flag_id         SERIAL PRIMARY KEY,
    transaction_id  BIGINT NOT NULL REFERENCES transactions(transaction_id),
    rule_triggered  VARCHAR(100) NOT NULL,
    flagged_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed        BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------- 5. AUDIT LOG ----------
CREATE TABLE audit_log (
    audit_id        BIGSERIAL PRIMARY KEY,
    table_name      VARCHAR(50) NOT NULL,
    operation       VARCHAR(10) NOT NULL,
    record_id       BIGINT NOT NULL,
    changed_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    details         JSONB
);
