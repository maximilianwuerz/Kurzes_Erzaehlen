CREATE OR REPLACE VIEW "H8b_auflagenhoehe_zeitschriften"
 WITH base AS (
         SELECT l.literaturzeitschrift_id,
            l.auflagenhoehe AS auflagen_raw,
            lower(COALESCE(l.auflagenhoehe, ''::character varying)::text) AS a_lc
           FROM literaturzeitschrift l
        ), nums AS (
         SELECT b.literaturzeitschrift_id,
            b.auflagen_raw,
            b.a_lc,
            NULLIF(regexp_replace("substring"(b.a_lc, '(\d{1,3}(?:[.\s]\d{3})*|\d+)'::text), '[.\s]'::text, ''::text, 'g'::text), ''::text) AS n1_txt,
            NULLIF(regexp_replace("substring"(b.a_lc, '(?:bis|-|–|/)\s(\d{1,3}(?:[.\s]\d{3})|\d+)'::text), '[.\s]'::text, ''::text, 'g'::text), ''::text) AS n2_txt,
            b.a_lc ~~ '%tsd%'::text OR b.a_lc ~~ '%tausend%'::text AS is_thousand
           FROM base b
        ), parsed AS (
         SELECT n.literaturzeitschrift_id,
            n.auflagen_raw,
            n.a_lc,
            n.is_thousand,
                CASE
                    WHEN n.n1_txt IS NULL THEN NULL::bigint
                    WHEN n.n2_txt IS NOT NULL THEN round((n.n1_txt::numeric + n.n2_txt::numeric) / 2.0)::bigint
                    ELSE n.n1_txt::bigint
                END AS val_num
           FROM nums n
        ), scaled AS (
         SELECT p.literaturzeitschrift_id,
            p.auflagen_raw,
                CASE
                    WHEN p.val_num IS NULL THEN NULL::bigint
                    WHEN p.is_thousand THEN p.val_num * 1000
                    ELSE p.val_num
                END AS auflage_pro_heft
           FROM parsed p
        )
 SELECT literaturzeitschrift_id,
    auflagen_raw,
    auflage_pro_heft
   FROM scaled;