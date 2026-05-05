CREATE OR REPLACE VIEW "H7_personen_mit_gnd_beruf_autor" AS 
WITH base AS (
  SELECT DISTINCT
    p.person_id,
    p.beruf_beschaeftigung_gnd
  FROM person p
  JOIN person_rolle_objekt pro
    ON pro.person_id = p.person_id
)
SELECT
  COUNT(*) AS n_personen,
  COUNT(*) FILTER (
    WHERE LOWER(COALESCE(beruf_beschaeftigung_gnd, '')) LIKE '%autor%'
       OR LOWER(COALESCE(beruf_beschaeftigung_gnd, '')) LIKE '%schriftsteller%'
  ) AS n_autor_schriftsteller_gnd,
  ROUND(
    100.0*  (COUNT(*) FILTER (
      WHERE LOWER(COALESCE(beruf_beschaeftigung_gnd, '')) LIKE '%autor%'
         OR LOWER(COALESCE(beruf_beschaeftigung_gnd, '')) LIKE '%schriftsteller%'
    ))::numeric / NULLIF(COUNT(*), 0),
    2
  ) AS pct_autor_schriftsteller_gnd
FROM base;