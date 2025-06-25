--liquibase formatted sql

--changeset sihan:create-test-base-table
-- DROP TABLE test_base CASCADE CONSTRAINTS PURGE;

CREATE TABLE test_base (
  id   NUMBER,
  name VARCHAR2(50)
);

--changeset sihan:insert-test-data-1
INSERT INTO test_base VALUES (1, 'hello');
COMMIT;

--changeset sihan:create-test-mv
-- DROP MATERIALIZED VIEW test_mv;

CREATE MATERIALIZED VIEW test_mv
BUILD IMMEDIATE
REFRESH ON DEMAND
AS
SELECT * FROM test_base;

--changeset sihan:insert-test-data-2
INSERT INTO test_base VALUES (2, 'world');
COMMIT;
