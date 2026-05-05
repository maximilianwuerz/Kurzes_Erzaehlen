CREATE OR REPLACE VIEW "H7b_gnd_autoren_top20_lebend" AS 
with gnd_autoren as (
  select distinct person_id
  from person
  where nullif(btrim(gnd_nummer), '') is not null
    and (
      lower(coalesce(beruf_beschaeftigung_gnd, '')) like '%autor%'
      or lower(coalesce(beruf_beschaeftigung_gnd, '')) like '%schriftsteller%'
    )
),
autor_links as (
  select distinct person_id, objekt_id
  from person_rolle_objekt
  where rolle in ('VerfasserIn Buch', 'Verfasser Zeitschriftbeitrag', 'GewinnerIn')
)
select
  coalesce(p.person_name_gnd, p.person_name) as person_name,
  count(distinct al.objekt_id) as n_verfasserbeteiligungen
from gnd_autoren g
join autor_links al using (person_id)
join person p using (person_id)
WHERE
  NULLIF(BTRIM(p.sterbedatum_gnd), '') IS NULL
  OR (p.sterbedatum_gnd ~ '^\d{4}-\d{2}-\d{2}$' AND p.sterbedatum_gnd::date >= DATE '2008-01-01')
group by g.person_id, person_name, person_name_gnd
order by n_verfasserbeteiligungen desc nulls last, person_name asc
limit 20;