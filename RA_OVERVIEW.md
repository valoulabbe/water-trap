# RA Overview: The Private Infrastructure Trap (Water Project)

*Read this first. It explains what we are trying to learn and why, assuming no
background in the literature. Budget ~15 minutes. `RA_INSTRUCTIONS.md` tells you
what to actually do; `FAST_PATH.md` is the short version of the work plan; and
`PHASE0_SPEC.md` has the exact data, variables, and regressions.*

---

## 1. The big question

Essential services — water, electricity, sanitation — can be delivered two ways:

- **Public / networked:** high fixed cost, low marginal cost. A piped water
  network is expensive to build but cheap to serve one more household once it
  exists. Quality is high (centralized treatment, monitoring, continuous supply).
- **Private / decentralized:** low fixed cost, high marginal cost. A household
  borewell or handpump is cheap to install but you bear the full per-unit cost
  yourself, and quality has a low ceiling (no treatment, no monitoring).

The question driving the project: **can the availability of the cheap private
option actually prevent the better public system from ever being built — and
leave people worse off in the long run?** We call that failure a **"private
infrastructure trap."** The logic: if enough people solve their own problem
privately, there is no longer the assembled demand or political support to
justify the public network, and everyone ends up stuck on an inferior technology
no single household can replace alone.

## 2. Why it isn't obvious — the rival explanation we must defeat

There is an innocent explanation for the same facts, and taking it seriously is
the heart of the project. Maybe places use private wells because wells are
genuinely the *right* technology there, and pipes elsewhere because pipes are
right there. That would be **efficient technology assignment** — a success, not
a trap. The two stories look identical in a simple comparison of regions.

So the whole design exists to **distinguish a trap from efficient assignment.**
The difference shows up in two places: **dynamics** (a trap stays stuck even
after the cheap option becomes a bad deal, or after a free public connection is
offered) and **welfare** (under a trap, the people on the private technology are
worse off — exposed to contamination a network would screen out, and with the
poorest, who can't afford a private well, left behind).

## 3. Our natural experiment: the 8-meter rule

We need something that made the *private* option cheap in some places and
expensive in others, for reasons unrelated to income, governance, or how good
the public option is. **The physics of water pumps gives us this.**

A cheap suction pump (the ordinary centrifugal pump) can only lift water from
roughly **8 meters** below the surface or less — that's a hard physical limit
(atmospheric pressure). If the water table sits deeper than about 8 meters, you
need a much more expensive submersible / deep-borewell setup. So:

- Water table **shallower than ~8 m** → cheap private water. → *cheap private
  technology.*
- Water table **deeper than ~8 m** → expensive private water. → *expensive
  private technology.*

This gives a sharp "regression discontinuity": compare villages whose water
table sits *just above* versus *just below* 8 meters. They have nearly identical
soil, climate, and settlement — but a sharply different **cost of getting water
privately**. That clean local comparison is what lets us make a causal claim
that a region-by-region comparison can't.

**One subtle but crucial point.** The 8-meter limit is about *suction* — pulling
water up from above. It only makes the *cheap private* options expensive (a
farmer's surface pump, a shallow well). The *public* options we care about don't
rely on suction: a piped network puts its pump down at the source, and India's
standard public handpump (the India Mark II) lifts from deep down with a
submerged cylinder. So crossing 8 meters raises the cost of *private* water
without raising the cost of *public* water. That asymmetry is what makes the
design clean: if public water provision or use jumps at 8 meters, it's because
the private alternative got expensive — not because the public system did. (This
means the sharpest test is **take-up**: where a public scheme exists, do people
actually connect to it? Below 8 m, with cheap private water on hand, many don't;
above 8 m, they do. That's the trap, and its stickiness, in one number.)

This design comes from influential work by **Sheetal Sekhri** — her 2014 paper
"Wells, Water, and Welfare" used exactly this 8-meter threshold to show that where
private groundwater is cheap, agriculture does better and poverty is lower, and her
2011 paper already paired the same threshold with a public-vs-private provision
question. We borrow her identification and point it at a question she didn't ask:
**what happens to the public drinking-water *network* over the long run?** (Because
the 8-meter design is hers, the novelty of our project lives in the model — the
dynamic trap and the political forces — and in the network outcome, not in the
identification itself. The spec's §12 spells this out; you don't need it to run the
analysis, but it's why we're careful to cite her prominently.)

Our prediction: just past 8 meters (where cheap private water disappears), public
piped-water coverage should jump **up** — because where households can't
self-supply, public provision is the only option left. Equivalently, the cheap-
water villages should have **less** public water. That "less public water where
private water is cheap" pattern is the trap's fingerprint.

## 4. The agriculture twist (important — it flips from threat to asset)

Here is the subtle part. Sekhri showed cheap groundwater makes places **richer**
through better irrigation. You might think that wrecks our design — geology
affects incomes, not just water choice. In a crude region comparison it would.
But in the local 8-meter comparison it does two helpful things:

1. **It validates the experiment.** If farming and incomes really do jump at
   exactly 8 meters, that confirms the cutoff genuinely changes water access —
   a second check that the design works.
2. **It makes our result *harder* to get, which makes it more convincing.**
   Richer places usually get *more* public infrastructure, not less. So the
   income effect pushes *against* our prediction. If we still find *less* public
   water where water is cheap — even though those places are richer — that's
   strong evidence of a trap, because it survives a force working the other way.

The memorable headline, if it holds: **the villages that won the groundwater
lottery are richer, yet have worse public water.** (Note for later: we do *not*
statistically "control for" income inside this comparison — because income is
itself a consequence of the cheap water, controlling for it would be a mistake.
The spec explains why.)

## 5. What "worse off" would look like

If it's a trap, not efficient assignment, then cheap-private-water areas should
show, at comparable incomes: more untreated-water contamination and waterborne
illness (a network would treat the water); falling water tables as everyone
privately over-pumps a shared resource; the poor left with the worst access; and
reluctance to connect even when a public scheme is finally offered, because money
is already sunk in private wells and tanks.

## 5A. The one rival story we have to rule out

There's a second explanation for "more public water where private water is
expensive," and it isn't ours. Call it the **depletion** story: cheap private water
→ everyone digs wells → the aquifer collapses → the private option *fails* → the
government eventually builds piped water as a **rescue**. That also predicts more
public water on the deep side, so the headline number alone can't tell the two apart.

Ours (**substitution**) is about *choice*: people with cheap private water don't want
or connect to the network. The rival (**depletion**) is about *resource collapse*:
people would happily have used private water, but it ran out.

Three things separate them, and they're built into the analysis:
- **Timing.** Substitution shows up early and persists; depletion only after decades
  of drawdown.
- **Take-up where wells still work.** If people decline to connect while their private
  water is still fine, that's substitution, not collapse.
- **Rich vs. poor.** Depletion makes places *poorer*. So if cheap-water villages are
  *richer* and *still* have worse public water, that points to substitution.

Two consequences worth knowing. Because private over-pumping also drags *public*
borewells into a deepening race, we anchor the main outcome on the **piped network**,
not on public borewells. And because the depletion rate is itself *caused* by the
treatment, it must never go into the covariate-balance tests — it's expected to jump
at 8 m, and that jump is a sign the design works.

## 6. The work: a quick first test, then optional extensions

The full project is multi-year. The RA's near-term job is deliberately **quick**,
because we can stand on Sekhri's existing, already-validated work instead of
building everything from scratch.

- **Phase 0a (the fast version — days to about two weeks):** Get Sekhri's
  published replication data, reproduce her result to confirm our setup is
  correct, merge in our public-water outcome, and run the one regression that
  matters — does public water jump up at the 8-meter cutoff? This single number
  is the most informative in the project, and it's cheap to get.
- **Then, only if 0a looks promising, optional extensions** (laddered in
  `FAST_PATH.md`): the agriculture mechanism, a full battery of validity checks,
  the modern government water-mission take-up data, building our own depth data
  to scale up, and — later, as a bigger investment — a complementary rock-type
  design and the Odisha "Drink from Tap" household study.

The point of front-loading the cheap test is that an honest "this doesn't hold"
after a few days saves the project a year of expensive data work.

## 7. One principle to internalize

We fixed the pass/fail criteria and the exact analyses *before seeing any data*
(`PHASE0_SPEC.md` §8). That discipline is what separates testing a hypothesis
from fishing for a result. If something is borderline, we report it as
borderline; we don't move the goalposts, and we don't run extra specifications
hunting for significance until the decision memo is written. Protecting that —
including against the AI coding agent, which will happily run a hundred
variations if asked — is part of your job. A clean null or a clean "it fails" is
a **successful** Phase 0.

---

### The document set, at a glance
- **RA_OVERVIEW.md** (this file) — why the project exists.
- **FAST_PATH.md** — the work plan in brief: the quick test, then extensions.
- **RA_INSTRUCTIONS.md** — what you do, step by step.
- **PHASE0_SPEC.md** — exact data, variables, regressions, decision gate.
- **CLAUDE.md** — standing instructions for the Claude Code agent.
- **KICKOFF.md** — how to set up and drive the Claude Code session.
