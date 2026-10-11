--Merge Demo
--before
SELECT account_id, account_balance, lchg_time
FROM silver.stg_account
WHERE account_id = 'AC000002';

SELECT count(*) FROM silver.stg_account; --150

-- change source data 
UPDATE bronze.account
SET account_balance = account_balance + 5000,
    lchg_time = now()
WHERE account_id = 'AC000002';

INSERT INTO bronze.account
  (account_id, customer_id, branch_id, account_balance, product_id, schm_type, schm_code, acct_crncy_code)
VALUES ('AC000151', 'C0001', 'BR001', 25000, 'PRD001', 'SA', 'SAV001', 'NPR');


--after incremental merge
SELECT account_id, account_balance, lchg_time
FROM silver.stg_account
WHERE account_id IN ('AC000002', 'AC000151');

SELECT count(*) FROM silver.stg_account;   -- 151


--Demonstrate the append
INSERT INTO bronze.hist_transactional
  (tran_id, account_id, branch_id, tran_amount, tran_crncy, tran_date,
   tran_particular, tran_remarks, created_date, modified_date)
VALUES
  ('TXN0000401', 'AC000002', 'BR008', 1500, 'NPR', current_date,
   'Cash Deposit', 'Deposited at branch counter', now(), now());


SELECT count(*) FROM silver.stg_hist_transactional;   -- 401
SELECT tran_id, dbt_loaded_at FROM silver.stg_hist_transactional
ORDER BY dbt_loaded_at DESC LIMIT 3;

--Output
TXN0000401	2026-10-06 21:49:27.765 +0545
TXN0000003	2026-10-06 18:30:53.671 +0545
TXN0000002	2026-10-06 18:30:53.671 +0545

--Snapshots Demo
SELECT count(*) FROM snapshots.snap_account;   -- 151
SELECT account_id, branch_id, acct_cls_flg, dbt_valid_from, dbt_valid_to
FROM snapshots.snap_account WHERE account_id = 'AC000006';

--update  data 
UPDATE bronze.account
SET acct_cls_flg = 'Y', branch_id = 'BR002', lchg_time = now()
WHERE account_id = 'AC000006';

--For history
SELECT account_id, branch_id, acct_cls_flg, dbt_valid_from, dbt_valid_to
FROM snapshots.snap_account
WHERE account_id = 'AC000006'
ORDER BY dbt_valid_from;

--Output
AC000006	BR012	N	2026-10-06 21:57:24.973	2026-10-06 22:00:41.980
AC000006	BR002	Y	2026-10-06 22:00:41.980	     

