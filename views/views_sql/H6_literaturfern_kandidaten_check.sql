CREATE TABLE IF NOT EXISTS "H6_literaturfern_kandidaten_check" (
  koerperschaft_id text PRIMARY KEY,
  koerperschaft_name text,
  koerperschaft_name_gnd text,
  gnd_sachgruppe text,
  name_flag text,
  literaturfern_status text NOT NULL DEFAULT 'unklar'
    CHECK (literaturfern_status IN ('true','false','unklar')),
  bemerkung text,
  website text,
  updated_at timestamp WITHOUT time ZONE DEFAULT now()
);



INSERT INTO "H6_literaturfern_kandidaten_check" (
  koerperschaft_id, koerperschaft_name, koerperschaft_name_gnd, gnd_sachgruppe, name_flag
)
SELECT
  k.koerperschaft_id, k.koerperschaft_name, k.koerperschaft_name_gnd, k.gnd_sachgruppe, k.name_flag
FROM "H6_literaturfern_kandidaten" k
ON CONFLICT (koerperschaft_id) DO NOTHING;


-- UPDATE NACH NAMEN FÜR HALBAUTOMATISCHE TYPOLOGISIERUNG
UPDATE "H6_literaturfern_kandidaten_check"
SET literaturfern_status = 'false',
    updated_at = now()
WHERE
  coalesce(koerperschaft_name, '') ilike any (array[
    '%litera%', '%verlag%', '%publ%', '%autor%', '%print%', '%druck%',
    '%buch%', '%bücher%', '%book%', '%biblio%', '%schriftstell%', '%edition%'
  ])
  or coalesce(koerperschaft_name_gnd, '') ilike any (array[
    '%litera%', '%verlag%', '%publ%', '%autor%', '%print%', '%druck%',
    '%buch%', '%bücher%', '%book%', '%biblio%', '%schriftstell%', '%edition%'
  ]);

UPDATE "H6_literaturfern_kandidaten_check"
SET literaturfern_status = 'true',
	updated_at = now()
WHERE
	(
	coalesce(koerperschaft_name, '') ilike any (array[
  	'%stadt %','%schule%', '%landkreis%', '%gemeinde%'])
  	or coalesce(koerperschaft_name_gnd, '') ilike any (array[
  	'%stadt %','%schule%', '%landkreis%', '%gemeinde%'])
	 )
  and not (
    coalesce(koerperschaft_name, '') ilike any (array['%litera%','%verlag%','%publ%','%autor%','%print%','%druck%','%buch%','%bücher%','%book%','%biblio%','%schriftstell%','%edition%'])
    or coalesce(koerperschaft_name_gnd, '') ilike any (array['%litera%','%verlag%','%publ%','%autor%','%print%','%druck%','%buch%','%bücher%','%book%','%biblio%','%schriftstell%','%edition%'])
  );