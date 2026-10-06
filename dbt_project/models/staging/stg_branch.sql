select
   upper(trim(branch_id)) as branch_id,
   initcap(trim(province)) as province,
   initcap(trim(cluster_name)) as cluster_name,
   initcap(trim(city_name)) as city_name,
   initcap(trim(branch_name)) as branch_name,

   case when branch_name ilike '%main%' then 'MAIN' else 'EXTENSION' end as branch_type
from {{ source('bronze', 'branch') }}