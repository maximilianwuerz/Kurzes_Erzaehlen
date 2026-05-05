CREATE OR REPLACE VIEW "H2c_laengenvorgabe_einheit" AS
SELECT
  einheit,
  COUNT(*) AS anzahl_wettbewerbe,
  ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS prozent
FROM "H2c_laengenvorgabe"
GROUP BY einheit
ORDER BY
  CASE einheit
    WHEN 'seiten'    THEN 1
    WHEN 'zeichen'   THEN 2
    WHEN 'woerter'   THEN 3
    WHEN 'minuten'   THEN 4
    WHEN 'keine'     THEN 5
    WHEN 'unbekannt' THEN 6
    ELSE 7
  END;