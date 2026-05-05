CREATE OR REPLACE VIEW "H8b_publikationszyklus" AS
WITH src AS (
  SELECT
    l.literaturzeitschrift_id,
    l.publikationszyklus,
    lower(coalesce(l.publikationszyklus, '')) AS z_lc
  FROM literaturzeitschrift l
)
SELECT
  s.literaturzeitschrift_id,
  s.publikationszyklus,
  s.z_lc,
  -- minimale Ausgaben/Jahr (konservativ)
  CASE
    -- zuerst Bereiche/Sonderfälle
    WHEN s.z_lc LIKE '%ein- bis zweimal jährlich%' OR s.z_lc LIKE '%ein bis zweimal jährlich%' THEN 1
    WHEN s.z_lc LIKE '%drei bis viermal jährlich%' THEN 3
    WHEN s.z_lc LIKE '%vier bis fünfmal jährlich%' THEN 4
    WHEN s.z_lc LIKE '%alle 1 bis 2 jahre%'        THEN 1
    WHEN s.z_lc LIKE '%wechselnd%' OR s.z_lc LIKE '%unregelmäßig%' OR s.z_lc LIKE '%unregelmaessig%' OR s.z_lc LIKE '%?%' THEN NULL
    -- dann die „normalen“ Frequenzen
    WHEN s.z_lc LIKE '%monatlich%'                 THEN 12
    WHEN s.z_lc LIKE '%alle zwei monate%'          THEN 6
    WHEN s.z_lc LIKE '%sechsmal jährlich%'         THEN 6
    WHEN s.z_lc LIKE '%fünfmal jährlich%' OR s.z_lc LIKE '%fuenfmal jährlich%' OR s.z_lc LIKE '%fuenfmal jaehrlich%' THEN 5
    WHEN s.z_lc LIKE '%viermal jährlich%'          THEN 4
    WHEN s.z_lc LIKE '%vierteljährlich%'           THEN 4
    WHEN s.z_lc LIKE '%dreimal jährlich%'          THEN 3
    WHEN s.z_lc LIKE '%halbjährlich%'              THEN 2
    WHEN s.z_lc LIKE '%zweimal jährlich%'          THEN 2
    WHEN s.z_lc LIKE '%jährlich im print%'         THEN 1
    WHEN s.z_lc LIKE '%etwa jährlich%'             THEN 1
    WHEN s.z_lc LIKE '%jährlich%'                  THEN 1
    ELSE NULL
  END AS issues_min,
  -- maximale Ausgaben/Jahr (optimistisch)
  CASE
    -- zuerst Bereiche/Sonderfälle
    WHEN s.z_lc LIKE '%ein- bis zweimal jährlich%' OR s.z_lc LIKE '%ein bis zweimal jährlich%' THEN 2
    WHEN s.z_lc LIKE '%drei bis viermal jährlich%' THEN 4
    WHEN s.z_lc LIKE '%vier bis fünfmal jährlich%' THEN 5
    WHEN s.z_lc LIKE '%alle 1 bis 2 jahre%'        THEN 2
    WHEN s.z_lc LIKE '%wechselnd%' OR s.z_lc LIKE '%unregelmäßig%' OR s.z_lc LIKE '%unregelmaessig%' OR s.z_lc LIKE '%?%' THEN NULL
    -- dann die „normalen“ Frequenzen
    WHEN s.z_lc LIKE '%monatlich%'                 THEN 12
    WHEN s.z_lc LIKE '%alle zwei monate%'          THEN 6
    WHEN s.z_lc LIKE '%sechsmal jährlich%'         THEN 6
    WHEN s.z_lc LIKE '%fünfmal jährlich%' OR s.z_lc LIKE '%fuenfmal jährlich%' OR s.z_lc LIKE '%fuenfmal jaehrlich%' THEN 5
    WHEN s.z_lc LIKE '%viermal jährlich%'          THEN 4
    WHEN s.z_lc LIKE '%vierteljährlich%'           THEN 4
    WHEN s.z_lc LIKE '%dreimal jährlich%'          THEN 3
    WHEN s.z_lc LIKE '%halbjährlich%'              THEN 2
    WHEN s.z_lc LIKE '%zweimal jährlich%'          THEN 2
    WHEN s.z_lc LIKE '%jährlich im print%'         THEN 1
    WHEN s.z_lc LIKE '%etwa jährlich%'             THEN 1
    WHEN s.z_lc LIKE '%jährlich%'                  THEN 1
    ELSE NULL
  END AS issues_max
FROM src s;