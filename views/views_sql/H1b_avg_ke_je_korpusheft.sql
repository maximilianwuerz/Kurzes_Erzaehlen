CREATE OR REPLACE VIEW "H1b_avg_ke_je_korpusheft" AS
WITH hefte AS (
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
)
SELECT
  ausgabevonliteraturzeitschrift,
  AVG(ke_anzahl)::numeric(10,3) AS avg_ke,
  COUNT(*) AS n_hefte,
  (AVG(ke_anzahl) >= 2) AS h1b_abs_erfuellt
FROM hefte
GROUP BY ausgabevonliteraturzeitschrift
ORDER BY ausgabevonliteraturzeitschrift;