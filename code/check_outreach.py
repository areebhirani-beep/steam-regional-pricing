#!/usr/bin/env python3
"""Sanity-check the correspondence templates: length, stale figures, placeholders."""
import re, json, os, sys

HERE = os.path.dirname(__file__)
F = os.path.join(HERE, "..", "outreach", "email-templates.md")
MAC = os.path.join(HERE, "..", "output", "tables", "macros.json")

t_raw = open(F).read()
t = re.sub(r"\n> ", " ", t_raw)   # unwrap quoted lines before matching
mac = json.load(open(MAC))

print("length of each letter (target: under 200 words)")
for m in re.finditer(r"^## ([A-D])\.\s*(.+?)\s*$", t_raw, re.M):
    start = m.end()
    nxt = t_raw.find("\n---", start)
    block = t_raw[start:nxt if nxt > 0 else len(t_raw)]
    body = " ".join(l[2:] for l in block.split("\n") if l.startswith("> "))
    body = re.sub(r"\*\*Subject:.*?\*\*", "", body)
    n = len(body.split())
    flag = "" if n <= 200 else "   <-- trim"
    print(f"   {m.group(1)}. {m.group(2)[:44]:46s} {n:3d} words{flag}")

print("\nfigures quoted in the letters vs. the current run")
quoted = {
    "triple difference": ("bDDD", r"−0\.317"),
    "its std. error":    ("seDDD", r"0\.057"),
    "elasticity":        ("bDose", r"−0\.287"),
    "percent decline":   ("pctDDD", r"27 percent"),
    "languages":         ("Nlang", r"28 Steam languages"),
    "horizon":           ("horizonMonths", r"31 months"),
}
bad = 0
for label, (key, pat) in quoted.items():
    present = re.search(pat, t) is not None
    print(f"   {label:20s} macro={mac.get(key):>10s}  quoted correctly: {present}")
    bad += (not present)

stale = [p for p in ("0.343", "0.331", "39 titles", "1.36 million", "page 11",
                     "fell by a third", "1,361,901") if p in t]
print(f"\nstale figures: {stale if stale else 'none'}")
placeholders = re.findall(r"\[(?:link|links)\]", t)
print(f"[link] placeholders: {len(placeholders)} (intentional; real URLs are listed at the top)")
sys.exit(1 if (bad or stale) else 0)
