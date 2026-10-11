select
    account_id,
    customer_id,
    branch_id,
    product_id,
    currency_code,
    account_balance,
    lien_amt,
    is_active,
    lchg_time
from {{ ref('stg_account') }}