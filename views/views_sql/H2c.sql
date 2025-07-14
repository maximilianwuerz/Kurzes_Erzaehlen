-- Analyse der Spalte themenvorgabe und Berechnung des Anteils in Prozent
SELECT 
    themenvorgabe,
    COUNT(*) AS anzahl,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS prozent
FROM 
    literaturwettbewerb
GROUP BY 
    themenvorgabe;

-- Analyse der Spalte alterbeschraenkung nach Kategorien
SELECT 
    COUNT(*) AS anzahl_wettbewerbe,
    CASE 
		WHEN altersbeschraenkung LIKE '%;%' THEN 'Mehrere Altersgruppen'
        WHEN altersbeschraenkung LIKE '%-%' THEN 'Spezifizierter Bereich'
        WHEN altersbeschraenkung LIKE '%+%' THEN 'Mindestalter'
		WHEN altersbeschraenkung LIKE '%<%' THEN 'Höchstalter'
        WHEN altersbeschraenkung = 'nein' THEN 'Keine Beschränkung'
		WHEN altersbeschraenkung IS NULL THEN 'Keine Info'
        ELSE 'Andere'
    END AS kategorie
FROM 
    literaturwettbewerb
GROUP BY 
    kategorie;

