-- ============================================================
-- PURE SQL DATA GENERATION (SEED SCRIPT)
-- ============================================================
-- This script uses PostgreSQL's generate_series() and random() 
-- functions to generate thousands of realistic rows for benchmarking.

DO $$
BEGIN
    -- 1. Insert 5000 Customers
    INSERT INTO customers (full_name, email, created_at)
    SELECT 
        'Customer ' || gs,
        'customer' || gs || '@example.com',
        NOW() - (random() * interval '365 days')
    FROM generate_series(1, 5000) AS gs;

    -- 2. Insert Accounts (1 Checking, 1 Savings per customer)
    -- Initialize with balance = 0 so triggers keep ledger in sync
    -- Checking
    INSERT INTO accounts (customer_id, account_type, balance, created_at)
    SELECT 
        customer_id, 
        'checking', 
        0::NUMERIC(14,2), 
        created_at + interval '1 day'
    FROM customers;
    
    -- Savings
    INSERT INTO accounts (customer_id, account_type, balance, created_at)
    SELECT 
        customer_id, 
        'savings', 
        0::NUMERIC(14,2), 
        created_at + interval '1 day'
    FROM customers;

    -- 3. Insert Normal Transactions (Deposits first to build balance)
    -- 10 Deposits per account
    INSERT INTO transactions (account_id, txn_type, amount, created_at)
    SELECT 
        account_id,
        'deposit',
        (random() * 500 + 100)::NUMERIC(14,2),
        created_at + (random() * interval '15 days')
    FROM accounts, generate_series(1, 10);

    -- 5 Withdrawals per account
    INSERT INTO transactions (account_id, txn_type, amount, created_at)
    SELECT 
        account_id,
        'withdrawal',
        (random() * 100 + 10)::NUMERIC(14,2),
        created_at + interval '15 days' + (random() * interval '15 days')
    FROM accounts, generate_series(1, 5);

    -- 4. Trigger Rapid Transactions Fraud Rule on Account 1
    INSERT INTO transactions (account_id, txn_type, amount, created_at)
    VALUES 
        (1, 'withdrawal', 10, NOW() - interval '10 seconds'),
        (1, 'withdrawal', 10, NOW() - interval '8 seconds'),
        (1, 'withdrawal', 10, NOW() - interval '5 seconds'),
        (1, 'withdrawal', 10, NOW() - interval '2 seconds');

    -- 5. Trigger Large Transaction Fraud Rule on Account 2
    INSERT INTO transactions (account_id, txn_type, amount, created_at)
    VALUES 
        (2, 'deposit', 500000, NOW());

END $$;

-- ============================================================
-- VERIFICATION QUERIES (Run these separately after the block)
-- ============================================================
-- 1. Check row counts
/*
SELECT 'customers' AS table, COUNT(*) FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'flagged_transactions', COUNT(*) FROM flagged_transactions
UNION ALL SELECT 'audit_log', COUNT(*) FROM audit_log;
*/

-- 2. Verify Ledger vs Balance (Should return 0 rows!)
/*
WITH calculated_ledger AS (
    SELECT 
        account_id,
        SUM(CASE WHEN txn_type IN ('deposit','transfer_in') THEN amount ELSE -amount END) AS ledger_balance
    FROM transactions
    GROUP BY account_id
)
SELECT a.account_id, a.balance AS account_balance, cl.ledger_balance 
FROM accounts a
JOIN calculated_ledger cl ON a.account_id = cl.account_id
WHERE a.balance != cl.ledger_balance;
*/
