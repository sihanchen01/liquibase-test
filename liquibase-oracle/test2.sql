--liquibase formatted sql
--changeset sihan:refresh-test-mv
BEGIN
  DBMS_MVIEW.REFRESH('TEST_MV', 'C');
END;
/
