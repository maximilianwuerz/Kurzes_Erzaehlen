create or replace view "H6b_literaturferne_beteiligungen_top20" as 
select
  h.koerperschaft_id,
  h.koerperschaft_name,
  h.n_publikationsbeteiligungen_gew as engagement_gew
from "H6b_literaturferne_beteiligungen_gew" h
order by h.n_publikationsbeteiligungen_gew desc nulls last,
         h.koerperschaft_name asc
limit 20;
