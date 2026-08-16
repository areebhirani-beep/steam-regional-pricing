#!/bin/bash
UA="AreebHirani-HSResearch areeb.research@gmail.com"
mkdir -p data/raw/formd
ok=0; fail=0
for y in $(seq 2008 2026); do
  for q in 1 2 3 4; do
    f="data/raw/formd/${y}q${q}_d.zip"
    [ -s "$f" ] && continue
    code=$(curl -s -A "$UA" -w "%{http_code}" -o "$f" "https://www.sec.gov/files/structureddata/data/form-d-data-sets/${y}q${q}_d.zip")
    if [ "$code" = "200" ] && [ -s "$f" ]; then echo "OK   ${y}q${q} $(du -h $f|cut -f1)"; ok=$((ok+1)); else rm -f "$f"; echo "MISS ${y}q${q} http=$code"; fail=$((fail+1)); fi
    sleep 0.3
  done
done
echo "DONE ok=$ok miss=$fail"
