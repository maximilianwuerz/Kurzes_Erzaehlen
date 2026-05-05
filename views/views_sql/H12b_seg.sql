CREATE OR REPLACE VIEW "H12b_seg" AS
SELECT
  debut_segment,
  COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL) AS n_with_age,

  COUNT(*) FILTER (WHERE age_at_debut < 25) AS n_under25,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE age_at_debut < 25)
    / NULLIF(COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL), 0), 2
  ) AS share_under25_pct,

  COUNT(*) FILTER (WHERE age_at_debut < 30) AS n_under30,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE age_at_debut < 30)
    / NULLIF(COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL), 0), 2
  ) AS share_under30_pct,

  COUNT(*) FILTER (WHERE age_at_debut < 35) AS n_under35,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE age_at_debut < 35)
    / NULLIF(COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL), 0), 2
  ) AS share_under35_pct

FROM "H12a_base"
GROUP BY debut_segment
ORDER BY debut_segment;