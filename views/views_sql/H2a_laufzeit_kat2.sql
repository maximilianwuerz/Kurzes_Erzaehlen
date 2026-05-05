CREATE OR REPLACE VIEW "H2a_laufzeit_kat2" AS
WITH basis AS (
  SELECT
    substring(lw.erstausrichtung::text FROM '((19|20)[0-9]{2})')::int AS start_jahr,
    2008::int AS fenster_start,
    2023::int AS fenster_ende
  FROM literaturwettbewerb AS lw
),
klass AS (
  SELECT
    CASE
      WHEN start_jahr IS NULL THEN 'unbekannt'
      WHEN start_jahr > fenster_ende THEN 'außerhalb (0 Jahre im Fenster)'
      WHEN start_jahr < fenster_start THEN 'vor 2008 gestartet (>16 Jahre)'
      WHEN (fenster_ende - GREATEST(start_jahr, fenster_start) + 1) BETWEEN 9 AND 16 THEN 'lang (9–16 Jahre)'
      WHEN (fenster_ende - GREATEST(start_jahr, fenster_start) + 1) BETWEEN 4 AND 8  THEN 'mittel (4–8 Jahre)'
      WHEN (fenster_ende - GREATEST(start_jahr, fenster_start) + 1) BETWEEN 1 AND 3  THEN 'kurz (1–3 Jahre)'
      ELSE 'unbekannt'
    END AS laufzeit_kategorie
  FROM basis
)
SELECT
  laufzeit_kategorie,
  COUNT(*) AS anzahl
FROM klass
GROUP BY laufzeit_kategorie
ORDER BY
  CASE laufzeit_kategorie
    WHEN 'vor 2008 gestartet (>16 Jahre)' THEN 1
    WHEN 'lang (9–16 Jahre)'                        THEN 2
    WHEN 'mittel (4–8 Jahre)'                       THEN 3
    WHEN 'kurz (1–3 Jahre)'                         THEN 4
    ELSE 5
  END;