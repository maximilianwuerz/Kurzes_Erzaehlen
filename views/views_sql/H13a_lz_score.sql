-- Logik:
--  - Auflagenhöhe wird nur berücksichtigt, wenn ein parsebarer Wert in H8b_auflagenhoehe_zeitschriften.auflage_pro_heft vorliegt;
--    Punkt gibt es erst ab >= 1000; fehlt der Wert, fließt er NICHT in den Nenner ein.
--  - has_5years bezieht sich auf das Ende des Beobachtungszeitraums (2023) mit Schwelle >= 3 Jahre.
--  - Klassifikation über den Score: score >= 0.75 → professionell; 0.50 <= score < 0.75 → semi-professionell; score < 0.50 → nicht professionell.

CREATE OR REPLACE VIEW public."H13a_lz_score" AS
SELECT
  lz.literaturzeitschrift_id,
  lz.literaturzeitschrift_name,

  -- Basis-Indikatoren (1/0)
  CASE WHEN NULLIF(TRIM(lz.literaturzeitschrift_creator), '')    IS NOT NULL THEN 1 ELSE 0 END AS has_creator,
  CASE WHEN NULLIF(TRIM(lz.literaturzeitschriftverlegtvon), '') IS NOT NULL THEN 1 ELSE 0 END AS has_organisation,
  CASE
    WHEN lz.publikationszyklus IS NOT NULL
     AND NOT (
          lz.publikationszyklus ILIKE '%?%'
       OR lz.publikationszyklus ILIKE '%keine info%'
       OR lz.publikationszyklus ILIKE '%ungefähr%'
       OR lz.publikationszyklus ILIKE '%un-regelmäßig%'
       OR lz.publikationszyklus ILIKE '%unregelmäßig%'
       OR lz.publikationszyklus ILIKE '%wechselnd%'
     )
    THEN 1 ELSE 0
  END AS is_regelmaessig,
  CASE WHEN NULLIF(TRIM(lz.website), '') IS NOT NULL THEN 1 ELSE 0 END AS has_website,
  CASE
    WHEN lz.erstveroeffentlichung ~ '^\d{4}'
     AND (2023 - (substring(lz.erstveroeffentlichung FROM '^\d{4}')::int)) >= 3
    THEN 1 ELSE 0
  END AS has_5years,

  -- Auflage (dynamisch): nur wenn auflage_pro_heft vorhanden → fließt in Denominator ein; Punkt erst ab >= 1000
  CASE
    WHEN a.auflage_pro_heft IS NULL THEN NULL
    WHEN a.auflage_pro_heft >= 1000 THEN 1
    ELSE 0
  END AS hasauflage1k,

  -- Dynamischer Nenner: 5 Basis-Indikatoren + (1, falls Auflage parsebar; sonst 0)
  (5 + CASE WHEN a.auflage_pro_heft IS NOT NULL THEN 1 ELSE 0 END) AS indicators_available,

  -- Trefferzahl (Auflage zählt nur, wenn vorhanden und >= 1000 → +1; wenn vorhanden aber <1000 → +0; wenn NULL → +0)
  (
    (CASE WHEN NULLIF(TRIM(lz.literaturzeitschrift_creator), '')    IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN NULLIF(TRIM(lz.literaturzeitschriftverlegtvon), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE
       WHEN lz.publikationszyklus IS NOT NULL
        AND NOT (
             lz.publikationszyklus ILIKE '%?%'
          OR lz.publikationszyklus ILIKE '%keine info%'
          OR lz.publikationszyklus ILIKE '%ungefähr%'
          OR lz.publikationszyklus ILIKE '%un-regelmäßig%'
          OR lz.publikationszyklus ILIKE '%unregelmäßig%'
          OR lz.publikationszyklus ILIKE '%wechselnd%'
        )
       THEN 1 ELSE 0 END) +
    (CASE WHEN NULLIF(TRIM(lz.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE
       WHEN lz.erstveroeffentlichung ~ '^\d{4}'
        AND (2023 - (substring(lz.erstveroeffentlichung FROM '^\d{4}')::int)) >= 3
       THEN 1 ELSE 0 END) +
    COALESCE(CASE WHEN a.auflage_pro_heft >= 1000 THEN 1 ELSE 0 END, 0)
  ) AS hits,

  -- Score = hits / indicators_available
  ROUND(
    (
      (CASE WHEN NULLIF(TRIM(lz.literaturzeitschrift_creator), '')    IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN NULLIF(TRIM(lz.literaturzeitschriftverlegtvon), '') IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE
         WHEN lz.publikationszyklus IS NOT NULL
          AND NOT (
               lz.publikationszyklus ILIKE '%?%'
            OR lz.publikationszyklus ILIKE '%keine info%'
            OR lz.publikationszyklus ILIKE '%ungefähr%'
            OR lz.publikationszyklus ILIKE '%un-regelmäßig%'
            OR lz.publikationszyklus ILIKE '%unregelmäßig%'
            OR lz.publikationszyklus ILIKE '%wechselnd%'
          )
         THEN 1 ELSE 0 END) +
      (CASE WHEN NULLIF(TRIM(lz.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE
         WHEN lz.erstveroeffentlichung ~ '^\d{4}'
          AND (2023 - (substring(lz.erstveroeffentlichung FROM '^\d{4}')::int)) >= 3
         THEN 1 ELSE 0 END) +
      COALESCE(CASE WHEN a.auflage_pro_heft >= 1000 THEN 1 ELSE 0 END, 0)
    )::numeric
    / (5 + CASE WHEN a.auflage_pro_heft IS NOT NULL THEN 1 ELSE 0 END)
  , 3) AS score,

  -- Klassifikation über Score
  CASE
    WHEN (
      (
        (CASE WHEN NULLIF(TRIM(lz.literaturzeitschrift_creator), '')    IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN NULLIF(TRIM(lz.literaturzeitschriftverlegtvon), '') IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE
           WHEN lz.publikationszyklus IS NOT NULL
            AND NOT (
                 lz.publikationszyklus ILIKE '%?%'
              OR lz.publikationszyklus ILIKE '%keine info%'
              OR lz.publikationszyklus ILIKE '%ungefähr%'
              OR lz.publikationszyklus ILIKE '%un-regelmäßig%'
              OR lz.publikationszyklus ILIKE '%unregelmäßig%'
              OR lz.publikationszyklus ILIKE '%wechselnd%'
            )
           THEN 1 ELSE 0 END) +
        (CASE WHEN NULLIF(TRIM(lz.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE
           WHEN lz.erstveroeffentlichung ~ '^\d{4}'
            AND (2023 - (substring(lz.erstveroeffentlichung FROM '^\d{4}')::int)) >= 3
           THEN 1 ELSE 0 END) +
        COALESCE(CASE WHEN a.auflage_pro_heft >= 1000 THEN 1 ELSE 0 END, 0)
      )::numeric
      / (5 + CASE WHEN a.auflage_pro_heft IS NOT NULL THEN 1 ELSE 0 END)
    ) >= 0.75 THEN 'professionell'
    WHEN (
      (
        (CASE WHEN NULLIF(TRIM(lz.literaturzeitschrift_creator), '')    IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN NULLIF(TRIM(lz.literaturzeitschriftverlegtvon), '') IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE
           WHEN lz.publikationszyklus IS NOT NULL
            AND NOT (
                 lz.publikationszyklus ILIKE '%?%'
              OR lz.publikationszyklus ILIKE '%keine info%'
              OR lz.publikationszyklus ILIKE '%ungefähr%'
              OR lz.publikationszyklus ILIKE '%un-regelmäßig%'
              OR lz.publikationszyklus ILIKE '%unregelmäßig%'
              OR lz.publikationszyklus ILIKE '%wechselnd%'
            )
           THEN 1 ELSE 0 END) +
        (CASE WHEN NULLIF(TRIM(lz.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE
           WHEN lz.erstveroeffentlichung ~ '^\d{4}'
            AND (2023 - (substring(lz.erstveroeffentlichung FROM '^\d{4}')::int)) >= 3
           THEN 1 ELSE 0 END) +
        COALESCE(CASE WHEN a.auflage_pro_heft >= 1000 THEN 1 ELSE 0 END, 0)
      )::numeric
      / (5 + CASE WHEN a.auflage_pro_heft IS NOT NULL THEN 1 ELSE 0 END)
    ) >= 0.50 THEN 'semi-professionell'
    ELSE 'nicht professionell'
  END AS klasse

FROM literaturzeitschrift lz
LEFT JOIN "H8b_auflagenhoehe_zeitschriften" a
  ON a.literaturzeitschrift_id = lz.literaturzeitschrift_id
;