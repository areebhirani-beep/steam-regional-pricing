# Correspondence

Four letters, because an IO economist and a marketing professor are persuaded by different things.
The paper is the same in all four. The first paragraph is not.

**Links to use**

- Paper: `https://github.com/areebhirani-beep/steam-regional-pricing/blob/main/paper/paper.pdf`
- Code and data: `https://github.com/areebhirani-beep/steam-regional-pricing`

Post the PDF to SSRN before the first batch and swap the link. A blob URL works today; a dead link
in eighteen months is worse than never writing.

**Before sending**

Keep it under 200 words. Attach nothing, since attachments trip filters and imply they owe you work
before deciding. Ask one question they can answer in two sentences, and never open with
co-authorship. Send twenty, wait a week, then revise.

---

## A. Industrial organization, digital economics

*Economics departments, NBER IO and Digitization, IIOC, EARIE. They are won or lost on the design.*

> **Subject: Valve raised Turkish game prices up to 2,900% overnight. What happened to demand.**
>
> Professor [Name],
>
> On 20 November 2023 Valve dropped the Turkish Lira and repriced the whole Steam catalogue in
> dollars. Local prices rose 240 to 2,900 percent on one date, chosen for exchange-rate reasons
> that had nothing to do with any particular game. Free-to-play titles have no price, so the change
> left an untreated control group inside the treated country.
>
> Turkish demand for paid titles falls 27 percent in a triple difference (−0.317, s.e. 0.057), and
> the dose-response specification gives an elasticity of −0.287. Relabelling each of the 28 Steam
> languages as treated in turn puts Turkish first. Latin-American Spanish, whose countries moved to
> a discounted dollar schedule the same day, moves the other way.
>
> Paper and code: [links]. Public endpoints throughout, no API key.
>
> One thing I cannot resolve. The dose assumes pre-2023 lira prices were a common fraction of
> dollar prices, since per-title lira history is not free. Is there a way around that you have seen
> work, or is it simply a licensed-archive problem?
>
> I am a high school junior in Texas. Fifteen minutes would be worth a lot to me.
>
> Areeb Hirani

---

## B. Quantitative marketing, pricing

*Marketing groups, ISMS. Lead with the number and what a pricing manager does with it.*

> **Subject: A digital-goods elasticity from a permanent 3x to 30x price increase**
>
> Professor [Name],
>
> Nearly every price-sensitivity estimate for digital entertainment comes from temporary
> promotions, which mix price response with intertemporal substitution. Valve supplied a permanent
> one in November 2023: it abolished Turkish Lira pricing on Steam and repriced the catalogue in
> dollars, raising local prices several-fold to thirty-fold depending on the title.
>
> Demand turns out to be inelastic, −0.287 (s.e. 0.055), well short of the unit-elastic point a
> zero-marginal-cost seller should be pricing at. So the deep emerging-market discount was
> revenue-reducing, and the surplus lost when it ended fell almost entirely on Turkish consumers:
> the seller captured 62 to 84 percent of it. That is the mirror image of the DellaVigna and
> Gentzkow uniform-pricing result, arrived at from the opposite direction.
>
> Paper: [link]. The figure that carries it is on page 9.
>
> My question is about the outcome variable. I observe reviews, not units, and validate the mapping
> against SteamSpy owner counts, which are concave in reviews, so I report bounds. Would that
> satisfy you as a referee, or is there a validation you would insist on?
>
> Areeb Hirani

---

## C. Information systems, platform economics

*IS groups, ISR, MISQ, Management Science, WISE. Lead with the panel.*

> **Subject: A platform reset every seller's price in two countries on one day**
>
> Professor [Name],
>
> Work on platform power tends to study the platform competing with its complementors or steering
> what users see. Valve did neither in November 2023. It changed the currency its whole catalogue
> is denominated in, resetting every independent seller's price in Turkey and Argentina at once.
> Pricing architecture binds thousands of sellers simultaneously, and I have not found it measured.
>
> The panel is 9.6 million Steam reviews across 484 titles and 28 languages. Each observation
> carries a timestamp, a language, the reviewer's playtime when they wrote, their library size, and
> a flag for whether the copy came from a non-Steam key, which makes gray-market substitution
> observable rather than assumed. Turkish demand for paid titles falls 27 percent. Free titles in
> the same country fall far less, which is how the design separates price from macro.
>
> Paper and full pipeline: [links]. No API key anywhere.
>
> The extension I should not attempt alone is Argentina, treated the same day but pooled with the
> rest of Latin America in Steam's language tags. Separating it needs user-level country data at
> scale, which raises collection questions I would rather not decide by myself. Worth scoping?
>
> Areeb Hirani

---

## D. International economics, open-economy macro

*Trade and international finance, NBER IFM. The segment most likely to treat it as their own.*

> **Subject: A digital good forced from local-currency to dollar pricing, with quantities observed**
>
> Professor [Name],
>
> The dominant-currency literature usually has prices and only coarse quantities. In November 2023
> Valve moved Steam's Turkish and Argentine storefronts off local currency onto dollars, which is
> close to a forced currency-union entry for a digital good, imposed by a platform rather than a
> central bank. Because Steam tags every review with the writer's client language, quantities are
> observable at product level and monthly frequency.
>
> Turkish demand for paid titles falls 27 percent, implying an elasticity of −0.287. The
> pre-existing differential trend runs positive, so netting it out makes the decline larger.
> Latin-American Spanish, repriced downward the same day, moves up. The window runs 31 months past
> the event with no reversion.
>
> Paper: [link]. This is the quantity-side complement to Cavallo, Neiman and Rigobon, in a setting
> where the currency switch is dated to the day and hits an entire catalogue at once.
>
> What I would most value your read on: whether so little quantity response says something about
> pass-through where the seller has no marginal cost, or whether I am over-reading one country.
>
> Areeb Hirani

---

## Follow-up

Once, ten to fourteen days later. Three sentences. Add something new. Never resend the original.

> Professor [Name],
>
> Following up once. Since writing I extended the window to 31 months past the event, where the
> effect shows no reversion, and added a leave-one-title-out check that moves the estimate only
> between −0.502 and −0.497.
>
> If this is not your area, a name would be as useful to me as a reply.
>
> Areeb

That last line is the highest-yield sentence here. People who will not help you will often forward
you.

---

## Who to write to

These are people whose published work the paper engages, so the letter has a reason to exist. Get
addresses from department pages rather than guessing them.

| Institution | Person | Connection |
| :--- | :--- | :--- |
| Harvard (HBS) | Alberto Cavallo | Cavallo, Neiman & Rigobon (2014, QJE) is the price-side paper this complements |
| Harvard | Gita Gopinath | Dominant Currency Paradigm (2020, AER); this is a forced move to dollar pricing |
| Harvard (HBS) | Feng Zhu | Platform-owner behaviour and complementors (2018 and 2019, SMJ) |
| Brown | Daniel Björkegren | Demand for a network good in a low-income country (2019, ReStud) |
| Penn (Wharton) | Aviv Nevo | Nevo, Turner & Williams (2016, Econometrica) solve the temporary-vs-permanent price problem structurally |
| Penn (Wharton) | Kartik Hosanagar | Fleder & Hosanagar (2009, Management Science) |
| Penn (Wharton) | Pinar Yildirim | Applied theory and empirics of online platforms |
| Berkeley | Stefano DellaVigna | Uniform Pricing in U.S. Retail Chains (2019, QJE); this is its mirror image |
| Berkeley | Pierre-Olivier Gourinchas | Co-author on Dominant Currency Paradigm |
| Berkeley (Haas) | Steve Tadelis | Measurement in online platform markets |
| Berkeley (Haas) | Carl Shapiro, Michael Katz | Network externalities (1985, AER), the framework the free-to-play control tests |
| ITAM | José Tudón | Distilling Network Effects from Steam (2022, QME), the closest existing elasticity |
| Xiamen, Academia Sinica | Yuta Watabe, Han Yang | Steam cross-country gravity (2025, CJE), nearest neighbour in data |

**Building the long list.** One conference in one subfield clears the target on its own: the 24th
International Industrial Organization Conference program lists 72 sessions and 254 papers, with 536
affiliation mentions across 110 institutions. Pull author lists from IIOC, the ISMS Marketing
Science Conference and WISE, sort each name into A, B, C or D by where they publish, and send in
batches of forty so the letter can improve between waves.

**Expected yield.** From 250 well-sorted letters, a low single-digit reply rate is five to twelve
real conversations. That is the number this project exists to produce.
