create or replace view "H6b_literaturferne_beteiligungen_gew" as
with kandidaten as (
  select
    k.koerperschaft_id,
    coalesce(k.koerperschaft_name, k.koerperschaft_name_gnd) as koerperschaft_name
  from "H6_literaturfern_kandidaten_check" k
  where k.literaturfern_status = 'true'
),
links as (
  -- pro Körperschaft alle distinct Objekt-Links (Mehrfachrollen je Objekt nur 1x)
  select distinct
    c.koerperschaft_id,
    c.koerperschaft_name,
    kro.objekt_id,
    kro.objekt_typ
  from kandidaten c
  join koerperschaft_rolle_objekt kro
    on kro.koerperschaft_id = c.koerperschaft_id
),
gew as (
  -- Gewicht je Link:
  -- Buch = 1
  -- Literaturzeitschrift/Wettbewerb/Plattform = aktive Jahre im Zeitraum 2008–2023
  select
    l.koerperschaft_id,
    l.koerperschaft_name,
    l.objekt_id,
    l.objekt_typ,
    case
      when l.objekt_typ = 'Buch' then 1::numeric
      when l.objekt_typ = 'Literaturzeitschrift' then
        coalesce(
          greatest(0, 2023 - greatest(2008, substring(z.erstveroeffentlichung::text from '([12][0-9]{3})')::int) + 1),
          1
        )::numeric
      when l.objekt_typ = 'Literaturwettbewerb' then
        coalesce(
          greatest(0, 2023 - greatest(2008, substring(w.erstausrichtung::text from '([12][0-9]{3})')::int) + 1),
          1
        )::numeric
      when l.objekt_typ = 'Plattform Internet' then
        coalesce(
          greatest(0, 2023 - greatest(2008, substring(p.gruendungsjahr::text from '([12][0-9]{3})')::int) + 1),
          1
        )::numeric
      else 1::numeric
    end as gewicht
  from links l
  left join literaturzeitschrift z
    on z.literaturzeitschrift_id = l.objekt_id and l.objekt_typ = 'Literaturzeitschrift'
  left join literaturwettbewerb w
    on w.literaturwettbewerb_id = l.objekt_id and l.objekt_typ = 'Literaturwettbewerb'
  left join plattform_internet p
    on p.plattform_id = l.objekt_id and l.objekt_typ = 'Plattform Internet'
)
select
  koerperschaft_id,
  koerperschaft_name,
  coalesce(sum(gewicht), 0)::numeric as n_publikationsbeteiligungen_gew
from gew
group by koerperschaft_id, koerperschaft_name;