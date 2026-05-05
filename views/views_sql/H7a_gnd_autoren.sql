CREATE OR REPLACE VIEW "H7a_gnd_autoren" AS
with gnd as (
  select person_id, beruf_beschaeftigung_gnd
  from person
  where nullif(btrim(gnd_nummer), '') is not null
),
gnd_personen_in_korpus as (
  select count(distinct pro.person_id) as n_gnd_personen_in_korpus
  from person_rolle_objekt pro
  join gnd using (person_id)
),
gnd_autoren_in_korpus as (
  select count(distinct pro.person_id) as n_gnd_autoren_in_korpus
  from person_rolle_objekt pro
  join gnd using (person_id)
  where lower(coalesce(gnd.beruf_beschaeftigung_gnd, '')) like '%autor%'
     or lower(coalesce(gnd.beruf_beschaeftigung_gnd, '')) like '%schriftsteller%'
),
gnd_personen_mit_verfasserrolle as (
  select count(distinct pro.person_id) as n_gnd_personen_mit_verfasserrolle
  from person_rolle_objekt pro
  join gnd using (person_id)
  where pro.rolle in ('VerfasserIn Buch', 'Verfasser Zeitschriftbeitrag', 'GewinnerIn')
),
gnd_autoren_mit_verfasserrolle as (
  select count(distinct pro.person_id) as n_gnd_autoren_mit_verfasserrolle
  from person_rolle_objekt pro
  join gnd using (person_id)
  where pro.rolle in ('VerfasserIn Buch', 'Verfasser Zeitschriftbeitrag', 'GewinnerIn')
  and (
  lower(coalesce(gnd.beruf_beschaeftigung_gnd, '')) like '%autor%'
     or lower(coalesce(gnd.beruf_beschaeftigung_gnd, '')) like '%schriftsteller%'
	 )
)
select
  (select n_gnd_personen_in_korpus from gnd_personen_in_korpus) as n_gnd_personen_in_korpus,
  (select n_gnd_autoren_in_korpus from gnd_autoren_in_korpus) as n_gnd_autoren_in_korpus,
  (select n_gnd_personen_mit_verfasserrolle from gnd_personen_mit_verfasserrolle) as n_gnd_personen_mit_verfasserrolle,
  (select n_gnd_autoren_mit_verfasserrolle from gnd_autoren_mit_verfasserrolle) as n_gnd_autoren_mit_verfasserrolle;