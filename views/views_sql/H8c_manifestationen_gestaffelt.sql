create or replace view "H8c_manifestationen_gestaffelt" as
with b as (
  select n_manifestationen from "H8c_manifestationen"
),
agg as (
  select
    case
      when n_manifestationen = 1 then '1'
      when n_manifestationen = 2 then '2'
	  when n_manifestationen = 3 then '3'
      when n_manifestationen = 4 then '4'
      else '5+'
    end as klasse,
    count(*) as n_werke
  from b
  group by 1
)
select klasse, n_werke
from agg
order by array_position(array['1','2','3','4','5+'], klasse);