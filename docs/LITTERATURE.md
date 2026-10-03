# Private Infrastructure Trap — Literature Note: Generators & Household Water Filters

Sep 23, 2026 · @valentine

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

## 3bis. Track C — groundwater: what moves the price of private water

Added 2 October 2026. This track was not covered in the September pass, and it is the best-backed of the three: the cost shock has a published identification strategy and the public-versus-private choice has a published model in the same Indian setting. Farm electricity policy is the price of private water.

**Sekhri, Sheetal (2011), "Public Provision and Protection of Natural Resources: Groundwater Irrigation in Rural India," *AEJ: Applied Economics* 3(4): 29–55.** DOI: [10.1257/app.3.4.29](https://www.aeaweb.org/articles?id=10.1257%2Fapp.3.4.29). The paper closest to our mechanism, and closer than Sekhri (2014). She evaluates a public groundwater provision programme on water tables in Northern India, theorising that public provision leads to sustainable use when the fixed cost of a private well is high, and exploits the cost difference created at a specific depth by the physical limits of surface pumps. Same cost-threshold logic as the trap, run in the opposite direction: public provision displacing private extraction rather than cheap private water displacing public investment. Do not skip — this is the paper a referee will ask how we differ from.

**Sekhri, Sheetal (2014), "Wells, Water, and Welfare," *AEJ: Applied Economics* 6(3): 76–102.** DOI: [10.1257/app.6.3.76](https://www.aeaweb.org/articles?id=10.1257/app.6.3.76). Already in the project folder. Rural poverty is 9–10% higher where depth is below the 8-metre cutoff, and irrigation disputes rise by 25% around it. Useful for the welfare stakes, not for our design — and its microdata are the ones we could not obtain.

**Badiani, Reena & Katrina Jessoe, "Electricity Prices, Groundwater, and Agriculture," NBER chapter in *Agricultural Productivity and Producer Behavior*, 157–183.** [Chapter page](https://www.nber.org/books-and-chapters/agricultural-productivity-and-producer-behavior/electricity-prices-groundwater-and-agriculture-environmental-and-agricultural-impacts-electricity); [working paper PDF](https://kkjessoe.faculty.ucdavis.edu/wp-content/uploads/sites/803/2024/01/BJ_ElectricityH2O.pdf). The design we would borrow. They exploit changes in state electricity prices over time, controlling for aggregate annual shocks and fixed district unobservables, and find an implied extensive-margin price elasticity of groundwater extraction of −0.18, with effects on the area under water-intensive crops. Two things matter for us: the variation is continuous state-year tariffs, not a handful of binary reform dates, which answers the few-treated-states objection; and they must hold a state agricultural tariff panel we would otherwise rebuild by hand.

**Badiani, Jessoe & Plant, "Development and the Environment: The Implications of Agricultural Electricity Subsidies in India," *Journal of Environment & Development*.** [PDF](https://kkjessoe.faculty.ucdavis.edu/wp-content/uploads/sites/803/2024/01/BJP_JED.pdf). The policy-history companion, and the fastest route to a dated reform table. It traces free power from the 1977 Andhra Pradesh campaign through the 1999 AP Electricity Reform Act to the Congress platform of 2004, implemented shortly after the election. Read for the chronology, not the estimates.

**Gupta, Disha (2023), "Free power, irrigation, and groundwater depletion: Impact of farm electricity policy of Punjab, India," *Agricultural Economics* 54(4): 515–541.** [RePEc entry](https://ideas.repec.org/p/ags/iaae21/315001.html). Direct precedent for treating a single state's free-power policy as the shock. Worth reading mainly to see how she handles the Punjab timeline, which is messier than it looks: free power from 1997 under SAD-BJP, withdrawn in 2002, restored around 2005. Reversals are usable variation but rule out a clean staggered-adoption design.

**Fishman, Ram, Upmanu Lall, Vijay Modi & Nikunj Parekh (2016), "Can Electricity Pricing Save India's Groundwater?" *JAERE* 3(4): 819–855.** DOI: [10.1086/688496](https://www.journals.uchicago.edu/doi/10.1086/688496). A Gujarat field experiment paying farmers for electricity they "save". Take-up was high, water use did not move. Read it as a warning about the first stage: the link from the price of power to the quantity of water pumped is not automatic, so our first stage has to be shown, not assumed.

**Cross-reference.** Ryan & Sudarshan (2022), already listed under Track A, belongs here too: in Rajasthan the binding instrument is rationed hours of supply rather than price, and farmers use roughly the socially optimal amount of water on average despite trivial extraction prices. If rationing binds, tariff variation may move nothing. Check which regime applies in the states we would use before committing.

**The problem to settle first.** Farm power subsidies lower the cost of *irrigation* water; our outcome is *drinking* water provision. Same aquifer, often the same tubewell, but not the same good. Either we state and defend the link (rural households using irrigation tubewells domestically, as in Sekhri's setting) or we move the outcome to public irrigation infrastructure. This needs an answer before anything is estimated, not after.

## 3ter. Track C — close reads

Read 2 October 2026. The headline from reading these properly: the obstacle to the farm-power design is not the tariff data, which is reconstructible. It is that in the states with the worst groundwater pressure the market for water clears on **quantity, not price**, so a tariff change there moves nothing.

| Paper | Read | Variation used | Sample | Headline estimate |
| --- | --- | --- | --- | --- |
| [Badiani & Jessoe](https://kkjessoe.faculty.ucdavis.edu/wp-content/uploads/sites/803/2024/01/BJ_ElectricityH2O.pdf) | Full text | State-year flat agricultural tariff (Rs per hp-month) | 587 district-years, 280 districts, 13 states; 1995, 1998, 2002, 2004 | −1.05 mcm of extraction per Rs; elasticity −0.18 |
| [Badiani, Jessoe & Plant](https://kkjessoe.faculty.ucdavis.edu/wp-content/uploads/sites/803/2024/01/BJP_JED.pdf) | Full text | None (review) | — | Policy chronology 1910–2011 |
| [Ryan & Sudarshan](https://www.nber.org/papers/w27473.pdf) | Full text | Geology as instrument for well depth | 4,262 farmers, 300 feeders, 4 districts of Rajasthan, Rabi 2016-17 | +1 sd depth (187 ft) → −INR 8,870 profit per Ha |
| Fishman et al. | Full text | Voluntary metering + payment per unit "saved" | Gujarat | 75% take-up; can reject cuts above 7–13% |
| Gupta (2023) | Not yet (pull the DSE working paper 316 version) | Punjab free-power policy | — | — |

### Badiani & Jessoe — the design we would borrow

**Their outcome is a well count, not a water measurement.** This is the single most useful thing in the paper for us. The CGWB *Dynamic Ground Water Resources* reports do not measure physical extraction; they estimate annual demand as the number of abstraction structures multiplied by the unit seasonal draft. So the dependent variable moves when wells are installed. Their first stage is therefore literally our treatment: cheaper power produces more private tubewells. We do not have to argue that water quantity is the right object.

**The tariff panel is reconstructible.** Prices are a flat monthly fee per horsepower set by the State Electricity Board, with a volumetric rate of zero. They gathered them from *Tariff Schedules of Electric Power Utilities*, published 1997, 1998, 2002 and 2005, which also record the dates tariffs changed. Mean 83.5 Rs per hp-month; Tamil Nadu free; some states above 500. Those volumes are our source. Do not substitute the Planning Commission's average revenue per unit for agriculture: it is revenue divided by units sold, so it is a different object and endogenous to consumption.

**Specification.** District and year fixed effects, standard errors clustered at state, controlling for district rainfall, a state-election dummy, generation and T&D losses. Baseline coefficient −0.417 mcm per rupee, rising to −1.054 with the full control set, implying elasticities of −0.07 and −0.18.

**Three weaknesses to know before copying it.**

1. *The effect is asymmetric.* Splitting the sample, price cuts drive everything; excluding state-years with price decreases leaves −3.2 with a standard error of 4.8. They read this as adoption: farmers install wells when the rate falls and do not abandon them when it rises. For a trap story this is the right direction, but it halves the usable variation.
2. *The output IV is thin.* The second stage runs on 202 district-years with a first-stage F of 11.7. Fine for their claim, too weak to build on.
3. *They name rationing as a reason their elasticity is low.* Where supply constrains pumping, price is not the binding margin. They flag it; Ryan & Sudarshan show it is true.

**The version to copy is the earlier one.** The JED companion describes a 2011 draft of the same project that interacted state tariffs with district hydrogeology — mean minimum and maximum aquifer depth — citing Domenico et al. (1968) and Martin & Archer (1971) for the idea that price times depth is the price of groundwater. That is published precedent for exactly the exposure design we were considering, and it generates within-state variation instead of resting on a handful of treated states. We are not contacting researchers during the exploratory phase, so this is to be rebuilt rather than requested: the tariff series from the Tariff Schedules volumes, the depth interaction from our own CGWB wells.

### Badiani, Jessoe & Plant — the chronology, and one sentence that matters

The review's closing recommendations include investing in public provision of groundwater **in order to crowd out private well construction**, citing Sekhri (2011). Our second leg is already named in this literature as a policy instrument. Nobody has tested whether the causality also runs backwards, which is the project.

It also frames Indian water and power as a *low-level equilibrium trap* (Nelson 1956; Briscoe 1999; Singh et al. 1993 on rural water supply in Kerala) — poor service, so nobody pays, so service stays poor. That is a second naming precedent for "trap", and in drinking water specifically.

Dated chronology, usable as the reform table:

| Year | Event |
| --- | --- |
| 1948 | Electricity Supply Act; vertically integrated State Electricity Boards set tariffs |
| 1977 | Andhra Pradesh: first party to campaign on free power |
| 1991 | Tamil Nadu makes farm power free; still free in 2011 |
| 1996 | Minimum Action Plan: Rs 0.5/kWh farm tariff agreed; only 9 states had done it by 2001 |
| 1999 | AP Electricity Reform Act; a 2000 order to raise farm tariffs 50% was abandoned after opposition |
| 2003 | Electricity Act mandates metering for all user categories |
| 2004 | AP Congress wins on a free-power platform and implements it |

One number for Track A while we are here: roughly 69% of Indian firms had their own generator, at a private cost 24% above grid power (Bhattacharya & Patel 2008, as cited there).

### Ryan & Sudarshan — the threat to the whole design

**Rationing, not pricing, is the de facto groundwater policy.** States set power prices near zero and then cut supply to farm feeders for most of the day. In 2017 the daily ration was 6 hours in Rajasthan and Karnataka, 5 in Punjab, 7 in Andhra Pradesh, 8 in Gujarat, and 9 in Madhya Pradesh, Maharashtra, Haryana and Tamil Nadu. Those states hold 585 million people and produce 65% of India's agricultural output. In Rajasthan the tariff is Rs 0.9 per kWh, 15% of private marginal cost and 7% of social marginal cost — and the ration binds: over 80% of farmers report exactly 6 hours of supply, with use bunched just below it. Pump number and size are regulated too, so the extensive margin is closed off.

The implication for us is blunt. A tariff change in a rationing state-year should do nothing, because quantity already clears the market. The Badiani–Jessoe design is only defensible where and when the ration was not binding. Before anything else on this track, we need the overlap between tariff variation and rationing adoption dates. If it is empty, the shock is unusable and the track closes.

**Their identification, for the record.** Depth substitutes for the ration: since electricity only matters through water, the return to water is a sufficient statistic for the benefit of more hours. Well depth is instrumented with geology from the Bhuvan Bhujal Groundwater Prospect Maps — 62 rock-type categories, 20 aquifer types, fracture density within 2 km and 5 km, plus interactions — selected by post-double-selection LASSO from 419 candidates, first-stage F of 34, with subdivision and plot-size-decile fixed effects and errors clustered at the feeder. A one standard deviation increase in depth cuts profit by INR 8,870 per hectare, about three times the OLS estimate and 14% of output per hectare.

Two notes. First, this is consistent with our failed Andhra Pradesh stage rather than contradicting it: they work *within* four hard-rock districts with subdivision fixed effects and their own survey, not across districts in alluvium. Second, those Groundwater Prospect Maps were produced under the Accelerated Rural Water Supply Programme — a drinking-water programme. Worth checking what they cover outside Rajasthan, since they are a public-provision artefact in their own right.

### Fishman, Lall, Modi & Parekh — what the null actually bounds

**The design.** North Gujarat, UGVCL's Kukarwada substation, 2011-12. Four of 28 agricultural feeders treated; well owners were offered a meter and 2.5 Rs per kWh for every unit consumed below a baseline entitlement, with no charge for going over. Baselines were set as verified pump horsepower times an assumed number of hours, estimated from aggregate feeder data. Of 113 eligible consumers, 84 consented — over 75%, against official expectations — and there was no meter tampering. Rebates were paid through reductions in the flat-rate bill, which caps the rebate at roughly 20% of consumption value.

**The null is tight.** Feeder-level difference-in-differences on log monthly consumption, with feeder and year-month fixed effects, over 28 feeders and 927 feeder-months. Every point estimate is small and positive. They reject reductions above about 7% with OLS errors and 13% clustered at the feeder. Hour-meters on 98 wells reject effects above 0.5 hours of daily pump use, with Lee bounds from −0.42 to 1.14 hours.

**Why this does not contradict Badiani & Jessoe.** Their margin is intensive — same wells, fewer hours — in an area where supply is already rationed to 8 hours a day and water tables run to 300 metres. Badiani & Jessoe's effect is extensive: new wells installed when the flat rate falls. Read together, the two papers say the price of power moves whether a tubewell gets dug and does not move how hard an existing one is run. For us that is the convenient reading, since our outcome is also extensive and decadal. It should be stated explicitly rather than assumed, because a referee will otherwise read Fishman as a null on the whole mechanism.

**A methodological warning we should act on.** Treated farmers were 17 to 33 percentage points more likely to *report* saving water, driven entirely by claims of reducing hours — unverifiable — with no increase in reported use of observable irrigation technology, while the meters showed nothing. Relying on self-reports would have produced a large positive treatment effect out of thin air. Our household-survey outcomes (IHDS, DHS water source) are self-reported in exactly this way, and respondents in a surveyed village have some idea what the surveyor wants to hear.

**Their Table 1 is a ready-made exposure table.** Average agricultural tariff in Rs per unit around 2011: Punjab and Tamil Nadu 0.00, Andhra Pradesh 0.09, Haryana 0.36, Rajasthan 1.21, Karnataka 1.45, Gujarat 1.77, Maharashtra 1.97, Uttar Pradesh 2.10, Madhya Pradesh 2.29, against an all-India cost of supply of 4.91. Share of sown area irrigated by groundwater: Haryana 62%, Punjab 61%, Uttar Pradesh 50%, Gujarat 30%, Rajasthan 23%, Tamil Nadu 22%, Andhra Pradesh 19%, Madhya Pradesh 16%, Karnataka 12%, Maharashtra 11%. The cross-state spread in the tariff is wide and it lines up only loosely with groundwater dependence, which is what an exposure design needs.

The sources behind that table matter more than the numbers: the Planning Commission's annual report on the working of state power utilities, *All India Electricity Statistics*, and the **3rd Minor Irrigation Census (2001)** for electrically powered wells and the groundwater-irrigated share. The MI census blocked us at village level, but its state aggregates are published and usable.

**One reference to add.** Sekhri & Nagavarapu, "Less is more? Implications of regulatory capture for natural resource depletion" (Virginia working paper), on regulatory capture of electricity regulation amplifying extraction. It sits between our two legs — politics shaping the price of private water — and should be tracked down.

### What this changes

1. The rationing map is now the first thing to build, before any tariff table. It decides whether the track lives.
2. If it lives, the specification to run is tariffs interacted with pre-existing aquifer depth, following the 2011 Badiani–Jessoe draft, not a binary reform dummy.
3. The extensive-margin asymmetry is a feature: well adoption responds to price cuts and does not reverse, which is the right time profile for a decadal census outcome.

### Open questions for Jack

1. Can we get the Tariff Schedules of Electric Power Utilities volumes (1997, 1998, 2002, 2005) through a library, given that we are not writing to the authors?
2. Does the irrigation-versus-drinking-water link (section 3bis) survive, or do we switch the outcome to public irrigation?
3. Is a design that only identifies off non-rationing state-years worth the sample it leaves?

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
