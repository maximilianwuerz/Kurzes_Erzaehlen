CREATE OR REPLACE VIEW "H7_personen_mit_gnd_anteil" AS
WITH base AS (
  SELECT DISTINCT
    p.person_id,
    (NULLIF(BTRIM(p.gnd_nummer), '') IS NOT NULL) AS has_gnd
  FROM person p
  JOIN person_rolle_objekt pro
    ON pro.person_id = p.person_id
)
SELECT
  COUNT(*) AS n_personen,
  COUNT(*) FILTER (WHERE has_gnd) AS n_mit_gnd,
  ROUND(
    100.0 * (COUNT(*) FILTER (WHERE has_gnd))::numeric
    / NULLIF(COUNT(*), 0),
    2
  ) AS pct_mit_gnd
FROM base;