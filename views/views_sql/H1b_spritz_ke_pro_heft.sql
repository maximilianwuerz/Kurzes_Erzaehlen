CREATE OR REPLACE VIEW "H1b_spritz_ke_pro_heft" AS
SELECT
  lza.literaturzeitschrift_ausgabe_id,
  lza.literaturzeitschrift_id,
  lza.ausgabevonliteraturzeitschrift,
  lza.heftnummer,
  lza.erscheinungsjahr,
  COALESCE(
    cardinality(
      array_remove(
        regexp_split_to_array(COALESCE(lza.ke_beitraege, ''), E'\\s*;\\s*'),
        ''
      )
    ),
    0
  )::int AS ke_anzahl
FROM literaturzeitschrift_ausgabe AS lza
WHERE lza.ausgabevonliteraturzeitschrift = 'Sprache im technischen Zeitalter (Spr.i.t.Z.)'
ORDER BY
  CASE WHEN lza.heftnummer ~ '^[0-9]+$' THEN lza.heftnummer::int END NULLS LAST,
  lza.heftnummer;