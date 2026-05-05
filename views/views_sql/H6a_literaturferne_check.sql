  CREATE OR REPLACE VIEW "H6a_literaturferne_check" as
  select literaturfern_status, count(*) as anzahl
  from "H6_literaturfern_kandidaten_check"
  group by literaturfern_status
  order by literaturfern_status;