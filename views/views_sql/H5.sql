-- Erstellung der View "H5" mit der Spalte koerperschaft_typ 
-- Hiermit wird auswertbar, welche Körperschaften Verlage sind 
-- Die so erstellte View wird auch für die Prüfung von T6 herangezogen
-- 13.07.2025 Überlegung: Körperschaften ohne gnd_nummer ausschließen, da es hierfür keine Normdaten gibt und die Qualität nicht gesichert ist. 

CREATE OR REPLACE VIEW H5 AS
SELECT *,
    CASE
WHEN koerperschaft_name_gnd ILIKE '%Verl.%' OR koerperschaft_name_gnd ILIKE '%Verlag%' 
													OR koerperschaft_name_gnd ILIKE '%Ed.%'
													OR koerperschaft_name_gnd ILIKE '%Edition%' THEN 'Verlag'
        WHEN koerperschaft_name_gnd ILIKE '%Verein%' OR koerperschaft_name_gnd ILIKE '%e.V.%' THEN 'Verein'
		WHEN koerperschaft_name_gnd ILIKE '%Akademie%' THEN 'Akademie'
		WHEN koerperschaft_name_gnd ILIKE '%Institut%' THEN 'Institut'
		WHEN koerperschaft_name_gnd ILIKE '%Druck%' THEN 'Druckerei'
		WHEN koerperschaft_name_gnd ILIKE '%Buchhandl%' THEN 'Buchhandlung'
		WHEN koerperschaft_name_gnd ILIKE '%Verband%' OR koerperschaft_name_gnd ILIKE '%Verb.%' THEN 'Verband'
		WHEN koerperschaft_name_gnd ILIKE '%Forum%' OR koerperschaft_name_gnd ILIKE '%Gemeinschaft%' 
													OR koerperschaft_name_gnd ILIKE '%Gruppe%'
													OR koerperschaft_name_gnd ILIKE '%Kollektiv%'
													OR koerperschaft_name_gnd ILIKE '%Kreis%' 
													OR koerperschaft_name_gnd ILIKE '%Club%' 
													OR koerperschaft_name_gnd ILIKE '%Gesellschaft%' 
													OR koerperschaft_name_gnd ILIKE '%Netzwerk%'THEN 'Gemeinschaft'
		WHEN koerperschaft_name_gnd ILIKE '%mbh%' 	OR koerperschaft_name_gnd ILIKE '%m.b.h.%'
													OR koerperschaft_name_gnd ILIKE '%GbR%'
													OR koerperschaft_name_gnd ILIKE '%oHG%'
													/*OR koerperschaft_name_gnd ILIKE '%KG%'
													OR koerperschaft_name_gnd ILIKE '%AG%'*/
													OR koerperschaft_name_gnd ILIKE '%e.k.%'
												  	OR koerperschaft_name_gnd ILIKE '%Firma%' THEN 'Unternehmen'
        ELSE NULL
    END AS koerperschaft_typ
FROM koerperschaft;

-- Dann überprüfen, welche Einträge keinem Typ zugeordnet wurden, aber in der GND verzeichnet sind
SELECT koerperschaft_name, koerperschaft_name_gnd, koerperschaft_typ FROM public.h5
WHERE koerperschaft_typ IS NULL
AND gnd_nummer IS NOT NULL

-- Diese müssen, wenn möglich noch manuell einem Typ zugeordnet werden
-- (bis "Frauenmuseum Bonn" umgesetzt, nach Abgabe Manuskript fortzuführen)

-- Mit dem nachfolgenden Code wird eine Hilfstabelle erstellt
-- und die manuellen identifizierten Zuordnungen darin eingetragen
CREATE TABLE koerperschaft_typ_manuell (
    koerperschaft_name VARCHAR,
    koerperschaft_typ TEXT
);

-- Einfügen der Verlage
INSERT INTO koerperschaft_typ_manuell (koerperschaft_name, koerperschaft_typ) VALUES
('Unartproduktion (Dornbirn)', 'Verlag'),
('Walter de Gruyter & Co.', 'Verlag'),
('Adolf Dahlfeld Erben', 'Verlag'),
('Allegria', 'Verlag'),
('Altan', 'Verlag'),
('ambiente-krimis', 'Verlag'),
('Amicus', 'Verlag'),
('Bastei Lübbe AG', 'Verlag'),
('Benevento Publishing', 'Verlag'),
('Berchtesgadener Anzeiger KG', 'Verlag'),
('Berlin Univ. Press', 'Verlag'),
('blaetterhaus', 'Verlag'),
('Bloomsbury Taschenbuch', 'Verlag'),
('Bremer Tageszeitungen AG', 'Verlag'),
('Brunner Medien AG', 'Verlag'),
('Bücken & Sulzer', 'Verlag'),
('Cl. Attenkofer (Straubing)', 'Verlag'),
('J. P. Bachem (Köln)', 'Verlag'),
('Diaphanes', 'Verlag'),
('Dietschi AG', 'Verlag'),
('Diogenes Theater', 'Verlag'),
('Distillery', 'Verlag'),
('Dover Publications', 'Verlag'),
('Droste', 'Verlag'),
('Duncker & Humblot', 'Verlag'),
('Éditions Trèves', 'Verlag'),
('Garamond', 'Verlag'),
('Ehe Familie Buch Maria Büchsenmeister', 'Verlag'),
('Elysion-Books', 'Verlag'),
('Esras.net', 'Verlag'),
('Faber & Faber', 'Verlag'),
('FISCHER Krüger', 'Verlag'),
('Fontana edizioni', 'Verlag'),
('Fontis AG', 'Verlag'),
('Frankfurter Allgemeine Buch', 'Verlag');

-- Einfügen der Gemeinschaften
INSERT INTO koerperschaft_typ_manuell (koerperschaft_name, koerperschaft_typ) VALUES
('Angele-Sippe', 'Gemeinschaft'),
('Brückenschreiber Koblenz', 'Gemeinschaft'),
('BördeAutoren', 'Gemeinschaft'),
('Dichterstammtisch (Siegen)', 'Gemeinschaft'),
('Die Küstenautoren', 'Gemeinschaft'),
('Die Chromatischen Phantasten', 'Gemeinschaft'),
('Die Rosenheimer Autoren', 'Gemeinschaft'),
('Dresdner Literaturner', 'Gemeinschaft');

-- Einfügen der Vereine
INSERT INTO koerperschaft_typ_manuell (koerperschaft_name, koerperschaft_typ) VALUES
('Saarländisches Künstlerhaus Saarbrücken. Galerie', 'Verein'),
('Equicane - Gemeinsam mit den Partnern Pferd und Hund', 'Verein'),
('Frauenmuseum Bonn', 'Verein');

-- Einfügen der (Hoch-)Schulen, Universitäten, Bildungseinrichtungen
INSERT INTO koerperschaft_typ_manuell (koerperschaft_name, koerperschaft_typ) VALUES
('Duale Hochschule Baden-Württemberg Mannheim', 'Bildungseinrichtung'),
('Ernst-Moritz-Arndt-Gymnasium Bergen', 'Bildungseinrichtung');

-- Einfügen der Stiftungen
INSERT INTO koerperschaft_typ_manuell (koerperschaft_name, koerperschaft_typ) VALUES
('Bürgerstiftung Düren', 'Stiftung'),
('Crespo Foundation', 'Stiftung'),
('Donauschwäbische Kulturstiftung', 'Stiftung');

-- Einfügen der Kirchlichen Einrichtungen
INSERT INTO koerperschaft_typ_manuell (koerperschaft_name, koerperschaft_typ) VALUES
('Dominikanerkloster Prenzlau - Kulturzentrum und Museum', 'Kirchliche Einrichtung'),
('Evangelisches Johannesstift Behindertenhilfe', 'Kirchliche Einrichtung');

-- Abfragen zur Überprüfung (sind es nun weniger Zeilen?)
SELECT koerperschaft_name, koerperschaft_name_gnd, koerperschaft_typ FROM public.h5
WHERE koerperschaft_typ IS NULL
AND gnd_nummer IS NOT NULL

-- Nun die komplette Abfrage zur Erstellung von H5 unter Einbezug der Hilfsstabelle koerperschaft_typ_manuell
-- ausführen und so die Einträge in der Spalte koerperschaft_typ der View H5 vervollständigen
CREATE OR REPLACE VIEW H5 AS
SELECT 
    ko.*, 
    COALESCE(
        mz.koerperschaft_typ,
        CASE
            WHEN ko.koerperschaft_name_gnd ILIKE '%Verl.%' OR ko.koerperschaft_name_gnd ILIKE '%Verlag%' OR ko.koerperschaft_name_gnd ILIKE '%Ed.%' OR ko.koerperschaft_name_gnd ILIKE '%Edition%' THEN 'Verlag'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Verein%' OR ko.koerperschaft_name_gnd ILIKE '%e.V.%' THEN 'Verein'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Akademie%' THEN 'Akademie'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Institut%' THEN 'Institut'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Druck%' THEN 'Druckerei'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Buchhandl%' THEN 'Buchhandlung'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Verband%' OR ko.koerperschaft_name_gnd ILIKE '%Verb.%' THEN 'Verband'
            WHEN ko.koerperschaft_name_gnd ILIKE '%Forum%' OR ko.koerperschaft_name_gnd ILIKE '%Gemeinschaft%' OR ko.koerperschaft_name_gnd ILIKE '%Gruppe%' OR ko.koerperschaft_name_gnd ILIKE '%Kollektiv%' OR ko.koerperschaft_name_gnd ILIKE '%Kreis%' OR ko.koerperschaft_name_gnd ILIKE '%Club%' OR ko.koerperschaft_name_gnd ILIKE '%Gesellschaft%' OR ko.koerperschaft_name_gnd ILIKE '%Netzwerk%' THEN 'Gemeinschaft'
            WHEN ko.koerperschaft_name_gnd ILIKE '%mbh%' OR ko.koerperschaft_name_gnd ILIKE '%m.b.h.%' OR ko.koerperschaft_name_gnd ILIKE '%GbR%' OR ko.koerperschaft_name_gnd ILIKE '%oHG%' OR ko.koerperschaft_name_gnd ILIKE '%e.k.%' OR ko.koerperschaft_name_gnd ILIKE '%Firma%' THEN 'Unternehmen'
            ELSE NULL
        END
    ) AS koerperschaft_typ
FROM 
    koerperschaft ko
LEFT JOIN 
    koerperschaft_typ_manuell mz ON ko.koerperschaft_name_gnd = mz.koerperschaft_name;