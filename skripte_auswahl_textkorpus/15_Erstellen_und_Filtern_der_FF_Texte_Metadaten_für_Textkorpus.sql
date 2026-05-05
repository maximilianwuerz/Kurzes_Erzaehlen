-- Erstellen und Befüllen der "FF_Texte_Metadaten" Tabelle sowie Identifikation relevanter Einträge für Textkorpus

CREATE TABLE ff_texte_metadaten (
    meta_id SERIAL PRIMARY KEY,
    author_username VARCHAR,
    author_url VARCHAR,
    text_id VARCHAR,
    url VARCHAR,
    text_title VARCHAR,
    medium_orig VARCHAR,
    fandom_categories VARCHAR,
    chapter_amount INTEGER,
    creation_date DATE,
    update_date DATE,
    wordcount VARCHAR, 
    genre VARCHAR,
    age_restriction VARCHAR,
    endorsement_amount INTEGER,
    review_amount INTEGER
);

-- "Hilfsskript_Umwandlung_Datumsformat_Wordcount_FF_Texte_Metadaten.py" ausführen, um Formate in "FF_Text_Metadaten.csv" 
-- passend umzuwandeln 
-- FF_Text_Metadaten.csv importieren über pgAdmin
-- Nachfolgende Abfrage ausführen, um nur Texte mit mindestens 20 und höchsten 10.000 Wörtern sowie mind. einem
-- Endorsement und einem Kommentar. Zusätzlich beschränken auf maximal 500 Ergebnisse und Auswahl jener 
-- mit den höchsten Werten bei endorsement_amount 

SELECT *
FROM ff_texte_metadaten
WHERE CAST(wordcount AS INTEGER) > 20
  AND CAST(wordcount AS INTEGER) < 10000
  AND endorsement_amount > 0
  AND review_amount > 0
  ORDER BY endorsement_amount DESC
  LIMIT 500;

-- Export der Ergebnisse als "FF_Texte_Metadaten_Export_500.csv"
-- Manuelles Einpflegen der Datensätze in die Textkorpus-Importdatei "Textkorpus_gesamt.csv"