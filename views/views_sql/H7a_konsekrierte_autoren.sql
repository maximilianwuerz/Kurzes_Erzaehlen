CREATE OR REPLACE VIEW "H7a_konsekrierte_autoren" AS 
with k as (
  select distinct
    coalesce(ka.person_id, p.person_id) as person_id
  from "konsekrierte_autoren" ka
  left join person p
    on p.person_name = ka.autor_name
    or p.person_name_gnd = ka.autor_name
  where coalesce(ka.person_id, p.person_id) is not null
),
k_total as (
  select count(distinct person_id) as n_konsekrierte_autoren_in_korpus
  from k
),
k_in as (
  select distinct k.person_id
  from k
  join person_rolle_objekt pro on pro.person_id = k.person_id
  where pro.rolle in ('VerfasserIn Buch','Verfasser Zeitschriftbeitrag', 'GewinnerIn')
),
k_in_count as (
  select count(*) as n_konsekrierte_mit_verfasserrolle
  from k_in
),
list_total as (
  select count(distinct autor_name) as n_konsekrierte_autoren
  from "konsekrierte_autoren"
)
select
  lt.n_konsekrierte_autoren,
  kt.n_konsekrierte_autoren_in_korpus,
  kc.n_konsekrierte_mit_verfasserrolle
from list_total lt
cross join k_total kt
cross join k_in_count kc;