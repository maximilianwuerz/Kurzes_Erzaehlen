CREATE OR REPLACE VIEW "H3a" AS
SELECT
  ROW_NUMBER() OVER (ORDER BY plattform_name) AS zn,
  plattform_name,
  plattform_art,
  gruendungsjahr,
  anzahl_mitglieder,
  anzahl_texte_gesamt,
  anzahl_ke
  FROM plattform_internet
ORDER BY plattform_name;