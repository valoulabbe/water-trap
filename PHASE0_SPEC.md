# PHASE0_SPEC.md — Phase 0 Analysis Specification (v2, depth-RD primary)

**Project:** Private vs. public infrastructure — the "private infrastructure trap"
**This version:** The identification backbone is now the **8-meter groundwater-depth
regression discontinuity** (Sekhri 2014). The lithology/rock-type cross-section is
demoted to a **secondary arm (§9), for later.**
**Purpose of Phase 0:** Cheap kill-shot tests, using mostly existing data, of whether
cheap private groundwater access lowers long-run *public* piped-water provision (a trap),
versus efficient technology assignment.
**Estimated effort:** ~3–5 RA-weeks (faster than v1 if Sekhri's replication data is usable).
**Read alongside:** RA_OVERVIEW.md (the why), RA_INSTRUCTIONS.md (the how).
**Positioning (see §12):** the 8 m discontinuity is Sekhri's, not ours — Sekhri (2011) already
pairs it with public-vs-private fixed-cost logic. Our novelty is the drinking-water *network*
outcome, the *dynamic trap*, and the *political-economy* channel, carried more by the model than
by the identification. Read §12 before writing anything positioned as new.

---

## 0. Quick Track (do this first — target ~1 week)

The minimal viable Phase 0 needs **two free datasets and no GIS, no depth-building,
no scraping.** It rides on Sekhri's already-validated 8 m running variable and just
swaps in our outcome. Everything else in this spec is an **extension** (tagged below),
to be done only if the Quick Track clears its gate or is blocked.

**Inputs:** (1) Sekhri (2014) replication package (openICPSR/AEA — free); (2) SHRUG
Village Directory (free, registration). Nothing else.

**Steps**
1. **Inventory Sekhri's data (½ day) — this is the true first gate.** Confirm it
   contains her depth running variable and **merge keys to SHRUG/Census** (village
   census codes or coordinates). If it does, proceed. If it does *not*, the Quick
   Track is blocked → go to Extension E1 (build depth independently) or escalate.
2. **Replicate her published RD (½–1 day).** Reproduce her poverty/conflict result
   in her own data. This validates the pipeline and the **sign of `z`** (§2). *If it
   won't replicate, STOP and fix before anything else.* (Spec Stage A.)
3. **Merge our outcomes (1 day).** Attach SHRUG public-water variables
   (`tap11`, `tap_treated11`, `private_gw11`) to her villages. Report the merge rate;
   if low, note which states drop.
4. **Run the three core RDs (1 day).** First stage (`private_gw` jumps **down** at
   `z>0`); headline (`tap`/`tap_treated` jumps **up** at `z>0` — the trap signature);
   the any-water placebo (`drnk_wat_f` should **not** jump). (Spec Stage B, C.)
5. **Minimal validity (1 day).** McCrary density test + covariate continuity on the
   covariates already in Sekhri's data. (Subset of Stage E.)
6. **One-page verdict (½ day).** Does the trap signature appear, with a clean first
   stage and no validity red flag? Apply the Quick-Track gate below.

**Quick-Track gate (pre-committed):** proceed to extensions only if (a) Stage A
replicates, (b) the first stage shows a clear downward jump at 8 m, (c) McCrary and
the available covariate-continuity checks are clean, and (d) the headline shows a
public-water discontinuity in the trap direction **or** a precise, interesting null.
A clean null or clean fail here is a successful Phase 0 — it saves the extensions.

**Extensions (optional, ordered; each points to the full detail below)**
- **E1 — Independent depth** from CGWB/India-WRIS interpolation. *Required if Sekhri's
  data won't merge; otherwise robustness/scaling beyond her sample.* (§3.2, §7)
- **E2 — Agriculture mechanism** RD and the "richer-but-worse-public-water" combined
  result, with proper ag data. (§3.4, §6)
- **E3 — Full validity battery:** placebo cutoffs, bandwidth/polynomial/donut
  sensitivity, fuzzy RD with MI-Census pump type, near-well subsample. (§5 Stage E, §7)
- **E4 — JJM modern outcomes:** take-up, scheme type, rollout timing (Wayback). (§3.3)
- **E5 — Secondary lithology arm** and the historical divergence figure (needs
  digitization). (§9)
- **E6 — Pre-1994 / "natural" depth** from CGWB yearbooks (digitization). (§3.2)

The sections below (§1–§11) are the **full reference**: the Quick Track uses §2 (signs),
§3.1 (Sekhri data), and the relevant parts of §5 and §8; extensions use the rest.

---

## 1. What changed from v1 and why

v1 used rock type (alluvial vs. hard rock) as a cross-sectional shifter of private-water
cost. That design has a fatal exclusion problem: geology also drives **agriculture**, and
a large literature (Sekhri 2014 and successors) shows groundwater access raises
agricultural productivity and incomes and lowers poverty. Rock type affects our outcome
through many channels, so a causal reading is not defensible to referees.

The **8-meter discontinuity** fixes this by going local. Suction/centrifugal pumps can
lift water only from shallow depths; past roughly 8 meters below ground level you need a
much more expensive submersible/deep-well setup. Villages whose water table sits *just
above* vs. *just below* 8 m are alike in soil, climate, and settlement, but differ sharply
in the **cost of private groundwater**. That is exactly the variation our theory needs,
and it is purely local, so the agricultural-prosperity confound that sinks the
cross-section becomes — at the cutoff — either continuous (and thus differenced out) or, in
the case of agriculture itself, a **validation** that the cutoff bites (see §6).

## 2. Sign conventions (lock these; do not flip)

| Object | Definition |
|---|---|
| `depth_mbgl` | depth to water table, meters below ground level (larger = deeper = costlier to access) |
| `z` | running variable = `depth_mbgl − 8` (centered at the cutoff) |
| Treatment region | `z > 0` (depth > 8 m): **private groundwater is EXPENSIVE** |
| Control region | `z < 0` (depth < 8 m): **private groundwater is CHEAP** |

Predicted discontinuities when crossing **upward** through the cutoff (z: − → +):
- **Private groundwater use** (tubewells, pumps, handpumps): jumps **DOWN** (cheap access lost). *First stage.*
- **Agriculture / income** (irrigation, yields; poverty): irrigation & income **DOWN**, poverty **UP**. *Replicates Sekhri; validates the cutoff.*
- **Public piped/tap water** (our outcome): jumps **UP**. *The trap signature:* where the cheap private substitute is unavailable, public provision/demand fills in. Equivalently, cheap-water (`z<0`) villages have **less** public water.

**The headline surprise (see §6):** `z<0` villages are *richer* (Sekhri) yet have *less*
public water (us). The public-water discontinuity in the trap direction is **conservative**,
because the income channel pushes the other way (richer places usually get *more*
infrastructure). Finding the trap direction despite that is strong evidence.

## 3. Data acquisition

### 3.1 PRIORITY 1 — Sekhri replication packages (pull BOTH)
Get **both** Sekhri papers' data during the inventory step (see §12 for why both matter):
- **Sekhri (2014)**, "Wells, Water, and Welfare," *AEJ: Applied* 6(3):76–102 — openICPSR
  project **113902** (DOI 10.3886/E113902V1). The RD backbone (poverty/conflict at the cutoff).
- **Sekhri (2011)**, "Public Provision and Protection of Natural Resources," *AEJ: Applied*
  3(4):29–55 — replication `2010-0056_data.zip`, openly downloadable from the AEA article page.
  This one already links the 8 m depth discontinuity to **public groundwater provision** at
  village level (8 UP districts, longitudinal well/aquifer data), so it may be *closer* to what
  we need than the 2014 data and could accelerate Phase 0a — inventory it first.
- **Inventory each precisely** (one-page memo): the exact depth measure and vintage; unit of
  analysis (village? identifiers/coordinates?); bandwidth, kernel, polynomial; outcome and
  covariate definitions; and the **merge keys** (census village codes, district codes, lat/lon)
  — the feasibility hinge for merging our public-water outcomes.
- The fast Phase 0 spine, conditional on the inventory, is: **(a)** reproduce her published
  result in her own data — validates our pipeline and confirms the sign of `z`; **(b)** merge
  our public-water and agriculture outcomes onto her villages; **(c)** run the RD on the *new*
  outcomes using her validated running variable and bandwidth. This inherits a referee-blessed
  first stage and is faster than building depth from scratch.
- If neither package has merge keys to SHRUG/Census (or both are district-only for key vars),
  fall back to independent construction (§3.2) and report the limitation.

**Positioning note (see §12):** Sekhri (2011) is the closest antecedent — same instrument,
same public/private fixed-cost logic. Our novelty is the *drinking-water network* outcome, the
*dynamic trap* and *political-economy* channels, and *welfare under a trap* — not the design.
The RA should flag anything in her 2011 results that pre-empts a claim we plan to make.

### 3.2 Independent depth construction (for scaling/robustness, and if 3.1 won't merge)
- **CGWB / India-WRIS monitoring wells:** ~25,000 stations, 4×/year, machine-readable from
  ~1994. Download station coordinates + levels. **Use the EARLIEST available vintage**
  (mid-1990s) and the **pre-monsoon** reading (the deeper, pump-binding measure). Depth is
  endogenous to cumulative pumping; using the earliest reading minimizes (does not eliminate)
  drawdown contamination. See §7 on why the *local* RD survives an endogenous *level*.
- Interpolate well levels to village centroids (kriging or IDW) → `depth_mbgl`. **Record the
  interpolation and an uncertainty/leave-one-out error per village** — measurement error in
  the running variable is the central technical risk (§7).
- Pre-1994 depths (1970s–80s, closer to "natural") exist only in CGWB yearbooks → digitization,
  a Phase-1 decision, not Phase 0.

### 3.3 Outcomes — public water (SHRUG, free, registration wall)
Same modules and **the same missingness rule as before**: code a water amenity 0 only where
the "any drinking-water facility" flag (`pc91_vd_drnk_wat_f`) is itself non-missing; else drop;
run every headline RD **both ways** (missing=0 and listwise) and flag instability.
- `tap91/01/11` (tap present), `tap_treated11` (treated tap — the high-quality public tech),
  `private_gw91/01/11` (tubewell OR handpump present). 2001/2011 drinking-water variable names
  are **not yet verified** — confirm via docs.devdatalab.org/variable-search/ and record in the
  build-script header before use.
- JJM IMIS (ejalshakti) village-level tap-connection counts, scheme type (single-village
  groundwater vs. multi-village surface), completion dates; pull Wayback snapshots (2019→) for
  rollout *timing*. NRDWP legacy quality-affected-habitation flags (fluoride/arsenic/saline).

### 3.4 Agriculture — mechanism & validation (NOT a placebo here; see §6)
- SHRUG VD irrigation-by-source (ha): `pc91_vd_tw_w_el`, `pc91_vd_tw_wo_el`,
  `pc91_vd_well_w_el`, `pc91_vd_well_wo_el`, `pc91_vd_canal_govt`, `pc91_vd_canal_pvt`,
  `pc91_vd_tank_irr`, `pc91_vd_tot_irr`; 2011 `pc11_vd_land_wl_tw_irr`, `pc11_vd_land_canal_irr`.
- Where obtainable at the RD unit: district/sub-district crop output or yields (Agricultural
  Census / ICRISAT-VDSA / district crop statistics) and a consumption/poverty proxy (SECC-2012
  rural, or Sekhri's own poverty measure from 3.1).

### 3.5 Covariates — for continuity tests (the RD's main validity check)
GAEZ crop suitability, IMD rainfall, SRTM elevation/slope (or SHRUG terrain module), distance
to perennial river (HydroSHEDS), distance to town (`pc91_vd_dist_town` + GIS), baseline
(earliest-census) population and household count, agro-climatic zone, state. These must be
**continuous at z=0**. **Also include, per §7A, baseline aquifer characteristics** (principal
aquifer type / lithology, and storativity or specific-yield where CGWB/NAQUIM provides it) **and
baseline pre-well-era depth** — these are genuinely pre-treatment and must be smooth.

**NOT a balance covariate: the depletion rate.** It is treatment-caused (more wells on the
shallow side → faster drawdown) and *should* jump at 8 m — see §7A. Still **collect** it (the
1990s→2000s trend in CGWB levels for the well feeding the village, plus well-failure status
where available), but use it as the **mediator-separation variable** in the §7A tests (interact
with the RD; restrict to villages whose private option still works), never as a continuity check.

### 3.6 Secondary lithology layer — see §9 (build only if time permits / for Phase 1).

## 4. Running variable & treatment construction

1. Build `depth_mbgl` per unit (from 3.1 preferably, else 3.2); `z = depth_mbgl − 8`.
2. **Heaping:** depth is often recorded to the whole/half meter, creating mass points
   (including at 8). Implement a **donut RD** dropping a small window around the cutoff
   (default exclude `|z| < 0.5 m`; robustness at 0.25 and 1.0) and use heaping-aware checks.
3. **Sharp vs. fuzzy:** if depth is directly measured at the unit, sharp RD. If depth is
   interpolated (measurement error) or treatment is "uses expensive pump," prefer **fuzzy RD**:
   assigned `1{z>0}` instruments for actual deep-extraction technology (pump type from MI
   Census where available), or restrict to villages within X km of a monitoring well as a
   measurement-error-robust subsample.
4. Treatment indicator `D = 1{z > 0}`.

## 5. Estimation

Use local-linear RD with a triangular kernel and MSE-optimal bandwidth, bias-corrected robust
CIs (Calonico–Cattaneo–Titiunik). Python: `rdrobust`, `rddensity` (R fallback if the Python
ports misbehave — note which was used). Cluster by the well/locality where depth is shared
across villages from interpolation.

**Stage A — pipeline & sign validation (do first).**
Reproduce Sekhri's published RD (poverty up, irrigation disputes up, for `z>0`) in her data.
If this does **not** replicate, the pipeline or sign is wrong — STOP and fix before anything else.

**Stage B — first stage.** RD of `private_gw` and (where available) pump ownership / well count
on `z`. Expect a **downward** jump at `z>0`. Report the estimate, bandwidth, effective N.

**Stage C — headline (two margins; lead with take-up).** See §7A: because the public cost is
continuous at 8 m, the *cleanest* margin is **take-up/use conditional on availability** — RD of
JJM household-connection take-up and payment on `z`, run *within* villages that received schemes
(JJM's near-universal push makes availability closer to exogenous). Trap predicts **higher**
take-up at `z>0` (where cheap private water is gone). Then the **supply/investment** margin — RD
of `tap11`, `tap_treated11` on `z`; an upward jump here runs through demand/politics, not
engineering cost. **Split the supply outcome by scheme type** (single-village groundwater point
source vs. multi-village treated network — §3.3): a jump toward the treated *network* is the
trap-about-networks signature. Also report `drnk_wat_f` (any-water): it should NOT jump — good-
access villages aren't waterless, they're *public-network*-less (the RD analogue of v1's
signature distinction).

**Stage D — mechanism/validation (agriculture).** RD of irrigation/yields/poverty on `z`.
Expect the Sekhri pattern. This is **not** a falsification — a jump here is *expected and
required*; it confirms the cutoff bites. See §6 for interpretation and why we do **not**
control for agriculture inside the RD.

**Stage E — VALIDITY BATTERY (this is the gate, §8).**
- **Covariate continuity:** RD of each §3.5 covariate on `z`. All must be **continuous**
  (no significant jump). A jump in soil/climate/baseline-population/distance-to-town at exactly
  8 m would mean the cutoff is proxying something — design fails. **Include baseline aquifer
  characteristics** (lithology, storativity, recharge) and **baseline pre-well-era depth** — these
  are pre-treatment and must be smooth. **Do NOT include the depletion rate or well counts**:
  they are treatment-caused and *should* jump at 8 m (§7A) — testing them for balance is bad
  control, and a jump there is confirmation, not failure.
- **Mediator-separation tests (§7A):** the RD interacted with well-failure/depletion status
  (take-up among shallow-side villages whose private option still *works*), and the timing of
  provision against the depletion trajectory. These distinguish our substitution mechanism (M1)
  from the resource-destruction rival (M2); they are interpretation tests, not validity tests,
  but report them alongside.
- **Density (McCrary / Cattaneo-Jansson-Ma):** no bunching of units at the cutoff (no sorting).
- **Placebo cutoffs:** re-run Stage C at fake thresholds (6, 7, 9, 10 m) — expect null.
- **Secondary placebo outcomes:** roads, schools, clinics, post office on `z` — expect
  continuity (no reason public roads jump at the *water-extraction-cost* cutoff). Power is a
  **contrast, not a placebo** (groundwater pumping raised electricity demand) — discuss, don't
  treat as clean.
- **Bandwidth / polynomial / donut sensitivity:** MSE-optimal ± half/double; local linear vs.
  quadratic; donut at 0.25/0.5/1.0.

## 6. The agriculture question, stated carefully (read before Stage D)

In the v1 cross-section, an agricultural effect of geology was a **confound to rule out**. In
the RD it changes role for two reasons. First, at the cutoff, a jump in agriculture is the
*expected* Sekhri result and **validates** that crossing 8 m really does change groundwater
access — it is a second first stage, not a threat. Second, the public-water RD (Stage C) is a
**net reduced-form** effect that runs through two channels: (i) cheap shallow water directly
substitutes for public drinking water (our trap channel), and (ii) cheap irrigation makes
shallow-water areas richer (Sekhri), and richer areas usually demand/receive *more* public
infrastructure. Channel (ii) biases Stage C **against** finding the trap. So a trap-direction
result (less public water where water is cheap) is observed *despite* the income channel —
which is why it is compelling.

**Do NOT control for agriculture/income inside the RD.** They are post-treatment (they jump at
the cutoff), so conditioning on them induces bad-control bias. The decomposition of channels
(i) vs. (ii) is a job for the structural/theory work, not Phase 0. Phase 0 reports the net
reduced form and notes its conservative direction.

## 7. Why the RD survives endogenous depth (and where it doesn't)

The *level* of `depth_mbgl` is endogenous to cumulative pumping. The **local RD is still valid**
if (a) the density is continuous at 8 m (no precise sorting — implausible that villages tune
their aquifer to 7.9 vs. 8.1 m; McCrary tests this) and (b) covariates are continuous at 8 m
(Stage E tests this). Drawdown over time is itself part of the trap story (cheap access →
overpumping → resource degradation), and assigning treatment by the *earliest* depth with
*later* outcomes is the correct temporal order.

The genuine technical risks, to confront explicitly: **measurement error** in interpolated depth
(attenuates and can bias the RD near the cutoff) → fuzzy RD / near-well subsample / prefer
Sekhri's validated measure; **heaping** at integer depths → donut RD; and the fact that the 8 m
suction-lift threshold is cleanest for **irrigation pumps** — for *drinking* water the
cost gradient runs the same direction but the precise threshold is fuzzier, which is one reason
we retain the lithology arm (§9) as a complementary, broader cost-structure measure.

## 7A. Threats to *mechanism interpretation* (the reduced form is valid; the story needs defending)

The RD's *validity* is defended in §7. This section is about *interpretation* — what the
discontinuity means — because that is where the real challenges sit.

**The key physical fact: the 8 m cutoff bites only for suction-lift technologies.** A
centrifugal/surface pump cannot draw water from more than ~8 m down (atmospheric-pressure
limit). That describes the cheap **private** technologies — a farmer's surface irrigation pump,
a shallow dug well, a suction handpump. It does **not** describe the public technologies that
are our outcome:
- A **piped drinking-water network** places a submersible pump (or a surface intake + treatment)
  *at the source* regardless of water-table depth, so its construction cost is essentially
  **continuous through 8 m** — no reason a network costs more to build at 8.1 m than 7.9 m.
- The standard Indian public point source, the **India Mark II deep-well handpump**, lifts with a
  submerged cylinder and works to ~50 m — **not** bound by the suction limit. (Only cheap
  *suction* handpumps are, and those are not the public default.)

So the treatment changes the **private** cost, not the public cost. This is *good* for the
design: because the public side's cost is continuous at 8 m, a discontinuity in public provision
is more cleanly attributable to **private substitution** than to any public-sector engineering-
cost story. (An earlier draft of this spec wrongly claimed the public cost also jumps at 8 m —
it does not, for networks or Mark II.)

**Consequence: two public-side outcomes, not equally clean. Lead with take-up.**
- **Take-up / use conditional on availability** (do households connect and pay, *given* a scheme
  exists?) is the **cleanest** margin: it is driven purely by private cost, with no public-cost
  contamination. Below 8 m, cheap private water → low connection/payment even where the network
  exists; above 8 m → higher take-up. This is exactly Sekhri's "use of the public system once
  installed," and it is our sharpest reduced form and the "is the trap sticky" test. **Make this
  the headline mechanism result where the data allow.**
- **Supply / investment** (does a scheme get *built*?) cannot be an engineering-cost story
  (public cost is continuous), so a discontinuity here runs through **demand and political
  pressure** — the trap/political-exit channel. That is our mechanism, not a confounder, but it
  is a *behavioral/political* channel and needs the political-salience and inequality-
  heterogeneity evidence (below) to attribute, not just the discontinuity.

**The depletion channel: a COMPETING MEDIATOR, not a confounder — and not a continuity check.**
Depletion is *downstream* of treatment (cheap suction pumps → more private wells → more
extraction → drawdown). Two consequences, and the second corrects an earlier draft of this spec:

1. *It cannot bias the reduced form.* Everything caused by the treatment is legitimately part of
   the effect of crossing the threshold. You cannot be confounded by your own consequences, so
   the Stage C estimate is valid regardless.
2. *Depletion rate must therefore be EXCLUDED from the Stage E covariate-continuity battery.*
   Because more wells are dug on the shallow side, the depletion **rate should jump at 8 m** if
   the mechanism works at all — that jump is confirmation the treatment bit, not evidence of a
   broken design. Putting a treatment-caused variable into a covariate-balance test is the same
   bad-control error §6 warns about. **Keep in the battery only genuinely pre-treatment,
   treatment-invariant characteristics**: aquifer lithology, storativity, recharge, soil, rainfall,
   terrain, baseline (pre-well-era) depth, baseline population. Those must be smooth. Depletion
   rate must not be forced to be.

**Where depletion does bite: two same-signed mediators that the reduced form cannot separate.**
Both run from "cheap private water" to "more public piped water," so the headline estimate is
consistent with either, and a referee from the hydrology literature will press this hard:
- **(M1) Substitution / political exit — OUR mechanism.** Cheap private water → households
  self-supply → they don't demand or connect to the network → public provision crowded out.
  Runs through *choice*. Operates immediately and persistently.
- **(M2) Resource destruction — the rival.** Cheap private water → many wells → aquifer collapse
  → the private option *fails* → government builds piped water as a **rescue**. Runs through
  *resource dynamics*. Operates only *after* decades of drawdown.

M2 is essentially the Srinivasan et al. (2025) story (see §12). It is a genuine threat to the
*claim*, not the estimate, and must be defeated empirically — not assumed away.

**Discriminating tests (these earn the interpretation; they also separate us from Sekhri 2011):**
- **Timing / sequence.** M1 predicts a public-provision gap present *early* and stable; M2
  predicts one that opens *late*, following the drawdown trajectory. Date provision against
  depletion history where possible — this is the sharpest separation.
- **Take-up conditional on the private option still WORKING.** Restrict to shallow-side villages
  whose wells have *not* failed. If households there still decline to connect, that is M1 —
  choosing private over public while the resource is fine. If low public provision appears *only*
  where wells have failed, that is M2. (Interact the RD with well-failure/depletion status.)
- **"Richer yet worse public water."** M2 makes places *poorer* (depletion lowers incomes —
  Sekhri, Blakeslee et al.). So cheap-water villages being simultaneously **richer** and
  **under-provided** with public water points to M1, since M2 predicts poorer-and-eventually-
  rescued.
- **Scheme type** (§3.3): a discontinuity toward the high-fixed-cost *treated multi-village
  network* is the trap-about-networks signature; a jump only toward a public *deep borewell +
  tank* point source is closer to the access-restoration/M2 story. Split the outcome — and note
  the public borewell margin is additionally contaminated by the deepening race (§12).
- **Political salience & inequality heterogeneity:** water-as-electoral-issue and heterogeneity
  by landholding/inequality distinguish political exit from an apolitical planning response.

**Residual limitation (state it honestly):** dynamic sorting — a village that started shallow
could deplete *across* the cutoff — which is why treatment is assigned on the **earliest** depth
(§7) and McCrary must show no bunching. Even 1990s depth embeds some drawdown; truly "natural"
pre-development depth is a digitization item (§9/Phase 1).

**Two further caveats:** (a) conditioning on "a scheme exists" can induce selection if scheme
*placement* is depth-driven — JJM's near-universal-coverage push helps, so run the take-up RD
*within* the set of villages that all received schemes; (b) Sekhri (2011)'s *own* public scheme
was irrigation tubewells, which may carry a suction-limited cost element in *her* setting — an
irrigation feature that does not transfer to our drinking-water networks, but note it when
citing her.

## 8. Decision gate (pre-committed; do not adjust after seeing data)

**Proceed to Phase 1 only if all hold:**
1. **Stage A replicates** Sekhri's published result (pipeline/sign valid).
2. **First stage (B)** shows a clear downward jump in private groundwater use at `z>0`
   (benchmark: a discontinuity of meaningful size, not a hairline; quantify before judging).
3. **Validity battery (E) is clean:** covariates continuous at 8 m, McCrary passes, placebo
   cutoffs null, secondary placebos continuous. *If covariates jump at 8 m or McCrary fails, the
   RD is invalid — STOP (and consider falling back to the §9 lithology arm).*
4. **Headline (C)** shows a public-water discontinuity in the **trap direction**, OR a
   **precisely estimated null** (a tight null is itself publishable — it would say cheap private
   access does not crowd out public provision at the margin, against the trap).

**Stop / escalate** if: Stage A won't replicate; first stage is a hairline; the validity battery
fails (covariate jumps or sorting); or results flip across missingness treatments or bandwidths.
A clean null or a clean fail is a *successful* Phase 0 — it saves the expensive Phase 1.

## 9. SECONDARY ARM — lithology / rock type (for later)

Retained as a complementary, broader measure of private-water cost (it captures the drinking-water
cost structure the 8 m irrigation-pump threshold captures only fuzzily), and as a fallback if the
RD validity battery fails. **Do not build in Phase 0 unless the depth arm is blocked or time allows.**

Condensed construction (full detail was in v1): classify GSI lithology into ALLUV / SEMI / BASALT /
CRYST / OTHER (**keep basalt separate from crystalline** — basalt → fertile black soil, a confound);
spatially join SHRUG village polygons; compute alluvial-area share and distance-to-contact. Then the
v1 design applies: first-stage (alluvial → more private groundwater), cross-sectional gradient
(alluvial → less tap), and — critically, given §1 — **agriculture as the primary placebo/mechanism
check**, plus roads/schools, in both all-India and peninsular-only samples, with state×agro-climatic-
zone FE and Conley SEs. The lithology arm's headline figure (geology×census-decade divergence, flat
pre-1971) needs the historical digitization and is a Phase-1 item.

## 10. Outputs
- `output/tables/` Stage A–E tables (.tex + .csv); coefficients with robust bias-corrected CIs,
  bandwidth, kernel, effective N, donut window.
- `output/figures/` RD plots (binned scatter + local-linear fit) for first stage, headline,
  agriculture; covariate-continuity panel; McCrary density plot; placebo-cutoff coefficient plot.
- `data/rd_analysis.*` the assembled unit-level dataset (depth, z, outcomes, covariates).
- `memo/phase0_decision_memo.pdf` — §8 gate verdict first, then magnitudes, then recommendation.

## 11. Pitfalls (RD-specific + retained)
- Get the **sign of `z` right** and confirm it by replicating Sekhri (Stage A) before trusting anything.
- Never control for agriculture/income in the RD (bad control — §6).
- Use **earliest** depth, **pre-monsoon**; never contemporary depth for assignment.
- Watch **heaping** at integer depths (donut RD) and **measurement error** from interpolation (fuzzy RD / near-well subsample).
- VD water data is accountant-reported *availability*, not household take-up — phrase results as network-presence margins.
- `shrid2` is a string key; keep it string. Validate every ingested file (row counts, key uniqueness, variable presence) and STOP on failure rather than adapting.
- The 8 m threshold is cleanest for irrigation; flag the drinking-water threshold as fuzzier and lean on the lithology arm (§9) for the broader cost structure.

## 12. Relation to prior work (read before writing the intro; positioning matters)

The 8-meter surface-pump cost discontinuity is **not novel to this project** — it is
Sekhri's, used in both papers below — so our contribution cannot rest on the instrument or
on the public-vs-private-fixed-cost framing. State novelty carefully; any AEJ/AER referee in
this space knows these papers, and both over-claiming and ignoring them are punished.

**Sekhri (2011) — the closest antecedent. Cite prominently and early.** She uses the *same*
8 m discontinuity and an explicitly public-vs-private, fixed-cost logic: public provision
yields sustainable groundwater use "when the fixed costs for private well provision are
high," with the effect jumping at exactly the depth where surface pumps become infeasible.
Her wealth-sorting mechanism is our trap in miniature — marginal farmers take the public
option, large farmers keep building private wells, the public scheme substitutes for private
extraction in the middle. We therefore claim none of: (a) the instrument, (b) the
public/private fixed-cost framing, (c) the finding that public provision substitutes for
private extraction at the high-fixed-cost margin.

**Four points of daylight (our defensible contribution):**
1. **Different outcome/question.** Her dependent variable is the *water table* (a resource-
   sustainability question: does a deployed public scheme conserve the aquifer?). Ours is
   *public network provision and its long-run viability* (does cheap private access prevent
   the public network from emerging and being sustained?).
2. **Reversed causal direction.** For her, public provision is the *treatment* and private
   use/water tables the response — she evaluates a program. For us, the cost of the private
   technology is the force and public provision is the *outcome* being crowded out or
   supported — we explain the endogenous (non-)emergence of the network.
3. **Different sector and scale.** Her "public provision" is *irrigation tubewells* in eight
   UP districts over ~7 years. Ours is *piped drinking-water networks*, national, multi-
   decade, into the JJM/Odisha era — where the trap's quality-ceiling and cream-skimming
   logic (treated networked water vs. untreated self-supply) actually applies and hers does not.
4. **Dynamics and political economy.** She has no multiple-equilibria / lock-in structure and
   no political channel; her scheme is exogenously deployed. Our novelty lives in the
   *dynamic trap* (irreversibility, sunk private capital) and the *political-economy* channel
   (private exit eroding the coalition for public provision), plus *welfare under a trap*
   (people worse off), versus her aquifer-conservation welfare metric.

**Implication for the project's weight:** the 8 m RD is increasingly a *validation of a known
mechanism*; originality is carried by the model (multiple equilibria, commitment, political
economy) and the network/drinking-water outcomes. Frame the empirics as extending a validated
design to a new outcome, not as a new identification.

**Sekhri (2014)** is the RD backbone for Phase 0a (poverty/conflict at the cutoff; agriculture
as validation). **Blakeslee, Fishman & Srinivasan (2020)** use a *different* geological
instrument (borewell-failure IV, not the depth RD) and find adaptation to water loss runs
through off-farm labor reallocation, not agricultural or water-system adjustment — a useful
foil: private-water failure does *not* automatically summon public provision. Chase
**Blakeslee & Fishman (2018 wp), "Wealth inequality and access to depleting water,"** during
the lit review — closest to our inequality-and-private-exit mechanism.

### References
- Sekhri, Sheetal. 2011. "Public Provision and Protection of Natural Resources: Groundwater
  Irrigation in Rural India." *AEJ: Applied Economics* 3 (4): 29–55. DOI: 10.1257/app.3.4.29.
  Replication data openly downloadable from the AEA article page (`2010-0056_data.zip`).
- Sekhri, Sheetal. 2014. "Wells, Water, and Welfare: The Impact of Access to Groundwater on
  Rural Poverty and Conflict." *AEJ: Applied Economics* 6 (3): 76–102. DOI: 10.1257/app.6.3.76.
  Replication package: openICPSR project **113902** (DOI 10.3886/E113902V1).
- Blakeslee, David, Ram Fishman, and Veena Srinivasan. 2020. "Way Down in the Hole:
  Adaptation to Long-Term Water Loss in Rural India." *American Economic Review* 110 (1):
  200–224. DOI: 10.1257/aer.20180976.
- Blakeslee, David, and Ram Fishman. 2018 (working paper). "Wealth Inequality and Access to
  Depleting Water." *(RA: locate current version/venue during lit review.)*
- Srinivasan, Veena, Lakshmikantha NR, Manjunatha G, and Ganesh Nagnath Shinde. 2025. "Chasing
  the water table: The impact of groundwater depletion on rural drinking water supply in
  peninsular India." *PLOS Water* 4 (4): e0000138. DOI: 10.1371/journal.pwat.0000138.
  **Why it matters:** not a competitor (hydrology case study of two Gram Panchayats, no RD, no
  8 m threshold), but it is the clearest statement of the **M2 rival mechanism** in §7A —
  depletion forcing costly public response. It documents public drinking-water borewells being
  dragged into the deepening race (average GP well depth 183 m in 2001–11 → 321 m in 2011–21;
  ~70% of drinking-water wells failing within a decade; GP electricity arrears exceeding all
  revenue), which is why the **public point-source margin is contaminated** and the trap claim
  should rest on the **treated network** margin. Also useful for the hysteresis argument: with so
  many abandoned wells, latent abstraction capacity means water-table recovery is immediately
  pumped away.
