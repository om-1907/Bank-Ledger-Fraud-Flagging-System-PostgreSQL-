-- ============================================================
-- TRIGGER 4: Audit log every insert on transactions
-- ============================================================
CREATE OR REPLACE FUNCTION log_transaction_audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, details)
    VALUES ('transactions', 'INSERT', NEW.transaction_id, to_jsonb(NEW));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_transaction_audit
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION log_transaction_audit();
