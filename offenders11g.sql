-- offenders11g.sql
-- This script consists of 3 queries to be used in sequence. 
-- Originally for Oracle 11g. 

-- 
-- Query 1
-- Find SQL IDs from the 20 highest exec time queries
-- XMLAGG is used instead of LISTAGG because of ORA-01489
-- ---------------------------------------------------------------------------

-- Setup when on SQL*Plus
SET LIN 160 PAGES 100
SET LONG 210
COL SQL_IDS           FOR A70
COL SQL_FULLTEXT      FOR A160
COL PLAN_TABLE_OUTPUT FOR A160

SELECT * 
FROM (
  SELECT PLAN_HASH_VALUE
     , COUNT(1)               AS NUM_SQLS
     , SUM(ROWS_PROCESSED)    AS SUM_ROWS
     , SUM(EXECUTIONS)        AS SUM_EXECS
     , SUM(CPU_TIME)          AS SUM_CPUTIME
     , SUM(ELAPSED_TIME)      AS SUM_ELAPTIME
     , CASE 
      WHEN SUM(executions) = 0 THEN -1 
      ELSE Round( SUM(elapsed_time)/Sum(executions), 3 ) END 
     AS AVG_TIME
     , XMLAGG(xmlelement(e,SQL_ID,',').extract('//text()') 
       ORDER BY ELAPSED_TIME DESC)
     AS SQL_IDS
  FROM  V$SQLSTATS
  GROUP BY PLAN_HASH_VALUE
  ORDER BY SUM(ELAPSED_TIME) DESC
) S
WHERE ROWNUM < 20;

-- 
-- Query 2
-- List the full query from previous step
-- ---------------------------------------------------------------------------
SET LONG 9999

SELECT SQL_FULLTEXT FROM V$SQLSTATS WHERE SQL_ID = '&SQLID_FROM_QUERY_1';

-- 
-- Query 3
-- Show the cached execution plan for the query
-- ---------------------------------------------------------------------------
SELECT PLAN_TABLE_OUTPUT FROM table(DBMS_XPLAN.DISPLAY_CURSOR('&SQLID_FROM_QUERY_1'));
