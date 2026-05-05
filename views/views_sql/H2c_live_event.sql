CREATE OR REPLACE VIEW "H2c_live_event" AS
WITH base AS (
  SELECT
    NULLIF(btrim(lower(regexp_replace(live_event, '\s+', ' ', 'g'))), '') AS t
  FROM literaturwettbewerb
),
klass AS (
  SELECT
    CASE
      WHEN t = 'ja' THEN 'ja'
      WHEN t IN ('ja (online)', 'ja online') THEN 'ja (online)'
      WHEN t IN ('ja (radio)', 'ja radio') THEN 'ja (radio)'
      WHEN t = 'nein' THEN 'nein'
      ELSE 'keine Info'
    END AS live_event
  FROM base
)
SELECT
  live_event,
  COUNT(*) AS anzahl_wettbewerbe,
  ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS prozent
FROM klass
GROUP BY live_event
ORDER BY
  CASE
    WHEN live_event = 'ja' THEN 1
    WHEN live_event = 'ja (online)' THEN 2
    WHEN live_event = 'ja (radio)' THEN 3
    WHEN live_event = 'nein' THEN 4
    WHEN live_event = 'keine Info' THEN 5
    ELSE 6
  END;