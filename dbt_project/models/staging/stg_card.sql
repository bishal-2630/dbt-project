select
    trim(card_number)                                                                   as card_number,
    left(trim(card_number), 4) || '-****-****-' || right(trim(card_number), 4)          as masked_card_number,
    upper(trim(account_id))                                                             as account_id,
    coalesce(balance, 0)::numeric(15,2)                                                 as card_balance,
    upper(trim(card_type))                                                              as card_type,
    closing_balance::numeric(15,2)                                                      as closing_balance,
    card_expiry_date::date                                                              as card_expiry_date,
    (card_expiry_date < current_date)                                                   as is_expired,
    case
        when upper(trim(card_type)) = 'DEBIT' then closing_balance is null
        when upper(trim(card_type)) = 'CREDIT' then closing_balance is not null
    end                                                                                 as is_closing_balance_valid
from {{ source('bronze', 'card') }}