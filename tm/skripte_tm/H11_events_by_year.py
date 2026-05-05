#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Zählt ereignisspezifische Treffer (Anker / Anker ODER Kontext) in vollständigen .txt-Dateien
eines Verzeichnisses und aggregiert pro Jahr (für H11).

Erwartetes Dateinamenschema (wie bei dir):
JAHR_SEGMENTCODE_SEGMENTINFO_AUTOR_TITEL[_pp].txt
z. B.: 2020_OP_Plattform_Max-Mustermann_Ein-Text_pp.txt

Zwei Kennzahlen je Ereignis:
- anchor_only: Dokument hat ≥1 Treffer im Anker-Lexikon (explizite Thematisierung)
- anchor_plus_context: Dokument hat ≥1 Anker ODER ≥1 Kontext-Treffer (explizit oder implizit)

Aufrufbeispiel:
python H11_events_by_year.py ^
  --indir "C:\mallet\textkorpus\final_txtonly" ^
  --outcsv "C:\mallet\ergebnisse\H11\H11_events_by_year.csv" ^
  --recursive
"""

import os
import re
import argparse
import pandas as pd


# Ereignis-Lexika als Regex (case-insensitiv).
# Umsetzung deiner Sternchen-Logik:
# - wort (ohne Stern)  ->  \bwort\w*          (Wortanfang + Flexion/Komposita rechts)
# - *wort               ->  \wwort\b           (Komposita links zulassen)  [hier nur gezielt genutzt]
# - wort                ->  wort               (infix, überall im Wort – z. B. 'ukrain' inkl. Ostukraine)
# Phrasen mit Leerzeichen als feste Folge (z. B. "fridays for").
EVENTS_REGEX = {
    "finanzkrise2007_2008": {
        "anchor": (
            r"\bfinanzkrise\w*|\bbankenkrise\w*|\blehman\w*|\bkreditkrise\w*|"
            r"\bfinanzmarktkrise\w*|\bbailout\w*|\bkonjunkturpaket\w*|"
            r"\bimmobilienblase\w*|\brettungspaket\w*"
        ),
        "context": (
            r"\bhypothek\w*|\bfinanzmarkt\w*|\brezession\w*|\bverschuldung\w*|"
            r"\bschulden\w*|\bspekulation\w*|\bwährungsfond\w*|\bwaehrungsfond\w*|"
            r"\bkursverlust\w*|\bkredit\w*|\bzins\w*|\bezb\b|\bkapital\w*"
        ),
    },
    "migrationskrise2015_2016": {
        "anchor": (
            r"\bmigration\w*|\bmigrant\w*|\bflüchtling\w*|\bfluechtling\w*|\bgeflüchtet\w*|\bgefluechtet\w*|\basyl\w*|"
            r"\brefugee\w*|\bdisplaced\w*|\beinwander\w*|\bseenotrettung\w*|"
            r"\blampedusa\b|\bmittelmeerroute\w*|\bgrenzkontroll\w*|\bfrontex\b|\beurosur\b"
        ),
        "context": (
            r"\bflucht\w*|\bgrenz\w*|\bgeflohen\b|\bfliehen\w*|\bvisum\b|\bvisa\b|"
            r"\bmittelmeer\b|\bsyrien\b|\bsyrer\w*|\bschleuser\w*"
        ),
    },
    "corona2020_2023": {
        "anchor": (
            r"\bcorona\b|\bcovid\b|\bcovid-?19\b|\bepidemie\w*|\bpandemie\w*|\blockdown\w*|"
            r"\bimpf\w*|\bquarant\w*|\binzidenz\w*|\bkontaktverbot\w*|\bmaskenpflicht\w*|"
            r"\bffp\w*|\bquerdenk\w*|\bwuhan\b|\bvirusvaria\w*|"
            r"\bübersterblichkeit\w*|\buebersterblichkeit\w*"
        ),
        "context": (
            r"\bvirus\w*|\bviren\b|\bkrankheit\w*|\bseuche\w*|\binfektion\w*|"
            r"\brisikogrupp\w*|\bimmunolog\w*|\blauterbach\b|\bdrosten\b"
        ),
    },
    "ukraine_ab_2022": {
        "anchor": (
            # 'ukrain' inkl. Ostukraine/Ost-Ukraine (bewusst ohne End-\b, um Komposita wie 'Ostukraine' zu treffen)
            r"\bostukrain\w*|\bost-?ukrain\w*|ukrain\w*|"
            r"\bangriffskr\w*|\bspezial-?operation\w*|\bkrim\b|\bannexion\w*|"
            r"\bkiew\b|\bkyiv\b|\bkijiv\b|\bdonbas\w*|\bbutscha\b|\bcharkiw\b|"
            r"\bodessa\b|\bmariupol\b|\bluhansk\b|\bdonezk\b"
        ),
        "context": (
            r"\bruss\w*|\binvasion\w*|\bkrieg\w*|\bdrohn\w*|\bangriff\w*|\bnato\b|"
            r"\bputin\b|\bselenskyj\b|\bselensky\b|\bzelensky\b|\bzelenskyy\b|\bmobilmachung\w*"
        ),
    },
}


def parse_year_segment_from_filename(path: str):
    """Extrahiert Jahr und Segmentcode aus 'JAHR_SEGMENT...[_pp].txt'."""
    base = os.path.basename(str(path))
    name, _ = os.path.splitext(base)  # Endung (.txt/.TXT) entfernen
    parts = name.split("_")
    year = int(parts[0]) if parts and parts[0].isdigit() else None
    seg = parts[1] if len(parts) > 1 else None
    return year, seg


def read_text(path: str) -> str:
    """Liest Text robust (UTF-8, Fallback cp1252)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        with open(path, "r", encoding="cp1252", errors="ignore") as f:
            return f.read()


def iter_txt_files(indir: str, recursive: bool = False):
    """Liefert .txt-Dateipfade aus einem Verzeichnis (optional rekursiv)."""
    if recursive:
        for root, _, files in os.walk(indir):
            for fn in files:
                if fn.lower().endswith(".txt"):
                    yield os.path.join(root, fn)
    else:
        for fn in os.listdir(indir):
            if fn.lower().endswith(".txt"):
                yield os.path.join(indir, fn)


def main():
    ap = argparse.ArgumentParser(
        description="Ereignis-Treffer (Anker / Anker ODER Kontext) pro Dokument zählen und pro Jahr aggregieren (H11)."
    )
    ap.add_argument("--indir", required=True, help="Verzeichnis mit .txt-Dateien (vollständig, nicht vorverarbeitet)")
    ap.add_argument("--outcsv", required=True, help="Ausgabe CSV pro Jahr und Ereignis")
    ap.add_argument("--recursive", action="store_true", help="Unterordner rekursiv durchsuchen")
    args = ap.parse_args()

    # Regex kompilieren (case-insensitiv)
    compiled = {}
    for ev, dct in EVENTS_REGEX.items():
        pat_anchor = re.compile(dct["anchor"], flags=re.IGNORECASE)
        pat_context = re.compile(dct["context"], flags=re.IGNORECASE)
        compiled[ev] = (pat_anchor, pat_context)

    rows = []
    n_files = 0

    for path in iter_txt_files(args.indir, recursive=args.recursive):
        n_files += 1
        text = read_text(path)
        if not text:
            continue
        tokens = len(text.split())
        if tokens == 0:
            continue
        year, seg = parse_year_segment_from_filename(path)
        rec = {
            "file": os.path.basename(path),
            "path": path,
            "year": year,
            "segmentcode": seg,
            "tokens": tokens,
        }
        for ev, (pat_anchor, pat_context) in compiled.items():
            a_hits = len(pat_anchor.findall(text))
            c_hits = len(pat_context.findall(text))
            rec[f"{ev}_anchor_hits"] = a_hits
            rec[f"{ev}_context_hits"] = c_hits
            rec[f"{ev}_anchor_hits_per_1000"] = (a_hits * 1000.0 / tokens) if tokens > 0 else 0.0
            rec[f"{ev}_context_hits_per_1000"] = (c_hits * 1000.0 / tokens) if tokens > 0 else 0.0
            rec[f"{ev}_anchor_only"] = int(a_hits >= 1)
            rec[f"{ev}_anchor_plus_context"] = int((a_hits >= 1) or (c_hits >= 1))
        rows.append(rec)

    if not rows:
        raise RuntimeError(f"Keine verwertbaren Texte gefunden unter: {args.indir}")

    df = pd.DataFrame(rows)

    # Aggregation pro Jahr (einzige Ausgabe)
    out_year = []
    for y, sub in df.groupby("year", dropna=False):
        n_docs = len(sub)
        for ev in EVENTS_REGEX.keys():
            col_aonly = f"{ev}_anchor_only"
            col_apc = f"{ev}_anchor_plus_context"
            col_aper1k = f"{ev}_anchor_hits_per_1000"
            col_cper1k = f"{ev}_context_hits_per_1000"

            docs_anchor = int(sub[col_aonly].sum())
            docs_apc = int(sub[col_apc].sum())
            share_anchor = (docs_anchor / n_docs) if n_docs else 0.0
            share_apc = (docs_apc / n_docs) if n_docs else 0.0
            mean_a_per1k = float(sub[col_aper1k].mean()) if n_docs else 0.0
            mean_c_per1k = float(sub[col_cper1k].mean()) if n_docs else 0.0

            out_year.append({
                "year": y,
                "event": ev,
                "n_docs": n_docs,
                "docs_anchor": docs_anchor,
                "docs_anchor_kontext": docs_apc,  # (Anker ODER Kontext)
                "share_anchor_docs": share_anchor,
                "share_anchor_plus_context_docs": share_apc,
                "mean_anchor_hits_per_1000": mean_a_per1k,
                "mean_context_hits_per_1000": mean_c_per1k
            })

    by_year = pd.DataFrame(out_year).sort_values(["event", "year"])
    by_year.to_csv(args.outcsv, index=False, encoding="utf-8")
    print(f"Gespeichert: {args.outcsv}")
    print(f"Verarbeitete Dateien: {n_files}")


if __name__ == "__main__":
    main()