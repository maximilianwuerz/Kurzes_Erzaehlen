CREATE OR REPLACE VIEW public."H13a_summary" AS
WITH unioned AS (
  SELECT 'LZ'::text AS segment, klasse FROM public."H13a_lz_score"
  UNION ALL
  SELECT 'LW'::text AS segment, klasse FROM public."H13a_lw_score"
  UNION ALL
  SELECT 'OP'::text AS segment, klasse FROM public."H13a_op_score"
),
agg AS (
  SELECT
    segment,
    COUNT(*)                                                        AS n_total,
    COUNT(*) FILTER (WHERE klasse = 'professionell')                AS prof,
    COUNT(*) FILTER (WHERE klasse = 'semi-professionell')           AS semi_prof,
    COUNT(*) FILTER (WHERE klasse = 'nicht professionell')          AS nicht_prof
  FROM unioned
  GROUP BY segment
)
SELECT
  segment,
  prof,
  ROUND(100.0 * prof       / NULLIF(n_total, 0), 2) AS prof_anteil,
  semi_prof,
  ROUND(100.0 * semi_prof  / NULLIF(n_total, 0), 2) AS semi_prof_anteil,
  nicht_prof,
  ROUND(100.0 * nicht_prof / NULLIF(n_total, 0), 2) AS nicht_prof_anteil
FROM agg
ORDER BY segment
;