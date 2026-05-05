CREATE OR REPLACE VIEW "H2b_avg" AS
WITH ausgaben AS (
  SELECT
    lwa.literaturwettbewerb_id,
    lwa.vonliteraturwettbewerb,
    lwa.literaturwettbewerb_ausgabe_id,
    COALESCE((
      SELECT COUNT(DISTINCT LOWER(NULLIF(BTRIM(x.txt), '')))
      FROM unnest(regexp_split_to_array(COALESCE(lwa.gewinnertexte, ''), E'\\s*;\\s*')) AS x(txt)
      WHERE NULLIF(BTRIM(x.txt), '') IS NOT NULL
    ), 0)::int AS texte_pro_ausgabe
  FROM literaturwettbewerb_ausgabe AS lwa
)
SELECT
  literaturwettbewerb_id,
  vonliteraturwettbewerb AS literaturwettbewerb_name,
  AVG(texte_pro_ausgabe)::numeric(10,3) AS avg_texte_pro_ausgabe,
  SUM(texte_pro_ausgabe)::int AS summe_texte,
  COUNT(*) AS anzahl_ausgaben
FROM ausgaben
GROUP BY literaturwettbewerb_id, vonliteraturwettbewerb
ORDER BY vonliteraturwettbewerb;