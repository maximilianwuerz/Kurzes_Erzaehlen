CREATE OR REPLACE VIEW "H8a_ff_engagement" AS
WITH tot AS (
  SELECT COUNT(*) AS n
  FROM ff_texte_metadaten
),
rows AS (
  SELECT 'gesamt'::text AS kategorie, t.n::bigint AS anzahl
  FROM tot t
  UNION ALL
  SELECT 'likes=0', COUNT(*)::bigint
  FROM ff_texte_metadaten
  WHERE endorsement_amount = 0
  UNION ALL
  SELECT 'likes<=1', COUNT(*)::bigint
  FROM ff_texte_metadaten
  WHERE endorsement_amount <= 1
  UNION ALL
  SELECT 'reviews=0', COUNT(*)::bigint
  FROM ff_texte_metadaten
  WHERE review_amount = 0
  UNION ALL
  SELECT 'reviews<=1', COUNT(*)::bigint
  FROM ff_texte_metadaten
  WHERE review_amount <= 1
  UNION ALL
  SELECT 'beides=0', COUNT(*)::bigint
  FROM ff_texte_metadaten
  WHERE endorsement_amount = 0 AND review_amount = 0
)
SELECT
  r.kategorie,
  r.anzahl,
  ROUND(100.0 * r.anzahl::numeric / NULLIF(t.n, 0), 2) AS prozent
FROM rows r
CROSS JOIN tot t
ORDER BY CASE r.kategorie
  WHEN 'gesamt'    THEN 0
  WHEN 'likes=0'   THEN 1
  WHEN 'likes<=1'  THEN 2
  WHEN 'reviews=0' THEN 3
  WHEN 'reviews<=1'THEN 4
  WHEN 'beides=0'  THEN 5
  ELSE 99
END;