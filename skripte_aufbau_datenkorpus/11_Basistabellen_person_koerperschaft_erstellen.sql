-- Container für „person“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE Person (
    person_id SERIAL PRIMARY KEY,
    person_name VARCHAR(255),
    person_name_gnd VARCHAR(255),
    person_username_ff VARCHAR(255),
    beruf_beschaeftigung_gnd TEXT,  -- TEXT verwendet für potenziell lange Listen
    geburtsdatum_gnd VARCHAR(50),   -- VARCHAR für flexibles Datumsformat
    sterbedatum_gnd VARCHAR(50),    -- VARCHAR für flexibles Datums- oder 'Unbekannt'
    alter_ff INTEGER,               -- INTEGER für Altersangaben
    geschlecht_gnd_ff VARCHAR(20),  -- Kürzer, für wenige Geschlechteroptionen
    gnd_nummer VARCHAR,         -- VARCHAR für alphanumerische GND-Nummern
    person_homepage_gnd_ff TEXT     -- TEXT für längere URLs
);


-- Container für „koerperschaft“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE Koerperschaft (
    koerperschaft_id SERIAL PRIMARY KEY,
    koerperschaft_name VARCHAR(255),
    koerperschaft_name_gnd VARCHAR(255),
    sitz_gnd VARCHAR(255),
    gruendungsdatum_gnd VARCHAR(10),
    aufloesungsdatum_gnd VARCHAR(10),
    gnd_nummer VARCHAR,
    homepage_gnd VARCHAR(255),
    gnd_sachgruppe VARCHAR(255)
);

-- CSV-Dateien importieren erfolgt manuell über pgAdmin 
-- "Pfadzu\Konsolidierte\Person-kk-pk-fin-reconsiled.csv"


/*
Diese Schritte funktionieren nur, wenn die Dateien auf dem gleichen Server liegen, wie die RDB
COPY person (
  person_id, person_name, person_name_gnd, person_username_ff,
  beruf_beschaeftigung_gnd, geburtsdatum_gnd, sterbedatum_gnd,
  alter_ff, geschlecht_gnd_ff, gnd_nummer, person_homepage_gnd_ff
)
FROM 'Pfadzu\Konsolidierte\Person-kk-pk-fin-reconsiled1.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8', NULL '');

-- "Pfadzu\Konsolidierte\Koerperschaft_kk_pk_fin_reconciled.csv"
COPY koerperschaft (
  koerperschaft_id, koerperschaft_name, koerperschaft_name_gnd,
  sitz_gnd, gruendungsdatum_gnd, aufloesungsdatum_gnd,
  gnd_nummer, homepage_gnd, gnd_sachgruppe
)
FROM 'Pfadzu\Konsolidierte\Koerperschaft_kk_pk_fin_reconciled.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8', NULL '');
*/

-- Anpassen der ID-Spalten: Formatänderung und Hinzufügen von Präfix
ALTER TABLE person
ALTER COLUMN person_id TYPE VARCHAR USING person_id::VARCHAR;

UPDATE person
SET person_id = 'P' || TRIM(person_id)
WHERE person_id !~ '^P[0-9]+$';

ALTER TABLE koerperschaft
ALTER COLUMN koerperschaft_id TYPE VARCHAR USING koerperschaft_id::VARCHAR;

UPDATE koerperschaft
SET koerperschaft_id = 'K' || TRIM(koerperschaft_id)
WHERE koerperschaft_id !~ '^K[0-9]+$';

ALTER TABLE person ALTER COLUMN person_id DROP DEFAULT;
ALTER TABLE koerperschaft ALTER COLUMN koerperschaft_id DROP DEFAULT;

-- Klappt erst, wenn alte Tabellen (person_alt etc.) gelöscht wurden. Ist nur zum "Aufräumen"
-- DROP SEQUENCE IF EXISTS public.person_person_id_seq;
-- DROP SEQUENCE IF EXISTS public.koerperschaft_koerperschaft_id_seq;

ALTER TABLE person
  ADD CONSTRAINT chk_person_id_prefix CHECK (person_id ~ '^P[0-9]+$');
ALTER TABLE koerperschaft
  ADD CONSTRAINT chk_koerperschaft_id_prefix CHECK (koerperschaft_id ~ '^K[0-9]+$');

