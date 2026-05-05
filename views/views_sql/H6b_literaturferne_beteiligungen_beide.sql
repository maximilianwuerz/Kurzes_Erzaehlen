create or replace view "H6b_literaturferne_beteiligungen_beide" as
with u as (
  select coalesce(n_publikationsbeteiligungen, 0) as n
  from "H6b_literaturferne_beteiligungen"
),
w as (
  select coalesce(n_publikationsbeteiligungen_gew, 0) as n
  from "H6b_literaturferne_beteiligungen_gew"
),
agg_u as (
  select
    'Literaturferne Koerperschaften (ungewichtet)'::text as kategorie,
    sum((n = 1)::int)              as n_einmalig,
    sum((n between 2 and 5)::int)  as n_selten,
    sum((n between 6 and 10)::int) as n_gelegentlich,
    sum((n between 11 and 15)::int)as n_regelmaessig,
    sum((n >= 16)::int)            as n_haeufig
  from u
),
agg_w as (
  select
    'Literaturferne Koerperschaften (gewichtet)'::text as kategorie,
    sum((n = 1)::int)              as n_einmalig,
    sum((n between 2 and 5)::int)  as n_selten,
    sum((n between 6 and 10)::int) as n_gelegentlich,
    sum((n between 11 and 15)::int)as n_regelmaessig,
    sum((n >= 16)::int)            as n_haeufig
  from w
),
stacked as (
  select 1 as sort_order, kategorie, n_einmalig, n_selten, n_gelegentlich, n_regelmaessig, n_haeufig from agg_u
  union all
  select 2 as sort_order, kategorie, n_einmalig, n_selten, n_gelegentlich, n_regelmaessig, n_haeufig from agg_w
)
select
  kategorie,
  n_einmalig,
  n_selten,
  n_gelegentlich,
  n_regelmaessig,
  n_haeufig
from stacked
order by sort_order;