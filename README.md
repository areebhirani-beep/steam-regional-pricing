# The Price of Being Priced Like America

**Demand for Digital Goods When Regional Pricing Ends**

Replication package. Paper: [`paper/paper.pdf`](paper/paper.pdf).

On **20 November 2023** Valve eliminated Turkish Lira and Argentine Peso pricing on Steam and moved
both storefronts to US dollars, raising local prices by roughly **240 to 2,900 percent** depending
on the title. This repository estimates the demand response and recovers an own-price elasticity
for digital goods in an emerging market.

Everything here runs on **public endpoints that require no API key, no login, no institutional
affiliation, and no paid subscription.**

---

## Headline results

| Specification | Estimate | s.e. | Reading |
|---|---:|---:|---|
| DiD, paid titles, Turkish vs. other languages | **−0.468** | 0.055 | 37% fall in Turkish demand |
| DDD, adding free-to-play as within-Turkey control | **−0.343** | 0.083 | 29% fall (preferred) |
| Poisson PML on raw counts | −0.413 | 0.082 | not a log-transform artefact |
| With a Turkish linear time trend | −0.580 | 0.042 | pre-trend correction makes it larger |
| **Dose response: own-price elasticity** | **−0.331** | 0.153 | **inelastic** |
| Placebo: free-to-play titles only | −0.136 | 0.069 | small, and the reason DDD < DiD |
| Latin-American Spanish (repriced *down* same day) | **+0.148** | 0.032 | opposite sign, as predicted |
| Gray market (non-Steam key share) | +0.0063 | 0.0061 | null |

Sample: **1,361,901 reviews**, 39 titles (29 paid, 10 free-to-play), 28 languages, 526
title-by-language cells, 18,410 title-language-month observations, July 2022 to June 2025.

Falsification: randomization inference across all 28 languages ranks Turkish first
(p = 0.036; next most negative placebo −0.175). Leave-one-title-out gives [−0.490, −0.448].
The fitted pre-trend slope is **positive** (+0.0153 per month, s.e. 0.0073), so it biases against
the finding.

*All numbers regenerate from `output/tables/stats.json`.*

---

## Reproducing from a cold start

```bash
# 0. environment
python3 -m venv .venv
./.venv/bin/pip install pandas numpy requests matplotlib statsmodels pyarrow pdfminer.six
brew install r tectonic          # macOS. R >= 4.3; tectonic compiles the paper without sudo
Rscript install_pkgs.R           # data.table, fixest, ggplot2, broom, jsonlite, ...

# 1. pull raw review histories (hours; resumable, safe to interrupt and rerun)
./.venv/bin/python code/pull_steam_reviews.py \
    "413150,292030,271590,1091500,431960,105600,322330,252490,1145360,620" \
    "turkish,latam,russian,german,polish,schinese,brazilian,koreana,spanish,french"

# 2. pull title metadata and current prices across storefronts
./.venv/bin/python code/pull_steam_meta.py "413150,292030,271590,1091500,431960"

# 3. build the title x language x week panel
./.venv/bin/python code/build_panel.py

# 4. every table, figure, and in-text number
Rscript code/analysis_full.R

# 5. compile the paper
cd paper && tectonic -X compile paper.tex
```

Step 4 writes `output/tables/macros.tex`, a set of `\newcommand` definitions the manuscript reads.
**No number in the paper is typed by hand.** Expand the sample, rerun step 4, recompile, and the
paper updates itself, abstract included.

---

## Layout

```
code/pull_steam_reviews.py   paginated review-history collector, resumable per (appid, language)
code/pull_steam_meta.py      title metadata and prices across storefronts
code/build_panel.py          reviews -> title x language x week panel, with coverage checks
code/analysis_full.R         every table, figure, and \newcommand in the paper
install_pkgs.R               R dependencies
paper/paper.tex              the manuscript
paper/refs.bib               bibliography
data/raw/                    raw pulls (not committed; regenerate with steps 1 and 2)
data/interim/                panel in parquet and csv
output/figures/              six figures, PDF
output/tables/               LaTeX fragments, CSVs, stats.json, macros.tex
candidates.md                Phase 1: six candidate questions
verification-log.md          Phase 2: every check run, with commands and results
research-plan.md             Phases 3 to 5: graveyard, commitment, proof of pipeline
```

---

## Data sources

| Source | Endpoint | Auth |
|---|---|---|
| Steam reviews | `store.steampowered.com/appreviews/{appid}` | none |
| Steam store metadata and prices | `store.steampowered.com/api/appdetails` | none |
| Steam title list | `api.steampowered.com/ISteamApps/GetAppList/v2/` | none |

The review endpoint is documented by Valve for third-party use at
`partner.steamgames.com/doc/store/getreviews`. The collector sends a descriptive User-Agent with a
contact address and sleeps 0.25s between requests.

**steamdb.info is deliberately not used.** It refuses programmatic requests and its terms restrict
scraping. Historical per-title lira prices are therefore not in this package, which is why the
dose-response specification identifies the elasticity under a stated proportionality assumption
rather than from observed prices. That is the paper's main open gap and it is stated as such.

---

## Known issues and gotchas

**Pagination depth binds asymmetrically.** High-volume language cells hit the practical page limit
before reaching the pre-period. English on Stardew Valley returns roughly 40,000 reviews and only
reaches 2025-08, while Turkish reaches 2021 comfortably. `build_panel.py` verifies coverage cell by
cell and drops any cell that does not span the estimation window, so this restricts the sample
rather than biasing it. Raise `MAXPAGES` for high-volume cells.

**A datetime-resolution bug was found and fixed during development.** Aligning weekly counts built
with `to_period("W-MON").start_time` against a `pd.date_range(freq="W-MON")` index produced a
silent all-`NaN` reindex, which `fillna(0)` then turned into a panel of clean, plausible, entirely
fictitious zeros. The current code builds weeks by explicit Monday arithmetic and asserts that the
reindex matched. If you refactor the panel builder, keep the assertion.

**Inference has one treated cluster.** Randomization inference across languages is the honest test,
and its minimum attainable one-sided p-value is 1/(number of languages). The current run uses 28
and attains p = 0.036.

**`latam` is not Argentina.** Steam's Latin-American Spanish tag pools Argentina with countries that
moved in the *opposite* price direction on the same date. Column (5) of Table 2 is a directional
check, not a second treatment estimate.

---

## On the citations

Located and verified during this project, with the bibliographic record retrieved:
Cavallo, Neiman and Rigobon (2014, QJE); Gopinath, Boz, Casas, Díez, Gourinchas and
Plagborg-Møller (2020, AER); DellaVigna and Gentzkow (2019, QJE); Björkegren (2019, ReStud);
Nevo, Turner and Williams (2016, Econometrica); Fleder and Hosanagar (2009, Management Science);
Zhu and Liu (2018, SMJ); Wen and Zhu (2019, SMJ); Katz and Shapiro (1985, AER); Varian (1985, AER);
Tadelis (2016, Annual Review of Economics); Aguirre, Cowan and Vickers (2010, AER);
Tudón (2022, QME); Watabe, Yang and Kanasheuski (2025, CJE); Danaher, Smith and Telang (2014);
Choi (2025, Apple-funded DMA study, read in full); Howell and Parker (2024, SEC OASB, read in full).

Cited from knowledge and flagged in `paper/refs.bib` for verification before journal submission:
Schmalensee (1981), Cavallo (2017), Gorodnichenko and Talavera (2017), Danaher et al. (2010),
Goodman-Bacon (2021), Callaway and Sant'Anna (2021), Sun and Abraham (2021), Borusyak, Jaravel and
Spiess (2024), Santos Silva and Tenreyro (2006), Young (2019), Bertrand, Duflo and Mullainathan
(2004), Cameron, Gelbach and Miller (2008), Conley and Taber (2011).

## The Form D code

`pull_formd.sh` and `build_formd.py` build a 609,582-row panel of every SEC Form D filing from 2014
to 2026. They belong to a candidate project investigated and then abandoned once the design turned
out to be already published; see `research-plan.md`, Phase 3. They are kept because the pipeline
works and the panel is a genuine free substitute for the financing side of Crunchbase.
