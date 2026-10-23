# Water trap — state of play and decisions needed

Oct 23, 2026 · @valentine

## The question, and what a test of it requires

When households can buy a cheap private substitute for a public service, does the state stop building the public network? Testing this requires one specific thing, and everything in this note follows from it.

We need a cause that makes the private substitute expensive in one place and cheap in another, for a reason unrelated to how good the public service is. Call it a cost shifter. Without one, we only observe that private adoption and weak public provision go together, which is as easily explained by households reacting to bad public service as by the state retreating.

Two further conditions matter for the paper. The outcome has to be public provision itself, not private adoption: that is where the existing literature stops. And the effect has to persist, since a temporary retreat is not a trap.

## The design we started from, and why it was dropped

The original design is still the benchmark every later attempt is measured against, so it is worth restating what made it good.

A suction pump cannot lift water from more than about eight metres. Below that depth a private well is cheap; above it the household needs a submersible pump, which costs far more. The cost shifter is physics, it varies from one village to the next, and two villages at 7.9 and 8.1 metres are otherwise alike. Sekhri (2014) uses exactly this threshold.

We dropped it on 23 September for one reason: the running variable does not exist. Water table depth per village in 1993 is not in either of Sekhri's replication packages, is not published for the Minor Irrigation censuses before 2017-18. Obtaining her own data would have meant writing to her, which you preferred not to do.

Everything since has been an attempt to recover the properties of that design by other means: a cost shifter that is exogenous, that moves the private substitute and not the public network, and that varies at a fine geographic scale.

## What the closed tracks taught

Six tracks are closed, each against a criterion written before I looked at the data. They failed for different surface reasons, but five of the six share one: the cost shifter varied only across states.

That is problematic for two reasons. Statistically, the information in the design is counted in states, not villages, so there are roughly twenty independent units however many villages the data contains. Substantively, states differ in everything at once, including their capacity to build networks, which is the very thing we are trying to measure. A shifter that varies within a district lets us compare neighbouring villages, and those differences cancel.

The working rule I have applied since 2 October: a cost shifter that varies no more finely than the state cannot support this design, regardless of data quality. Annex A lists each closure and its reason.

## Track A: groundwater, with geology as the instrument

This is the main track, and it needs a decision from you on where to run it.

The idea follows Ryan and Sudarshan (2022): rock type, aquifer material and fracture density determine how deep the water table sits, which determines what a private well costs, and geology varies village to village. It recovers the property the eight metre threshold had, without needing observed depth.

My first attempt failed in September. I fitted the whole geology block at once, which overfits. Using their own variable selection, the instrument holds on their terrain, but it travels badly: drop one administrative subdivision and most of the predictive power goes.

Since 8 October I have the detailed geological maps on disk, roughly three orders of magnitude finer than the national map I started from. Two gaps remain.

1. The maps do not carry aquifer material, so I have rock type and fractures but not the third ingredient of their instrument. I am checking whether two coded fields in the detailed maps encode it. No result yet: the script stopped on a control check and needs fixing.
2. Map detail varies across states by a factor of about a hundred, and it is thinnest exactly where the census water outcomes are cleanest. This is the decision below.

## Track C: household water filters

This track measures the private substitute well and has no cost shifter. That is its only problem, and it is a blocking one.

I closed it in September for lack of a pre-period, then reopened it on 7 October: the national health survey records household water treatment method as far back as 1998 and distinguishes filters from electric purifiers. The mass market arrival, the brand "Pureit" nationally in 2008 and the other brand "Tata Swach" in December 2009, falls between survey waves, so there is a before and an after.

I tried local water chemistry as the shifter (Claude's idea). It failed on measurement: of the variation left after district fixed effects, about half is year to year noise at the same station rather than stable spatial signal. Instrumenting with that would be instrumenting with noise.

## Decisions I would like from you

**1. Where do we run the geology track?** The two options cannot be combined, and the choice sets the perimeter for everything downstream.

| Option | Geological detail | Water outcomes |
| --- | --- | --- |
| Andhra Pradesh or Rajasthan | High: tens of thousands of distinct map units, and the instrument has already been tested there | Weaker: census water variables are saturated or patchy |
| Uttar Pradesh | Low: the alluvial plain is close to uniform, so the instrument barely varies within the state | Clean: the best water coverage we have |

My reading is that the instrument has to vary first, since clean outcomes cannot rescue a first stage with no variation. But the trade is real and I would rather you set it.

**2. Do you know of a cost shifter for household filters that varies more finely than the state?** This is the single binding constraint on track C. If there is none, the track closes on substance rather than on data.&#32;

**3. One track deep, or both open on the same mechanism?** This shapes the next few weeks. Running both keeps optionality but means neither reaches an estimate soon.

## Annex A: closed tracks

Each closure was decided against a criterion committed before estimation.

| Track | Cost shifter tried | Why it closed | Closed |
| --- | --- | --- | --- |
| Original design | Depth of the water table at 8 m | Village level depth for 1993 does not exist in any accessible source; interpolation error of about 3.5 m against an 8 m threshold | 23 Sep |
| E: agricultural electricity tariff | Price of pumping | Tariffs are set by state, so treated clusters are bounded however good the data | 2 Oct |
| F: CGWB block classification | Refinancing restrictions on new wells | The restrictions target industry, not agriculture, and over 60% of wells are self financed | 2 Oct |
| G: 1991 tariff liberalisation | Import price of generators | 32 generators imported a year before liberalisation, 140 after, for the whole country: imports are not how India equips itself | 2 Oct |
| B: electricity, household side | Generator cost | Households buy battery inverters, not generators, and no source records inverters before 2014, so there is no pre-period | 8 Oct |
| B: electricity, firm side | Generator cost falls less than proportionally with capacity, so it varies at the plant | Valid variation, but public provision does not vary at the plant, so the only available outcome is the firm's own adoption, which the literature has settled | 8 Oct |
| I: groundwater salinity | Geochemistry deciding filter versus reverse osmosis | About half the variation left after district fixed effects is year to year measurement noise | 8 Oct |

A multi-country extension using DHS data (track D) produced descriptive series for six countries where a private substitute rose as piped public supply fell. It is background, not an identification strategy, since those series are national.

## Annex B: data in hand

All of it is downloaded, checked and recorded with source, date and checksum. The analysis runs in R from a clean clone.

| Source | What it gives | Used for |
| --- | --- | --- |
| SHRUG v2.2 | Village level census outcomes, 1991, 2001 and 2011: piped water, treated piped water, private groundwater, plus village and district boundaries | Outcome variables on every India track |
| Detailed geological maps, 1:50,000 | 820,552 lithology and geomorphology polygons, 3,966,842 national lithology polygons, 859,695 structural features, 236,334 lineaments | Track A instrument |
| Ryan and Sudarshan replication package | Their well depth data, variable selection and block level shapefiles | Replicating and testing their instrument |
| CGWB observation wells | 165,162 readings, 22,795 stations, 2000 to 2025, with coordinates and conductivity | Depth and the salinity test |
| NFHS, waves 3 to 5 | Household water treatment method from 1998, filters distinguished from electric purifiers | Track C adoption measure |
| NSS schedule 1.2 and IHDS | Drinking water source, whether the source was publicly or privately funded, household assets | Cross-checks on tracks B and C |
| DHS, around 70 countries | Harmonised private substitutes and piped supply, georeferenced clusters | Track D descriptives |
| Sekhri replication packages, 2011 and 2014 | Code and poverty outcomes; no depth variable | The original design, now dropped |

## Annex C: papers read

Read in full, and each one decided something. A fuller annotated note exists and I can send it.

| Paper | What it settled for us |
| --- | --- |
| Sekhri, Wells, Water and Welfare, AEJ Applied 2014 | The original threshold design, and the closest precedent |
| Sekhri, Public Provision and Protection of Natural Resources, AEJ Applied 2011 | Nearest antecedent on public provision and private wells |
| Ryan and Sudarshan, Rationing the Commons, JPE 2022 | The geology instrument: rock, aquifer and fractures, and the variable selection track A now follows |
| Allcott, Collard-Wexler and O'Connell, AER 2016 | Self generation by Indian firms; their cost shifter varies by state and year, and generator cost scales with capacity at an exponent of 0.83 |
| Brehm, Johnston and Milton, JAERE 2024 | Closest work on the mechanism, but the public response is calibrated rather than estimated: this is the gap we would fill |
| Badiani and Jessoe, on agricultural electricity tariffs | Their first stage is our treatment; also showed the state level limit |
| Blakeslee, Fishman and Srinivasan, AER 2020 | Counterpoint: well failure does not trigger public provision |
| Meenakshi, review of Indian groundwater interventions, 2026 | Closed track F: classification restrictions target industry, not agriculture |
| Chindarkar, Chen and Sathe, Energy Policy 2020 | The counter-result to sit against: better public supply raised private well ownership in Gujarat |
| Acharya, Tasting Numbers, Water Alternatives 2024 | Reverse osmosis adoption tracks discourse about dissolved solids, not measured quality |
| Hirschman, Exit, Voice and Loyalty, 1970 | The framing of political exit |
