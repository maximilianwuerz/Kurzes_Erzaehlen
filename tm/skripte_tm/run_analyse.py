#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import argparse
import pandas as pd
import numpy as np

SEG_MAP = {
    "B": "Buch",
    "LZ": "Literaturzeitschrift",
    "LW": "Literaturwettbewerb",
    "OP": "Online-Plattform",
}


def parse_meta(path: str) -> pd.Series:
    # Entferne evtl. "file:/" Präfix
    p = re.sub(r"^file:/+", "", str(path))
    name = os.path.basename(p)
    stem = re.sub(r"\.txt$", "", name, flags=re.IGNORECASE)
    parts = stem.split("_")

    # Erwartet: [jahr, seg_code, seg_info, autor, titel..., 'pp']
    year = int(parts[0]) if len(parts) > 0 and parts[0].isdigit() else None
    seg_code = parts[1] if len(parts) > 1 else None
    seg_info = parts[2] if len(parts) > 2 else ""
    author = parts[3] if len(parts) > 3 else ""

    # Titel: alle Teile ab Index 4 bis (vor) 'pp'
    rest = parts[4:] if len(parts) > 4 else []
    if rest and rest[-1].lower().startswith("pp"):
        rest = rest[:-1]
    title = " ".join(rest)

    # Schönmachen
    author = author.replace("-", " ")
    title = title.replace("-", " ")
    segment = SEG_MAP.get(seg_code, seg_code)

    return pd.Series(
        dict(
            year=year,
            segmentcode=seg_code,
            segment=segment,
            segmentinfo=seg_info,
            author=author,
            title=title,
        )
    )


def run_analysis(
    doctopics: str,
    codebook: str,
    outdir: str,
    tau: float = 0.02,
    delta: float = 0.40,
    minmax: float = 0.20,
    delta_sweep: bool = False,
) -> None:
    os.makedirs(outdir, exist_ok=True)

    # 1) MALLET doc_topics laden (dichtes Format): [docidx, docpath, t0..tK-1]
    dt = pd.read_csv(doctopics, sep="\t", header=None, engine="python")
    K = dt.shape[1] - 2
    topic_cols = [f"t{i}" for i in range(K)]
    dt.columns = ["docidx", "docpath"] + topic_cols

    # 2) Metadaten aus Dateinamen
    meta = dt["docpath"].apply(parse_meta)
    df = pd.concat([dt, meta], axis=1)

    # 3) Codebook laden/prüfen
    cb = pd.read_csv(codebook, sep=";")
    cb.columns = [c.strip().lower() for c in cb.columns]

    # Spalten vereinheitlichen
    if "topic_id" not in cb.columns and "topicid" in cb.columns:
        cb = cb.rename(columns={"topicid": "topic_id"})
    if "topic_id" not in cb.columns:
        raise ValueError("Codebook muss eine Spalte 'topic_id' (oder 'topicid') enthalten.")

    # Notes-Regel: notes==0 -> 'unklar'
    if "notes" in cb.columns:
        cb["notes"] = pd.to_numeric(cb["notes"], errors="coerce").fillna(0).astype(int)
        if "kategorie" in cb.columns:
            cb.loc[cb["notes"] == 0, "kategorie"] = "unklar"

    # Kategorie prüfen
    if "kategorie" not in cb.columns:
        raise ValueError("Codebook muss eine Spalte 'kategorie' enthalten (krit/unt/unklar).")
    cb["kategorie"] = cb["kategorie"].astype(str).str.lower().fillna("unklar")

    # Gültige Topics (0..K-1)
    cb["topic_id"] = pd.to_numeric(cb["topic_id"], errors="coerce").astype("Int64")
    cb = cb[(cb["topic_id"].notna()) & (cb["topic_id"] >= 0) & (cb["topic_id"] < K)].copy()
    cb["topic_id"] = cb["topic_id"].astype(int)

    krit_ids = cb.loc[cb["kategorie"] == "krit", "topic_id"].tolist()
    unt_ids = cb.loc[cb["kategorie"] == "unt", "topic_id"].tolist()
    print(f"Codebuch: krit-Topics = {len(krit_ids)}, unt-Topics = {len(unt_ids)} (von K={K})")

    # 4) Rauschen kappen (tau) und pkrit/punt berechnen (array-basiert, performant)
    vals = df[topic_cols].astype(float).to_numpy(copy=False)
    vals_masked = np.where(vals >= tau, vals, 0.0)

    if len(krit_ids) > 0:
        krit_idx = np.array(krit_ids, dtype=int)
        pkrit = vals_masked[:, krit_idx].sum(axis=1)
    else:
        pkrit = np.zeros(len(df), dtype=float)

    if len(unt_ids) > 0:
        unt_idx = np.array(unt_ids, dtype=int)
        punt = vals_masked[:, unt_idx].sum(axis=1)
    else:
        punt = np.zeros(len(df), dtype=float)

    df["pkrit"] = pkrit
    df["punt"] = punt
    df["diff"] = df["pkrit"] - df["punt"]

    # 5) Dominanz (vektorisiert)
    m = np.maximum(df["pkrit"].to_numpy(), df["punt"].to_numpy())
    conds = [
        (df["pkrit"].to_numpy() - df["punt"].to_numpy() >= delta) & (m >= minmax),
        (df["punt"].to_numpy() - df["pkrit"].to_numpy() >= delta) & (m >= minmax),
    ]
    choices = ["dominant_kritisch", "dominant_unterhaltend"]
    df["klassifikation"] = np.select(conds, choices, default="keine_dominanz")

    # 6) Ausgaben
    out_docs = os.path.join(outdir, "dok_kennzahlen.csv")
    cols_out = [
        "docidx",
        "docpath",
        "year",
        "segmentcode",
        "segment",
        "author",
        "title",
        "pkrit",
        "punt",
        "diff",
        "klassifikation",
    ]
    df.loc[:, cols_out].to_csv(out_docs, index=False, encoding="utf-8")
    print(f"Gespeichert: {out_docs}")

    # Summary gesamt
    summ = df["klassifikation"].value_counts().rename_axis("klasse").reset_index(name="n")
    summ["anteil"] = summ["n"] / len(df)
    out_overall = os.path.join(outdir, "summary_overall.csv")
    summ.to_csv(out_overall, index=False, encoding="utf-8")
    print(f"Gespeichert: {out_overall}")

    # Summary nach Segment
    seg = (
        df.groupby(["segmentcode", "segment"], dropna=False)
        .agg(
            n=("docidx", "count"),
            pkrit_mean=("pkrit", "mean"),
            punt_mean=("punt", "mean"),
            domkrit_n=("klassifikation", lambda s: (s == "dominant_kritisch").sum()),
            domunt_n=("klassifikation", lambda s: (s == "dominant_unterhaltend").sum()),
        )
        .reset_index()
    )
    seg["domkrit_anteil"] = seg["domkrit_n"] / seg["n"]
    seg["domunt_anteil"] = seg["domunt_n"] / seg["n"]
    out_seg = os.path.join(outdir, "summary_by_segment.csv")
    seg.to_csv(out_seg, index=False, encoding="utf-8")
    print(f"Gespeichert: {out_seg}")

    # Optional: Delta-Sweep
    if delta_sweep:
        print("\nDelta-Sweep (Anteile):")
        for d in [0.30, 0.35, 0.40, 0.45]:
            conds_d = [
                (df["pkrit"].to_numpy() - df["punt"].to_numpy() >= d) & (m >= minmax),
                (df["punt"].to_numpy() - df["pkrit"].to_numpy() >= d) & (m >= minmax),
            ]
            klass_d = np.select(conds_d, ["krit", "unt"], default="keine")
            vc = pd.Series(klass_d).value_counts(normalize=True)
            print(f"  delta={d:.2f}: krit={float(vc.get('krit', 0.0)):.3f}, unt={float(vc.get('unt', 0.0)):.3f}, keine={float(vc.get('keine', 0.0)):.3f}")


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Berechnet pkrit/punt und Klassifikation aus MALLET doc_topics + Codebook."
    )
    ap.add_argument("--doctopics", required=True, help="Pfad zu MALLET doc_topics.txt (dichtes Format)")
    ap.add_argument("--codebook", required=True, help="Pfad zum Codebook (CSV, ; als Trenner)")
    ap.add_argument("--outdir", required=True, help="Ausgabeordner")
    ap.add_argument("--tau", type=float, default=0.02, help="Rauschschwelle für Topic-Anteile (default: 0.02)")
    ap.add_argument("--delta", type=float, default=0.40, help="Dominanzschwelle |pkrit - punt| (default: 0.40)")
    ap.add_argument("--minmax", type=float, default=0.20, help="Minimalstärke max(pkrit, punt) (default: 0.20)")
    ap.add_argument("--delta_sweep", action="store_true", help="Zusatz-Ausgabe der Anteile für mehrere Delta-Werte")
    return ap.parse_args()


def main():
    args = parse_args()
    run_analysis(
        doctopics=args.doctopics,
        codebook=args.codebook,
        outdir=args.outdir,
        tau=args.tau,
        delta=args.delta,
        minmax=args.minmax,
        delta_sweep=args.delta_sweep,
    )


if __name__ == "__main__":
    main()