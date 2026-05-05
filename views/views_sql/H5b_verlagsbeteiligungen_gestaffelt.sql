create or replace view "H5b_verlagsbeteiligungen_gestaffelt" as
with base as (
  select
    kategorie,
    coalesce(n_publikationsbeteiligungen, 0) as n
  from "H5b"
  where kategorie in (
    'definitiv Verlag (Name + Sachgruppe)',
    'Verlag laut Name (keine verlagsrelevante Sachgruppe)'
  )
),
agg as (
  select
    kategorie,
    sum((n = 1)::int)              as n_einmalig,
    sum((n between 2 and 5)::int)  as n_selten,
    sum((n between 6 and 10)::int) as n_gelegentlich,
    sum((n between 11 and 15)::int)as n_regelmaessig,
    sum((n >= 16)::int)            as n_haeufig,
    case
      when kategorie = 'definitiv Verlag (Name + Sachgruppe)' then 1
      when kategorie = 'Verlag laut Name (keine verlagsrelevante Sachgruppe)' then 2
      else 99
    end as sort_order
  from base
  group by kategorie
),
total as (
  select
    'Gesamt: definitiv + wahrsch. Verlage'::text as kategorie,
    sum(n_einmalig)     as n_einmalig,
    sum(n_selten)       as n_selten,
    sum(n_gelegentlich) as n_gelegentlich,
    sum(n_regelmaessig) as n_regelmaessig,
    sum(n_haeufig)      as n_haeufig,
    3                   as sort_order
  from agg
)
select
  kategorie,
  n_einmalig,
  n_selten,
  n_gelegentlich,
  n_regelmaessig,
  n_haeufig
from (
  select * from agg
  union all
  select * from total
) u
order by sort_order;