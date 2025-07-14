-- Trigger und Funktionen für das Löschen von Rollen-Einträgen in den Tabellen person_rolle_objekt und koerperschaft_rolle_objekt
-- Anpassung 30.06.2025: Ausnahmen bei Löschfunktion (ab Zeile 112) für Person und Koerperschaft hinzugefügt

-- Bei Löschvorgängen in der Tabelle buch 
-- Funktion zum Entfernen von Rollen-Einträgen mit Verbindung zur Tabelle Buch
CREATE OR REPLACE FUNCTION remove_role_entries_b()
RETURNS TRIGGER AS $
BEGIN
    DELETE FROM person_rolle_objekt
    WHERE objekt_id = OLD.isbn AND objekt_typ = 'Buch';

    DELETE FROM koerperschaft_rolle_objekt
    WHERE objekt_id = OLD.isbn AND objekt_typ = 'Buch';

    RETURN OLD;
END;
$ LANGUAGE plpgsql;

-- Trigger zum Auslösen der Funktion zum Entfernen von Rollen-Einträgen, sobald eine Zeile in Buch gelöscht wird 

CREATE TRIGGER delete_buch_related
AFTER DELETE ON buch2
FOR EACH ROW EXECUTE FUNCTION remove_role_entries_b();


-- Bei Löschvorgängen in der Tabelle literaturzeitschrift 
-- Funktion zum Entfernen von Rollen-Einträgen mit Verbindung zur Tabelle literaturzeitschrift
CREATE OR REPLACE FUNCTION remove_role_entries_lz()
RETURNS TRIGGER AS $
BEGIN
    DELETE FROM person_rolle_objekt
    WHERE objekt_id = OLD.literaturzeitschrift_id AND objekt_typ = 'Literaturzeitschrift';

    DELETE FROM koerperschaft_rolle_objekt
    WHERE objekt_id = OLD.literaturzeitschrift_id AND objekt_typ = 'Literaturzeitschrift';

    RETURN OLD;
END;
$ LANGUAGE plpgsql;

-- Trigger zum Auslösen der Funktion zum Entfernen von Rollen-Einträgen, sobald eine Zeile in literaturzeitschrift gelöscht wird 
CREATE TRIGGER delete_lz_related
AFTER DELETE ON literaturzeitschrift
FOR EACH ROW EXECUTE FUNCTION remove_role_entries_lz();



-- Bei Löschvorgängen in der Tabelle literaturwettbewerb 
-- Funktion zum Entfernen von Rollen-Einträgen mit Verbindung zur Tabelle literaturwettbewerb
CREATE OR REPLACE FUNCTION remove_role_entries_lw()
RETURNS TRIGGER AS $
BEGIN
    DELETE FROM person_rolle_objekt
    WHERE objekt_id = OLD.literaturwettbewerb_id AND objekt_typ = 'Literaturwettbewerb';

    DELETE FROM koerperschaft_rolle_objekt
    WHERE objekt_id = OLD.literaturwettbewerb_id AND objekt_typ = 'Literaturwettbewerb';

    RETURN OLD;
END;
$ LANGUAGE plpgsql;

-- Trigger zum Auslösen der Funktion zum Entfernen von Rollen-Einträgen, sobald eine Zeile in literaturwettbewerb gelöscht wird 
CREATE TRIGGER delete_lw_related
AFTER DELETE ON literaturwettbewerb
FOR EACH ROW EXECUTE FUNCTION remove_role_entries_lw();


-- Bei Löschvorgängen in der Tabelle literaturwettbewerb_ausgabe 
-- Funktion zum Entfernen von Rollen-Einträgen mit Verbindung zur Tabelle literaturwettbewerb_ausgabe
CREATE OR REPLACE FUNCTION remove_role_entries_lwa()
RETURNS TRIGGER AS $
BEGIN
    DELETE FROM person_rolle_objekt
    WHERE objekt_id = OLD.literaturwettbewerb_ausgabe_id AND objekt_typ = 'Literaturwettbewerb Ausgabe';

    DELETE FROM koerperschaft_rolle_objekt
    WHERE objekt_id = OLD.literaturwettbewerb_ausgabe_id AND objekt_typ = 'Literaturwettbewerb Ausgabe';

    RETURN OLD;
END;
$ LANGUAGE plpgsql;

-- Trigger zum Auslösen der Funktion zum Entfernen von Rollen-Einträgen, sobald eine Zeile in literaturwettbewerb_ausgabe gelöscht wird 
CREATE TRIGGER delete_lwa_related
AFTER DELETE ON literaturwettbewerb_ausgabe
FOR EACH ROW EXECUTE FUNCTION remove_role_entries_lwa();


-- Bei Löschvorgängen in der Tabelle plattform_internet 
-- Funktion zum Entfernen von Rollen-Einträgen mit Verbindung zur Tabelle plattform_internet
CREATE OR REPLACE FUNCTION remove_role_entries_pl()
RETURNS TRIGGER AS $
BEGIN
    DELETE FROM person_rolle_objekt
    WHERE objekt_id = OLD.plattform_id AND objekt_typ = 'Plattform Internet';

    DELETE FROM koerperschaft_rolle_objekt
    WHERE objekt_id = OLD.plattform_id AND objekt_typ = 'Plattform Internet';

    RETURN OLD;
END;
$ LANGUAGE plpgsql;

-- Trigger zum Auslösen der Funktion zum Entfernen von Rollen-Einträgen, sobald eine Zeile in plattform_internet gelöscht wird 
CREATE TRIGGER delete_pl_related
AFTER DELETE ON plattform_internet
FOR EACH ROW EXECUTE FUNCTION remove_role_entries_pl();



-- Funktion zur Bereingung der Tabellen person und koerperschaft
-- Erstellung der Funktion
CREATE OR REPLACE FUNCTION remove_unused_entities()
RETURNS VOID AS $
BEGIN
    DELETE FROM person 
    WHERE person_id NOT IN (SELECT DISTINCT person_id FROM person_rolle_objekt)
    AND (person_username_ff IS NULL OR person_username_ff = '');
    AND person_id <> 'P13148'; -- hierbei handelt es sich um eine person_id, die creator einer Internetplattform ist,
    -- diese ist aufgrund der 1-n-Beziehung  nicht in der person_rolle_objekt gelistet
    
    DELETE FROM koerperschaft 
    WHERE koerperschaft_id NOT IN (SELECT DISTINCT koerperschaft_id FROM koerperschaft_rolle_objekt)
    AND koerperschaft_id NOT IN ('K3296', 'K3191', 'K3015', 'K2498', 'K3054', 'K1421', 'K2016'); 
    -- hierbei handelt es sich um koerperschaft_ids, die creator der Internetplattformen sind, 
    -- diese sind aufgrund der 1-n-Beziehungen  nicht in der koerperschaft_rolle_objekt gelistet
END;
$ LANGUAGE plpgsql;

-- Ausführen der Funktion aktuell noch manuell (kann aber per Cron-Job in festgelegten Zeitplänen automatisiert ausgeführt werden)
SELECT remove_unused_entities();