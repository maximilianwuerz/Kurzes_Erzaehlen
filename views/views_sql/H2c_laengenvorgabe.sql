CREATE OR REPLACE VIEW "H2c_laengenvorgabe" AS
WITH params AS (
  SELECT
    1800::int    AS chars_per_page,     -- ~1800 Zeichen pro DIN-A4-Seite
    300::int     AS words_per_page,     -- ~300 Wörter pro Seite
    220::int     AS words_per_minute,   -- ~220 Wörter/Minute (Lesegeschwindigkeit)
    5.5::numeric AS chars_per_word      -- ~5,5 Zeichen je Wort (inkl. Leerzeichen, im Mittel)
),
src AS (
  SELECT
    lw.literaturwettbewerb_id,
    lw.literaturwettbewerb_name,
    lw.laengenvorgabe_text,
    LOWER(BTRIM(lw.laengenvorgabe_text)) AS t
  FROM literaturwettbewerb AS lw
),
parsed AS (
  SELECT
    s.literaturwettbewerb_id,
    s.literaturwettbewerb_name,
    s.laengenvorgabe_text,
    s.t,
    CASE
      WHEN s.t ~ '(seite|din[-\s]*a4)' THEN 'seiten'
      WHEN s.t ~ 'zeichen' THEN 'zeichen'
      WHEN s.t ~ '(w[öo]rter|woerter|wort)' THEN 'woerter'
      WHEN s.t ~ '(min(ute)?\.?|minüt|lesedauer|lesezeit)' OR s.t ~ '\d+\s*min' THEN 'minuten'
      WHEN s.t ~ 'keine info|^keine$|^n/?a' THEN 'keine'
      ELSE 'unbekannt'
    END AS unit_detected,
    MIN(n.val_int) AS value_min,
    MAX(n.val_int) AS value_max
  FROM src AS s
  LEFT JOIN LATERAL (
    SELECT (regexp_replace(m[1], '[^0-9]', '', 'g'))::int AS val_int
    FROM regexp_matches(s.t, '([0-9][0-9\.\,]*)', 'g') AS m
  ) AS n ON TRUE
  GROUP BY s.literaturwettbewerb_id, s.literaturwettbewerb_name, s.laengenvorgabe_text, s.t
),
heuri AS (
  SELECT
    p.*,
    CASE
      WHEN p.unit_detected IN ('seiten','zeichen','woerter','minuten','keine') THEN p.unit_detected
      WHEN p.value_max IS NULL THEN 'unbekannt'
      WHEN p.value_max >= 1000 THEN 'zeichen'  -- große reine Zahlenbereiche ohne Einheit → Zeichen
      ELSE 'woerter'                           -- kleine reine Zahlenbereiche → Wörter
    END AS unit_final
  FROM parsed AS p
)
SELECT
  h.literaturwettbewerb_id,
  h.literaturwettbewerb_name,
  h.laengenvorgabe_text,
  h.unit_final AS einheit,
  h.value_min,
  h.value_max,
  -- Normalisierung: geschätzte Seiten
  CASE
    WHEN h.unit_final = 'seiten'  THEN h.value_min
    WHEN h.unit_final = 'zeichen' THEN CEIL(h.value_min::numeric / p.chars_per_page)
    WHEN h.unit_final = 'woerter' THEN CEIL(h.value_min::numeric / p.words_per_page)
    WHEN h.unit_final = 'minuten' THEN CEIL((h.value_min::numeric * p.words_per_minute) / p.words_per_page)
    ELSE NULL
  END AS est_pages_min,
  CASE
    WHEN h.unit_final = 'seiten'  THEN h.value_max
    WHEN h.unit_final = 'zeichen' THEN CEIL(h.value_max::numeric / p.chars_per_page)
    WHEN h.unit_final = 'woerter' THEN CEIL(h.value_max::numeric / p.words_per_page)
    WHEN h.unit_final = 'minuten' THEN CEIL((h.value_max::numeric * p.words_per_minute) / p.words_per_page)
    ELSE NULL
  END AS est_pages_max,
  -- Normalisierung: geschätzte Zeichen
  CASE
    WHEN h.unit_final = 'zeichen' THEN h.value_min
    WHEN h.unit_final = 'seiten'  THEN h.value_min * p.chars_per_page
    WHEN h.unit_final = 'woerter' THEN CEIL(h.value_min::numeric * p.chars_per_word)
    WHEN h.unit_final = 'minuten' THEN CEIL(h.value_min::numeric * p.words_per_minute * p.chars_per_word)
    ELSE NULL
  END AS est_chars_min,
  CASE
    WHEN h.unit_final = 'zeichen' THEN h.value_max
    WHEN h.unit_final = 'seiten'  THEN h.value_max * p.chars_per_page
    WHEN h.unit_final = 'woerter' THEN CEIL(h.value_max::numeric * p.chars_per_word)
    WHEN h.unit_final = 'minuten' THEN CEIL(h.value_max::numeric * p.words_per_minute * p.chars_per_word)
    ELSE NULL
  END AS est_chars_max
FROM heuri AS h
CROSS JOIN params AS p
ORDER BY h.literaturwettbewerb_name;