create or replace view "H5c_konzentration" as
with b as (
  select
    kategorie,
    coalesce(n_publikationsbeteiligungen, 0) as n
  from "H5b"
  where kategorie in (
    'definitiv Verlag (Name + Sachgruppe)',
    'Verlag laut Name (keine verlagsrelevante Sachgruppe)'
  )
),
b2 as (
  select kategorie, n from b
  union all
  select 'Gesamt: definitiv + laut Name'::text as kategorie, n from b
),
ranked as (
  select
    kategorie,
    n,
    row_number() over (partition by kategorie order by n desc)  as rk_desc,
    count(*)  over (partition by kategorie) as n_total_count,
    sum(n)    over (partition by kategorie) as s_total_sum
  from b2
),
agg as (
  select
    kategorie,
    n_total_count,
    s_total_sum,
    sum((n::numeric) * (n::numeric))      as sum_n2,
    sum(n) filter (where rk_desc <= 10)                        as sum_top10,
    sum(n) filter (where rk_desc <= ceil(0.10 * n_total_count)) as sum_top10pct
  from ranked
  group by kategorie, n_total_count, s_total_sum
)
select
  kategorie,
  n_total_count as n_verlage,
  s_total_sum   as sum_beteiligungen,
  case
    when s_total_sum > 0
      then (sum_n2 / (s_total_sum::numeric * s_total_sum::numeric))
    else null
  end as hhi,
  case when s_total_sum > 0 then sum_top10::numeric   / s_total_sum::numeric else null end as top10_share,
  case when s_total_sum > 0 then sum_top10pct::numeric / s_total_sum::numeric else null end as top10pct_share
from agg
order by case kategorie
  when 'definitiv Verlag (Name + Sachgruppe)' then 1
  when 'Verlag laut Name (keine verlagsrelevante Sachgruppe)' then 2
  else 3
end;