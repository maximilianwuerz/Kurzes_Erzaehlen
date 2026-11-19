# Dies ist das Repository des Dissertationsprojekts "Kurzes Erzählen im 21. Jahrhundert - Entstehungsbedingungen und Aneignungspotenziale kurzer Erzählformen in der Gegenwart" 
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20126377.svg)](https://doi.org/10.5281/zenodo.20126377)

# Worum geht es? 
Im Zuge des Projekts wurde quantitativ untersucht, unter welchen öffentlichen Rahmenbedingungen kurze Erzählformen gegenwärtig (d.h. im Zeitraum 2008-2023) entstehen und welche Effekte sie potenziell auf sie umgebende Umwelten haben können. Hierfür wurde ein umfassendes Datenkorpus mit Informationen zu kurzen Erzählformen, zu den für sie relevanten Publikationssegmenten (Bücher, Literaturzeitschriften, Literaturwettbewerbe, Social-Reading-Plattformen) und den Akteuren, die an ihrer Entstehung, Verbreitung und Rezeption direkt beteiligt sind, erstellt. Die Daten zu kurzen Erzählformen und Literaturzeitschriften, Literaturwettbewerben sowie Social-Reading-Plattformen wurden eigenständig recherchiert und zusammengetragen. Die Daten zu kurzen Erzählformen und Büchern entstammen dem bibliografischen Gesamtbestand der Deutschen Nationalbibliothek. 

# Das Verzeichnis /skripte_aufbau_datenkorpus
Mit den Python-Skripten (und z.T. SQL-Skripten) im Verzeichnis /skripte_aufbau_datenkorpus wurden die aus dem DNB-Katalog exportierten Rohdaten bereinigt, Informationen zu den relevanten Akteuren (Personen, Körperschaften) aus allen im Datenkorpus vorhandenen Dateien exportiert, konsolidiert und in eigenen Dateien gespeichert. Auch wurden damit die Objekttabellen (literaturzeitschrift, literaturzeitschrift_ausgabe, literaturwettbewerb etc.) und Verknüpfungstabellen (person_rolle_objekt, koerperschaft_rolle_objekt) erstellt. 

# Das Verzeichnis /tabellen_datenkorpus 
Darin sind alle Tabellen des Datenkorpus versammelt. Im Verzeichnis /import liegen die Rohdateien, die in die RDB eingespeist wurden. Im Verzeichnis /export liegen die finalen Tabellen aus der RDB. Letztere wurden im Zuge der empirischen Untersuchung ausgewertet; sie stellen die Datenbasis für die erzeugten Views dar. 

# Das Verzeichnis /views 
Der Unterorder /views_sql enthält jene SQL-Abfragen, die bei Prüfung der Hypothesen zum Einsatz kamen, wobei die Namen der Skripte, den geprüften Hypothesen entsprechen. 
Im Unterordner /views_csv finden sich Abzüge der dabei erstellten Views als CSV-Dateien. 

# Das Verzeichnis /tm
Darin sind verschiedene Python-Skripte enthalten, die im Zuge der statistisch-probabilistischen Auswertung des Textkorpus mittels Topic Modeling (MALLET) ausgeführt wurden. Zudem finden sich darin einzelne Diagnose- und Ergebnisfiles, ein Codebook und der beim Trainieren des Topics genutzte Befehl als Textdatei. Da das Textkorpus urheberrechtlich relevante Texte enthält, wurde es ebenso wie einzelne sensible Ergebnisdateien vor dem unberechtigten Zugriff durch Dritte im Forschungsinformationssystem der Friedrich-Alexander-Universität Erlangen-Nürnberg (CRIS) hinterlegt. Siehe hierzu: Würz, Maximilian: Text corpus for the Dissertation "Kurzes Erzählen im 21. Jahrhundert. Entstehungsbedingungen und Aneignungspotenziale kurzer Erzählformen in der Gegenwart". 2026. DOI: 10.48742/fau.zpwv-2f87. 

# Das Verzeichnis /skripte_auswahl_textkorpus 
Die SQL-Skripte im Verzeichnis /skripte_auswahl_textkorpus dienten dem Selektionsprozess bei der Konstitution des Textkorpus. 

# Versionen und Änderungen

## Version 1.1.0 (November 2026)
Für die Buchpublikation der Dissertation wurde die Tabelle literaturzeitschrift_ausgabe mit dem Textkorpus abgeglichen und mit dem Skript 15_Korrektur_literaturzeitschrift_ausgabe.sql (Verzeichnis /skripte_aufbau_datenkorpus) korrigiert. Im Einzelnen wurden
- Sammeleinträge in Einzeltitel aufgeschlüsselt (Sinn und Form 2/2012, 5/2014, 4/2020),
- Sammeltitel, die zusätzlich zu den Einzeltiteln erfasst waren, entfernt bzw. durch den fehlenden Einzeltitel ersetzt (Spr.i.t.Z. 189, 190, 217),
- acht Texte entfernt, die nach erneuter Prüfung keine kurzen Erzählformen sind (Sinn und Form 3/2009, 3/2012, 3/2017, 1/2022), posthum erschienen sind (Sinn und Form 1/2015, 3/2016, 5/2016) oder bei denen nicht abschließend geklärt werden konnte, ob sie originär in deutscher Sprache verfasst wurden (Spr.i.t.Z. Sonderheft 2008),
- eine Heftzuordnung korrigiert und ein fehlender Text ergänzt (Sinn und Form 4/2021 und 5/2021) sowie ein Titel berichtigt (Spr.i.t.Z. 190).

Die Tabelle umfasst damit für Sinn und Form 97 kurze Erzählformen in 51 Heften (zuvor 87 in 54) und für die Spr.i.t.Z. 135 kurze Erzählformen in 46 Heften (zuvor 137 in 46) und stimmt mit dem Textkorpus überein. Die davon abhängigen Einträge in den Tabellen person_rolle_objekt und person wurden angepasst. Die Tabellen in /tabellen_datenkorpus/export, die betroffenen Views (H1b, H7, H12) in /views/views_csv sowie der Datenbank-Dump (backup_rdb_kurzes_erzaehlen.sql) wurden neu erzeugt. Die Bewertung der Hypothesen ändert sich dadurch nicht. Die Rohdateien in /tabellen_datenkorpus/import blieben unverändert.

Darüber hinaus wurde das Verzeichnis /views bereinigt: Die CSV-Dateien zu H5, H6b_literaturferne_beteiligungen und H8c_manifestationen wurden auf den Stand der Datenbank gebracht, die fehlenden Dateien H5b_gew.csv, H8b_auflagenhoehe_zeitschriften.csv und H8b_publikationszyklus.csv ergänzt und H4a-trend.csv in H4a_trend.csv umbenannt. Entfernt wurden eine doppelte Datei (H1a-abs.csv), veraltete Dateien ohne zugehörige Abfrage (H6b_literaturferne_beteiligungen_gestaffelt.csv, H6b_literaturferne_beteiligungen_gestaffelt_gew.csv, H7c_autoren_pre_post_norm.csv) sowie die in der Arbeit nicht verwendeten Abfragen H2a_laufzeit, H2a_laufzeit_kat und H2a_laufzeit_kat2.

## Version 1.0.0 (Mai 2026)
Fassung zum Zeitpunkt der Einreichung der Dissertation.

# Kontakt
- Email: [maximilian.wuerz@fau.de](mailto:maximilian.wuerz@fau.de)
