CREATE OR REPLACE VIEW "H2a_laufzeit" AS
WITH basis AS (
  SELECT
    lw.literaturwettbewerb_name,
    substring(lw.erstausrichtung::text FROM '((19|20)[0-9]{2})')::int AS start_jahr,
    2023::int AS bezugsjahr  -- alternativ: EXTRACT(YEAR FROM CURRENT_DATE)::int
  FROM literaturwettbewerb AS lw
)
SELECT
  literaturwettbewerb_name,
  start_jahr,
  CASE WHEN start_jahr IS NOT NULL THEN (bezugsjahr - start_jahr + 1) END AS laufzeit_jahre,
  CASE
    WHEN start_jahr IS NULL THEN 'unbekannt'
    WHEN (bezugsjahr - start_jahr + 1) >= 20 THEN '20+ Jahre'
    WHEN (bezugsjahr - start_jahr + 1) >= 10 THEN '10–19 Jahre'
    WHEN (bezugsjahr - start_jahr + 1) >= 6  THEN '6–9 Jahre'
    WHEN (bezugsjahr - start_jahr + 1) >= 3  THEN '3–5 Jahre'
    ELSE '0–2 Jahre'
  END AS laufzeit_kategorie
FROM basis
ORDER BY laufzeit_jahre DESC NULLS LAST, literaturwettbewerb_name;
