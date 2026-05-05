create or replace view "H8c_manifestationen_summary" as
with agg as (
  select
    case when n_manifestationen >= 2 then '>=2 (mehrfach)' else '1 (einmal)' end as kategorie,
    count(*) as n_werke
  from "H8c_manifestationen"
  group by case when n_manifestationen >= 2 then '>=2 (mehrfach)' else '1 (einmal)' end
),
tot as (
  select sum(n_werke) as n_werke_total from agg
)
select
  a.kategorie,
  a.n_werke,
  round(100.0 * a.n_werke::numeric / nullif(t.n_werke_total, 0), 2) as pct
from agg a cross join tot t
order by case a.kategorie when '1 (einmal)' then 1 else 2 end;