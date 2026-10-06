{{ config(
    materialized= 'incremental',
    incremental_strategy= 'merge',
    unique_key= 'account_id',
    on_schema_change= 'sync_all_columns'
)
}}

with src as (
    select * from {{ source('bronze', 'account') }}
    {% if is_incremental() %}
    where lchg_time > (select coalesce(max(lchg_time), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}
),

deduped as (
    select *, row_number() over (partition by upper(trim(account_id)) order by lchg_time desc) as rn
    from src
),

cleaned as (
    select
        upper(trim(account_id))                      as account_id,
        upper(trim(customer_id))                     as customer_id,
        upper(trim(branch_id))                       as branch_id,
        upper(trim(product_id))                      as product_id,
        upper(trim(schm_type))                       as schm_type,
        upper(trim(schm_code))                       as schm_code,
        upper(trim(acct_crncy_code))                 as currency_code,
        coalesce(account_balance, 0)::numeric(15,2)  as account_balance,
        coalesce(lien_amt, 0)::numeric(15,2)         as lien_amt,
        upper(trim(acct_cls_flg))                    as acct_cls_flg,
        lchg_time
    from deduped
    where rn = 1
)

select
    c.*,
    (c.acct_cls_flg = 'N')                           as is_active,
    (c.schm_type = 'LD')                             as is_loan,
    case
        when c.schm_type = 'LD' then null
        else c.account_balance - c.lien_amt
    end                                              as available_balance,
    coalesce(p.schm_type = c.schm_type and p.schm_code = c.schm_code, false) as is_product_consistent,
    (c.lien_amt <= abs(c.account_balance))           as is_lien_valid
from cleaned c
left join {{ ref('stg_product') }} p on c.product_id = p.product_id
