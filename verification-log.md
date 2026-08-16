# Phase 2. Verification log

Every claim below was produced by a command run in this session. Commands are shown.
Anything I could not confirm is marked `UNVERIFIED`.

Machine: macOS 25.5.0 (Darwin), Apple Silicon. Working dir `~/research-paper`.

---

## §0 Toolchain

```
$ which R python3 curl jq git
R not found            -> installed via `brew install r`  => R version 4.6.1 (2026-06-24) "Happy Hop"
/opt/homebrew/bin/python3   (Python 3.14.6)
/usr/bin/curl, /usr/bin/jq, /usr/bin/git
$ pdflatex / xelatex / tectonic  -> not found -> installed BasicTeX via `brew install --cask basictex`
```

Python venv at `~/research-paper/.venv`: `pandas 3.0.5`, `numpy`, `requests`, `matplotlib`,
`statsmodels 0.14.6`, `linearmodels 7.0`, `pdfminer.six`, `pyarrow`.

R packages installed from CRAN (`install_pkgs.R`, exit code 0): `data.table`, `fixest`, `did`,
`didimputation`, `bacondecomp`, `HonestDiD`, `rdrobust`, `modelsummary`, `sandwich`, `lmtest`,
`ggplot2`, `broom`, `jsonlite`, `httr2`, `stringi`, `fst`, `kableExtra`, `tinytable`, `future.apply`.

**Result: the full modern applied-micro stack runs on this laptop.** No cluster, no Stata.

---

## §1 SEC EDGAR Form D. VERIFIED, complete, and richer than expected

**Access.** The documented path `../files/dera/data/form-d-data-sets/` returns 404. The working
path is:

```
$ curl -sIL -A "<UA>" -o /dev/null -w "%{http_code}" \
    https://www.sec.gov/files/structureddata/data/form-d-data-sets/2025q1_d.zip
200
```

**Coverage.** `pull_formd.sh` walked 2008q1–2026q4. Result: **51 quarterly files downloaded,
2014Q1–2026Q1 contiguous** (plus stray 2008q1, 2012q1). 2009–2013 are not published at this path.

**Contents.** Six TSVs per quarter. 2025Q1: FORMDSUBMISSION 14,757 rows; ISSUERS 14,973;
OFFERING 14,757; RELATEDPERSONS **51,603**; RECIPIENTS 7,149.

Built panel (`build_formd.py`) → `data/interim/formd_all.parquet`:

```
ROWS: 609,582      filing_date range: 2014-01-02 -> 2026-03-31   (0 unparsed dates)
filings/yr: 2014 37,984 | 2017 41,941 | 2020 46,089 | 2022 62,440 | 2025 56,519
```

Gotcha, recorded so it is not rediscovered: **FILING_DATE has two formats** across vintages
(`2014-03-31 17:30:58` vs `31-MAR-2021`), and `IS_PRIMARYISSUER_FLAG` is `YES`/`NO`, not
`true`/`false`. Both silently produce empty results if assumed.

Variables confirmed present: issuer state, city, year of incorporation, entity type, SIC,
industry group, **fund type (Venture Capital / Private Equity / Hedge / Other)**, total offering
amount, total amount sold, **total number of investors already invested**, minimum investment,
federal exemption claimed (506(b) vs 506(c)), and officer/director **names and addresses**.

Sample check, 2025Q1 "Other Technology" issuers by amount sold, real, current, and correct:
Databricks $8.59B (175 investors), Apptronik $403M, Saronic Technologies $348M, Whatnot $262M.
VC fund offerings that quarter: 1,976, incl. Sequoia Capital Fund LP $19.6B, Madrona Venture
Fund X $490M.

**Verdict: Form D is a free, complete substitute for the financing side of Crunchbase/PitchBook.**
It is not, however, unexploited, see §2.

---

## §2 Literature check that killed two candidates. VERIFIED

Search led to a report hosted on sec.gov, downloaded and read in full:

**Sabrina T. Howell & Dean Parker (October 2024), "VC Funds and Regulation D's Rule 506(c): Did
Permitting General Solicitation Open the Door for Emerging and Underrepresented Managers?",
SEC Office of the Advocate for Small Business Capital Formation.** Drawn from Howell, Parker &
Xu (2024), *Tyranny of the Personal Network: The Limits of Arm's Length Fundraising in Venture
Capital*.

Direct quotes extracted from the PDF text:

> "We use a new fund exemption that raised the cap to 250 investors for very small funds to show
> that the cap seems to be binding, and is one lever policymakers could adjust to increase
> participation."

> "On May 25, 2018, the SEC raised the cap from 100 investors to 250 investors for VC funds with
> less than $10 million assets, while keeping the cap unchanged at 100 for VC funds larger than
> $10 million. … In Howell et al. (2024), we examine the impact of the 2018 investor cap increase
> on 506(c) take-up **using an event study design**. We show that after the 2018 new exemption,
> smaller VC funds below the $10m regulatory cutoff are much more likely to use 506(c) relative
> to funds larger than $10m."

This is, essentially exactly, candidate C1's design (below/above $10M × before/after 2018) and it
is candidate C6's entire question. Both are dead. Data: Form D + PitchBook + LinkedIn + a survey.
I would have brought Form D alone, against an NBER faculty member with the SEC's cooperation.

**Cost of not searching:** I had already run C1's core test on real data and it worked, see §3.
That is exactly the trap the search was for.

---

## §3 The C1 result I found and then had to throw away (recorded because it is real)

Offering-level collapse of Form D (max investor count per FILE_NUM across amendments), VC funds
with amount sold < $10M:

```
share of small VC fund offerings with >100 investors, by year of first filing
2014 0.000 (max n_inv = 99)     2019 0.016 (max = 249)     2022 0.028
2015 0.000 (max = 98)           2020 0.032 (max = 247)     2023 0.020
2016 0.000 (max = 100)          2021 0.051 (max = 247)     2024 0.012
2017 0.000 (max = 99)                                       2025 0.011
2018 0.000 (max = 99)
```

An absolute ceiling of 99–100 investors for five consecutive years, then a jump to a ceiling of
247–249. Private equity funds (ineligible) show no break: share >100 is 0.093, 0.065, 0.066,
0.062, 0.055, 0.054, 0.063 for 2014–2020. The first small VC funds to cross 100 are, in order,
`FundersClub VD8 LLC`, `NO Fund I, a series of AngelList-Forefront Venture Partners-Funds, LP`,
`AK Fund I, a series of AngelList-GP-Funds-I, LP`, i.e. exactly the platforms that built the
solo-GP era. A lovely figure. Scooped.

Statute verified independently from SEC Release No. IC-35305 (downloaded, text extracted):
Pub. L. 115-174 §504 (**May 24, 2018**); "qualifying venture capital fund" = VC fund with
≤ $10,000,000 aggregate capital contributions and uncalled committed capital; 250 beneficial
owners vs. 100. Inflation adjustment to **$12,000,000**, new Rule 3c-7, effective **Sept 30, 2024**.
SEC's own estimate: of ~5,000 qualifying VC funds as of June 2024, **989 have more than 100
beneficial owners** and "could not use the section 3(c)(1) exclusion absent" §504.

---

## §4 App-side data, what is and is not retrievable for free

### 4.1 Live Apple endpoints. VERIFIED WORKING
- `itunes.apple.com/lookup?id=…` returns price, releaseDate, currentVersionReleaseDate,
  averageUserRating, userRatingCount, genre, seller. (Spotify id=324684580 returned
  41,530,342 ratings, minimum iOS 16.1.)
- `rss.marketingtools.apple.com/api/v2/us/apps/top-free/…` returns current top charts.
- **In-app purchase names and prices are on the public App Store web page.** Duolingo US:
  `Super Duolingo $9.99 | Barrel of Gems (1200) $4.99 | Super Duolingo $83.99 | … | $119.99`.
  This works for any of ~175 storefronts. **Current cross-section only.**
- `itunes.apple.com/{cc}/rss/customerreviews/page={1.10}/id={app}/sortby=mostrecent/json`
  returns **50 reviews/page, hard cap 10 pages = 500 per app per country**; page 11 is invalid.
  Verified in us/de/br/no.

### 4.2 The retrospective wall. VERIFIED NEGATIVE, and it killed several candidates
- **Wayback is far too sparse for App Store pages.** Duolingo US page, all snapshots, 200-limit
  CDX query: **12 snapshots in five years** (2019:2, 2020:2, 2021:1, 2022:5, 2023:2). For one of
  the ten largest apps on earth. There is no monthly historical app panel here.
- **The 500-review cap binds hardest exactly where you want data.** Duolingo US: 500 reviews
  covers **3 days** (2026-08-11 → 2026-08-14). Germany: 20 days. Norway: 4 months. A long-tail
  app tested reached back to 2021. So review-based history exists only for small apps.

### 4.3 Common Crawl. VERIFIED RICH, but with three hard constraints
Index API (`index.commoncrawl.org`), 126 crawls available (CC-MAIN-2013-* … CC-MAIN-2026-30).

```
CC-MAIN-2024-33, url=apps.apple.com/us/app/*  -> 19,824 index records
   status: 200: 13,775 | 404: 3,805 | 301: 2,145 | 500: 97
   unique app ids with HTTP 200: 11,759
```

Fetching the WARC bytes by HTTP range request and parsing the embedded
`<script type="fastboot/shoebox" id="shoebox-media-api-cache-apps">` yields Apple's own media-API
record. Confirmed fields, per app, from an actual archived page:

- `versionHistory`, **every version with `releaseNotes` text and `releaseTimestamp`**
- `offers`, price + currency; `top-in-apps`, the IAP list *with prices*
  (verified example: `$5 Bill Helper Basic Plan $4.99`, `Gold Plan $49.99`)
- `userRating.ratingCountList`, the **1★–5★ histogram**, so two snapshots give ratings *flow*
- `privacy.privacyTypes`, the App Privacy nutrition label
- `releaseDate`, `bundleId`, `seller`, description, genres, file size, supported locales
- `customers-also-bought-apps` and `developer-other-apps`, a co-purchase / portfolio graph

Format stability probe (12 records sampled per crawl):
```
CC-MAIN-2023-40: idx200=10,225  parsed 12/12  versionHistory 12, offers 12, ratingHistogram 12,
                                              privacyLabel 12, IAP list 2
CC-MAIN-2024-33: parsed OK (same schema)
CC-MAIN-2025-30: KeyError('ios')  -> schema changed
CC-MAIN-2021-31: 0 records on page 0
CC-MAIN-2019-35: idx200=9,502 but parsed 0/12 -> different HTML era
```

**Constraint 1, three or four HTML eras** need separate parsers; the rich-JSON era is roughly
2022–2024.
**Constraint 2, non-US storefronts are thin.** Index block counts, CC-MAIN-2023-40:
us 15, de 3, jp 3, nl 2, it 2, gb 1, kr 1. Roughly a fifth to a fifteenth of US coverage. A
same-app × multi-country × multi-period intersection collapses. **This is what killed the
cross-country App Store price panel, and with it the EU/DMA pass-through design.**
**Constraint 3, the index server rate-limits hard.** Sustained querying produced
`ConnectionRefusedError: [Errno 61] Connection refused`. Anything at scale must use the columnar
(Parquet) index on S3, not the CDX API.

Also verified negative: the **live 2026** App Store page uses a different renderer
(`serialized-server-data`), carries no `versionHistory`/`ratingCountList`, and its
`hasExternalPurchases` flag reads `False` for Spotify, Kindle, Netflix, Tinder, NYTimes, so it is
*not* a usable indicator of external-purchase-link adoption in the US.

---

## §5 Apple's own pass-through study. VERIFIED, and it reframes that question

Downloaded `https://developer.apple.com/download/files/DMA-Study-Nov-2025.pdf`.

**Jane Choi, Ph.D. (November 2025), "What Happens to App Prices when Developers Pay Lower
Commission Fees? Evidence from the European Union."** Cover page: "Support for this study was
provided by Apple."

Its numbers, quoted: ~21,000 unique paid apps and in-app purchases; 41 million+ transactions;
€20.1 million in commission savings; "developers kept prices the same or increased them on 91% of
products"; "86% of commission savings went to non-EU developers."

Two observations. First, it runs on **Apple's internal transaction data**, which nobody can audit.
Second, as described it is a **share-of-prices-changed calculation, not a causal design**, the
comparison is to "usual patterns in price changes," with no explicit control group, no event
study, no counterfactual. An independent, public-data, properly identified pass-through study is
therefore genuinely valuable. It is also, on this laptop, not buildable, see §4.3 Constraint 2.
Recorded as a strong idea whose data does not exist for me. **Marked dead for this project, live
for a co-author with Sensor Tower or appfigures access.**

---

## §6 Steam. VERIFIED, and this is where the project landed

### 6.1 The event
- **Announced 25 October 2023; effective 20 November 2023.** Valve ended Turkish Lira and
  Argentine Peso pricing; both storefronts moved to USD, and Valve introduced new "LATAM – USD"
  and "MENA – USD" regional price sets covering 25 additional countries.
- Stated reason: exchange-rate volatility making it "hard for game developers to choose
  appropriate prices … and keep them current." **The trigger is Valve's, and macro, not any
  game's demand.**
- Magnitude, from contemporaneous trade press: before the change Argentina and Turkey were the
  two cheapest Steam regions "by a huge margin," with $60 US games selling for under $5. After:
  increases "by as much as more than 4,000 per cent"; **Stardew Valley +2,900%, Far Cry 5 +240%**.
- Official Valve FAQ page exists at `help.steampowered.com/en/faqs/view/2720-4EC7-B95A-1D2A`.

**The dose varies enormously across games and in a structured way** (cheap indie titles were
disproportionately underpriced in TRY, so they took the biggest percentage increases). That is the
identifying variation.

### 6.2 The outcome data. VERIFIED FREE, COMPLETE, DEEP
`https://store.steampowered.com/appreviews/{appid}?json=1&filter=recent&language={lang}&num_per_page=100&cursor=…`
No API key. Fields confirmed on live data:

```
review:  recommendationid, timestamp_created, timestamp_updated, language, voted_up,
         steam_purchase, received_for_free, refunded, written_during_early_access,
         primarily_steam_deck, votes_up, weighted_vote_score
author:  steamid, num_games_owned, num_reviews, playtime_at_review, playtime_forever,
         playtime_last_two_weeks, last_played
```

Two properties that make this unusually good:
1. **`language` is a country proxy, and `turkish` is a clean one.** Turkish is spoken essentially
   only in Turkey. (`latam` is NOT clean, see §6.4.)
2. **`steam_purchase = false` means the copy was activated from a non-Steam key**, i.e. a
   third-party/gray-market key. This is a *directly observable substitution margin*.

Pagination depth, measured:
```
Stardew Valley (413150), language=turkish
   40 pages  ->  3,998 reviews, back to 2025-07-22
  200 pages  -> 19,993 reviews, back to 2022-12-03
  400 pages  -> 24,593 reviews, back to 2021-12-30   (no cap hit; the cursor kept advancing)
   by year: 2022 345 | 2023 7,497 | 2024 5,941 | 2025 3,808 | 2026 2,402
```

Raw annual Turkish review counts for this one game already fall 21% then 36% after the change.
That is not yet evidence, it needs the controls, but the pipeline reaches the pre-period, which
was the thing that had to be true.

### 6.3 Prices. VERIFIED for the present, PARTIAL for the past
`https://store.steampowered.com/api/appdetails?appids=413150&cc={cc}&filters=price_overview`
returns current price in local currency for any storefront:

```
us $14.99 | tr $5.99 USD | ar $4.99 USD | br R$24,99 | ru 299 руб. | de 13,99€ | pl 53,99 zł | cn ¥48
```

Note tr/ar now report **USD**, the change itself is visible in the API today.

**Historical per-game TRY/ARS prices are the one thing I could not verify.** steamdb.info returns
**HTTP 403** to programmatic fetches and its terms restrict scraping; I did not attempt to evade
it. IsThereAnyDeal exposes a price-history API with a free individual key and multi-country
support (`github.com/IsThereAnyDeal/API`), but whether its history includes TRY back to 2023 is
`UNVERIFIED`, that is a 30-minute check to run before relying on it. The design below therefore
does **not** depend on per-game historical prices for its main result; they enter only the
dose-response extension.

### 6.4 A negative finding that reshaped the design
Argentina cannot be isolated. Steam's language tag `latam` is Latin-American Spanish, covering
Argentina alongside Mexico, Colombia, Chile and others. Those other countries were *also* treated
on 20 Nov 2023, but in the **opposite direction**, they moved from plain USD (US prices) onto the
new discounted "LATAM – USD" set, i.e. price *decreases*. Aggregating them into one language cell
mixes opposite-signed treatments. **Argentina is therefore demoted from co-treatment to an
extension** requiring user-level country identification via Steam Community profiles.

Turkey survives clean: `turkish` ≈ Turkey, and Turkey's move was unambiguously a large increase.

### 6.5 Control groups available. VERIFIED PRESENT IN THE DATA
- **Within Turkey:** free-to-play titles (Dota 2, CS2, Warframe, War Thunder, Path of Exile,
  Apex Legends) had no price and so no treatment, while sharing every Turkish macro shock.
- **Across countries:** other cheap/high-volatility storefronts that **kept local-currency
  pricing**, Russia (RUB), Brazil (BRL), Poland (PLN), China (CNY), all confirmed still local in
  the price API above. Russia is the ideal control: comparable currency collapse, no Valve
  treatment.

---

## §7 Running status of the data pull (this session)

`code/pull_steam_reviews.py`, 20 games × 8 languages, resumable per (appid, language), 5 parallel
shards. Confirmed completed cells at time of writing include:

```
413150 turkish  n=24,593  2021-12-30 -> 2026-08-15
413150 latam    n= 6,900  2021-12-05 -> 2026-08-15
431960 turkish  n= 9,799  2021-12-26 -> 2026-08-14
431960 latam    n= 3,900  2021-12-10 -> 2026-08-14
1145360 turkish n= 4,500  2021-12-25 -> 2026-08-14
578080 turkish  n=35,893  2021-12-28 -> 2026-08-14
```

Throughput ≈ 2 min per (game, language) cell for deep pulls. See `research-plan.md` §Timeline for
what this implies for the full sample.
