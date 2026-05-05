CREATE OR REPLACE VIEW "H2c_publikation" AS
WITH base AS (
  SELECT
    NULLIF(btrim(lower(publikation)), '') AS t
  FROM literaturwettbewerb
),
klass AS (
  SELECT
    CASE
      WHEN t = 'ja' THEN 'ja'
      ELSE 'keine Info'
    END AS publikation
  FROM base
)
SELECT
  publikation,
  COUNT(*) AS anzahl_wettbewerbe,
  ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS prozent
FROM klass
GROUP BY publikation
ORDER BY CASE WHEN publikation = 'ja' THEN 1 ELSE 2 END;