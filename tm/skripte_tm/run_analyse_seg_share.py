#!/usr/bin/env python38 -*-

"""
Berechnet tokengewichtete Korpusanteile (krit/unt/rest)
- gesamt und je Segment (aus doc_topics + Dokumentlängen, mit τ-Kappung wie in run_analyse)
- optional zusätzlich: gesamt aus diagnostics.xml (Themen-Tokenzahlen ohne τ-Kappung)

Aufrufbeispiel:
python corpus_shares.py ^
  --doctopics "C:\mallet\ergebnisse\k100_spacy_nonames\doc_topics.txt" ^
  --codebook  "C:\mallet\ergebnisse\k100_spacy_nonames\k100_codebook_komplett_run.csv" ^
  --outdir    "C:\mallet\ergebnisse\k100_spacy_nonames\corpus" ^
  --tau 0.02 ^
  --diagnostics "C:\mallet\ergebnisse\k100_spacy_nonames\diagnostics.xml"
"""

import os
import re
import argparse
import pandas as pd
import numpy as np
from xml.etree import ElementTree as ET


def strip_file_prefix(p: str) -> str:
    return re.sub(r"^file:/+", "", str(p))


def parse_year_seg_from_filename(fname: str):
    base = os.path.basename(str(fname))
    stem = re.sub(r"\.txt$", "", base, flags=re.IGNORECASE)
    parts = stem.split("_")
    year = int(parts[0]) if parts and parts[0].isdigit() else None
    seg = parts[1] if len(parts) > 1 else None
    return year, seg


def count_tokens(local_path: str, enc_primary: str = "utf-8") -> int:
    p = strip_file_prefix(local_path)
    try:
        with open(p, "r", encoding=enc_primary) as f:
            txt = f.read()
    except UnicodeDecodeError:
        with open(p, "r", encoding="cp1252", errors="ignore") as f:
            txt = f.read()
    # Whitespace-basierte Tokenzählung (konsistent und schnell)
    return len(txt.split())


def load_codebook(path: str, K: int):
    cb = pd.read_csv(path, sep=";")
    cb.columns = [c.strip().lower() for c in cb.columns]
    if "topic_id" not in cb.columns and "topicid" in cb.columns:
        cb = cb.rename(columns={"topicid": "topic_id"})
    if "kategorie" not in cb.columns:
        cb["kategorie"] = "unklar"
    cb["topic_id"] = pd.to_numeric(cb["topic_id"], errors="coerce").astype("Int64")
    cb = cb[cb["topic_id"].notna()].copy()
    cb["topic_id"] = cb["topic_id"].astype(int)
    cb = cb[(cb["topic_id"] >= 0) & (cb["topic_id"] < K)]
    cb["kategorie"] = cb["kategorie"].astype(str).str.lower()
    krit_ids = cb.loc[cb["kategorie"] == "krit", "topic_id"].tolist()
    unt_ids = cb.loc[cb["kategorie"] == "unt", "topic_id"].tolist()
    return cb, krit_ids, unt_ids


def corpus_shares_tau(doctopics: str, codebook: str, outdir: str, tau: float = 0.02, encoding: str = "utf-8"):
    # doc_topics laden
    dt = pd.read_csv(doctopics, sep="\t", header=None, engine="python")
    K = dt.shape[1] - 2
    topic_cols = [f"t{i}" for i in range(K)]
    dt.columns = ["docidx", "docpath"] + topic_cols
    dt["docidx"] = pd.to_numeric(dt["docidx"], errors="coerce").astype(int)
    dt["docpath_local"] = dt["docpath"].apply(strip_file_prefix)
    dt["file"] = dt["docpath_local"].apply(os.path.basename)

    # Metadaten aus Dateinamen
    ys = dt["file"].apply(parse_year_seg_from_filename)
    dt["year"] = ys.apply(lambda x: x[0])
    dt["segmentcode"] = ys.apply(lambda x: x[1])

    # Codebook/Kategorien
    cb, krit_ids, unt_ids = load_codebook(codebook, K)

    # Dokumentlängen zählen
    dt["tokens"] = dt["docpath_local"].apply(lambda p: count_tokens(p, enc_primary=encoding))

    # θ unter tau auf 0 (keine Renormierung)
    vals = dt[topic_cols].astype(float).to_numpy(copy=False)
    if tau is not None and tau > 0.0:
        vals = np.where(vals >= tau, vals, 0.0)

    # Massen = Nd * θ
    Nd = dt["tokens"].to_numpy(dtype=float).reshape(-1, 1)
    masses = Nd * vals  # Shape: (n_docs, K)

    total_tokens = float(dt["tokens"].sum())
    if total_tokens <= 0:
        raise RuntimeError("Gesamttokenzahl ist 0 – bitte Pfade/Encoding prüfen.")

    def share_for_ids(id_list):
        if not id_list:
            return 0.0
        cols_idx = np.array(id_list, dtype=int)
        return float(masses[:, cols_idx].sum() / total_tokens)

    share_krit = share_for_ids(krit_ids)
    share_unt = share_for_ids(unt_ids)
    share_rest = max(0.0, 1.0 - share_krit - share_unt)

    overall = pd.DataFrame([{
        "n_docs": int(len(dt)),
        "total_tokens": int(total_tokens),
        "tau": tau,
        "share_krit": share_krit,
        "share_unt": share_unt,
        "share_rest": share_rest
    }])

    # Segmentweise Anteile
    seg_rows = []
    for seg, sub in dt.groupby("segmentcode", dropna=False):
        sub_tokens = float(sub["tokens"].sum())
        if sub_tokens <= 0:
            sharek = shareu = sharer = 0.0
        else:
            idx = sub.index.to_numpy()
            sub_masses = masses[idx, :]

            def subshare(id_list):
                if not id_list:
                    return 0.0
                return float(sub_masses[:, np.array(id_list, dtype=int)].sum() / sub_tokens)

            sharek = subshare(krit_ids)
            shareu = subshare(unt_ids)
            sharer = max(0.0, 1.0 - sharek - shareu)

        seg_rows.append({
            "segmentcode": seg,
            "n_docs": int(len(sub)),
            "total_tokens": int(sub_tokens),
            "share_krit": sharek,
            "share_unt": shareu,
            "share_rest": sharer
        })
    by_segment = pd.DataFrame(seg_rows).sort_values("segmentcode", na_position="last")

    # Ausgaben
    os.makedirs(outdir, exist_ok=True)
    overall_out = os.path.join(outdir, "corpus_shares_overall_tau.csv")
    byseg_out = os.path.join(outdir, "corpus_shares_by_segment_tau.csv")
    overall.to_csv(overall_out, index=False, encoding="utf-8")
    by_segment.to_csv(byseg_out, index=False, encoding="utf-8")
    print(f"Gespeichert: {overall_out}")
    print(f"Gespeichert: {byseg_out}")

    return overall, by_segment


def corpus_shares_from_diagnostics(diagnostics_xml: str, codebook: str, outdir: str):
    """
    Liest pro Topic das Attribut 'tokens' aus diagnostics.xml und aggregiert nach Kategorien (krit/unt/rest).
    Diese Anteile sind ohne τ-Kappung (direkte Zuweisungen aus MALLET).
    """
    tree = ET.parse(diagnostics_xml)
    root = tree.getroot()

    topic_tokens = {}
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
        topic_tokens[tid] = tok

    if not topic_tokens:
        raise RuntimeError("Keine Topic-Token-Zahlen in diagnostics.xml gefunden (Attribut 'tokens').")

    tokens_sum = float(sum(topic_tokens.values()))

    # Codebook für Kategorien
    cb = pd.read_csv(codebook, sep=";")
    cb.columns = [c.strip().lower() for c in cb.columns]
    if "topic_id" not in cb.columns and "topicid" in cb.columns:
        cb = cb.rename(columns={"topicid": "topic_id"})
    if "kategorie" not in cb.columns:
        cb["kategorie"] = "unklar"
    cb["topic_id"] = pd.to_numeric(cb["topic_id"], errors="coerce").astype("Int64")
    cb = cb[cb["topic_id"].notna()].copy()
    cb["topic_id"] = cb["topic_id"].astype(int)
    cb["kategorie"] = cb["kategorie"].astype(str).str.lower()

    rows = []
    for tid, tok in sorted(topic_tokens.items()):
        mask = (cb["topic_id"] == tid)
        cat = cb.loc[mask, "kategorie"].iloc[0] if mask.any() else "unklar"
        rows.append({"topic_id": tid, "tokens": tok, "share": tok / tokens_sum, "kategorie": cat})
    per_topic = pd.DataFrame(rows)

    share_krit = float(per_topic.loc[per_topic["kategorie"] == "krit", "share"].sum())
    share_unt = float(per_topic.loc[per_topic["kategorie"] == "unt", "share"].sum())
    share_rest = max(0.0, 1.0 - share_krit - share_unt)
    overall = pd.DataFrame([{
        "share_krit": share_krit,
        "share_unt": share_unt,
        "share_rest": share_rest,
        "tokens_total": int(tokens_sum)
    }])

    # Ausgaben
    os.makedirs(outdir, exist_ok=True)
    per_topic_out = os.path.join(outdir, "corpus_shares_per_topic_diagnostics.csv")
    overall_out = os.path.join(outdir, "corpus_shares_overall_diagnostics.csv")
    per_topic.to_csv(per_topic_out, index=False, encoding="utf-8")
    overall.to_csv(overall_out, index=False, encoding="utf-8")
    print(f"Gespeichert: {per_topic_out}")
    print(f"Gespeichert: {overall_out}")

    return per_topic, overall


def parse_args():
    ap = argparse.ArgumentParser(description="Tokengewichtete Korpusanteile (krit/unt/rest) berechnen.")
    ap.add_argument("--doctopics", required=True, help="Pfad zu MALLET doc_topics.txt (dichtes Format)")
    ap.add_argument("--codebook", required=True, help="Pfad zum Codebook (CSV, ; als Trenner)")
    ap.add_argument("--outdir", required=True, help="Ausgabeordner")
    ap.add_argument("--tau", type=float, default=0.02, help="Kappungsschwelle für θ (Default: 0.02)")
    ap.add_argument("--diagnostics", default=None, help="Optional: Pfad zu diagnostics.xml (liefert gesamt per Topic)")
    ap.add_argument("--encoding", default="utf-8", help="Encoding der Textdateien (Default: utf-8; Fallback cp1252)")
    return ap.parse_args()


def main():
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    # τ-konsistente Korpusanteile (gesamt + segmentweise)
    corpus_shares_tau(args.doctopics, args.codebook, args.outdir, tau=args.tau, encoding=args.encoding)

    # Optional: Korpusanteile aus diagnostics.xml (gesamt, per Topic – ohne τ)
    if args.diagnostics:
        corpus_shares_from_diagnostics(args.diagnostics, args.codebook, args.outdir)


if __name__ == "__main__":
    main()