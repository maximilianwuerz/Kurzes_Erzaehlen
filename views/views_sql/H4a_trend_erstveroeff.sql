CREATE OR REPLACE VIEW "H4a_trend_erstveroeff" AS
SELECT 
    publikationsjahr, 
    COUNT(*) AS anzahl_der_buecher
FROM 
    "H4a_erstveroeff"
GROUP BY 
    publikationsjahr
ORDER BY 
    publikationsjahr;
