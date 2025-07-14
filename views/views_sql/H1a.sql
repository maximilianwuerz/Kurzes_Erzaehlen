-- Hiermit wird die View für die Prüfung der Hypothese H1a erstellt
-- Die View beinhaltet alle identifizierten Literaturzeitschriften mit regelmäßigen Publikationen von KE im Beobachtungszeitraum

CREATE OR REPLACE VIEW H1a AS
SELECT 
    literaturzeitschrift_name, 
    erstveroeffentlichung, 
    publikationszyklus, 
    auflagenhoehe
FROM 
    literaturzeitschrift
ORDER BY 
    literaturzeitschrift_name;