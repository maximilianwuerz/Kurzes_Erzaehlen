
CREATE OR REPLACE VIEW "H1a_abs" AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY literaturzeitschrift_name) AS ZN,
    literaturzeitschrift_name, 
    erstveroeffentlichung, 
    publikationszyklus, 
    auflagenhoehe
FROM 
    literaturzeitschrift
ORDER BY 
    literaturzeitschrift_name;