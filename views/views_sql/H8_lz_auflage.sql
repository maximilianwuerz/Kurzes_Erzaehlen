-- Alle Literaturzeitschriften mit Angaben zur Auflagenhöhe
SELECT literaturzeitschrift_name, auflagenhoehe
FROM literaturzeitschrift
WHERE auflagenhoehe NOT LIKE '?'
