# Dies ist das Repository des Dissertationsprojekts "Kurzes Erzählen im 21. Jahrhundert - Entstehungsbedingungen und Aneignungspotenziale kurzer Erzählformen in der Gegenwart" 

# Worum geht es? 
Im Zuge des Projekts wurde quantitativ untersucht, unter welchen öffentlichen Rahmenbedingungen kurze Erzählformen gegenwärtig (d.h. im Zeitraum 2008-2023) entstehen und welche Effekte sie potenziell auf sie umgebende Umwelten haben können. Hierfür wurde ein umfassendes Datenkorpus mit Informationen zu kurzen Erzählformen, zu den für sie relevanten Publikationssegmenten (Bücher, Literaturzeitschriften, Literaturwettbewerbe, Social-Reading-Plattformen) und den Akteuren, die an ihrer Entstehung, Verbreitung und Rezeption direkt beteiligt sind, erstellt. Die Daten zu kurzen Erzählformen und Literaturzeitschriften, Literaturwettbewerben sowie Social-Reading-Plattformen wurden eigenständig recherchiert und zusammengetragen. Die Daten zu kurzen Erzählformen und Büchern entstammen dem bibliografischen Gesamtbestand der Deutschen Nationalbibliothek. 

Mit den unter "skripte_aufbau_datenkorpus" versammelten Python-Skripten (und z.T. SQL-Skripten) wurden die aus dem DNB-Katalog exportierten Rohdaten bereinigt, Informationen zu den relevanten Akteuren (Personen, Körperschaften) aus allen im Datenkorpus vorhandenen Dateien exportiert, konsolidiert und in eigenen Dateien gespeichert. Auch wurden damit die Objekttabellen (literaturzeitschrift, literaturzeitschrift_ausgabe, literaturwettbewerb etc.) und Verknüpfungstabellen (person_rolle_objekt, koerperschaft_rolle_objekt) erstellt. 

Die SQL-Skripte im Verzeichnis "skripte_textkorpus" dienten dem Selektionsprozess bei der Konstitution des Textkorpus. 

# Das Verzeichnis "views" 
Der Unterorder "views_sql" enthält jene SQL-Abfragen, die bei Prüfung der Hypothesen zum Einsatz kamen, wobei die Namen der Skripte, den geprüften Hypothesen entsprechen. 
Im Unterordner "views_csv" finden sich Abzüge der dabei erstellten Views als CSV-Dateien. 

## Kontakt
- Email: [maximilian.wuerz@fau.de](mailto:maximilian.wuerz@fau.de)
