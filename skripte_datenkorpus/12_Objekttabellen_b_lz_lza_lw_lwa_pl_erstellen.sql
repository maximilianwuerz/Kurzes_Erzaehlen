-- Container für „buch“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE buch (
    isbn VARCHAR PRIMARY KEY,
    buchtitel VARCHAR,
    auflage VARCHAR,
    publikationsort VARCHAR,
    buchverlegtvon VARCHAR,
    publikationsjahr integer,
    seitenzahl integer,
    verfasser VARCHAR,
    herausgeber VARCHAR,
    uebersetzer VARCHAR,
    keinerolle VARCHAR,
    sonstige VARCHAR,
);

-- Container für „literaturzeitschrift“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE literaturzeitschrift (
    literaturzeitschrift_ausgabe_id VARCHAR(10) PRIMARY KEY,
    issn VARCHAR(255),
    literaturzeitschrift_name VARCHAR(255),
    literaturzeitschrift_creator VARCHAR(255),
    literaturzeitschrift_verlegtvon VARCHAR(255),
    erstveroeffentlichung VARCHAR(50),
    publikationszyklus VARCHAR(255),
    auflagenhoehe VARCHAR(255),
    quelle_website VARCHAR(255),
);


-- Container für „literaturzeitschrift_ausgabe“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE literaturzeitschrift_ausgabe (
    literaturzeitschrift_ausgabe_id VARCHAR(10) PRIMARY KEY,
    ausgabevonliteraturzeitschrift VARCHAR(255),
    literaturzeitschrift_id VARCHAR(10),
    heftnummer VARCHAR(10),
    erscheinungsjahr VARCHAR(10),
    ke_beitraege VARCHAR(255),
    FOREIGN KEY (literaturzeitschrift_id) REFERENCES literaturzeitschrift(literaturzeitschrift_id)
);


-- Container für „literaturwettbewerb“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE literaturwettbewerb (
    literaturwettbewerb_id VARCHAR(10) PRIMARY KEY,
    literaturwettbewerb_name VARCHAR(255),
    veranstalter VARCHAR(255),
    veranstaltungsort VARCHAR(255),
    laengenvorgabe_text VARCHAR(255),
    themenvorgabe VARCHAR(20),
    altersbeschraenkung VARCHAR(255),
    jury_2023 VARCHAR(255),
    ausrichtungszyklus VARCHAR(255),
    preisart VARCHAR(255),
    hoehe_preisgeld VARCHAR(255),
    publikation VARCHAR(20),
    live_event VARCHAR(20),
    erstausrichtung VARCHAR(10),
    website VARCHAR(255),
);


-- Container für „literaturwettbewerb_ausgabe“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE literaturwettbewerb_ausgabe (
    literaturwettbewerb_ausgabe_id VARCHAR(10) PRIMARY KEY,
    literaturwettbewerb_ausgabe_titel VARCHAR(255),
    vonliteraturwettbewerb VARCHAR(255),
    literaturwettbewerb_id VARCHAR(10),
    jahr integer,
    gewinner VARCHAR(255),
    gewinnertexte VARCHAR(255),
    jury VARCHAR(255),
    themenvorgabe VARCHAR(255),
    preise VARCHAR(255),
    quelle_website VARCHAR(255),
    FOREIGN KEY (literaturwettbewerb_id) REFERENCES literaturwettbewerb(literaturwettbewerb_id)
);

-- Container für „plattform_internet“ im Query-Tool des pgAdmin erstellen: 
CREATE TABLE plattform_internet (
    plattform_id VARCHAR(10) PRIMARY KEY,
    plattform_name VARCHAR(255),
	plattform_art VARCHAR(255),
	plattform_creator VARCHAR(255),
	gruendungsjahr integer,
	aufloesungsjahr integer, 
	anzahl_mitglieder VARCHAR(255),
	anzahl_texte_gesamt VARCHAR(255),
	anzahl_ke VARCHAR(255),
	selbstbeschreibung VARCHAR,
	quelle_website VARCHAR
);

-- CSV-Dateien importieren aus C:\PfadzumVerzeichnis\uploads
