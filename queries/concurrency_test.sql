-- ============================================================
-- CONCURRENCY TEST: PREVENTING LOST UPDATES (FOR UPDATE LOCK)
-- ============================================================
/*
This test proves that the `SELECT ... FOR UPDATE` lock prevents a race condition
where two concurrent transfers could theoretically both read a stale balance and 
pass the sufficient-funds check before either transaction commits.

INSTRUCTIONS:
1. Open TWO separate pgAdmin Query Tool tabs (representing two concurrent app sessions).
2. Run the "SETUP" block in Tab 1 to create a fresh test account.
3. Replace `<test_account_id>` and `<test_dest_account_id>` in BOTH tabs with the IDs printed from the setup block.
4. Execute "STEP 1" in Tab 1 (Starts transaction and acquires lock).
5. Execute "STEP 2" in Tab 2 (Attempts concurrent transfer). Notice it hangs! ("waiting...")
6. Execute "STEP 3" in Tab 1 (Commits).
7. Notice Tab 2 immediately unblocks and throws the "Insufficient funds" constraint violation.
*/

-- ============================================================
-- SETUP (Run in Tab 1)
-- ============================================================
INSERT INTO customers (full_name, email) VALUES ('Concurrency Tester', 'test_' || NOW()::TEXT || '@example.com') RETURNING customer_id;
-- Note the customer_id. For this example, let's say it's 9999.
INSERT INTO accounts (customer_id, account_type, balance) VALUES (9999, 'checking', 1000) RETURNING account_id; -- Source account
INSERT INTO accounts (customer_id, account_type, balance) VALUES (9999, 'savings', 0) RETURNING account_id;  -- Destination account


-- ============================================================
-- TAB 1: FIRST WORKER
-- ============================================================
-- STEP 1: Begin and acquire lock
BEGIN;

-- Lock the source account
SELECT balance FROM accounts WHERE account_id = <test_account_id> FOR UPDATE;
-- (Application would normally check balance here in memory, but we'll proceed assuming balance >= 600)

INSERT INTO transactions (account_id, txn_type, amount, related_account)
VALUES (<test_account_id>, 'transfer_out', 600, <test_dest_account_id>);

INSERT INTO transactions (account_id, txn_type, amount, related_account)
VALUES (<test_dest_account_id>, 'transfer_in', 600, <test_account_id>);

-- DO NOT COMMIT YET. Go to Tab 2 and run STEP 2.

-- STEP 3: Commit the transaction
COMMIT;


-- ============================================================
-- TAB 2: SECOND CONCURRENT WORKER
-- ============================================================
-- STEP 2: Attempt concurrent transfer
BEGIN;

-- This will HANG and wait for Tab 1 to commit/rollback!
SELECT balance FROM accounts WHERE account_id = <test_account_id> FOR UPDATE;

-- Once Tab 1 commits, this unblocks. The new balance is $400.
-- If the application layer didn't re-check the balance, it might still insert:
INSERT INTO transactions (account_id, txn_type, amount, related_account)
VALUES (<test_account_id>, 'transfer_out', 600, <test_dest_account_id>);
-- ^^^ THIS WILL FAIL due to the `balance >= 0` check constraint on `accounts`, 
-- proving the defense-in-depth works. 

ROLLBACK;

-- ============================================================
-- VERIFICATION (Run in Tab 1 after Tab 2 finishes)
-- ============================================================
-- Final balance should be $400, not -$200.
SELECT account_id, balance FROM accounts WHERE account_id = <test_account_id>;

/*
Why FOR UPDATE instead of SERIALIZABLE isolation level?
- SERIALIZABLE would throw a serialization anomaly error when the second transaction attempts to commit. The application would have to catch this specific error and retry the entire transaction from the beginning.
- FOR UPDATE (Pessimistic Locking) simply forces the second transaction to wait. Once the lock is released, it reads the freshest data. This avoids deadlocks across the entire table and requires far less retry logic in the application tier, making it better for high-throughput pinpoint operations like ledger transfers.
*/
