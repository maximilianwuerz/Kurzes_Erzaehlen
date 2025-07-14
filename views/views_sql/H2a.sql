CREATE OR REPLACE VIEW H2a AS 
SELECT 
    lw.literaturwettbewerb_name,
    STRING_AGG(k.koerperschaft_name, '; ') AS veranstalter_names,
    lw.erstausrichtung,
    lw.laengenvorgabe_text,
    lw.themenvorgabe,
    lw.altersbeschraenkung,
    lw.ausrichtungszyklus,
    lw.preisart,
    lw.hoehe_preisgeld,
    lw.publikation,
    lw.live_event    
FROM 
    literaturwettbewerb lw
LEFT JOIN 
    LATERAL (
        SELECT koerperschaft_name
        FROM koerperschaft k
        WHERE k.koerperschaft_id = ANY(STRING_TO_ARRAY(lw.veranstalter, ';'))
    ) k ON TRUE
GROUP BY 
    lw.literaturwettbewerb_name, lw.erstausrichtung, lw.laengenvorgabe_text, 
    lw.themenvorgabe, lw.altersbeschraenkung, lw.ausrichtungszyklus, lw.preisart, 
    lw.hoehe_preisgeld, lw.publikation, lw.live_event
ORDER BY 
    lw.literaturwettbewerb_name;