with src as (
    select * from {{ source('bronze', 'customer') }}
),

deduped as (
    select *, row_number() over (partition by upper(trim(cust_id)) order by cust_id) as rn
    from src
),

cleaned as (
    select
        upper(trim(cust_id))                                              as cust_id,
        initcap(trim(name))                                               as name,
        trim(address)                                                     as address,
        nullif(regexp_replace(trim(phone_number), '[^0-9]', '', 'g'), '') as phone_number,
        trim(postal_code)                                                 as postal_code,
        initcap(trim(country))                                            as country,
        lower(trim(email))                                                as email,
        initcap(trim(father_name))                                        as father_name,
        initcap(trim(mother_name))                                        as mother_name,
        trim(occupation)                                                  as occupation,
        trim(education)                                                   as education,
        initcap(trim(nationality))                                        as nationality
    from deduped
    where rn = 1
)

select
    *,
    coalesce(length(phone_number) = 10, false)                            as is_valid_phone,
    coalesce(email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$', false)   as is_valid_email,
    (nationality <> 'Nepali')                                             as is_foreign_national
from cleaned