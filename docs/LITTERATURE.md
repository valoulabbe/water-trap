# Private Infrastructure Trap — Literature Note: Generators & Household Water Filters

Sep 23, 2026 · @Someone

## How to use this note

Scope: the two tracks other than groundwater/geology — backup **generators** and **household water treatment in cities** — plus the shared conceptual apparatus that makes all three the same paper.

Each entry gives a full reference with DOI, a short summary of what the paper actually does (data, identification, headline number), and a line on why it matters for us. The summaries are written so that skipping the paper is a defensible choice.

**Zotero import.** Every entry carries a DOI. Three routes, fastest first:

1. In Zotero, *Add Item by Identifier* (the magic-wand icon) accepts a list of DOIs pasted one per line. The DOI block at the end of this note is formatted for exactly that.
2. A `.bib` file with all entries is attached alongside this note in the chat — drag it into a Zotero collection.
3. For NBER working-paper versions (ungated PDFs), the NBER page has a Download Citation button the Zotero Connector reads directly.

Suggested collection structure: `Private infrastructure trap / 01 Framing`, `/ 02 Generators`, `/ 03 Water treatment`, `/ 04 Method analogues`.

**Skim order if you have one hour:** Brehm–Johnston–Milton (the model *is* our question), Kosec (the political-economy half), Graff Zivin–Neidell–Schlenker (four pages, cleanest design template), Allcott–Collard-Wexler–O'Connell (introduction and the model section only).

## 1. The common framing: private substitutes for public infrastructure

The object is the same in all three tracks: a household or firm can buy a private, divisible substitute for an unreliable or absent public network good (a borewell, a generator, a purifier). The literature has thoroughly established the *first* leg — poor public service raises private adoption — and barely touched the *second* — private adoption changes what the state subsequently builds. Everything below is organised around that asymmetry.

**Brehm, Paul A., Sarah Johnston & Ross Milton (2024), "Backup Power: Public Implications of Private Substitutes for Electric Grid Reliability," *Journal of the Association of Environmental and Resource Economists* 11(6).** DOI: 10.1086/730158. The closest thing to a formal statement of our question. Two parts: (i) evidence that US households buy backup generators and home batteries in response to perceived declines in grid reliability, with adoption concentrated among higher-income households — they use EIA survey data plus California battery-purchase records, and find outages raised battery spending by over $20m in four years; (ii) a model of public provision of reliability when private substitutes exist. The key comparative static: the availability of substitutes *reduces the efficient level of public reliability spending* and raises aggregate welfare. In their calibration, most non-adopters gain, because lower utility reliability spending shows up as lower bills, and they value that more than the lost reliability. Why it matters: it gives us the null. Public retrenchment following private adoption is not per se a trap — it can be the efficient response. Our paper only has a "trap" if we can name why the retreat is inefficient: scale economies the private option forgoes, health externalities (contagion, aquifer depletion), or a political-economy channel where the exiting group is also the group with voice. Their model deliberately does not distinguish generators from batteries, so it transposes to water with no work.

**Kosec, Katrina (2014), "Relying on the Private Sector: The Income Distribution and Public Investments in the Poor," *Journal of Development Economics* 107: 320–342.** DOI: 10.1016/j.jdeveco.2013.12.006. The political-economy leg, and the best design template for the second half of our question. She uses non-linearities in Brazilian federal transfer rules to generate exogenous revenue shocks to municipalities, 1995–2008. Municipalities with higher income inequality or higher median income allocate less of the shock to education — a good with a private substitute — and are less likely to expand public school enrolment; they put it instead into broadly enjoyed infrastructure (parks, roads) or save it. She finds no degradation of public school quality, and shows the reverse flow too: higher public revenue lowers private school enrolment. Why it matters: the design is *exogenous budget shock × prior exposure to the private substitute*, which is exactly transposable to Indian ULBs or panchayats (Finance Commission devolution formulas, population thresholds). It also supplies the mechanism we would need: exit by the rich, not just substitution at the margin.

**Hirschman, Albert O. (1970), *Exit, Voice, and Loyalty*.** Harvard University Press. The original statement: when quality declines, the customers most sensitive to quality — and hence most able to exert voice — are the first to exit, which removes the pressure that would have triggered recuperation. One chapter is enough. This is the sentence our abstract is trying to make causal.

**Courant, Paul N. & Richard C. Porter (1981), "Averting Expenditure and the Cost of Pollution," *JEEM* 8(4): 321–329.** DOI: 10.1016/0095-0696(81)90014-5. The theory of defensive/averting expenditures: what households spend to avoid a public bad bounds their willingness to pay for its removal, but only bounds it — the bound is loose when the private good is an imperfect substitute (RO removes dissolved solids but not the need for piped volume; a generator gives power but at several times the grid tariff). Read the four pages so the WTP claims in the empirical papers below are correctly caveated.

**Szasz, Andrew (2007), *Shopping Our Way to Safety* — "inverted quarantine" and political anaesthesia.** Sociology, not economics, but it names our mechanism cleanly: by switching to the private substitute, people feel individually protected and stop worrying about the collective quality, which lowers political pressure on regulators to invest in and enforce standards for the public system — which in turn pushes more people to the private substitute. Cited in the bottled-water literature as the standard statement of the feedback loop.

**Teodoro, Manuel P., Samantha Zuhlke & David Switzer (2022), *The Profits of Distrust: Citizen-Consumers, Drinking Water, and the Crisis of Confidence in American Government*.** Cambridge University Press. DOI: 10.1017/9781009094443. The empirical counterpart to Szasz for the US: bottled-water consumption is higher among lower-income households despite affordability, and among Hispanic and Black households after adjusting for age, education and income, tracking past public water crises; the growth of commercial water kiosks in poor urban neighbourhoods compounds it. Their positive claim is the mirror of ours — reliable public service *builds* trust in government. Why it matters: the distributional prediction is the opposite of Brehm et al.'s (there, the rich exit). Worth knowing which one India looks like before committing to a welfare story.

## 2. Track A — Generators and backup electricity

**Allcott, Hunt, Allan Collard-Wexler & Stephen D. O'Connell (2016), "How Do Electricity Shortages Affect Industry? Evidence from India," *American Economic Review* 106(3): 587–624.** DOI: 10.1257/aer.20140389. Ungated: NBER WP 19977. The central paper for this track. Plant-level ASI data on Indian manufacturers; shortages instrumented by supply shifts from hydroelectric availability (rainfall-driven). Average reported shortages cut the average plant's revenue and producer surplus by 5–10%, but productivity losses are much smaller because most inputs can be stored through an outage. The mechanism we care about: shortages act like a time-varying input tax for plants with a generator, which self-generate at higher cost, and like an infinite tax for plants without, which simply shut down; because generator costs have strong scale economies, shortages distort the plant size distribution against small plants. They simulate interruptible retail contracts as the fix. Why it matters: establishes the private substitute as lumpy capital with scale economies, so adoption is sharply selected on firm size — which is both our identification problem and, potentially, our distributional story. They also released their data as the India Energy Data Repository, so the state-year shortage series does not need rebuilding.

**Burgess, Robin, Michael Greenstone, Nicholas Ryan & Anant Sudarshan (2020), "The Consequences of Treating Electricity as a Right," *Journal of Economic Perspectives* 34(1): 145–169.** DOI: 10.1257/jep.34.1.145. Non-technical, 25 pages, and the best short account of why the Indian public equilibrium is low-recovery/low-quality: subsidised and unenforced tariffs → utility losses → rationing and poor supply → weaker willingness to pay → more losses. Read it as the political-economy environment in which our private substitution happens; it explains why the state's reaction function to private exit may be muted for reasons that have nothing to do with efficiency.

**Ryan, Nicholas & Anant Sudarshan (2022), "Rationing the Commons," *Journal of Political Economy* 130(1): 210–257.** DOI: 10.1086/717045. Jack's pointer. Electricity rationing to agricultural feeders in Rajasthan as a second-best instrument for managing groundwater extraction; the paper recovers how farmers substitute between rationed power and well depth/capital, and is the main reference for the "geology and depth as a source of variation" idea. Sits at the junction of Track A and the groundwater track — worth reading even though the primary design is electricity.

**Steinbuks, Jevgenijs & Vivien Foster (2010), "When Do Firms Generate? Evidence on In-House Electricity Supply in Africa," *Energy Economics* 32(3): 505–514.** DOI: 10.1016/j.eneco.2009.10.012. Descriptive but useful: World Bank Enterprise Survey data across African countries, modelling the discrete choice to own a generator and the intensive margin of how much to self-generate. Confirms the scale-economy pattern and gives the standard covariates (firm size, sector, outage frequency, ownership). Good for calibrating priors on adoption rates; not an identification template.

**Reinikka, Ritva & Jakob Svensson (2002), "Coping with Poor Public Capital," *Journal of Development Economics* 69(1): 51–69.** DOI: 10.1016/S0304-3878(02)00052-4. Uganda: firms facing unreliable power invest in their own generating capacity, and this substitution *crowds out* their productive capital investment. The closest early statement that the private substitute is not free — it diverts resources from the firm's core investment. Why it matters: gives us an outcome variable beyond "did the public network arrive" — the opportunity cost borne by the adopter. (Verify the exact volume/pages when importing; I have not re-checked the issue.)

**Grimm, Michael, Luciane Lenz, Jörg Peters & Maximiliane Sievert (2020), "Demand for Off-Grid Solar Electricity: Experimental Evidence from Rwanda," *JAERE* 7(3): 417–454.** DOI: 10.1086/707384. Revealed WTP for off-grid solar technologies elicited experimentally in rural Rwanda, with randomised payment periods. Households will devote substantial budget shares to electricity but not enough to reach cost-covering prices, and extended payment periods do not change that. Their stylised welfare comparison concludes off-grid solar is the preferable technology for mass rural electrification, with grid extension concentrated in selected regions. Why it matters: this is the policy literature explicitly recommending that the private/decentralised substitute *replace* grid extension. It is the planner's version of our trap — and a useful foil, because it assumes the substitution is welfare-improving without modelling the state's subsequent investment response.

**Complement worth a skim:** work on solar mini-grid adoption in already-grid-electrified Indian villages (Bihar/UP surveys, *Energy for Sustainable Development*, 2020) — households adopt mini-grids alongside a cheap but unreliable grid, mostly for basic lighting and cooling. It documents coexistence rather than substitution, which is a caution for our sharp-substitution framing.

## 3. Track B — Household water treatment in cities

**Graff Zivin, Joshua, Matthew Neidell & Wolfram Schlenker (2011), "Water Quality Violations and Avoidance Behavior: Evidence from Bottled Water Consumption," *American Economic Review* 101(3): 448–453.** DOI: 10.1257/aer.101.3.448. Ungated: NBER WP 16695. Four pages, and the cleanest template we have. Scanner data from a national US grocery chain matched to EPA drinking-water violations by service area and date. Bottled-water sales rise 22% after violations due to microorganisms and 17% after violations due to elements and chemicals; a back-of-envelope puts nationwide avoidance costs around $60m for 2005 violations, which they stress is a significant *understatement* of total WTP to eliminate violations. Why it matters: the identification is an information/quality shock at the level of the public system, with private purchases as the outcome. Our version runs the same regression and then keeps going — does the utility's subsequent capital plan respond?

**Ito, Koichiro & Shuang Zhang (2020), "Willingness to Pay for Clean Air: Evidence from Air Purifier Markets in China," *Journal of Political Economy* 128(5): 1627–1672.** DOI: 10.1086/705554. The method analogue to imitate. They use the Huai River heating discontinuity plus market-level data on air purifier sales and characteristics, and recover WTP for clean air structurally from the demand system for the defensive good. The point is that a market for a private substitute is an instrument for measuring the value of the public good it substitutes for. Why it matters: if we can assemble Indian purifier sales/ownership by city-year, this is the paper whose structure we borrow — and it shows how to handle the fact that the defensive good is an imperfect substitute.

**Devoto, Florencia, Esther Duflo, Pascaline Dupas, William Parienté & Vincent Pons (2012), "Happiness on Tap: Piped Water Adoption in Urban Morocco," *AEJ: Economic Policy* 4(4): 68–99.** DOI: 10.1257/pol.4.4.68. RCT in Tangier: credit for a private in-house connection to the existing public network sharply raises take-up; the gains are mostly in time use and subjective well-being rather than health. Useful as the demand-side counterpart — when the public network *is* there, what actually blocks connection is liquidity, not preference. Why it matters: our trap story needs the counterfactual that households would have connected had the network arrived. This gives a credible take-up parameter and shows the binding constraint is credit.

**Kremer, Michael, Jessica Leino, Edward Miguel & Alix Peterson Zwane (2011), "Spring Cleaning: Rural Water Impacts, Valuation, and Property Rights Institutions," *Quarterly Journal of Economics* 126(1): 145–205.** DOI: 10.1093/qje/qjq010. Randomised spring protection in Kenya: substantial improvements in source water quality, much smaller improvements at the point of consumption, modest health effects, and revealed WTP well below the cost of provision. Property-rights arrangements shape who benefits. Why it matters: the gap between source quality and household-consumed quality is precisely the space the private purifier occupies. If public investment improves the source but households treat anyway, the substitution is partial and our outcome variable has to be chosen carefully.

**Ashraf, Nava, James Berry & Jesse M. Shapiro (2010), "Can Higher Prices Stimulate Product Use? Evidence from a Field Experiment in Zambia," *American Economic Review* 100(5): 2383–2413.** DOI: 10.1257/aer.100.5.2383. Two-stage randomised pricing of Clorin point-of-use water treatment. Higher prices screen buyers (selection effect) but show little evidence of a psychological sunk-cost effect on use. The classic reference on pricing a private water-treatment good in a poor market. Why it matters: bears on whether purifier adoption in Indian cities is selection on need or selection on income — which determines whose voice is exiting.

**Kremer, Michael, Stephen Luby, Ricardo Maertens, Brandon Tan & Witold Więcek (2023), "Water Treatment and Child Mortality: A Meta-Analysis and Cost-Effectiveness Analysis," NBER WP 30835.** DOI: 10.3386/w30835. Bayesian meta-analysis across 15+ RCTs of water treatment; the pooled child-mortality reduction is large (roughly a quarter) and the intervention is highly cost-effective. Supplies the social return figure our welfare calculation needs, and shows treatment at the household level does deliver health gains — so the trap, if it exists, is about *coverage and cost*, not about the private good failing to work.

### India-specific facts and grey literature

These are for background and calibration rather than citation-grade identification, but they establish that the phenomenon is large and datable.

- **NFHS-based analysis of household water treatment in India** (*Dialogues in Health / Elsevier*, 2025): 41.7% of households practise some water treatment, higher in urban (56.5%) than rural (34.3%) areas, with state variation from over 95% in Nagaland and Kerala to under 10% in Bihar. By method: boiling 38.3%, cloth straining 35.6%, water filter 16.7%, chlorine bleach 8.1%, electronic purifiers 3.3%. Strongest positive predictors are the richest wealth quintile, higher education, pucca housing and urban residence. DOI: 10.1016/j.dialog.2025.100248 (verify on import).
- **MIT study on decentralised treatment and reverse osmosis in urban India** (Rao et al., MIT DSpace, \~2016): 2010 market studies put RO diffusion low, but later studies find adoption above 50% in some urban areas; 2016 interviews confirm that households *on the municipal supply* treat with RO, so RO has spread beyond groundwater-only homes. Also quantifies the reject-water externality — RO discards 30–80% of input water, up to \~82 MLD in Delhi alone.
- **Regulatory hook:** the National Green Tribunal has issued recommendations regulating RO use by TDS thresholds, on the grounds that RO is unjustified where piped water already meets BIS norms. A threshold set by a regulator on a continuous water-chemistry variable is worth checking for RD potential.

The substantive point buried in these: **RO adoption in India is conditional on dissolved-solids chemistry, which is geological.** That is the bridge between this track and the groundwater track.

## 4. The gap

Stated as precisely as I can after this pass:

1. **The forward leg is saturated.** Poor public service → private adoption is estimated repeatedly, across goods (electricity, water, air) and settings, with credible instruments (hydro availability, EPA violations, the Huai River line). Adding another estimate of this would not be a paper.
2. **The return leg is essentially unestimated.** I found no paper that takes exogenous variation in *private substitute adoption* and traces its effect on *subsequent public infrastructure investment or service quality*. Brehm–Johnston–Milton model it and calibrate it; Kosec estimates the budget-allocation version for a good with a private substitute (education), but her variation is in public revenue, not in private adoption. The bottled-water "political anaesthesia" claim is asserted in sociology and advocacy literature, and reviewed in Teodoro et al., but not identified.
3. **The welfare sign is not obvious and that is a feature.** Brehm et al. give conditions under which public retrenchment is efficient and non-adopters gain. Our contribution is stronger if we specify ex ante which of the trap conditions (scale economies, externalities, exit-of-voice) we think binds in the Indian case, and design a test that can distinguish efficient retrenchment from a trap — not just document co-movement.
4. **Operational consequence.** The scarce input is *exogenous variation in the cost or availability of the private substitute*, holding public quality fixed. That is the thing to hunt for in both tracks. Variation in public quality (feeder separation, 24×7 schemes, AMRUT) identifies the forward leg only, and is abundant.

## 5. Design sketch — Track A (generators)

**Unit and outcome.** Firm-level (ASI plants) or district-level. Public-side outcomes: feeder-level supply hours, DISCOM capital expenditure, transformer/feeder additions, agricultural feeder separation roll-out, and (further out) tariff enforcement and collection rates.

**Candidate sources of variation in the cost of the private substitute** — this is the binding constraint, and diesel prices are out per the 23/09 discussion:

- *Capital price of gensets.* Import duty changes and exchange-rate/import-competition shocks on generating sets (HS 8502), from Indian customs data (DGCI&S / Tips), interacted with baseline local dependence on self-generation. This is a genuine cost shifter for the substitute that does not move public supply quality directly. Main worry: genset imports correlate with the broader capital-goods cycle, so the interaction term does the work, not the time series.
- *DG-set bans under GRAP in the Delhi NCR.* A sharp administrative removal of the private substitute, with spatial discontinuities at the NCR boundary and time discontinuities at air-quality thresholds. This runs the experiment in reverse — when the private option is taken away, does public reliability improve or does demand simply go unmet? Attractive because bans are enforced at a well-defined boundary; the threat is that NCR is confounded with everything else about Delhi.
- *Jyotigram / feeder separation in Gujarat (2003–2006)* and later state replications. This identifies the forward leg cleanly (exogenous improvement in public quality), so use it for the *reverse* question that is still interesting and much easier: how fast is private backup capital scrapped when public quality improves? Hysteresis in scrapping is itself evidence of a trap — sunk private capital that keeps households indifferent to public improvement.

**First stage.** Generator ownership and installed self-generation capacity are reported in ASI; the Allcott et al. India Energy Data Repository gives the shortage series to interact with.

**Main threats.** (i) Selection on firm size, given the scale economies documented in Allcott et al. — any shifter of genset prices differentially affects mid-size plants, so heterogeneity by size is not a nuisance but the object. (ii) Public investment in electricity is decided at state/DISCOM level, far above the firms adopting generators, so the political feedback loop is long and diluted — this is the deepest problem with Track A and the main reason I rank it second.

**Honest assessment.** Best data, weakest link between the exiting agent and the political principal.

## 6. Design sketch — Track B (household water treatment)

**Why I rank this first.** The substitute is divisible and cheap, so adoption is not truncated by scale economies the way generators are; its diffusion is datable; the adopting household and the political principal (the municipality/ULB) are at the same spatial scale, so the feedback loop is short; and there is an exogenous determinant of the substitute's *value* that has nothing to do with municipal politics — water chemistry.

**The instrument.** The return to a reverse-osmosis purifier depends on total dissolved solids and salinity, which are set by aquifer lithology. Geological variation in TDS therefore shifts the private benefit of adoption while being plausibly orthogonal to municipal investment capacity, conditional on the usual geography controls. We already hold CGWB well data, which carries water-quality parameters alongside depth — the same source we built the depth interpolation from, reused for a variable that is far more spatially persistent than the water table (a chemistry signature does not flip year to year the way depth does near 8m, which was what killed voie B).

**Reduced form.** City (or ward) × year panel. First stage: baseline TDS/salinity → purifier ownership. Second stage: purifier penetration → municipal piped-water outcomes — household connection rates, 24×7 supply projects, AMRUT project selection and spend, complaint volumes, and reported satisfaction.

**Complementary timing variation.** The diffusion of RO in urban India is recent and uneven, so an event-study on diffusion timing is feasible: brand/distribution entry by city, EMI and e-commerce availability, and the electricity-access precondition (RO needs both pressure and power). The NGT's TDS-threshold recommendations on RO use are a possible regulatory discontinuity — worth a serious look before building anything else, since a clean RD would dominate the IV.

**Design template.** Graff Zivin–Neidell–Schlenker for the reduced form (quality shock → private purchases), Ito–Zhang for recovering WTP from the substitute's market, Kosec for the public-budget response.

**Main threats.** (i) Reverse causality in the timing design — cities where the municipal supply is deteriorating are exactly where purifiers spread, which is why the geological instrument carries the weight. (ii) TDS may directly affect municipal treatment costs and hence public investment, violating exclusion; needs a story or a control for treatment technology. (iii) Purifier ownership is measured coarsely in most surveys (see data section) — CPHS is the exception. (iv) The externality channel (RO reject water, 30–80% of input) affects aggregate demand on the network, which is a confound *and* potentially the welfare story.

## 7. Data to check

**Track A**

| Source | Contains | Limit |
| --- | --- | --- |
| ASI (Annual Survey of Industries) | Plant-level self-generation capacity and fuel spend, 1998– | Access via MoSPI; unit-level files are restricted |
| India Energy Data Repository (Allcott, Collard-Wexler & O'Connell 2015) | State-year shortage series, hydro availability | Public; ends mid-2010s |
| DGCI&S / customs (HS 8502) | Genset import values and volumes by port | Port, not destination district |
| CEA / PFC utility reports | DISCOM capex, supply hours, AT&C losses | Annual, state or DISCOM level only |

**Track B**

| Source | Contains | Limit |
| --- | --- | --- |
| CMIE Consumer Pyramids (CPHS) | Monthly panel, \~170k households, appliance ownership including water purifier | Subscription; urban sampling frame criticised — check before committing |
| NSS 76th round (2018), Drinking Water, Sanitation, Hygiene and Housing | Source, treatment practice, adequacy, satisfaction | Cross-section only |
| NFHS-4 / NFHS-5 | Water treatment method by household, district-representative | Treatment categories coarse; "electronic purifier" only \~3% nationally |
| HCES 2011-12 and 2022-23 | Durable ownership and monthly expenditure | Two points in time, but they bracket the RO diffusion |
| CGWB | Well-level water chemistry (TDS, salinity, fluoride, arsenic) | The unofficial GitHub mirror we already hold has no licence — get the official series for anything published |
| AMRUT / MoHUA dashboards, ULB budgets | City water project selection and capital spend | Coverage starts 2015; earlier municipal capex is hard |
| Census Towns / SHRUG urban directory | Piped supply, treatment status | Already in the repo |

**Note on reuse.** Everything already downloaded for Phase 0 — SHRUG water variables, CGWB, the shrid/district polygons — carries over to Track B without modification. The chemistry columns of CGWB are the piece we have not yet touched.

## 8. Priority reading and open questions

**Tier 1 — read properly (four papers, \~5 hours)** Brehm, Johnston & Milton 2024 · Kosec 2014 · Graff Zivin, Neidell & Schlenker 2011 · Allcott, Collard-Wexler & O'Connell 2016.

**Tier 2 — read the introduction and results tables** Ito & Zhang 2020 · Ryan & Sudarshan 2022 · Burgess, Greenstone, Ryan & Sudarshan 2020 · Devoto et al. 2012.

**Tier 3 — know the result, skip the paper** Steinbuks & Foster 2010 · Reinikka & Svensson 2002 · Ashraf, Berry & Shapiro 2010 · Kremer et al. 2011 and 2023 · Grimm et al. 2020 · Teodoro et al. 2022 · the India RO grey literature.

### Open questions for Jack

1. Does he want the welfare question (is public retrenchment efficient?) or the positive question (does it happen at all)? Brehm et al. make them separable, and they imply different outcome variables.
2. Track B needs the political principal and the adopting household at the same scale. Is he willing to move the project from villages to cities/ULBs, with the data cost that implies?
3. Is the CGWB chemistry route acceptable given the licence problem with the mirror we currently hold, or should we obtain the official series first?
4. On Track A: does he see a cost shifter for genset capital that I have missed? Absent one, Track A is a paper about hysteresis in scrapping private capital after public improvement — still interesting, but a different paper.

### DOI list for Zotero (Add Item by Identifier)

```
10.1086/730158
10.1016/j.jdeveco.2013.12.006
10.1016/0095-0696(81)90014-5
10.1017/9781009094443
10.1257/aer.20140389
10.1257/jep.34.1.145
10.1086/717045
10.1016/j.eneco.2009.10.012
10.1016/S0304-3878(02)00052-4
10.1086/707384
10.1257/aer.101.3.448
10.1086/705554
10.1257/pol.4.4.68
10.1093/qje/qjq010
10.1257/aer.100.5.2383
10.3386/w30835
```

Hirschman 1970 has no DOI — add by ISBN 9780674276604.
