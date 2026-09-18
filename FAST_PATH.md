# FAST_PATH.md — Phase 0a (the quick version) + extension ladder

*The full design is in `PHASE0_SPEC.md`. This is the minimal critical path to a
real go/no-go signal, plus everything else marked optional and ordered by cost.
Do Phase 0a first; only climb the ladder if 0a survives.*

---

## Why a fast version exists
Sekhri (2014) already built and validated the 8-meter depth discontinuity and
its first stage, and AEJ: Applied requires her data + code to be deposited. So
the quickest possible test is to **borrow her identification and swap in our
outcome** — no depth construction, no interpolation, no spatial joins, no
digitization.

## Phase 0a — the critical path (target: a few days to ~2 weeks)
1. **Get Sekhri's replication package** (AEA / openICPSR) and inventory it:
   her running variable and its vintage, the unit of analysis, her bandwidth/
   kernel, and — the hinge — what **merge keys** it carries (village census
   codes? coordinates? district only?).
2. **Replicate her published RD** (poverty/conflict jump at 8 m) in her own
   data. This validates the pipeline and locks the sign of the running variable.
   If it won't replicate, STOP — something is wrong before we add anything.
3. **Merge our public-water outcome** onto her units: tap / treated-tap coverage
   from SHRUG/Census (village-code or spatial merge if she has identifiers;
   district-level as a coarse fallback if not).
4. **Run the one regression that matters most:** the RD of public piped-water
   coverage on her running variable, at her bandwidth. The trap predicts public
   water jumps **UP** just past 8 m (where cheap private water is unavailable,
   public provision fills in) — i.e. cheap-water villages have **less** public
   water. This single estimate is the most informative number in the whole
   project.
5. **Two checks we can't skip:** re-confirm covariate continuity + McCrary in the
   merged sample (likely fine — same units she validated), and run placebo
   cutoffs (6/7/9/10 m) on the new outcome.

**The hinge:** feasibility turns entirely on step 1's merge keys. If her data
carries village identifiers or coordinates, 0a is days of work. If it's
district-only, you get a coarse first look now and need extension E1 for a clean
answer.

**Go/no-go after 0a:**
- *Green* — first stage present, validity clean, public-water discontinuity in
  the trap direction (or a tight, interesting null): proceed to Phase 0b.
- *Red* — won't replicate, or covariates jump at 8 m, or the result is a noisy
  nothing: stop or rethink. A clean null/fail here has cost you days, not a year.

---

## Extension ladder (climb only after 0a is green), cheapest first

- **E3 — Agriculture mechanism (cheap; often free in her data).** Replicate her
  irrigation/income result and frame the headline surprise: cheap-water villages
  are *richer* yet have *less* public water. Do NOT control for it in the RD
  (bad control — spec §6); report it as the validating second first stage.
- **E4 — Full validity battery (low–medium).** Bandwidth/polynomial/donut
  sweeps, secondary placebos (roads, schools, clinics), the near-well subsample.
  Needed for a paper, not for the first signal.
- **E2 — JJM take-up + scheme type (medium).** Scrape IMIS (with Wayback
  snapshots for timing) and add the modern, policy-relevant outcome: do
  cheap-water areas resist *connecting* when offered a free public scheme? This
  is the "trap is sticky" test and the bridge to the Odisha story.
- **E1 — Independent depth construction (medium).** CGWB/India-WRIS well
  interpolation to villages (earliest vintage, pre-monsoon), with measurement-
  error handling (fuzzy RD / near-well subsample). Required if her data won't
  merge, or to scale beyond her sample and reach recent outcomes. This is the
  full §§3.2, 4, 5 of the spec.
- **E5 — Lithology cross-section arm (high; Phase 1).** The complementary
  broad-cost-structure design (spec §9) and the historical geology×decade
  divergence figure — the latter needs the DCHB/town-directory digitization.
- **E6 — Odisha / Drink-from-Tap micro (high; separate data partnership).** The
  household-vintage tests (sunk private capital → connection resistance) in
  WATCO data.

---

## How this maps to the documents
- `PHASE0_SPEC.md` is the full reference; Phase 0a above is its §3.1 spine
  (Stages A→C→partial E) run first and alone.
- `PHASE0_SPEC.md` §§3.2–5 = extensions E1–E4 (this is "proper" Phase 0b).
- `PHASE0_SPEC.md` §9 = extension E5.
- `CLAUDE.md` analysis discipline applies throughout — including in 0a, do only
  these steps and write the verdict before exploring.
- `RA_OVERVIEW.md` (the why) and `RA_INSTRUCTIONS.md` (the how, session by
  session) are written around this fast-path-first structure.
