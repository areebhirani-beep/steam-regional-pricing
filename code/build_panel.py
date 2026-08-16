#!/usr/bin/env python3
"""
Build the title x language x week panel of Steam review flow.

Streams one (appid, language) file at a time so memory stays flat regardless of
sample size. For each cell it:
  1. aggregates reviews to weeks (Mondays, computed by explicit arithmetic;
     do NOT use to_period("W-MON"), whose start_time does not align with a
     date_range on the same alias and silently produces an all-NaN reindex),
  2. trims two weeks from the start and one from the end of the retrieved
     window, since pagination edges are unreliable,
  3. fills interior weeks with zero,
  4. drops cells with fewer than eight trustworthy weeks.

Outcome:  n           review count, the demand proxy
Also:     share_nonsteam  non-Steam key activations, the gray-market margin
          share_pos       satisfaction
          med_playtime    engagement / selection on intensity
          med_games_owned reviewer library size
"""
import json, glob, os, sys
import pandas as pd, numpy as np

HERE = os.path.dirname(__file__)
RAW  = os.path.join(HERE, "..", "data", "raw", "steam_reviews")
META = os.path.join(HERE, "..", "data", "raw", "steam_meta.json")
OUT  = os.path.join(HERE, "..", "data", "interim")
EVENT = pd.Timestamp("2023-11-20")
MIN_WEEKS = 8


def monday(ts):
    ts = pd.Timestamp(ts).normalize()
    return ts - pd.Timedelta(days=ts.dayofweek)


def cell_frame(path):
    recs = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                recs.append(json.loads(line))
            except json.JSONDecodeError:      # a worker may still be writing
                continue
    if not recs:
        return None, None
    d = pd.DataFrame(recs)
    d["dt"] = pd.to_datetime(d.ts, unit="s", utc=True).dt.tz_convert(None)
    first, last = d.dt.min(), d.dt.max()
    d["week"] = (d.dt.dt.normalize()
                 - pd.to_timedelta(d.dt.dt.normalize().dt.dayofweek, unit="D"))
    g = (d.groupby("week")
           .agg(n=("rid", "size"),
                share_pos=("up", "mean"),
                share_nonsteam=("steam_purchase", lambda s: 1 - np.nanmean(s.astype(float))),
                med_playtime=("pt_at_review", "median"),
                med_games_owned=("n_games", "median")))
    lo = monday(first + pd.Timedelta(days=14))
    hi = monday(last - pd.Timedelta(days=7))
    if (hi - lo).days < MIN_WEEKS * 7:
        return None, (first, last)
    idx = pd.date_range(lo, hi, freq="7D")
    s = g.reindex(idx)
    if not s["n"].notna().any():
        return None, (first, last)
    s["n"] = s["n"].fillna(0)
    s.index.name = "week"
    return s.reset_index(), (first, last)


def main():
    meta = json.load(open(META))
    m = pd.DataFrame([{"appid": int(k), "name": v.get("name"), "is_free": v.get("is_free"),
                       "us_price": ((v.get("prices", {}).get("us") or {}).get("final") or 0) / 100,
                       "tr_price_now": ((v.get("prices", {}).get("tr") or {}).get("final") or 0) / 100,
                       "genres": ",".join(v.get("genres") or [])}
                      for k, v in meta.items() if v.get("name")])

    files = sorted(glob.glob(os.path.join(RAW, "*.jsonl")))
    print(f"streaming {len(files):,} cell files", flush=True)
    frames, cov, kept, dropped = [], [], 0, 0
    for i, f in enumerate(files, 1):
        base = os.path.basename(f)[:-6]
        appid, lang = base.split("_", 1)
        fr, rng = cell_frame(f)
        if rng:
            cov.append({"appid": int(appid), "language": lang, "first": rng[0], "last": rng[1]})
        if fr is None:
            dropped += 1
            continue
        fr["appid"] = int(appid); fr["language"] = lang
        frames.append(fr); kept += 1
        if i % 1000 == 0:
            print(f"  {i:,}/{len(files):,}  kept {kept:,} dropped {dropped:,}", flush=True)

    print(f"cells kept {kept:,} / dropped {dropped:,}")
    assert kept > 0.5 * (kept + dropped), "more than half of all cells failed to build"

    pd.DataFrame(cov).to_csv(os.path.join(OUT, "coverage.csv"), index=False)
    p = pd.concat(frames, ignore_index=True).merge(m, on="appid", how="left")
    miss = sorted(p.loc[p.is_free.isna(), "appid"].unique())
    if miss:
        print(f"dropping {len(miss)} titles with no store metadata")
        p = p[p.is_free.notna()].copy()
    p["is_free"] = p.is_free.astype(bool)
    p["treated_lang"] = (p.language == "turkish").astype(int)
    p["post"] = (p.week >= EVENT).astype(int)
    p["paid"] = (~p.is_free).astype(int)
    p["log_n"] = np.log(p.n + 1)
    ev = monday(EVENT)
    p["rel_week"] = ((p.week - ev).dt.days // 7).astype(int)

    p.to_parquet(os.path.join(OUT, "panel_weekly.parquet"), index=False)
    p.to_csv(os.path.join(OUT, "panel_weekly.csv"), index=False)
    print("panel rows:", f"{len(p):,}")
    print("titles:", p.appid.nunique(), "| languages:", p.language.nunique())
    print("reviews in panel:", f"{int(p.n.sum()):,}")
    print("week range:", p.week.min().date(), "->", p.week.max().date())


if __name__ == "__main__":
    main()
