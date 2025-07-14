# Mit diesem Skript wird aus den Rohdaten, die im csv-Format aus dem DNB-Katalog exportiert wurden, die Entitätentabelle "Buch" erzeugt.
# Dabei werden mehrere Bereinigungsschritte vorgenommen und die neue Datei abgespeichert.  
# Gelöschte Zeilen werden zur Nachvollziehbarkeit in den csv-Dateien "bereinigte_schritt_i.csv" (i=Ziffer des jeweiligen Berenigungsschritts) gespeichert. 

import pandas as pd
import re 
# Einlesen der Originaldatei aus dem DNB-Katalog
df = pd.read_csv(
    r"C:\Pfad\zur\exportierten\Rohdatei\Gesamt-Buch.csv",
    sep=';', encoding='utf-8')

gesamt_af = len(df)
print(f"Originale Zeilenanzahl: {gesamt_af}")

# Neues Verzeichnis für die gelöschten Zeilen
entfernte_buch_verzeichnis = r'C:\Pfad\zu\neuem\Verzeichnis\Entfernte_Buch'

# Funktion zur Berechnung und Protokollierung der Zeilenänderungen
def bereinigen(df, bedingung, name):
    vorher = len(df)
    dazwischen = df[~bedingung]
    df = df[bedingung]
    nachher = len(df)
    print(f"{name}: {vorher - nachher} Zeilen gelöscht.")
    dazwischen.to_csv(f"{entfernte_buch_verzeichnis}/bereinigte_{name}.csv", index=False, encoding='utf-8', sep=';')
    return df

# Schritt 1: Nur bestimmte subjects behalten
df = bereinigen(df, df["subject"] == "830 Deutsche Literatur ; B Belletristik", "schritt_1")

# Schritt 2: Zeilen mit Einträgen in "volume" löschen
df = bereinigen(df, df["volume"].isna(), "schritt_2")

# Schritt 3: Nicht benötigte Spalten löschen
spalten_loeschen = ["subject", "type", "identifier", "volume", "ISSN", "ISMN", "EAN/UPC", "description", "rights",
                    "subject headings", "frequency", "wv number"]
df.drop(columns=[s for s in spalten_loeschen if s in df.columns], inplace=True)

# Schritt 4a: Komplette Duplikate löschen
df = bereinigen(df, ~df.duplicated(), "schritt_4a")

# Schritt 4b: Duplikate in der ISBN-Spalte löschen
if "ISBN" in df.columns:
    df = bereinigen(df, ~df.duplicated(subset=["ISBN"]), "schritt_4b")

# Schritt 4c: Duplikate basierend auf title und year löschen
if "title" in df.columns and "year" in df.columns:
    df = bereinigen(df, ~df.duplicated(subset=["title", "year"]), "schritt_4c")

# Schritt 4d: Duplikate basierend auf title und edition löschen
if "title" in df.columns and "edition" in df.columns:
    df = bereinigen(df, ~df.duplicated(subset=["title", "edition"]), "schritt_4d")

# Schritt 5: Zeilen ohne "creator"-Einträge löschen
if "creator" in df.columns:
    df = bereinigen(df, df["creator"].notna() & (df["creator"].str.strip() != ""), "schritt_5")

# Schritt 6: Nur Zeilen mit dem language-Eintrag "ger" behalten
if "language" in df.columns:
    df = bereinigen(df, df["language"] == "ger", "schritt_6")

# Schritt 7: Zeilen mit mehreren Doppelpunkten in der "publisher"-Spalte löschen
if "publisher" in df.columns:
    df = bereinigen(df, df["publisher"].str.count(":") <= 1, "schritt_7")

# Schritt 8: Eckige Klammern aus der "publisher"-Spalte entfernen
if "publisher" in df.columns:
    df["publisher"] = df["publisher"].str.replace(r"[\[\]]", "", regex=True)

# Schritt 9: Publikationsort aus der "publisher"-Spalte extrahieren
if "publisher" in df.columns:
    df["publikationsort"] = df["publisher"].apply(lambda x: x.split(":", 1)[0].strip() if ":" in x else None)
    df["publisher"] = df["publisher"].apply(lambda x: x.split(":", 1)[1].strip() if ":" in x else x)

# Schritt 10: Spalte "creator" nach Semikolons in mehrere Spalten aufteilen
if "creator" in df.columns:
    # maxsplit: Maximale Anzahl der Trennvorgänge für einen Splitt
    creator_split = df['creator'].str.split(';', expand=True)
    # Erstellen neuer Spaltennamen basierend auf der maximalen Anzahl von Split-Spalten
    creator_col_names = [f"creator{i+1}" for i in range(creator_split.shape[1])]
    creator_split.columns = creator_col_names
    # Kombinieren der neuen 'creator' Spalten mit dem Original
    df = pd.concat([df, creator_split], axis=1)

# Schritt 11: Verteilung auf Verfasser-, Herausgeber-, Sonstige-, Übersetzer- und keineRolle-Spalten
def verteileaufrollen(df):
    df['Verfasser'] = ''
    df['Herausgeber'] = ''
    df['Sonstige'] = ''
    df['Übersetzer'] = ''
    df['keineRolle'] = ''
    
    sonstige_rollen = [
        "Fotograf", "Einbandgestalter", "Illustrator", 
        "Verfasser eines Vorworts", "Verfasser eines Geleitworts", "Verfasser einer Einleitung", "Produzent",
        "Verfasser eines Nachworts", "Verfasser von ergänzendem Text", "Kommentarverfasser", "Kommentator", "Herausgebendes Organ",
        "Mitwirkender", "Sonstige", "Geistiger Schöpfer", "Designer", "Erzähler", "Gefeierter", "Komponist",
        "Drehbuchautor", "Künstler", "Buchgestalter", "Zusammenstellender"
    ]
    
    for col in creator_col_names:
        df['Verfasser'] += df[col].apply(lambda x: f"{x.strip()}; " if pd.notna(x) and "Verfasser" in x and not any(phrase in x for phrase in ["Vorwort", "Nachwort", "Geleitswort", "Kommentar", "Einleitung", "Text"]) else "")
        df['Herausgeber'] += df[col].apply(lambda x: f"{x.strip()}; " if pd.notna(x) and "Herausgeber" in x else "")
        df['Übersetzer'] += df[col].apply(lambda x: f"{x.strip()}; " if pd.notna(x) and "Übersetzer" in x else "")
        df['Sonstige'] += df[col].apply(lambda x: f"{x.strip()}; " if pd.notna(x) and any(role in x for role in sonstige_rollen) else "")
        df['keineRolle'] += df[col].apply(lambda x: f"{x.strip()}; " if pd.notna(x) and not (any(role in x for role in sonstige_rollen) or "Verfasser" in x or "Herausgeber" in x or "Übersetzer" in x) else "")
    
    
# Entferne das letzte "; " am Ende jeder Zeile

    df['Verfasser'] = df['Verfasser'].str.rstrip("; ")
    df['Herausgeber'] = df['Herausgeber'].str.rstrip("; ")
    df['Sonstige'] = df['Sonstige'].str.rstrip("; ")
    df['Übersetzer'] = df['Übersetzer'].str.rstrip("; ")
    df['keineRolle'] = df['keineRolle'].str.rstrip("; ")

verteileaufrollen(df)


# Schritt 12: Überflüssige creator-Spalten löschen
df.drop(columns=creator_col_names, inplace=True)


# Schritt 13: Bereinigung der Rollenspalten
def bereinige_rollen_inhalte(content):
    zu_entfernende_woerter = [
        "Verfasser eines Vorworts", "Verfasser eines Geleitworts", "Verfasser eines Nachworts", "Verfasser von ergänzendem Text",
        "Verfasser einer Einleitung", "Kommentarverfasser",
        "Verfasser", "Herausgeber", "Sonstige", "Übersetzer", "Fotograf", "Geistiger Schöpfer", "Designer", "Erzähler",
        "Gefeierter", "Komponist", "Drehbuchautor", "Einbandgestalter", "Illustrator", "Mitwirkender", 
        "Künstler", "Buchgestalter", "Zusammenstellender"
    ]
    
    # Erstellen eines regulären Ausdrucks, um alle unerwünschten Wörter und eckige Klammern zu entfernen.
    muster = r'\b(?:' + '|'.join(re.escape(w) for w in zu_entfernende_woerter) + r')\b|\[|\]'
    
    # Entfernen der unerwünschten Wörter und Klammern
    if pd.notna(content):
        bereinigt = re.sub(muster, '', content)
        bereinigt = re.sub(r'\s+;', ';', bereinigt)  # Entferne Leerzeichen vor Semikolons
        bereinigt = re.sub(r'\s{2,}', ' ', bereinigt)  # Ersetze doppelte Leerzeichen durch ein einzelnes
        return bereinigt.strip()
    return content

# Anwenden der Bereinigungsfunktion auf alle relevanten Rollenspalten
rolle_spalten = ['Verfasser', 'Herausgeber', 'Sonstige', 'Übersetzer', 'keineRolle']

for spalte in rolle_spalten:
    df[spalte] = df[spalte].apply(bereinige_rollen_inhalte)

# Weitere Anpassung des Buchtitels
def bereinige_buchtitel(titel):
    if pd.notna(titel):
        bereinigt = re.sub(r'\s{2,}', ' ', titel)  # Ersetze doppelte Leerzeichen durch ein einzelnes.
        bereinigt = re.sub(r'\s+:', ':', bereinigt)  # Entferne Leerzeichen vor Doppelpunkten.
        return bereinigt.strip()
    return titel

df['title'] = df['title'].apply(bereinige_buchtitel)

# Schritt 14: Entfernen von Bindestrichen in der ISBN-Spalte
if "ISBN" in df.columns:
    df['ISBN'] = df['ISBN'].str.replace('-', '', regex=False)

# Schritt 15: Extraktion der Seitenzahl aus der "format"-Spalte
def extrahierte_seitennummern(fmt):
    if isinstance(fmt, str):  # Prüfen, ob der Wert eine Zeichenfolge ist
        match = re.match(r"^(\d{1,4})", fmt)
        return int(match.group(1)) if match else 0
    return 0

df['Seitenzahl'] = df['format'].apply(extrahierte_seitennummern)


'''# Optionaler Schritt 16: Neue Spalte "Übersetzung" erstellen

df['Übersetzung'] = False

# Prüfung auf Übersetzung

muster = ["Übersetz", "übersetz", "aus dem Engl", "aus dem Amer", "aus dem Russ", 
          "aus dem Span", "aus dem Franz", "aus dem Ital", "aus dem Jap", "aus dem Chin"]

def check_übersetzung(row):
    
# Überprüfen des Titels auf bekannte Übersetzungszeichenfolgen

    if any(ms.lower() in row['title'].lower() for ms in muster):
        return True
    
# Überprüfen, ob die Spalte Übersetzer befüllt ist

    if pd.notna(row['Übersetzer']) and row['Übersetzer'].strip() != "":
        return True
    return False

df['Übersetzung'] = df.apply(check_übersetzung, axis=1)


# Optionaler Schritt 17: Neue Spalte "ThemaGenre" erstellen
df['ThemaGenre'] = False

# Prüfung auf Thema/Genre
muster_thema_genre = ["Weihnacht", "Ostern", "Österlich", "Erotik", "Erotisch", "BDSM", "Sex", "prickelnde", "Krimi", 
                      "Thriller", "Horror", "Liebesgeschicht", "Romance", "Fantasy", "phantastisch", "fantastisch", "Geschichten von der Liebe", 
                      "Tierisch", "Rätsel", "Wandkalender"]

def check_thema_genre(row):

# Überprüfen des Titels auf genre-spezifische Zeichenfolgen
    if any(ms.lower() in row['title'].lower() for ms in muster_thema_genre):
        return True
    return False

df['ThemaGenre'] = df.apply(check_thema_genre, axis=1)'''

# Schritt 18: Nicht mehr benötigte Spalten löschen
spalten_loeschen = [
    "creator", "format", "binding/price", "language", "country", 
    "date of publication", "collective title", "links", "relation", 
    "connected titles", "uniform title"
]
df.drop(columns=[s for s in spalten_loeschen if s in df.columns], inplace=True)

# Schritt 19: Umbenennen von Spalten entsprechend der Datenbankanforderungen
umbenennungen = {
    "title": "buchtitel",
    "edition": "auflage",
    "publisher": "buchverlag",
    "year": "publikationsjahr",
    "ISBN": "isbn",
    "Verfasser": "verfasser",
    "Herausgeber": "herausgeber",
    "Übersetzer": "uebersetzer",
    "keineRolle": "keinerolle",
    "Sonstige":"sonstige",
    "Seitenzahl":"seitenzahl"
}

df.rename(columns=umbenennungen, inplace=True)

# Schritt 20: Spaltenreihenfolge anpassen entsprechend der Datenbankanforderungen
neue_spaltenreihenfolge = [
    'isbn', 'buchtitel', 'auflage', 'publikationsort', 'buchverlag', 
    'publikationsjahr', 'seitenzahl', 'verfasser', 'herausgeber', 
    'uebersetzer', 'keinerolle', 'sonstige'
]

df = df.reindex(columns=neue_spaltenreihenfolge)

final_af = len(df)
print(f"Ende: {final_af} Zeilen")

# Speichern der bereinigten Daten
df.to_csv(r'C:\Pfad\zum\Zielverzeichnis\2008-2023_Buch.csv',
          index=False, encoding='utf-8', sep=';')

print("✅ Datei erfolgreich gespeichert.")