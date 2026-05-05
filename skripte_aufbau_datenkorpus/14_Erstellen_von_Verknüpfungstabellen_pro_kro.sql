-- Verknüpfungstabellen anlegen
CREATE TABLE person_rolle_objekt (
  objekt_id    VARCHAR(255),
  objekt_typ   VARCHAR(50),
  person_id    VARCHAR REFERENCES person(person_id),
  rolle        TEXT,
  PRIMARY KEY (objekt_id, objekt_typ, person_id, rolle)
);

CREATE TABLE koerperschaft_rolle_objekt (
  objekt_id        VARCHAR(255),
  objekt_typ       VARCHAR(50),
  koerperschaft_id VARCHAR REFERENCES koerperschaft(koerperschaft_id),
  rolle            TEXT,
  PRIMARY KEY (objekt_id, objekt_typ, koerperschaft_id, rolle)
);

-- Indizes für typische Abfragen (empfohlen)
CREATE INDEX IF NOT EXISTS idx_pro_person ON person_rolle_objekt(person_id);
CREATE INDEX IF NOT EXISTS idx_pro_obj    ON person_rolle_objekt(objekt_id, objekt_typ);
CREATE INDEX IF NOT EXISTS idx_kro_koerp  ON koerperschaft_rolle_objekt(koerperschaft_id);
CREATE INDEX IF NOT EXISTS idx_kro_obj    ON koerperschaft_rolle_objekt(objekt_id, objekt_typ);

--------------------------------------------------------------------------------
-- PERSONEN-ROLLEN
--------------------------------------------------------------------------------

-- Buch
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT
  b.isbn,
  'Buch',
  id,
  rolle
FROM buch b
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(b.verfasser, '') || ';' ||
    coalesce(b.buchverlegtvon, '') || ';' ||
    coalesce(b.herausgeber, '') || ';' ||
    coalesce(b.uebersetzer, '') || ';' ||
    coalesce(b.keinerolle, '') || ';' ||
    coalesce(b.sonstigerolle, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.verfasser, ''), '\s*;\s*'))       THEN 'VerfasserIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.buchverlegtvon, ''), '\s*;\s*')) THEN 'VerlegerIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.herausgeber, ''), '\s*;\s*'))    THEN 'HerausgeberIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.uebersetzer, ''), '\s*;\s*'))    THEN 'ÜbersetzerIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.keinerolle, ''), '\s*;\s*'))     THEN 'Unklare Rolle Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.sonstigerolle, ''), '\s*;\s*'))  THEN 'Sonstige Rolle Buch' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'P%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM person_rolle_objekt pro
  WHERE pro.objekt_id = b.isbn AND pro.objekt_typ = 'Buch'
    AND pro.person_id = id AND pro.rolle = rolle
);

-- Literaturzeitschrift
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT
  lz.literaturzeitschrift_id,
  'Literaturzeitschrift',
  id,
  rolle
FROM literaturzeitschrift lz
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(lz.literaturzeitschrift_creator, '') || ';' ||
    coalesce(lz.literaturzeitschriftverlegtvon, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lz.literaturzeitschrift_creator, ''), '\s*;\s*'))     THEN 'Creator Zeitschrift' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lz.literaturzeitschriftverlegtvon, ''), '\s*;\s*'))  THEN 'VerlegerIn Zeitschrift' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'P%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM person_rolle_objekt pro
  WHERE pro.objekt_id = lz.literaturzeitschrift_id AND pro.objekt_typ = 'Literaturzeitschrift'
    AND pro.person_id = id AND pro.rolle = rolle
);

-- Literaturwettbewerb
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT
  lw.literaturwettbewerb_id,
  'Literaturwettbewerb',
  id,
  rolle
FROM literaturwettbewerb lw
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(lw.veranstalter, '') || ';' || coalesce(lw.jury_2023, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lw.veranstalter, ''), '\s*;\s*')) THEN 'VeranstalterIn' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lw.jury_2023, ''), '\s*;\s*'))   THEN 'Jurymitglied 2023' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'P%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM person_rolle_objekt pro
  WHERE pro.objekt_id = lw.literaturwettbewerb_id AND pro.objekt_typ = 'Literaturwettbewerb'
    AND pro.person_id = id AND pro.rolle = rolle
);

-- Literaturwettbewerb_Ausgabe
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT
  lwa.literaturwettbewerb_ausgabe_id,
  'Literaturwettbewerb Ausgabe',
  id,
  rolle
FROM literaturwettbewerb_ausgabe lwa
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(lwa.gewinner, '') || ';' || coalesce(lwa.jury, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lwa.gewinner, ''), '\s*;\s*')) THEN 'GewinnerIn' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lwa.jury, ''), '\s*;\s*'))     THEN 'Jurymitglied' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'P%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM person_rolle_objekt pro
  WHERE pro.objekt_id = lwa.literaturwettbewerb_ausgabe_id AND pro.objekt_typ = 'Literaturwettbewerb Ausgabe'
    AND pro.person_id = id AND pro.rolle = rolle
);

-- Literaturzeitschrift_Ausgabe (Spalte: verfasser_ke_beitraege)
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT
  lza.literaturzeitschrift_ausgabe_id,
  'Literaturzeitschrift Ausgabe',
  id,
  'Verfasser Zeitschriftbeitrag'
FROM literaturzeitschrift_ausgabe lza
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(coalesce(lza.verfasser_ke_beitraege,''), '\s*;\s*')
) AS t(id)
WHERE id <> '' AND id LIKE 'P%'
AND NOT EXISTS (
  SELECT 1 FROM person_rolle_objekt pro
  WHERE pro.objekt_id = lza.literaturzeitschrift_ausgabe_id
    AND pro.objekt_typ = 'Literaturzeitschrift Ausgabe'
    AND pro.person_id = id
    AND pro.rolle = 'Verfasser Zeitschriftbeitrag'
);


-- Plattform_Internet (Spalte: gruender_betreiber)
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT
  pl.plattform_id,
  'Plattform Internet',
  id,
  rolle
FROM plattform_internet pl
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(coalesce(pl.gruender_betreiber, ''), '\s*;\s*')
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(pl.gruender_betreiber, ''), '\s*;\s*')) THEN 'Creator Plattform' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'P%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM person_rolle_objekt pro
  WHERE pro.objekt_id = pl.plattform_id AND pro.objekt_typ = 'Plattform Internet'
    AND pro.person_id = id AND pro.rolle = rolle
);

--------------------------------------------------------------------------------
-- KÖRPERSCHAFTS-ROLLEN
--------------------------------------------------------------------------------

-- Buch
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT
  b.isbn,
  'Buch',
  id,
  rolle
FROM buch b
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(b.verfasser, '') || ';' ||
    coalesce(b.buchverlegtvon, '') || ';' ||
    coalesce(b.herausgeber, '') || ';' ||
    coalesce(b.uebersetzer, '') || ';' ||
    coalesce(b.keinerolle, '') || ';' ||
    coalesce(b.sonstigerolle, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.verfasser, ''), '\s*;\s*'))       THEN 'VerfasserIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.buchverlegtvon, ''), '\s*;\s*')) THEN 'VerlegerIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.herausgeber, ''), '\s*;\s*'))    THEN 'HerausgeberIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.uebersetzer, ''), '\s*;\s*'))    THEN 'ÜbersetzerIn Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.keinerolle, ''), '\s*;\s*'))     THEN 'Unklare Rolle Buch' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(b.sonstigerolle, ''), '\s*;\s*'))  THEN 'Sonstige Rolle Buch' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'K%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM koerperschaft_rolle_objekt pro
  WHERE pro.objekt_id = b.isbn AND pro.objekt_typ = 'Buch'
    AND pro.koerperschaft_id = id AND pro.rolle = rolle
);

-- Literaturzeitschrift
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT
  lz.literaturzeitschrift_id,
  'Literaturzeitschrift',
  id,
  rolle
FROM literaturzeitschrift lz
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(lz.literaturzeitschrift_creator, '') || ';' ||
    coalesce(lz.literaturzeitschriftverlegtvon, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lz.literaturzeitschrift_creator, ''), '\s*;\s*'))     THEN 'Creator Zeitschrift' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lz.literaturzeitschriftverlegtvon, ''), '\s*;\s*'))  THEN 'VerlegerIn Zeitschrift' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'K%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM koerperschaft_rolle_objekt pro
  WHERE pro.objekt_id = lz.literaturzeitschrift_id AND pro.objekt_typ = 'Literaturzeitschrift'
    AND pro.koerperschaft_id = id AND pro.rolle = rolle
);

-- Literaturwettbewerb
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT
  lw.literaturwettbewerb_id,
  'Literaturwettbewerb',
  id,
  rolle
FROM literaturwettbewerb lw
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(
    coalesce(lw.veranstalter, '') || ';' || coalesce(lw.jury_2023, ''), '\s*;\s*'
  )
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lw.veranstalter, ''), '\s*;\s*')) THEN 'VeranstalterIn' END,
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(lw.jury_2023, ''), '\s*;\s*'))   THEN 'Jurymitglied 2023' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'K%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM koerperschaft_rolle_objekt pro
  WHERE pro.objekt_id = lw.literaturwettbewerb_id AND pro.objekt_typ = 'Literaturwettbewerb'
    AND pro.koerperschaft_id = id AND pro.rolle = rolle
);

-- Plattform_Internet (Spalte: gruender_betreiber)
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT
  pl.plattform_id,
  'Plattform Internet',
  id,
  rolle
FROM plattform_internet pl
CROSS JOIN LATERAL unnest(
  regexp_split_to_array(coalesce(pl.gruender_betreiber, ''), '\s*;\s*')
) AS t(id)
CROSS JOIN LATERAL unnest(ARRAY[
  CASE WHEN id = ANY(regexp_split_to_array(coalesce(pl.gruender_betreiber, ''), '\s*;\s*')) THEN 'Creator Plattform' END
]) AS r(rolle)
WHERE id <> '' AND id LIKE 'K%' AND rolle IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM koerperschaft_rolle_objekt pro
  WHERE pro.objekt_id = pl.plattform_id AND pro.objekt_typ = 'Plattform Internet'
    AND pro.koerperschaft_id = id AND pro.rolle = rolle
);