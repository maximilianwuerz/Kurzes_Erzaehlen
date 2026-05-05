create or replace view "H6c_literaturferne_rollen" as
with lf as (
  select koerperschaft_id
  from "H6_literaturfern_kandidaten_check"
  where literaturfern_status = 'true'
),
links as (
  -- pro Körperschaft x Objekt nur einmal zählen, Rolle mitführen
  select distinct
    kro.koerperschaft_id,
    kro.objekt_id,
    kro.rolle
  from koerperschaft_rolle_objekt kro
  join lf using (koerperschaft_id)
),
norm as (
  select
    koerperschaft_id,
    objekt_id,
    btrim(coalesce(rolle, '')) as rolle_txt
  from links
)
select
  case when rolle_txt = '' then '(ohne Rollenbezeichnung)' else rolle_txt end as rolle,
  count(*) as n_vorkommen,
  count(distinct koerperschaft_id) as n_koerperschaften,
round(100.0 * count(*)::numeric / nullif(sum(count(*)) over (), 0), 2) as anteil_pct
from norm
group by case when rolle_txt = '' then '(ohne Rollenbezeichnung)' else rolle_txt end
order by n_vorkommen desc, rolle asc;