import requests, json, re, time, sys, os
UA={"User-Agent":"AreebHirani-HSResearch areeb.research@gmail.com"}
S=requests.Session(); S.headers.update(UA)
def get(url, params, tries=6):
    for i in range(tries):
        r=S.get(url, params=params, timeout=300)
        if r.status_code==200: return r
        time.sleep(4*(i+1))
    return None
def pull(crawl, cc):
    pat=f"apps.apple.com/{cc}/app/*"
    m=get(f"https://index.commoncrawl.org/{crawl}-index",{"url":pat,"output":"json","showNumPages":"true"})
    if m is None: return None
    meta=m.json(); ids=set()
    for p in range(meta["pages"]):
        r=get(f"https://index.commoncrawl.org/{crawl}-index",{"url":pat,"output":"json","page":p})
        if r is None: continue
        for line in r.text.strip().split("\n"):
            if not line.strip(): continue
            try: rec=json.loads(line)
            except: continue
            if rec.get("status")!="200": continue
            mm=re.search(r"/id(\d+)",rec["url"])
            if mm: ids.add(mm.group(1))
        time.sleep(1)
    return ids
if __name__=="__main__":
    os.makedirs("data/interim/ccidx",exist_ok=True)
    for spec in sys.argv[1:]:
        crawl,cc=spec.split(":")
        f=f"data/interim/ccidx/{crawl}_{cc}.json"
        if os.path.exists(f): 
            print("cached",spec,len(json.load(open(f)))); continue
        ids=pull(crawl,cc)
        if ids is None: print("FAIL",spec); continue
        json.dump(sorted(ids),open(f,"w"))
        print(f"{spec}: {len(ids)} unique app ids")
        time.sleep(2)
