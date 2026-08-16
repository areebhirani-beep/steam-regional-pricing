#!/usr/bin/env python3
"""
Build the sampling frame and select the estimation sample.

Frame:   SteamSpy `all` pages (top titles by owner estimate), cached under
         data/raw/steamspy/. Gives owners, price, positive/negative review
         counts, ccu, genre, tags.
Screen:  one request per title to Steam's review endpoint returns the title's
         *lifetime Turkish review count* in query_summary. ~1.5s per title.
Select:  titles with enough Turkish volume to identify a monthly series, and
         enough total volume to be economically meaningful, stratified across
         price tiers and including free-to-play titles as the control arm.
"""
import json, glob, os, sys, time, random
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

UA = {"User-Agent": "AreebHirani-HSResearch areeb.research@gmail.com"}
HERE = os.path.dirname(__file__)
SS = os.path.join(HERE, "..", "data", "raw", "steamspy")
OUT = os.path.join(HERE, "..", "data", "interim")


def load_frame():
    rows = {}
    for f in sorted(glob.glob(os.path.join(SS, "all_*.json"))):
        rows.update(json.load(open(f)))
    return rows


def owners_mid(s):
    try:
        lo, hi = [int(x.replace(",", "").strip()) for x in s.split("..")]
        return (lo + hi) / 2
    except Exception:
        return None


def turkish_total(appid, tries=3):
    for _ in range(tries):
        try:
            r = requests.get(f"https://store.steampowered.com/appreviews/{appid}",
                             params={"json": 1, "filter": "recent", "language": "turkish",
                                     "num_per_page": 1, "cursor": "*"},
                             headers=UA, timeout=30)
            if r.status_code == 200:
                return r.json().get("query_summary", {}).get("total_reviews")
        except Exception:
            pass
        time.sleep(1.5)
    return None


def main(min_turkish=400, target=600, workers=12):
    frame = load_frame()
    print(f"frame: {len(frame):,} titles")

    cand = []
    for aid, v in frame.items():
        try:
            price = int(v.get("price") or 0)
        except Exception:
            price = 0
        pos = int(v.get("positive") or 0); neg = int(v.get("negative") or 0)
        own = owners_mid(v.get("owners", ""))
        if pos + neg < 2000:            # need enough total volume for a monthly series
            continue
        cand.append({"appid": int(aid), "name": v.get("name"), "price_cents": price,
                     "is_free": price == 0, "owners_mid": own,
                     "pos": pos, "neg": neg, "ccu": int(v.get("ccu") or 0),
                     "genre": v.get("genre", "")})
    print(f"candidates with >=2,000 total reviews: {len(cand):,}")

    cache_f = os.path.join(OUT, "turkish_screen.json")
    screened = json.load(open(cache_f)) if os.path.exists(cache_f) else {}
    todo = [c for c in cand if str(c["appid"]) not in screened]
    print(f"screening {len(todo):,} titles for Turkish review volume ...")

    t0 = time.time()
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(turkish_total, c["appid"]): c for c in todo}
        for i, fut in enumerate(as_completed(futs), 1):
            c = futs[fut]
            screened[str(c["appid"])] = fut.result()
            if i % 250 == 0:
                el = time.time() - t0
                print(f"  {i:,}/{len(todo):,}  ({el:.0f}s, {i/max(el,1):.1f}/s)", flush=True)
                json.dump(screened, open(cache_f, "w"))
    json.dump(screened, open(cache_f, "w"))

    for c in cand:
        c["tr_reviews"] = screened.get(str(c["appid"])) or 0
    ok = [c for c in cand if c["tr_reviews"] >= min_turkish]
    print(f"titles with >= {min_turkish} Turkish reviews: {len(ok):,}")

    free = [c for c in ok if c["is_free"]]
    paid = [c for c in ok if not c["is_free"]]
    tiers = {"budget": [c for c in paid if c["price_cents"] < 1000],
             "mid":    [c for c in paid if 1000 <= c["price_cents"] < 2500],
             "premium":[c for c in paid if c["price_cents"] >= 2500]}
    print("  free:", len(free), "| budget:", len(tiers["budget"]),
          "| mid:", len(tiers["mid"]), "| premium:", len(tiers["premium"]))

    random.seed(20231120)
    sel = []
    n_free = min(len(free), max(60, target // 5))
    sel += sorted(free, key=lambda c: -c["tr_reviews"])[:n_free]
    per = (target - n_free) // 3
    for k, v in tiers.items():
        sel += sorted(v, key=lambda c: -c["tr_reviews"])[:per]
    sel = {c["appid"]: c for c in sel}
    json.dump(list(sel.values()), open(os.path.join(OUT, "sample.json"), "w"), indent=1)
    print(f"\nSELECTED {len(sel)} titles "
          f"({sum(1 for c in sel.values() if c['is_free'])} free, "
          f"{sum(1 for c in sel.values() if not c['is_free'])} paid)")
    print("appids written to data/interim/sample.json")


if __name__ == "__main__":
    main(min_turkish=int(sys.argv[1]) if len(sys.argv) > 1 else 400,
         target=int(sys.argv[2]) if len(sys.argv) > 2 else 600)
