#!/usr/bin/env python3
"""Pull current Steam store metadata + prices for a set of appids across storefronts."""
import requests, json, time, os, sys

UA = {"User-Agent": "AreebHirani-HSResearch areeb.research@gmail.com"}
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "steam_meta.json")
CCS = ["us", "tr", "ar", "ru", "br", "pl", "de", "cn", "gb", "kz", "ua"]


def appdetails(appid, cc):
    r = requests.get("https://store.steampowered.com/api/appdetails",
                     params={"appids": appid, "cc": cc, "l": "english"},
                     headers=UA, timeout=60)
    d = r.json().get(str(appid), {})
    return d.get("data") if d.get("success") else None


def main(appids):
    out = {}
    if os.path.exists(OUT):
        out = json.load(open(OUT))
    for appid in appids:
        k = str(appid)
        if k in out:
            print("cached", appid); continue
        base = appdetails(appid, "us")
        if base is None:
            print("FAIL", appid); continue
        rec = {
            "appid": appid,
            "name": base.get("name"),
            "is_free": base.get("is_free"),
            "release_date": base.get("release_date", {}).get("date"),
            "genres": [g["description"] for g in base.get("genres", [])],
            "developers": base.get("developers"),
            "publishers": base.get("publishers"),
            "type": base.get("type"),
            "prices": {},
        }
        for cc in CCS:
            try:
                d = appdetails(appid, cc)
                po = (d or {}).get("price_overview")
                rec["prices"][cc] = po
            except Exception as e:
                rec["prices"][cc] = {"err": repr(e)[:80]}
            time.sleep(0.6)
        out[k] = rec
        print(f'{appid} {rec["name"]!r} free={rec["is_free"]} '
              f'us={(rec["prices"].get("us") or {}).get("final_formatted")} '
              f'tr={(rec["prices"].get("tr") or {}).get("final_formatted")}', flush=True)
        json.dump(out, open(OUT, "w"), indent=1)
    json.dump(out, open(OUT, "w"), indent=1)
    print("saved", OUT, len(out), "apps")


if __name__ == "__main__":
    main([int(x) for x in sys.argv[1].split(",")])
