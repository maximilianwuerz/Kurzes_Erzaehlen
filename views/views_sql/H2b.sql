-- Abfrage über textkorpus und Abgleich mit literaturwettbewerb_ausgabe (korrekte Ergebnisse = 420)
SELECT 
    lwa.vonliteraturwettbewerb, 
    COUNT(DISTINCT tk.text_id) AS anzahl_prämierter_texte
FROM 
    textkorpus tk
JOIN 
    literaturwettbewerb_ausgabe lwa ON tk.publikationsobjekt_id = lwa.literaturwettbewerb_ausgabe_id
WHERE 
    tk.publikationssegment = 'Literaturwettbewerb'
    AND lwa.vonliteraturwettbewerb ILIKE ANY(ARRAY[
        '%Open Mike%', 
        '%Schreibwettbewerb des Literaturhaus Zürich%', 
        '%Ingeborg-Bachmann-Preis%', 
        '%Moerser-Literaturpreis%', 
        '%Deutscher Kurzgeschichtenwettbewerb%'
    ])
GROUP BY 
    lwa.vonliteraturwettbewerb
ORDER BY anzahl_prämierter_texte;

-- Abfrage über literaturwettbewerb_ausgabe (hier erhält man etwas zu viele Ergebnisse)
SELECT 
    lwa.vonliteraturwettbewerb, 
    COUNT(DISTINCT beitraege.value) AS anzahl_praemierter_texte
FROM 
    literaturwettbewerb_ausgabe lwa
LEFT JOIN 
    LATERAL UNNEST(STRING_TO_ARRAY(lwa.gewinnertexte, ';')) AS beitraege(value) ON TRUE
WHERE 
    lwa.vonliteraturwettbewerb ILIKE ANY(ARRAY[
        '%Open Mike%', 
        '%Schreibwettbewerb des Literaturhaus Zürich%', 
        '%Ingeborg-Bachmann-Preis%', 
        '%Moerser-Literaturpreis%', 
        '%Deutscher Kurzgeschichtenwettbewerb%'
    ])
GROUP BY 
    lwa.vonliteraturwettbewerb;

-- Alphabetisch sortierte und nach Wettbewerben gruppierte Liste aller KE aus Literaturwettbewerben  
SELECT DISTINCT
    lwa.vonliteraturwettbewerb, 
    TRIM(beitraege.value) AS text_titel
FROM 
    literaturwettbewerb_ausgabe lwa
LEFT JOIN 
    LATERAL UNNEST(STRING_TO_ARRAY(lwa.gewinnertexte, ';')) AS beitraege(value) ON TRUE
ORDER BY 
    text_titel;




SELECT * FROM textkorpus WHERE publikationssegment LIKE 'Literaturwettbewerb'
ORDER BY text_titel;