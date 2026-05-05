CREATE OR REPLACE VIEW "H8b_auflagenhoehe_zeitschriften_gestaffelt" AS
WITH x AS (
  SELECT auflage_pro_heft
  FROM "H8b_auflagenhoehe_zeitschriften"
  WHERE auflage_pro_heft IS NOT NULL AND auflage_pro_heft > 0
),
b AS (
  SELECT
    CASE
      WHEN auflage_pro_heft < 1000 THEN '<1.000'
      WHEN auflage_pro_heft < 3000 THEN '1.000-2.999'
      WHEN auflage_pro_heft < 5000 THEN '3.000-4.999'
      WHEN auflage_pro_heft < 10000 THEN '5.000-9.999'
      WHEN auflage_pro_heft < 20000 THEN '10.000-19.999'
      ELSE '20.000+'
    END AS staffel,
    COUNT(*) AS anzahl
  FROM x
  GROUP BY 1
)
SELECT
  staffel,
  anzahl
FROM b
ORDER BY array_position(ARRAY['<1.000','1.000-2.999','3.000-4.999','5.000-9.999','10.000-19.999','20.000+'], staffel);