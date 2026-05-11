# Dies ist das Repository des Dissertationsprojekts "Kurzes Erzählen im 21. Jahrhundert - Entstehungsbedingungen und Aneignungspotenziale kurzer Erzählformen in der Gegenwart" 
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20126377.svg)](https://doi.org/10.5281/zenodo.20126377)

# Worum geht es? 
Im Zuge des Projekts wurde quantitativ untersucht, unter welchen öffentlichen Rahmenbedingungen kurze Erzählformen gegenwärtig (d.h. im Zeitraum 2008-2023) entstehen und welche Effekte sie potenziell auf sie umgebende Umwelten haben können. Hierfür wurde ein umfassendes Datenkorpus mit Informationen zu kurzen Erzählformen, zu den für sie relevanten Publikationssegmenten (Bücher, Literaturzeitschriften, Literaturwettbewerbe, Social-Reading-Plattformen) und den Akteuren, die an ihrer Entstehung, Verbreitung und Rezeption direkt beteiligt sind, erstellt. Die Daten zu kurzen Erzählformen und Literaturzeitschriften, Literaturwettbewerben sowie Social-Reading-Plattformen wurden eigenständig recherchiert und zusammengetragen. Die Daten zu kurzen Erzählformen und Büchern entstammen dem bibliografischen Gesamtbestand der Deutschen Nationalbibliothek. 

Mit den Python-Skripten (und z.T. SQL-Skripten) im Verzeichnis "skripte_aufbau_datenkorpus" wurden die aus dem DNB-Katalog exportierten Rohdaten bereinigt, Informationen zu den relevanten Akteuren (Personen, Körperschaften) aus allen im Datenkorpus vorhandenen Dateien exportiert, konsolidiert und in eigenen Dateien gespeichert. Auch wurden damit die Objekttabellen (literaturzeitschrift, literaturzeitschrift_ausgabe, literaturwettbewerb etc.) und Verknüpfungstabellen (person_rolle_objekt, koerperschaft_rolle_objekt) erstellt. 

Die SQL-Skripte im Verzeichnis "skripte_textkorpus" dienten dem Selektionsprozess bei der Konstitution des Textkorpus. 

# Das Verzeichnis "views" 
Der Unterorder "views_sql" enthält jene SQL-Abfragen, die bei Prüfung der Hypothesen zum Einsatz kamen, wobei die Namen der Skripte, den geprüften Hypothesen entsprechen. 
Im Unterordner "views_csv" finden sich Abzüge der dabei erstellten Views als CSV-Dateien. 

# Das Verzeichnis tm
Darin sind verschiedene Python-Skripte enthalten, die im Zuge der statistisch-probabilistischen Auswertung des Textkorpus mittels Topic Modeling (MALLET) ausgeführt wurden. Zudem finden sich darin einzelne Diagnose- und Ergebnisfiles, ein Codebook und der beim Trainieren des Topics genutzte Befehl als Textdatei. Da das Textkorpus urheberrechtlich relevante Texte enthält, wurde es ebenso wie einzelne sensible Ergebnisdateien vor dem unberechtigten Zugriff durch Dritte im Forschungsinformationssystem der Friedrich-Alexander-Universität Erlangen-Nürnberg (CRIS) hinterlegt. Siehe hierzu: Würz, Maximilian: Text corpus for the Dissertation "Kurzes Erzählen im 21. Jahrhundert. Entstehungsbedingungen und Aneignungspotenziale kurzer Erzählformen in der Gegenwart". 2026. DOI: 10.48742/fau.zpwv-2f87. 

## Kontakt
- Email: [maximilian.wuerz@fau.de](mailto:maximilian.wuerz@fau.de)
