CREATE OR REPLACE VIEW "H6_literaturfern_kandidaten" AS
SELECT
  koerperschaft_id,
  koerperschaft_name,
  koerperschaft_name_gnd,
  gnd_sachgruppe,
  name_flag
FROM "H5_verlag_flags"
WHERE COALESCE(name_flag, '') NOT IN ('Verlag','Druckerei','Buchhandlung')
  AND NOT (
    LOWER(COALESCE(gnd_sachgruppe,'')) LIKE '%buchhandel%'
    OR LOWER(COALESCE(gnd_sachgruppe,'')) LIKE '%buchwissenschaft%'
    OR lower(COALESCE(gnd_sachgruppe,'')) LIKE '%litera%'
  );