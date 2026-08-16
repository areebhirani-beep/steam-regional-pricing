#!/usr/bin/env bash
# Rebuild everything from a cold start. Steps 1-3 hit the network and take hours;
# they are resumable, so re-running skips whatever is already cached on disk.
set -euo pipefail
PY=./.venv/bin/python

echo "[1/6] sampling frame + Turkish-volume screen"
$PY code/build_frame.py 400 600          # -> data/interim/sample.json

echo "[2/6] review histories (resumable; ~2-4h with 30 shards)"
LANGS="turkish,latam,russian,german,polish,brazilian,schinese,spanish,french,koreana,tchinese,ukrainian,czech,hungarian,thai,japanese"
export STOP_YEAR=2022 STOP_MONTH=4 MAXPAGES=160
$PY - <<'PYEOF'
import json
ids=[str(c["appid"]) for c in json.load(open("data/interim/sample.json"))]
N=32
open("data/interim/shards.txt","w").write("\n".join(",".join(ids[i::N]) for i in range(N)))
PYEOF
i=0; while IFS= read -r SH; do i=$((i+1))
  $PY code/pull_steam_reviews.py "$SH" "$LANGS" > "logs_pull$i.txt" 2>&1 &
done < data/interim/shards.txt; wait

echo "[3/6] title metadata and US/TR prices"
$PY code/pull_meta_fast.py

echo "[4/6] SteamSpy export for the proxy validation"
$PY code/export_steamspy.py

echo "[5/6] panel + every table, figure and in-text number"
$PY code/build_panel.py
Rscript code/analysis_full.R

echo "[6/6] compile the paper"
( cd paper && tectonic -X compile paper.tex )
echo "done -> paper/paper.pdf"
