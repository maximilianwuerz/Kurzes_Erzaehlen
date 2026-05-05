create or replace view "H5_verlag_flags" as
with base as (
  select
    k.koerperschaft_id,
    k.koerperschaft_name,
    k.koerperschaft_name_gnd,
    k.gnd_sachgruppe,
    lower(coalesce(k.koerperschaft_name_gnd, k.koerperschaft_name, '')) as name_src,
    lower(coalesce(k.gnd_sachgruppe, '')) as sach_src
  from koerperschaft k
),
flags as (
  select
    koerperschaft_id,
    koerperschaft_name,
    koerperschaft_name_gnd,
    gnd_sachgruppe,
    case
      when name_src like '%verl.%'
        or name_src like '%verlag%'
        or name_src like '%ed.%'
		or (name_src like '%edition%' AND name_src not like '%tredition%') then 'Verlag'
      when name_src like '%verein%'
        or name_src like '%e.v.%' then 'Verein'
      when name_src like '%akademie%' then 'Akademie'
      when name_src like '%institut%' then 'Institut'
      when name_src like '%druck%' then 'Druckerei'
      when name_src like '%buchhandl%' then 'Buchhandlung'
      when name_src like '%verband%' or name_src like '%verb.%' then 'Verband'
      when name_src like '%forum%'
        or name_src like '%gemeinschaft%'
        or name_src like '%gruppe%'
        or name_src like '%kollektiv%'
        or name_src like '%kreis%'
        or name_src like '%club%'
        or name_src like '%gesellschaft%'
        or name_src like '%netzwerk%' then 'Gemeinschaft'
      when name_src like '%mbh%'
        or name_src like '%m.b.h.%'
        or name_src like '%gbr%'
        or name_src like '%ohg%'
        or name_src like '%e.k.%'
        or name_src like '%firma%' then 'Unternehmen'
	  when name_src like '%schule%'
	    or name_src like '%universitä%'
        or name_src like '%gymnasium%' then 'Bildungseinrichtung'
      else null
    end as name_flag,
    case
      when sach_src like '%buchwissenschaft%'
        or sach_src like '%buchhandel%'
        or sach_src like '%litera%' then 'verlagsrelevant'
      else null
    end as sachgruppe_flag
  from base
)
select
  koerperschaft_id,
  koerperschaft_name,
  koerperschaft_name_gnd,
  gnd_sachgruppe,
  name_flag,
  sachgruppe_flag,
  (name_flag = 'Verlag') as is_verlag_by_name,
  (sachgruppe_flag is not null) as is_verlagsrelevant_by_sachgruppe,
  ((name_flag = 'Verlag') or (sachgruppe_flag is not null)) as is_verlag_candidate,
  (case when name_flag = 'Verlag' then 1 else 0 end
   + case when sachgruppe_flag is not null then 1 else 0 end) as verlag_score
from flags;