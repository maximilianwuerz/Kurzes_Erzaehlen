import pandas as pd
import re
import unicodedata

# Pfad zur Eingabedatei
input_file = r"Pfadzu\DNB_KE_2008_2023.csv"

# Output-Pfade (anpassen!)
output_file_clean = r"Pfadzu\DNB_KE_2008_2023_bereinigt.csv"
output_file_duplikate = r"Pfadzu\Entfernte_Buch\Entfernte_Duplikate.csv"
output_file_ohne_isbn = r"Pfadzu\Entfernte_Buch\Entfernte_ohne_ISBN.csv"
output_file_isbn_duplikat = r"Pfadzu\Entfernte_Buch\Entfernte_ISBN_Duplikate.csv"
output_file_falsche_origsprache = r"Pfadzu\Entfernte_Buch\Entfernte_Originalsprache.csv"
output_file_ohne_creator = r"Pfadzu\Entfernte_Buch\Entfernte_ohne_Creator.csv"
output_file_falsche_gattung = r"Pfadzu\Entfernte_Buch\Entfernte_falsche_Gattung.csv"

# CSV einlesen (alles als String)
df = pd.read_csv(input_file, delimiter=',', dtype=str)

# -------- Unicode-Normalisierung & Entfernen unsichtbarer Zeichen --------

ZERO_WIDTHS = {
    "\u200B",  # ZERO WIDTH SPACE
    "\u200C",  # ZERO WIDTH NON-JOINER
    "\u200D",  # ZERO WIDTH JOINER
    "\u2060",  # WORD JOINER
    "\uFEFF",  # ZERO WIDTH NO-BREAK SPACE (BOM)
}

def normalize_nfc(s: str) -> str:
    """Normalisiert auf Unicode NFC und entfernt Zero-Width/BOM."""
    if not isinstance(s, str):
        return s
    for zw in ZERO_WIDTHS:
        s = s.replace(zw, "")
    return unicodedata.normalize("NFC", s)

def remove_control_chars(s: str) -> str:
    """Entfernt Steuer-/Kontrollzeichen (Unicode-Kategorie 'C'), lässt Umlaute/Diakritika intakt."""
    if not isinstance(s, str):
        return s
    keep = {'\t', '\n', '\r'}
    return "".join(ch for ch in s if unicodedata.category(ch)[0] != 'C' or ch in keep)

# Auf alle Textspalten anwenden (erst NFC, dann Steuerzeichen entfernen)
for col in df.columns:
    df[col] = df[col].map(normalize_nfc)
    df[col] = df[col].map(remove_control_chars)

# Funktion zur Entfernung von eckigen Klammern
def remove_brackets(s):
    if pd.isna(s):
        return s
    return s.replace('[', '').replace(']', '')

# Formale Bereinigungen: Entfernen von eckigen Klammern
for column in ['Publikationsort', 'Publisher', 'Auflage']:
    if column in df.columns:
        df[column] = df[column].apply(remove_brackets)

# Funktion, um die erste Ziffernfolge aus einem String zu extrahieren
def extract_first_digits(s):
    if pd.isna(s):
        return s
    match = re.search(r'\d+', s)
    if match:
        return match.group(0)
    return ""

# Bereinigung der "Seitenzahl"
if 'Seitenzahl' in df.columns:
    df['Seitenzahl'] = df['Seitenzahl'].apply(extract_first_digits)

# Funktion, um nur das vierstellige Jahr zu extrahieren
def extract_year(s):
    if pd.isna(s):
        return s
    s = s.replace('[', '').replace(']', '').replace('(', '').replace(')', '')
    match = re.search(r'(17|18|19|20)\d{2}', s)
    if match:
        return match.group(0)
    return s

# Bereinigung des "Publikationsjahr"
if 'Publikationsjahr' in df.columns:
    df['Publikationsjahr'] = df['Publikationsjahr'].apply(extract_year)

# Inhaltliche Bereinigung: Entfernen von Duplikaten
duplicates = df[df.duplicated(keep=False)]
df_cleaned = df.drop_duplicates()
duplicates.to_csv(output_file_duplikate, index=False, sep=',')

# Informationen nach dem Entfernen von Duplikaten
print(f'Ursprüngliche Anzahl an Datensätzen: {len(df)}')
print(f'Anzahl der Duplikatdatensätze in der Datei {output_file_duplikate}: {len(duplicates)}')
print(f'Anzahl der Datensätze nach Entfernung von Duplikaten: {len(df_cleaned)}\n')

# Bereinigung: Entfernen von Datensätzen ohne ISBN
if 'ISBN' in df_cleaned.columns:
    ohne_isbn = df_cleaned[df_cleaned['ISBN'].isna() | (df_cleaned['ISBN'].str.strip() == "")]
    df_cleaned = df_cleaned.drop(ohne_isbn.index)
    ohne_isbn.to_csv(output_file_ohne_isbn, index=False, sep=',')

# Informationen nach dem Entfernen von Datensätzen ohne ISBN
print(f'Anzahl der Datensätze ohne ISBN: {len(ohne_isbn)}')
print(f'Anzahl der Datensätze in der Datei {output_file_ohne_isbn}: {len(ohne_isbn)}')
print(f'Anzahl der Datensätze nach Entfernung von Datensätzen ohne ISBN: {len(df_cleaned)}\n')

# Bereinigung: Entfernen von doppelten ISBNs
if 'ISBN' in df_cleaned.columns:
    isbn_duplikate = df_cleaned[df_cleaned.duplicated(subset=['ISBN'], keep=False)]
    df_cleaned_after_isbn = df_cleaned.drop_duplicates(subset=['ISBN'])
    isbn_duplikate.to_csv(output_file_isbn_duplikat, index=False, sep=',')
    print(f'Anzahl der ISBN-Duplikatdatensätze in der Datei {output_file_isbn_duplikat}: {len(isbn_duplikate)}')
    print(f'Anzahl der entfernten ISBN-Duplikate: {len(df_cleaned) - len(df_cleaned_after_isbn)}')
    print(f'Anzahl der Datensätze nach Entfernung von doppelten ISBNs: {len(df_cleaned_after_isbn)}\n')
else:
    df_cleaned_after_isbn = df_cleaned.copy()

# Bereinigung: Entfernen von Datensätzen mit falscher Originalsprache
if 'SpracheOriginal' in df_cleaned_after_isbn.columns:
    falsche_origsprache = df_cleaned_after_isbn[
        ~(df_cleaned_after_isbn['SpracheOriginal'].isna() | df_cleaned_after_isbn['SpracheOriginal'].eq('ger'))
    ]
    df_cleaned_final = df_cleaned_after_isbn.drop(falsche_origsprache.index)
    falsche_origsprache.to_csv(output_file_falsche_origsprache, index=False, sep=',')

# Informationen nach dem Entfernen von Datensätzen mit falscher Originalsprache
    print(f'Anzahl der Datensätze mit falscher Originalsprache: {len(falsche_origsprache)}')
    print(f'Anzahl der Datensätze in der Datei {output_file_falsche_origsprache}: {len(falsche_origsprache)}')
    print(f'Anzahl der Datensätze nach Entfernung von falscher Originalsprache: {len(df_cleaned_final)}\n')
else:
    df_cleaned_final = df_cleaned_after_isbn.copy()

# Bereinigung: Entfernen von Datensätzen ohne Creator
rollenfelder = [c for c in ['Verfasser', 'Herausgeber', 'Übersetzer', 'keineRolle', 'sonstigeRolle'] if c in df_cleaned_final.columns]
if rollenfelder:
    ohne_creator = df_cleaned_final[df_cleaned_final[rollenfelder].isna().all(axis=1)]
    df_cleaned_final = df_cleaned_final.drop(ohne_creator.index)
    ohne_creator.to_csv(output_file_ohne_creator, index=False, sep=',')
    print(f'Anzahl der Datensätze ohne Creator: {len(ohne_creator)}')
    print(f'Anzahl der Datensätze in der Datei {output_file_ohne_creator}: {len(ohne_creator)}')
    print(f'Abschließende Anzahl der Datensätze nach Entfernung von Datensätzen ohne Creator: {len(df_cleaned_final)}\n')

# Bereinigung: Entfernen von falschen Gattung_Genre-Einträgen
if 'Gattung_Genre' in df_cleaned_final.columns:
    mask_falsche_gattung = (
    # Lyrik: Entfernt Einträge, die "Lyrik" enthalten, aber nicht "gemischt" oder irgendeine Form von "erzählender Literatur"
        (df_cleaned_final['Gattung_Genre'].str.contains('Lyrik', na=False) &
         ~(df_cleaned_final['Gattung_Genre'].str.contains('gemischt', case=False, na=False) |
           df_cleaned_final['Gattung_Genre'].str.contains('lende Lit', case=False, na=False)))
        |
    # Dramatik: Entfernt Einträge, die "Dramatik" enthalten, aber nicht "gemischt" oder irgendeine Form von "erzählender Literatur"
        (df_cleaned_final['Gattung_Genre'].str.contains('Dramatik', na=False) &
         ~(df_cleaned_final['Gattung_Genre'].str.contains('gemischt', case=False, na=False) |
           df_cleaned_final['Gattung_Genre'].str.contains('lende Lit', case=False, na=False)))
        |
    # Hauptwerk vor 1945: Immer entfernen
        df_cleaned_final['Gattung_Genre'].str.contains('Hauptwerk vor 1945', na=False)
        |
    # Romanhafte: Immer entfernen
        df_cleaned_final['Gattung_Genre'].str.contains('Romanhafte', na=False)
        |
    # Kriminalromane: Immer entfernen
        df_cleaned_final['Gattung_Genre'].str.contains('Kriminalromane', na=False)
        |
    # Bildband: Entfernt Einträge, die "Bildband" enthalten, aber nicht irgendeine Form von "erzählender Literatur"
        (df_cleaned_final['Gattung_Genre'].str.contains('Bildband', na=False) &
         ~df_cleaned_final['Gattung_Genre'].str.contains('lende Lit', case=False, na=False))
    )
# Entfernen der Einträge, die als falsche Gattung erkannt wurden
    falsche_gattung = df_cleaned_final[mask_falsche_gattung]
    df_cleaned_final = df_cleaned_final.drop(falsche_gattung.index)
# Speichern der falschen Gattungseinträge in einer separaten CSV
    falsche_gattung.to_csv(output_file_falsche_gattung, index=False, sep=',')
# Überprüfung der Ergebnisse
    print(f'Anzahl der Datensätze mit falscher Gattung: {len(falsche_gattung)}')
    print(f'Anzahl der Datensätze nach Entfernung von falscher Gattung: {len(df_cleaned_final)}')
# Informationen nach dem Entfernen von falschen Gattung_Genre-Einträgen
    print(f'Anzahl der Datensätze in der Datei {output_file_falsche_gattung}: {len(falsche_gattung)}\n')

# Bereinigte CSV speichern
df_cleaned_final.to_csv(output_file_clean, index=False, sep=',')

print(f'Abschließende Anzahl der Datensätze in der bereinigten Datei: {len(df_cleaned_final)}')