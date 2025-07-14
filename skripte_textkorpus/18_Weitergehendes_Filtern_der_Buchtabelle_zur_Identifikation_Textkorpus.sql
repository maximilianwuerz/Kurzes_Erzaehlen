

-- AB HIER FILTERN AUF KOERPERSCHAFTNAMEN UND JAHR 
WITH gefilterte_koerperschaften AS (
    SELECT koerperschaft_id
    FROM koerperschaft
	-- hier die spezifischen Namen eintragen und NOT ein- oder auskommentieren, je nach Intention
   WHERE /*NOT*/ koerperschaft_name ILIKE ANY (array[
        '%Rowohlt%', 
        '%Suhrkamp%', 
        '%dtv%', 
        '%piper%', 
        '%Diogenes%', 
        '%btb%', 
        '%Kiepenheu%', 
        '%Verbrecher%', 
        '%Reclam%', 
        '%Insel%', 
        '%Aufbau%', 
        '%Fischer%', 
        '%Mitteldeutsch%', 
        '%Deutsche Verlags-Anstalt%'
    ])
),
expanded_entries AS (
    SELECT b.*, unnest(string_to_array(b.buchverlegtvon, ';')) AS id
    FROM ausgewählte_bücher3 b
    WHERE b.publikationsjahr = 2011
	AND b.auflage NOT ILIKE '%2.%'
	AND b.auflage NOT ILIKE	'%3.%' 
	AND b.auflage NOT ILIKE	'%4.%'
	AND b.auflage NOT ILIKE	'%5.%' 
	AND b.auflage NOT ILIKE	'%6.%' 
	AND b.auflage NOT ILIKE	'%7.%' 
	AND b.auflage NOT ILIKE	'%8.%' 
	AND b.auflage NOT ILIKE	'%9.%'
	AND b.auflage NOT ILIKE	'%10.%'
	AND b.auflage NOT ILIKE	'%11.%' 
	AND b.auflage NOT ILIKE	'%Neu%'
	AND b.auflage NOT ILIKE	'%Erw%' 
	AND b.auflage NOT ILIKE	'%über%' 
	AND b.auflage NOT ILIKE	'%Zweit%' 
	AND b.auflage NOT ILIKE	'%Dritt%'
	AND b.auflage NOT ILIKE	'%Viert%'
	AND b.auflage NOT ILIKE	'%Fünft%'
	AND b.auflage NOT ILIKE	'%Sechs%'
	AND b.auflage NOT ILIKE	'%Sieb%'
	AND b.auflage NOT ILIKE	'%Acht%'
	AND b.auflage NOT ILIKE	'%Neun%'
	AND b.auflage NOT ILIKE	'%Zehn%'
	AND b.auflage NOT ILIKE	'%Nachdr%'
	AND b.auflage NOT ILIKE	'%über%'
    UNION ALL
    SELECT b.*, unnest(string_to_array(b.verfasser, ';')) AS id
    FROM ausgewählte_bücher3 b
    WHERE b.publikationsjahr = 2011
    UNION ALL
    SELECT b.*, unnest(string_to_array(b.herausgeber, ';')) AS id
    FROM ausgewählte_bücher3 b
    WHERE b.publikationsjahr = 2011
)
SELECT DISTINCT e.*
FROM expanded_entries e
JOIN gefilterte_koerperschaften gk ON e.id = gk.koerperschaft_id;