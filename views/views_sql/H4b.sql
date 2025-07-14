CREATE OR REPLACE VIEW H4b AS
SELECT 
    objekt_titel, 
    COUNT(text_id) AS textmenge
FROM 
    textkorpus
WHERE 
    publikationssegment = 'Buch'
GROUP BY 
    objekt_titel
ORDER BY 
    objekt_titel;