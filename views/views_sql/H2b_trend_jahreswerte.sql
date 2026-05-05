CREATE OR REPLACE VIEW "H2b_trend_jahreswerte" AS
WITH ausgaben AS (
  SELECT
    jahr,
    COALESCE(
      (
        SELECT COUNT(DISTINCT LOWER(NULLIF(BTRIM(x), '')))
        FROM unnest(regexp_split_to_array(COALESCE(lwa.gewinnertexte, ''), E'\\s*;\\s*')) AS s(x)
        WHERE NULLIF(BTRIM(x), '') IS NOT NULL
      ),
      0
    )::int AS ke_pro_ausgabe
  FROM literaturwettbewerb_ausgabe AS lwa
)
SELECT
  jahr,
  COUNT(*) AS anzahl_ausgaben_mit_ke,
  SUM(ke_pro_ausgabe) AS summe_praemierte_ke,
  AVG(ke_pro_ausgabe)::numeric(10,3) AS avg_ke_pro_ausgabe
FROM ausgaben
GROUP BY jahr
ORDER BY jahr;