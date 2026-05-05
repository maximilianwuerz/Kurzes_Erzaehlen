#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import argparse
import pandas as pd
import numpy as np


def strip_file_prefix(path: str) -> str:
    """Entfernt 'file:/'-Präfix und gibt einen lokal lesbaren Pfad zurück."""
    return re.sub(r"^file:/+", "", str(path))


def basename_only(path: str) -> str:
    """Nur Dateiname (ohne Verzeichnisse)."""
    return os.path.basename(strip_file_prefix(path))


def parse_year_seg(fname: str) -> pd.Series:
    """Extrahiert Jahr und Segmentcode aus dem Dateinamen."""
    fname = os.path.basename(str(fname))
    stem = re.sub(r"\.txt$", "", fname, flags=re.IGNORECASE)
    parts = stem.split("_")
    year = int(parts[0]) if parts and parts[0].isdigit() else None
    seg = parts[1] if len(parts) > 1 else None
    return pd.Series(dict(year=year, segmentcode=seg))


def count_tokens(local_path: str) -> int:
    """Zählt Tokens (Whitespace-Split); robustes Encoding-Fallback."""
    p = strip_file_prefix(local_path)
    try:
        with open(p, "r", encoding="utf-8") as f:
            txt = f.read()
    except UnicodeDecodeError:
        with open(p, "r", encoding="cp1252", errors="ignore") as f:
            txt = f.read()
    return len(txt.split())


def top_docs_by_mass(df: pd.DataFrame, topic_col: str, n: int, tau: float, min_tokens: int) -> pd.DataFrame:
    """
    Top-N je Topic, primär sortiert nach mass = theta * tokens, sekundär nach theta (weight).
    Filter: theta >= tau und tokens >= min_tokens; falls <N, ohne Filter auffüllen.
    """
    cols = ["docidx", "docpath_local", "file", "year", "segmentcode", "tokens", topic_col]
    sub = df.loc[(df[topic_col] >= tau) & (df["tokens"] >= min_tokens), cols].copy()
    if sub.empty:
        sub = df.loc[:, cols].copy()
    sub["mass"] = sub[topic_col] * sub["tokens"]
    sub = sub.sort_values(["mass", topic_col], ascending=False).head(n)

    # Auffüllen, falls < N
    if len(sub) < n:
        add = df.loc[:, cols].copy()
        add["mass"] = add[topic_col] * add["tokens"]
        add = add[~add["docidx"].isin(sub["docidx"])].sort_values(["mass", topic_col], ascending=False).head(n - len(sub))
        sub = pd.concat([sub, add], ignore_index=True)

    sub = sub.reset_index(drop=True)
    sub["rank"] = np.arange(1, len(sub) + 1)
    sub = sub.rename(columns={topic_col: "weight"})
    return sub[["rank", "docidx", "file", "docpath_local", "year", "segmentcode", "tokens", "weight", "mass"]]


def main():
    ap = argparse.ArgumentParser(description="Top-N Dokumente je Topic nach absoluter Evidenz (theta * Tokens) ausgeben.")
    ap.add_argument("--doctopics", required=True, help="Pfad zu MALLET doc_topics.txt (dichtes Format: id, path, t0..tK-1)")
    ap.add_argument("--codebook", required=True, help="Pfad zum Codebook (CSV, ; als Trenner, Spalten: topic_id, kategorie)")
    ap.add_argument("--outdir", required=True, help="Ausgabeordner")
    ap.add_argument("--cats", default="unklar", help="Kommagetrennte Kategorien aus dem Codebook (z. B. unklar oder unklar,krit,unt). Default: unklar")
    ap.add_argument("--topics", default="", help="Optional: explizite Topic-IDs (Komma-separiert). Überschreibt --cats.")
    ap.add_argument("--n", type=int, default=3, help="Top-N Dokumente pro Topic (Default: 3)")
    ap.add_argument("--tau", type=float, default=0.02, help="Anteilsschwelle theta >= tau (Default: 0.02)")
    ap.add_argument("--min_tokens", type=int, default=150, help="Mindest-Tokens je Dokument für die Top-Auswahl (Default: 150)")
    ap.add_argument("--augment_codebook", action="store_true", help="Zusätzlich codebook_aug_mass.csv mit Top1..TopN (file/weight/mass) schreiben")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    # 1) doc_topics laden
    dt = pd.read_csv(args.doctopics, sep="\t", header=None, engine="python")
    K = dt.shape[1] - 2
    topic_cols = [f"t{i}" for i in range(K)]
    dt.columns = ["docidx", "docpath"] + topic_cols

    # 2) Basis-DF mit Dateinamen, Jahr, Segment, Tokenanzahl
    df = dt.copy()
    df["docpath_local"] = df["docpath"].apply(strip_file_prefix)
    df["file"] = df["docpath"].apply(basename_only)
    meta = df["file"].apply(parse_year_seg)
    df = pd.concat([df, meta], axis=1)
    df["tokens"] = df["docpath_local"].apply(count_tokens)

    # 3) Codebook laden
    cb = pd.read_csv(args.codebook, sep=";")
    cb.columns = [c.strip().lower() for c in cb.columns]
    if "topic_id" not in cb.columns and "topicid" in cb.columns:
        cb = cb.rename(columns={"topicid": "topic_id"})
    if "topic_id" not in cb.columns:
        raise ValueError("Codebook braucht eine Spalte 'topic_id' (oder 'topicid').")
    if "kategorie" not in cb.columns:
        cb["kategorie"] = "unklar"  # falls nicht vorhanden

    cb["topic_id"] = pd.to_numeric(cb["topic_id"], errors="coerce").astype("Int64")
    cb = cb[cb["topic_id"].notna()].copy()
    cb["topic_id"] = cb["topic_id"].astype(int)
    cb["kategorie"] = cb["kategorie"].astype(str).str.lower().fillna("unklar")

    # 4) Topics-Auswahl
    if args.topics.strip():
        topic_ids = [int(x) for x in re.split(r"[,\s]+", args.topics.strip()) if x != ""]
    else:
        cats = [c.strip().lower() for c in args.cats.split(",") if c.strip()]
        topic_ids = cb.loc[cb["kategorie"].isin(cats), "topic_id"].tolist()

    # 5) Top-N je Topic berechnen
    rows = []
    for tid in topic_ids:
        if tid < 0 or tid >= K:
            continue
        col = f"t{tid}"
        res = top_docs_by_mass(df, col, n=args.n, tau=args.tau, min_tokens=args.min_tokens)
        res.insert(0, "topic_id", tid)
        rows.append(res)
    if not rows:
        raise RuntimeError("Keine validen Topics gefunden (prüfe --topics/--cats oder Codebook).")

    top_all = pd.concat(rows, ignore_index=True).sort_values(["topic_id", "rank"])

    # 6) Übersicht schreiben
    out_top = os.path.join(args.outdir, "topic_topdocs_by_mass.csv")
    top_all.to_csv(out_top, index=False, encoding="utf-8")
    print(f"Gespeichert: {out_top}")

    # 7) Optional: Codebook anreichern (Top1..TopN: file/weight/mass)
    if args.augment_codebook:
        files_pv = top_all.pivot_table(index="topic_id", columns="rank", values="file", aggfunc="first")
        w_pv = top_all.pivot_table(index="topic_id", columns="rank", values="weight", aggfunc="first")
        m_pv = top_all.pivot_table(index="topic_id", columns="rank", values="mass", aggfunc="first")

        files_pv.columns = [f"top{r}_file" for r in files_pv.columns]
        w_pv.columns = [f"top{r}_weight" for r in w_pv.columns]
        m_pv.columns = [f"top{r}_mass" for r in m_pv.columns]

        agg = pd.concat([files_pv, w_pv, m_pv], axis=1).reset_index()
        cb_aug = cb.merge(agg, on="topic_id", how="left")
        out_cb = os.path.join(args.outdir, "codebook_aug_mass.csv")
        cb_aug.to_csv(out_cb, index=False, sep=";", encoding="utf-8")
        print(f"Gespeichert: {out_cb}")


if __name__ == "__main__":
    main()