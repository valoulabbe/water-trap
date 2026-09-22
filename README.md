# README — Project Packet (Phase 0)

Self-contained handoff for **Phase 0** of the "private infrastructure trap" water
project: a fast, cheap test of whether cheap private groundwater access in India
lowered long-run *public* piped-water provision (a trap), as opposed to places
simply using the appropriate technology for their conditions.

## The design in three sentences
Identification is the **8-meter groundwater-depth regression discontinuity**
(Sekhri 2014): cheap suction pumps lift water only from shallower than ~8 m, so
villages whose water table sits just above vs. just below 8 m differ sharply in
the cost of private water but are otherwise alike. We borrow that validated
cutoff and ask what happens to the *public* network — the trap predicts public
water jumps **up** just past 8 m, where cheap private water disappears, i.e.
cheap-water villages have *less* public water. The agriculture literature (cheap
water → richer) doesn't sink this design; at the local cutoff it *validates* the
experiment and makes the trap result conservative, because richer places usually
get more infrastructure, not less.

## What's here, and the order to read it

**For the RA (a human):**
1. **`RA_OVERVIEW.md`** — the why. The economic question, the trap-vs-efficient-
   assignment problem, the 8-meter experiment, the agriculture twist, and the one
   discipline rule. Read first (~15 min); assumes no background.
2. **`FAST_PATH.md`** — the work plan in brief: Phase 0a (the quick test that
   borrows Sekhri's data) and the laddered optional extensions.
3. **`RA_INSTRUCTIONS.md`** — the how, step by step: setup, data, driving Claude
   Code, your manual checkpoints, when to escalate, packaging.

**For Claude Code (the AI agent), and for the RA to consult:**
4. **`PHASE0_SPEC.md`** — the authoritative technical spec: sign conventions, data
   sources, construction, the Stage A–E analyses, the §8 decision gate, and the
   secondary lithology arm (§9).
5. **`CLAUDE.md`** — standing instructions the agent loads: work order, the
   non-negotiable analysis discipline, tooling, data-access division of labor,
   verified data facts.
6. **`KICKOFF.md`** — how to set up and drive the Claude Code session: Plan Mode,
   model/extended-thinking settings, the session sequence, the first prompt.

## The work, in short
**Phase 0a (days to ~2 weeks):** get Sekhri's replication package, reproduce her
result (confirms the pipeline and the sign of the running variable), merge in our
public-water outcome, run the one RD that matters, do the can't-skip validity
checks. **Then, only if 0a is green,** climb the extension ladder in `FAST_PATH.md`
(agriculture mechanism → full validity battery → government-mission take-up →
build our own depth data → later, the rock-type arm and the Odisha study). The
feasibility hinge is whether Sekhri's deposited data carries keys to merge our
outcome — the first task is to download it and look.

## What success looks like
A reproducible `output/` folder, the Stage A replication, one headline RD estimate
with its validity battery, and a 3–5 page memo whose first line is the gate verdict:
proceed, need independent depth data first, or stop. An honest "stop" after a few
days is a successful Phase 0.

## One discipline note
The analyses and pass/fail criteria were fixed before seeing data and must not
drift. If you revise a threshold or a definition in `PHASE0_SPEC.md`, update the
RA-facing documents to match — the whole packet is meant to tell one story.

## `build/` contient des copies converties des données SHRUG

`build/` n'est pas seulement un dossier de sorties : il contient aussi une
copie `.rds` de chaque table `.dta` de `raw/shrug/`, produite par
`code/00_convert_dta.R`.

**Pourquoi.** Sur la machine de développement, une politique de contrôle
d'application Windows bloque par intermittence le chargement des DLL de
packages R depuis le cache `renv` (message : *« LoadLibrary failure : Une
stratégie de contrôle d'application a bloqué ce fichier »*, le plus souvent sur
`cli.dll`). `haven` devient alors indisponible sans préavis et toute lecture de
`.dta` échoue, parfois en pleine exécution du pipeline. Un `.rds` se lit avec
`readRDS()`, sans aucun package tiers : une fois la conversion faite, le
pipeline ne dépend plus de `haven`.

**Statut des fichiers.** Les `.rds` sont des **copies dérivées, jamais la source
de vérité**. `raw/` reste immuable et n'est ouvert qu'en lecture. Les objets
sont enregistrés tels que `haven` les renvoie, étiquettes Stata comprises, pour
que la lecture via `.rds` et via `.dta` donne exactement le même objet.
`build/` étant dans `.gitignore`, ces copies ne sont pas versionnées : il faut
relancer la conversion après un clone.

**Usage.**

```
Rscript code/00_convert_dta.R                # les 59 tables (~3,9 Go de source)
Rscript code/00_convert_dta.R --used-only    # les 8 tables lues par le pipeline
```

Le script se lance **seul**, il n'est pas dans `run_all.R`. Il est idempotent :
le SHA256 de chaque `.dta` source est consigné dans
`build/dta_conversion_manifest.csv`, et une table n'est reconvertie que si son
`.rds` manque ou si le hachage de la source a changé. Il écrit le manifeste au
fil de l'eau, donc une interruption ne perd rien et la relance reprend où elle
s'était arrêtée. Les tables du pipeline sont converties en premier.

**Effet sur les étapes.** Aucun appel à modifier : `read_dta_chk()` préfère
`build/<nom>.rds` et ne retombe sur le `.dta` que si la copie est absente. Si
les deux manquent, l'exécution s'arrête avec un message explicite plutôt que de
planter sur une DLL.

**Conséquence pour la validation.** Quand l'étape 1 lit une copie convertie,
elle valide la conversion et non le `.dta` lui-même ; son log le signale
fichier par fichier, et le SHA256 de la source se retrouve dans le manifeste de
conversion. L'intégrité des archives `.zip` téléchargées reste vérifiée
séparément contre `raw/README.md`.
