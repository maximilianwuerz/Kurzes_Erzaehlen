import pandas as pd

# Schritt 1: Struktur der leeren Entitätentabelle "Koerperschaft" anlegen
koerperschaft_df = pd.DataFrame(columns=['koerperschaft_id', 'koerperschaft_name'])

# Ausgabe zur Überprüfung, dass die Struktur korrekt erstellt wurde
print(koerperschaft_df.head())

# 2. Schritt: Einlesen der aktuellen Buch-CSV
buch_df = pd.read_csv(
    r'C:\Pfad\zur\2008-2023_Buch.csv',
    sep=';', encoding='utf-8'
)

# 3. Schritt: Einlesen der aktuellen Literaturwettbewerb.csv
literaturwettbewerb_df = pd.read_csv(
    r'C:\Pfad\zur\Literaturwettbewerb.csv',
    sep=';', encoding='utf-8'
)

# 4. Schritt: Einlesen der Literaturzeitschrift.csv
literaturzeitschrift_df = pd.read_csv(
    r'C:\Pfad\zur\Literaturzeitschrift.csv',
    sep=';', encoding='utf-8'
)

# 5. Schritt: Einlesen der Plattform_Internet.csv
plattform_internet_df = pd.read_csv(
    r'C:\Pfad\zur\Plattform_Internet.csv',
    sep=';', encoding='utf-8'
)

# 6. Schritt: Extrahieren und Bereinigen von Koerperschaftsdaten
koerperschaft_set = set()  # Nutzung einer Menge, um Duplikate zu vermeiden

# Extrahieren von Verlagsnamen aus der Buch-CSV
for eintrag in buch_df['buchverlag'].dropna():
    koerperschaften = [name.strip() for name in eintrag.split(';') if name.strip()]  # Leere Namen ignorieren
    koerperschaft_set.update(koerperschaften)

# Extrahieren von Veranstaltern aus der Literaturwettbewerb-CSV
for eintrag in literaturwettbewerb_df['veranstalter'].dropna():
    koerperschaften = [name.strip() for name in eintrag.split(';') if name.strip()]  # Leere Namen ignorieren
    koerperschaft_set.update(koerperschaften)

# Extrahieren von Zeitschriftenverlagen aus der Literaturzeitschrift-CSV
for eintrag in literaturzeitschrift_df['zeitschriftverlegtvon'].dropna():
    koerperschaften = [name.strip() for name in eintrag.split(';') if name.strip()]  # Leere Namen ignorieren
    koerperschaft_set.update(koerperschaften)

# Extrahieren von Unternehmen aus der Plattform_Internet-CSV
for eintrag in plattform_internet_df['unternehmen'].dropna():
    koerperschaften = [name.strip() for name in eintrag.split(';') if name.strip()]  # Leere Namen ignorieren
    koerperschaft_set.update(koerperschaften)

# 7. Schritt: Füllen des Koerperschaft-Datensatzes
koerperschaft_records = []
sorted_koerperschaften = sorted(list(koerperschaft_set))  # Alphabetisch sortieren
koerperschaft_id = 1  # Initialisieren der koerperschaft_id
for name in sorted_koerperschaften:
    koerperschaft_records.append({
        'koerperschaft_id': koerperschaft_id,
        'koerperschaft_name': name
    })
    koerperschaft_id += 1

koerperschaft_df = pd.DataFrame.from_records(koerperschaft_records, columns=['koerperschaft_id', 'koerperschaft_name'])

# 8. Schritt: Speichern der Koerperschaftsdaten in eine CSV-Datei
koerperschaft_df.to_csv(
    r'C:\Pfad\zur\Koerperschaft.csv',
    index=False, encoding='utf-8', sep=';'
)

print("✅ Datei erfolgreich gespeichert.")