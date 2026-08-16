#!/usr/bin/env python3
"""
Resolve self-reported country for a random sample of Steam users who wrote
Latin-American Spanish reviews.

Why: Steam's `latam` language tag pools Argentina, which Valve repriced UPWARD
on 20 Nov 2023, with Mexico, Colombia, Chile and others, which it repriced
DOWNWARD on the same date. Without separating them the two treatments cancel.
Steam Community profiles expose a public, user-set <location> field.

Design: we sample USERS uniformly at random, not reviews. Every sampled user's
entire review history enters, so the classified series is an unbiased scaled
copy of the true country series, and the scaling constant is absorbed by the
title-by-country fixed effect in logs.

Only the country string is retained. No profile names, avatars, or any other
personal field is stored, and nothing is reported below the country-month level.
"""
import json, os, re, sys, time, random
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

UA = {"User-Agent": "AreebHirani-HSResearch areeb.research@gmail.com"}
HERE = os.path.dirname(__file__)
IDS = os.path.join(HERE, "..", "data", "interim", "latam_steamids.json")
OUT = os.path.join(HERE, "..", "data", "interim", "user_country.json")

LOC = re.compile(r"<location>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</location>", re.S)


def country(sid):
    """Return the last comma-separated component of the profile location, or ''."""
    for _ in range(2):
        try:
            r = requests.get(f"https://steamcommunity.com/profiles/{sid}",
                             params={"xml": 1}, headers=UA, timeout=25)
            if r.status_code != 200:
                time.sleep(2); continue
            m = LOC.search(r.text)
            if not m:
                return ""
            loc = m.group(1).strip()
            return loc.split(",")[-1].strip() if loc else ""
        except Exception:
            time.sleep(2)
    return None


def main(n_sample=120000, workers=12):
    ids = json.load(open(IDS))
    random.seed(20231120)
    random.shuffle(ids)
    ids = ids[:n_sample]
    out = json.load(open(OUT)) if os.path.exists(OUT) else {}
    todo = [i for i in ids if i not in out]
    print(f"sample {len(ids):,} users; {len(out):,} cached; resolving {len(todo):,}", flush=True)

    t0, done = time.time(), 0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(country, i): i for i in todo}
        for fut in as_completed(futs):
            sid = futs[fut]
            c = fut.result()
            if c is not None:
                out[sid] = c
            done += 1
            if done % 2000 == 0:
                el = time.time() - t0
                have = sum(1 for v in out.values() if v)
                print(f"  {done:,}/{len(todo):,}  ({el:.0f}s, {done/max(el,1):.1f}/s) "
                      f"with-country {have:,}", flush=True)
                json.dump(out, open(OUT, "w"))
    json.dump(out, open(OUT, "w"))
    have = {k: v for k, v in out.items() if v}
    print(f"resolved {len(out):,}; {len(have):,} have a country "
          f"({100*len(have)/max(len(out),1):.0f}%)")
    from collections import Counter
    for c, n in Counter(have.values()).most_common(12):
        print(f"   {c:<28} {n:,}")


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 120000)
