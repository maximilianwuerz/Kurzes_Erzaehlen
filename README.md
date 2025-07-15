# Dies ist das Repository des Dissertationsprojekts "Kurzes Erzählen im 21. Jahrhundert - Entstehungsbedingungen und Aneignungspotenziale kurzer Erzählformen in der Gegenwart" 

# Worum geht es? 
Im Zuge des Projekts wurde quantitativ untersucht, unter welchen öffentlichen Rahmenbedingungen kurze Erzählformen gegenwärtig (d.h. im Zeitraum 2008-2023) entstehen und welche Effekte sie potentiell auf die sie umgebenden Umwelten haben können. Hierfür wurde ein umfassendes Datenkorpus mit Informationen zu kurzen Erzählformen, zu den für sie relevanten Publikationssegmenten (Bücher, Literaturzeitschriften, Literaturwettbewerbe, Social-Reading-Plattformen) und den Akteuren, die an ihrer Entstehung, Verbreitung und Rezeption direkt beteiligt sind, erstellt. Die Daten zu kurzen Erzählformen und Literaturzeitschriften, Literaturwettbewerben sowie Social-Reading-Plattformen wurden eigenständig recherchiert und zusammengetragen. Die Daten zu kurzen Erzählformen und Büchern entstammen dem Katalog der Deutschen Nationalbibliothek. 

Mit den unter "skripte_datenkorpus" versammelten Python-Skripten (und z.T. SQL-Skripten) wurden die aus dem DNB-Katalog exportierten Rohdaten bereinigt, Informationen zu den relevanten Akteuren (Personen, Körperschaften) aus allen im Datenkorpus vorhandenen Dateien exportiert, konsolidiert und in eigenen Dateien gespeichert. Auch wurden damit die Objekttabellen (literaturzeitschrift, literaturzeitschrift_ausgabe, literaturwettbewerb etc.) und Verknüpfungstabellen (person_rolle_objekt, koerperschaft_rolle_objekt) erstellt. Zur Erhöhung der Funktionalität wurden Funktionen und Trigger erstellt. Diese sind in der RDB aktuell deaktiviert. 

# Die Skripte zur Erstellung des Datenkorpus
- **Skript 1:** Details zum Skript.
- **Skript 2:** Details zum Skript.
- **Skript 3:** Details zum Skript.
- **Skript 4:** Details zum Skript.
- **Skript 5:** Details zum Skript.
- **Skript 6:** Details zum Skript.
- **Skript 7:** Details zum Skript.
- **Skript 8:** Details zum Skript.
- **Skript 9:** Details zum Skript.
- **Skript 10:** Details zum Skript.
- **Skript 11:** Details zum Skript.
- **Skript 12:** Details zum Skript.
- **Skript 13:** Details zum Skript.
- **Skript 14:** Details zum Skript.
- **Skript 15:** Details zum Skript.
- **Skript 16:** Details zum Skript.

Die SQL-Skripte im Verzeichnis "skripte_textkorpus" dienten dem Selektionsprozess bei der Konstitution des Textkorpus. 

# Die Skripte zur Erstellung des Textkorpus
- **Skript 17:** Details zum Skript.
- **Skript 18:** Details zum Skript.
- **Skript 19:** Details zum Skript.
- **Skript 20:** Details zum Skript.

# Das Verzeichnis "views" 
Der Unterorder "views_sql" enthält jene SQL-Abfragen, die bei Prüfung der Hypothesen zum Einsatz kamen, wobei die Namen der Skripte, den geprüften Hypothesen entsprechen. 
Im Unterordner "views_csv" finden sich Abzüge der so erstellten Views als CSV-Dateien. 

## Kontakt
- Email: [maximilian.wuerz@fau.de](mailto:maximilian.wuerz@fau.de)
