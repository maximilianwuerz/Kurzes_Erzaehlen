CREATE OR REPLACE VIEW "H8b_jahresauflage" AS
WITH auflage_pro_heft AS (
  SELECT
    l.literaturzeitschrift_id,
    l.auflagenhoehe AS auflagen_raw,
    lower(coalesce(l.auflagenhoehe, '')) AS a_lc,
    -- erste Zahl (mit Tausenderpunkten) extrahieren und säubern
    NULLIF(regexp_replace(SUBSTRING(lower(coalesce(l.auflagenhoehe, '')) FROM '(\d{1,3}(?:[.\s]\d{3})*|\d+)'), '[.\s]', '', 'g'), '')::int AS n1,
    -- zweite Zahl (bei Bereichen: "bis", "-", "–", "/")
    NULLIF(regexp_replace(SUBSTRING(lower(coalesce(l.auflagenhoehe, '')) FROM '(?:bis|-|–|/)\s(\d{1,3}(?:[.\s]\d{3})|\d+)'), '[.\s]', '', 'g'), '')::int AS n2,
    -- Marker für "Tsd."/"tausend"
    (lower(coalesce(l.auflagenhoehe, '')) LIKE '%tsd%' OR lower(coalesce(l.auflagenhoehe, '')) LIKE '%tausend%') AS is_thousand
  FROM literaturzeitschrift l
),
parsed AS (
  SELECT
    a.literaturzeitschrift_id,
    a.auflagen_raw,
    CASE
      WHEN a.n1 IS NULL THEN NULL
      WHEN a.n2 IS NOT NULL THEN ROUND(((a.n1 + a.n2) / 2.0))::int
      ELSE a.n1
    END AS val_num,
    a.is_thousand
  FROM auflage_pro_heft a
),
heft AS (
  SELECT
    p.literaturzeitschrift_id,
    CASE
      WHEN val_num IS NULL THEN NULL
      WHEN is_thousand THEN (val_num * 1000)
      ELSE val_num
    END AS auflage_pro_heft
  FROM parsed p
),
freq AS (
  SELECT
    f.literaturzeitschrift_id,
    f.issues_min,
    f.issues_max,
    CASE
      WHEN f.issues_min IS NULL AND f.issues_max IS NULL THEN NULL
      WHEN f.issues_min IS NULL THEN f.issues_max::numeric
      WHEN f.issues_max IS NULL THEN f.issues_min::numeric
      ELSE ((f.issues_min + f.issues_max) / 2.0)::numeric
    END AS issues_mid
  FROM "H8b_publikationszyklus" f
)
SELECT
  h.literaturzeitschrift_id,
  h.auflage_pro_heft,
  f.issues_min,
  f.issues_max,
  f.issues_mid,
  CASE
    WHEN h.auflage_pro_heft IS NULL OR f.issues_mid IS NULL THEN NULL
    ELSE ROUND(h.auflage_pro_heft * f.issues_mid)::bigint
  END AS jahresauflage_mid
FROM heft h
LEFT JOIN freq f USING (literaturzeitschrift_id);



-- Verteilung (Buckets) der Jahresauflagen
CREATE OR REPLACE VIEW "H8b_jahresauflage_gestaffelt" AS
WITH x AS (
  SELECT jahresauflage_mid
  FROM "H8b_jahresauflage"
  WHERE jahresauflage_mid IS NOT NULL AND jahresauflage_mid > 0
),
b AS (
  SELECT
    CASE
      WHEN jahresauflage_mid < 1000   THEN '<1.000'
      WHEN jahresauflage_mid < 3000   THEN '1.000-2.999'
      WHEN jahresauflage_mid < 5000   THEN '3.000-4.999'
      WHEN jahresauflage_mid < 10000  THEN '5.000-9.999'
      WHEN jahresauflage_mid < 20000  THEN '10.000-19.999'
      ELSE '20.000+'
    END AS staffel,
    COUNT(*) AS anzahl
  FROM x
  GROUP BY 1
)
SELECT staffel, anzahl
FROM b
ORDER BY array_position(ARRAY['<1.000','1.000-2.999','3.000-4.999','5.000-9.999','10.000-19.999','20.000+'], staffel);



-- Median der Jahresauflagen (optional mit N)
CREATE OR REPLACE VIEW "H8b_jahresauflage_median" AS
SELECT
  COUNT(*) AS n_titel,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY jahresauflage_mid) AS median_jahresauflage
FROM "H8b_jahresauflage"
WHERE jahresauflage_mid IS NOT NULL AND jahresauflage_mid > 0;