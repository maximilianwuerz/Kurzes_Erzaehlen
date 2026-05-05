--CREATE OR REPLACE VIEW "H8c_manifestationen" AS
WITH base AS (
  SELECT
    b.isbn,
    b.buchtitel,
    b.publikationsjahr,
    btrim(lower(regexp_replace(regexp_replace(b.buchtitel, '[[:punct:]]+', ' ', 'g'), '\s+', ' ', 'g'))) AS title_norm
  FROM buch b
)
SELECT
  title_norm,
  MIN(buchtitel) AS exemplar_titel,
  COUNT(DISTINCT isbn) AS n_manifestationen,
  COUNT(*) AS n_zeilen,
  MIN(publikationsjahr) AS min_jahr,
  MAX(publikationsjahr) AS max_jahr
FROM base
GROUP BY title_norm;
 
 select sum(n_zeilen) from "H8c_manifestationen";