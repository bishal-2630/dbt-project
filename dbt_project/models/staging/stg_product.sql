select 
    upper(trim(product_id)) as product_id,
    upper(trim(schm_type)) as schm_type,
    upper(trim(schm_code)) as schm_code,
    initcap(trim(product_desc)) as product_desc,
    case upper(trim(schm_type)) 
        when 'SA' then 'SAVINGS'
        when 'CA' then 'CURRENT'
        when 'FD' then 'FIXED_DEPOSIT'
        when 'RD' then 'RECURRING_DEPOSIT'
        when 'LD' then 'LOAN'
    end as product_category,
    case
        when upper(trim(schm_type)) in ('SA','CA') then 'CASA'
        when upper(trim(schm_type)) in ('FD','RD') then 'TERM_DEPOSIT'
        when upper(trim(schm_type)) = 'LD'         then 'LOAN'
    end as product_group
from {{ source('bronze', 'product') }}