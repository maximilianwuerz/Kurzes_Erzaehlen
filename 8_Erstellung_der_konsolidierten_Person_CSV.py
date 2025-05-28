import pandas as pd

# Schritt 1: Struktur der leeren Entitätentabelle "Person" anlegen
personen_df = pd.DataFrame(columns=['person_id', 'person_name', 'person_username', 'gender', 'alter', 'website'])

# Ausgabe zur Überprüfung, dass die Struktur korrekt erstellt wurde
print(personen_df.head())

# 2. Schritt: Einlesen der konsolidierten Buch-CSV
buch_df = pd.read_csv(
    r'C:\Users\ab32ihaq\FAUbox\Dissertation\FAU\Dissertation\Arbeitspakete\4_Feldanalyse\Relationale Datenbank\20250515\20250526\Konsolidierte\2008-2023_Buch_kk_pk.csv',
    sep=';', encoding='utf-8'
)

# 3. Schritt: Einlesen der konsolidierten Literaturwettbewerb_Ausgabe-CSV
wettbewerb_df = pd.read_csv(
    r'C:\Users\ab32ihaq\FAUbox\Dissertation\FAU\Dissertation\Arbeitspakete\4_Feldanalyse\Relationale Datenbank\20250515\20250526\Konsolidierte\Literaturwettbewerb_Ausgabe_kk_pk.csv',
    sep=';', encoding='utf-8'
)

# 4. Schritt: Einlesen der konsolidierten Literaturzeitschrift_Ausgabe-CSV
literaturzeitschrift_df = pd.read_csv(
    r'C:\Users\ab32ihaq\FAUbox\Dissertation\FAU\Dissertation\Arbeitspakete\4_Feldanalyse\Relationale Datenbank\20250515\20250526\Konsolidierte\Literaturzeitschrift_Ausgabe_kk_pk.csv',
    sep=';', encoding='utf-8'
)

# 5. Schritt: Einlesen der konsolidierten Literaturzeitschrift.csv
literaturzeitschrift_main_df = pd.read_csv(
    r'C:\Users\ab32ihaq\FAUbox\Dissertation\FAU\Dissertation\Arbeitspakete\4_Feldanalyse\Relationale Datenbank\20250515\20250526\Konsolidierte\Literaturzeitschrift_kk_pk.csv',
    sep=';', encoding='utf-8'
)

# 6. Schritt: Einlesen der fanfiktion_autorinneninfo.csv
fanfiktion_autorinneninfo_df = pd.read_csv(
    r'C:\Users\ab32ihaq\FAUbox\Dissertation\FAU\Dissertation\Arbeitspakete\4_Feldanalyse\Relationale Datenbank\20250515\20250526\Originaldateien\fanfiktion_autorinneninfo.csv',
    sep=';', encoding='utf-8'
)

# 7. Schritt: Extrahieren und Bereinigen von konsolidierten Personendaten 
personen_dict = {}

# Extrahieren von Personennamen aus der konsolidierten Buch-CSV
rolle_spalten = ['verfasser', 'herausgeber', 'uebersetzer', 'keinerolle', 'sonstige']
for spalte in rolle_spalten:
    for eintraege in buch_df[spalte].dropna():
        person_namen = [name.strip() for name in eintraege.split(';') if name.strip()]
        for name in person_namen:
            if name not in personen_dict:
                personen_dict[name] = {"usernames": set(), "gender": set(), "alter": set(), "website": set()}

# Extrahieren von Personennamen aus der konsolidierten Literaturwettbewerb_Ausgabe-CSV
rolle_spalten_wettbewerb = ['gewinner', 'jury']
for spalte in rolle_spalten_wettbewerb:
    for eintraege in wettbewerb_df[spalte].dropna():
        person_namen = [name.strip() for name in eintraege.split(';') if name.strip()]
        for name in person_namen:
            if name not in personen_dict:
                personen_dict[name] = {"usernames": set(), "gender": set(), "alter": set(), "website": set()}

# Extrahieren von Personennamen aus der konsolidierten Literaturzeitschrift_Ausgabe-CSV
for eintraege in literaturzeitschrift_df['verfasser_ke_beiträge'].dropna():
    person_namen = [name.strip() for name in eintraege.split(';') if name.strip()]
    for name in person_namen:
        if name not in personen_dict:
            personen_dict[name] = {"usernames": set(), "gender": set(), "alter": set(), "website": set()}

# Extrahieren von Personennamen aus der konsolidierten Literaturzeitschrift-CSV
for eintraege in literaturzeitschrift_main_df['creator'].dropna():
    person_namen = [name.strip() for name in eintraege.split(';') if name.strip()]
    for name in person_namen:
        if name not in personen_dict:
            personen_dict[name] = {"usernames": set(), "gender": set(), "alter": set(), "website": set()}

# Extrahieren von Personennamen aus der Fanfiktion_Autorinneninfo-CSV
for index, row in fanfiktion_autorinneninfo_df.iterrows():
    person_username = row['author_username'] if row['author_username'] and row['author_username'] != '0' else ''
    if row['first_name'] and row['last_name'] and row['first_name'] != '0' and row['last_name'] != '0':
        person_name = f"{row['last_name'].strip()}, {row['first_name'].strip()}"
    else:
        person_name = ''
    
    # Schlüssel basierend auf vorhandenem Namen oder Benutzernamen bestimmen
    key = person_name if person_name else f"__{person_username}__"
    
    gender = row['gender'] if row['gender'] and row['gender'] != '0' else ''
    website = row['homepage'] if row['homepage'] and row['homepage'] != '0' else ''
    alter = str(row['age']) if row['age'] and row['age'] != '0' else ''

    if key not in personen_dict:
        personen_dict[key] = {"usernames": set(), "gender": set(), "alter": set(), "website": set()}

    personen_dict[key]["usernames"].add(person_username)
    personen_dict[key]["gender"].add(gender)
    personen_dict[key]["alter"].add(alter)
    personen_dict[key]["website"].add(website)

# 12. Schritt: Füllen des Personendatensatzes
person_records = []
person_id = 1
for key, attributes in personen_dict.items():
    # Den Namen aus dem Schlüssel wiederherstellen
    person_name = key if not key.startswith("__") else ""
    person_username = ';'.join(filter(None, attributes['usernames'])) if person_name else key.strip("__")
    
    person_records.append({
        'person_id': person_id,
        'person_name': person_name,
        'person_username': person_username,
        'gender': ';'.join(filter(None, attributes['gender'])),
        'alter': ';'.join(filter(None, map(str, attributes['alter']))),
        'website': ';'.join(filter(None, attributes['website']))
    })
    person_id += 1

personen_df = pd.DataFrame.from_records(person_records, columns=['person_id', 'person_name', 'person_username', 'gender', 'alter', 'website'])

# 13. Schritt: Speichern der konsolidierten Personendaten in eine CSV-Datei
personen_df.to_csv(
    r'C:\Users\ab32ihaq\FAUbox\Dissertation\FAU\Dissertation\Arbeitspakete\4_Feldanalyse\Relationale Datenbank\20250515\20250526\Konsolidierte\Person_kk_pk.csv',
    index=False, encoding='utf-8', sep=';'
)

print("✅ Datei erfolgreich gespeichert.")