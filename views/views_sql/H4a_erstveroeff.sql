create or replace view "H4a_erstveroeff" as
with base as (
  select
    buchtitel,
    auflage,
    publikationsjahr,
    -- Titel normalisieren (Kleinbuchstaben, Satzzeichen/Mehrfach-Whitespace glätten, trimmen)
    btrim(lower(regexp_replace(regexp_replace(buchtitel, '[[:punct:]]+', ' ', 'g'), '\s+', ' ', 'g'))) as title_norm,
    nullif(trim(lower(auflage)), '') as auflage_lc
  from buch
  where publikationsjahr between 2008 and 2023
),
parsed as (
  select
    *,
    coalesce(auflage_lc, '') as al,
    -- Auflagenzahl extrahieren ("2. Auflage" oder "Auflage 2")
    coalesce(
      nullif(substring(auflage_lc from '\b(\d{1,3})\s*(?:\.\s*)?(?:auf(?:l|lage)?|ausgabe)\b'), '')::int,
      nullif(substring(auflage_lc from '(?:auf(?:l|lage)?|ausgabe)\D{0,15}(\d{1,3})\b'), '')::int
    ) as auflage_num,
    -- Eindeutig ≥ 2. Auflage erwähnt?
    (
      coalesce(auflage_lc,'') ~ '\b([2-9]|\d{2,})\s*(?:\.\s*)?(?:auf(?:l|lage)?|ausgabe)\b'
      or coalesce(auflage_lc,'') ~ '(?:auf(?:l|lage)?|ausgabe)\D{0,15}([2-9]|\d{2,})\b'
    ) as is_edition_ge2
  from base
),
flags as (
  select
    buchtitel,
    auflage,
    publikationsjahr,
    title_norm,
    al,
    auflage_num,
    is_edition_ge2,
    -- explizit erst?
    case
      when auflage_num = 1 then true
      when al like '%erstausgabe%' then true
      when al like '%originalausgabe%' then true
      when al ~ '(^|[^[:alnum:]])ea([^[:alnum:]]|$)' then true
      when al like '%1. aufl%' or al like '%1. auflage%' then true
      when al like '%erste aufl%' or al like '%erste auflage%' then true
      else false
    end as is_erst,
    -- spätere/neu gesetzte Ausgabe?
    case
      when auflage_num >= 2 or is_edition_ge2 then true
      when al like '%neuauflage%' or al like '%neuaufl.%' then true
      when al like '%nachdruck%' or al like '%reprint%' then true
      when al like '%sonderausgabe%' or al like '%lizenzausgabe%' then true
      when al like '%überarb%' or al like '%überarbeit%' or al like '%aktualisiert%' or al like '%durchges%' then true
      -- Zahl-Prefixe (inkl. 2.)
      when al like '%2.%'
        or al like '%3.%'
        or al like '%4.%'
        or al like '%5.%'
        or al like '%6.%'
        or al like '%7.%'
        or al like '%8.%'
        or al like '%9.%'
        or al like '%10.%'
        or al like '%11.%'
        or al like '%21.%'
        or al like '%31.%'
      then true
      -- Kontextgebundene Kürzel in Nähe von Aufl./Ausg.
      when al ~ '(erw\w|kor\w|gek\w|gen\w|gro\w|jub\w|lim\w|sond\w|deut\w|neu\w)\D{0,12}(auf|ausg)'
        or al ~ '(?:auf|ausg)\D{0,12}(erw\w|kor\w|gek\w|gen\w|gro\w|jub\w|lim\w|sond\w|deut\w|neu\w)'
      then true
      else false
    end as is_spaeter,
    min(publikationsjahr) over (partition by title_norm) as min_year_for_title,
    bool_or(
      case
        when auflage_num = 1
          or al like '%erstausgabe%'
          or al like '%originalausgabe%'
          or al ~ '(^|[^[:alnum:]])ea([^[:alnum:]]|$)'
          or al like '%1. aufl%'
          or al like '%1. auflage%'
          or al like '%erste aufl%'
          or al like '%erste auflage%'
        then true else false
      end
    ) over (partition by title_norm) as any_row_claims_first
  from parsed
),
candidates as (
  -- Nimm alle expliziten Erstausgaben; falls es die nicht gibt,
  -- nimm die früheste Manifestation im Zeitraum, sofern nicht klar spätere Auflage.
  select
    buchtitel,
    auflage,
    publikationsjahr,
    title_norm,
    case when is_erst then 0 else 1 end as rank_is_erst
  from flags
  where is_erst
     or (
       not any_row_claims_first
       and not is_spaeter
       and publikationsjahr = min_year_for_title
     )
)
-- Pro normalisiertem Titel genau eine (beste) Zeile zurückgeben
select distinct on (title_norm)
  buchtitel, auflage, publikationsjahr
from candidates
order by title_norm, rank_is_erst, publikationsjahr asc, buchtitel asc;