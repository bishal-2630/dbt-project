select
    tran_month,

    -- KPI 9: Transaction Volume and Value
    count(*)                                                    as txn_count,
    sum(tran_amount)                                            as txn_value,

    -- KPI 10: Net Cash Flow = credits - debits
    coalesce(sum(tran_amount) filter (where tran_direction = 'CREDIT'), 0)
      - coalesce(sum(tran_amount) filter (where tran_direction = 'DEBIT'), 0) as net_cash_flow,

    -- KPI 11: Digital Transaction Share
    round(count(*) filter (where tran_channel = 'DIGITAL')::numeric / count(*), 4) as digital_txn_share,

    -- KPI 12: Remittance Inflow
    coalesce(sum(tran_amount) filter (where tran_particular = 'REMITTANCE CREDIT'), 0) as remittance_inflow,

    -- KPI 13: Fee Income
    coalesce(sum(tran_amount) filter (where tran_particular = 'SERVICE CHARGE DEBIT'), 0) as fee_income
from {{ ref('fct_transactions') }}
group by tran_month
order by tran_month