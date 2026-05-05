CREATE OR REPLACE VIEW "H2c_preisarten" AS
WITH base AS (
  SELECT
    lw.literaturwettbewerb_id,
    COALESCE(lw.preisart, '') AS preise_raw
  FROM literaturwettbewerb AS lw
),
tokens AS (
  SELECT
    b.literaturwettbewerb_id,
    NULLIF(btrim(lower(tok)), '') AS tok
  FROM base b
  LEFT JOIN LATERAL regexp_split_to_table(b.preise_raw, E'\\s*;\\s*') AS s(tok) ON TRUE
),
mapped AS (
  SELECT
    t.literaturwettbewerb_id,
    CASE
      WHEN tok IS NULL OR tok IN ('/', 'keine', 'keine info', 'n/a', 'na') THEN 'Keine Angabe'
      WHEN tok LIKE '%preisgeld%'                    THEN 'Preisgeld'
      WHEN tok LIKE '%publikation%' 				 THEN 'Publikation'
      WHEN tok LIKE '%buchpreis%' OR tok LIKE '%belegexemplar%' OR tok LIKE '%bücher%' THEN 'Buchpreise'
      WHEN tok LIKE '%workshop%' OR tok LIKE '%sprechcoaching%' THEN 'Workshop/Coaching'
      WHEN tok LIKE 'reise%'                        THEN 'Reise'
      WHEN tok LIKE '%auftritt%'                     THEN 'Auftritt'
      WHEN tok LIKE '%jurymitgliedschaft%'           THEN 'Jurymitgliedschaft'
      WHEN tok LIKE '%auszeichnung%'                 THEN 'Auszeichnung'
      WHEN tok LIKE '%überraschungspaket%' OR tok LIKE '%ueberraschungspaket%' THEN 'Sachpreise'
      WHEN tok LIKE '%sachpreis%' OR tok LIKE '%bronze%' OR tok LIKE '%kleinplastik%' OR tok LIKE '%gutschein%' THEN 'Sachpreise'
      ELSE 'Sonstiges'
    END AS preisart
  FROM tokens t
)
SELECT
  preisart,
  COUNT(DISTINCT literaturwettbewerb_id) AS anzahlwettbewerbe,
  ROUND(
    100.0 * COUNT(DISTINCT literaturwettbewerb_id)
    / NULLIF((SELECT COUNT(DISTINCT literaturwettbewerb_id) FROM literaturwettbewerb), 0),
    2
  ) AS prozent
FROM mapped
GROUP BY preisart
ORDER BY
  CASE preisart
    WHEN 'Preisgeld'            THEN 1
    WHEN 'Publikation'          THEN 2
    WHEN 'Buchpreise'           THEN 3
    WHEN 'Sachpreise'           THEN 4
    WHEN 'Workshop/Coaching'    THEN 5
    WHEN 'Reise'                THEN 6
    WHEN 'Auftritt'             THEN 7
    WHEN 'Jurymitgliedschaft'   THEN 8
    WHEN 'Auszeichnung'         THEN 9
    WHEN 'Sonstiges'            THEN 10
    WHEN 'Keine Angabe'         THEN 11
    ELSE 12
  END;