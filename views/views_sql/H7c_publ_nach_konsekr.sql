CREATE OR REPLACE VIEW "H7c_publ_nach_konsekr" AS
WITH ka AS (
  -- pro Person das erste Award-Jahr im Zeitraum
  SELECT
    person_id,
    MIN(jahr) AS award_year
  FROM konsekrierte_autoren
  WHERE person_id IS NOT NULL
    AND jahr BETWEEN 2007 AND 2023
  GROUP BY person_id
),
pub AS (
  SELECT
    pro.person_id,
    pro.objekt_id,
    CASE
      WHEN pro.objekt_typ = 'Buch' THEN b.publikationsjahr
      WHEN pro.objekt_typ = 'Literaturzeitschrift Ausgabe' THEN
        NULLIF(
          substring(coalesce(lza.erscheinungsjahr::text, '') FROM '([12][0-9]{3})'),
          ''
        )::int
      WHEN pro.objekt_typ = 'Literaturwettbewerb Ausgabe' THEN
        NULLIF(
          substring(coalesce(lwa.jahr::text, '') FROM '([12][0-9]{3})'),
          ''
        )::int
      ELSE NULL
    END AS pub_year
  FROM person_rolle_objekt pro
  LEFT JOIN buch b
    ON pro.objekt_typ = 'Buch' AND b.isbn = pro.objekt_id
  LEFT JOIN literaturzeitschrift_ausgabe lza
    ON pro.objekt_typ = 'Literaturzeitschrift Ausgabe'
   AND lza.literaturzeitschrift_ausgabe_id = pro.objekt_id
  LEFT JOIN literaturwettbewerb_ausgabe lwa
    ON pro.objekt_typ = 'Literaturwettbewerb Ausgabe'
   AND lwa.literaturwettbewerb_ausgabe_id = pro.objekt_id
  WHERE pro.rolle IN ('GewinnerIn','VerfasserIn Buch','Verfasser Zeitschriftbeitrag')
),
per AS (
  -- Zählen der Publikationen NACH dem Award (strict: pubyear > awardyear)
  SELECT
    k.person_id,
    k.award_year,
    COUNT(DISTINCT p.objekt_id) FILTER (WHERE p.pub_year > k.award_year) AS n_after
  FROM ka k
  LEFT JOIN pub p ON p.person_id = k.person_id
  GROUP BY k.person_id, k.award_year
)
SELECT
  per.person_id,
  COALESCE(pe.person_name_gnd, pe.person_name) AS person_name,
  per.award_year,
  per.n_after
FROM per
LEFT JOIN person pe ON pe.person_id = per.person_id
ORDER BY person_name, award_year;


select * from konsekrierte_autoren where autor_name = 'Schulze, Ingo'