select
    card_number,
    masked_card_number,
    account_id,
    card_type,
    card_expiry_date,
    is_expired
from {{ ref('stg_card') }}