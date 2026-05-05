CREATE OR REPLACE VIEW "H7c_publ_nach_konsekr_auswert" AS
SELECT
  COUNT(*) AS n_autoren,
  SUM((n_after = 0)::int) AS n_keine_nachher,
  SUM((n_after >= 1)::int) AS n_mindestens_eine_nachher,
  ROUND(100.0*  SUM((n_after >= 1)::int)::numeric / NULLIF(COUNT(*), 0), 2) AS pct_mindestens_eine_nachher,
  ROUND(100.0*  SUM((n_after = 0)::int)::numeric / NULLIF(COUNT(*), 0), 2) AS pct_keine_nachher
FROM "H7c_publ_nach_konsekr";