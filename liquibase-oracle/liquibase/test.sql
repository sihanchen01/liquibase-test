--liquibase formatted sql

--changeset sihan:test-run-proc
--comment: Call my Oracle stored procedure
BEGIN
  test_user.my_procedure('hello from liquibase');
END;
/

--changeset sihan:test-run-proc2
--comment: Call my Oracle stored procedure
BEGIN
  DBMS_OUTPUT.PUT_LINE('Start');
  test_user.my_procedure('hello again');
  DBMS_OUTPUT.PUT_LINE('Done');
END;
/


--changeset sihan:test-run-proc3
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dual;
  DBMS_OUTPUT.PUT_LINE(v_count);
END;
/
