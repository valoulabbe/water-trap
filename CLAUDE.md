# CLAUDE.md — Private Infrastructure Trap (Water): Phase 0

## What this project is
Phase 0 (kill-shot tests) of a natural-experiment design asking whether cheap
private/decentralized water access — tubewells, handpumps, borewells — causally
reduces long-run **public** piped-water provision in India (a "private
infrastructure trap"), or whether the observed pattern just reflects efficient
technology assignment. Part of a larger theory + empirics project.

**Identification (primary): the 8-meter groundwater-depth regression
discontinuity (Sekhri 2014).** Cheap suction pumps lift water only from ~<8 m
below ground level; past 8 m, private extraction needs a much costlier
submersible/deep-well setup. Villages just above vs. just below 8 m differ
sharply in the cost of private water but are otherwise alike. The rock-type /
lithology cross-section is a **secondary arm** (spec §9), for later.

**Read `PHASE0_SPEC.md` in full before any work.** It is authoritative: data
sources, sign conventions, construction, the Stage A–E analyses, and the §8
decision gate. `FAST_PATH.md` defines the order of work (Phase 0a first). This
file adds conventions and the non-negotiable discipline.

## Work order (do not skip ahead)
1. **Phase 0a (fast path, spec §3.1 spine):** obtain + inventory Sekhri's
   replication package; replicate her published result (Stage A — validates
   pipeline and the sign of the running variable); merge our public-water
   outcome onto her units; run the headline RD (Stage C); minimal validity
   (McCrary, covariate continuity, placebo cutoffs).
2. **Decision point:** write the §8 gate verdict. Stop or proceed.
3. **Extensions only if 0a is green** (FAST_PATH E3, E4, E2, E1): agriculture
   mechanism; full validity battery; JJM take-up; independent depth construction.
4. **Phase 1 (later):** lithology arm (spec §9); Odisha micro.

## Analysis discipline (non-negotiable)
- Run ONLY the analyses in PHASE0_SPEC.md §5 (Stages A–E), in the FAST_PATH
  order. No exploratory specifications, no extra outcomes, no specification
  search until the decision memo is written and the §8 verdict recorded.
- **Confirm the sign of the running variable by replicating Sekhri (Stage A)
  before trusting any new result.** If her published result won't replicate in
  her own data, STOP — the pipeline or sign is wrong.
- **Never control for agriculture/income inside the RD.** They jump at the
  cutoff (post-treatment), so conditioning on them is bad-control bias (spec §6).
  Agriculture is a validation/mechanism check, not a control.
- **Interpretation (spec §7A): the 8 m cutoff raises the PRIVATE cost only.** The
  public network's build cost and the India Mark II deep-well handpump are NOT
  suction-limited, so public cost is continuous at 8 m. Therefore: lead with the
  **take-up / use conditional on availability** margin (cleanest — pure private-
  cost channel; run it *within* villages that all received JJM schemes), and read
  any **supply/investment** discontinuity as a demand/political channel, not
  engineering. Split the supply outcome by scheme type (point source vs. treated
  network). Do NOT reintroduce a "public cost also jumps at 8 m" story — it is wrong.
- **Depletion is a treatment-caused MEDIATOR, not a confounder** — it cannot bias
  the reduced form. Critically: the depletion rate **should jump at 8 m** (more wells
  on the shallow side), so it must be **EXCLUDED from the Stage E covariate-continuity
  battery** — testing a treatment-caused variable for balance is bad control. Keep only
  pre-treatment characteristics there (aquifer lithology, storativity, recharge, soil,
  rainfall, terrain, baseline pre-well-era depth, baseline population). Collect
  depletion/well-failure status and use it as the **mediator-separation variable**
  (§7A): our substitution mechanism (M1) vs. the resource-destruction rival (M2 —
  depletion forces costly public rescue). They are same-signed, so run the
  discriminating tests: timing of provision vs. drawdown trajectory; take-up among
  shallow-side villages whose wells still *work*; and the "richer yet worse public
  water" result (M2 predicts poorer). Assign treatment on earliest depth; check
  McCrary for dynamic sorting across the cutoff.
- Use the **earliest, pre-monsoon** depth for assignment; never contemporary
  depth. Handle heaping at integer depths with a donut RD; if depth is
  interpolated, treat measurement error explicitly (fuzzy RD / near-well subsample).
- Every public-water regression runs under BOTH missingness treatments (missing=0
  conditional on `pc91_vd_drnk_wat_f` non-missing; listwise drop). Instability
  across the two is a red-flag memo item, not something to resolve by picking one.
- The §8 gate criteria were committed before seeing data. Do not adjust them. A
  clean null or a clean fail is a SUCCESSFUL Phase 0. Borderline is reported as
  borderline.
- Everything reproducible by one master script (`make all`) from raw/ with no
  manual steps. No numbers pasted by hand.

## Validation, and stopping on failure
On every ingested file, VALIDATE before use (row counts vs. expectation, key
uniqueness, presence of the variables the spec names) and **refuse to proceed
past a failed validation rather than silently adapting** (e.g. do not substitute
a guessed variable name, do not quietly drop a merge that lost most rows). Report
the failure and wait.

## Repository layout
```
raw/        immutable downloads, never edited; one subfolder per source
build/      scripts turning raw/ into analysis datasets; numbered (01_, 02_)
data/       intermediate + final analysis datasets (gitignored if large)
analysis/   RD + figure scripts, numbered to mirror spec Stages A–E
output/     tables (tex + csv), figures (pdf), logs
memo/       the decision memo
```

## Tooling
- Python preferred. RD: `rdrobust`, `rddensity` (PyPI; R fallback if a port
  misbehaves — note which was used). Data: pandas, numpy, pyarrow, matplotlib.
- RD estimation: local linear, triangular kernel, MSE-optimal bandwidth,
  bias-corrected robust CIs (Calonico–Cattaneo–Titiunik). Cluster at the
  well/locality where depth is shared across villages from interpolation. Donut
  RD for heaping. Bandwidth/polynomial/donut sensitivity in the validity battery.
- Geo stack (geopandas, shapely, rasterstats/exactextract, a kriging/IDW library)
  is needed ONLY for extension E1 (depth interpolation) and the §9 lithology arm
  — not for Phase 0a. CRS for geo steps: EPSG:7755; store final lat/lon in WGS84.
- Logs (ingest validation, well→village match, interpolation error) to output/logs/.

## Data access — division of labor
The human handles registration/license walls; the agent fetches open sources and
ALWAYS produces a precise download checklist (exact names, URLs, expected files)
for anything it cannot fetch.
- **Phase 0a:** human downloads Sekhri's replication package (AEA replication
  archive / openICPSR) and the SHRUG modules (devdatalab.org/data, license
  click-through). That's all 0a needs.
- **Extensions:** CGWB / India-WRIS depth data (E1); JJM IMIS scrape + Wayback
  snapshots (E2); GSI lithology from bhukosh.gsi.gov.in and confounds — GAEZ,
  IMD, HydroSHEDS, SRTM (E5).

## Known data facts (verified against the SHRUG codebook — do not re-derive)
- VD files: `pc91_vd_clean_shrid.dta` / pc01 / pc11, key `shrid2` (a STRING — keep
  it string).
- 1991 water vars: `pc91_vd_tap`, `pc91_vd_tubewell`, `pc91_vd_handpump`,
  `pc91_vd_well`, `pc91_vd_tank`, `pc91_vd_river`, `pc91_vd_drnk_wat_f`,
  `pc91_vd_rang_wat_f`. Missingness 7–36% (tap ≈ 28%) — apply the missingness rule.
- 1991 irrigation-by-source (ha), for the agriculture mechanism (E3):
  `pc91_vd_tw_w_el`, `pc91_vd_tw_wo_el`, `pc91_vd_well_w_el`, `pc91_vd_well_wo_el`,
  `pc91_vd_canal_govt`, `pc91_vd_canal_pvt`, `pc91_vd_tank_irr`, `pc91_vd_tot_irr`.
- 2011 verified: `pc11_vd_land_wl_tw_irr`, `pc11_vd_land_canal_irr`, placebo counts
  (`pc11_vd_p_sch_gov`, `pc11_vd_ph_cntr`, `pc11_vd_all_hosp`, ...).
- 2011/2001 drinking-water variable names: NOT yet verified — confirm via
  docs.devdatalab.org/variable-search/ and record in the build-script header
  before use.
- Sekhri's running variable, unit, bandwidth, and MERGE KEYS are unknown until her
  package is inventoried — that inventory is the first task and the feasibility hinge.

## Style for outputs
- Tables: booktabs LaTeX + a csv twin; RD estimates with bias-corrected robust CIs,
  bandwidth, kernel, effective N, donut window; N and dep-var mean.
- Figures: matplotlib, no baked-in titles (they live in the paper). RD plots
  (binned scatter + local-linear fit), covariate-continuity panel, McCrary density
  plot, placebo-cutoff coefficient plot.
- Decision memo follows spec §8/§10: gate verdict first, then magnitudes, then
  recommendation. 3–5 pages.
