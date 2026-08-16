import requests, json, gzip, re, sys, collections
UA={"User-Agent":"AreebHirani-HSResearch areeb.research@gmail.com"}
S=requests.Session(); S.headers.update(UA)
def idx(crawl, pat="apps.apple.com/us/app/*", page=0):
    r=S.get(f"https://index.commoncrawl.org/{crawl}-index",
            params={"url":pat,"output":"json","page":page},timeout=300)
    out=[]
    for line in r.text.strip().split("\n"):
        if line.strip():
            try: out.append(json.loads(line))
            except: pass
    return out
def warc(rec):
    off=int(rec["offset"]); ln=int(rec["length"])
    r=S.get("https://data.commoncrawl.org/"+rec["filename"],
            headers={"Range":f"bytes={off}-{off+ln-1}"},timeout=180)
    return gzip.decompress(r.content).decode("utf-8","ignore").split("\r\n\r\n",2)[-1]
def parse(body):
    m=dict(re.findall(r'<script[^>]*type="fastboot/shoebox"[^>]*id="([^"]+)"[^>]*>(.*?)</script>',body,re.S))
    key=[k for k in m if 'media-api-cache' in k]
    if not key: return None
    d=json.loads(m[key[0]])
    for k in d:
        v=json.loads(d[k]) if isinstance(d[k],str) else d[k]
        if isinstance(v,dict) and v.get('d'): return v['d'][0]
    return None
if __name__=="__main__":
    for crawl in sys.argv[1:]:
        try:
            recs=[r for r in idx(crawl,page=0) if r["status"]=="200"]
            hit=0; feats=collections.Counter(); ex=None
            for r in recs[:12]:
                try:
                    data=parse(warc(r))
                except Exception: continue
                if not data: continue
                hit+=1
                ios=data['attributes']['platformAttributes']['ios']
                if ios.get('versionHistory'): feats['versionHistory']+=1
                if ios.get('offers'): feats['offers']+=1
                if data['attributes'].get('userRating',{}).get('ratingCountList'): feats['ratingHistogram']+=1
                if data['attributes'].get('privacy'): feats['privacyLabel']+=1
                if data.get('relationships',{}).get('top-in-apps',{}).get('data'): feats['IAP_list']+=1
                if ex is None and data.get('relationships',{}).get('top-in-apps',{}).get('data'): ex=data
            print(f"{crawl}: idx200={len(recs)} parsed={hit}/12  feats={dict(feats)}")
            if ex:
                t=ex['relationships']['top-in-apps']['data'][:3]
                print("   IAP sample:",[(x['attributes'].get('name'),x['attributes'].get('offers',[{}])[0].get('priceFormatted')) for x in t])
        except Exception as e:
            print(crawl,"ERR",repr(e)[:200])
