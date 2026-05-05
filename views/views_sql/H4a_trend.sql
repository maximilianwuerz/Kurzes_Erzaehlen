CREATE OR REPLACE VIEW "H4a_trend" AS
SELECT 
    publikationsjahr, 
    COUNT(*) AS anzahl_der_buecher
FROM 
    buch
GROUP BY 
    publikationsjahr
ORDER BY 
    publikationsjahr;
