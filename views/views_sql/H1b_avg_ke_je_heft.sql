CREATE OR REPLACE VIEW "H1b_avg_ke_je_heft" AS
WITH ke_by_issue AS (
  SELECT
    ausgabevonliteraturzeitschrift,
    COALESCE(
      cardinality(
        array_remove(
          regexp_split_to_array(COALESCE(ke_beitraege, ''), E'\\s*;\\s*'),
          ''
        )
      ),
      0
    )::int AS ke_anzahl
  FROM literaturzeitschrift_ausgabe
  WHERE ausgabevonliteraturzeitschrift IN (
    'Das GRAMM',
    'Sinn und Form',
    'Sprache im technischen Zeitalter (Spr.i.t.Z.)'
  )
),
journal_totals AS (
  SELECT * FROM (VALUES
    ('Das GRAMM'::text, 18::int),
    ('Sinn und Form'::text, 96::int),
    ('Sprache im technischen Zeitalter (Spr.i.t.Z.)'::text, 70::int)
  ) AS v(ausgabevonliteraturzeitschrift, total_issues)
),
observed AS (
  SELECT
    ausgabevonliteraturzeitschrift,
    COUNT(*)::int AS observed_issues
  FROM ke_by_issue
  GROUP BY ausgabevonliteraturzeitschrift
),
zeros AS (
  SELECT
    jt.ausgabevonliteraturzeitschrift,
    0::int AS ke_anzahl
  FROM journal_totals jt
  LEFT JOIN observed o USING (ausgabevonliteraturzeitschrift)
  CROSS JOIN generate_series(
    1,
    GREATEST(jt.total_issues - COALESCE(o.observed_issues, 0), 0)
  ) AS gs(dummy)
),
universe AS (
  SELECT ausgabevonliteraturzeitschrift, ke_anzahl FROM ke_by_issue
  UNION ALL
  SELECT ausgabevonliteraturzeitschrift, ke_anzahl FROM zeros
)
SELECT
  ausgabevonliteraturzeitschrift,
  AVG(ke_anzahl)::numeric(10,3) AS avg_ke,
  COUNT(*) AS n_hefte,
  (AVG(ke_anzahl) >= 2) AS h1b_abs_erfuellt
FROM universe
GROUP BY ausgabevonliteraturzeitschrift
ORDER BY ausgabevonliteraturzeitschrift;