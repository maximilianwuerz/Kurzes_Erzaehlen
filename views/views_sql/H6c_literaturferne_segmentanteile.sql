create or replace view "H6c_literaturferne_segmentanteile" as
with lf as (
  select koerperschaft_id
  from "H6_literaturfern_kandidaten_check"
  where literaturfern_status = 'true'
),
den as (
  select 'Buch'::text as segment, count(*)::bigint as n_objekte_total
  from buch
  union all
  select 'Literaturzeitschrift', count(*)::bigint
  from literaturzeitschrift
  union all
  select 'Literaturwettbewerb', count(*)::bigint
  from literaturwettbewerb
  union all
  select 'Plattform Internet', count(*)::bigint
  from plattform_internet
),
num as (
  select 'Buch'::text as segment, count(distinct b.isbn)::bigint as n_objekte_mit_literaturfernen
  from buch b
  join koerperschaft_rolle_objekt kro
    on kro.objekt_typ = 'Buch' and kro.objekt_id = b.isbn
  join lf on lf.koerperschaft_id = kro.koerperschaft_id
  union all
  select 'Literaturzeitschrift', count(distinct z.literaturzeitschrift_id)::bigint
  from literaturzeitschrift z
  join koerperschaft_rolle_objekt kro
    on kro.objekt_typ = 'Literaturzeitschrift' and kro.objekt_id = z.literaturzeitschrift_id
  join lf on lf.koerperschaft_id = kro.koerperschaft_id
  union all
  select 'Literaturwettbewerb', count(distinct w.literaturwettbewerb_id)::bigint
  from literaturwettbewerb w
  join koerperschaft_rolle_objekt kro
    on kro.objekt_typ = 'Literaturwettbewerb' and kro.objekt_id = w.literaturwettbewerb_id
  join lf on lf.koerperschaft_id = kro.koerperschaft_id
  union all
  select 'Plattform Internet', count(distinct p.plattform_id)::bigint
  from plattform_internet p
  join koerperschaft_rolle_objekt kro
    on kro.objekt_typ = 'Plattform Internet' and kro.objekt_id = p.plattform_id
  join lf on lf.koerperschaft_id = kro.koerperschaft_id
)
select
  d.segment as publikationssegment,
  d.n_objekte_total,
  coalesce(n.n_objekte_mit_literaturfernen, 0) as n_objekte_mit_literaturfernen,
  case
    when d.n_objekte_total > 0
      then round(100.0 * coalesce(n.n_objekte_mit_literaturfernen, 0)::numeric / d.n_objekte_total, 2)
    else null
  end as anteil_literaturfern_pct
from den d
left join num n using (segment)
order by case d.segment
  when 'Buch' then 1
  when 'Literaturzeitschrift' then 2
  when 'Literaturwettbewerb' then 3
  else 4
end;