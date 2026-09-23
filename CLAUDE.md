# CLAUDE.md — Private Infrastructure Trap (Water)

## Status (read first)
**Exploration phase since the 23/09/2026 pivot.** The 8 m groundwater-depth RD
(Sekhri 2014) is **no longer the reference design**, and the Sekhri replication
is dropped (the PI will not contact her). Three tracks run in parallel, none
preselected:

| Track | Private substitute | Identifying variation (candidate) |
| --- | --- | --- |
| A — Groundwater | Borewell + pump | Geology (rock, aquifer, fractures), à la Ryan & Sudarshan (JPE 2022) |
| B — Electricity | Diesel genset | Price of capital (imports, tariffs), state diesel VAT, CPCB rules in NCR |
| C — Drinking water | Household filter | Mass-market arrival: Pureit national early 2008, Tata Swach Dec 2009 |

Current work is Track A: choosing a study region on numbers (`code/09_geology_by_state.R`),
then a first stage at the WELL (depth ~ geology + surface controls) on CGWB wells.
The Uttar Pradesh restriction came from Sekhri's sample and has no remaining
justification.

`docs/ROADMAP.md` holds the live plan, checklists and decision log. It is an
**export of a document the user maintains elsewhere: never edit it**; anything
written there is overwritten. Put anything to be recorded in the chat.

`PHASE0_SPEC.md`, `FAST_PATH.md`, `KICKOFF.md` and `RA_INSTRUCTIONS.md` describe
the RD-era Phase 0. They are **superseded** except for their data-source notes;
do not follow their work order, Stage A–E list or §8 gate.

## The question
Does cheap private access to a service (groundwater, generators, filters)
prevent the emergence of the public network (a trap), or is it efficient
technology assignment? Common mechanism: the trap bites only when the public
good is a **high-fixed-cost network**. When solvent households exit, the average
cost per remaining subscriber rises and the political return to the network
collapses (exit/voice, Hirschman). Testable prediction: stronger public
retreat for piped water and electricity than for non-network goods.

## Analysis discipline (non-negotiable)
- **Golden rule:** write the exit criterion BEFORE estimating, write the verdict
  against that criterion, and discuss no variant before the verdict is written.
  A clean null or a clean fail is a successful exploration. Borderline is
  reported as borderline.
- **The variation must move the cost of the PRIVATE substitute**, not demand for
  the service. No story in which the public cost jumps at the same place as the
  private cost.
- **No outcome is read before the criterion exists.** Descriptive work on the
  instrument, the first stage or data coverage is fine; regressions of public-
  provision outcomes are not, until the criterion is written.
- **Never control for post-treatment variables** (agriculture, income, well
  counts, depletion). They are mechanisms or mediators, not controls.
  Depletion is a treatment-caused mediator: it separates the substitution
  mechanism from the resource-destruction rival (depletion forcing costly public
  rescue). Test rival mechanisms (depletion, income, administrative capacity);
  don't just mention them.
- **Relevance is judged by eye** (magnitude of the first stage or shock), not only
  by the F-statistic. For any difference-in-differences design, plot trajectories
  before any estimate.
- **Missing data:** every public-water regression runs under BOTH treatments
  (missing = 0 conditional on `pc91_vd_drnk_wat_f` non-missing; listwise drop).
  Instability between the two is a red flag to report, not to resolve by
  picking one.
- **Escalate to the PI immediately** if the first stage or shock is too weak,
  pre-trends diverge, a merge is impossible, results flip with specification or
  missingness treatment, a track depends on non-public data, or there is a
  temptation to keep a track that doesn't work.

## Validation, and stopping on failure
Validate every ingested file before use: row counts against expectation, key
uniqueness, presence of the named variables. **Refuse to proceed past a failed
validation rather than silently adapting**: don't substitute a guessed
variable name, and don't quietly drop a merge that lost most rows. Use the
hard-stop helpers in `code/00_utils.R` (`check`, `check_rows`, `check_vars`,
`check_unique`). Report the failure and wait.

## Running long jobs
- **Long R jobs run in the user's terminal, not in the agent's process.** Write
  the script, give the exact command (`Rscript code/NN_name.R` from the repo
  root) and say what to look for in the output. Short checks of a few seconds
  may be run directly.
- `Rscript` may not be on the PATH on this machine. The full path is
  `& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe"` (PowerShell).
- **Every long script is resumable and observable.** Split it into stages with
  `stage(label, path, build, after)` from `00_utils.R`. Each stage writes its
  output to `build/` as soon as it exists (`.gpkg` for geometry, `.rds`
  otherwise), through a `.part` file then a rename. A stage whose output exists
  is reread, not redone. `--force` redoes everything, and a stage is redone if
  an upstream output (`after`) is newer. Progress lines use `tmsg()`, which is
  timestamped and flushed to the log at once.
- Before proposing a fix for a slow script, report stage timings and object
  sizes from the files and logs. Don't guess the bottleneck.

## Tooling
- **R only**, with `renv` (`renv.lock` is committed; run `renv::snapshot()`
  after installing anything). Core: data.table, sf, arrow (GeoParquet), ggplot2.
  Only if a design needs them: rdrobust, rddensity, fixest.
- **App-control DLL blocking:** a Windows policy intermittently blocks loading
  package DLLs from the renv cache (seen on `cli.dll`, hence haven). SHRUG
  `.dta` files are therefore converted once to `build/*.rds` by
  `Rscript code/00_convert_dta.R --used-only` (run on its own, not in
  `run_all.R`). `read_dta_chk()` prefers the `.rds` automatically.
- Local GDAL 3.12 has no Parquet driver and cannot read `.7z`. Read GeoParquet
  with `arrow::read_parquet()` + `sf::st_as_sfc(structure(..., class = "WKB"))`.
- India-WRIS (`arc.indiawris.gov.in`) does not answer from this machine
  (TCP timeout). Anything that must come from there goes on the user's
  download checklist.

## CRS convention
- Store coordinates in **WGS84 (EPSG:4326)**.
- **Areas, densities, area shares:** equal-area LAEA centred on India,
  `+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs`.
  EPSG:7755 is conformal (LCC): its area error runs from −4 % to +3.7 % across
  India (−3.7 % mean in UP), which biases cross-state density comparisons
  (checked 23/09, `tmp_crs/`).
- **Distances and buffers:** EPSG:7755 is acceptable where a linear scale error
  of up to ~2 % doesn't matter (e.g. nearest-neighbour ranking). Otherwise use
  geodesic distances on WGS84 (sf with s2).
- Repair geometries (`st_make_valid`) in a projected CRS before any area
  computation; the GSI geology layer has 99 invalid polygons.

## Repository layout
```
raw/        immutable downloads, one subfolder per source; provenance + SHA256
            in raw/README.md (only that file is tracked)
code/       numbered scripts NN_name.R, plus 00_utils.R (shared helpers)
build/      intermediate data and stage outputs (gitignored)
output/     tables (csv, tex), figures (pdf), logs/
memo/       decision memos
docs/       ROADMAP.md (export, do not edit), LITTERATURE.md
run_all.R   master script at the root: `Rscript run_all.R`
```
Scripts live in `code/`, not `build/`, because `build/` is gitignored. Everything
must reproduce from `raw/` with one command and no hand-entered numbers.

Frozen scripts (kept as committed, not in `run_all.R`): `06_interp_loo_up.R` and
`07_temporal_noise_up.R`, the depth interpolation built for the dropped RD. In
`08_wells_in_villages.R`, sections 8e–8h (village depth, bands around 8 m) are
disabled behind `RD_LEGACY <- FALSE`; the well→village link stays active.

## Known data facts (verified — do not re-derive)
- **SHRUG v2.2.** VD files `pc91/pc01/pc11_vd_clean_shrid.dta` (564,855 /
  527,920 / 588,973 rows), key `shrid2`, a **string**: keep it string.
  `pc11r_shrid_key` has 597,597 rows and carries `pc11_state_id`. State names
  come from `shrid_loc_names`.
- 1991 water vars: `pc91_vd_tap`, `pc91_vd_tubewell`, `pc91_vd_handpump`,
  `pc91_vd_well`, `pc91_vd_tank`, `pc91_vd_river`, `pc91_vd_drnk_wat_f`,
  `pc91_vd_rang_wat_f`. Missingness 7–36 % (tap ≈ 28 %).
- 1991 irrigation by source (ha): `pc91_vd_tw_w_el`, `pc91_vd_tw_wo_el`,
  `pc91_vd_well_w_el`, `pc91_vd_well_wo_el`, `pc91_vd_canal_govt`,
  `pc91_vd_canal_pvt`, `pc91_vd_tank_irr`, `pc91_vd_tot_irr`. 2011:
  `pc11_vd_land_wl_tw_irr`, `pc11_vd_land_canal_irr`; placebo counts
  `pc11_vd_p_sch_gov`, `pc11_vd_ph_cntr`, `pc11_vd_all_hosp`.
- 2001/2011 drinking-water variable names: check on
  docs.devdatalab.org/variable-search/ and record them in the script header
  before use.
- `private_gw` = tubewell OR handpump, so it probably includes public India Mark
  II pumps, and it saturates near 1 in UP. It is not a clean measure of private
  adoption.
- **CGWB wells** (`raw/cgwb/CGWB_data_wide.csv`, an unofficial copy): 28,076
  wells, quarterly levels May 1996 – Jan 2017. **No reading before 1996.** Median
  within-well year-to-year SD of May depth: 0.73 m (UP). Variogram range of May
  depth: 30–70 km (UP). Use it as a starting scale for spatial standard errors,
  re-estimated on first-stage residuals.
- **GSI geology 1:2M** (`raw/geology/ngdr/NGDR_Geology_2M.parquet`): 4,531
  polygons. It is **stratigraphic** (unit 504, age 72, supergroup 18; supergroup
  empty on ~60 % of the area). It has no rock-type or aquifer-class field. Any
  lithology classification built from it is a judgement coding for the user to
  review. The CGWB principal-aquifer layer is not available locally.

## Style for outputs
- Code comments and log messages in French, matching the existing scripts.
- Tables: booktabs LaTeX plus a csv twin; report N, the dependent-variable mean
  and the estimator settings.
- Figures: ggplot2, no titles baked in (they live in the paper).
- Decision memos: verdict against the pre-written criterion first, then
  magnitudes, then recommendation.
