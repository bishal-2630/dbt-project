{% snapshot snap_account %}

{{ config(
    target_schema = 'snapshots',
    unique_key    = 'account_id',
    strategy      = 'check',
    check_cols    = ['account_balance', 'acct_cls_flg', 'branch_id', 'product_id']
) }}

select * from {{ source('bronze', 'account') }}

{% endsnapshot %}