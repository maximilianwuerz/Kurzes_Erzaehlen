-- Preprocessing H6

-- Identifikation möglicher literaturferner Körperschaften und Speicherung in der neuen Hilfstabelle koerperschaft_literaturfern_manuell
-- Die Erstellung einer View ist in diesem Fall nicht direkt möglich, da die Daten darin nicht bearbeitet werden können
CREATE TABLE koerperschaft_literaturfern_manuell AS
SELECT 
    koerperschaft_id, 
    koerperschaft_name, 
    gnd_nummer, 
    koerperschaft_typ,
    NULL AS literaturfern -- initial NULL 
FROM 
    h5
WHERE 
    (koerperschaft_typ NOT LIKE 'Verlag' 
     AND koerperschaft_typ NOT LIKE 'Druckerei')
    OR koerperschaft_typ IS NULL;

-- Die so erhaltenen Datensätze manuell prüfen: liegt der primäre Tätigkeitsbereich der jeweiligen Körperschaften 
-- im literarischen Feld? 
-- Die Ergebnisse der Prüfungen sind als true oder false (boolean) in die Spalte literaturfern (initial: NULL) einzutragen. 
-- Ergibt sich aus der Prüfung keine eindeutige Zuordnung, verbleibt der Wert in der Spalte literaturfern NULL

-- Wenn die Befüllung per Point-and-Click im pgAdmin erfolgen soll, ist ein Primary Key notwendig 
ALTER TABLE koerperschaft_literaturfern_manuell
ADD PRIMARY KEY (koerperschaft_id); 

-- Wenn die Befüllung der Spalte literaturfern per Code statt per Point-and-Click im pgAdmin erfolgen soll
UPDATE koerperschaft_literaturfern_manuell
SET literaturfern = 'true'
WHERE koerperschaft_id IN ('K1', 'K2', 'usw');  -- Entsprechende koerperschaft_ids eintragen!  

UPDATE koerperschaft_literaturfern_manuell
SET literaturfern = 'false'
WHERE koerperschaft_id IN ('K3', 'K4', 'usw');  -- Entsprechende koerperschaft_ids eintragen!  


-- Abfrage der Ergebnisse zur Thesenprüfung
-- Danach Abfrage auf koerperschaft_literaturfern_manuell möglich, um zu erfahren, welche und wie viele Körperschaften literaturfern sind 
CREATE OR REPLACE VIEW H6 AS
SELECT 
    ROW_NUMBER() OVER () AS zeilenid,
    koerperschaft_id,
    koerperschaft_name,
    gnd_nummer,
    koerperschaft_typ,
    literaturfern
FROM 
    koerperschaft_literaturfern_manuell 
WHERE 
    literaturfern = 'true';
	
-- Abfrage, um herauszufinden, wie aktiv die literaturfernen Körperschaften in den einzelnen Segmenten sind 
CREATE OR REPLACE VIEW H6_segmente AS
SELECT 
    kro.objekt_typ AS publikationssegment,
    COUNT(kro.koerperschaft_id) AS totalkoerperschaften, -- Gesamtanzahl an Körperschaften für jedes Publikationssegment
    SUM(CASE WHEN nk.literaturfern = 'true' THEN 1 ELSE 0 END) AS literaturfern_koerperschaften, -- Zahl der literaturfernen Körperschaften
    (SUM(CASE WHEN nk.literaturfern = 'true' THEN 1 ELSE 0 END) * 1.0 / COUNT(kro.koerperschaft_id)) * 100 AS anteilliteraturfern -- Anteil der literaturfernen Körperschaften
FROM 
    koerperschaft_rolle_objekt kro
LEFT JOIN 
    koerperschaft_literaturfern_manuell nk ON kro.koerperschaft_id = nk.koerperschaft_id
GROUP BY 
    kro.objekt_typ
ORDER BY 
    kro.objekt_typ;
