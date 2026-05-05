CREATE OR REPLACE VIEW "H2a_abs" AS
WITH lw_expanded AS (
  SELECT
    lw.literaturwettbewerb_name,
    lw.erstausrichtung,
    lw.veranstalter AS veranstalter_ids,
    NULLIF(BTRIM(x.id_raw), '') AS koerperschaft_id
  FROM literaturwettbewerb AS lw
  LEFT JOIN LATERAL (
    SELECT regexp_split_to_table(COALESCE(lw.veranstalter, ''), E'\\s*;\\s*') AS id_raw
  ) AS x ON TRUE
),
lw_mapped AS (
  SELECT
    e.literaturwettbewerb_name,
    e.erstausrichtung,
    e.veranstalter_ids,
    k.koerperschaft_name
  FROM lw_expanded AS e
  LEFT JOIN koerperschaft AS k
    ON k.koerperschaft_id = e.koerperschaft_id
),
lw_agg AS (
  SELECT
    literaturwettbewerb_name,
    erstausrichtung,
    veranstalter_ids,
    NULLIF(
      string_agg(DISTINCT koerperschaft_name, '; ' ORDER BY koerperschaft_name),
      ''
    ) AS veranstalter_namen
  FROM lw_mapped
  GROUP BY literaturwettbewerb_name, erstausrichtung, veranstalter_ids
)
SELECT
  ROW_NUMBER() OVER (ORDER BY literaturwettbewerb_name) AS ZN,
  literaturwettbewerb_name,
  COALESCE(veranstalter_namen, veranstalter_ids) AS veranstalter,
  erstausrichtung
FROM lw_agg
ORDER BY literaturwettbewerb_name;