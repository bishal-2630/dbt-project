select
    cust_id,
    name,
    address,
    phone_number,
    occupation,
    education,
    nationality
from {{ ref('stg_customer') }}