-- Aufteilen der Datensätze nach Jahren 
CREATE OR REPLACE VIEW H4 AS
SELECT 
    publikationsjahr, 
    COUNT(*) AS anzahl_der_buecher
FROM 
    buch
GROUP BY 
    publikationsjahr
ORDER BY 
    publikationsjahr;

-- Test finden noch Übersetzungen enthalten? 
SELECT buchtitel FROM buch
WHERE buchtitel ILIKE '%übersetz%'
ORDER BY buchtitel;

-- Test: gibt es noch buchtitel die mehrfach vorkommen? 
SELECT buchtitel, COUNT(*) AS anzahl
FROM buch
GROUP BY buchtitel 
HAVING COUNT(*) > 1
ORDER BY buchtitel;


-- Herausfiltern von Übersetzungen und übersehener Neuauflagen 
CREATE OR REPLACE VIEW H4a AS
WITH gefilterte_bücher AS (
    SELECT * FROM buch
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
gefilterte_bücher2 AS (
    SELECT * FROM gefilterte_bücher
    WHERE uebersetzer IS NULL OR uebersetzer = ''
)
SELECT DISTINCT buchtitel FROM gefilterte_bücher2;

-- Gefilterte Werte erneut nach Jahr ausgeben lassen 
CREATE OR REPLACE VIEW H4a_year AS
SELECT 
    publikationsjahr, 
    COUNT(DISTINCT buchtitel) AS anzahluniquebuecher
FROM 
    buch
WHERE 
    buchtitel IN (SELECT buchtitel FROM H4a)
GROUP BY 
    publikationsjahr
ORDER BY 
    publikationsjahr;