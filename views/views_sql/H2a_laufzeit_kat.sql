CREATE OR REPLACE VIEW "H2a_laufzeit_kat" AS
SELECT
  laufzeit_kategorie,
  COUNT(*) AS anzahl
FROM "H2a_laufzeit"
GROUP BY laufzeit_kategorie
ORDER BY
  CASE laufzeit_kategorie
    WHEN '0–2 Jahre'   THEN 1
    WHEN '3–5 Jahre'   THEN 2
    WHEN '6–9 Jahre'   THEN 3
    WHEN '10–19 Jahre' THEN 4
    WHEN '20+ Jahre'   THEN 5
    ELSE 6
  END;