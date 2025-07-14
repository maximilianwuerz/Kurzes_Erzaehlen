-- SQL-Abfrage um die Kandidaten der Tabelle Bücher für das Textkorpus zu identifizieren
CREATE TABLE ausgewählte_bücher3 AS
-- Übersetzungen rausfiltern nach Titelangaben in der Spalte buchtitel
WITH gefilterte_bücher AS (
    SELECT * FROM buch2
    WHERE buchtitel NOT ILIKE '%Übersetz%'
    AND buchtitel NOT ILIKE '%übersetz%'
    AND buchtitel NOT ILIKE '%aus dem Engl%'
    AND buchtitel NOT ILIKE '%aus dem Amer%'
    AND buchtitel NOT ILIKE '%aus dem Russ%'
    AND buchtitel NOT ILIKE '%aus dem Span%'
    AND buchtitel NOT ILIKE '%aus dem Franz%'
    AND buchtitel NOT ILIKE '%aus dem Ital%'
    AND buchtitel NOT ILIKE '%aus dem Jap%'
    AND buchtitel NOT ILIKE '%aus dem Chin%'
),
-- Datensätze filtern, die Einträge in der Spalte uebersetzer haben 
gefilterte_bücher2 AS (
    SELECT * FROM gefilterte_bücher
    WHERE (uebersetzer IS NULL OR uebersetzer = '')
),
-- Thematisch festgelegte Bücher und Genreliteratur entfernen nach Titelangaben in der Spalte buchtitel 
gefilterte_bücher3 AS (
    SELECT * FROM gefilterte_bücher2
    WHERE buchtitel NOT ILIKE '%Weihnacht%'
    AND buchtitel NOT ILIKE '%Erotisch%'
    AND buchtitel NOT ILIKE '%BDSM%'
    AND buchtitel NOT ILIKE '%Sex%'
    AND buchtitel NOT ILIKE '%prickelnd%'
    AND buchtitel NOT ILIKE '%Krimi%'
    AND buchtitel NOT ILIKE '%Thriller%'
    AND buchtitel NOT ILIKE '%Horror%'
    AND buchtitel NOT ILIKE '%Liebesgeschicht%'
    AND buchtitel NOT ILIKE '%Romance%'
    AND buchtitel NOT ILIKE '%Fantasy%'
    AND buchtitel NOT ILIKE '%phantastisch%'
    AND buchtitel NOT ILIKE '%fantastisch%'
    AND buchtitel NOT ILIKE '%Geschichten von der Liebe%'
    AND buchtitel NOT ILIKE '%Tierisch%'
)
-- Bücher von zum Publikationszeitpunkt bereits verstorbenen Verfasserinnen und Herausgeberinnen filtern
SELECT DISTINCT b.*
FROM gefilterte_bücher3 b
LEFT JOIN person p_verfasser ON p_verfasser.person_id = ANY(string_to_array(b.verfasser, ';'))
LEFT JOIN person p_herausgeber ON p_herausgeber.person_id = ANY(string_to_array(b.herausgeber, ';'))
WHERE (p_verfasser.sterbedatum_gnd IS NULL OR 
       (CAST(SUBSTRING(p_verfasser.sterbedatum_gnd FROM 1 FOR 4) AS INTEGER) > b.publikationsjahr))
  AND (p_herausgeber.sterbedatum_gnd IS NULL OR 
       (CAST(SUBSTRING(p_herausgeber.sterbedatum_gnd FROM 1 FOR 4) AS INTEGER) > b.publikationsjahr));

-- Optional: Ergebnisse anzeigen
SELECT * FROM ausgewählte_bücher3;