CREATE OR REPLACE VIEW "H2c_altersbeschraenkung" AS
WITH base AS (
  SELECT
    altersgrenze,
    NULLIF(btrim(lower(altersgrenze)), '') AS t
  FROM literaturwettbewerb
),
klass AS(
SELECT
  CASE
    WHEN t IS NULL OR t IN ('keine info', 'n/a', 'na', 'nein', 'keine altersbegrenzung') THEN 'Keine Beschränkung'
    WHEN position(';' IN t) > 0 THEN 'Mehrere Altersgruppen'
    WHEN t ~ '\d+\s*-\s*\d+' OR t ~ '\d+\s*bis\s*\d+' THEN 'Spezifizierter Bereich'
    WHEN t LIKE '%+%' OR t ~ '(^|[^a-z])ab\s*\d+' OR t ~ '(^|[^a-z])mind(\.|estens)?\s*\d+' THEN 'Mindestalter'
    WHEN t ~ '(^|[^a-z])max\.?\s*\d+' OR t ~ '(^|[^a-z])unter\s*\d+' OR t LIKE '%<%' THEN 'Höchstalter'
    ELSE 'Andere'
  END AS kategorie
  FROM base
  )
  SELECT 
  kategorie,
  COUNT(*) AS anzahl_wettbewerbe,
  ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS prozent
  FROM klass
GROUP BY kategorie
ORDER BY
  CASE kategorie
    WHEN 'Mehrere Altersgruppen'  THEN 1
    WHEN 'Spezifizierter Bereich' THEN 2
    WHEN 'Mindestalter'           THEN 3
    WHEN 'Höchstalter'            THEN 4
    WHEN 'Keine Beschränkung'     THEN 5
    ELSE 6
  END;