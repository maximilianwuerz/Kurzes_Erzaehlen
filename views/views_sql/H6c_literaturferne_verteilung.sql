CREATE OR REPLACE VIEW "H6c_literaturferne_verteilung" AS
with kandidaten as (
  select koerperschaft_id
  from "H6_literaturfern_kandidaten_check"
  where literaturfern_status = 'true'
),
links as (
  -- distinct je Koerperschaft x Objekt x Typ (Mehrfachrollen pro Objekt nicht doppelt)
  select distinct
    kro.koerperschaft_id,
    kro.objekt_id,
    kro.objekt_typ
  from koerperschaft_rolle_objekt kro
  join kandidaten k using (koerperschaft_id)
  where kro.objekt_typ in ('Buch','Literaturzeitschrift','Literaturwettbewerb','Plattform Internet')
),
gew as (
  select
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
  left join literaturzeitschrift   z on z.literaturzeitschrift_id = l.objekt_id and l.objekt_typ = 'Literaturzeitschrift'
  left join literaturwettbewerb    w on w.literaturwettbewerb_id  = l.objekt_id and l.objekt_typ = 'Literaturwettbewerb'
  left join plattform_internet     p on p.plattform_id            = l.objekt_id and l.objekt_typ = 'Plattform Internet'
),
agg as (
  select objekt_typ, sum(gewicht) as engagement_gew
  from gew
  group by objekt_typ
)
select
  objekt_typ as publikationssegment,
  engagement_gew,
  round(100.0 * engagement_gew / sum(engagement_gew) over (), 2) as engagement_share_pct
from agg
order by engagement_gew desc;