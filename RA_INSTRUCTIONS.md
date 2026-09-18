# RA Instructions: Running Phase 0 Step by Step

*This is your working manual. Read `RA_OVERVIEW.md` first for the "why" and
`FAST_PATH.md` for the shape of the work plan; this document is the detailed
"how." Keep `PHASE0_SPEC.md` open alongside it — that file has the exact
variables and regressions, and this tells you when to use them. You will run the
analysis with Claude Code (an AI coding agent) in VS Code; your job is to set up
the data, supervise the agent, check its work at defined checkpoints, and protect
the analysis discipline. You need not be an expert coder, but you must be a
careful supervisor.*

*Realistic timeline: Phase 0a (the fast test) is days to ~2 weeks, dominated by
getting Sekhri's data and checking one merge. Extensions, only if 0a is green, add
~3–5 weeks. The first real go/no-go signal can arrive very early — that's the point.*

---

## Part A — Before you touch any data

### A1. What you are producing
A single project folder that, by the end of Phase 0a, contains: the replication
of Sekhri's published result (proof the pipeline is right), one headline
regression-discontinuity (RD) estimate of public water at the 8-meter cutoff with
its validity checks, and a short decision memo whose first line is the go/no-go
verdict. Nothing in that folder is a number you typed by hand — everything traces
to a script that re-runs from raw data. That reproducibility is the only way the
PI (and later, referees) can trust the result.

### A2. The one rule that overrides everything
We fixed the analyses and the pass/fail criteria *before* seeing data
(`PHASE0_SPEC.md` §5, §8). You run exactly those, in the `FAST_PATH.md` order,
report what comes out, and write the gate verdict **before** anyone discusses
"what else we could try." The AI agent will cheerfully generate fifty extra
specifications if asked — telling it no is part of your job. If you feel the urge
to tweak a threshold because a result is "just barely" on the wrong side, that is
exactly the moment to stop and email the PI.

### A3. The two facts about this design you must hold onto
1. **The sign of the running variable.** Depth is measured below ground level, so
   *bigger = deeper = more expensive* to get water privately. We center it at 8 m:
   `z = depth − 8`. **`z < 0` (shallow) = cheap private water; `z > 0` (deep) =
   expensive private water.** The trap predicts public water jumps **up** at
   `z > 0`. You will confirm this orientation by replicating Sekhri before trusting
   anything (Checkpoint 2). Getting this sign backwards would invert every result,
   so it is the first thing to nail down.
2. **Agriculture is a friend, not a confound, in this design.** Sekhri showed cheap
   water makes places richer through irrigation. At the 8-meter cutoff, a jump in
   farming/income is *expected* and *validates* the experiment, and because richer
   places usually get more infrastructure, the income effect makes our trap result
   *harder* to find — so finding it anyway is strong evidence. **You must never let
   the agent statistically "control for" income or agriculture inside the RD**
   (they're caused by the treatment, so controlling for them is a known error —
   spec §6).

### A4. Accounts to create (day one)
1. **Sekhri (2014) replication data** — locate it on the AEA replication archive
   for *AEJ: Applied* (it may be hosted via openICPSR; a free ICPSR/openICPSR
   account is typically needed). This is the backbone of Phase 0a. *Essential.*
2. **SHRUG / Development Data Lab** — devdatalab.org. Free, license click-through.
   Source of our public-water outcome on consistent village geography. *Essential.*
3. **(Extensions only, not 0a):** India-WRIS / CGWB for depth data (E1); Bhukosh
   (GSI) for lithology (E5). Don't get blocked setting these up now.

If a portal has moved, note it and let Claude Code find the current link when you
reach that step. Never fabricate or guess a URL — confirm it live.

### A5. Software environment
Phase 0a is light — data wrangling plus the RD packages; you do **not** need the
geospatial stack until extension E1. The project runs in **R only** (see the
Tooling section of `CLAUDE.md`). Install:
1. **VS Code**, then the **Claude Code extension** (from the marketplace; it
   bundles the agent). Sign in when prompted. Optionally add the R extension for
   VS Code; RStudio is fine for looking at data by eye.
2. **R** (a recent 4.x release). Then, from R, in the project folder:
```r
   install.packages("renv")
   renv::init()
   install.packages(c("haven", "dplyr", "data.table", "readr", "ggplot2",
                      "modelsummary", "kableExtra", "rdrobust", "rddensity"))
   renv::snapshot()
```
   Commit `renv.lock` so every run uses the same package versions.
   (For extensions later: `install.packages(c("sf", "terra", "exactextractr",
   "gstat"))`. On Linux, install the GDAL/GEOS/PROJ system libraries first.)
3. **Stage A needs the Imbens–Kalyanaraman bandwidth**, which current `rdrobust`
   no longer offers. Try `install.packages("rdd")` (`RDestimate`). If it no longer
   installs, note it and have the agent implement IK explicitly and log how
   (`CLAUDE.md`, Tooling).
4. Confirm: `Rscript -e 'library(haven); library(rdrobust); library(rddensity); cat("ok\n")'`.


### A6. Set up the project folder
1. Create `~/projects/water-trap/` and put all seven packet documents in the root.
2. Open it in VS Code (File → Open Folder) and **trust the workspace** (Claude
   Code won't run in Restricted Mode).
3. `git init`, commit the packet, and commit after every session so you can roll
   back. The agent will add a `.gitignore` excluding `raw/` and large `data/` files.

---

## Part B — Getting the data

The exact file lists are in `PHASE0_SPEC.md` §3. For Phase 0a you need only two
sources; everything else belongs to the extensions.

### B1. Phase 0a — you download by hand, into `raw/`
- **Sekhri's replication package** → `raw/sekhri/`. The single most important
  early task is to *inventory* it (the agent will help): her depth/running
  variable and its vintage, her unit of analysis, her bandwidth and kernel, and —
  the hinge — **what merge keys it carries** (village census codes? coordinates?
  district only?). Whether Phase 0a is days or needs extension E1 depends entirely
  on this.
- **SHRUG modules** (devdatalab.org/data) → `raw/shrug/`: the 1991/2001/2011
  Village Directory files and the matching Population Census Abstracts; the
  village polygons (for a spatial merge if Sekhri has coordinates rather than
  codes). Download as offered (zipped .dta/.csv).

### B2. Extensions — later, when you reach them
CGWB/India-WRIS depth wells (E1); JJM IMIS scrape with Wayback snapshots (E2);
GSI lithology and confound layers — GAEZ, IMD, HydroSHEDS, SRTM (E5). The agent
fetches the open ones and gives you a checklist for any behind a wall.

### B3. A sanity habit
Open every file in `raw/` once, by eye, before trusting it — a `.dta` loaded with
`pandas.read_stata().head()`, a quick look at Sekhri's variable list. Corrupt or
wrong-version downloads are the most common silent failure, and ten seconds of
looking prevents days of confusion. Session 1's validation does this
programmatically too, but build the habit.

---

## Part C — Driving Claude Code

`KICKOFF.md` has the setup specifics and the exact first prompt; this is the
supervision mindset and the session checklist. Mechanics that matter: type `/` to
select the most capable model and turn on **Extended Thinking**; use **Plan Mode**
(Shift+Tab) for any building session so the agent writes a plan you approve before
it runs; and run `/compact` between phases.

### The supervision mindset
Treat the agent as a fast, capable, slightly over-eager junior colleague. It
produces correct code quickly, and it will also — if unsupervised — paper over a
merge that dropped most rows, invent a plausible variable name it didn't verify,
or run extra regressions you didn't ask for. Your value is judgment at the seams:
check that inputs are what they claim, that it stopped where it should, and that
it didn't improvise around a problem. When unsure, ask it to show you the
intermediate object — a table of merge match rates, the head of a dataframe, the
RD plot — rather than trusting its prose summary.

### Phase 0a sessions
**Session 1 — Scaffold, inventory, and replicate Sekhri (Stage A).**
- *Goal:* repo structure, validated ingest, the Sekhri inventory, and a
  reproduction of her published RD. No new outcomes yet.
- *Check:* its summary of the design and the §8 gate matches `RA_OVERVIEW.md`;
  validation STOPS on any failure rather than adapting; **Stage A actually
  reproduces her numbers** (Checkpoint 2). If it can't, the pipeline or sign is
  wrong — fix before proceeding.

**Session 2 — Headline RD and minimal validity (Stages C + partial E).**
- *Goal:* merge our public-water outcome onto her units; run the RD of public
  piped water on `z` at her bandwidth (trap predicts a jump up at `z>0`); run the
  McCrary density test, covariate-continuity checks, and placebo cutoffs; do the
  water outcome under both missingness treatments.
- *Check:* inspect the merge match rate (a merge that silently lost most villages
  invalidates everything); read the McCrary plot and covariate-continuity panel
  yourself (Checkpoint 4); confirm both missingness treatments were run
  (Checkpoint 5).
- *Then:* the decision point — write the §8 verdict.

### Extension sessions (only if 0a is green)
E3 agriculture mechanism (Stage D) → E4 full validity battery → E2 JJM take-up →
E1 independent depth construction if needed → decision memo. Same supervision
discipline throughout.

---

## Part D — Your manual checkpoints, collected

Points where a human must look, because they involve judgment a script can't supply.

1. **Design comprehension (Session 1):** the agent's summary matches the overview
   and gets the sign of `z` right. Fix any misunderstanding before code.
2. **Sekhri replication + sign of `z` (Session 1):** Stage A reproduces her
   published poverty/conflict result. *This is now the foundational check — it
   simultaneously proves the pipeline works and that the running variable is
   oriented correctly.* If it fails, nothing downstream is trustworthy.
3. **Merge-key inventory + match rate (Sessions 1–2):** confirm how Sekhri's units
   join to our public-water data, and that the merge actually keeps the villages.
   A merge that drops most rows is a silent killer; a district-only fallback is a
   coarser-result flag, not a crash.
4. **RD validity (Session 2):** the McCrary density test shows no bunching at 8 m
   (no sorting), and *pre-treatment* covariates (soil, climate, terrain, baseline
   population, distance to town, **baseline aquifer characteristics and pre-well-era
   depth**) are **continuous** at 8 m. **Important: the depletion rate and well counts
   do NOT belong in this test** — they are caused by the treatment (more wells on the
   cheap-water side) and *should* jump at 8 m; a jump there is confirmation the design
   works, not a failure. A jump in genuinely pre-treatment covariates, or a density
   spike, means the RD is invalid — escalate.
5. **Separating our mechanism from the depletion rival (Session 2):** two stories both
   predict more public water above 8 m — ours (cheap private water → households
   self-supply → public provision crowded out) and the rival (cheap private water →
   too many wells → aquifer collapse → government builds piped water as a rescue). The
   reduced form can't tell them apart, so check the agent runs the three separating
   tests: (a) *timing* — is the gap present early, or only after drawdown? (b) *take-up
   among shallow-side villages whose wells still work* — declining to connect while the
   private option is fine is our mechanism; (c) *"richer yet worse public water"* —
   depletion makes places poorer, so richer-and-underprovided points our way.
6. **Take-up is the cleanest test (Session 2):** the 8 m limit raises the *private*
   cost only — a piped network and the India Mark II deep handpump aren't suction-
   limited, so *public* cost is smooth at 8 m. That means the sharpest result is
   whether households *connect to and pay for* a scheme that exists (higher above
   8 m, where cheap private water is gone), run within villages that all got JJM
   schemes. A jump in whether a scheme gets *built* is a demand/political signal,
   not engineering. Make sure the agent leads with take-up and doesn't smuggle in
   a "public cost jumps too" story — it doesn't.
7. **Missingness stability (Session 2):** compare the headline coefficient under
   missing=0 vs. listwise. Material disagreement is a red-flag memo item, not
   something to resolve by picking the nicer one.
8. **Heaping / measurement error:** confirm the donut RD is applied for integer-
   depth heaping; if depth is interpolated (extension E1), confirm measurement
   error is handled (fuzzy RD or near-well subsample).
9. **The gate verdict (decision point):** written down against the pre-committed
   §8 criteria before anything else.
10. **Reproducibility (end):** from a fresh clone, one command reproduces every
   table and figure with no manual steps.

---

## Part E — When to stop and email the PI

Escalate immediately — don't push through — if:

- **Stage A won't replicate** Sekhri's published result. The setup is wrong;
  fixing it is the priority, and it may need the PI's read of her code.
- **The RD validity battery fails:** covariates jump at 8 m, or the McCrary test
  shows bunching. This means the design is invalid in this data — a real finding,
  and the trigger to consider the lithology fallback (spec §9).
- **The first stage is a hairline** (private-water use barely moves at 8 m) — then
  the cutoff isn't biting and the rest is moot.
- **Sekhri's data won't merge** to a public-water outcome (district-only, no keys).
  This isn't failure — it means Phase 0a gives only a coarse look and you need
  extension E1 (independent depth construction). Flag it as a scope decision.
- **Results flip** across bandwidths or missingness treatments.
- **You feel pressure — internal or from the agent — to deviate from the spec.**
  Any temptation to add a specification or move a threshold is a PI question, not
  an agent decision.

A borderline or null result is itself a finding — report it as borderline. The
project is designed so an honest "this doesn't hold" at Phase 0a costs days, not a
year. Delivering that verdict cleanly is a success.

---

## Part F — Packaging the handoff

At the end of Phase 0a the `~/projects/water-trap/` folder should contain:
- `output/tables/` — the Stage A replication and the headline RD (.tex + .csv),
  with bias-corrected robust CIs, bandwidth, kernel, effective N, donut window.
- `output/figures/` — the RD plots (binned scatter + local-linear fit), the
  McCrary density plot, the covariate-continuity panel, the placebo-cutoff plot.
- `output/logs/` — ingest validation and merge match-rate logs.
- `data/rd_analysis.*` — the assembled unit-level dataset.
- `memo/phase0_decision_memo.pdf` — the §8 verdict first.
- A clean git history, one commit per session.

Then email the PI: the gate verdict in the first sentence; the first-stage and
headline magnitudes in the second; the validity picture (McCrary, covariate
continuity, missingness stability) in the third; the recommendation (proceed to
extensions, need E1 first, or stop) in the fourth. Attach the memo. Resist writing
more until the PI has read it — the discipline that made the test credible extends
to not burying the verdict in caveats.

---

## Part G — Troubleshooting (the predictable snags)

- **The sign looks wrong** (public water seems higher where water is cheap, or
  Stage A gives poverty falling where it should rise): re-derive `z = depth − 8`
  and which side is "deep." Confirm against Sekhri's published direction before
  doing anything else. This is the single most common and most consequential slip.
- **The merge keeps too few villages:** inspect the keys. Census village codes
  change across years; you may need SHRUG's crosswalks or a spatial join on
  coordinates. A merge match rate well below ~80% needs investigating, not
  accepting.
- **Heaping at integer depths** (mass points at 8 m): apply the donut RD (drop a
  small window around the cutoff, default `|z| < 0.5 m`; robustness at 0.25 and 1.0).
- **`rdrobust` results swing wildly with bandwidth:** that's information, not a
  bug — report the MSE-optimal estimate plus the sensitivity sweep. Wild swings
  with a tiny effective N near the cutoff signal you're underpowered; tell the PI.
- **`shrid2` won't merge:** it's a string key; a leading-zero or integer-coercion
  mismatch is usual. Keep it a string everywhere.
- **SHRUG water numbers don't match a published figure:** VD amenity data is
  village-accountant-reported *availability*, not household take-up, and the
  official sources disagree by design (spec notes this). Phrase results as
  network-presence margins; don't reconcile to houselisting totals in Phase 0.
- **The agent proposes something off-spec:** decline and point it at the
  analysis-discipline section of `CLAUDE.md`. If you think the deviation is
  warranted, that's a PI email, not an agent decision.

---

*If a setup or data issue stalls you for more than an hour, that's an email to the
PI, not a lost day. If a result surprises you, that's also an email — surprising
results are either the finding or a bug, and either way the PI wants to know early.*
