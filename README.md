# The Price of Being Priced Like America

### Demand for digital goods when regional pricing ends

On 20 November 2023 Valve abolished Turkish Lira pricing on Steam and repriced its entire catalogue
in US dollars. Local prices rose by between roughly 240 and 2,900 percent overnight, on a date
Valve chose for reasons of exchange-rate volatility rather than anything to do with the games. This
repository estimates what happened to demand, and recovers a price elasticity for digital goods in
an emerging market.

**Paper:** [`paper/paper.pdf`](paper/paper.pdf) · 28 pages

Everything runs on public endpoints. No API key, no login, no institutional affiliation, no paid
subscription.

---

## What the data show

Turkish demand for paid games falls by **27 percent** against a control group of 27 other
languages, and the implied own-price elasticity is **−0.29**. Demand is inelastic, which carries
two consequences. Steam's deep regional discount was leaving revenue on the table, so the industry
habit of steep emerging-market discounting does not rest on the profit grounds usually offered for
it. And because quantity barely moved, ending regional pricing was mostly a transfer out of a poor
market rather than forgone trade: the seller captured between 62 and 84 percent of what Turkish
consumers lost.

| | Estimate | s.e. |
| :--- | ---: | ---: |
| **Difference-in-differences**, paid titles, Turkish vs. other languages | **−0.499** | 0.016 |
| **Triple difference**, adding free-to-play as a within-Turkey control | **−0.317** | 0.057 |
| **Dose response**, own-price elasticity | **−0.287** | 0.055 |
| Poisson PML on raw counts | −0.472 | 0.029 |
| Turkish-specific linear time trend included | −0.492 | 0.014 |
| Signed treatment, two clusters (Turkey up, LatAm down) | −0.350 | 0.010 |
| Free-to-play titles in Turkish, the macro control | −0.189 | 0.055 |
| Latin-American Spanish, repriced *downward* the same day | +0.207 | 0.012 |
| Non-Steam key share, the gray-market margin | +0.013 | 0.003 |

The triple difference is the preferred estimate. The plain difference-in-differences contains a
macroeconomic component, visible in the free-to-play row, which the triple difference removes.

**In units rather than reviews.** SteamSpy owner counts give an independent measure of quantity.
Across 8,767 titles, `log(owners) = 8.23 + 0.577·log(reviews)`, R² = 0.65. The slope is below one,
so a percentage fall in reviews does not mean the same percentage fall in units. Every magnitude is
therefore bounded: the unit response lies in [−0.183, −0.317], a fall of 17 to 27 percent, and the
elasticity in [−0.17, −0.29]. Both ends inelastic.

**Falsification.** Randomization inference across all 28 languages ranks Turkish first
(p = 0.036). Conley–Taber interval, inverted from the placebo distribution: [−1.002, −0.280].
Leave-one-title-out: [−0.502, −0.497]. Placebo event dates at ±6 and −12 months. Russia, which had
a comparable currency collapse but kept Ruble pricing, does not move. The fitted pre-trend slope is
*positive*, so correcting for it makes the estimated decline larger.

**Horizon.** 31 months past the event, with no reversion.

---

## Sample

9,608,862 reviews inside the estimation window, drawn from a raw collection of 17.4 million across
560 titles and 29 languages. The window runs July 2022 to June 2026 and admits a title-language
cell only if its retrieved review history demonstrably spans the whole period, which is checked
cell by cell rather than assumed.

| | |
| :--- | ---: |
| Titles | 484 (462 paid, 22 free-to-play) |
| Languages | 28 |
| Title × language cells | 6,501 |
| Title × language × month observations | 312,048 |

---

## Reproducing

```bash
./run_all.sh
```

That runs the whole pipeline, from an empty `data/` directory to a compiled PDF. Steps 1 to 3 hit
the network and take a few hours; all three are resumable, so interrupting and re-running skips
whatever is already on disk.

Step by step:

```bash
python3 -m venv .venv
./.venv/bin/pip install pandas numpy requests matplotlib statsmodels pyarrow pdfminer.six
brew install r tectonic                  # tectonic compiles the paper without sudo
Rscript install_pkgs.R

./.venv/bin/python code/build_frame.py 400 600      # sampling frame, screened for Turkish volume
./.venv/bin/python code/pull_steam_reviews.py ...   # review histories, sharded and resumable
./.venv/bin/python code/pull_meta_fast.py           # metadata and US/TR prices
./.venv/bin/python code/export_steamspy.py          # owner estimates for the proxy validation
./.venv/bin/python code/build_panel.py              # title x language x week panel
Rscript code/analysis_full.R                        # every table, figure and in-text number
cd paper && tectonic -X compile paper.tex
```

`analysis_full.R` writes `output/tables/macros.tex`, a set of `\newcommand` definitions that
`paper.tex` reads. **No number in the paper is typed by hand.** Expand the sample, re-run the
analysis, recompile, and the manuscript updates itself, abstract included.

---

## Repository

```
run_all.sh                    cold start to compiled PDF
code/
  build_frame.py              SteamSpy frame; screens candidates for Turkish review volume
  pull_steam_reviews.py       paginated review collector, resumable per (appid, language)
  pull_meta_fast.py           metadata and US/TR prices, rate-limited
  export_steamspy.py          owner estimates, for validating the review proxy
  build_panel.py              streams cell files into the panel, with coverage checks
  analysis_full.R             all regressions, seven figures, eight tables, all macros
  verify_refs.py              checks every citation against Crossref
  formd/                      SEC Form D pipeline, from an abandoned candidate project
paper/
  paper.tex, refs.bib, paper.pdf
output/
  figures/                    seven PDFs
  tables/                     LaTeX fragments, CSVs, stats.json, macros.tex
candidates.md                 six candidate questions considered
verification-log.md           every data check run, with commands and results
research-plan.md              why five candidates were discarded, and the plan for this one
outreach/                     segmented correspondence templates
```

`data/raw/` is not committed. Steps 1 to 3 regenerate it.

---

## Data

| Source | Endpoint | Auth |
| :--- | :--- | :--- |
| Steam reviews | `store.steampowered.com/appreviews/{appid}` | none |
| Steam store metadata and prices | `store.steampowered.com/api/appdetails` | none |
| Steam title list | `api.steampowered.com/ISteamApps/GetAppList/v2/` | none |
| SteamSpy owner estimates | `steamspy.com/api.php` | none |

Valve documents the review endpoint for third-party use at
`partner.steamgames.com/doc/store/getreviews`. The collector identifies itself with a contact
address and sleeps between requests.

`steamdb.info` is deliberately not used. It refuses programmatic requests and its terms restrict
scraping. Historical per-title lira prices are therefore absent, which is why the dose-response
specification identifies the elasticity under a stated proportionality assumption rather than from
observed prices. That is the paper's main open gap and it is labelled as such in the text.

---

## Known limits

**Pagination depth binds asymmetrically.** High-volume language cells exhaust the practical page
limit before reaching the pre-period, while mid-volume cells reach 2021 comfortably.
`build_panel.py` checks coverage cell by cell and drops any cell that does not span the estimation
window, so this restricts the sample rather than biasing it. Raise `MAXPAGES` for high-volume cells.

**Inference rests on one treated cluster.** Randomization inference across languages is the honest
test and its smallest attainable one-sided p-value is 1/(number of languages). With 28 languages
that floor is 0.036, which the estimate attains.

**`latam` is not Argentina.** Steam's Latin-American Spanish tag pools Argentina, repriced upward,
with countries repriced downward on the same date. The Latin-American row above is a directional
check on the mechanism, not a second treatment estimate. Separating Argentina requires user-level
country identification and is left as an extension.

**A silent bug, recorded so it is not reintroduced.** Aligning weekly counts built with
`to_period("W-MON").start_time` against a `pd.date_range(freq="W-MON")` index produces an all-`NaN`
reindex, which `fillna(0)` then turns into a panel of clean, plausible, entirely fictitious zeros.
The builder now computes weeks by explicit Monday arithmetic and asserts that the reindex matched.
Keep the assertion.

---

## Citations

All 29 bibliography entries are checked against the publisher record rather than cited from
recollection. Run `./.venv/bin/python code/verify_refs.py` to reproduce: it parses `refs.bib`,
queries Crossref by title and first author, filters out preprint and SSRN records so it compares
against the published version, and diffs journal, year, volume, issue and pages. Current status:
zero entries need attention.

Twenty-three verify automatically. Six cannot be matched by title search and were checked by hand
against the sources named in the script's `MANUAL` block: Varian (1985), Schmalensee (1981) and
Katz & Shapiro (1985) pre-date reliable Crossref coverage of the *AER*; Björkegren (2019) against
the *Review of Economic Studies* listing; Tudón (2022) by DOI; and Young (2019), where Crossref
reports the online-first year rather than the issue year.

Two entries were corrected by this process. Tudón (2022) and Wen & Zhu (2019) were both missing
volume and page numbers. One near-miss is worth recording: a web search had reported Tudón as
"volume 53, 328–355", which is wrong. The DOI lookup caught it.

---

## Citing this

> Hirani, Areeb (2026). *The Price of Being Priced Like America: Demand for Digital Goods When
> Regional Pricing Ends.* Working paper.
