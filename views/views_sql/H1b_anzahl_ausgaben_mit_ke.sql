CREATE OR REPLACE VIEW "H1b_anzahl_ausgaben_mit_ke" AS
SELECT
  lza.literaturzeitschrift_id,
  lza.ausgabevonliteraturzeitschrift AS literaturzeitschrift_name,
  COUNT(*) AS anzahl_ausgaben
FROM literaturzeitschrift_ausgabe AS lza
GROUP BY lza.literaturzeitschrift_id, lza.ausgabevonliteraturzeitschrift
ORDER BY anzahl_ausgaben DESC, literaturzeitschrift_name;