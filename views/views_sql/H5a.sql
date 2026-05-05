create or replace view "H5a" as
select
  category,
  count(distinct koerperschaft_id) as anzahl
from (
  select
    koerperschaft_id,
    case
      when name_flag = 'Verlag' and sachgruppe_flag is not null
        then 'definitiv Verlag (Name + Sachgruppe)'
      when name_flag = 'Verlag' and sachgruppe_flag is null
        then 'Verlag laut Name (keine verlagsrelevante Sachgruppe)'
      when sachgruppe_flag is not null and (name_flag is null or name_flag = 'Unternehmen')
        then 'verlagsrelevante Sachgruppe; Name nicht eindeutig'
      else 'kein Verlag'
    end as category
  from "H5_verlag_flags"
) x
group by category
order by case category
  when 'definitiv Verlag (Name + Sachgruppe)' then 1
  when 'nur Name = Verlag (keine verlagsrelevante Sachgruppe)' then 2
  when 'nur Sachgruppe verlagsrelevant (Name nicht eindeutig)' then 3
  when 'kein Verlag' then 4
end;