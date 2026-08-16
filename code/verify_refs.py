#!/usr/bin/env python3
"""
Verify every bibliography entry against Crossref.

Parses paper/refs.bib, queries the Crossref REST API by title + first author,
and compares the returned journal, year, volume, issue and pages with what the
bib file claims. Prints a per-entry verdict so nothing in the manuscript rests
on recollection.
"""
import re, json, sys, time, unicodedata
import requests

UA = {"User-Agent": "AreebHirani-HSResearch (mailto:areeb.research@gmail.com)"}
BIB = "paper/refs.bib"

# Entries Crossref cannot confirm by title search, each checked by hand against
# the source named below. Re-check if the bib entry is edited.
MANUAL = {
    "varian1985":      "AER 75(4) 870-875 1985; RePEc aea/aecrev/v75y1985i4p870-75 (pre-Crossref)",
    "schmalensee1981": "AER 71(1) 242-247 1981; RePEc aea/aecrev/v71y1981i1p242-47 (pre-Crossref)",
    "katz1985":        "AER 75(3) 424-440 1985; RePEc aea/aecrev/v75y1985i3p424-40 (pre-Crossref)",
    "bjorkegren2019":  "ReStud 86(3) 1033-1060 2019; publisher listing + Brown VIVO record",
    "tudon2022":       "QME 20(3) 293-312 2022; confirmed by DOI 10.1007/s11129-022-09254-5",
    "young2019":       "QJE 134(2) 557-598 2019; Crossref reports the 2018 online-first date",
}


def norm(s):
    s = unicodedata.normalize("NFKD", s or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[{}\\'\"`^~]", "", s)
    s = re.sub(r"[^a-z0-9 ]", " ", s.lower())
    return re.sub(r"\s+", " ", s).strip()


def parse_bib(path):
    txt = open(path).read()
    out = []
    for m in re.finditer(r"@(\w+)\{([^,]+),(.*?)\n\}", txt, re.S):
        kind, key, body = m.group(1), m.group(2).strip(), m.group(3)
        f = {}
        for fm in re.finditer(r"(\w+)\s*=\s*\{(.*?)\}(?=\s*,\s*\w+\s*=|\s*$)", body, re.S):
            f[fm.group(1).lower()] = re.sub(r"\s+", " ", fm.group(2)).strip()
        out.append({"kind": kind, "key": key, **f})
    return out


PREPRINT = ("ssrn", "working paper", "nber", "arxiv", "repec", "preprint",
            "research papers in economics", "variants in economic theory")


def crossref(title, author, want_year=None):
    try:
        r = requests.get("https://api.crossref.org/works",
                         params={"query.bibliographic": title,
                                 "query.author": author, "rows": 20,
                                 "filter": "type:journal-article"},
                         headers=UA, timeout=45)
        items = r.json().get("message", {}).get("items", [])
    except Exception as e:
        return None, f"query failed: {type(e).__name__}"
    tn = norm(title)
    best, bestscore = None, 0.0
    for it in items:
        cand = norm((it.get("title") or [""])[0])
        if not cand:
            continue
        cont = norm((it.get("container-title") or [""])[0])
        if any(p in cont for p in PREPRINT):      # skip preprint servers
            continue
        a, b = set(tn.split()), set(cand.split())
        score = len(a & b) / max(len(a | b), 1)
        yr = str((it.get("issued", {}).get("date-parts") or [[None]])[0][0])
        if want_year and yr == want_year:          # published version wins ties
            score += 0.30
        if it.get("volume"):
            score += 0.05
        if score > bestscore:
            best, bestscore = it, score
    if best is None or bestscore < 0.50:
        return None, f"no confident match (best overlap {bestscore:.2f})"
    return best, None


def main():
    entries = parse_bib(BIB)
    print(f"checking {len(entries)} entries against Crossref\n")
    problems = []
    for e in entries:
        if e["kind"].lower() == "techreport":
            print(f"  SKIP  {e['key']:<18} (report, not indexed)")
            continue
        if e["key"] in MANUAL:
            print(f"  MAN   {e['key']:<18} {MANUAL[e['key']]}")
            continue
        author1 = e.get("author", "").split(" and ")[0]
        surname = author1.split(",")[0].strip() if "," in author1 else author1.split()[-1]
        it, err = crossref(e.get("title", ""), surname, e.get("year"))
        time.sleep(0.4)
        if it is None:
            print(f"  ?     {e['key']:<18} {err}")
            problems.append((e["key"], err))
            continue
        got = {
            "journal": (it.get("container-title") or [""])[0],
            "year": str((it.get("issued", {}).get("date-parts") or [[None]])[0][0]),
            "volume": it.get("volume", ""),
            "issue": it.get("issue", ""),
            "pages": (it.get("page", "") or "").replace("-", "--"),
        }
        want = {k: (e.get(k, "") or "").replace("–", "--") for k in got}
        bad = []
        for k in ("year", "volume", "issue", "pages"):
            if want[k] and got[k] and norm(want[k]) != norm(got[k]):
                bad.append(f"{k}: bib={want[k]} crossref={got[k]}")
        jw, jg = norm(want["journal"]), norm(got["journal"])
        if jw and jg and jw not in jg and jg not in jw:
            bad.append(f"journal: bib='{want['journal']}' crossref='{got['journal']}'")
        if bad:
            print(f"  FIX   {e['key']:<18} " + " | ".join(bad))
            problems.append((e["key"], "; ".join(bad)))
        else:
            miss = [k for k in ("volume", "issue", "pages") if not want[k] and got[k]]
            extra = f"   (crossref also has {', '.join(f'{k}={got[k]}' for k in miss)})" if miss else ""
            print(f"  OK    {e['key']:<18} {got['journal']} {got['volume']}"
                  f"({got['issue']}) {got['pages']} {got['year']}{extra}")
    print(f"\n{len(problems)} entries need attention")
    for k, v in problems:
        print(f"   - {k}: {v}")


if __name__ == "__main__":
    main()
