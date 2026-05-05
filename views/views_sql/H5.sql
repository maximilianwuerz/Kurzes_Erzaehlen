CREATE OR REPLACE VIEW "H5" AS
SELECT
	koerperschaft_name,
	koerperschaft_name_gnd,
	gnd_sachgruppe,
CASE 
	WHEN koerperschaft_name_gnd ILIKE '%Verl.%' 
		OR koerperschaft_name_gnd ILIKE '%Verlag%' 
		OR koerperschaft_name_gnd ILIKE '%Ed.%'
		OR (koerperschaft_name_gnd ILIKE '%Edition%' AND koerperschaft_name_gnd NOT ILIKE '%tredition%')
		THEN 'Verlag'
	WHEN koerperschaft_name_gnd ILIKE '%Verein%' 
		OR koerperschaft_name_gnd ILIKE '%e.V.%' 
		THEN 'Verein'
	WHEN koerperschaft_name_gnd ILIKE '%Akademie%' 
		THEN 'Akademie'
	WHEN koerperschaft_name_gnd ILIKE '%Institut%' 
		THEN 'Institut'
	WHEN koerperschaft_name_gnd ILIKE '%Druck%' 
		THEN 'Druckerei'
	WHEN koerperschaft_name_gnd ILIKE '%Buchhandl%' 
		THEN 'Buchhandlung'
	WHEN koerperschaft_name_gnd ILIKE '%Verband%' 
		OR koerperschaft_name_gnd ILIKE '%Verb.%' 
		THEN 'Verband'
	WHEN koerperschaft_name_gnd ILIKE '%Forum%' 
		OR koerperschaft_name_gnd ILIKE '%Gemeinschaft%' 
		OR koerperschaft_name_gnd ILIKE '%Gruppe%'
		OR koerperschaft_name_gnd ILIKE '%Kollektiv%'
		OR koerperschaft_name_gnd ILIKE '%Kreis%' 
		OR koerperschaft_name_gnd ILIKE '%Club%' 
		OR koerperschaft_name_gnd ILIKE '%Gesellschaft%' 
		OR koerperschaft_name_gnd ILIKE '%Netzwerk%'
		THEN 'Gemeinschaft'
	WHEN koerperschaft_name_gnd ILIKE '%mbh%' 	
		OR koerperschaft_name_gnd ILIKE '%m.b.h.%'
		OR koerperschaft_name_gnd ILIKE '%GbR%'
		OR koerperschaft_name_gnd ILIKE '%oHG%'
		/*OR koerperschaft_name_gnd ILIKE '%KG%'
		OR koerperschaft_name_gnd ILIKE '%AG%'*/
		OR koerperschaft_name_gnd ILIKE '%e.k.%'
		OR koerperschaft_name_gnd ILIKE '%Firma%' 
		THEN 'Unternehmen'
    ELSE NULL
END AS name_flag
FROM koerperschaft k
WHERE LOWER(COALESCE(k.gnd_sachgruppe,'')) LIKE '%buchhandel%';
