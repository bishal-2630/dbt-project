{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'append',
    on_schema_change     = 'append_new_columns'
) }}

with src as (
    select * from {{ source('bronze', 'hist_transactional') }} s
    {% if is_incremental() %}
    where s.created_date > (select max(created_date) from {{ this }})
      and not exists (
          select 1 from {{ this }} t where t.tran_id = upper(trim(s.tran_id))
      )
    {% endif %}
),

cleaned as (
    select
        upper(trim(tran_id))            as tran_id,
        upper(trim(account_id))         as account_id,
        upper(trim(branch_id))          as branch_id,
        tran_amount::numeric(15,2)      as tran_amount,
        upper(trim(tran_crncy))         as currency_code,
        tran_date::date                 as tran_date,
        upper(trim(tran_particular))    as tran_particular,
        trim(tran_remarks)              as tran_remarks,
        created_date,
        modified_date,
        case
            when upper(trim(tran_particular)) in (
                'FUND TRANSFER - INWARD', 'REMITTANCE CREDIT', 'INTEREST CREDIT',
                'SALARY CREDIT', 'CASH DEPOSIT', 'CHEQUE DEPOSIT') then 'CREDIT'
            else 'DEBIT'
        end as tran_direction,
        case
            when upper(trim(tran_particular)) = 'ATM WITHDRAWAL' then 'ATM'
            when upper(trim(tran_particular)) = 'POS PURCHASE' then 'POS'
            when upper(trim(tran_particular)) in ('CASH DEPOSIT', 'CASH WITHDRAWAL',
                 'CHEQUE DEPOSIT', 'CHEQUE WITHDRAWAL') then 'BRANCH'
            when upper(trim(tran_particular)) in ('MOBILE BANKING TRANSFER',
                 'FUND TRANSFER - INWARD', 'FUND TRANSFER - OUTWARD', 'UTILITY BILL PAYMENT') then 'DIGITAL'
            else 'SYSTEM'
        end as tran_channel
    from src
)

select
    c.*,
    (c.currency_code = a.currency_code)     as is_currency_match,
    (c.tran_date = c.created_date::date)    as is_date_consistent,
    (c.tran_date <= current_date)           as is_not_future_dated,
    current_timestamp                       as dbt_loaded_at
from cleaned c
left join {{ ref('stg_account') }} a on c.account_id = a.account_id