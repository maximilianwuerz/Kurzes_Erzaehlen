CREATE OR REPLACE VIEW "H7_personen_autorrollen" AS
select
  rolle,
  count(distinct person_id) as n_personen
from person_rolle_objekt
where rolle in ('GewinnerIn', 'VerfasserIn Buch', 'Verfasser Zeitschriftbeitrag')
group by rolle
order by rolle;