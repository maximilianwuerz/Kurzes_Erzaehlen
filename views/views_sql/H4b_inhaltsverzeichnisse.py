import csv
import re
import time
from pathlib import Path
from typing import Optional, Tuple
import requests
from xml.etree import ElementTree as ET

SRU_URL = "https://services.dnb.de/sru/dnb"
DEFAULT_SLEEP_S = 0.3  # kleine Pause zwischen Anfragen (Rate-Limit schonen)

# HTTP-Session mit Retry
SESSION = requests.Session()
ADAPTER = requests.adapters.HTTPAdapter(max_retries=3)
SESSION.mount("https://", ADAPTER)
SESSION.headers.update({"User-Agent": "FAU-Research-ISBN-ToC/1.0 (+contact@example.org)"})


def load_done_isbns(out_csv: str) -> tuple[set[str], set[str]]:
    """
    Liest bereits verarbeitete ISBNs aus der Ergebnis-CSV und gibt zwei Sets zurück:
    - done_raw: ISBNs genau so, wie sie in der CSV-Spalte 'isbn' stehen
    - done_norm: normalisierte Varianten dieser ISBNs
    """
    done_raw: set[str] = set()
    done_norm: set[str] = set()
    p = Path(out_csv)
    if not p.exists():
        return done_raw, done_norm

    try:
        with p.open("r", encoding="utf-8", newline="") as f:
            r = csv.DictReader(f)
            if r.fieldnames and "isbn" in r.fieldnames:
                for row in r:
                    raw = (row.get("isbn") or "").strip()
                    if not raw:
                        continue
                    done_raw.add(raw)
                    done_norm.add(re.sub(r"[^0-9Xx]", "", raw).upper())
    except Exception:
        # Wenn Datei gesperrt/korrupt ist: Resume still überspringen
        return done_raw, done_norm

    return done_raw, done_norm


def normalize_isbn(raw: str) -> str:
    """Entfernt alles außer Ziffern und X (für ISBN-10 Prüfziffer)."""
    return re.sub(r"[^0-9Xx]", "", raw).upper()


def resolve_isbn_to_dnb_id(isbn: str, sleep_s: float = DEFAULT_SLEEP_S) -> Optional[str]:
    """
    Ruft die DNB-SRU-Schnittstelle mit isbn=<ISBN> auf und versucht, eine d-nb.info-ID zu extrahieren.
    Gibt die reine ID zurück (z. B. '123456789X') oder None, wenn nichts gefunden.
    """
    params = {
        "version": "1.1",
        "operation": "searchRetrieve",
        "recordSchema": "MARC21-xml",
        "query": f"isbn={isbn}",
    }
    try:
        r = SESSION.get(SRU_URL, params=params, timeout=20)
        r.raise_for_status()
    except requests.RequestException:
        time.sleep(sleep_s)
        return None

    xml_text = r.text

    # 1) Robust: direkt im XML nach d-nb.info/<ID> suchen
    m = re.search(r"d-nb\.info/([0-9Xx]+)", xml_text)
    if m:
        return m.group(1).upper()

    # 2) Fallback: aus MARC-Controlfield 001 lesen
    try:
        ns = {
            "srw": "http://www.loc.gov/zing/srw/",
            "marc": "http://www.loc.gov/MARC21/slim",
        }
        root = ET.fromstring(xml_text)
        cf001 = root.find(".//marc:record/marc:controlfield[@tag='001']", ns)
        if cf001 is not None and cf001.text:
            return cf001.text.strip()
    except ET.ParseError:
        pass

    time.sleep(sleep_s)
    return None


def build_toc_url(dnb_id: str) -> str:
    """URL für das ToC-Textformat: https://d-nb.info/<ID>/04/text"""
    return f"https://d-nb.info/{dnb_id}/04/text"


def fetch_toc_text(toc_url: str, sleep_s: float = DEFAULT_SLEEP_S) -> Tuple[Optional[str], str]:
    """
    Holt den ToC-Text. Gibt (text, status) zurück.
    status: 'ok', 'not_found', 'error', 'http<code>'
    """
    try:
        resp = SESSION.get(toc_url, timeout=20)
        if resp.status_code == 200:
            text = resp.text.strip()
            if text:
                return text, "ok"
            else:
                return None, "not_found"
        elif resp.status_code == 404:
            return None, "not_found"
        else:
            return None, f"http{resp.status_code}"
    except requests.RequestException:
        return None, "error"
    finally:
        time.sleep(sleep_s)


def count_contributions_from_toc(toc_text: Optional[str]) -> int:
    """
    Robuste Heuristik:
    - Entfernt Füllzeichen (____, ....), normalisiert Whitespaces.
    - Merged "Zahl-allein"-Zeilen an die vorherige (oder notfalls nächste) Titelzeile.
    - Erkannt werden Seitenzahlen am Zeilenende ODER -anfang (arabisch oder römisch).
    - Überschriften wie "Inhalt", "Vorwort" etc. werden ignoriert.
    """
    if not toc_text:
        return 0

    ignore_heads = {
        "inhalt",
        "vorwort",
        "danksagung",
        "einleitung",
        "literaturverzeichnis",
        "bibliographie",
        "register",
        "anhang",
        "impressum",
        "contents",
    }

    # Roman- und arabische Seitenzahlen
    roman_ci = r'(?i:[ivxlcdm]{1,7})'       # römische Zahl (case-insensitive)
    page_token = rf'(?:\d{{1,4}}|{roman_ci})'

    # Muster:
    only_page_re  = re.compile(rf'^(?:s\.|p\.|seite)?\s*({page_token})\s*$', re.IGNORECASE)  # Seitenzahl in eigener Zeile    
    page_end_re = re.compile(rf'(?:\.{{2,}}|_{{2,}}|\s)\s*({page_token})\s*$', re.IGNORECASE)  # Seitenzahl am Zeilenende
    page_start_re = re.compile(rf'^\s*({page_token})\s{{1,6}}\S', re.IGNORECASE)  # Seitenzahl am Zeilenanfang
    def clean_line(s: str) -> str:
        s = s.replace("\u200b", "")  # Zero-width space
        # Füllzeichen (Unterstriche, Punkte, Striche, Bullets) vereinfachen
        s = re.sub(r'[_.·•⋅\-–—]{2,}', ' ', s)
        s = re.sub(r'\s+', ' ', s)
        return s.strip()

    def is_header(ln: str) -> bool:
        l = ln.lower()
        return any(l == h or l.startswith(h + " ") for h in ignore_heads)

    # 1) Normalisieren und leere Zeilen verwerfen
    lines = [clean_line(ln) for ln in toc_text.splitlines() if ln.strip()]

    # 2) Zahl-allein-Zeilen an vorherige (oder nächste) Titelzeile mergen
    merged: list[str] = []
    i = 0
    while i < len(lines):
        ln = lines[i]
        m = only_page_re.match(ln)
        if m:
            page = m.group(1)
            if merged and not is_header(merged[-1]):
                merged[-1] = f"{merged[-1]} {page}".strip()
            elif i + 1 < len(lines) and not is_header(lines[i + 1]):
                # wenn davor nur Kopfzeile war, hänge Seite an die nächste Titelzeile
                lines[i + 1] = f"{page} {lines[i + 1]}".strip()
            i += 1
            continue
        merged.append(ln)
        i += 1

    # 3) Zählen: Seitenzahl am Ende oder am Anfang
    cnt = 0
    for ln in merged:
        if is_header(ln):
            continue
        if page_end_re.search(ln) or page_start_re.search(ln):
            cnt += 1

    return cnt


def main(isbn_file: str = "dnb_all_isbn.txt", out_csv: str = "dnb_toc_counts2.csv", resume: bool = True) -> None:
    in_path = Path(isbn_file)
    out_path = Path(out_csv)

    if not in_path.exists():
        print(f"Eingabedatei nicht gefunden: {in_path.resolve()}")
        return

    # Resume: bereits verarbeitete ISBNs aus vorhandener CSV laden
    done_raw: set[str] = set()
    done_norm: set[str] = set()
    append_mode = False
    if resume and out_path.exists():
        done_raw, done_norm = load_done_isbns(out_csv)
        append_mode = True
        if done_raw:
            print(f"Resume aktiv: {len(done_raw)} ISBN(s) aus {out_path.name} werden übersprungen.")

    fieldnames = ["isbn", "dnb_id", "toc_url", "status", "n_contributions", "note"]

    processed_new = 0
    with out_path.open("a" if append_mode else "w", encoding="utf-8", newline="") as f_out:
        writer = csv.DictWriter(f_out, fieldnames=fieldnames)
        if not append_mode:
            writer.writeheader()

        try:
            with in_path.open("r", encoding="utf-8") as f_in:
                for i, raw in enumerate(f_in, start=1):
                    raw = raw.strip()
                    if not raw:
                        continue
                    isbn_norm = normalize_isbn(raw)

                    # Bereits verarbeitet?
                    if resume and (raw in done_raw or isbn_norm in done_norm):
                        if i % 250 == 0:
                            print(f"Skip/Resume: bis Eingabezeile {i} …")
                        continue

                    dnb_id = resolve_isbn_to_dnb_id(isbn_norm)
                    if not dnb_id:
                        writer.writerow({
                            "isbn": raw,
                            "dnb_id": "",
                            "toc_url": "",
                            "status": "no_record",
                            "n_contributions": "",
                            "note": "Kein DNB-Datensatz gefunden",
                        })
                        processed_new += 1
                        if processed_new % 100 == 0:
                            f_out.flush()
                            print(f"{processed_new} neue Einträge geschrieben …")
                        continue

                    toc_url = build_toc_url(dnb_id)
                    toc_text, status = fetch_toc_text(toc_url)

                    if status != "ok":
                        writer.writerow({
                            "isbn": raw,
                            "dnb_id": dnb_id,
                            "toc_url": toc_url,
                            "status": status,
                            "n_contributions": "",
                            "note": "Kein ToC-Text verfügbar oder Fehler",
                        })
                    else:
                        n_contrib = count_contributions_from_toc(toc_text)
                        writer.writerow({
                            "isbn": raw,
                            "dnb_id": dnb_id,
                            "toc_url": toc_url,
                            "status": "ok",
                            "n_contributions": n_contrib,
                            "note": "",
                        })

                    processed_new += 1
                    if processed_new % 100 == 0:
                        f_out.flush()
                        print(f"{processed_new} neue Einträge geschrieben …")
        except KeyboardInterrupt:
            f_out.flush()
            print("\nAbbruch durch Benutzer – Zwischenergebnisse wurden gespeichert.")

    print(f"Fertig. Neue Einträge: {processed_new}. Ausgabe: {out_path.resolve()}")


if __name__ == "__main__":
    main()