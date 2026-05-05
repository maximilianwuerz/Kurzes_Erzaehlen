
-- Indikatoren (1/0):
--   has_jury            = jury_2023 nicht leer
--   has_preisgeld       = preisart ILIKE '%preisgeld%'
--   has_folgepublikation= publikation ILIKE 'ja%'
--   has_liveevent       = live_event ILIKE 'ja%'
--   has_website         = website nicht leer
--   is_regelmaessig     = ausrichtungszyklus klar (NICHT 'keine info'/'ungefähr'/'alle paar') UND nicht NULL
--   has_5years          = (aktuelles Jahr − erstausrichtung) >= 5
-- Score = hits / 7.0
-- Klassifikation (score-basiert):
--   score >= 0.75  → 'professionell'
--   0.50 <= score < 0.75 → 'semi-professionell'
--   score < 0.50  → 'nicht professionell'

CREATE OR REPLACE VIEW public."H13a_lw_score" AS
SELECT
  lw.literaturwettbewerb_id,
  lw.literaturwettbewerb_name,

  -- Indikatoren
  CASE WHEN NULLIF(TRIM(lw.jury_2023), '') IS NOT NULL THEN 1 ELSE 0 END AS has_jury,
  CASE WHEN lw.preisart ILIKE '%preisgeld%'          THEN 1 ELSE 0 END AS has_preisgeld,
  CASE WHEN lw.publikation ILIKE 'ja%'               THEN 1 ELSE 0 END AS has_folgepublikation,
  CASE WHEN lw.live_event ILIKE 'ja%'                THEN 1 ELSE 0 END AS has_liveevent,
  CASE WHEN NULLIF(TRIM(lw.website), '') IS NOT NULL THEN 1 ELSE 0 END AS has_website,
  CASE
    WHEN lw.ausrichtungszyklus IS NOT NULL
     AND NOT (
          lw.ausrichtungszyklus ILIKE '%keine info%'
       OR lw.ausrichtungszyklus ILIKE '%ungefähr%'
       OR lw.ausrichtungszyklus ILIKE '%alle paar%'
     )
    THEN 1 ELSE 0
  END AS is_regelmaessig,
  CASE
    WHEN lw.erstausrichtung ~ '^\d{4}'
     AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - (substring(lw.erstausrichtung FROM '^\d{4}')::int)) >= 5
    THEN 1 ELSE 0
  END AS has_5years,

  -- Trefferzahl (feste 7 Indikatoren)
  (
    (CASE WHEN NULLIF(TRIM(lw.jury_2023), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN lw.preisart ILIKE '%preisgeld%'          THEN 1 ELSE 0 END) +
    (CASE WHEN lw.publikation ILIKE 'ja%'               THEN 1 ELSE 0 END) +
    (CASE WHEN lw.live_event ILIKE 'ja%'                THEN 1 ELSE 0 END) +
    (CASE WHEN NULLIF(TRIM(lw.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE
       WHEN lw.ausrichtungszyklus IS NOT NULL
        AND NOT (
             lw.ausrichtungszyklus ILIKE '%keine info%'
          OR lw.ausrichtungszyklus ILIKE '%ungefähr%'
          OR lw.ausrichtungszyklus ILIKE '%alle paar%'
        )
       THEN 1 ELSE 0 END) +
    (CASE
       WHEN lw.erstausrichtung ~ '^\d{4}'
        AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - (substring(lw.erstausrichtung FROM '^\d{4}')::int)) >= 5
       THEN 1 ELSE 0 END)
  ) AS hits,

  7 AS indicators_total,

  ROUND((
    (CASE WHEN NULLIF(TRIM(lw.jury_2023), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN lw.preisart ILIKE '%preisgeld%'          THEN 1 ELSE 0 END) +
    (CASE WHEN lw.publikation ILIKE 'ja%'               THEN 1 ELSE 0 END) +
    (CASE WHEN lw.live_event ILIKE 'ja%'                THEN 1 ELSE 0 END) +
    (CASE WHEN NULLIF(TRIM(lw.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE
       WHEN lw.ausrichtungszyklus IS NOT NULL
        AND NOT (
             lw.ausrichtungszyklus ILIKE '%keine info%'
          OR lw.ausrichtungszyklus ILIKE '%ungefähr%'
          OR lw.ausrichtungszyklus ILIKE '%alle paar%'
        )
       THEN 1 ELSE 0 END) +
    (CASE
       WHEN lw.erstausrichtung ~ '^\d{4}'
        AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - (substring(lw.erstausrichtung FROM '^\d{4}')::int)) >= 5
       THEN 1 ELSE 0 END)
  ) / 7.0, 3) AS score,

  CASE
    WHEN (
      (CASE WHEN NULLIF(TRIM(lw.jury_2023), '') IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN lw.preisart ILIKE '%preisgeld%'          THEN 1 ELSE 0 END) +
      (CASE WHEN lw.publikation ILIKE 'ja%'               THEN 1 ELSE 0 END) +
      (CASE WHEN lw.live_event ILIKE 'ja%'                THEN 1 ELSE 0 END) +
      (CASE WHEN NULLIF(TRIM(lw.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE
         WHEN lw.ausrichtungszyklus IS NOT NULL
          AND NOT (
               lw.ausrichtungszyklus ILIKE '%keine info%'
            OR lw.ausrichtungszyklus ILIKE '%ungefähr%'
            OR lw.ausrichtungszyklus ILIKE '%alle paar%'
          )
         THEN 1 ELSE 0 END) +
      (CASE
         WHEN lw.erstausrichtung ~ '^\d{4}'
          AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - (substring(lw.erstausrichtung FROM '^\d{4}')::int)) >= 5
         THEN 1 ELSE 0 END)
    ) / 7.0 >= 0.75 THEN 'professionell'
    WHEN (
      (CASE WHEN NULLIF(TRIM(lw.jury_2023), '') IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE WHEN lw.preisart ILIKE '%preisgeld%'          THEN 1 ELSE 0 END) +
      (CASE WHEN lw.publikation ILIKE 'ja%'               THEN 1 ELSE 0 END) +
      (CASE WHEN lw.live_event ILIKE 'ja%'                THEN 1 ELSE 0 END) +
      (CASE WHEN NULLIF(TRIM(lw.website), '') IS NOT NULL THEN 1 ELSE 0 END) +
      (CASE
         WHEN lw.ausrichtungszyklus IS NOT NULL
          AND NOT (
               lw.ausrichtungszyklus ILIKE '%keine info%'
            OR lw.ausrichtungszyklus ILIKE '%ungefähr%'
            OR lw.ausrichtungszyklus ILIKE '%alle paar%'
          )
         THEN 1 ELSE 0 END) +
      (CASE
         WHEN lw.erstausrichtung ~ '^\d{4}'
          AND (EXTRACT(YEAR FROM CURRENT_DATE)::int - (substring(lw.erstausrichtung FROM '^\d{4}')::int)) >= 5
         THEN 1 ELSE 0 END)
    ) / 7.0 >= 0.50 THEN 'semi-professionell'
    ELSE 'nicht professionell'
  END AS klasse

FROM literaturwettbewerb lw
;