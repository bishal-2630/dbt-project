# DBT Banking Data Engineering Project

Builds a Bronze, Silver and Gold pipeline with dbt and PostgreSQL on a banking dataset (customers, branches, products, accounts, cards and transactions). It cleans the raw data, loads one table with incremental MERGE and another with incremental APPEND, keeps account history with a snapshot, models dimensions and facts, calculates 13 banking KPIs including the required CASA Ratio, and checks quality with 21 tests.

## Bronze Layer

The provided insert.sql is loaded by insert_to_postgres.py, which I changed to use a schema named bronze instead of public. The six raw tables are customer, branch, product, account, card and hist_transactional. No transformations are applied here. They are declared in models/staging/sources.yml and read with source() in every model.

## Silver Layer

Six staging models clean the Bronze data with TRIM, UPPER, LOWER and INITCAP, type casting, null handling, duplicate handling and validation flags. Bad rows are flagged instead of deleted. Examples: stg_customer validates phones and emails and flags foreign nationals, stg_product adds product_group (CASA, TERM_DEPOSIT, LOAN), stg_card masks card numbers and flags expired cards, and stg_account checks that its product details match the product table. A small macro (macros/generate_schema_name.sql) makes dbt create the schemas exactly as silver and gold.

## Incremental MERGE

stg_account uses the merge strategy with account_id as the unique key. The first run loads all 150 accounts. Later runs only read rows whose lchg_time is newer than the maximum already loaded, then update existing accounts and insert new ones.
Proof: after changing AC000002 and adding AC000151 in Bronze, the run logged a MERGE and the count went from 150 to 151 (not 152), so the update matched on account_id. A run with no changes logged MERGE 0.

## Incremental APPEND

stg_hist_transactional uses the append strategy. Because append cannot update or de-duplicate, the filter only takes rows with a newer created_date whose tran_id is not already loaded.
Proof: after adding TXN0000401 in Bronze, only that row was appended (400 to 401). A run with no new data logged INSERT 0 0.

## Snapshot

snap_account uses the check strategy on account_balance, acct_cls_flg, branch_id and product_id. After closing AC000006 and moving it from BR012 to BR002, the snapshot holds two rows for it: the old version (BR012, flag N) with a dbt_valid_to timestamp, and the new version (BR002, flag Y) with dbt_valid_to empty. Both versions are preserved.

## Gold Layer and KPIs

The Gold layer is in models/marts. The dimensions folder has dim_customer, dim_branch, dim_product, dim_account and dim_card. The facts folder has fct_account_balance, fct_transactions and two KPI models. Everything reads from Silver or other Gold models, never from Bronze.

kpi_account_portfolio holds KPIs 1 to 8 by branch, province and whole bank (using GROUP BY ROLLUP): CASA Ratio, Total Deposits, Loan Portfolio, Loan-to-Deposit Ratio, Account Closure Rate, Lien Ratio, Average Deposit per Customer and Average Accounts per Customer. kpi_transactions_monthly holds KPIs 9 to 13 by month: Transaction Volume and Value, Net Cash Flow, Digital Transaction Share, Remittance Inflow and Fee Income.

CASA Ratio is calculated as (CA + SA) / (CA + SA + TD), counting active accounts. The bank-wide result is 0.4189 (41.89%), with total deposits of 39,575,600.66, a loan portfolio of 11,374,266.90 and a loan-to-deposit ratio of 0.2874.

## Data Quality Tests

models/staging/schema.yml defines 21 tests (unique, not_null, accepted_values, relationships), and all pass. A full dbt build passes with 37 results: 13 table models, 2 incremental models, 1 snapshot and 21 tests.

## Assumptions

Term deposit (TD) is treated as FD plus RD. Balances are summed as stored with no currency conversion, so monetary KPIs mix currencies. Debit and credit are derived from tran_particular because amounts are always positive (Mobile Banking Transfer counts as a debit), and channels are derived the same way. Only active accounts count in deposit and loan KPIs.

## Deliberate Changes to Bronze

To demonstrate the incremental models and snapshot, I raised the balance of AC000002 by 5000, added account AC000151, added transaction TXN0000401, and closed AC000006 and moved it to BR002. Bronze now has 151 accounts and 401 transactions.

## Challenges Faced

The loader script created tables in public instead of bronze, so it needed editing. dbt rejected the hyphen in the project name, so I ran dbt init as dbt_project inside my dbt-project folder. Without a macro, dbt named the schemas dbt_dev_silver and dbt_dev_gold. Most other errors were small paste mistakes, like a missing end in a CASE or a lost endif in a Jinja block.

## Project Files

1. insert.sql: creates and fills the six source tables.
2. insert_to_postgres.py: loads insert.sql into the bronze schema.
3. .env: database credentials (not committed).
4. dbt_project/dbt_project.yml: project configuration.
5. dbt_project/macros/generate_schema_name.sql: schema naming macro.
6. dbt_project/snapshots/snap_account.sql: account snapshot.
7. dbt*project/models/staging/: sources.yml, schema.yml (tests) and the six stg* models.
8. dbt*project/models/marts/dimensions/: the five dim* models.
9. dbt*project/models/marts/facts/: the two fct* models and the two kpi models.
10. screenshots/: proof of MERGE, APPEND, snapshot, CASA result, tests and lineage graph.
11. demo.sql: manual demo queries used to show MERGE, APPEND and the snapshot.

## Setup

1. Install PostgreSQL 15 or higher (MERGE needs it).
2. Create and activate a virtual environment.
3. Run pip install psycopg2-binary python-dotenv dbt-postgres.
4. Create a .env file next to insert_to_postgres.py with PGHOST, PGPORT, PGDATABASE, PGUSER and PGPASSWORD.
5. Add a profile named dbt_project to profiles.yml in your user .dbt folder, pointing to the same database with schema dbt_dev.

## How to Run

1. Activate the virtual environment.
2. Run python insert_to_postgres.py --drop to load the six tables into the bronze schema. Check the counts: 50, 30, 15, 150, 60 and 400.
3. Go into the project folder with cd dbt_project.
4. Run dbt debug and confirm that all checks pass.
5. Run dbt build to run the models, snapshot and tests in order.
6. Check the results in PostgreSQL, for example the CASA Ratio in gold.kpi_account_portfolio on the row where province is ALL PROVINCES.
7. Run dbt docs generate, then dbt docs serve, and open the lineage graph in the browser.
