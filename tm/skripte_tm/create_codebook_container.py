
#Erzeugt aus MALLETs topic_keys.txt ein Codebuch-Skelett (CSV).

#Eingabe (typisch je Zeile):
 # topic_id<TAB>alpha<TAB>topwords (durch Leerzeichen getrennt)
#Fallback:
 # Whitespace-Split, erster Token = topic_id, zweiter evtl. alpha, Rest = topwords.

#Ausgabe-CSV (Spalten):
 # topic_id, alpha, topwords, label, kategorie, notes

#Aufrufbeispiel:
# python create_codebook_container.py C:\mallet\ergebnisse\k100\topic_keys.txt C:\mallet\ergebnisse\k100\k100_codebook_container.csv


import argparse
import csv
from pathlib import Path
from typing import List, Tuple, Optional, Dict


def parse_alpha(s: str) -> Optional[float]:
    if s is None:
        return None
    s = s.strip()
    if not s:
        return None
    
#Komma als Dezimaltrenner erlauben

    s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def parse_line(line: str) -> Optional[Tuple[int, Optional[float], str]]:
    #Parsen einer Zeile aus topic_keys.txt → (topic_id, alpha, topwords)
    
    s = line.strip()
    if not s or s.startswith("#"):
        return None

    
#Bevorzugt: TAB-getrennt (Standard in MALLET)

    parts = s.split("\t", 2)
    if len(parts) >= 3:
        tid_str, alphastr, top_words = parts[0].strip(), parts[1].strip(), parts[2].strip()
        try:
            tid = int(tid_str)
        except ValueError:
            return None
        alpha = parse_alpha(alphastr)
        return tid, alpha, top_words

    
#Fallback: Whitespace-Split

    tokens = s.split()
    if not tokens:
        return None
    try:
        tid = int(tokens[0])
    except ValueError:
        return None

    alpha = None
    top_words = ""
    if len(tokens) >= 2:
        a = parse_alpha(tokens[1])
        if a is not None:
            alpha = a
            top_words = " ".join(tokens[2:]) if len(tokens) > 2 else ""
        else:
            top_words = " ".join(tokens[1:])
    return tid, alpha, top_words


def read_topic_keys(path: Path) -> List[Dict]:
    rows: List[Dict] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            parsed = parse_line(line)
            if parsed is None:
                continue
            tid, alpha, top_words = parsed
            rows.append({
                "topic_id": tid,
                "alpha": "" if alpha is None else alpha,
                "topwords": top_words,
                "label": "",       
#manuell ausfüllen

                "kategorie": "",   
#krit | unt | unklar

                "notes": ""        
#Begründung/Belege

            })
    rows.sort(key=lambda r: r["topic_id"])
    return rows


def main():
    ap = argparse.ArgumentParser(description="Codebuch-Skelett aus MALLET topic_keys.txt erzeugen")
    ap.add_argument("topic_keys", help="Pfad zu topic_keys.txt")
    ap.add_argument("out_csv", help="Pfad zur Ausgabe-CSV (Codebuch-Skelett)")
    args = ap.parse_args()

    in_path = Path(args.topic_keys)
    out_path = Path(args.out_csv)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    rows = read_topic_keys(in_path)

    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["topic_id", "alpha", "topwords", "label", "kategorie", "notes"]
        )
        w.writeheader()
        w.writerows(rows)

    print(f"Codebuch-Skelett geschrieben: {out_path.resolve()}")


if __name__ == "__main__":
    main()