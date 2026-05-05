CREATE OR REPLACE VIEW "H8a_gestaffelt" AS
WITH base AS (
  SELECT endorsement_amount, review_amount
  FROM ff_texte_metadaten
),
likes AS (
  SELECT
    'likes'::text AS metric,
    CASE
      WHEN endorsement_amount = 0 THEN '0'
      WHEN endorsement_amount = 1 THEN '1'
      WHEN endorsement_amount BETWEEN 2 AND 5 THEN '2-5'
      WHEN endorsement_amount BETWEEN 6 AND 10 THEN '6-10'
      WHEN endorsement_amount BETWEEN 11 AND 20 THEN '11-20'
      WHEN endorsement_amount BETWEEN 21 AND 50 THEN '21-50'
      ELSE '51+'
    END AS bucket,
    CASE
      WHEN endorsement_amount = 0 THEN 0
      WHEN endorsement_amount = 1 THEN 1
      WHEN endorsement_amount BETWEEN 2 AND 5 THEN 2
      WHEN endorsement_amount BETWEEN 6 AND 10 THEN 3
      WHEN endorsement_amount BETWEEN 11 AND 20 THEN 4
      WHEN endorsement_amount BETWEEN 21 AND 50 THEN 5
      ELSE 6
    END AS bucket_order,
    1 AS metric_order,
    COUNT(*) AS anzahl
  FROM base
  GROUP BY 1, 2, 3, 4
),
reviews AS (
  SELECT
    'reviews'::text AS metric,
    CASE
      WHEN review_amount = 0 THEN '0'
      WHEN review_amount = 1 THEN '1'
      WHEN review_amount BETWEEN 2 AND 5 THEN '2-5'
      WHEN review_amount BETWEEN 6 AND 10 THEN '6-10'
      WHEN review_amount BETWEEN 11 AND 20 THEN '11-20'
      WHEN review_amount BETWEEN 21 AND 50 THEN '21-50'
      ELSE '51+'
    END AS bucket,
    CASE
      WHEN review_amount = 0 THEN 0
      WHEN review_amount = 1 THEN 1
      WHEN review_amount BETWEEN 2 AND 5 THEN 2
      WHEN review_amount BETWEEN 6 AND 10 THEN 3
      WHEN review_amount BETWEEN 11 AND 20 THEN 4
      WHEN review_amount BETWEEN 21 AND 50 THEN 5
      ELSE 6
    END AS bucket_order,
    2 AS metric_order,
    COUNT(*) AS anzahl
  FROM base
  GROUP BY 1, 2, 3, 4
)
SELECT
  metric,
  bucket,
  anzahl
FROM (
  SELECT metric, bucket, bucket_order, metric_order, anzahl FROM likes
  UNION ALL
  SELECT metric, bucket, bucket_order, metric_order, anzahl FROM reviews
) u
ORDER BY metric_order, bucket_order;