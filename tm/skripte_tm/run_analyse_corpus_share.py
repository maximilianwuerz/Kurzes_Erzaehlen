#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Einfache Variante: Korpusanteile (krit/unt/rest) nur aus diagnostics.xml
- Keine τ-Kappung, keine Segmentaufschlüsselung
- Aggregiert die in diagnostics.xml pro Topic angegebenen Tokenzahlen (Attribut 'tokens')
- Mapped Topics per Codebook (topic_id, kategorie in {krit, unt, unklar})

Aufrufbeispiel:
python corpus_shares_diagnostics_only.py ^
  --diagnostics "C:\mallet\ergebnisse\k100_spacy_nonames\diagnostics.xml" ^
  --codebook   "C:\mallet\ergebnisse\k100_spacy_nonames\k100_codebook_komplett_run.csv" ^
  --outdir     "C:\mallet\ergebnisse\k100_spacy_nonames\corpus"
"""

import os
import argparse
import pandas as pd
from xml.etree import ElementTree as ET


def load_diagnostics_tokens(diagnostics_xml: str) -> pd.DataFrame:
    """Liest pro Topic (id) die Tokenzahl aus diagnostics.xml."""
    tree = ET.parse(diagnostics_xml)
    root = tree.getroot()
    rows = []
    for t in root.iterfind(".//topic"):
        tid_attr = t.get("id")
        tok_attr = t.get("tokens")
        if tid_attr is None or tok_attr is None:
            continue
        try:
            tid = int(tid_attr)
            tok = float(tok_attr)
        except ValueError:
            continue
        rows.append({"topic_id": tid, "tokens": tok})
    if not rows:
        raise RuntimeError("Keine gültigen <topic id='...' tokens='...'>-Einträge in diagnostics.xml gefunden.")
    return pd.DataFrame(rows)


def load_codebook_categories(codebook_csv: str) -> pd.DataFrame:
    """Liest Topic-Kategorien aus dem Codebook (topic_id, kategorie)."""
    cb = pd.read_csv(codebook_csv, sep=";")
    cb.columns = [c.strip().lower() for c in cb.columns]
    if "topic_id" not in cb.columns and "topicid" in cb.columns:
        cb = cb.rename(columns={"topicid": "topic_id"})
    if "topic_id" not in cb.columns:
        raise ValueError("Codebook benötigt eine Spalte 'topic_id' (oder 'topicid').")
    if "kategorie" not in cb.columns:
        cb["kategorie"] = "unklar"
    out = cb[["topic_id", "kategorie"]].copy()
    out["topic_id"] = pd.to_numeric(out["topic_id"], errors="coerce").astype("Int64")
    out = out[out["topic_id"].notna()].copy()
    out["topic_id"] = out["topic_id"].astype(int)
    out["kategorie"] = out["kategorie"].astype(str).str.lower()
    return out


def main():
    ap = argparse.ArgumentParser(description="Korpusanteile (krit/unt/rest) nur aus diagnostics.xml berechnen.")
    ap.add_argument("--diagnostics", required=True, help="Pfad zu MALLET diagnostics.xml")
    ap.add_argument("--codebook", required=True, help="Pfad zum Codebook (CSV, ; als Trenner)")
    ap.add_argument("--outdir", required=True, help="Ausgabeordner")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    # 1) diagnostics.xml laden (Tokens je Topic)
    diag = load_diagnostics_tokens(args.diagnostics)  # Spalten: topic_id, tokens

    # 2) Codebook (Kategorien) laden und mergen
    cb = load_codebook_categories(args.codebook)      # Spalten: topic_id, kategorie
    df = diag.merge(cb, on="topic_id", how="left")
    df["kategorie"] = df["kategorie"].fillna("unklar").str.lower()

    # 3) Anteile berechnen (gesamt)
    total_tokens = float(df["tokens"].sum())
    if total_tokens <= 0:
        raise RuntimeError("Summe der Tokens aus diagnostics.xml ist 0.")
    df["share"] = df["tokens"] / total_tokens

    share_krit = float(df.loc[df["kategorie"] == "krit", "share"].sum())
    share_unt  = float(df.loc[df["kategorie"] == "unt",  "share"].sum())
    share_rest = max(0.0, 1.0 - share_krit - share_unt)

    # 4) Ausgaben
    per_topic_out = os.path.join(args.outdir, "corpus_shares_per_topic.csv")
    overall_out   = os.path.join(args.outdir, "corpus_shares.csv")

    df.sort_values("topic_id").to_csv(per_topic_out, index=False, encoding="utf-8")
    pd.DataFrame([{
        "tokens_total": int(round(total_tokens)),
        "share_krit": share_krit,
        "share_unt":  share_unt,
        "share_rest": share_rest
    }]).to_csv(overall_out, index=False, encoding="utf-8")

    print(f"Gespeichert: {per_topic_out}")
    print(f"Gespeichert: {overall_out}")
    print(f"Summary (gesamt): krit={share_krit:.3f}, unt={share_unt:.3f}, rest={share_rest:.3f}")


if __name__ == "__main__":
    main()