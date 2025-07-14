-- Container in der Datenbank erstellen
CREATE TABLE textkorpus (
       text_id VARCHAR(255) PRIMARY KEY,
       text_titel VARCHAR(255),
       verfasser_id VARCHAR(255),
       publikationsjahr INTEGER,
       publikationssegment VARCHAR(50),
       publikationsobjekt_id VARCHAR(255),
       objekt_titel VARCHAR(255),
       anzahl_woerter INTEGER,
       anzahl_likes INTEGER,
       topics TEXT,
       genres TEXT
   );

-- csv-Datei über pgAdmin importieren 

-- Personennamen in verfasser_id zu Personen_IDs ändern 
UPDATE textkorpus
SET verfasser_id = p.person_id
FROM person p
WHERE textkorpus.verfasser_id = p.person_name OR textkorpus.verfasser_id = p.person_username_ff;

-- Prüfen, ob es noch Namen gibt, die nicht konvertiert wurden 
SELECT * FROM textkorpus WHERE verfasser_id NOT LIKE 'P%'

-- In Person fehlende Namen in die Tabellen person und person_rolle_objekt aufnehmen 
-- letzte ID herausfinden 
SELECT person_id 
FROM person 
ORDER BY person_id DESC 
LIMIT 1; 

INSERT INTO person (personid, personname)
VALUES 
('P26121', 'Scheffel, Anna'),
('P26122', 'Rigg, Donata'),
('P26123', 'Zange, Julia'),
('P26124', 'Roßbacher, Verena'); 

-- Inhalte manuell zusammentragen 
INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
VALUES 
('9783518462997', 'Buch', 'P26121', 'VerfasserIn Buch'),
('9783518462997', 'Buch', 'P26122', 'VerfasserIn Buch'),
('9783518462997', 'Buch', 'P26123', 'VerfasserIn Buch'),
('9783518462997', 'Buch', 'P26124', 'VerfasserIn Buch');

-- publikationsobjekt_id mit fehlenden Objekt_IDs befüllen
-- aus Literaturzeitschrift_Ausgabe
UPDATE textkorpus
SET publikationsobjekt_id = lza.literaturzeitschrift_ausgabe_id
FROM literaturzeitschrift_ausgabe lza
WHERE textkorpus.publikationssegment = 'Literaturzeitschrift'
AND TRIM(textkorpus.text_titel) = ANY(
    SELECT TRIM(value)
    FROM UNNEST(STRING_TO_ARRAY(lza.ke_beitraege, ';')) AS value
)
AND textkorpus.publikationsobjekt_id IS NULL;

-- aus Literaturwettbewerb_Ausgabe
UPDATE textkorpus
   SET publikationsobjekt_id = lwa.literaturwettbewerb_ausgabe_id
   FROM literaturwettbewerb_ausgabe lwa
   WHERE publikationssegment = 'Literaturwettbewerb'
	AND TRIM(textkorpus.text_titel) = ANY(
    SELECT TRIM(value)
    FROM UNNEST(STRING_TO_ARRAY(lwa.gewinnertexte, ';')) AS value
)
AND textkorpus.publikationsobjekt_id IS NULL;

-- aus Plattform_Internet (überall 'I1' da nur Texte von Fanfiktion.de)
UPDATE textkorpus
SET publikationsobjekt_id = 'I1'
WHERE publikationssegment = 'Plattform_Internet'
AND publikationsobjekt_id IS NULL;

-- Finale Überprüfung, ob noch Einträge mit leerer publikationsobjekt_id
SELECT * FROM textkorpus WHERE publikationsobjekt_id IS NULL;

