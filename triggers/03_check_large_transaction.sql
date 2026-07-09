-- ============================================================
-- TRIGGER 3: Fraud rule — amount > 10x account's historical average
-- ============================================================
CREATE OR REPLACE FUNCTION check_large_transaction()
RETURNS TRIGGER AS $$
DECLARE
    avg_amount NUMERIC;
BEGIN
    SELECT AVG(amount) INTO avg_amount
    FROM transactions
    WHERE account_id = NEW.account_id
      AND transaction_id != NEW.transaction_id;

    IF avg_amount IS NOT NULL AND NEW.amount > 10 * avg_amount THEN
        INSERT INTO flagged_transactions (transaction_id, rule_triggered)
        VALUES (NEW.transaction_id, 'amount_10x_average');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_large_transaction
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION check_large_transaction();
