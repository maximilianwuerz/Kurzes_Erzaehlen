-- Abfrage zur Erstellung der View "H1b"

CREATE OR REPLACE VIEW H1b AS
SELECT 
    lz.literaturzeitschrift_name,
    tk.publikationsjahr,
    COUNT(tk.text_titel) AS anzahl_texte
FROM 
    textkorpus tk
JOIN 
    literaturzeitschrift_ausgabe lza ON tk.publikationsobjekt_id = lza.literaturzeitschrift_ausgabe_id
JOIN 
    literaturzeitschrift lz ON lza.literaturzeitschrift_id = lz.literaturzeitschrift_id
WHERE 
    tk.publikationssegment = 'Literaturzeitschrift'
GROUP BY 
    lz.literaturzeitschrift_name, tk.publikationsjahr
ORDER BY 
    lz.literaturzeitschrift_name, tk.publikationsjahr;


-- Ermittlung der Anzahl an Beiträgen pro Heft in der Spr.i.t.Z

SELECT 
    lza.literaturzeitschrift_ausgabe_id, 
    lza.heftnummer, 
    COUNT(beitraege.value) AS anzahl_ke_beitraege
FROM 
    literaturzeitschrift_ausgabe lza
LEFT JOIN 
    LATERAL UNNEST(STRING_TO_ARRAY(lza.ke_beitraege, ';')) AS beitraege(value) ON TRUE
WHERE 
    lza.ausgabevonliteraturzeitschrift LIKE '%Spr.i.t.Z.%'
GROUP BY 
    lza.literaturzeitschrift_ausgabe_id, 
    lza.heftnummer
ORDER BY heftnummer;