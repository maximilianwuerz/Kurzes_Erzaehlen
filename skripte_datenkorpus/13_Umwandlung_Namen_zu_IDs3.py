# Skript zur Umwandlung der Inhalte in den Entitätentabellen 
# von person_name und koerperschaft_name zu person_id und koerperschaft_id 


import pandas as pd
from sqlalchemy import create_engine

# Verbindung zur PostgreSQL-Datenbank
engine = create_engine('DB-Verbindungsinformationen')

# Abfrage der 'Person'- und 'Koerperschaft'-Tabellen
person_df = pd.read_sql_table('person', engine)
koerperschaft_df = pd.read_sql_table('koerperschaft', engine)

# Debug-Ausgaben zur Diagnose (optional, bei Bedarf)
print(person_df.head(30))  # Zeigt die ersten 30 Zeilen zur Fehlersuche an
print(person_df.isnull().sum())  # Überprüft auf fehlende Daten in den Spalten

# Daten auf Zeilen reduzieren, die validierte 'person_name' haben
valid_person_df = person_df.dropna(subset=['person_name'])

# Mapping von Namen zu IDs
person_mapping = valid_person_df.set_index('person_name')['person_id'].to_dict()
koerperschaft_mapping = koerperschaft_df.set_index('koerperschaft_name')['koerperschaft_id'].to_dict()

# CSV-Datei Buch einlesen
buch_df = pd.read_csv(r'PfadzurDatei\2008-2023_Buch_kk_pk_neu.csv', sep=';', encoding='utf-8', dtype={'isbn': 'string'})
literaturzeitschrift_df = pd.read_csv(r'PfadzurDatei\Literaturzeitschrift_kk_pk_id.csv', sep=';', encoding='utf-8')
literaturzeitschrift_ausgabe_df = pd.read_csv(r'PfadzurDatei\Literaturzeitschrift_Ausgabe_kk_pk_id.csv', sep=';', encoding='utf-8')
literaturwettbewerb_df = pd.read_csv(r'PfadzurDatei\Literaturwettbewerb_kk_pk_id.csv', sep=';', encoding='utf-8')
literaturwettbewerb_ausgabe_df = pd.read_csv(r'PfadzurDatei\Literaturwettbewerb_Ausgabe_kk_pk_id.csv', sep=';', encoding='utf-8')
plattform_internet_df = pd.read_csv(r'PfadzurDatei\Plattform_Internet_kk_pk_id.csv', sep=';', encoding='utf-8', dtype={'gründungsjahr': 'Int64', 'anzahl_mitglieder': 'string'})


# Funktion um Namen durch IDs zu ersetzen
def map_names_to_ids(name_string, mapping):
    if pd.isna(name_string):
        return ''
    names = [name.strip() for name in name_string.split(';') if name]
    ids = [str(mapping.get(name, None)) for name in names if mapping.get(name, None) is not None]
    return '; '.join(ids)

# Mapping Funktionen kombinieren
def map_combine(name_string, person_mapping, koerperschaft_mapping):
    person_ids = map_names_to_ids(name_string, person_mapping)
    koerperschaft_ids = map_names_to_ids(name_string, koerperschaft_mapping)
    return '; '.join(filter(None, [person_ids, koerperschaft_ids]))

# Ersetze die Namensspalten durch die ID-Spalten und benenne um
buch_df['buchverlegtvon'] = buch_df['buchverlegtvon'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
buch_df['verfasser'] = buch_df['verfasser'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
buch_df['herausgeber'] = buch_df['herausgeber'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
buch_df['uebersetzer'] = buch_df['uebersetzer'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
buch_df['keinerolle'] = buch_df['keinerolle'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
buch_df['sonstige'] = buch_df['sonstige'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturzeitschrift_df['literaturzeitschriftverlegtvon'] = literaturzeitschrift_df['literaturzeitschriftverlegtvon'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturzeitschrift_df['literaturzeitschrift_creator'] = literaturzeitschrift_df['literaturzeitschrift_creator'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturzeitschrift_ausgabe_df['verfasser_ke_beiträge'] = literaturzeitschrift_ausgabe_df['verfasser_ke_beiträge'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturwettbewerb_df['veranstalter'] = literaturwettbewerb_df['veranstalter'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturwettbewerb_df['jury_2023'] = literaturwettbewerb_df['jury_2023'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturwettbewerb_ausgabe_df['gewinner'] = literaturwettbewerb_ausgabe_df['gewinner'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
literaturwettbewerb_ausgabe_df['jury'] = literaturwettbewerb_ausgabe_df['jury'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))
plattform_internet_df['unternehmen'] = plattform_internet_df['unternehmen'].apply(lambda x: map_combine(x, person_mapping, koerperschaft_mapping))



# Gespeicherte, umstrukturierte CSV ausgeben
buch_df.to_csv(r'PfadzurDatei\2008-2023_Buch_kk_pk_id3.csv', sep=';', index=False, encoding='utf-8')
literaturzeitschrift_df.to_csv(r'PfadzurDatei\Literaturzeitschrift_kk_pk_id3.csv', sep=';', index=False, encoding='utf-8')
literaturzeitschrift_ausgabe_df.to_csv(r'PfadzurDatei\Literaturzeitschrift_Ausgabe_kk_pk_id3.csv', sep=';', index=False, encoding='utf-8')
literaturwettbewerb_df.to_csv(r'PfadzurDatei\Literaturwettbewerb_kk_pk_id3.csv', sep=';', index=False, encoding='utf-8')
literaturwettbewerb_ausgabe_df.to_csv(r'PfadzurDatei\Literaturwettbewerb_Ausgabe_kk_pk_id3.csv', sep=';', index=False, encoding='utf-8')
plattform_internet_df.to_csv(r'PfadzurDatei\Plattform_Internet_kk_pk_id3.csv', sep=';', index=False, encoding='utf-8')


print("✅ CSV-Datei erfolgreich angepasst.")