select
    product_id,
    schm_type,
    schm_code,
    product_desc,
    product_group
from {{ ref('stg_product') }}