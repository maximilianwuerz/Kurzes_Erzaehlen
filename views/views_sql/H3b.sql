CREATE OR REPLACE VIEW "H3b" AS
WITH base AS (
SELECT
  plattform_name,
  anzahl_ke::text AS anzahl_ke_raw,
  anzahl_texte_gesamt::text AS anzahl_texte_gesamt_raw  
  FROM plattform_internet
),
norm AS (
  SELECT
    plattform_name,
    NULLIF(btrim(lower(anzahl_ke_raw)), '') AS ke_t,
    NULLIF(btrim(lower(anzahl_texte_gesamt_raw)), '') AS ges_t
  FROM base
),
clean AS (
  SELECT
    plattform_name,
    NULLIF(regexp_replace(ke_t, '[^0-9]', '', 'g'), '')::int AS anzahl_ke,
    NULLIF(regexp_replace(ges_t, '[^0-9]', '', 'g'), '')::int AS anzahl_texte_gesamt
  FROM norm
  WHERE ke_t IS NOT NULL
    AND ke_t <> '?'
)
SELECT
  plattform_name,
  anzahl_ke,
  anzahl_texte_gesamt,
  ROUND(100.0 * anzahl_ke / NULLIF(anzahl_texte_gesamt, 0), 2) AS anteil_ke_in_prozent
FROM clean
WHERE anzahl_ke IS NOT NULL
ORDER BY anzahl_ke DESC, plattform_name;