# Water trap: repository guide

**The question.** When households can buy a cheap private substitute for a
public service (a borewell, a generator, a water filter), does the state stop
building the public network? Or is private adoption just the right technology
for the place?

**What a test needs.** We need a *cost shifter*: something that makes the
private substitute expensive in one place and cheap in another, for a reason
unrelated to income or to the cost of the public network. We then check
whether public provision is higher where the private option is expensive.
Most of the work so far is the search for that cost shifter.

**Current status and the decisions needed:** see
[`STATEOFPLAY.md`](STATEOFPLAY.md). This README only explains how the
repository is organised.

---

## 1. How to read this repository: one branch per track

The most important thing to know: **`main` holds only the shared data
infrastructure. Each exploratory track lives on its own branch.** A track's
scripts, decision memos and outputs are on its branch, not on `main`.

| Branch | Track | Status |
| --- | --- | --- |
| `main` | Shared infrastructure: data ingestion, census water variables, CGWB wells, spatial tools | Base for all branches |
| `piste-a-geology` | **A: geology as the cost shifter** (rock type sets water-table depth, hence well cost). First stage on CGWB wells, then replication of Ryan & Sudarshan's variable selection on fine maps | Open |
| `piste-a-classe-aquifere` | **A**, next step: does the fine geological map carry an aquifer class? | Open, criterion written, script stopped on a validation check |
| `piste-a-recodage-ap` | **A**: hydrogeological recoding of the Andhra Pradesh map units | Folded into A |
| `piste-c-purificateurs` | **C: household water filters**, adoption measured in NFHS from 1998 | Open, no cost shifter yet |
| `piste-d-dhs-hv202` | **D**: multi-country DHS descriptives (bottled and sachet water vs piped supply) | Descriptive only |
| `piste-ihds-inventaire` | Inventory of the IHDS private/public water variables | Done |
| `piste-e-exposition` | **E**: agricultural electricity tariff as the price of pumping | Closed 02/10: varies only by state |
| `piste-g-tarifs` | **G**: 1991 import-tariff cuts on generators | Closed 02/10: India imported almost no generators |
| `piste-i-salinite` | **I**: groundwater salinity as a shifter for filter cost | Closed 08/10: half the variation is measurement noise |

Tracks B (household electricity) and F (CGWB block classification) were
closed on desk review, with no code. The reasons are in `STATEOFPLAY.md`,
Annex A.

> Script numbers are global but were assigned branch by branch, so the same
> number can appear on two branches (e.g. `14_`). Always read a script on its
> own branch.

---

## 2. Folder layout

```
raw/        original downloads, never modified. Not in git (too large / licensed);
            raw/README.md records the source, date and SHA256 checksum of each file
code/       analysis scripts, numbered in run order (NN_name.R), plus 00_utils.R
code/ref/   small hand-documented lookup tables (codebooks, recodings)
build/      intermediate datasets produced by the scripts. Not in git, rebuilt from raw/
output/     tables/ (csv), figures/ (pdf), logs/ (one log per script run)
memo/       decision memos: the pass/fail criterion, then the verdict (see §4)
docs/       ROADMAP.md (working plan and decision log),
            LITTERATURE.md (annotated reading notes), OUTILS.md (data-access notes)
run_all.R   master script for the shared pipeline
```

Everything reproduces from `raw/` with scripts, with no hand-entered numbers.
Code comments, logs and memos are in French.

---

## 3. Scripts

### Shared pipeline (on `main`)

| Script | What it does |
| --- | --- |
| `00_utils.R` | Shared helpers: hard-stop validation checks, resumable stages, timestamped logging |
| `00_convert_dta.R` | Converts the Stata census files once to `.rds` (see §5) |
| `01_ingest_validate.R` | Checks every raw file (row counts, keys, variable names) and stops on any failure |
| `02_shrug_water.R` | Village-level water variables from the 1991, 2001 and 2011 censuses (SHRUG) |
| `03_cgwb_long.R` | Government observation wells (CGWB): pre-monsoon depth panel, 1996–2017 |
| `04_shrid_centroids_dist.R` | Village centroids and distance to the nearest well |
| `05_diag_missing_tap.R` | How much of the piped-water variable is missing, and where |
| `06_`, `07_` | *Frozen.* Depth interpolation built for the abandoned 8 m design |
| `08_wells_in_villages.R` | Links each well to the village it sits in |
| `09_geology_by_state.R` | How much geological variation each state has (choosing a study region) |
| `10_piste_a_premier_stage_ap.R` | Track A, first attempt: does geology predict well depth in Andhra Pradesh? (failed) |
| `11_piste_c_inventaire.R` | Track C: inventory of filter/water-source variables in NSS and IHDS |
| `12_dhs_api_inventaire.R` | Track D: national DHS series by country |
| `13_giz_prix_carburant.R` | Track D: fuel-price series as a candidate shifter (criterion never fixed, not run) |

### Track scripts (on their branches)

| Branch | Scripts |
| --- | --- |
| `piste-a-geology` | `29`–`33`: fine geological maps, LASSO replication of Ryan & Sudarshan (`30`, `31`, `33` are Python), Andhra Pradesh on fine maps |
| `piste-a-classe-aquifere` | `34`: aquifer class in the Bhujal map |
| `piste-c-purificateurs` | `24`–`28`: NFHS filter adoption, questionnaire changes, geographic level |
| `piste-d-dhs-hv202` | `14_dhs_hv201_hv202.R`: water source for drinking vs other uses |
| `piste-ihds-inventaire` | `15`: IHDS inventory |
| `piste-e-exposition` | `16`–`19`: district depth, tubewell exposure, power counts |
| `piste-g-tarifs` | `20`–`23`: Topalova tariffs, engine prices, generator imports |
| `piste-i-salinite` | `14_piste_i_salinite.R`: CGWB water quality |

---

## 4. Memos and the working rule

Every test follows the same order, and the git history shows it:

1. **Criterion first.** A memo `memo/<track>_critere.md` states what counts as
   pass or fail, with numerical thresholds. It is committed **before** the
   script is run.
2. **Then the script**, committed before execution.
3. **Then the verdict**, `memo/<track>_verdict.md`, written against the
   criterion. No variant is discussed before the verdict is written.

A clean failure counts as a result. This is why most tracks are closed with
a dated reason rather than abandoned.

Two other rules in the code:

- **Hard stops.** Every input file is validated (row counts, unique keys,
  expected variables). On failure, the script stops and reports the problem
  instead of adapting silently. The `[FAIL]` lines in `output/logs/` show where.
- **No outcome before the criterion.** Public-provision outcomes are never
  regressed until the criterion for that test is written.

---

## 5. Running the code

- **R 4.5** with `renv`: run `renv::restore()` to install the exact package
  versions in `renv.lock`.
- **Data:** `raw/` is not in git. `raw/README.md` lists every source with its
  URL and checksum.
- **One-time conversion:** `Rscript code/00_convert_dta.R --used-only`.
  On the development machine, a Windows security policy sometimes blocks R
  packages from loading the Stata reader. So the census `.dta` files are
  converted once to `.rds` copies in `build/`, which the pipeline reads first.
  `raw/` stays the source of truth.
- **Shared pipeline:** `Rscript run_all.R` from the repository root. Logs go
  to `output/logs/`.
- **Track scripts:** check out the branch, then
  `Rscript code/NN_name.R`. Long scripts are split into stages that save
  their output as they go, so an interrupted run resumes where it stopped.

---

## 6. Older documents

`RA_OVERVIEW.md`, `FAST_PATH.md`, `RA_INSTRUCTIONS.md`, `PHASE0_SPEC.md` and
`KICKOFF.md` are the original Phase 0 packet, built around the 8 m
water-table threshold design (Sekhri 2014). That design was dropped on
23/09/2026 (village-level depth does not exist in any accessible source).
Their framing of the question and their data-source notes still hold; their
work plan does not. `CLAUDE.md` holds the standing instructions for the AI
coding assistant used on the project.
