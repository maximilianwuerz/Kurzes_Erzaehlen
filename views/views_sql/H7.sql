-- Erstellung der View H7 in der alle Beteiligungen von allen Personen enthalten sind 
CREATE OR REPLACE VIEW H7 AS -- früher pro_mit_lz_ff_beitraege
SELECT DISTINCT 
    pro.person_id, 
    p.person_name, 
    pro.objekt_typ, 
    pro.rolle, 
    pro.objekt_id, 
    COALESCE(
        b.publikationsjahr, 
        lza.erscheinungsjahr,
        lwa.jahr
    ) AS publikationsjahr
FROM 
    person_rolle_objekt pro
JOIN 
    person p ON pro.person_id = p.person_id
LEFT JOIN 
    buch b ON pro.objekt_id = b.isbn AND pro.objekt_typ = 'Buch'
LEFT JOIN 
    literaturzeitschrift_ausgabe lza ON pro.objekt_id = lza.literaturzeitschrift_ausgabe_id AND pro.objekt_typ = 'Literaturzeitschrift'
LEFT JOIN 
    literaturwettbewerb_ausgabe lwa ON pro.objekt_id = lwa.literaturwettbewerb_ausgabe_id AND pro.objekt_typ = 'Literaturwettbewerb Ausgabe'

UNION ALL

SELECT DISTINCT 
    tk.verfasser_id AS person_id, 
    p.person_name, 
    'Literaturzeitschrift' AS objekt_typ,
    'VerfasserIn Literaturzeitschrift Beitrag' AS rolle,
    tk.text_id AS objekt_id,
    tk.publikationsjahr
FROM 
    textkorpus tk
JOIN 
    person p ON tk.verfasser_id = p.person_id
WHERE 
    tk.publikationssegment = 'Literaturzeitschrift'

UNION ALL

SELECT DISTINCT 
    tk.verfasser_id AS person_id, 
    COALESCE(p.person_name, p.person_username_ff) AS person_name, 
    'Plattform' AS objekt_typ,
    'VerfasserIn Plattform Text' AS rolle,
    tk.text_id AS objekt_id,
    tk.publikationsjahr
FROM 
    textkorpus tk
JOIN 
    person p ON tk.verfasser_id = p.person_id
WHERE 
    tk.publikationssegment LIKE '%Plattform%';


-- Abfrage: Gib mir alle Personen, die mehr als n Mal an einem Text oder Artefakt beteiligt waren 
SELECT *
FROM H7
WHERE person_name IN (
  SELECT person_name
  FROM H7
  GROUP BY person_name
  HAVING COUNT(*) >= 5
)
ORDER BY person_name, publikationsjahr;


-- Abfrage: Gib mir alle noch lebenden Personen, die mehr als x Mal als Verfasser:in eines Textes oder Artefakts gelistet sind 
-- Bedenken: Ungleiche Gewichtung: Verfassen eines Buches (mit x Texten) wiegt genauso stark, wie ein Textbeitrag in einer
-- Zeitschrift oder auf einer Plattform
SELECT 
   	H7.person_id, 
    p.person_name, 
    COUNT(*) AS anzahl_beitraege
FROM 
    H7
JOIN 
    person p ON H7.person_id = p.person_id
WHERE 
    (rolle LIKE '%Verfasser%' 
     OR rolle LIKE '%Gewinner%') 
    AND p.gnd_nummer IS NOT NULL -- optionaler Schritt: nur Personen mit GND-Eintrag
    AND p.sterbedatum_gnd IS NULL -- optionaler Schrit: bereits verstorbene Personen ausschließen
GROUP BY 
    H7.person_id, 
    p.person_name
HAVING 
    COUNT(*) > 6 -- x kann beliebig angepasst werden
ORDER BY 
    anzahl_beitraege DESC;


-- Wie oft kommen die einzelnen Rollen vor? 
SELECT
    rolle,
    COUNT(*) AS anzahl_vorkommen
FROM
    H7
JOIN
    person p ON H7.person_id = p.person_id
 /*WHERE
    p.gnd_nummer IS NOT NULL -- optionaler Schritt: nur Personen mit GND-Eintrag
    AND p.sterbedatum_gnd IS NULL*/ -- optionaler Schrit: bereits verstorbene Personen ausschließen
GROUP BY
    rolle
ORDER BY
    anzahl_vorkommen DESC;


-- Personen ermitteln, die neben dem Gewinn eines im Korpus vorhandenen Wettbewerb, eine weitere Rolle eingenommen haben
SELECT DISTINCT 
    p.person_id, 
    p.person_name
FROM 
    person p
JOIN 
    h7 h71 ON p.person_id = h71.person_id
JOIN 
    h7 h722 ON p.person_id = h722.person_id
WHERE 
    h71.rolle = 'GewinnerIn'
    AND h722.rolle != 'GewinnerIn';


-- Personen ermitteln, die NACH dem Gewinn eines im Korpus vorhandenen Wettbewerb, eine weitere Rolle eingenommen haben
-- Hier wird der zeitliche Aspekt berücksichtigt 
CREATE OR REPLACE VIEW H7_gewinner_mit_folgebeteiligungen AS
WITH gewinn_rollen AS (
    SELECT 
        pro.person_id, 
        COALESCE(
            b.publikationsjahr, 
            lza.erscheinungsjahr, 
            lwa.jahr
        ) AS gewinnjahr
    FROM 
        person_rolle_objekt pro
    LEFT JOIN 
        buch b ON pro.objekt_id = b.isbn AND pro.objekt_typ = 'Buch'
    LEFT JOIN 
        literaturzeitschrift_ausgabe lza ON pro.objekt_id = lza.literaturzeitschrift_ausgabe_id AND pro.objekt_typ = 'Literaturzeitschrift'
    LEFT JOIN 
        literaturwettbewerb_ausgabe lwa ON pro.objekt_id = lwa.literaturwettbewerb_ausgabe_id AND pro.objekt_typ = 'Literaturwettbewerb Ausgabe'
    WHERE 
        pro.rolle = 'GewinnerIn'
),
personenfolgerolle AS (
    SELECT 
        pro.person_id, 
        pro.rolle AS folge_rolle, 
        COALESCE(
            b.publikationsjahr, 
            lza.erscheinungsjahr, 
            lwa.jahr
        ) AS folge_jahr
    FROM 
        person_rolle_objekt pro
    LEFT JOIN 
        buch b ON pro.objekt_id = b.isbn AND pro.objekt_typ = 'Buch'
    LEFT JOIN 
        literaturzeitschrift_ausgabe lza ON pro.objekt_id = lza.literaturzeitschrift_ausgabe_id AND pro.objekt_typ = 'Literaturzeitschrift'
    LEFT JOIN 
        literaturwettbewerb_ausgabe lwa ON pro.objekt_id = lwa.literaturwettbewerb_ausgabe_id AND pro.objekt_typ = 'Literaturwettbewerb Ausgabe'
    WHERE 
        pro.rolle != 'GewinnerIn'
)
SELECT DISTINCT 
    p.person_id, 
    p.person_name, 
    pfr.folge_rolle, 
    pfr.folge_jahr
FROM 
    person p
JOIN 
    gewinn_rollen gr ON p.person_id = gr.person_id
JOIN 
    personenfolgerolle pfr ON p.person_id = pfr.person_id
WHERE 
    pfr.folge_jahr > gr.gewinnjahr;