import re
import pandas as pd
from collections import defaultdict
from sqlalchemy import create_engine

# Verbindung
engine = create_engine('postgresql://DB_Verbindungsdaten')  # anpassen

# Stammdaten laden
person_df = pd.read_sql_table('person', engine)
koerperschaft_df = pd.read_sql_table('koerperschaft', engine)

# Normalisierung: Trim, NBSP -> Space, Mehrfach-Leerzeichen reduzieren
def normalize(s):
    if pd.isna(s):
        return None
    s = str(s).replace('\u00A0', ' ')        # no-break space
    s = ' '.join(s.strip().split())          # trim + collapse whitespace
    return s if s else None

# Mapping-Dict aus mehreren Namensspalten (z. B. *_name und *_name_gnd) bauen
def build_mapping(df, name_cols, id_col):
    m = {}
    for _, row in df.iterrows():
        ent_id = row.get(id_col)
        for c in name_cols:
            if c in df.columns:
                k = normalize(row.get(c))
                if k:
                    m[k] = ent_id
    return m

# Dublettenwarnung (nach Normalisierung)
def warn_dups(df, name_cols, id_col, label):
    frames = []
    for c in name_cols:
        if c in df.columns:
            t = df[[id_col, c]].copy()
            t['name_key'] = t[c].apply(normalize)
            frames.append(t[[id_col, 'name_key']])
    if not frames:
        return
    all_names = pd.concat(frames, ignore_index=True).dropna(subset=['name_key'])
    dups = all_names.duplicated(subset=['name_key'], keep=False)
    if dups.any():
        print(f"Warnung: doppelte {label}-Namen (nach Normalisierung) – Beispiel:")
        print(all_names.loc[dups].head(20))

# Mappings aufbauen (nutzt sowohl *_name als auch *_name_gnd)
person_mapping = build_mapping(person_df, ['person_name', 'person_name_gnd'], 'person_id')
koerperschaft_mapping = build_mapping(koerperschaft_df, ['koerperschaft_name', 'koerperschaft_name_gnd'], 'koerperschaft_id')

warn_dups(person_df, ['person_name', 'person_name_gnd'], 'person_id', 'Personen')
warn_dups(koerperschaft_df, ['koerperschaft_name', 'koerperschaft_name_gnd'], 'koerperschaft_id', 'Körperschaften')

# CSVs laden
buch_df = pd.read_csv(
    r'Pfadzu\Konsolidierte\upload\DNB_KE_2008_2023_bereinigt_kk_pk.csv', # Pfad anpassen
    sep=';', encoding='utf-8', dtype={'isbn': 'string'}
)
literaturzeitschrift_df = pd.read_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturzeitschrift_kk_pk.csv', # Pfad anpassen
    sep=';', encoding='utf-8'
)
literaturzeitschrift_ausgabe_df = pd.read_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturzeitschrift_Ausgabe_kk_pk.csv', # Pfad anpassen
    sep=';', encoding='utf-8'
)
literaturwettbewerb_df = pd.read_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturwettbewerb_kk_pk.csv', # Pfad anpassen
    sep=';', encoding='utf-8'
)
literaturwettbewerb_ausgabe_df = pd.read_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturwettbewerb_Ausgabe_kk_pk.csv', # Pfad anpassen
    sep=';', encoding='utf-8'
)
plattform_internet_df = pd.read_csv(
    r'Pfadzu\Konsolidierte\upload\Plattform_Internet_kk_pk.csv', # Pfad anpassen
    sep=';', encoding='utf-8'
)

# Platzhalter, die ignoriert werden sollen
PLACEHOLDERS = {None, '', 'keine info', 'k.a.', 'n/a', '?', '-', '—', 'na', 'k. a.', 'k.a'}
ID_PATTERN = re.compile(r'^[PK]\d+$')

missing_by_col = defaultdict(set)
stats_by_col = defaultdict(lambda: {'tokens': 0, 'matched': 0, 'missing': 0})

def map_names_to_ids(name_string, col_label):
    if pd.isna(name_string) or str(name_string).strip() == '':
        return ''
    parts = [normalize(p) for p in str(name_string).split(';')]
    parts = [p for p in parts if p and (p.lower() not in PLACEHOLDERS)]
    out_ids = []
    for p in parts:
        stats_by_col[col_label]['tokens'] += 1
        # Bereits vorhandene IDs (P.../K...) durchreichen
        if ID_PATTERN.match(p):
            out_ids.append(p)
            stats_by_col[col_label]['matched'] += 1
            continue
        pid = person_mapping.get(p)
        kid = koerperschaft_mapping.get(p)
        if pid:
            out_ids.append(str(pid))
            stats_by_col[col_label]['matched'] += 1
        elif kid:
            out_ids.append(str(kid))
            stats_by_col[col_label]['matched'] += 1
        else:
            missing_by_col[col_label].add(p)
            stats_by_col[col_label]['missing'] += 1
    return '; '.join(out_ids)

def apply_map(df, candidate_cols):
    """Wendet Mapping auf die erste existierende Spalte aus candidate_cols an und gibt den Spaltennamen zurück."""
    for col in candidate_cols:
        if col in df.columns:
            df[col] = df[col].apply(lambda x: map_names_to_ids(x, col))
            return col
    return None

# Buch: deine Spaltennamen mit Großbuchstaben/Umlauten
apply_map(buch_df, ['Publisher'])
apply_map(buch_df, ['Verfasser'])
apply_map(buch_df, ['Herausgeber'])
apply_map(buch_df, ['Übersetzer'])
apply_map(buch_df, ['keineRolle'])
apply_map(buch_df, ['sonstigeRolle'])

# Literaturzeitschrift (verschiedene mögliche Header-Varianten abdecken)
apply_map(literaturzeitschrift_df, ['literaturzeitschrift_creator', 'creator'])
apply_map(literaturzeitschrift_df, ['literaturzeitschriftverlegtvon', 'literaturzeitschrift_verlegtvon', 'zeitschriftverlegtvon'])

# Literaturzeitschrift_Ausgabe (mit/ohne Umlaut)
apply_map(literaturzeitschrift_ausgabe_df, ['verfasser_ke_beitraege', 'verfasser_ke_beiträge'])

# Literaturwettbewerb
apply_map(literaturwettbewerb_df, ['veranstalter'])
apply_map(literaturwettbewerb_df, ['jury_2023', 'jury2023'])

# Literaturwettbewerb_Ausgabe
apply_map(literaturwettbewerb_ausgabe_df, ['gewinner'])
apply_map(literaturwettbewerb_ausgabe_df, ['jury'])

# Plattform_Internet (verschiedene mögliche Header)
apply_map(plattform_internet_df, ['unternehmen', 'plattform_creator', 'gruender_betreiber'])

# CSVs schreiben (überschreiben die Eingabedateien mit den gemappten IDs in den genannten Spalten)
buch_df.to_csv(
    r'Pfadzu\Konsolidierte\upload\DNB_KE_2008_2023_bereinigt_kk_pk_id.csv', # Pfad anpassen
    sep=';', index=False, encoding='utf-8'
)
literaturzeitschrift_df.to_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturzeitschrift_kk_pk_id.csv', # Pfad anpassen
    sep=';', index=False, encoding='utf-8'
)
literaturzeitschrift_ausgabe_df.to_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturzeitschrift_Ausgabe_kk_pk_id.csv', # Pfad anpassen
    sep=';', index=False, encoding='utf-8'
)
literaturwettbewerb_df.to_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturwettbewerb_kk_pk_id.csv', # Pfad anpassen
    sep=';', index=False, encoding='utf-8'
)
literaturwettbewerb_ausgabe_df.to_csv(
    r'Pfadzu\Konsolidierte\upload\Literaturwettbewerb_Ausgabe_kk_pk_id.csv', # Pfad anpassen
    sep=';', index=False, encoding='utf-8'
)
plattform_internet_df.to_csv(
    r'Pfadzu\Konsolidierte\upload\Plattform_Internet_kk_pk_id.csv', # Pfad anpassen
    sep=';', index=False, encoding='utf-8'
)

# Missing-Logs je Spalte ausgeben
base_out = r'Pfadzu\Konsolidierte\upload\missing_by_column' # Pfad anpassen
for col, vals in missing_by_col.items():
    if vals:
        pd.Series(sorted(vals)).to_csv(f'{base_out}_{col}.csv', index=False, encoding='utf-8')

# Zusammenfassung
total_missing = sum(s['missing'] for s in stats_by_col.values())
total_tokens = sum(s['tokens'] for s in stats_by_col.values())
print(f'Tokens gesamt: {total_tokens:,} | gematcht: {total_tokens - total_missing:,} | fehlend: {total_missing:,}')
for col, s in stats_by_col.items():
    if s['tokens'] == 0:
        continue
    rate = 100 * s['matched'] / s['tokens']
    print(f'{col}: Tokens={s["tokens"]:,}, gematcht={s["matched"]:,} ({rate:.1f}%), fehlend={s["missing"]:,}')