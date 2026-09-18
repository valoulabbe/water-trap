# KICKOFF — running Phase 0 in Claude Code (VS Code)

## One-time setup
1. Create a project folder, e.g. `~/projects/water-trap/`.
2. Put all packet documents in the root: `README.md`, `RA_OVERVIEW.md`,
   `FAST_PATH.md`, `RA_INSTRUCTIONS.md`, `PHASE0_SPEC.md`, `CLAUDE.md`,
   `KICKOFF.md`.
3. Set up the R environment as in `RA_INSTRUCTIONS.md` §A5 (R, `renv`, the RD
   packages). The project runs in R only; see the Tooling section of `CLAUDE.md`.
4. Open the folder in VS Code (File → Open Folder) and **trust the workspace**
   — Claude Code does not run in Restricted Mode.
5. Open the Claude Code panel from the sidebar.
6. In the command menu (type `/`): select the most capable model available and
   toggle **Extended Thinking ON**. Keep both on for these design-heavy sessions.
7. Before Session 1, download the things Phase 0a needs into `raw/`:
   **both Sekhri replication packages** into `raw/sekhri/` — 2014 (openICPSR
   project 113902) and 2011 (`2010-0056_data.zip`, AEA article page) — and the
   **SHRUG modules** (devdatalab.org/data) into `raw/shrug/`. Everything else is
   for later extensions and the agent will fetch or checklist it when you get there.

## Working pattern
- Start each substantive session in **Plan Mode** (Shift+Tab): the agent reads
  the repo, asks clarifying questions, and writes a plan you review and edit
  before anything runs. Approve, then let it execute.
- Run `/compact` when switching phases (after Phase 0a, before extensions) so
  context stays coherent.
- One session per step below; don't ask for everything at once.
- Commit after every session (including `renv.lock`).

## Session sequence

### Phase 0a — the fast path
1. **Scaffold + Sekhri inventory + replication (Stage A).** Set up the repo and
   `renv`, ingest and VALIDATE the raw files, and inventory both Sekhri packages
   — running variable, unit, bandwidth, and especially the **merge keys** (this
   is the feasibility hinge). Then replicate her published poverty/conflict RD
   with **her own estimator first** (rectangular kernel, Imbens–Kalyanaraman
   bandwidth, plus bandwidths 5 and 2; target: Table 6), and only then
   re-estimate with the CCT specification. This confirms the pipeline and locks
   the sign of the running variable. STOP if it won't replicate.
2. **Headline RD + minimal validity (Stages B, C + partial E).** Merge our
   public-water outcome onto her units; run the first stage (private
   groundwater jumps DOWN past 8 m) and the RD of public piped-water coverage on
   her running variable (the trap predicts a jump UP just past 8 m), reporting
   both her bandwidth and the MSE-optimal one, with the verdict bandwidth fixed
   in advance. Then the can't-skip checks: McCrary density (no sorting),
   covariate continuity at 8 m (no jumps), placebo cutoffs (6/7/9/10 m). Run the
   public-water outcome under both missingness treatments.

   → **Decision point.** Write the §8 gate verdict now, before anything else.

### Extensions — only if 0a is green (see FAST_PATH ladder)
3. **Agriculture mechanism (E3 / Stage D).** Replicate her agriculture/income
   result and frame the "richer yet worse public water" finding. Do NOT control
   for it in the RD.
4. **Full validity battery (E4 / rest of Stage E).** Bandwidth/polynomial/donut
   sweeps; secondary placebos (roads, schools, clinics); near-well subsample.
5. **JJM take-up (E2)** and, if Sekhri's data wouldn't merge or you need to scale,
   **independent depth construction (E1)**.
6. **Decision memo (spec §8/§10).** Gate verdict first.

### Later (Phase 1) — not in this engagement unless told
7. Lithology cross-section arm (E5, spec §9); Odisha / Drink-from-Tap micro (E6).

## First prompt to paste (Session 1, in Plan Mode)
"Read CLAUDE.md, PHASE0_SPEC.md, and FAST_PATH.md in full. This project is done
in R only (see the Tooling section of CLAUDE.md). Then: (a) summarize back the
design, the sign conventions, the §8 decision gate, and the analysis-discipline
constraints in your own words so I can check your understanding; (b) inventory
what is in raw/, i.e. BOTH Sekhri packages (2014, openICPSR 113902, and 2011,
2010-0056_data.zip): for each, the running variable and its vintage, the unit
of analysis, the bandwidth and kernel, and the merge keys available to join our
SHRUG/Census public-water outcomes. Report what you find; do not guess variable
names; (c) propose the repository scaffold, the renv setup, the ingest-validation
plan, and a plan to replicate Sekhri (2014) Table 6 with HER estimator first
(rectangular kernel, IK bandwidth, bandwidths 5 and 2) before any CCT
re-estimation. Do not write any analysis code beyond the Stage A replication
plan yet, and do not start extensions."

## Guardrails to keep yourself honest
- If the agent proposes anything beyond the current step, decline and point it to
  the analysis-discipline section of `CLAUDE.md`.
- If the agent starts writing Python, stop it and point it to the Tooling
  section of `CLAUDE.md`.
- Personally confirm Stage A actually reproduces Sekhri's numbers before trusting
  any new outcome — this is the foundational check that the running variable is
  oriented correctly.
- Review the McCrary density plot and the covariate-continuity panel yourself;
  a jump in covariates at 8 m, or bunching at the cutoff, means the RD is invalid.
- The gate verdict gets written into the memo before any "what else we could try."