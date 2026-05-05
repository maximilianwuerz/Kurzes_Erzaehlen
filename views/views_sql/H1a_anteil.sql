-- Ermittlung des Anteils in Relation zum breiten Register (=178)
CREATE OR REPLACE VIEW "H1a_anteil" AS
SELECT
  COUNT(*) AS n_aktive_mit_ke,
  173      AS n_aktive_gesamt,
  ROUND(100.0 * COUNT(*) / 173, 2) AS anteil_prozent,
  (COUNT(*)::numeric / 173 > 0.33) AS ueber_33_prozent
FROM "H1a-abs";