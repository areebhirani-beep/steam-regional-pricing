# Outreach pack

The paper is the artifact. This file is how it gets read.

**Rule zero: never send the same email twice.** An IO economist is bought by the research design,
a marketing professor by the elasticity, an information-systems professor by the panel, and an
international economist by the law-of-one-price framing. The figure is identical in all four. The
first sentence is not.

**Rule one: the subject line does the work.** A professor decides in the preview pane.

> **Valve raised game prices in Turkey by up to 2,900% overnight. Demand fell by a third.**

Alternates, if you want to A/B them across batches:

- *A natural experiment in regional pricing you may not have seen*
- *An elasticity for digital goods, identified off a 3x to 30x permanent price change*
- *Steam abolished Turkish Lira pricing in 2023. I measured what happened.*

**Rule two: attach nothing.** Link the PDF and link the GitHub. Attachments trip spam filters and
signal that you expect them to do work before deciding.

**Rule three: one ask, and make it small.** Never open with "will you co-author." Open with a
question only they can answer. The co-authorship conversation happens on the second or third
exchange, or it does not happen.

---

## Segment A: Industrial organization and digital economics

*Economics departments; NBER IO and Economics of Digitization; IIOC, EARIE.*
*Lead with identification. These readers are bought or lost on the research design.*

> Subject: **Valve raised game prices in Turkey by up to 2,900% overnight. Demand fell by a third.**
>
> Professor [Name],
>
> On 20 November 2023 Valve abolished Turkish Lira pricing on Steam and repriced its entire
> catalogue in dollars. Local prices rose by between roughly 240 and 2,900 percent on a single
> date, for reasons that had nothing to do with any individual game: Valve cited exchange-rate
> volatility. Free-to-play titles had no price and so were untreated, which leaves a control group
> inside the treated country.
>
> I used it to estimate the price elasticity of demand for digital goods in an emerging market.
> Turkish demand for paid titles falls 29 percent in a triple difference (−0.343, s.e. 0.083), and
> a dose-response specification recovers an elasticity of −0.331. Randomization inference across
> all 28 Steam languages ranks Turkish first. Latin-American Spanish, whose countries moved onto a
> *discounted* dollar schedule on the same day, moves in the opposite direction.
>
> Paper: [link]. Replication package: [link]. Everything runs on public endpoints, no API key.
>
> The question I cannot answer alone is the one you would ask first. My dose measure assumes
> pre-change lira prices were a common fraction of dollar prices, because per-title historical lira
> quotations are not free. Is there a defensible way to relax that assumption with data you have
> seen used, or is it a licensed-archive problem?
>
> I am a high school junior in Texas, applying to economics programs next year. I would value fifteen minutes
> if you have it, and I am happy to be told the design has a hole in it.
>
> Areeb Hirani

---

## Segment B: Quantitative marketing and pricing

*Business school marketing groups; ISMS Marketing Science Conference.*
*Lead with the number and what it means for a pricing manager.*

> Subject: **An elasticity for digital goods, identified off a permanent 3x to 30x price increase**
>
> Professor [Name],
>
> Almost every estimate of price sensitivity for digital entertainment comes from temporary
> promotions, which confound price sensitivity with intertemporal substitution. In November 2023
> Valve gave us a permanent one: it abolished Turkish Lira pricing on Steam and repriced the whole
> catalogue in dollars overnight, raising local prices several-fold to thirty-fold depending on the
> title.
>
> Demand is inelastic. The dose-response estimate is −0.331 (s.e. 0.153), well above the
> unit-elastic benchmark a zero-marginal-cost seller should price at. The implication is
> uncomfortable for industry practice: Steam's deep emerging-market discount was
> revenue-reducing, and the surplus lost when it ended fell almost entirely on Turkish consumers.
> It is the mirror image of DellaVigna and Gentzkow's uniform-pricing result, and it points at the
> same underlying fact, that geographic prices are set with heuristics rather than elasticities.
>
> Paper: [link]. One figure carries it, and it is on page 11.
>
> My question for you: I observe reviews, not units, and I show the composition of reviewers is
> stable on library size and sentiment while playtime rises. Is that enough to convince a referee
> that the proxy is not doing the work, or is there a validation you would insist on?
>
> Areeb Hirani

---

## Segment C: Information systems and platform economics

*IS groups in business schools; ISR, MISQ, Management Science; WISE, CIST.*
*Lead with the data asset and the platform-governance angle.*

> Subject: **A platform reset every seller's price in two countries on one day. I built the panel.**
>
> Professor [Name],
>
> Most empirical work on platform power studies the platform competing with its complementors or
> shaping what users see. Valve did something different in November 2023: it changed the currency
> its entire catalogue is denominated in, and in doing so reset every independent seller's price in
> Turkey and Argentina simultaneously. Pricing architecture is a platform decision that binds
> thousands of sellers at once, and I have not found it measured.
>
> To measure it I assembled a panel of 1.36 million Steam reviews across 39 titles and 28
> languages. Each observation carries a timestamp, a language, the reviewer's playtime at the
> moment of writing, their library size, and a flag for whether the copy was activated from a
> non-Steam key, which makes gray-market substitution directly observable rather than inferred.
> The collector and the cleaning code are public and require no API key.
>
> Turkish demand for paid titles falls 29 percent. Free-to-play titles in the same country barely
> move.
>
> Paper: [link]. Code and data pipeline: [link].
>
> The extension I cannot do alone: separating Argentina, which was treated on the same date but is
> pooled with the rest of Latin America in Steam's language tags. Doing it properly needs
> user-level country identification at scale, which raises collection and ethics questions I should
> not resolve unilaterally. Is that a project you would want to scope?
>
> Areeb Hirani

---

## Segment D: International economics and open-economy macro

*Economics departments, trade and international finance; NBER IFM.*
*Lead with dominant-currency pricing. This is the segment most likely to see the paper as their own.*

> Subject: **A digital good forced from local-currency to dollar pricing, with quantities observed**
>
> Professor [Name],
>
> The dominant-currency literature has price data and, usually, coarse quantity data. In November
> 2023 Valve moved Steam's Turkish and Argentine storefronts off local currency and onto dollars,
> which is close to a forced currency-union entry for a digital good, imposed by a platform rather
> than a central bank. Because Steam tags every review with the reviewer's client language, the
> quantity margin is observable at the product level and at monthly frequency.
>
> Turkish demand for paid titles falls 29 percent, with an implied elasticity of −0.331. The
> pre-existing differential trend is mildly positive, so netting it out makes the decline larger.
> Latin-American Spanish, repriced downward on the same date, moves the other way.
>
> This is the quantity-side complement to Cavallo, Neiman and Rigobon, in a setting where the
> currency switch is dated to the day and applies to an entire catalogue at once.
>
> Paper: [link].
>
> What I would most value your view on: whether the near-complete absence of a quantity response
> tells us something about pass-through into a market where the seller has no marginal cost, or
> whether I am reading too much into one country.
>
> Areeb Hirani

---

## Follow-up, sent once, ten to fourteen days later

Keep it three sentences. Add one new thing. Never resend the original.

> Professor [Name],
>
> Following up once on the note below. Since sending it I added a weekly event study covering
> Valve's 26-day announcement window, which shows no anticipatory movement, and a leave-one-title-
> out check that moves the estimate only within [−0.490, −0.448].
>
> If this is not your area, I would be grateful for a name rather than a reply.
>
> Areeb

That last sentence is the highest-yield line in the whole pack. People who will not help you will
often forward you.

---

## Named starting points

These are people whose published work the paper engages directly, so the email has a real reason to
exist. Get current addresses from department pages; do not guess them.

| Institution | Person | The connection |
|---|---|---|
| Harvard (HBS) | Alberto Cavallo | Cavallo, Neiman and Rigobon (2014, QJE) is the price-side paper this is the quantity-side complement to |
| Harvard | Gita Gopinath | Dominant Currency Paradigm (2020, AER); this is a forced move to dollar pricing |
| Harvard (HBS) | Feng Zhu | Platform-owner behaviour and complementors (2018, SMJ; 2019, SMJ with Wen) |
| Brown | Daniel Björkegren | Demand for a network good in a low-income country (2019, ReStud); closest antecedent in setting |
| Penn (Wharton) | Aviv Nevo | Nevo, Turner and Williams (2016, Econometrica) solve the temporary-vs-permanent price problem structurally |
| Penn (Wharton) | Kartik Hosanagar | Fleder and Hosanagar (2009, Management Science); platform design and consumption |
| Penn (Wharton) | Pinar Yildirim | Applied theory and empirics of online platforms |
| Berkeley | Stefano DellaVigna | Uniform Pricing in U.S. Retail Chains (2019, QJE); this paper is its mirror image in digital goods |
| Berkeley | Pierre-Olivier Gourinchas | Co-author on Dominant Currency Paradigm |
| Berkeley (Haas) | Steve Tadelis | Online platform markets and their measurement |
| Berkeley (Haas) | Carl Shapiro, Michael Katz | Network externalities (1985, AER); the framework the free-to-play control tests against |
| ITAM | José Tudón | Distilling Network Effects from Steam (2022, QME); the closest existing elasticity for the same market |
| Xiamen / Academia Sinica | Yuta Watabe, Han Yang | Steam cross-country gravity (2025, CJE); nearest neighbour in data |

**Segmenting the long list.** Verified pool from a single conference in a single subfield: the 24th
International Industrial Organization Conference program lists 72 sessions and 254 papers, with 536
affiliation mentions across 110 institutions. Pull author lists from IIOC, the ISMS Marketing
Science Conference, and WISE, then sort each author into segment A, B, C or D by the journal they
publish in most. Send in batches of about 40 so you can revise the template between waves.

**Expected yield.** From 250 well-segmented emails, a low single-digit percentage reply rate is 5
to 12 real conversations. That is the number the whole project is built to produce.
