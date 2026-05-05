create or replace view "H6b_literaturferne_beteiligungen" as
select
  k.koerperschaft_id,
  coalesce(k.koerperschaft_name, k.koerperschaft_name_gnd) as koerperschaft_name,
  count(distinct kro.objekt_id) as n_publikationsbeteiligungen
from "H6_literaturfern_kandidaten_check" k
left join koerperschaft_rolle_objekt kro
  on kro.koerperschaft_id = k.koerperschaft_id
where k.literaturfern_status = 'true'
group by k.koerperschaft_id, coalesce(k.koerperschaft_name_gnd, k.koerperschaft_name);