# Phase 1. Six candidate questions

Written 2026-08-15. Generated *after* a first reconnaissance pass on data availability
(see `verification-log.md` §0), because a candidate whose outcome variable does not exist
in free form is not a candidate, it is a daydream.

Two structural facts from recon shape all six:

- **Retrospective app-level outcomes are essentially unavailable for free.** Wayback has ~12
  snapshots in 5 years for the Duolingo US App Store page, one of the ten biggest apps in the
  world. There is no free historical download, revenue, or rank series. Any app-side design must
  either (a) use an outcome that is *retrievable today but timestamped in the past* (customer
  reviews RSS), or (b) be collected prospectively.
- **SEC EDGAR is the opposite.** Form D structured data is complete, free, quarterly since 2008,
  and contains issuer state, industry, amount raised, investor counts, fund type, and the *names
  and addresses of officers and directors*. It is the closest free substitute for Crunchbase or
  PitchBook that exists, and it is systematically under-exploited because everyone with a
  university login uses paid data instead.

---

## C1. The 250-investor rule: did a 2018 statutory footnote create the micro-VC era?

Section 3(c)(1) of the Investment Company Act lets a private fund avoid registration only if it
has **no more than 100 beneficial owners**. For a fund raising $5M this is the binding constraint
on the business model: at 100 LPs you need an average check of $50K, which rules out the
"twenty-friends-and-a-Substack" fund. Section 504 of the Economic Growth, Regulatory Relief, and
Consumer Protection Act (May 2018) raised that cap to **250 owners, but only for a "qualifying
venture capital fund,"** defined by aggregate capital contributions plus uncalled capital below a
dollar threshold. Private equity funds, hedge funds, and larger VC funds of *identical size* were
left at 100. Form D reports, for every private fund offering since 2008: fund type
(Venture Capital / Private Equity / Hedge / Other), amount sold, and **total number of investors
who have already invested**. That is exactly the running variable and exactly the treatment
margin. The design writes itself: a mass point at 100 that should dissolve after 2018 *only* for
small VC funds, with same-size PE and hedge funds as an untreated placebo group sitting in the
same file. Second stage: if the constraint bound, its release should show up downstream as more
micro-funds, more first-time fund managers, and more seed capital reaching issuers outside the
Bay Area–NYC–Boston triangle.

## C2. Anti-steering deregulation: Apple's commission was cut jurisdiction by jurisdiction

Between 2021 and 2025 Apple was forced to relax its anti-steering rules in a *staggered* sequence
that varied by both country and app category: Japan's JFTC (reader apps), the Dutch ACM (dating
apps only, Netherlands only), South Korea's amended Telecommunications Business Act, the EU's
DMA, and, sharpest of all, the 30 April 2025 US contempt ruling in *Epic v. Apple*, which
forced Apple to permit external purchase links at a **zero** commission. This is a country ×
category × time natural experiment in the effective tax rate on a two-sided platform's
complementors. The outcome that matters is pass-through: when the platform's cut falls, do
in-app prices fall, or do developers pocket it? Recon established that **in-app purchase names
and prices are published on public App Store pages** for every storefront, which makes the
cross-sectional panel buildable. The risk is entirely historical: without archived prices before
each event date, this becomes a prospective study with no pre-period.

## C3. Apple's May 2023 price-point liberalization and constrained international price discrimination

Until 9 May 2023 an iOS developer chose one of 87 price *tiers*, and Apple mechanically converted
that tier into a local price in every one of ~175 storefronts. The developer could not price
Brazil differently from Britain. Apple then replaced tiers with **900 price points and per-storefront
control**. That is an exogenous, dated expansion of the pricing *choice set*, the constraint on
third-degree price discrimination was lifted for roughly two million sellers at once. Do sellers
use it? Who? The theory prediction is unambiguous (dispersion across countries should rise toward
the profit-maximizing PPP-adjusted schedule) and the null is interesting (if most developers stay
on Apple's auto-generated grid, the finding is about inattention and default effects at
commercial scale). Apple's default grid is a deterministic function of the base price, so *any*
deviation is a revealed choice, an unusually clean way to separate seller intent from platform
default.

## C4. Startup repositioning: a pivot panel reconstructed from web archives

Pivots are central to how venture capital says it works and are almost entirely unmeasured,
because no database records them. But every startup's homepage `<title>` and meta description is
a dated, archived, one-sentence self-description, and the Wayback Machine has millions of them.
Diffing consecutive snapshots of a firm's own homepage yields a **timestamped panel of
positioning changes**, the first systematic pivot dataset built without survey or interview data.
Match to Form D to observe financing before and after. The question: conditional on raising once,
does repositioning predict raising again, and does the answer depend on whether the pivot moves
*toward* a contemporaneous demand shock?

## C5. Founder recycling: what a startup's death does to the people inside it

Form D's RELATEDPERSONS table gives first name, last name, city, state, and role (Executive
Officer / Director / Promoter) for every officer of every Reg D issuer, 51,603 person-rows in
2025Q1 alone. Name-linking across filings yields a **person-level panel of US private-company
executives, 2008–2026**, free. When a startup stops filing (a death proxy), where do its people
go, a new venture, an established firm, or out of the sample? Does a failed founder's *state*
change? The unresolved piece is the source of variation: comparing failed to surviving startups
is selection, not identification, so this needs a shock to firm survival that is unrelated to
founder quality.

## C6. Rule 506(c): why won't startups advertise that they are raising?

Title II of the JOBS Act (effective 23 September 2013) legalized **general solicitation**, public
advertising of a private securities offering, under new Rule 506(c), at the cost of having to
verify that every purchaser is accredited. Adoption has been strikingly low. Form D records which
federal exemption each offering claims, so the choice is directly observable for every US private
raise since 2013, alongside the amount, the state, and the industry. The question is not "did the
JOBS Act work" but the sharper one: **what is the shadow price of the accreditation-verification
requirement?** Firms that choose 506(b) and forgo advertising are revealing that verification
costs exceed the value of a wider investor pool, and the size of the offering, the number of
investors, and the presence of a placement agent identify who that binds on.

---

### Deliberately unconventional entries

C3 (the treatment is the widening of a *choice set*, not a price or a rule) and C6 (the outcome is
a *revealed shadow price* inferred from a corner solution, not a quantity) are the two that do not
look like a normal DiD paper. C1 is conventional in form but unconventional in that nobody has
noticed the statute.
