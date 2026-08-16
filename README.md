# The Price of Being Priced Like America

Replication package for *Demand for Digital Goods When Regional Pricing Ends*.

On **20 November 2023** Valve eliminated Turkish Lira and Argentine Peso pricing on Steam and
moved both storefronts to US dollars, raising local prices by roughly **240%–2,900%** depending on
the title. This repository estimates the demand response.

Everything here runs on **public endpoints that require no API key, no login, and no paid
subscription.**

---

## Headline result

| Specification | Estimate | s.e. | Interpretation |
|---|---|---|---|
| DiD, paid titles, Turkish vs. other languages | **-0.483** | 0.056 | 38% fall in Turkish demand |
| DDD, adding free-to-play as within-Turkey control | **-0.383** | 0.088 | 32% fall |
| Placebo: free-to-play titles only | -0.106 | 0.078 | null, as predicted |
| Gray-market (non-Steam key) share | +0.0003 | 0.0058 | null |

Sample: 34 titles (25 paid, 9 free-to-play), 28 languages, 342 game × language cells, 11,970
game-language-month observations, July 2022 – June 2025.

Randomization inference across all 28 languages: Turkish is the most negative, p = 0.036; the
next-most-negative placebo is −0.175. Leave-one-game-out: [−0.505, −0.458].
Implied own-price elasticity: −0.14 to −0.39 — **inelastic**.

*(Numbers regenerate from `output/tables/stats.json`; the values above are from the run current at
the time of writing and will shift as the sample grows.)*

---

## Reproducing from a cold start

```bash
# 0. environment
python3 -m venv .venv
./.venv/bin/pip install pandas numpy requests matplotlib statsmodels pyarrow pdfminer.six
brew install r tectonic          # macOS; R >= 4.3, tectonic for LaTeX
Rscript install_pkgs.R           # data.table, fixest, ggplot2, modelsummary, broom, ...

# 1. pull raw review histories  (hours; resumable — safe to interrupt and rerun)
./.venv/bin/python code/pull_steam_reviews.py \
    "413150,292030,271590,1091500,431960,105600,322330,252490,1145360,620" \
    "turkish,latam,english,russian,brazilian,german,polish,schinese"

# 2. pull game metadata and current prices in every storefront
./.venv/bin/python code/pull_steam_meta.py "413150,292030,271590,..."

# 3. build the game x language x week panel
./.venv/bin/python code/build_panel.py

# 4. every table and figure in the paper
Rscript code/analysis_full.R

# 5. compile the paper
cd paper && tectonic -X compile paper.tex
```

Step 4 writes `output/tables/macros.tex`, a set of `\newcommand` definitions the paper
`\input`s. **No number in the paper is typed by hand**; changing the sample and rerunning step 4
updates the manuscript.

---

## Layout

```
code/pull_steam_reviews.py   paginated pull of review histories, resumable per (appid, language)
code/pull_steam_meta.py      store metadata + prices across ~11 storefronts
code/build_panel.py          reviews -> game x language x week panel
code/analysis.R              quick DiD/DDD + event study (development script)
code/analysis_full.R         every table, figure, and \newcommand in the paper
install_pkgs.R               R dependencies
pull_formd.sh, build_formd.py   SEC Form D pipeline (from the discarded candidate; kept, see below)
paper/paper.tex              the manuscript
data/raw/                    raw pulls (not committed; regenerate with steps 1-2)
data/interim/                panel parquet/csv
output/tables/, output/figures/
candidates.md                Phase 1 — six candidate questions
verification-log.md          Phase 2 — every check run, with commands and results
research-plan.md             Phases 3-5 — graveyard, commitment, and proof of pipeline
```

---

## Data sources

| Source | Endpoint | Auth |
|---|---|---|
| Steam reviews | `store.steampowered.com/appreviews/{appid}` | none |
| Steam store metadata & prices | `store.steampowered.com/api/appdetails` | none |
| Steam app list | `api.steampowered.com/ISteamApps/GetAppList/v2/` | none |

The review endpoint is documented by Valve for third-party use at
`partner.steamgames.com/doc/store/getreviews`. The puller sends a descriptive User-Agent with a
contact address and sleeps 0.25s between requests.

**steamdb.info is deliberately not used.** It returns HTTP 403 to programmatic requests and its
terms restrict scraping. Historical per-title lira prices — needed for the dose-response
specification — are therefore *not* in this package. That is the paper's main open gap and it is
stated as such rather than papered over.

---

## Known issues and gotchas

- **Pagination depth is the binding constraint.** High-volume language cells hit the page cap
  before reaching the pre-period: English on Stardew Valley returns ~40,000 reviews and only
  reaches 2025-08, while Turkish reaches 2021 comfortably. `build_panel.py` verifies coverage
  cell by cell and drops cells that do not span the estimation window, so this degrades the sample
  rather than silently biasing it. Raise `MAXPAGES` for high-volume cells.
- **A datetime-resolution bug was found and fixed during development.** Aligning weekly counts
  with `to_period("W-MON").start_time` against a `pd.date_range(freq="W-MON")` index produced a
  silent all-`NaN` reindex which `fillna(0)` then turned into a panel of clean, plausible,
  entirely fictitious zeros. The current code builds weeks by explicit Monday arithmetic and
  asserts that the reindex matched. If you refactor the panel builder, keep the assertion.
- **Inference has one treated cluster.** Randomization inference across languages is the honest
  test, and its minimum attainable one-sided p-value is 1/(number of languages). Pull all 29 Steam
  languages to reach 0.034. The current run uses 28 and attains p = 0.036.
- **`latam` is not Argentina.** Steam's Latin-American Spanish tag pools Argentina with countries
  that moved in the *opposite* price direction on the same date. Do not treat `latam` as a second
  treated unit.

---

## On the citations

Papers cited in the manuscript that were located and read (or whose bibliographic record was
retrieved) during this project: Cavallo, Neiman & Rigobon (2014, QJE); Watabe, Yang & Kanasheuski
(2025, CJE); Tudón (2022, QME); Howell & Parker (2024, SEC OASB report — full text read); Choi
(2025, Apple-funded DMA study — full text read); Danaher, Smith & Telang (2014). The
econometrics references (Goodman-Bacon, Callaway–Sant'Anna, Sun–Abraham, Borusyak–Jaravel–Spiess,
Silva–Tenreyro, Young, Bertrand–Duflo–Mullainathan, Cameron–Gelbach–Miller, Conley–Taber,
Cavallo 2017, Gorodnichenko–Talavera 2017, Danaher et al. 2010) are standard and were cited from
knowledge; **verify each against the published record before submission.**

## The Form D code

`pull_formd.sh` and `build_formd.py` build a 609,582-row panel of every SEC Form D filing
2014–2026. They belong to a candidate project that was investigated and then abandoned
(see `research-plan.md`, Phase 3) after the design turned out to be already published. They are
kept because the pipeline works and the panel is a genuine free substitute for the financing side
of Crunchbase.
