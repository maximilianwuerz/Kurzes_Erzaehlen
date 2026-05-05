create or replace view "H5b" as
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
)
select
  v.koerperschaft_id,
  v.kategorie,
  count(distinct kro.objekt_id) as n_publikationsbeteiligungen   -- distinct: Mehrfachrollen je Objekt werden nur 1x gezählt
from verlage v
left join koerperschaft_rolle_objekt kro
  on kro.koerperschaft_id = v.koerperschaft_id
where v.kategorie is not null
group by v.koerperschaft_id, v.kategorie;