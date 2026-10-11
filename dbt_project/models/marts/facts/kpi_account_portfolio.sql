with accounts as (
    select
        f.account_id, f.customer_id, f.is_active, f.account_balance, f.lien_amt,
        p.product_group,
        b.province, b.branch_name
    from {{ ref('fct_account_balance') }} f
    join {{ ref('dim_product') }} p on f.product_id = p.product_id
    join {{ ref('dim_branch') }}  b on f.branch_id  = b.branch_id
)

select
    coalesce(province, 'ALL PROVINCES')   as province,
    coalesce(branch_name, 'ALL BRANCHES') as branch_name,

    -- KPI 1: CASA Ratio = (CA + SA) / (CA + SA + TD)
    round(
        sum(account_balance) filter (where product_group = 'CASA' and is_active)
        / nullif(sum(account_balance) filter (where product_group in ('CASA','TERM_DEPOSIT') and is_active), 0)
    , 4) as casa_ratio,

    -- KPI 2: Total Deposits
    sum(account_balance) filter (where product_group in ('CASA','TERM_DEPOSIT') and is_active) as total_deposits,

    -- KPI 3: Loan Portfolio
    sum(abs(account_balance)) filter (where product_group = 'LOAN' and is_active) as loan_portfolio,

    -- KPI 4: Loan-to-Deposit Ratio
    round(
        sum(abs(account_balance)) filter (where product_group = 'LOAN' and is_active)
        / nullif(sum(account_balance) filter (where product_group in ('CASA','TERM_DEPOSIT') and is_active), 0)
    , 4) as loan_to_deposit_ratio,

    -- KPI 5: Account Closure Rate
    round(count(*) filter (where not is_active)::numeric / nullif(count(*), 0), 4) as account_closure_rate,

    -- KPI 6: Lien Ratio
    round(
        sum(lien_amt) filter (where product_group in ('CASA','TERM_DEPOSIT') and is_active)
        / nullif(sum(account_balance) filter (where product_group in ('CASA','TERM_DEPOSIT') and is_active), 0)
    , 4) as lien_ratio,

    -- KPI 7: Average Deposit per Customer
    round(
        sum(account_balance) filter (where product_group in ('CASA','TERM_DEPOSIT') and is_active)
        / nullif(count(distinct customer_id), 0)
    , 2) as avg_deposit_per_customer,

    -- KPI 8: Average Accounts per Customer
    round(count(*)::numeric / nullif(count(distinct customer_id), 0), 2) as avg_accounts_per_customer
from accounts
group by rollup (province, branch_name)