#!/usr/bin/env python3
"""Fast metadata + US/TR price pull for the full sample, parallelised."""
import json, os, sys, time, requests
from concurrent.futures import ThreadPoolExecutor, as_completed
UA={"User-Agent":"AreebHirani-HSResearch areeb.research@gmail.com"}
HERE=os.path.dirname(__file__)
OUT=os.path.join(HERE,"..","data","raw","steam_meta.json")
CCS=["us","tr"]

def one(appid):
    rec={"appid":appid,"prices":{}}
    for cc in CCS:
        for _ in range(3):
            try:
                r=requests.get("https://store.steampowered.com/api/appdetails",
                    params={"appids":appid,"cc":cc,"l":"english"},headers=UA,timeout=45)
                d=(r.json() or {}).get(str(appid),{})
                if not d.get("success"):
                    time.sleep(5); continue
                data=d["data"]
                if cc=="us":
                    rec.update({"name":data.get("name"),"is_free":data.get("is_free"),
                        "release_date":data.get("release_date",{}).get("date"),
                        "genres":[g["description"] for g in data.get("genres",[])],
                        "developers":data.get("developers"),"publishers":data.get("publishers"),
                        "type":data.get("type")})
                rec["prices"][cc]=data.get("price_overview")
                time.sleep(1.2)
                break
            except Exception:
                time.sleep(6)
    return rec

def main(appids, workers=3):
    out=json.load(open(OUT)) if os.path.exists(OUT) else {}
    todo=[a for a in appids if str(a) not in out or "name" not in out.get(str(a),{})]
    print(f"pulling metadata for {len(todo)} titles ({len(out)} cached)",flush=True)
    t0=time.time(); done=0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs={ex.submit(one,a):a for a in todo}
        for fut in as_completed(futs):
            rec=fut.result()
            if rec.get("name"): out[str(rec["appid"])]=rec
            done+=1
            if done%100==0:
                print(f"  {done}/{len(todo)}  ({time.time()-t0:.0f}s)",flush=True)
                json.dump(out,open(OUT,"w"))
    json.dump(out,open(OUT,"w"))
    print("saved",len(out),"titles")

if __name__=="__main__":
    ids=[c["appid"] for c in json.load(open(os.path.join(HERE,"..","data","interim","sample.json")))]
    main(ids)
