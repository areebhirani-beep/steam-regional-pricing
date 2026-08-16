# The Price of Being Priced Like America

`https://github.com/areebhirani-beep/steam-regional-pricing`

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
| DiD, paid titles, Turkish vs. other languages | **-0.493** | 0.014 | 39% fall in review flow |
| DDD, adding free-to-play as within-Turkey control | **-0.292** | 0.049 | 25% fall (preferred) |
| Poisson PML on raw counts | -0.489 | 0.026 | not a log-transform artefact |
| With a Turkish linear time trend | -0.567 | 0.017 | pre-trend correction makes it larger |
| **Dose response: own-price elasticity** | **-0.239** | 0.052 | **inelastic** |
| Two treated clusters, signed (Turkish up, LatAm down) | -0.306 | 0.010 | the mechanism is price |
| Free-to-play in Turkish (macro control) | -0.207 | 0.047 | why DDD is smaller than DiD |
| Latin-American Spanish (repriced down same day) | **+0.121** | 0.010 | opposite sign, as predicted |
| Gray market (non-Steam key share) | +0.0100 | 0.0026 | +1.0pp shift to third-party keys |

Sample: **7,323,081 reviews** in the estimation window across 486 titles (464 paid, 22 free-to-play), 28 languages, 7348 title-by-language cells and 257,180 title-language-month observations, July 2022 to June 2025. The raw collection behind it is 17.4 million reviews across 560 titles and 29 languages.

**Proxy validated against units.** SteamSpy owner estimates provide an independent measure of units: log(owners) = 8.23 + 0.577·log(reviews), R-squared 0.65, N = 8,767. The slope is below one, so the unit response is bounded at [-0.169, -0.292] and the elasticity in units at [-0.14, -0.24]. Both ends inelastic.

**Inference designed for one treated cluster.** Randomization inference across all 28 languages ranks Turkish first (p = 0.036; next most negative placebo -0.122). Conley-Taber interval inverted from the placebo distribution: [-0.866, -0.335]. Leave-one-title-out: [-0.496, -0.492]. The fitted pre-trend slope is **positive** (+0.0118 per month), so it biases against the finding.

**Welfare.** Revenue rose by 2.5x to 22.4x. Consumer-surplus loss is 1.8 to 2.4 times pre-change Turkish revenue at the conservative price multiple, bounded without a functional form.

*All numbers regenerate from `output/tables/stats.json`.*

---

## Reproducing from a cold start

```bash
./run_all.sh          # everything below, in order, resumable
```

Or step by step:

```bash
# 0. environment
python3 -m venv .venv
./.venv/bin/pip install pandas numpy requests matplotlib statsmodels pyarrow pdfminer.six
brew install r tectonic          # macOS. R >= 4.3; tectonic compiles the paper without sudo
Rscript install_pkgs.R           # data.table, fixest, ggplot2, broom, jsonlite, ...

# 1. sampling frame: SteamSpy top titles, screened for Turkish review volume
./.venv/bin/python code/build_frame.py 400 600

# 2. review histories, sharded and resumable (hours)
./.venv/bin/python code/pull_steam_reviews.py "<appids>" "<languages>"

# 3. title metadata and US/TR prices
./.venv/bin/python code/pull_meta_fast.py

# 4. SteamSpy owner estimates, for validating the review proxy
./.venv/bin/python code/export_steamspy.py

# 5. panel, then every table, figure and in-text number
./.venv/bin/python code/build_panel.py
Rscript code/analysis_full.R

# 6. compile the paper
cd paper && tectonic -X compile paper.tex
```

Step 4 writes `output/tables/macros.tex`, a set of `\newcommand` definitions the manuscript reads.
**No number in the paper is typed by hand.** Expand the sample, rerun step 4, recompile, and the
paper updates itself, abstract included.

---

## Layout

```
run_all.sh                   one command, cold start to compiled PDF
code/pull_steam_reviews.py   paginated review-history collector, resumable per (appid, language)
code/build_frame.py          SteamSpy sampling frame + Turkish-volume screen
code/pull_meta_fast.py       parallel metadata/price pull for the full sample
code/export_steamspy.py      owner estimates for the proxy validation
code/build_panel.py          reviews -> title x language x week panel, with coverage checks
code/analysis_full.R         every table, figure, and \newcommand in the paper
install_pkgs.R               R dependencies
paper/paper.tex              the manuscript
paper/refs.bib               bibliography
data/raw/                    raw pulls (not committed; regenerate with steps 1 and 2)
data/interim/                panel in parquet and csv
output/figures/              seven figures, PDF
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
