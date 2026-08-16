#!/usr/bin/env python3
"""
Build the game x language x week panel of Steam review flow.

Outcome:  n_reviews  (proxy for units sold, up to a game x language specific
          review-propensity constant that differences out in logs with FE)
Also:     share of non-Steam-key activations (steam_purchase == False)  -> gray-market margin
          share positive (voted_up)                                     -> satisfaction
          median playtime_at_review                                     -> engagement/selection
"""
import json, glob, os, sys
import pandas as pd, numpy as np

HERE = os.path.dirname(__file__)
RAW = os.path.join(HERE, "..", "data", "raw", "steam_reviews")
META = os.path.join(HERE, "..", "data", "raw", "steam_meta.json")
OUT = os.path.join(HERE, "..", "data", "interim")

EVENT = pd.Timestamp("2023-11-20", tz="UTC")   # Valve ends TRY/ARS pricing


def load_reviews():
    rows = []
    for f in sorted(glob.glob(os.path.join(RAW, "*.jsonl"))):
        with open(f) as fh:
            for line in fh:
                line = line.strip()
                if line:
                    rows.append(json.loads(line))
    df = pd.DataFrame(rows)
    df["dt"] = pd.to_datetime(df.ts, unit="s", utc=True)
    return df


def main():
    df = load_reviews()
    meta = json.load(open(META))
    m = pd.DataFrame([{"appid": int(k), "name": v["name"], "is_free": v["is_free"],
                       "us_price": ((v["prices"].get("us") or {}).get("final") or 0) / 100,
                       "tr_price_now": ((v["prices"].get("tr") or {}).get("final") or 0) / 100,
                       "genres": ",".join(v.get("genres") or [])}
                      for k, v in meta.items()])

    # ---- coverage diagnostics: per (appid,language) the earliest date actually retrieved -----
    cov = (df.groupby(["appid", "language"])
             .agg(n=("rid", "size"), first=("dt", "min"), last=("dt", "max"))
             .reset_index())
    cov.to_csv(os.path.join(OUT, "coverage.csv"), index=False)

    naive = df.dt.dt.tz_convert(None).dt.normalize()
    df["week"] = (naive - pd.to_timedelta(naive.dt.dayofweek, unit="D")).astype("datetime64[ns]")
    g = (df.groupby(["appid", "language", "week"])
           .agg(n=("rid", "size"),
                share_pos=("up", "mean"),
                share_nonsteam=("steam_purchase", lambda s: 1 - np.nanmean(s.astype(float))),
                share_free=("free", lambda s: np.nanmean(s.astype(float))),
                med_playtime=("pt_at_review", "median"),
                med_games_owned=("n_games", "median"))
           .reset_index())

    # balanced weekly grid within each (appid,language)'s observed coverage window
    frames = []
    for (a, l), sub in g.groupby(["appid", "language"]):
        c = cov[(cov.appid == a) & (cov.language == l)].iloc[0]
        # trust coverage only from 2 weeks after the earliest retrieved review (pagination edge)
        def monday(x):
            x = pd.Timestamp(x).tz_localize(None).normalize()
            return x - pd.Timedelta(days=x.dayofweek)
        lo = monday(c["first"] + pd.Timedelta(days=14))
        hi = monday(c["last"] - pd.Timedelta(days=7))
        if (hi - lo).days < 8 * 7:          # need >= 8 weeks of trustworthy coverage
            continue
        idx = pd.date_range(lo, hi, freq="7D").astype("datetime64[ns]")
        s = sub.set_index("week").reindex(idx)
        assert s["n"].notna().any(), f"reindex produced no matches for {a} {l}"
        s["appid"], s["language"] = a, l
        s["n"] = s["n"].fillna(0)
        s.index.name = "week"
        frames.append(s.reset_index())
    p = pd.concat(frames, ignore_index=True).merge(m, on="appid", how="left")
    miss = sorted(p.loc[p.is_free.isna(), "appid"].unique())
    if miss:
        print("WARNING: dropping games with no store metadata:", miss)
        p = p[p.is_free.notna()].copy()
    p["is_free"] = p.is_free.astype(bool)

    p["treated_lang"] = (p.language == "turkish").astype(int)
    p["post"] = (p.week >= EVENT.tz_localize(None)).astype(int)
    p["paid"] = (~p.is_free).astype(int)
    p["log_n"] = np.log(p.n + 1)
    ev = EVENT.tz_localize(None).normalize()
    ev = ev - pd.Timedelta(days=ev.dayofweek)
    p["rel_week"] = ((p.week - ev).dt.days // 7).astype(int)

    p.to_parquet(os.path.join(OUT, "panel_weekly.parquet"), index=False)
    p.to_csv(os.path.join(OUT, "panel_weekly.csv"), index=False)

    print("panel rows:", len(p))
    print("games:", p.appid.nunique(), "| languages:", sorted(p.language.unique()))
    print("week range:", p.week.min().date(), "->", p.week.max().date())
    print("\ncoverage (earliest retrieved review per cell):")
    print(cov.sort_values(["language", "appid"]).to_string(index=False))


if __name__ == "__main__":
    main()
