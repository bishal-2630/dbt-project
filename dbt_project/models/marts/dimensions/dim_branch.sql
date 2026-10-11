select
    branch_id,
    province,
    cluster_name,
    city_name,
    branch_name
from {{ ref('stg_branch') }}