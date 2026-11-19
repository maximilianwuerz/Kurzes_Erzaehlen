-- =====================================================================
-- 15_Korrektur_literaturzeitschrift_ausgabe.sql
-- Korrektur der Tabelle literaturzeitschrift_ausgabe (Sinn und Form,
-- Spr.i.t.Z.) und der davon abhängigen Einträge in person_rolle_objekt
-- und person. Stand: November 2026.
--
-- Anlass: Abgleich der Tabelle mit dem Textkorpus. Die Tabelle wird an die
-- im Textkorpus enthaltenen kurzen Erzählformen angeglichen:
--   * Sammeleinträge werden in Einzeltitel aufgeschlüsselt
--     (Sinn und Form 2/2012, 5/2014, 4/2020).
--   * Sammeltitel, die zusätzlich zu den Einzeltiteln erfasst waren, werden
--     entfernt bzw. durch den fehlenden Einzeltitel ersetzt
--     (Spr.i.t.Z. 189, 190, 217).
--   * Texte, die nach Prüfung keine kurzen Erzählformen sind (Sinn und Form
--     3/2009, 3/2012, 3/2017, 1/2022), posthum erschienene Texte
--     (Sinn und Form 1/2015, 3/2016, 5/2016) sowie ein Text, bei dem nicht
--     abschließend geklärt werden konnte, ob er originär in deutscher Sprache
--     verfasst wurde (Spr.i.t.Z. Sonderheft 2008), werden entfernt.
--     Hefte ohne verbleibende kurze Erzählform werden gelöscht, da die
--     Tabelle nur Hefte mit kurzen Erzählformen enthält.
--   * Heftverwechslung Sinn und Form 4/2021 und 5/2021 wird behoben;
--     neue Person: Breh, Laura (P26358, ohne GND-Eintrag).
--   * Titelkorrektur: „Nichts umsonst!“ -> „Nicht umsonst!“ (Spr.i.t.Z. 190).
--
-- Ergebnis: Sinn und Form 97 KE in 51 Heften (vorher 87 in 54),
--           Spr.i.t.Z. 135 KE in 46 Heften (vorher 137 in 46).
--
-- Ausführung auf dem Server:
--   psql -v ON_ERROR_STOP=1 -d kurzes_erzaehlen -f 15_Korrektur_literaturzeitschrift_ausgabe.sql
-- Das Skript läuft in einer Transaktion. Schlägt eine der Prüfungen fehl,
-- bricht es ab und es wird nichts verändert.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 0. Vorabprüfung: Ist der Ausgangszustand der erwartete?
-- ---------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT SUM(cardinality(array_remove(regexp_split_to_array(COALESCE(ke_beitraege,''), E'\\s*;\\s*'), '')))
    INTO n FROM literaturzeitschrift_ausgabe WHERE ausgabevonliteraturzeitschrift = 'Sinn und Form';
  IF n <> 87 THEN RAISE EXCEPTION 'Vorabprüfung: Sinn und Form hat % statt 87 KE', n; END IF;

  SELECT SUM(cardinality(array_remove(regexp_split_to_array(COALESCE(ke_beitraege,''), E'\\s*;\\s*'), '')))
    INTO n FROM literaturzeitschrift_ausgabe WHERE ausgabevonliteraturzeitschrift = 'Sprache im technischen Zeitalter (Spr.i.t.Z.)';
  IF n <> 137 THEN RAISE EXCEPTION 'Vorabprüfung: Spr.i.t.Z. hat % statt 137 KE', n; END IF;

  SELECT COUNT(*) INTO n FROM literaturzeitschrift_ausgabe;
  IF n <> 118 THEN RAISE EXCEPTION 'Vorabprüfung: literaturzeitschrift_ausgabe hat % statt 118 Zeilen', n; END IF;

  SELECT COUNT(*) INTO n FROM person_rolle_objekt WHERE objekt_typ = 'Literaturzeitschrift Ausgabe';
  IF n <> 209 THEN RAISE EXCEPTION 'Vorabprüfung: % statt 209 Verknüpfungen zu Ausgaben', n; END IF;

  IF EXISTS (SELECT 1 FROM person WHERE person_id = 'P26358') THEN
    RAISE EXCEPTION 'Vorabprüfung: P26358 existiert bereits'; END IF;
  IF EXISTS (SELECT 1 FROM literaturzeitschrift_ausgabe WHERE literaturzeitschrift_ausgabe_id = 'LZA119') THEN
    RAISE EXCEPTION 'Vorabprüfung: LZA119 existiert bereits'; END IF;
  IF EXISTS (SELECT 1 FROM person WHERE person_name ILIKE 'Breh,%') THEN
    RAISE EXCEPTION 'Vorabprüfung: Eine Person "Breh" existiert bereits'; END IF;

  SELECT COUNT(*) INTO n FROM literaturzeitschrift_ausgabe
   WHERE (literaturzeitschrift_ausgabe_id, ke_beitraege) IN (
     ('LZA9',  'Das Deutschlandleben eines harmlosen orientalischen Banditen; Mit der Metro in Kiew'),
     ('LZA11', 'Ventimiglia di Sicilia; Meine anderen Leben. Sieben Erzählungen aus einer Serie; Der Wolf; Pipihendi; Das Tier; Die Münzen; Der Turm; Die Ernte; Die Käsehändlerin'),
     ('LZA12', 'Kalendergeschichten; Am Ball; Nichts umsonst!; Die Stille danach; Einer, der sich getraut; Nichts geschenkt!; Stille Verlierer; Volkes Gesänge'),
     ('LZA15', 'Der Mörder meines Bruders; Flickwerk'),
     ('LZA30', 'Das große Gehege; Capriccios'),
     ('LZA34', 'Der Herr des Berges. Eine Geschichte.'),
     ('LZA44', 'Ins Nachtbuch'),
     ('LZA45', 'Die Kellnerin; Der Torweg'),
     ('LZA54', 'Alessandro; Drei Erzählungen. Alles Gute; Echos; Senke; Die Zerstörung; Mit einem Fuß draußen; Namors Nebel; Die Lauschenden; Lucia; Dickicht'),
     ('LZA56', 'Aufzeichnungen eines Lehrlings; Begegnung; Eine Frau allein'),
     ('LZA57', 'Paulkes letzter Tag'),
     ('LZA62', 'Von der Kunst eine Kurzgeschichte lang erscheinen zu lassen'),
     ('LZA80', 'Der Wächter; Die Glut; Im Innern des Berges; Mikroben; Wo keine Frage ist; Zartplastik; Die Liste; Die Abkürzung; Die leere Seite im Reisetagebuch'),
     ('LZA94', 'Das japanische Palais'),
     ('LZA96', 'Das Zusammenfalten der Zeit'));
  IF n <> 15 THEN RAISE EXCEPTION 'Vorabprüfung: nur % von 15 zu ändernden Zeilen entsprechen dem erwarteten Stand', n; END IF;
END $$;

-- ---------------------------------------------------------------------
-- 1. Sinn und Form
-- ---------------------------------------------------------------------
-- 3/2009: „Flickwerk“ (Braun) ist keine kurze Erzählform
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Der Mörder meines Bruders',
  verfasser_ke_beitraege = 'P10098'
WHERE literaturzeitschrift_ausgabe_id = 'LZA15';

-- 2/2012: Sammeleintrag „Capriccios“ (Böhme) aufgeschlüsselt
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Das große Gehege; Das Verzeihkabinett; Der beste Friseur; Der Unausschöpfbare; Die Falltür; Erheblicher Schaden; Unsere Sehenswürdigkeiten; Öffentliche Einrichtungen',
  verfasser_ke_beitraege = 'P5886; P2490; P2490; P2490; P2490; P2490; P2490; P2490'
WHERE literaturzeitschrift_ausgabe_id = 'LZA30';

-- 5/2014: Sammeleintrag „Ins Nachtbuch“ (Sayer) aufgeschlüsselt
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Altersstufen; Frühschwimmer; Ins Nachtbuch; Laufstil; Musikwald; Nachhilfestunde; Umkreis',
  verfasser_ke_beitraege = 'P15238; P15238; P15238; P15238; P15238; P15238; P15238'
WHERE literaturzeitschrift_ausgabe_id = 'LZA44';

-- 1/2015: „Die Kellnerin“ (Herrmann-Neiße) posthum erschienen
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Der Torweg',
  verfasser_ke_beitraege = 'P18616'
WHERE literaturzeitschrift_ausgabe_id = 'LZA45';

-- 3/2016: „Begegnung“ (Rohr) posthum erschienen
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Aufzeichnungen eines Lehrlings; Eine Frau allein',
  verfasser_ke_beitraege = 'P13551; P11515'
WHERE literaturzeitschrift_ausgabe_id = 'LZA56';

-- 4/2020: vier weitere Texte von Sayer ergänzt
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Der Wächter; Die Glut; Im Innern des Berges; Mikroben; Wo keine Frage ist; Zartplastik; Die Liste; Die Abkürzung; Additiv; Die Katze ist das Leben der Möbel; Die leere Seite im Reisetagebuch; Einschlafschwierigkeiten; Vermisstenanzeige',
  verfasser_ke_beitraege = 'P10314; P10314; P10314; P10314; P10314; P17309; P544; P15903; P15238; P15238; P15238; P15238; P15238'
WHERE literaturzeitschrift_ausgabe_id = 'LZA80';

-- 4/2021 -> 5/2021: „Das japanische Palais“ (Deckert) erschien in Heft 5
UPDATE literaturzeitschrift_ausgabe SET heftnummer = '5'
WHERE literaturzeitschrift_ausgabe_id = 'LZA94';

-- Hefte ohne verbleibende kurze Erzählform:
-- 3/2012 (Buselmeier), 5/2016 (Borchardt, posthum), 3/2017 (Estis), 1/2022 („Seyer“)
DELETE FROM person_rolle_objekt
WHERE objekt_typ = 'Literaturzeitschrift Ausgabe'
  AND objekt_id IN ('LZA34', 'LZA57', 'LZA62', 'LZA96');
DELETE FROM literaturzeitschrift_ausgabe
WHERE literaturzeitschrift_ausgabe_id IN ('LZA34', 'LZA57', 'LZA62', 'LZA96');

-- Verknüpfungen der entfernten Einzeltitel
DELETE FROM person_rolle_objekt
WHERE objekt_typ = 'Literaturzeitschrift Ausgabe'
  AND rolle = 'Verfasser Zeitschriftbeitrag'
  AND (objekt_id, person_id) IN (('LZA15', 'P2011'), ('LZA45', 'P7000'), ('LZA56', 'P14629'));

-- 4/2021: „Angst“ (Laura Breh) ergänzt
INSERT INTO person (person_id, person_name)
VALUES ('P26358', 'Breh, Laura');

INSERT INTO literaturzeitschrift_ausgabe
  (literaturzeitschrift_ausgabe_id, ausgabevonliteraturzeitschrift, literaturzeitschrift_id,
   heftnummer, erscheinungsjahr, ke_beitraege, verfasser_ke_beitraege)
VALUES ('LZA119', 'Sinn und Form', 'LZ68', '4', '2021', 'Angst', 'P26358');

INSERT INTO person_rolle_objekt (objekt_id, objekt_typ, person_id, rolle)
VALUES ('LZA119', 'Literaturzeitschrift Ausgabe', 'P26358', 'Verfasser Zeitschriftbeitrag');

-- ---------------------------------------------------------------------
-- 2. Spr.i.t.Z.
-- ---------------------------------------------------------------------
-- Sonderheft 2008: Text von Hvorecky; nicht abschließend geklärt, ob originär
--                  in deutscher Sprache verfasst (vermutlich Übersetzung)
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Mit der Metro in Kiew',
  verfasser_ke_beitraege = 'P9613'
WHERE literaturzeitschrift_ausgabe_id = 'LZA9';

DELETE FROM person_rolle_objekt
WHERE objekt_typ = 'Literaturzeitschrift Ausgabe'
  AND rolle = 'Verfasser Zeitschriftbeitrag'
  AND objekt_id = 'LZA9' AND person_id = 'P7622';

-- 189: Sammeltitel zusätzlich zu den sieben Einzeltiteln erfasst
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Ventimiglia di Sicilia; Der Wolf; Pipihendi; Das Tier; Die Münzen; Der Turm; Die Ernte; Die Käsehändlerin',
  verfasser_ke_beitraege = 'P3583; P6773; P6773; P6773; P6773; P6773; P6773; P6773'
WHERE literaturzeitschrift_ausgabe_id = 'LZA11';

-- 190: Sammeltitel „Kalendergeschichten“ durch fehlenden Einzeltitel ersetzt;
--      Titelkorrektur „Nicht umsonst!“
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Gesellen der Liebe; Am Ball; Nicht umsonst!; Die Stille danach; Einer, der sich getraut; Nichts geschenkt!; Stille Verlierer; Volkes Gesänge'
WHERE literaturzeitschrift_ausgabe_id = 'LZA12';

-- 217: Sammeltitel vom Einzeltitel getrennt
UPDATE literaturzeitschrift_ausgabe SET
  ke_beitraege = 'Alessandro; Alles Gute; Echos; Senke; Die Zerstörung; Mit einem Fuß draußen; Namors Nebel; Die Lauschenden; Lucia; Dickicht'
WHERE literaturzeitschrift_ausgabe_id = 'LZA54';

-- ---------------------------------------------------------------------
-- 3. Abschlussprüfung
-- ---------------------------------------------------------------------
DO $$
DECLARE n int; h int;
BEGIN
  SELECT SUM(cardinality(array_remove(regexp_split_to_array(COALESCE(ke_beitraege,''), E'\\s*;\\s*'), ''))), COUNT(*)
    INTO n, h FROM literaturzeitschrift_ausgabe WHERE ausgabevonliteraturzeitschrift = 'Sinn und Form';
  IF n <> 97 OR h <> 51 THEN RAISE EXCEPTION 'Abschlussprüfung: Sinn und Form % KE in % Heften (erwartet 97 / 51)', n, h; END IF;

  SELECT SUM(cardinality(array_remove(regexp_split_to_array(COALESCE(ke_beitraege,''), E'\\s*;\\s*'), ''))), COUNT(*)
    INTO n, h FROM literaturzeitschrift_ausgabe WHERE ausgabevonliteraturzeitschrift = 'Sprache im technischen Zeitalter (Spr.i.t.Z.)';
  IF n <> 135 OR h <> 46 THEN RAISE EXCEPTION 'Abschlussprüfung: Spr.i.t.Z. % KE in % Heften (erwartet 135 / 46)', n, h; END IF;

  SELECT COUNT(*) INTO n FROM literaturzeitschrift_ausgabe;
  IF n <> 115 THEN RAISE EXCEPTION 'Abschlussprüfung: % statt 115 Zeilen', n; END IF;

  SELECT COUNT(*) INTO n FROM person_rolle_objekt WHERE objekt_typ = 'Literaturzeitschrift Ausgabe';
  IF n <> 202 THEN RAISE EXCEPTION 'Abschlussprüfung: % statt 202 Verknüpfungen zu Ausgaben', n; END IF;

  -- Jede Ausgabe hat gleich viele Titel wie Verfasserangaben
  SELECT COUNT(*) INTO n FROM literaturzeitschrift_ausgabe
   WHERE cardinality(array_remove(regexp_split_to_array(COALESCE(ke_beitraege,''), E'\\s*;\\s*'), ''))
      <> cardinality(array_remove(regexp_split_to_array(COALESCE(verfasser_ke_beitraege,''), E'\\s*;\\s*'), ''))
     AND literaturzeitschrift_ausgabe_id IN ('LZA9','LZA11','LZA12','LZA15','LZA30','LZA44','LZA45','LZA54','LZA56','LZA80','LZA119');
  IF n <> 0 THEN RAISE EXCEPTION 'Abschlussprüfung: % geänderte Zeilen mit ungleich vielen Titeln und Verfassern', n; END IF;

  -- Verfasserangaben in der Ausgabentabelle und Verknüpfungstabelle stimmen überein
  SELECT COUNT(*) INTO n FROM (
    (SELECT DISTINCT lza.literaturzeitschrift_ausgabe_id, t.id
       FROM literaturzeitschrift_ausgabe lza
       CROSS JOIN LATERAL unnest(regexp_split_to_array(COALESCE(lza.verfasser_ke_beitraege,''), '\s*;\s*')) AS t(id)
      WHERE t.id LIKE 'P%'
     EXCEPT
     SELECT objekt_id, person_id FROM person_rolle_objekt
      WHERE objekt_typ = 'Literaturzeitschrift Ausgabe' AND rolle = 'Verfasser Zeitschriftbeitrag')
    UNION ALL
    (SELECT objekt_id, person_id FROM person_rolle_objekt
      WHERE objekt_typ = 'Literaturzeitschrift Ausgabe' AND rolle = 'Verfasser Zeitschriftbeitrag'
     EXCEPT
     SELECT DISTINCT lza.literaturzeitschrift_ausgabe_id, t.id
       FROM literaturzeitschrift_ausgabe lza
       CROSS JOIN LATERAL unnest(regexp_split_to_array(COALESCE(lza.verfasser_ke_beitraege,''), '\s*;\s*')) AS t(id)
      WHERE t.id LIKE 'P%')
  ) d;
  IF n <> 0 THEN RAISE EXCEPTION 'Abschlussprüfung: % Abweichungen zwischen Ausgabentabelle und person_rolle_objekt', n; END IF;

  RAISE NOTICE 'Alle Prüfungen bestanden.';
END $$;

COMMIT;
