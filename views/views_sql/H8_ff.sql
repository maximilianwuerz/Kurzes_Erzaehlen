-- Skript für Hypothesen-Prüfung H8 zum leserseitigen Interesse an KE
CREATE OR REPLACE VIEW H8 AS -- H8 = ff_texte_metadaten
SELECT * FROM ff_texte_metadaten
-- Prüfung des Engagements von Lesern bei den gescrapten Texten von Fanfiktion.de 
-- Gesamtzahl der Texte, Texte mit Empfehlung und Texte mit Review 
SELECT 
    COUNT(*) AS gesamtmenge_texte, -- Gesamtanzahl der Texte
    COUNT(CASE WHEN endorsement_amount > 0 THEN 1 END) AS texte_mit_endorsement, -- Anzahl der Texte mit endorsement_amount > 0
    COUNT(CASE WHEN review_amount > 0 THEN 1 END) AS texte_mit_review, -- Anzahl der Texte mit review_amount > 0
	COUNT(CASE WHEN endorsement_amount <= 0 AND review_amount <= 0 THEN 1 ELSE NULL END) AS  texte_ohne_engagement -- Anzahl der Texte ohne Engagement
FROM 
    ff_texte_metadaten;

-- Gibt die durchschnittliche Wortzahl pro Fälle aus 
SELECT 
    ROUND(AVG(CAST(wordcount AS NUMERIC))) AS durchschnitt_wordcount_gesamt, -- Durchschnittlicher Wordcount für alle Texte
    ROUND(AVG(CASE WHEN endorsement_amount > 0 THEN CAST(wordcount AS NUMERIC) END)) AS durchschnitt_wordcount_endorsement, -- Durchschnittlicher Wordcount für Texte mit endorsement_amount > 0
    ROUND(AVG(CASE WHEN review_amount > 0 THEN CAST(wordcount AS NUMERIC) END)) AS durchschnitt_wordcount_review, -- Durchschnittlicher Wordcount für Texte mit review_amount > 0
	ROUND(AVG(CASE WHEN review_amount <= 0 AND endorsement_amount <= 0 THEN CAST (wordcount AS NUMERIC) END)) AS durchschnitt_wordcount_ohne_engagement
FROM 
    ff_texte_metadaten;

-- Gibt die fünf häufigsten Genres pro Fall aus 
WITH genre_exploded AS (
    SELECT 
        unnest(string_to_array(genre, ',')) AS einzelnes_genre,
        CASE 
            WHEN endorsement_amount > 0 THEN 'Texte mit Endorsement'
            WHEN review_amount > 0 THEN 'Texte mit Review'
            WHEN endorsement_amount <= 0 AND review_amount <= 0 THEN 'Texte ohne Engagement'
        END AS kategorie,
        'Gesamt' AS gesamt_kategorie  -- Zusätzliche Kategorie für Gesamt
    FROM 
        ff_texte_metadaten
),
individuelle_counts AS (
    SELECT 
        kategorie,
        einzelnes_genre,
        COUNT(*) AS anzahl
    FROM 
        genre_exploded
    WHERE 
        kategorie IS NOT NULL  -- Sicherstellen, dass ordentliche Kategorisierung genutzt wird
    GROUP BY 
        kategorie, 
        einzelnes_genre
),
gesamt_counts AS (
    SELECT 
        gesamt_kategorie AS kategorie,
        einzelnes_genre,
        COUNT(*) AS anzahl
    FROM 
        genre_exploded
    GROUP BY 
        einzelnes_genre, 
        gesamt_kategorie
),
ranked_genres AS (
    SELECT 
        kategorie,
        einzelnes_genre,
        anzahl,
        ROW_NUMBER() OVER (PARTITION BY kategorie ORDER BY anzahl DESC) AS rn
    FROM 
        individuelle_counts
    UNION ALL
    SELECT
        kategorie,
        einzelnes_genre,
        anzahl,
        ROW_NUMBER() OVER (PARTITION BY kategorie ORDER BY anzahl DESC) AS rn
    FROM 
        gesamt_counts
)
SELECT 
    kategorie, 
    einzelnes_genre, 
    anzahl
FROM 
    ranked_genres
WHERE 
    rn <= 5
ORDER BY 
    kategorie, 
    anzahl DESC;


