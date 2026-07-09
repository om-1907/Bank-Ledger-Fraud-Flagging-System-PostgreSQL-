-- ============================================================
-- TRIGGER 1: Maintain account balance
-- ============================================================
CREATE OR REPLACE FUNCTION apply_transaction()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.txn_type IN ('deposit','transfer_in') THEN
        UPDATE accounts SET balance = balance + NEW.amount WHERE account_id = NEW.account_id;
    ELSIF NEW.txn_type IN ('withdrawal','transfer_out') THEN
        UPDATE accounts SET balance = balance - NEW.amount WHERE account_id = NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_apply_transaction
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION apply_transaction();
