-- Online-Plattformen: H13a_op_score
-- Logik:
--  - anzahlmitglieder und anzahltexte_gesamt werden normalisiert (nur Ziffern); '?' / leer -> nicht beurteilbar
--  - Mitglieder-Indikator: Punkt nur, wenn mitglieder_num >= 1000; sonst 0; wenn NULL -> fließt NICHT in den Nenner ein
--  - Texte-Indikator: Punkt nur, wenn texte_num >= 5000; sonst 0; wenn NULL -> fließt NICHT in den Nenner ein
--  - Dynamischer Nenner: 3 Basis-Indikatoren (hasbetreiber, hasapplikation, has_5years)
--    + (1, falls Mitgliederzahl beurteilbar) + (1, falls Textmenge beurteilbar)
--  - Klassifikation per Score (wie bisher): score >= 2/3 → professionell; 1/3 ≤ score < 2/3 → semi; sonst nicht
--  - Hinweis: has_5years bezieht sich hier weiterhin auf (aktuelles Jahr - gruendungsjahr) >= 5

CREATE OR REPLACE VIEW public."H13a_op_score" AS
WITH norm AS (
  SELECT
    op.plattform_id,
    op.plattform_name,
    op.plattform_art,
    op.gruender_betreiber,
    op.gruendungsjahr,
    op.anzahl_mitglieder,
    op.anzahl_texte_gesamt,
    -- Nur Ziffern extrahieren; '' -> NULL
    NULLIF(regexp_replace(op.anzahl_mitglieder,    '[^0-9]', '', 'g'), '')::bigint AS mitglieder_num,
    NULLIF(regexp_replace(op.anzahl_texte_gesamt, '[^0-9]', '', 'g'), '')::bigint AS texte_num
  FROM plattform_internet op
)
SELECT
  n.plattform_id,
  n.plattform_name,

  -- Basis-Indikatoren (1/0)
  CASE WHEN NULLIF(TRIM(n.gruender_betreiber), '') IS NOT NULL THEN 1 ELSE 0 END AS has_betreiber,

  CASE
    WHEN n.plattform_art ILIKE '%applikation%' OR n.plattform_art ILIKE '%app%' THEN 1
    ELSE 0
  END AS has_applikation,

  CASE
    WHEN n.gruendungsjahr IS NOT NULL
     AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - n.gruendungsjahr) >= 5
    THEN 1 ELSE 0
  END AS has_5years,

  -- Dynamische Indikatoren (beurteilbar = nicht NULL)
  CASE
    WHEN n.mitglieder_num IS NULL     THEN NULL
    WHEN n.mitglieder_num >= 1000     THEN 1
    ELSE 0
  END AS has_mitglieder_1k,

  CASE
    WHEN n.texte_num IS NULL          THEN NULL
    WHEN n.texte_num >= 5000          THEN 1
    ELSE 0
  END AS has_texte_5k,

  -- Dynamischer Nenner: 3 Basis + (Mitglieder beurteilbar?) + (Texte beurteilbar?)
  (3
   + CASE WHEN n.mitglieder_num IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN n.texte_num      IS NOT NULL THEN 1 ELSE 0 END
  ) AS indicators_available,

  -- Trefferzahl (Mitglieder zählt nur bei >=1000; Texte nur bei >=5000; NULL → +0)
  (
    (CASE WHEN NULLIF(TRIM(n.gruender_betreiber), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN n.plattform_art ILIKE '%applikation%' OR n.plattform_art ILIKE '%app%' THEN 1 ELSE 0 END) +
    (CASE
       WHEN n.gruendungsjahr IS NOT NULL
        AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - n.gruendungsjahr) >= 5
       THEN 1 ELSE 0 END) +
    COALESCE(CASE WHEN n.mitglieder_num >= 1000 THEN 1 ELSE 0 END, 0) +
    COALESCE(CASE WHEN n.texte_num      >= 5000 THEN 1 ELSE 0 END, 0)
  ) AS hits,

  -- Score = hits / indicators_available
  ROUND((
    (CASE WHEN NULLIF(TRIM(n.gruender_betreiber), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN n.plattform_art ILIKE '%applikation%' OR n.plattform_art ILIKE '%app%' THEN 1 ELSE 0 END) +
    (CASE
       WHEN n.gruendungsjahr IS NOT NULL
        AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - n.gruendungsjahr) >= 5
       THEN 1 ELSE 0 END) +
    COALESCE(CASE WHEN n.mitglieder_num >= 1000 THEN 1 ELSE 0 END, 0) +
    COALESCE(CASE WHEN n.texte_num      >= 5000 THEN 1 ELSE 0 END, 0)
  )::numeric
  / NULLIF( (3
             + CASE WHEN n.mitglieder_num IS NOT NULL THEN 1 ELSE 0 END
             + CASE WHEN n.texte_num      IS NOT NULL THEN 1 ELSE 0 END
            ), 0)
  , 3) AS score,

   -- Klassifikation (Score-basiert, wie bei LZ)
  CASE
    WHEN (
      (
        (CASE WHEN NULLIF(TRIM(n.gruender_betreiber), '') IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.plattform_art ILIKE '%applikation%' OR n.plattform_art ILIKE '%app%' THEN 1 ELSE 0 END) +
        (CASE
           WHEN n.gruendungsjahr IS NOT NULL
            AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - n.gruendungsjahr) >= 5
           THEN 1 ELSE 0 END) +
        COALESCE(CASE WHEN n.mitglieder_num >= 1000 THEN 1 ELSE 0 END, 0) +
        COALESCE(CASE WHEN n.texte_num      >= 5000 THEN 1 ELSE 0 END, 0)
      )::numeric
      / NULLIF( (3
                 + CASE WHEN n.mitglieder_num IS NOT NULL THEN 1 ELSE 0 END
                 + CASE WHEN n.texte_num      IS NOT NULL THEN 1 ELSE 0 END
                ), 0)
    ) >= 0.75 THEN 'professionell'
    WHEN (
      (
        (CASE WHEN NULLIF(TRIM(n.gruender_betreiber), '') IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN n.plattform_art ILIKE '%applikation%' OR n.plattform_art ILIKE '%app%' THEN 1 ELSE 0 END) +
        (CASE
           WHEN n.gruendungsjahr IS NOT NULL
            AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - n.gruendungsjahr) >= 5
           THEN 1 ELSE 0 END) +
        COALESCE(CASE WHEN n.mitglieder_num >= 1000 THEN 1 ELSE 0 END, 0) +
        COALESCE(CASE WHEN n.texte_num      >= 5000 THEN 1 ELSE 0 END, 0)
      )::numeric
      / NULLIF( (3
                 + CASE WHEN n.mitglieder_num IS NOT NULL THEN 1 ELSE 0 END
                 + CASE WHEN n.texte_num      IS NOT NULL THEN 1 ELSE 0 END
                ), 0)
    ) >= 0.50 THEN 'semi-professionell'
    ELSE 'nicht professionell'
  END AS klasse

FROM norm n
;