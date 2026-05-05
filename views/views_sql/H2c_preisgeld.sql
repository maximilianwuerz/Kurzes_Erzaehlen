CREATE OR REPLACE VIEW "H2c_preisgeld" AS
WITH src AS (
  SELECT
    lw.literaturwettbewerb_id,
    lw.literaturwettbewerb_name,
    COALESCE(lw.preisart, '')    AS preise_angabe,
    COALESCE(lw.hoehe_preisgeld, '') AS preisgeld_angabe,
    lower(btrim(regexp_replace(COALESCE(lw.hoehe_preisgeld, ''), '\s+', ' ', 'g'))) AS t_norm,
    POSITION('preisgeld' IN LOWER(COALESCE(lw.preisart, ''))) > 0 AS has_preisgeld_hint
  FROM literaturwettbewerb AS lw
),
nums AS (
  SELECT
    s.*,
    -- größter im Text vorkommender EUR-Betrag (z. B. bei "100-500€" -> 500, bei "7.500€ gesamt" -> 7500)
    (
      SELECT MAX((regexp_replace(m[1], '[^0-9]', '', 'g'))::int)
      FROM regexp_matches(s.t_norm, '([0-9][0-9\.\,]*)', 'g') AS m
    ) AS max_eur
  FROM src AS s
),
final AS (
  SELECT
    n.literaturwettbewerb_id,
    n.literaturwettbewerb_name,
    n.preisgeld_angabe,
    CASE
      WHEN position('gesamt' IN n.t_norm) > 0 THEN NULL
      ELSE n.max_eur
    END AS hoechstes_einzel_preisgeld_euro,
    CASE
      WHEN position('gesamt' IN n.t_norm) > 0 THEN n.max_eur
      ELSE NULL
    END AS gesamtwert_preisgeld_eur,
	n.has_preisgeld_hint
  FROM nums AS n
)
SELECT
  literaturwettbewerb_id,
  literaturwettbewerb_name,
  preisgeld_angabe,
  hoechstes_einzel_preisgeld_euro,
  gesamtwert_preisgeld_eur
FROM final
WHERE
  -- nur Wettbewerbe mit auswertbarem Preisgeld anzeigen
  has_preisgeld_hint
  OR hoechstes_einzel_preisgeld_euro IS NOT NULL 
  OR gesamtwert_preisgeld_eur IS NOT NULL
ORDER BY literaturwettbewerb_name;