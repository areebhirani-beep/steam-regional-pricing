# Research plan, committed project

**Working title:** *The Price of Being Priced Like America: Demand for Digital Goods When
Regional Pricing Ends*

Written 15 August 2026. Every number below traces to a command in `verification-log.md` or to a
script in `code/`. Sources I could not verify are marked `UNVERIFIED`.

---

# Phase 3. The graveyard

Six candidates went in. Four are dead. Here is what killed each, with the evidence.

### C1. The 250-investor rule (2018 EGRRCPA §504) and the micro-VC era. **DEAD: scooped.**
I verified the statute (Pub. L. 115-174 §504, 24 May 2018), built the Form D panel (609,582
filings), and *found the result*: small VC funds had a hard ceiling of 99–100 investors every year
2014–2018 with literally zero exceptions, and from 2019Q1 the ceiling jumps to 247–249, with the
first movers being AngelList and FundersClub series funds. Private equity funds show no break.

Then I found **Howell & Parker (2024)**, hosted on sec.gov, drawing on **Howell, Parker & Xu
(2024), "Tyranny of the Personal Network."** Quoting their report: *"In Howell et al. (2024), we
examine the impact of the 2018 investor cap increase on 506(c) take-up using an event study
design. We show that after the 2018 new exemption, smaller VC funds below the $10m regulatory
cutoff are much more likely to use 506(c) relative to funds larger than $10m."* That is the design.
They have Form D **plus PitchBook plus LinkedIn plus a survey plus the SEC's cooperation.** I would
have had Form D. Emailing this to 250 finance professors would have reached Sabrina Howell, who
would have recognised her own paper.

### C6. Rule 506(c) general solicitation. **DEAD: same paper, entire question.**
Howell & Parker is *titled* "VC Funds and Regulation D's Rule 506(c)." Nothing left.

### C2. Apple anti-steering deregulation and commission pass-through. **DEAD: data does not exist for me.**
The question is excellent and live. Apple published its own study in November 2025 (Jane Choi,
*"What Happens to App Prices when Developers Pay Lower Commission Fees?"*, "Support for this study
was provided by Apple") claiming developers kept 91% of the savings, using **internal transaction
data nobody can audit**, with a descriptive share-of-prices-changed calculation rather than a
causal design. An independent public-data replication would be genuinely valuable.

It is not buildable here. It needs *historical in-app prices in EU storefronts*. Verified:
Wayback has **12 snapshots in five years** for the Duolingo US App Store page; Common Crawl's
non-US storefront coverage runs a fifth to a fifteenth of its US coverage (index blocks in
CC-MAIN-2023-40: us 15, de 3, jp 3, nl 2, gb 1, kr 1), so a same-app × multi-country ×
multi-period panel collapses to a few hundred observations. Additionally, **which developers
enrolled in Apple's EU alternative business terms is not public**, and the one public flag that
looked promising (`hasExternalPurchases`) reads `False` for Spotify, Kindle, Netflix, Tinder and
NYTimes. Treatment is unobservable and the pre-period is unpopulated. Dead for me; **live for a
co-author with appfigures or Sensor Tower.**

### C3. Apple's May 2023 price-point liberalisation. **DEAD: no pre-period.**
The event is real and verified (Apple Newsroom, Dec 2022; 87 tiers → 900 price points; existing
apps and one-time IAPs migrated across all 175 storefronts on **9 May 2023**). But measuring
whether cross-country price *dispersion* rose requires prices on both sides of May 2023 in many
storefronts, the same wall as C2. A prospective version is possible but would have a pre-period of
zero.

### C4. Startup pivots reconstructed from web archives. **DEMOTED, not killed.**
Wayback density is the problem again, and there is a deeper issue: a pivot panel is a *measurement*
contribution with no source of variation attached. Without a shock, "does pivoting pay" is
selection. Kept as a possible second paper.

### C5. Founder recycling from Form D RELATEDPERSONS. **DEMOTED.**
The panel is real and free (51,603 person-rows in 2025Q1 alone) and the name-linked
executive panel would be a genuine asset. But I could not find a source of variation in firm
survival that is unrelated to founder quality, and comparing failed to surviving startups is
selection. Also this is the most heavily-fished pond in entrepreneurial finance.

---

# Phase 4. The commitment

## 1. The question, as one testable sentence

**When Valve abolished Turkish Lira pricing on 20 November 2023 and repriced the entire Steam
catalogue in dollars, raising local prices by between roughly 240% and 2,900% depending on the
title, by how much did Turkish demand for paid games fall, and what does that imply about the
price elasticity of demand for digital goods in an emerging market?**

## 2. Why it matters, three sentences

Every firm selling software globally, including Steam, Spotify, Netflix, Adobe, and every consumer
app with a subscription, must decide whether to discount steeply in low-income countries, and it
makes that decision with essentially no causal evidence, because permanent price changes of this
magnitude do not otherwise occur. If demand in these markets turns out to be *inelastic*, the deep
regional discounts that are industry orthodoxy are leaving revenue on the table, and the firms
doing them are wrong; if elastic, abolishing regional pricing destroys both revenue and a large
amount of consumer surplus in exactly the countries least able to bear it. A pricing manager at any
global software firm, and any regulator asking whether platforms should be permitted or required
to price-discriminate geographically, changes their behaviour if the answer is known.

## 3. Identification

**Source of variation.** On 20 November 2023 Valve eliminated the Turkish Lira and Argentine Peso
as Steam currencies and moved both storefronts to USD, simultaneously introducing new "MENA – USD"
and "LATAM – USD" regional price sets. Announced 25 October 2023. Valve's stated reason was
exchange-rate volatility making it "hard for game developers to choose appropriate prices … and
keep them current."

**Why it is plausibly exogenous.** The decision was Valve's, it was driven by macro currency
volatility rather than by conditions in any game's market, it applied to the entire catalogue on a
single date, and it was announced 26 days ahead, long enough to be unanticipated in the pre-period
and short enough to limit strategic repositioning. Crucially, **no individual developer chose it**,
which is what separates this from every price change in observational data.

**Treatment.** Turkish-language Steam users, on paid titles. Steam tags every review with the
reviewer's client language; `turkish` is an unusually clean country proxy because Turkish is
spoken essentially only in Turkey.

**Control groups, three of them.**
- *Across countries:* the 28 other Steam languages (verified: all 29 return data). Russia is the
  ideal comparison, comparable currency collapse over the same years, **but Valve kept Ruble
  pricing**, confirmed live in the price API. Brazil (BRL), Poland (PLN) and China (CNY) likewise
  retained local currency.
- *Within Turkey:* free-to-play titles. Same country, same macroeconomy, same platform, **no
  price**, therefore no treatment.
- *Within game:* the same title in other languages in the same month.

**Threats, and how each is handled.**

| Threat | Handling |
|---|---|
| Turkey's macroeconomy (lira collapse, inflation) reduced game demand independently | The triple difference uses free-to-play titles *in Turkish* as the within-country control, absorbed by language × month fixed effects. Anything hitting Turkish players in a month (income, inflation, internet outages, holidays) is differenced out. |
| Review-writing propensity changes with price (people who paid more may review more, or angrier) | Test directly: `share_pos`, median `playtime_at_review`, and median `num_games_owned` of reviewers are all observable. If the reviewer *composition* is stable, the propensity story is weak. Reported as a table, not hand-waved. |
| Turkish users migrate to gray-market keys rather than exiting | This is measured, not assumed: `steam_purchase = false` identifies copies activated from non-Steam keys. It is an outcome, not a confound. |
| Turkish users change their Steam account region | Their reviews stay Turkish-language, so the estimand remains "demand of Turkish *people*", which is the object of interest. Region-switching is one of the substitution margins. |
| One treated cluster makes cluster-robust inference on language impossible | **Randomization inference across all 29 languages**, which bounds the attainable one-sided p-value at 1/29 = 0.034. Reported alongside SEs clustered at game × language. |
| Anticipation in the 26-day announcement window (stockpiling before the increase) | Visible directly in the event study; the window is excluded from the "pre" period and shown separately. A pre-event demand spike would be evidence *for* the mechanism. |
| Composition of the game catalogue changes over time | Panel is restricted to titles released before 2022, so entry/exit is not driving it. |

## 4. Data

| Source | Verified URL / endpoint | Variables | Coverage | Access |
|---|---|---|---|---|
| **Steam review histories** | `https://store.steampowered.com/appreviews/{appid}?json=1&filter=recent&language={lang}&num_per_page=100&cursor=…` | `timestamp_created`, `language`, `voted_up`, `steam_purchase`, `received_for_free`, `refunded`, `written_during_early_access`, `author.steamid`, `author.playtime_at_review`, `author.playtime_forever`, `author.num_games_owned`, `author.num_reviews` | Full history; verified pagination to **Dec 2021** at 400 pages and still advancing | Public HTTP, **no API key** |
| **Steam store metadata & prices** | `https://store.steampowered.com/api/appdetails?appids={id}&cc={cc}` | name, `is_free`, release date, genres, developer, publisher, `price_overview` (currency, initial, final, discount) in any storefront | Current cross-section, ~40 storefronts | Public HTTP, no key |
| **Steam app list** | `https://api.steampowered.com/ISteamApps/GetAppList/v2/` | every appid on Steam | Current | Public, no key |
| **Valve policy record** | `help.steampowered.com/en/faqs/view/2720-4EC7-B95A-1D2A`; Steam news post of 25 Oct 2023 | Event date, affected currencies, new regional price sets |, | Public |
| **Historical local prices (dose)** | IsThereAnyDeal API, free individual key (`github.com/IsThereAnyDeal/API`) | historical price by store and country | `UNVERIFIED` whether TRY history reaches 2023, a 30-minute check | Free registration |

**Observation counts, measured not estimated.** Stardew Valley alone returned **24,593 Turkish
reviews** back to 30 Dec 2021 and has 28,274 Turkish reviews lifetime. Across the 29 languages
Stardew has 392,117 English, 194,725 Simplified Chinese, 82,953 Brazilian Portuguese reviews. The
proof-of-concept panel already standing on disk is **211 MB of raw review JSON, 557,854 reviews,
15 games × 7 languages**. The full target sample (§ Sample below) is on the order of **8–15 million
reviews**.

**Terms of service.** The `appreviews` endpoint is documented by Valve for third-party use at
`partner.steamgames.com/doc/store/getreviews`; it is a public JSON endpoint requiring no
authentication, and the pull runs at ~4 requests/second with a descriptive User-Agent. I did *not*
scrape steamdb.info: it returned **HTTP 403** to programmatic requests and its terms restrict
scraping, so it is excluded and noted as excluded.

## 5. The estimating equation

Primary specification, a triple difference on the game × language × month panel:

$$
\ln(1+Q_{glt}) \;=\; \sum_{k \neq -1}\beta_k \cdot \mathbf{1}[t = t^{*}+k]\cdot \text{TR}_l \cdot \text{Paid}_g
\;+\; \alpha_{gt} \;+\; \delta_{lt} \;+\; \gamma_{gl} \;+\; \varepsilon_{glt}
$$

- $Q_{glt}$, count of reviews for game $g$ in language $l$ in month $t$; the demand proxy.
- $\text{TR}_l$, 1 if language $l$ is Turkish.
- $\text{Paid}_g$, 1 if game $g$ has a positive price (0 for free-to-play).
- $t^{*}$, November 2023; $k$ indexes months relative to the event; $k=-1$ omitted.
- $\alpha_{gt}$, **game × month** fixed effects: absorb every global shock to a title (sales,
  patches, DLC, esports events, seasonality, the game's own life cycle).
- $\delta_{lt}$, **language × month** fixed effects: absorb everything hitting speakers of a
  language in a month, including the Turkish macroeconomy.
- $\gamma_{gl}$, **game × language** fixed effects: absorb persistent affinity between a title and
  a linguistic market, and the language-specific review-propensity constant. *This is why the
  unknown reviews-to-sales multiplier does not bias the estimate: it is a level, and it differences
  out.*
- Standard errors clustered at **game × language**, the level at which the panel's serial
  correlation lives, with randomization inference across the 29 languages as the inferential
  backstop because treatment is assigned to one language.

**Coefficient of interest:** $\beta_k$ for $k \ge 0$, and its static analogue
$\beta = \sum_{k\ge0}\beta_k / K$. **Expected sign: negative.**

The implied own-price elasticity is $\hat{\varepsilon} = \beta / \Delta\ln P$, where $\Delta \ln P$
is the log price increase. Because $\Delta\ln P$ varies by title (240% ⇒ 1.22 log points; 2,900% ⇒
3.43), the elasticity is reported as a **range and a dose-response**, not a single number:

$$
\ln(1+Q_{glt}) = \theta \cdot \text{TR}_l\cdot\text{Post}_t\cdot \Delta\ln P_g + \alpha_{gt} + \delta_{lt} + \gamma_{gl} + \varepsilon_{glt}
$$

with $\theta$ the elasticity directly. **This is the specification that needs historical prices,
and it is the specification I may not be able to complete alone, see §17.**

## 6. Falsification and robustness

1. **Placebo event.** Re-run the identical specification with a fake event date of 20 November
   **2022**, on a window that ends before the true announcement. $\beta$ must be indistinguishable
   from zero. Repeat at 20 May 2023 and 20 May 2024.
2. **Placebo treated group.** Randomization inference: relabel each of the 28 non-Turkish
   languages as treated in turn and re-estimate. Turkish must sit in the tail. *Already run on the
   7-language pilot: Turkish is the most negative estimate, −0.615, against a next-most-negative of
   −0.097.*
3. **Free-to-play placebo, stated in advance.** Free titles have no price and must show
   $\beta \approx 0$ in the Turkish × Post interaction. *In the pilot the free-to-play title moved
   the other way: PUBG's Turkish review flow rose +31% while every paid title fell 12–58%.*
4. **Reviewer composition.** `share_pos`, median `playtime_at_review`, median `num_games_owned`.
   If the fall in counts were a review-propensity artefact rather than a demand fall, reviewer
   composition should shift; test whether it does.
5. **Russia falsification.** Russia had a comparable currency collapse and *no* Valve treatment.
   If the Turkish effect is macro rather than price, Russian flow should fall similarly. It does
   not: the pilot estimate for Russian is *positive*.
6. **Leave-one-game-out** and **leave-one-language-out** re-estimation.
7. **Poisson (PPML)** on raw counts instead of log(1+Q), to check the zero-handling.

## 7. What the paper looks like either way, and the null is publishable

**If demand turns out inelastic** (the pilot points here: a ~46% quantity fall against a price
increase of at least 240%, implying $\hat\varepsilon$ between roughly −0.2 and −0.6): the headline
is that *the deep regional discounts were revenue-reducing*, that Valve and its developers made
more money from Turkey after tripling-to-tenfold-ing prices, and that the entire welfare loss
landed on Turkish consumers. That is a striking, contrarian, industry-relevant result.

**If demand turns out elastic** ($\hat\varepsilon < -1$): the headline is that abolishing regional
pricing destroyed revenue *and* consumer surplus, a lose-lose, and that regional price
discrimination in emerging markets is not corporate charity but profit-maximisation, which is the
standard defence platforms give regulators and which has never been tested.

**If the effect is a precise zero:** that is the most interesting outcome of the three. It would
say demand for digital entertainment in an emerging market is essentially price-insensitive over a
3–10× range, which contradicts the stated premise of every regional pricing scheme in the software
industry, and it would be a genuine puzzle worth a paper. The design is powered to distinguish a
precise zero from a noisy one, which is what makes the null publishable rather than a file-drawer
result.

I am not spending a year on a coin flip: **all three outcomes are papers**, because the object
being estimated, an elasticity nobody has, is interesting at any value.

## 8. Paper structure

| § | Content | Words |
|---|---|---|
| 1 | Introduction, the event, the estimate, the three contributions | 1,400 |
| 2 | Institutional setting, Steam, regional pricing, what Valve did and why | 1,000 |
| 3 | Related literature, digital goods pricing, LOP and international prices, video-game demand, piracy and gray markets | 1,200 |
| 4 | Data, construction, the review-flow proxy and its validation, coverage, summary statistics | 1,600 |
| 5 | Empirical strategy, DiD, DDD, dose-response, inference under one treated cluster | 1,300 |
| 6 | Results, main effect, event study, heterogeneity by price tier and genre | 1,800 |
| 7 | Mechanisms: substitution to free-to-play, gray-market keys, extensive vs. intensive margin | 1,200 |
| 8 | Robustness and falsification | 900 |
| 9 | Magnitudes, implied elasticity, revenue arithmetic, consumer-surplus bounds | 900 |
| 10 | Conclusion and what this cannot answer | 600 |
| | **Total** | **≈ 11,900** |

**Tables.** T1 Summary statistics by language and game type. T2 Main DiD and DDD.
T3 Dose-response by price change. T4 Reviewer composition (the propensity test).
T5 Substitution: free-to-play and non-Steam keys. T6 Robustness battery. T7 Placebo dates.

**Figures.** F1 Event study, DiD and DDD panels *(built, `output/figures/fig1_event_study.pdf`)*.
F2 Raw review flow, Turkish vs. control languages, indexed. F3 Randomization inference
distribution across 29 languages. F4 Dose-response scatter: log price change vs. log quantity
change, by title. F5 Reviewer composition over time. F6 Free-to-play substitution.

## 9. Timeline, two-week blocks

| Block | Dates | Deliverable |
|---|---|---|
| 1 | Sep 1–14 2026 | Scale the puller: full 29 languages, resumable, rate-limit-safe. Sampling frame from `GetAppList`, all titles released before 2022 with ≥ 500 lifetime reviews. |
| 2 | Sep 15–28 | Run the bulk pull (background, days). Build metadata for the full sample. |
| 3 | Sep 29–Oct 12 | Panel construction, coverage diagnostics, the pagination-depth problem for high-volume languages. **⚠ most likely to slip, see below.** |
| 4 | Oct 13–26 | Replicate the pilot on the full sample. F1, F2. Summary statistics. |
| 5 | Oct 27–Nov 9 | Full falsification battery: placebo dates, RI across 29 languages, Russia, leave-one-out. |
| 6 | Nov 10–23 | Reviewer-composition tests; substitution margins (free-to-play, non-Steam keys). |
| 7 | Nov 24–Dec 7 | Historical price recovery (ITAD); build dose measure; F4. |
| 8 | Dec 8–21 | Dose-response estimation; elasticity with honest bounds. |
| 9 | Dec 22–Jan 4 2027 | First full draft, §§1–4. |
| 10 | Jan 5–18 | Draft §§5–8. |
| 11 | Jan 19–Feb 1 | Draft §§9–10; internal consistency pass; every number regenerated from scripts. |
| 12 | Feb 2–15 | Replication package: README that rebuilds every table and figure from a cold start. Public GitHub. |
| 13 | Feb 16–Mar 1 | Adversarial self-review; rewrite abstract and introduction until the hook survives a 20-second skim. |
| 14 | Mar 2–15 | **SSRN working paper posted.** Outreach wave 1 (100 emails). |
| 15 | Mar 16–29 | Outreach waves 2–3; JSHS / undergraduate journal submissions in parallel. |
| 16 | Mar 30–May 15 | Respond to replies; run extensions professors ask for; begin co-authored revision. |

**The block most likely to slip is Block 3 (panel construction).** Reason, already observed in the
pilot: the 400-page pull cap binds for high-volume language cells. English on Stardew Valley
returned 39,993 reviews and only reached 2025-08-31, nowhere near the pre-period, while Turkish
reached 2021 comfortably. High-volume controls need pulls an order of magnitude deeper, which is
slow, and the fix has to be designed rather than brute-forced (stratify controls toward mid-volume
languages; run the deep English pull as a long background job started in Block 2, not Block 3).

**Honest hour estimate: 300–340 hours.** Roughly 90 on data engineering, 70 on analysis, 90 on
writing, 50 on the replication package and outreach. This fits the budget, but only because the
pipeline already works, see Phase 5. Had it not, I would have told you the number was 500.

## 10. The three most likely ways this fails

1. **Review flow is a bad proxy for units in exactly the way that matters.** *Rank: highest.* If
   Turkish players who kept buying became *less* likely to review, because the same money now
   buys one game instead of five, changing who reviews, the count falls without demand falling as
   much. *Mitigation:* reviewer-composition tests (§6.4); validate the proxy against `total_reviews`
   growth in untreated languages; report bounds. *Early warning:* median `num_games_owned` or
   `playtime_at_review` of Turkish reviewers shifts sharply at the event.
2. **The price change cannot be measured per title.** *Rank: second.* Without historical TRY
   prices the dose-response is unidentified and the elasticity becomes a range under assumption
   rather than an estimate. *Mitigation:* ITAD API; failing that, reconstruct from Valve's
   published recommended-price grids; failing that, present the reduced form as the result and
   make the elasticity the co-author's contribution. *Early warning:* the ITAD check in Block 7
   comes back without 2023 TRY coverage, **run that check in Block 1 instead, not Block 7.**
3. **Turkish macro swamps the price effect and the DDD cannot separate them.** *Rank: third.* If
   free-to-play demand in Turkey responds to income shocks in the opposite direction to paid demand
   for reasons unrelated to price, the within-country control is contaminated. *Mitigation:*
   Russia as an external check; sharpness of the November break against the smoothness of the lira
   path; event study at weekly frequency around the date. *Early warning:* pre-trends in the DDD
   panel that are not flat.

---

# Phase 5. Proof that the pipeline works

This is not a proposal. The following has been run.

**Pull.** `code/pull_steam_reviews.py`, 40 games × up to 8 languages, 10 parallel resumable
shards. On disk at time of writing: **211 MB, 557,854 reviews**.

**Panel.** `code/build_panel.py` → `data/interim/panel_weekly.parquet`. One real bug was found and
fixed in the process: a datetime-resolution mismatch between `to_period("W-MON").start_time` and
`pd.date_range(freq="W-MON")` silently reindexed every weekly count to `NaN`, which `fillna(0)`
then turned into a panel of clean, plausible, entirely fictitious zeros. It is recorded here
because it is the exact class of error that survives into published tables.

**Estimation.** `code/analysis.R` using `fixest`, on 15 games (12 paid, 3 free-to-play) × 7
languages × 36 months, 1,995 game-language-month observations:

```
(1) DiD, paid games only            log_n ~ turkish:post | appid^month + appid^language
        turkish:post   -0.6154   (se 0.0935)   t = -6.58   p = 5.2e-08

(2) DDD, + free-to-play control     log_n ~ tr_paid:post | appid^month + language^month + appid^language
        tr_paid:post   -0.5485   (se 0.1683)   t = -3.26   p = 0.0019

(3) Gray-market share               share_nonsteam ~ turkish:post | appid^month + appid^language
        turkish:post   +0.0071   (se 0.0090)   t =  0.78   p = 0.44        [null, honestly reported]

(4) Randomization inference across languages (7 available in the pilot)
        turkish -0.615 | german -0.097 | schinese -0.084 | polish -0.016 | latam +0.358 | brazilian +0.458
        Turkish is rank 1 of 7. RI p = 1/7 = 0.14, which is the *minimum attainable* with 7 languages.
```

**A −0.615 log-point fall is a 46% decline in Turkish demand for paid games.**

Raw, before any regression. Turkish review counts, Jan–Oct 2023 vs. Jan–Oct 2024:

```
Red Dead Redemption 2   11,804 -> 4,980   -57.8%   (paid)
Portal 2                 1,875 -> 1,160   -38.1%   (paid)
Hades                      932 ->   608   -34.8%   (paid)
Stardew Valley           5,752 -> 4,225   -26.5%   (paid)
Wallpaper Engine         1,585 -> 1,389   -12.4%   (paid)
PUBG: BATTLEGROUNDS      4,635 -> 6,077   +31.1%   (FREE-TO-PLAY)
```

Every paid title down. The free title up, consistent with substitution from paid to free within
Turkey, which is a result in its own right.

**Figure 1 is built** (`output/figures/fig1_event_study.pdf/.png`): flat pre-trend hugging zero for
sixteen months, a sharp break at the event, and a persistent −0.5 to −0.7 level for eighteen months
after.

**One inference fix is already identified and priced.** With 7 languages the randomization-inference
p-value cannot go below 0.14. I verified that **all 29 Steam languages return review data** for a
test title (english 392,117 lifetime reviews … bulgarian 88). Pulling all 29 lowers the attainable
floor to 1/29 = **0.034**. That is a known, bounded, half-a-block task.

---

# Deliverables for outreach

## 11. Working title and abstract

> ### The Price of Being Priced Like America: Demand for Digital Goods When Regional Pricing Ends
>
> On 20 November 2023 Valve abolished Turkish Lira pricing on Steam and repriced its entire
> catalogue in dollars, raising local prices by between roughly 240% and 2,900% overnight. I use
> this platform-imposed shock to estimate the price elasticity of demand for digital goods in an
> emerging market, assembling a new panel of *[N]* million Steam reviews across 29 languages and
> *[G]* titles, every review carrying a timestamp, a language, a playtime, and a flag for whether
> the copy was activated from a non-Steam key. Because Steam tags reviews by client language, and
> because free-to-play titles were untouched by a change that hit every paid title, the design is a
> triple difference: Turkish versus other languages, paid versus free titles, before versus after.
> Turkish demand for paid games falls by *[X]%* relative to control, with a flat pre-trend over the
> preceding sixteen months and no comparable movement in Russian, a market with a similar currency
> collapse whose Ruble pricing Valve retained. The implied elasticity is *inelastic*, which means
> the deep regional discounts that are orthodoxy in the software industry were revenue-reducing,
> and that the surplus lost when they end falls almost entirely on consumers in the poorest markets.
> Existing estimates of digital-goods elasticity come from temporary promotions, which conflate
> price sensitivity with intertemporal substitution; this is a permanent, unanticipated, order-of-
> magnitude change.

*(Bracketed values fill in at Block 4; the pilot already gives X ≈ 46%.)*

## 12. The one figure that carries the paper

**Figure 1, the event study.** X-axis: months relative to 20 November 2023, roughly −16 to +18.
Y-axis: effect on log review flow, running about +0.2 to −0.8. A dashed vertical line at the event.

What the eye lands on: **a flat line at zero for sixteen months, then a cliff.** The pre-period
coefficients sit on zero with tight bands, visibly, obviously flat, and at $k=0$ the series drops
to about −0.5 and *stays there* for a year and a half. There is no ambiguity to referee: you do not
need to trust the econometrics, you can see the counterfactual.

It persuades at a glance because it does the two things a reader checks in three seconds, is the
pre-trend flat, and is the break at the right date, and passes both.

## 13. Email subject line

> **Valve raised game prices in Turkey by up to 2,900% overnight. Demand fell less than half.**

## 14. Who to email, and how to segment

**Verified pool.** The 24th International Industrial Organization Conference (Boston, 10–12 April
2026) program lists **72 sessions and 254 papers**, with **536 affiliation mentions across 110
unique institutions**, Boston University 30, Indiana 30, Cornell 26, MIT 18, Yale 17, NYU 16,
Northwestern 13. That is one conference in one of the four relevant subfields and it alone clears
the 200–300 target. *(Marketing Science Conference program size: `UNVERIFIED`, INFORMS had not
posted 2026 program statistics at the time of checking.)*

| Segment | Where they sit | What to lead with | Journals / venues |
|---|---|---|---|
| **A. Industrial organization / digital economics** | Economics departments; NBER IO and Economics of Digitization | The identification: a platform-imposed, catalogue-wide, permanent price change with a within-country placebo group | *RAND*, *JEMS*, *IJIO*, *AEJ: Micro*; IIOC, NBER SI IO, EARIE |
| **B. Quantitative marketing / pricing** | Business school marketing groups | The elasticity itself and the dose-response: a demand curve traced over a 3–10× range | *Marketing Science*, *QME*, *JMR*; ISMS Marketing Science Conference |
| **C. Information systems / platform economics** | IS groups in business schools | The dataset and the platform-governance angle: what a platform's pricing architecture does to its complementors and users | *Information Systems Research*, *MISQ*, *Management Science*; WISE, CIST |
| **D. International economics / open-economy macro** | Economics departments, trade and international finance | The law-of-one-price framing: a forced move into dollar pricing for a digital good, with *quantities* observed | *JIE*, *AEJ: Macro*, *IMF Economic Review*; NBER IFM |

**Named starting points, verified as real and directly adjacent:** José Tudón (ITAM), estimated
Steam price elasticities from within-consumer variation; Yuta Watabe (Xiamen), Han Yang (Academia
Sinica), Eugene Kanasheuski. Steam cross-country gravity, *CJE* 2025; Alberto Cavallo (HBS),
Brent Neiman (Chicago), Roberto Rigobon (MIT), the QJE currency-union price paper this is the
quantity-side complement to.

**Segmentation rule: never send the same email.** An IO economist is bought by the research design
and the placebo; a marketing professor is bought by the elasticity number and its managerial
implication; an IS professor is bought by the panel; an international economist is bought by the
law-of-one-price framing. The figure is identical in all four; the first sentence is not.

## 15. Open extensions the paper deliberately cannot resolve alone

1. **Argentina.** Argentina was treated on the same date, but Steam's `latam` language tag pools
   Argentina with Mexico, Colombia and Chile, countries that moved in the *opposite* direction,
   onto a discounted LATAM–USD set. Separating them requires user-level country identification from
   Steam Community profiles at scale, which raises collection and ethics questions I should not
   resolve unilaterally. Doing so would double the treated sample and give a second, independent
   estimate.
2. **Units, not reviews.** The whole paper rests on review flow as a demand proxy. Anyone with a
   licensed sales panel could validate the proxy directly and convert every estimate from
   "reviews" to "units" and "dollars", which is what turns a reduced form into a welfare
   calculation.
3. **The supply side.** Did developers respond by re-optimising Turkish prices in the months after?
   The design treats the price change as a one-shot shock; in fact developers could and did adjust
   within the new USD grid. Modelling that response requires the full price history and a
   structural pricing model.
4. **Consumer surplus.** A reduced-form elasticity at one large price change bounds but does not
   pin down the surplus loss, because the demand curve's *curvature* over the range matters and a
   single change identifies a chord, not a slope. A structural demand system, and a second price
   change for identification, closes it.
5. **Substitution to piracy.** I observe substitution to free-to-play and to non-Steam keys, and
   find the latter is a precise null. I cannot observe piracy at all. Anyone with torrent-tracker or
   ISP data closes the most policy-relevant margin in the paper.

## 16. What a faculty member actually gains

Honestly, three things, in descending order of how much they will care:

- **A clean natural experiment they did not know existed.** Nobody in economics has written about
  the Turkey/Argentina event; I searched. Large permanent price changes are the scarcest input in
  empirical IO, and this one is exogenous, dated, catalogue-wide, and comes with a within-country
  placebo group handed to you by the platform. That is a scarce asset, and it is the *reason* to
  reply.
- **A built, documented panel.** 29 languages, timestamped, with playtime, purchase channel and
  reviewer identifiers, plus the pull and cleaning code. Assembling it is roughly 90 hours of
  engineering that a professor will not do and a first-year PhD student will resent doing.
- **A cheap paper.** The empirical core is finished before they arrive. Their marginal cost is a
  structural section, a licensed data validation, and a referee-proofing pass, the parts they are
  actually good at and that I am not.

If the honest answer had been "not much," the design would be wrong. The test I applied: *would a
tenured IO economist read the abstract and think "I wish I'd found that event"?* I believe yes,
and that is the whole bet.

## 17. The co-authorship gap

**What I finish alone, by roughly March 2027:** the panel across 29 languages; the DiD, the DDD,
and the event study; the full falsification battery including placebo dates, randomization
inference, Russia, and leave-one-out; the reviewer-composition validation of the demand proxy; the
substitution margins; a public replication package; and a reduced-form magnitude, *demand fell by
X%*.

**What I cannot close, and why:**

| Gap | What it needs | Who has it |
|---|---|---|
| Elasticity rather than a reduced form | Per-title historical TRY prices, to build $\Delta \ln P_g$ | Anyone with licensed price history, or the standing to ask Valve |
| Reviews → units → dollars | A licensed sales panel to calibrate the review multiplier | Marketing/IS faculty with vendor data |
| Consumer surplus | A structural demand system, and a second price change for curvature | Structural IO |
| Argentina | User-level country identification, and an ethics review of it | A university with an IRB and an RA |
| Publication | Referee-proofing, framing for a specific editor, and a name on the paper | The co-author |

**What the paper becomes after they join.** The reduced form becomes a demand estimate with a
welfare number attached; the descriptive substitution results become a story about how consumers in
poor countries adjust to being priced like rich ones; and the policy section, should platforms be
permitted, or required, to price-discriminate geographically, becomes defensible rather than
suggestive.

**Journal tier, stated honestly.** Solo, the reduced-form version is a *Journal of Economics &
Management Strategy* / *International Journal of Industrial Organization* / *Information Systems
Research* paper. Co-authored with the structural section and validated units, it is a
*Marketing Science* or *Management Science* paper, and on the optimistic branch, if the elasticity
is precisely estimated and the welfare calculation is credible, *AEJ: Microeconomics*. I do not
think this is an *AER* or *QJE* paper and I would not claim it is. The event is unusually clean but
it is one event, in one country, in one product category.

**Month-by-month from first reply to submission:**

| Month | Step |
|---|---|
| Mar 2027 | Outreach; first replies. Expect a low single-digit percentage response from 250 emails, that is 5–12 real conversations. |
| Apr 2027 | Calls. Send the replication package, not just the PDF. Identify which gap in the table above each person can close. |
| May–Jun 2027 | One co-author commits. Scope the extension; they pull the licensed data. |
| Jul–Aug 2027 | Joint revision: structural section drafted, units validated, framing set for a target editor. |
| Sep 2027 | **Co-authored SSRN working paper posted with their name on it. This is what exists when I apply.** |
| Oct–Dec 2027 | Conference submissions (IIOC, ISMS, WISE). |
| Q1 2028 | Journal submission. |
| 2029 | First decision, plausibly a revise-and-resubmit. Publication 2029–2030. |

**The blunt version of the timeline.** Economics peer review runs 12–30 months to a *first*
decision. I apply in fall 2027. **There will be no publication by then, and anyone who tells you
otherwise is selling something.** What will exist on the application: a co-authored SSRN working
paper with a named faculty member, a conference presentation, an "under review at *[journal]*"
line if the submission lands by Q3 2027, a public GitHub replication package, and, in parallel and
entirely under my own control, a solo undergraduate-journal publication (*Issues in Political
Economy*, *The Developing Economist*, *Michigan Journal of Economics*), a *Journal of Emerging
Investigators* submission, and a JSHS presentation. That is the realistic package, and it is a
strong one; it is just not the word "published."

---

# Runners-up, and why each lost

**C5, the Form D founder panel.** Name-linking RELATEDPERSONS across 2014–2026 yields a free,
person-level panel of every officer and director of every Reg D issuer in the United States —
51,603 person-rows in a single quarter, which is a genuine asset that nobody has assembled in
public form. It lost because I could not attach a source of variation to it. Every question I could
pose ("do failed founders start again?", "where do they go?") compares firms that failed to firms
that did not, which is selection, not identification. A dataset without a shock is a resource, not
a paper. It is the strongest *second* project on this list, and it becomes a paper the moment a
shock to firm survival that is orthogonal to founder quality is found.

**C2. App Store commission pass-through.** This lost on data, not on merit, and it is the one I
regret. The question is live in front of the European Commission, the DOJ, and the UK CMA right
now; Apple has put a self-funded, non-causal study into that debate using data nobody can check;
and an independent test would be read. It died because the historical prices do not exist for free
in the EU storefronts (Wayback: 12 snapshots in five years; Common Crawl: non-US coverage a
fifteenth of US) and because enrolment in Apple's alternative business terms is not observable.
**Keep this one in your pocket.** It is the first thing to raise with a co-author who has appfigures
or Sensor Tower access, and it may be worth more than the Steam paper if that door opens.
