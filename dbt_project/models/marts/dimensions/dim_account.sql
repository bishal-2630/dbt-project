select
    account_id,
    customer_id,
    branch_id,
    product_id,
    schm_type,
    schm_code,
    currency_code,
    is_active
from {{ ref('stg_account') }}