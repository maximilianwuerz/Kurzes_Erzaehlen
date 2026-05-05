import xml.etree.ElementTree as ET
import requests
import csv
import unicodedata

# Basis-URL der SRU-Schnittstelle
base_url = "https://services.dnb.de/sru/dnb?version=1.1&operation=searchRetrieve&query=TIT%3DKurzgeschichte*%20or%20TIT%3DStories%20or%20TIT%3DErz%C3%A4hlungen%20or%20TIT%3DAnekdoten%20or%20TIT%3DSammelband%20or%20TIT%3DAnthologie%20or%20TIT%3DGeschichten%20and%20sgt=B%20and%20spr=ger%20and%20(jhr%3E=2008%20and%20jhr%3C=2023)%20and%20mat=books&recordSchema=MARC21-xml&maximumRecords=100"

# Startnummer für die erste Abfrage
start_record = 1

# Dateiname für die CSV-Ausgabe
filename = r'Pfad\zu\Repository\Outputs\DNB_KE_2008_2023.csv' # Hier den Pfad anpassen! 

# CSV-Header
header = [
    "ISBN", "Buchtitel", "Auflage", "Publikationsort", "Publisher",
    "Publikationsjahr", "Seitenzahl", "Verfasser", "Herausgeber", "Übersetzer",
    "keineRolle", "sonstigeRolle", "Gattung_Genre", "Sprache", "SpracheOriginal"
]

def fetch_records(start_record):
    """Holt den XML-Inhalt für die gegebene Startnummer in SRU-Anfrage."""
    response = requests.get(f"{base_url}&startRecord={start_record}")
    if response.status_code == 200:
        return response.content
    else:
        print(f"Fehler beim Abrufen der Daten: {response.status_code}")
        return None

def normalize_text(text):
    "Normalisiert Text für konsistente Unicode-Verarbeitung."
    return unicodedata.normalize('NFC', text)

def extract_names_by_role(tag, record):
    """Extrahiert Namen und ordnet sie den Rollen zu."""
    roles = {'Verfasser': [], 'Herausgeber': [], 'Übersetzer': [], 'keineRolle': [], 'sonstigeRolle': []}
    for datafield in record.findall(f"{tag}[@tag='100']") + record.findall(f"{tag}[@tag='700']"):
        role_codes = [normalize_text(subfield.text).strip() for subfield in datafield.findall("{http://www.loc.gov/MARC21/slim}subfield[@code='e']")]
        name_field = datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']")
        name = normalize_text(name_field.text).strip() if name_field is not None else ''
        
        if any(role.lower() == 'verfasser' for role in role_codes):
            roles['Verfasser'].append(name)
        if any(role.lower() == 'herausgeber' for role in role_codes):
            roles['Herausgeber'].append(name)
        if any(role.lower() in ['übersetzer', 'uebersetzer'] for role in role_codes):
            roles['Übersetzer'].append(name)
        if not role_codes:
            roles['keineRolle'].append(name)
        if any(role.lower() not in ['verfasser', 'herausgeber', 'übersetzer', 'uebersetzer'] for role in role_codes):
            roles['sonstigeRolle'].append(name)
    return roles

# Erstellen und Schreiben der CSV-Datei
with open(filename, mode='w', newline='', encoding='utf-8') as csv_file:
    writer = csv.writer(csv_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)

    # Schreiben des Headers
    writer.writerow(header)

    try:
        # Ermittle die Gesamtanzahl der verfügbaren Datensätze
        initial_content = fetch_records(start_record)
        root = ET.fromstring(initial_content)
        total_records = int(root.find('.//{http://www.loc.gov/zing/srw/}numberOfRecords').text)
        print(f"Gesamtzahl Datensätze: {total_records}")

        while start_record <= total_records:
            # Datensätze holen
            xml_content = fetch_records(start_record)
            if xml_content is None:
                break

            # Parsen des XML-Inhalts
            root = ET.fromstring(xml_content)

            # Überprüfen, ob Datensätze zurückgegeben wurden
            records_found = False

            for record in root.findall('.//{http://www.loc.gov/MARC21/slim}record'):
                records_found = True

                # ISBN
                isbns = [subfield.text for datafield in record.findall("{http://www.loc.gov/MARC21/slim}datafield[@tag='020']")
                         for subfield in datafield.findall("{http://www.loc.gov/MARC21/slim}subfield[@code='a']")]
                isbn_str = "; ".join(isbns)

                # Buchtitel
                title_datafield = record.find("{http://www.loc.gov/MARC21/slim}datafield[@tag='245']")
                title = title_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']").text if title_datafield is not None else ''

                # Auflage
                edition_datafield = record.find("{http://www.loc.gov/MARC21/slim}datafield[@tag='250']")
                edition = edition_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']").text if edition_datafield is not None else ''

                # Publikationsort, Publisher, Publikationsjahr
                pub_datafield = record.find("{http://www.loc.gov/MARC21/slim}datafield[@tag='264']")
                publication_place = pub_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']").text if pub_datafield is not None and pub_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']") is not None else ''
                publisher = pub_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='b']").text if pub_datafield is not None and pub_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='b']") is not None else ''
                publication_year = pub_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='c']").text if pub_datafield is not None and pub_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='c']") is not None else ''

                # Seitenzahl
                pages_datafield = record.find("{http://www.loc.gov/MARC21/slim}datafield[@tag='300']")
                pages = pages_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']").text if pages_datafield is not None and pages_datafield.find("{http://www.loc.gov/MARC21/slim}subfield[@code='a']") is not None else ''

                # Sprache
                languages = [subfield.text for datafield in record.findall("{http://www.loc.gov/MARC21/slim}datafield[@tag='041']")
                             for subfield in datafield.findall("{http://www.loc.gov/MARC21/slim}subfield[@code='a']")]
                language_str = "; ".join(languages)

                # SpracheOriginal
                original_languages = [subfield.text for datafield in record.findall("{http://www.loc.gov/MARC21/slim}datafield[@tag='041']")
                                      for subfield in datafield.findall("{http://www.loc.gov/MARC21/slim}subfield[@code='h']")]
                original_language_str = "; ".join(original_languages)

                # Extrahiere Namen und Rollen aus den Feldern 100 und 700
                all_roles = extract_names_by_role("{http://www.loc.gov/MARC21/slim}datafield", record)

                # Gattung_Genre
                genre_field = record.findall("{http://www.loc.gov/MARC21/slim}datafield[@tag='655']")
                genre_str = "; ".join([subfield.text for field in genre_field for subfield in field.findall("{http://www.loc.gov/MARC21/slim}subfield[@code='a']")])

                # Reihe in der CSV
                row = [
                    isbn_str,                         # ISBN
                    title,                            # Buchtitel
                    edition,                          # Auflage
                    publication_place,                # Publikationsort
                    publisher,                        # Publisher
                    publication_year,                 # Publikationsjahr
                    pages,                            # Seitenzahl
                    "; ".join(all_roles['Verfasser']),# Verfasser
                    "; ".join(all_roles['Herausgeber']),# Herausgeber
                    "; ".join(all_roles['Übersetzer']), # Übersetzer
                    "; ".join(all_roles['keineRolle']),# keineRolle
                    "; ".join(all_roles['sonstigeRolle']),# sonstigeRolle
                    genre_str,                        # Gattung_Genre
                    language_str,                     # Sprache
                    original_language_str             # SpracheOriginal
                ]
                
                # Schreiben der Reihe in die CSV-Datei
                writer.writerow(row)
            
            if not records_found:
                print(f"Keine weiteren Datensätze gefunden, Schleife bei Startrecord {start_record} beendet.")
                break
            
            # Nächsten 100 Datensätze beginnen
            start_record += 100
    except Exception as e:
        print(f"Unerwarteter Fehler: {e}")

print("Datenextraktion abgeschlossen.")

