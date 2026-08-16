#!/usr/bin/env python3
"""
Export the SteamSpy frame to CSV so the review-flow proxy can be validated
against an independent estimate of units.

SteamSpy publishes an owner-count estimate per title (a bucketed range) built
from a different method than review counts. Regressing log owners on log
reviews gives the reviews-to-units mapping, its dispersion, and whether it is
stable across genres and price tiers. That is the validation the paper needs
and could not previously supply.
"""
import json, glob, os, csv

HERE = os.path.dirname(__file__)
SS = os.path.join(HERE, "..", "data", "raw", "steamspy")
OUT = os.path.join(HERE, "..", "data", "interim", "steamspy_frame.csv")


def owners_bounds(s):
    try:
        lo, hi = [int(x.replace(",", "").strip()) for x in s.split("..")]
        return lo, hi
    except Exception:
        return None, None


def main():
    rows = {}
    for f in sorted(glob.glob(os.path.join(SS, "all_*.json"))):
        rows.update(json.load(open(f)))
    sample = {c["appid"] for c in json.load(
        open(os.path.join(HERE, "..", "data", "interim", "sample.json")))}
    n = 0
    with open(OUT, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["appid", "name", "in_sample", "price_cents", "is_free",
                    "owners_lo", "owners_hi", "owners_mid", "positive", "negative",
                    "reviews_total", "ccu", "genre"])
        for aid, v in rows.items():
            lo, hi = owners_bounds(v.get("owners", ""))
            if lo is None:
                continue
            try:
                price = int(v.get("price") or 0)
            except Exception:
                price = 0
            pos = int(v.get("positive") or 0); neg = int(v.get("negative") or 0)
            w.writerow([aid, v.get("name"), int(int(aid) in sample), price, int(price == 0),
                        lo, hi, (lo + hi) / 2, pos, neg, pos + neg,
                        int(v.get("ccu") or 0), v.get("genre", "")])
            n += 1
    print(f"wrote {n:,} titles to {OUT}")


if __name__ == "__main__":
    main()
