import os
import spacy
import nltk
from nltk.corpus import stopwords

# Lade die NLTK-Stopwörter herunter
nltk.download('stopwords')

# Lade das deutsche Sprachmodell von spaCy
nlp = spacy.load("de_core_news_sm")

def preprocess_text(text):
    # Normalisierung: Alles in Kleinbuchstaben konvertieren
    text = text.lower()

    # Verwende spaCy für die Tokenisierung, Lemmatisierung und Named Entity Recognition
    doc = nlp(text)

    # Filtere nicht alphabetische Tokens, Stopwords und Eigennamen (z.B. Personen)
    tokens = [token.lemma_ for token in doc if token.is_alpha and not token.is_stop and token.ent_type_ != 'PER']

    return tokens

def clean_text_files(source_dir, output_dir):
    # Stelle sicher, dass das Zielverzeichnis existiert
    os.makedirs(output_dir, exist_ok=True)

    for filename in os.listdir(source_dir):
        if filename.endswith(".txt"):
            filepath = os.path.join(source_dir, filename)
            with open(filepath, 'r', encoding='utf-8') as file:
                text = file.read()
                preprocessed_text = preprocess_text(text)
                
                # Erstellen des neuen Dateinamens mit dem Suffix _pp
                base_filename = os.path.splitext(filename)[0]
                output_filename = f"{base_filename}_pp.txt"
                output_filepath = os.path.join(output_dir, output_filename)
                
                # Ausgabe in die neue Datei mit UTF-8-Kodierung speichern
                with open(output_filepath, 'w', encoding='utf-8') as output_file:
                    output_file.write(' '.join(preprocessed_text))
                print(f"Processed and saved: {output_filename}")

# Verzeichnisse
source_directory = r'C:\mallet\textkorpus\final'
output_directory = r'C:\mallet\textkorpus\final\spacy_nonames'
clean_text_files(source_directory, output_directory)