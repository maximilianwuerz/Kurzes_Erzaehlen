CREATE OR REPLACE VIEW "H1b_total_ke_je_zeitschrift" AS
SELECT
  ausgabevonliteraturzeitschrift,
  SUM(
    COALESCE(
      cardinality(
        array_remove(
          regexp_split_to_array(COALESCE(ke_beitraege, ''), E'\\s*;\\s*'),
          ''
        )
      ),
      0
    )
  )::int AS total_ke
FROM literaturzeitschrift_ausgabe
WHERE ausgabevonliteraturzeitschrift IN (
  'Das GRAMM',
  'Sinn und Form',
  'Sprache im technischen Zeitalter (Spr.i.t.Z.)'
)
GROUP BY ausgabevonliteraturzeitschrift
ORDER BY ausgabevonliteraturzeitschrift;