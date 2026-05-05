create or replace view "H5c_top20" as
select
  h.koerperschaft_id,
  coalesce(k.koerperschaft_name_gnd, k.koerperschaft_name) as koerperschaft_name,
  h.kategorie,
  h.n_publikationsbeteiligungen
from "H5b" h
left join koerperschaft k on k.koerperschaft_id = h.koerperschaft_id
where h.kategorie in (
  'definitiv Verlag (Name + Sachgruppe)',
  'Verlag laut Name (keine verlagsrelevante Sachgruppe)'
)
order by h.n_publikationsbeteiligungen desc nulls last,
         coalesce(k.koerperschaft_name_gnd, k.koerperschaft_name) asc
limit 20;