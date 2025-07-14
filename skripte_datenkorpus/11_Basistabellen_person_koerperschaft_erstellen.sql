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
    gnd_nummer VARCHAR(20),         -- VARCHAR für alphanumerische GND-Nummern
    person_homepage_gnd_ff TEXT     -- TEXT für längere URLs
);


-- Container für „koerperschaft“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE Koerperschaft (
    koerperschaft_id SERIAL PRIMARY KEY,
    koerperschaft_name VARCHAR(255),
    koerperschaft_name_gnd VARCHAR(255),
    Sitz VARCHAR(255),
    Gruendungsdatum VARCHAR(10),
    Aufloesungsdatum VARCHAR(10),
    gnd_nummer VARCHAR(50),
    homepage VARCHAR(255)
);

-- CSV-Dateien importieren
-- "C:\PfadzurDatei\Person-kk-pk-fin-test2-rec-bis-Jensen-up_komp.csv"
-- "C:\PfadzurDatei\Koerperschaft-kk-pk-fin-rec.csv"

-- Anpassen der ID-Spalten: Formatänderung und Hinzufügen von Präfix
ALTER TABLE person
ALTER COLUMN person_id TYPE VARCHAR;

UPDATE person
SET person_id = 'P' || person_id;


ALTER TABLE koerperschaft
ALTER COLUMN koerperschaft_id TYPE VARCHAR;

UPDATE koerperschaft
SET koerperschaft_id = 'K' || koerperschaft_id;