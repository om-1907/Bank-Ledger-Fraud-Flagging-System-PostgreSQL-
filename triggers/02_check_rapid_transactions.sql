-- ============================================================
-- TRIGGER 2: Fraud rule — rapid transactions (>=3 in trailing 60s)
-- ============================================================
CREATE OR REPLACE FUNCTION check_rapid_transactions()
RETURNS TRIGGER AS $$
DECLARE
    recent_count INT;
BEGIN
    SELECT COUNT(*) INTO recent_count
    FROM transactions
    WHERE account_id = NEW.account_id
      AND created_at >= NEW.created_at - INTERVAL '60 seconds'
      AND transaction_id != NEW.transaction_id;

    IF recent_count >= 3 THEN
        INSERT INTO flagged_transactions (transaction_id, rule_triggered)
        VALUES (NEW.transaction_id, 'rapid_transactions_60s');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_rapid_transactions
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION check_rapid_transactions();
