-- ============================================================
-- SAMPLE DATA
-- ============================================================
INSERT INTO customers (full_name, email) VALUES
('Om Patel', 'om@example.com'),
('Asha Rao', 'asha@example.com');

INSERT INTO accounts (customer_id, account_type, balance) VALUES
(1, 'checking', 5000),
(2, 'savings', 2000);

-- ============================================================
-- SAFE TRANSFER (atomic, wrapped in a transaction)
-- ============================================================
BEGIN;

SELECT balance FROM accounts WHERE account_id = 1 FOR UPDATE;

INSERT INTO transactions (account_id, txn_type, amount, related_account)
VALUES (1, 'transfer_out', 500, 2);

INSERT INTO transactions (account_id, txn_type, amount, related_account)
VALUES (2, 'transfer_in', 500, 1);

COMMIT;

-- ============================================================
-- QUERY: View flagged transactions with context
-- ============================================================
SELECT
    ft.flag_id,
    ft.rule_triggered,
    t.transaction_id,
    t.account_id,
    t.amount,
    t.created_at
FROM flagged_transactions ft
JOIN transactions t ON t.transaction_id = ft.transaction_id
ORDER BY ft.flagged_at DESC;

-- ============================================================
-- QUERY: Rapid transaction fraud trigger demo
-- ============================================================
INSERT INTO transactions (account_id, txn_type, amount) VALUES (1, 'withdrawal', 50);
INSERT INTO transactions (account_id, txn_type, amount) VALUES (1, 'withdrawal', 50);
INSERT INTO transactions (account_id, txn_type, amount) VALUES (1, 'withdrawal', 50);
INSERT INTO transactions (account_id, txn_type, amount) VALUES (1, 'withdrawal', 50);

-- ============================================================
-- QUERY: Large-amount fraud trigger demo
-- ============================================================
INSERT INTO transactions (account_id, txn_type, amount) VALUES (1, 'deposit', 100000);

-- ============================================================
-- WINDOW FUNCTION: running balance per account
-- ============================================================
SELECT
    account_id,
    transaction_id,
    txn_type,
    amount,
    created_at,
    SUM(
        CASE WHEN txn_type IN ('deposit','transfer_in') THEN amount ELSE -amount END
    ) OVER (PARTITION BY account_id ORDER BY created_at, transaction_id) AS running_balance
FROM transactions
ORDER BY account_id, created_at;

-- ============================================================
-- EXPLAIN ANALYZE demo: index impact on lookup by account_id
-- ============================================================
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE account_id = 1
ORDER BY created_at DESC
LIMIT 20;
