create or replace view "H5b_gew" as
with verlage as (
  select
    koerperschaft_id,
    case
      when name_flag = 'Verlag' and sachgruppe_flag is not null
        then 'definitiv Verlag (Name + Sachgruppe)'
      when name_flag = 'Verlag' and sachgruppe_flag is null
        then 'Verlag laut Name (keine verlagsrelevante Sachgruppe)'
      else null
    end as kategorie
  from "H5_verlag_flags"
),
links as (
  -- pro Verlag alle distinct Objekt-Links (Mehrfachrollen je Objekt werden dedupliziert)
  select distinct
    kro.koerperschaft_id,
    kro.objekt_id,
    kro.objekt_typ
  from koerperschaft_rolle_objekt kro
  join verlage v on v.koerperschaft_id = kro.koerperschaft_id
  where v.kategorie is not null
),
gew as (
  select
    l.koerperschaft_id,
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
),
summe as (
  select
    v.koerperschaft_id,
    v.kategorie,
    coalesce(sum(g.gewicht), 0)::numeric as n_publikationsbeteiligungen_gew
  from verlage v
  left join gew g on g.koerperschaft_id = v.koerperschaft_id
  where v.kategorie is not null     
  group by v.koerperschaft_id, v.kategorie
)
select
  koerperschaft_id,
  kategorie,
  n_publikationsbeteiligungen_gew
from summe;