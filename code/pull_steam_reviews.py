#!/usr/bin/env python3
"""
Pull Steam review histories by (appid, language) from the public appreviews endpoint.

No API key required. Endpoint documented at:
https://partner.steamgames.com/doc/store/getreviews

Each review carries: timestamp_created, language, voted_up, playtime_at_review,
steam_purchase (False => activated a non-Steam key, i.e. gray-market / retail key),
received_for_free, author.steamid, author.num_games_owned.

We paginate with the opaque cursor until we reach STOP_BEFORE or the cursor stalls.
Results are cached per (appid, language) as newline-delimited JSON so the pull is resumable.
"""
import requests, json, time, os, sys, datetime as dt

UA = {"User-Agent": "AreebHirani-HSResearch areeb.research@gmail.com"}
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "steam_reviews")
STOP_BEFORE = dt.datetime(int(os.environ.get("STOP_YEAR", 2022)),
                          int(os.environ.get("STOP_MONTH", 1)), 1, tzinfo=dt.UTC).timestamp()
MAXPAGES = int(os.environ.get("MAXPAGES", 400))

S = requests.Session()
S.headers.update(UA)


def pull(appid, lang, stop_before=STOP_BEFORE, maxpages=MAXPAGES, verbose=False):
    cur, seen, out = "*", set(), []
    for i in range(maxpages):
        try:
            r = S.get(
                f"https://store.steampowered.com/appreviews/{appid}",
                params={"json": 1, "filter": "recent", "language": lang,
                        "num_per_page": 100, "cursor": cur,
                        "purchase_type": "all", "review_type": "all"},
                timeout=60)
            if r.status_code != 200:
                time.sleep(5); continue
            d = r.json()
        except Exception:
            time.sleep(5); continue
        rs = d.get("reviews", [])
        if not rs:
            break
        new = [x for x in rs if x["recommendationid"] not in seen]
        for x in new:
            seen.add(x["recommendationid"])
        out += new
        nc = d.get("cursor")
        oldest = min(x["timestamp_created"] for x in rs)
        if not new or not nc or nc == cur or oldest < stop_before:
            break
        cur = nc
        time.sleep(0.25)
    return out


def slim(x, appid, lang):
    a = x.get("author", {})
    return {
        "appid": appid, "language": lang,
        "rid": x["recommendationid"],
        "ts": x["timestamp_created"],
        "up": x["voted_up"],
        "steam_purchase": x.get("steam_purchase"),
        "free": x.get("received_for_free"),
        "early_access": x.get("written_during_early_access"),
        "pt_at_review": a.get("playtime_at_review"),
        "pt_forever": a.get("playtime_forever"),
        "n_games": a.get("num_games_owned"),
        "n_reviews": a.get("num_reviews"),
        "steamid": a.get("steamid"),
    }


def main(appids, langs):
    os.makedirs(OUT, exist_ok=True)
    for appid in appids:
        for lang in langs:
            f = os.path.join(OUT, f"{appid}_{lang}.jsonl")
            if os.path.exists(f) and os.path.getsize(f) > 0:
                print(f"cached {appid} {lang}", flush=True); continue
            rv = pull(appid, lang)
            with open(f, "w") as fh:
                for x in rv:
                    fh.write(json.dumps(slim(x, appid, lang)) + "\n")
            if rv:
                ts = [x["timestamp_created"] for x in rv]
                print(f"{appid} {lang}: n={len(rv)} "
                      f"{dt.datetime.fromtimestamp(min(ts), dt.UTC).date()} -> "
                      f"{dt.datetime.fromtimestamp(max(ts), dt.UTC).date()}", flush=True)
            else:
                print(f"{appid} {lang}: n=0", flush=True)


if __name__ == "__main__":
    APPIDS = [int(x) for x in sys.argv[1].split(",")]
    LANGS = sys.argv[2].split(",")
    main(APPIDS, LANGS)
