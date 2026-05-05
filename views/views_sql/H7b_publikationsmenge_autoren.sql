CREATE OR REPLACE VIEW "H7b_publikationsmenge_autoren" AS
with gnd_autoren as (
  select distinct person_id
  from person
  where nullif(btrim(gnd_nummer), '') is not null
    and (
      lower(coalesce(beruf_beschaeftigung_gnd, '')) like '%autor%'
      or lower(coalesce(beruf_beschaeftigung_gnd, '')) like '%schriftsteller%'
    )
),
konsekriert as (
  select distinct person_id
  from konsekrierte_autoren
  where person_id is not null
),
autor_links as (
  -- jede Person-Objekt-Kombination nur einmal zählen
  select distinct person_id, objekt_id
  from person_rolle_objekt
  where rolle in ('VerfasserIn Buch', 'Verfasser Zeitschriftbeitrag', 'GewinnerIn')
),
gnd_stats as (
  select
    count(distinct al.person_id) as anzahl, -- = n_gnd_autoren_mit_verfasserrolle
    count(*) as n_verfasserbeteiligungen
  from gnd_autoren g
  join autor_links al using (person_id)
),
konsekriert_stats as (
  select
    count(distinct al.person_id) as anzahl, -- = n_konsekrierte_mit_verfasserrolle
    count(*) as n_verfasserbeteiligungen
  from konsekriert k
  join autor_links al using (person_id)
)
select
  'GND-Autor*innen mit Verfasserrolle im Korpus'::text as kategorie,
  gc.anzahl,
  gc.n_verfasserbeteiligungen,
  round(
    case when gc.anzahl > 0
      then gc.n_verfasserbeteiligungen::numeric / gc.anzahl
      else null end
  , 2) as avg_verfasserbeteiligungen_pro_autor
from gnd_stats gc
union all
select
  'Konsekrierte Autor*innen mit Verfasserrolle im Korpus'::text as kategorie,
  kc.anzahl,
  kc.n_verfasserbeteiligungen,
  round(
    case when kc.anzahl > 0
      then kc.n_verfasserbeteiligungen::numeric / kc.anzahl
      else null end
  , 2) as avg_verfasserbeteiligungen_pro_autor
from konsekriert_stats kc;