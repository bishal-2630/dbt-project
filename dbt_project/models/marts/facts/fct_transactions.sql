select
    tran_id,
    account_id,
    branch_id,
    tran_date,
    date_trunc('month', tran_date)::date as tran_month,
    tran_particular,
    tran_direction,
    tran_channel,
    currency_code,
    tran_amount
from {{ ref('stg_hist_transactional') }}