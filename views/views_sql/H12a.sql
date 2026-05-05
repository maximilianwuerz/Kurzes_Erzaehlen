CREATE OR REPLACE VIEW "H12a_base" AS
WITH p AS (
  SELECT
    p.person_id,
    p.person_name,
    p.person_username_ff,
    p.alter_ff,
    p.geburtsdatum_gnd,
    CASE
      WHEN p.geburtsdatum_gnd ~ '^\d{4}' THEN substring(p.geburtsdatum_gnd FROM '^\d{4}')::int
      ELSE NULL
    END AS geburtsjahr
  FROM person p
),
params AS (
SELECT 2024::int AS scrape_year
),
src_buch AS (
  SELECT
    pr.person_id,
    b.publikationsjahr AS jahr,
    'B'::text AS debut_segment
  FROM person_rolle_objekt pr
  JOIN buch b ON b.isbn = pr.objekt_id
  WHERE pr.objekt_typ = 'Buch'
    AND pr.rolle = 'VerfasserIn Buch'
    AND b.publikationsjahr IS NOT NULL
),
src_lz AS (
  SELECT
    pr.person_id,
    ("erscheinungsjahr")::int AS jahr,
    'LZ'::text AS debut_segment
  FROM person_rolle_objekt pr
  JOIN "literaturzeitschrift_ausgabe" lza
    ON lza.literaturzeitschrift_ausgabe_id = pr.objekt_id
  WHERE pr.objekt_typ = 'Literaturzeitschrift Ausgabe'
    AND pr.rolle = 'Verfasser Zeitschriftbeitrag'
    AND lza."erscheinungsjahr" ~ '^\d{4}'
),
src_lw AS (
  SELECT
    pr.person_id,
    lwa.jahr AS jahr,
    'LW'::text AS debut_segment
  FROM person_rolle_objekt pr
  JOIN "literaturwettbewerb_ausgabe" lwa
    ON lwa.literaturwettbewerb_ausgabe_id = pr.objekt_id
  WHERE pr.objekt_typ = 'Literaturwettbewerb Ausgabe'
    AND pr.rolle = 'GewinnerIn'
    AND lwa.jahr IS NOT NULL
),
src_op AS (
  SELECT
    p.person_id,
    EXTRACT(YEAR FROM f.creation_date)::int AS jahr,
    'OP'::text AS debut_segment,
    p.alter_ff
  FROM ff_texte_metadaten f
  JOIN person p
    ON lower(p.person_username_ff) = lower(f.author_username)
  WHERE f.creation_date IS NOT NULL
),
unioned AS (
  SELECT person_id, jahr, debut_segment, NULL::int AS alter_ff FROM src_buch
  UNION ALL
  SELECT person_id, jahr, debut_segment, NULL::int            FROM src_lz
  UNION ALL
  SELECT person_id, jahr, debut_segment, NULL::int            FROM src_lw
  UNION ALL
  SELECT person_id, jahr, debut_segment, alter_ff             FROM src_op
),
ranked AS (
  SELECT
    u.*,
    ROW_NUMBER() OVER (PARTITION BY u.person_id ORDER BY u.jahr ASC, u.debut_segment ASC) AS rn
  FROM unioned u
  WHERE u.jahr IS NOT NULL
),
debut AS (
  SELECT
    r.person_id,
    r.jahr         AS debut_year,
    r.debut_segment,
    r.alter_ff
  FROM ranked r
  WHERE r.rn = 1
),
calc AS (
  SELECT
    d.person_id,
    d.debut_year,
    d.debut_segment,
    CASE
      WHEN d.debut_segment = 'OP' AND p.alter_ff IS NOT NULL THEN GREATEST(0, p.alter_ff - (params.scrape_year - d.debut_year))
      WHEN p.geburtsjahr IS NOT NULL AND d.debut_year IS NOT NULL THEN d.debut_year - p.geburtsjahr
      ELSE NULL
    END AS age_at_debut
  FROM debut d
  JOIN p ON p.person_id = d.person_id
  CROSS JOIN params
)
SELECT
  p.person_id,
  p.person_name,
  c.debut_year,
  c.debut_segment,
  c.age_at_debut,
  CASE
    WHEN c.age_at_debut IS NULL THEN NULL
    WHEN c.age_at_debut < 30 THEN TRUE
    ELSE FALSE
  END AS under_30
FROM calc c
JOIN p ON p.person_id = c.person_id
;

-- View: H12a
-- Anteil unter 30 (gesamt) auf Basis von h12a_base
CREATE OR REPLACE VIEW "H12a" AS
SELECT
  COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL) AS n_with_age,
  COUNT(*) FILTER (WHERE age_at_debut < 25) AS n_under25,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE age_at_debut < 25)
    / NULLIF(COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL), 0), 2
  ) AS share_under25_pct,
  
 COUNT(*) FILTER (WHERE age_at_debut < 30) AS n_under30,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE age_at_debut < 30)
    / NULLIF(COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL), 0), 2
  ) AS share_under30_pct,

  COUNT(*) FILTER (WHERE age_at_debut < 35) AS n_under35,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE age_at_debut < 35)
    / NULLIF(COUNT(*) FILTER (WHERE age_at_debut IS NOT NULL), 0), 2
  ) AS share_under35_pct

FROM "H12a_base"
;