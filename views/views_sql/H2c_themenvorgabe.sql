CREATE OR REPLACE VIEW "H2c_themenvorgabe" AS
WITH klass AS (
  SELECT
    CASE
      WHEN LOWER(COALESCE(themenvorgabe, '')) = 'ja'   THEN 'mit Themenvorgabe'
      WHEN LOWER(COALESCE(themenvorgabe, '')) = 'nein' THEN 'ohne Themenvorgabe'
      ELSE 'unbekannt'
    END AS literaturwettbewerbe
  FROM literaturwettbewerb
)
SELECT
  literaturwettbewerbe,
  COUNT(*) AS anzahl,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS anteil_in_prozent
FROM klass
GROUP BY literaturwettbewerbe
ORDER BY CASE literaturwettbewerbe
  WHEN 'mit Themenvorgabe' THEN 1
  WHEN 'ohne Themenvorgabe' THEN 2
  ELSE 3
END;