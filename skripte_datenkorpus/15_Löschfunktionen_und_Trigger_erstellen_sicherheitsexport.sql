-- Erstellen der Tabelle für Personen
CREATE TABLE person_rolle_objekt_neu (
    objekt_id VARCHAR(255),
    objekt_typ VARCHAR(50),
    person_id VARCHAR(10) REFERENCES person_neu(person_id),
    rolle TEXT,
    PRIMARY KEY (objekt_id, objekt_typ, person_id)
);

-- Erstellen der Tabelle für Körperschaften
CREATE TABLE koerperschaft_rolle_objekt_neu (
    objekt_id VARCHAR(255),
    objekt_typ VARCHAR(50),
    koerperschaft_id VARCHAR(10) REFERENCES koerperschaft_neu(koerperschaft_id),
    rolle TEXT,
    PRIMARY KEY (objekt_id, objekt_typ, koerperschaft_id)
);


-- Zunächst person_objekt_rolle befüllen 
-- rolle in der person_objekt_rolle als Primärschlüssel einbeziehen
ALTER TABLE person_rolle_objekt
DROP CONSTRAINT person_rolle_objekt_pkey,
ADD PRIMARY KEY (objekt_id, objekt_typ, person_id, rolle);

-- Einträge aus der Tabelle Buch in die Verknüpfungstabelle person_rolle_objekt überführen
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT b.isbn AS objekt_id, 'Buch' AS objekt_typ, TRIM(id) AS person_id, rolle
FROM buch b,
UNNEST(STRING_TO_ARRAY(
    COALESCE(b.verfasser, '') || ';' ||
    COALESCE(b.buchverlegtvon, '') || ';' ||
    COALESCE(b.herausgeber, '') || ';' ||
    COALESCE(b.uebersetzer, '') || ';' ||
    COALESCE(b.keinerolle, '') || ';' ||
    COALESCE(b.sonstige, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.verfasser, ';')) THEN 'VerfasserIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.buchverlegtvon, ';')) THEN 'VerlegerIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.herausgeber, ';')) THEN 'HerausgeberIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.uebersetzer, ';')) THEN 'ÜbersetzerIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.keinerolle, ';')) THEN 'Unklare Rolle Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.sonstige, ';')) THEN 'Sonstige Rolle Buch' END
]) AS rolle
WHERE TRIM(id) LIKE 'P%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM person_rolle_objekt pro
    WHERE pro.objekt_id = b.isbn
    AND pro.objekt_typ = 'Buch'
    AND pro.person_id = TRIM(id)
    AND pro.rolle = rolle
);

-- Einträge aus der Tabelle Literaturzeitschrift in die Verknüpfungstabelle person_rolle_objekt überführen
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT lz.literaturzeitschrift_id AS objekt_id, 'Literaturzeitschrift' AS objekt_typ, TRIM(id) AS person_id, rolle
FROM literaturzeitschrift lz,
UNNEST(STRING_TO_ARRAY(
    COALESCE(lz.literaturzeitschrift_creator, '') || ';' ||
    COALESCE(lz.literaturzeitschrift_verlegtvon, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(lz.literaturzeitschrift_creator, ';')) THEN 'Creator Zeitschrift' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(lz.literaturzeitschrift_verlegtvon, ';')) THEN 'VerlegerIn Zeitschrift' END
]) AS rolle
WHERE TRIM(id) LIKE 'P%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM person_rolle_objekt pro
    WHERE pro.objekt_id = lz.literaturzeitschrift_id
    AND pro.objekt_typ = 'Literaturzeitschrift'
    AND pro.person_id = TRIM(id)
    AND pro.rolle = rolle
);

-- Literaturwettbewerb in die Verknüpfungstabelle person_rolle_objekt überführen
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT lw.literaturwettbewerb_id AS objekt_id, 'Literaturwettbewerb' AS objekt_typ, TRIM(id) AS person_id, rolle
FROM literaturwettbewerb lw,
UNNEST(STRING_TO_ARRAY(
    COALESCE(lw.veranstalter, '') || ';' ||
    COALESCE(lw.jury_2023, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(lw.veranstalter, ';')) THEN 'VeranstalterIn' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(lw.jury_2023, ';')) THEN 'Jurymitglied 2023' END
]) AS rolle
WHERE TRIM(id) LIKE 'P%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM person_rolle_objekt pro
    WHERE pro.objekt_id = lw.literaturwettbewerb_id
    AND pro.objekt_typ = 'Literaturwettbewerb'
    AND pro.person_id = TRIM(id)
    AND pro.rolle = rolle
);

-- Literaturwettbewerb_Ausgabe in die Verknüpfungstabelle person_rolle_objekt überführen
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT lwa.literaturwettbewerb_ausgabe_id AS objekt_id, 'Literaturwettbewerb Ausgabe' AS objekt_typ, TRIM(id) AS person_id, rolle
FROM literaturwettbewerb_ausgabe lwa,
UNNEST(STRING_TO_ARRAY(
    COALESCE(lwa.gewinner, '') || ';' ||
    COALESCE(lwa.jury, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(lwa.gewinner, ';')) THEN 'GewinnerIn' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(lwa.jury, ';')) THEN 'Jurymitglied' END
]) AS rolle
WHERE TRIM(id) LIKE 'P%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM person_rolle_objekt pro
    WHERE pro.objekt_id = lwa.literaturwettbewerb_ausgabe_id
    AND pro.objekt_typ = 'Literaturwettbewerb Ausgabe'
    AND pro.person_id = TRIM(id)
    AND pro.rolle = rolle
);

-- Plattform_Internet in die Verknüpfungstabelle person_rolle_objekt überführen
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
SELECT DISTINCT pl.plattform_id AS objekt_id, 'Plattform Internet' AS objekt_typ, TRIM(id) AS person_id, rolle
FROM plattform_internet pl,
UNNEST(STRING_TO_ARRAY(
    COALESCE(pl.plattform_creator, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(pl.plattform_creator, ';')) THEN 'Creator Plattform' END
]) AS rolle
WHERE TRIM(id) LIKE 'P%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM person_rolle_objekt pro
    WHERE pro.objekt_id = pl.plattform_id
    AND pro.objekt_typ = 'Plattform Internet'
    AND pro.person_id = TRIM(id)
    AND pro.rolle = rolle
);

-- Ab hier nun koerperschaft_objekt_rolle
-- rolle in der koerperschaft_objekt_rolle als Primärschlüssel einbeziehen
ALTER TABLE koerperschaft_rolle_objekt
DROP CONSTRAINT koerperschaft_rolle_objekt_pkey,
ADD PRIMARY KEY (objekt_id, objekt_typ, koerperschaft_id, rolle);

-- Einträge aus der Tabelle Buch in die Verknüpfungstabelle koerperschaft_objekt_rolle überführen
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT b.isbn AS objekt_id, 'Buch' AS objekt_typ, TRIM(id) AS koerperschaft_id, rolle
FROM buch b,
UNNEST(STRING_TO_ARRAY(
    COALESCE(b.verfasser, '') || ';' ||
    COALESCE(b.buchverlegtvon, '') || ';' ||
    COALESCE(b.herausgeber, '') || ';' ||
    COALESCE(b.uebersetzer, '') || ';' ||
    COALESCE(b.keinerolle, '') || ';' ||
    COALESCE(b.sonstige, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.verfasser, ';')) THEN 'VerfasserIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.buchverlegtvon, ';')) THEN 'VerlegerIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.herausgeber, ';')) THEN 'HerausgeberIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.uebersetzer, ';')) THEN 'ÜbersetzerIn Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.keinerolle, ';')) THEN 'Unklare Rolle Buch' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(b.sonstige, ';')) THEN 'Sonstige Rolle Buch' END
]) AS rolle
WHERE TRIM(id) LIKE 'K%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM koerperschaft_rolle_objekt pro
    WHERE pro.objekt_id = b.isbn
    AND pro.objekt_typ = 'Buch'
    AND pro.koerperschaft_id = TRIM(id)
    AND pro.rolle = rolle
);


-- Einträge aus der Tabelle Literaturzeitschrift in die Verknüpfungstabelle koerperschaft_objekt_rolle überführen
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT lz.literaturzeitschrift_id AS objekt_id, 'Literaturzeitschrift' AS objekt_typ, TRIM(id) AS koerperschaft_id, rolle
FROM literaturzeitschrift lz,
UNNEST(STRING_TO_ARRAY(
    COALESCE(lz.literaturzeitschrift_creator, '') || ';' ||
    COALESCE(lz.literaturzeitschrift_verlegtvon, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(lz.literaturzeitschrift_creator, ';')) THEN 'Creator Zeitschrift' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(lz.literaturzeitschrift_verlegtvon, ';')) THEN 'VerlegerIn Zeitschrift' END
]) AS rolle
WHERE TRIM(id) LIKE 'K%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM koerperschaft_rolle_objekt pro
    WHERE pro.objekt_id = lz.literaturzeitschrift_id
    AND pro.objekt_typ = 'Literaturzeitschrift'
    AND pro.koerperschaft_id = TRIM(id)
    AND pro.rolle = rolle
);

-- Einträge aus der Tabelle Literaturwettbewerb in die Verknüpfungstabelle koerperschaft_objekt_rolle überführen
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT lw.literaturwettbewerb_id AS objekt_id, 'Literaturwettbewerb' AS objekt_typ, TRIM(id) AS koerperschaft_id, rolle
FROM literaturwettbewerb lw,
UNNEST(STRING_TO_ARRAY(
    COALESCE(lw.veranstalter, '') || ';' ||
    COALESCE(lw.jury_2023, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(lw.veranstalter, ';')) THEN 'VeranstalterIn' END,
    CASE WHEN id = ANY(STRING_TO_ARRAY(lw.jury_2023, ';')) THEN 'Jurymitglied 2023' END
]) AS rolle
WHERE TRIM(id) LIKE 'K%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM koerperschaft_rolle_objekt pro
    WHERE pro.objekt_id = lw.literaturwettbewerb_id
    AND pro.objekt_typ = 'Literaturwettbewerb'
    AND pro.koerperschaft_id = TRIM(id)
    AND pro.rolle = rolle
);


-- Einträge aus der Tabelle Plattform_Internet in die Verknüpfungstabelle koerperschaft_objekt_rolle überführen
INSERT INTO koerperschaft_rolle_objekt (objekt_id, objekt_typ, koerperschaft_id, rolle)
SELECT DISTINCT pl.plattform_id AS objekt_id, 'Plattform Internet' AS objekt_typ, TRIM(id) AS koerperschaft_id, rolle
FROM plattform_internet pl,
UNNEST(STRING_TO_ARRAY(
    COALESCE(pl.plattform_creator, ''), ';')) AS id,
UNNEST(ARRAY[
    CASE WHEN id = ANY(STRING_TO_ARRAY(pl.plattform_creator, ';')) THEN 'Creator Plattform' END
]) AS rolle
WHERE TRIM(id) LIKE 'K%'
AND rolle IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM koerperschaft_rolle_objekt pro
    WHERE pro.objekt_id = pl.plattform_id
    AND pro.objekt_typ = 'Plattform Internet'
    AND pro.koerperschaft_id = TRIM(id)
    AND pro.rolle = rolle
);