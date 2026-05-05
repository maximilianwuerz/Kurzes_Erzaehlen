#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import argparse
import pandas as pd
import numpy as np


def parse_meta(path: str) -> pd.Series:
    p = re.sub(r"^file:/+", "", str(path))
    name = os.path.basename(p)
    stem = re.sub(r"\.txt$", "", name, flags=re.IGNORECASE)
    parts = stem.split("_")

    year = int(parts[0]) if len(parts) > 0 and parts[0].isdigit() else None
    seg_code = parts[1] if len(parts) > 1 else None
    seg_info = parts[2] if len(parts) > 2 else ""
    author = parts[3] if len(parts) > 3 else ""
    rest = parts[4:] if len(parts) > 4 else []
    if rest and rest[-1].lower().startswith("pp"):
        rest = rest[:-1]
    title = " ".join(rest)
    return pd.Series(dict(year=year, segmentcode=seg_code, segmentinfo=seg_info,
                          author=author.replace("-", " "), title=title.replace("-", " ")))


def get_top_docs_for_topic(df: pd.DataFrame, topic_col: str, n: int = 3, tau: float = 0.02) -> pd.DataFrame:
    # Zuerst mit Schwelle tau filtern; falls zu wenige, ohne Schwelle auffüllen
    sub = df.loc[df[topic_col] >= tau, ["docidx", "docpath", topic_col, "year", "segmentcode", "author", "title"]]
    sub = sub.sort_values(topic_col, ascending=False).head(n)
    if len(sub) < n:
        # Auffüllen ohne tau-Filter
        add = df.loc[:, ["docidx", "docpath", topic_col, "year", "segmentcode", "author", "title"]].sort_values(
            topic_col, ascending=False
        )
        add = add[~add["docidx"].isin(sub["docidx"])].head(n - len(sub))
        sub = pd.concat([sub, add], ignore_index=True)
    sub = sub.reset_index(drop=True)
    sub["rank"] = np.arange(1, len(sub) + 1)
    sub = sub.rename(columns={topic_col: "weight"})
    return sub[["rank", "docidx", "docpath", "year", "segmentcode", "author", "title", "weight"]]


def main():
    ap = argparse.ArgumentParser(description="Top-N Dokumente je Topic ermitteln und ins Codebuch mappen.")
    ap.add_argument("--doctopics", required=True, help="Pfad zu MALLET doc_topics.txt (dichtes Format)")
    ap.add_argument("--codebook", required=True, help="Pfad zum Codebuch (CSV, ; als Trenner)")
    ap.add_argument("--outdir", required=True, help="Ausgabeordner")
    ap.add_argument("--topics", default="", help="Kommagetrennte Topic-IDs (z. B. 4,5,12). Leer = alle krit/unt aus Codebuch")
    ap.add_argument("--n", type=int, default=3, help="Top-N Dokumente pro Topic (Default: 3)")
    ap.add_argument("--tau", type=float, default=0.02, help="Schwelle für Topic-Anteil (Default: 0.02)")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    # 1) doc_topics laden (dicht: [docidx, docpath, t0..tK-1])
    dt = pd.read_csv(args.doctopics, sep="\t", header=None, engine="python")
    K = dt.shape[1] - 2
    topic_cols = [f"t{i}" for i in range(K)]
    dt.columns = ["docidx", "docpath"] + topic_cols

    # 2) Metadaten aus Dateinamen
    meta = dt["docpath"].apply(parse_meta)
    df = pd.concat([dt, meta], axis=1)

    # 3) Codebuch laden
    cb = pd.read_csv(args.codebook, sep=";")
    cb.columns = [c.strip().lower() for c in cb.columns]
    if "topic_id" not in cb.columns and "topicid" in cb.columns:
        cb = cb.rename(columns={"topicid": "topic_id"})
    if "topic_id" not in cb.columns:
        raise ValueError("Codebook braucht 'topic_id' (oder 'topicid').")
    cb["topic_id"] = pd.to_numeric(cb["topic_id"], errors="coerce").astype("Int64")
    cb = cb[cb["topic_id"].notna()].copy()
    cb["topic_id"] = cb["topic_id"].astype(int)

    # Topics wählen
    if args.topics.strip():
        topic_ids = [int(x) for x in re.split(r"[,\s]+", args.topics.strip()) if x != ""]
    else:
        if "kategorie" in cb.columns:
            topic_ids = cb.loc[cb["kategorie"].str.lower().isin(["krit", "unt"]), "topic_id"].tolist()
        else:
            topic_ids = cb["topic_id"].tolist()

    # 4) Top-N pro Topic ermitteln
    rows = []
    for tid in topic_ids:
        if tid < 0 or tid >= K:
            continue
        col = f"t{tid}"
        topdf = get_top_docs_for_topic(df, col, n=args.n, tau=args.tau)
        topdf.insert(0, "topic_id", tid)
        rows.append(topdf.assign(topic_col=col))
    if not rows:
        raise RuntimeError("Keine validen Topics gefunden.")
    top_all = pd.concat(rows, ignore_index=True)

    # 5) Übersicht ausgeben
    out_top = os.path.join(args.outdir, "topic_topdocs.csv")
    top_all.to_csv(out_top, index=False, encoding="utf-8")
    print(f"Gespeichert: {out_top}")

    # 6) Codebuch anreichern: top1_file/weight ... topN_file/weight
    agg = top_all.pivot_table(index="topic_id", columns="rank",
                              values=["docpath", "weight"], aggfunc="first")
    # Spalten umbenennen
    agg.columns = [f"top{r}_{name}" for name, r in agg.columns]
    agg = agg.reset_index()

    cb_aug = cb.merge(agg, on="topic_id", how="left")
    out_cb = os.path.join(args.outdir, "codebook_aug.csv")
    cb_aug.to_csv(out_cb, index=False, sep=";", encoding="utf-8")
    print(f"Gespeichert: {out_cb}")


if __name__ == "__main__":
    main()