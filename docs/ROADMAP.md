# Water Trap RA — Feuille de route Phase 0

Sep 18, 2026 · @Someone

<!-- COPIE. Source de vérité : https://claude.ai/code/artifact/9d308fe3-d2e6-4316-bbe3-191c1e737498
     Régénérer à chaque pivot, ne pas éditer ici. -->
     
## Statut

**Pivot du 23/09/2026.** Visio avec Jack : la profondeur comme instrument n'était qu'une suggestion pour l'exercice d'exploration, pas une obligation. On abandonne Sekhri (Jack ne souhaite pas lui écrire) : les voies A et A′ sont closes et le RD à 8 m n'est plus le design de référence. On est en phase d'exploration, avec **trois pistes menées en parallèle** — eau souterraine, groupes électrogènes, filtres domestiques — sans en présélectionner une. Ce qui reste acquis du travail fait : le dépôt, l'environnement R, les outils spatiaux et les variables d'eau SHRUG 1991/2001/2011.

- **Question du projet :** l'eau privée bon marché empêche-t-elle l'émergence du réseau public d'eau courante (piège), ou est-ce une allocation efficace des technologies ?
- **Identification (ouverte) :** plus de design imposé. Pour chaque piste, on cherche une variation exogène du **coût du substitut privé** — et non de la demande de service : géologie, prix du capital, date d'arrivée d'une technologie.
- **Prochaine étape :** premier stage géologique sur les puits CGWB déjà téléchargés, vérification des données IHDS/NFHS sur les filtres, puis note de cadrage à Jack.
- **Langage :** R (choix acté, pas encore confirmé par le PI).
- **Règle d'or :** critère de sortie écrit avant d'estimer, verdict écrit contre ce critère, aucune variante discutée avant le verdict. (Remplace la règle §5/§8 de la spec, retirée le 23/09 avec le design RD.)

## Trois pistes exploratoires (depuis le 23/09)

Cadre commun : le piège ne mord que si le bien public est un **réseau à coûts fixes élevés** — quand les ménages solvables sortent, le coût moyen par abonné restant monte et le rendement politique du réseau s'effondre (exit/voice). Prédiction testable : retrait public plus fort pour l'eau courante et l'électricité que pour les biens non-réseau.

| Piste | Substitut privé | Variation identifiante | Statut |
| --- | --- | --- | --- |
| A — Eau souterraine | Forage et pompe | Géologie (roche, fractures, aquifère), à la Ryan & Sudarshan | Données en partie déjà là |
| B — Électricité | Groupe électrogène | Prix du capital (importations, droits de douane), TVA diesel par État, normes CPCB en NCR | À cadrer, littérature à lire |
| C — Eau potable | Filtre domestique | Arrivée du marché de masse : Pureit national début 2008, Tata Swach déc. 2009 | La plus prometteuse côté données |

### Piste A — La géologie comme instrument

Ryan & Sudarshan (JPE 2022) instrumentent la profondeur du puits du paysan par le type de roche (62 catégories), le type d'aquifère (20), la densité de fractures et leurs interactions, en contrôlant élévation, pente et qualité des sols ; l'exclusion est l'absence d'effet direct sur les profits. Avantage pour nous : plus besoin de la profondeur observée village par village, donc plus besoin des microdonnées MI. Limite : la géologie est invariante dans le temps, et à l'échelle de l'Inde « alluvial vs socle » sépare aussi le revenu, la densité et la capacité administrative.

- [ ] Récupérer les couches publiques : aquifères principaux CGWB, lithologie GSI/Bhukosh ; GLiM et WHYMAP en secours
- [ ] Premier stage sur les puits CGWB déjà téléchargés : profondeur \~ roche + fractures + contrôles de surface
- [ ] Trancher IV en niveau (fragile hors d'une petite région) vs DiD géologie × choc temporel (électrification rurale, diffusion des pompes submersibles), avec effets fixes shrid
- [ ] Lire Blakeslee, Dar, Fishman, Malik, Pellegrina & Sekhri (JDE) et Blakeslee et al., « Way down in the hole »

### Piste B — Groupes électrogènes

Le prix du diesel est l'idée naturelle et l'impasse : il entre dans le transport, l'irrigation et la production, donc la forme réduite ne mesure rien d'interprétable. Trois contournements, du plus au moins propre.

- [ ] **Prix du capital plutôt que du carburant** (piste préférée) : baisse des prix des gensets importés, droits de douane ; shift-share sur l'exposition de base
- [ ] TVA diesel par État × exposition de base aux coupures (mesures ASI d'Allcott, Collard-Wexler & O'Connell, AER 2016)
- [ ] Choc réglementaire local : restrictions CPCB sur les groupes diesel en NCR (interdictions saisonnières, retrofit RECD)
- [ ] Données : ASI (auto-production captive, dépenses de carburant), Economic Census, NSS/IHDS côté ménages
- [ ] Garder le sens en tête : la littérature existante va des coupures vers l'adoption ; nous voulons le retour

### Piste C — Filtres à eau domestiques

Le timing du marché de masse tombe très bien : Pureit introduit en 2005 à Chennai puis dans le Sud, lancement national début 2008 ; Tata Swach lancé le 7 décembre 2009 à moins de 1 000 ₹, sans électricité ni eau courante. La bascule tombe donc entre les recensements 2001 et 2011, entre NFHS-3 (2005-06) et NFHS-4 (2015-16), et entre IHDS-I (2004-05) et IHDS-II (2011-12, qui est un panel de ménages).

- [ ] Vérifier IHDS-I/II : possession de filtre et source d'eau, panel exploitable ; taux d'adoption par district 2005 → 2012
- [ ] Idem NFHS-3/4 sur le traitement de l'eau au niveau ménage, agrégé par district
- [ ] Exposition = part de ménages sur eau non traitée au départ (et accès à l'électricité pour les purificateurs UV) × après 2008
- [ ] Outcome = qualité et dépenses de potabilisation, **pas** couverture du réseau : le filtre remplace la station de traitement, pas le tuyau. `tap_treated11` est déjà construit
- [ ] Formaliser le mécanisme politique (exit/voice) et chercher les précédents : écoles privées, cliniques privées

### À trancher avec Jack

- [ ] Un seul cas approfondi, ou trois chapitres d'un même papier sur la même mécanique ?
- [ ] Périmètre géographique par piste
- [ ] Ce qu'on garde du travail SHRUG déjà fait (variables d'eau, ancre des manquants 2001/2011)

## À faire maintenant

Mise en place terminée. Voies A et A′ (microdonnées de Sekhri) abandonnées le 23/09. La section Voie B ci-dessous est conservée : ses outils spatiaux et les puits CGWB resservent directement à la piste A.

**Documents**

- [x] Décompresser `phase0_packet.zip` et lire FAST\_PATH.md et KICKOFF.md
- [x] Mettre à jour CLAUDE.md pour R (section Tooling, `make all` → `Rscript run_all.R`, matplotlib → ggplot2), puis répercuter dans RA\_INSTRUCTIONS §A5 et KICKOFF pour que le packet reste cohérent

**Comptes et téléchargements**

- [x] Télécharger Sekhri 2011 (openICPSR 113803 ; code et Readme seulement, aucune donnée)
- [x] Créer un compte openICPSR et télécharger Sekhri 2014 (projet 113902)
- [x] Télécharger les modules SHRUG v2.2 (clés, PCA et VD 1991/2001/2011)
- [x] Tout ranger dans `raw/sekhri/` et `raw/shrug/` sans rien modifier

**Environnement**

- [x] Créer le dépôt `water-trap` (hors OneDrive), `git init`, commit du packet
- [x] Initialiser `renv` ; installer haven, dplyr, readr, rdrobust, rddensity, ggplot2
- [ ] Vérifier que `rdd` s'installe encore (bande IK pour la réplication)
- [x] Installer VS Code + extension Claude Code ; faire confiance au workspace

**Inventaire à la main**

- [x] Lancer le script d'inspection sur chaque `.dta` de Sekhri
- [x] Noter : variable de profondeur et millésime, unité, identifiants (codes village 2001 ? coordonnées ? district seulement ?)
- [x] Envoyer le mail au PI avec l'inventaire et les questions ouvertes

## Voie B — préparation (E1, profondeur indépendante)

À préparer en attendant Jack : collecte de données et outillage seulement, aucune estimation. Les principes sont fixés par la spec (§3.2, §4) : puits d'observation CGWB, relevé le plus ancien et pré-mousson (mai), interpolation jusqu'aux villages avec une erreur par village, puis RD flou ou sous-échantillon proche d'un puits.

**Données et outils**

- [ ] Données de puits CGWB (India-WRIS) : coordonnées et niveaux trimestriels ; vérifier le plus ancien relevé par puits (cible : milieu des années 1990)
- [ ] Explorer les raccourcis : couche des stations India-WRIS ; fichier national 1996–2017 que d'autres chercheurs ont obtenu du CGWB par mail
- [ ] SHRUG : module « Open Polygons and Spatial Statistics » dans `raw/shrug/`, avec sa ligne dans le README
- [ ] Packages R : sf, terra, exactextractr, gstat, puis `renv::snapshot()`

**Faisabilité (sans toucher aux résultats)**

- [ ] Densité de puits par district ; part des villages à moins de quelques kilomètres d'un puits

**Choix à faire trancher par Jack**

- [ ] Périmètre : Uttar Pradesh seul, plaine gangétique ou Inde entière
- [ ] Méthode d'interpolation (krigeage ou IDW) et rayon du sous-échantillon proche des puits

## Plan Phase 0a

**Suspendu depuis le 23/09** — ce plan dépendait des microdonnées Sekhri. Conservé comme gabarit : les six étapes, leurs critères de sortie et la discipline d'analyse restent valables pour la piste qui sera retenue.

```mermaid
flowchart LR
  A[1. Inventaire<br/>Sekhri] --> B[2. Réplication<br/>Stage A]
  B --> C[3. Fusion<br/>SHRUG]
  C --> D[4. RD principales<br/>Stages B-C]
  D --> E[5. Validité<br/>minimale]
  E --> F[6. Verdict §8]
```

### 1. Inventaire Sekhri (½ jour)

- [x] Mémo d'une page par package : profondeur et millésime, unité, bande, noyau, définitions, clés de fusion
- [ ] Signaler tout résultat de Sekhri 2011 qui devancerait une de nos contributions
- [x] **Sortie :** clés village présentes → continuer ; district seulement → E1 ou escalade au PI. **Résultat (18/09) :** ni profondeur ni clés dans les deux packages → escalade faite.

### 2. Réplication de Sekhri 2014 — Stage A (½ à 1 jour)

- [ ] Reproduire avec son estimateur : `rd` de Stata (noyau rectangulaire, bande IK) et bande de 5 ; score = profondeur **1993** (2ᵉ recensement MI) − 8 ; villages qui franchissent 8 m entre 1993 et 2000 exclus. Bloqué tant que les fichiers MI ne sont pas obtenus.
- [ ] Cible : 0,097 (0,04) sur le taux de pauvreté, Table 6 col. 3
- [ ] Ré-estimer ensuite en CCT (triangulaire, MSE-optimale)
- [ ] **Sortie :** chiffres reproduits et signe de `z` confirmé ; sinon STOP

### 3. Fusion des variables d'eau SHRUG (1 jour)

- [ ] Vérifier les noms des variables d'eau 2001/2011 sur docs.devdatalab.org et les noter dans l'en-tête du script
- [ ] Rattacher `tap11`, `tap_treated11`, `private_gw11` aux villages de Sekhri via `shrid2` (en caractères)
- [ ] Log du taux d'appariement ; enquêter si < 80 %
- [ ] **Sortie :** taux d'appariement documenté et acceptable

### 4. RD principales — Stages B et C (1 jour)

- [ ] Première étape : `private_gw` saute vers le bas à `z > 0`
- [ ] Résultat principal : `tap` / `tap_treated` sautent vers le haut à `z > 0`
- [ ] Placebo : `drnk_wat_f` ne saute pas
- [ ] Chaque régression sous les deux traitements des valeurs manquantes (missing = 0 et listwise)
- [ ] Donut RD pour l'empilement aux profondeurs entières (0,5 m ; robustesse 0,25 et 1,0)

### 5. Validité minimale (1 jour)

- [ ] Test de densité McCrary / Cattaneo-Jansson-Ma
- [ ] Continuité des covariables pré-traitement disponibles chez Sekhri (jamais le taux d'épuisement ni le nombre de puits)
- [ ] Seuils placebo à 6, 7, 9 et 10 m

### 6. Verdict (½ jour)

- [ ] Mémo `memo/phase0_decision_memo.pdf` : verdict §8 en première ligne, puis magnitudes, puis recommandation
- [ ] Mail au PI en quatre phrases : verdict, magnitudes, validité, recommandation
- [ ] Vérifier que `Rscript run_all.R` reproduit tout depuis un clone propre

## Checkpoints manuels

Dix points où ton jugement remplace celui de l'agent ; ne les coche qu'après avoir vu toi-même l'objet (tableau, graphique, log).

- [ ] **1. Compréhension du cadre** : l'agent restitue la question (quand le privé prend-il le relais du public), la variation identifiante de la piste et le sens attendu de l'effet
- [ ] **2. Source de variation** : ce qui est exploité porte bien sur le **coût du substitut privé**, pas sur la demande de service
- [ ] **3. Pertinence** : l'instrument ou le choc déplace visiblement l'adoption privée ; magnitude du premier stage regardée à l'œil, pas seulement le F
- [ ] **4. Pré-tendances** : pour toute spécification en différences, trajectoires vues sur graphique avant la moindre estimation
- [ ] **5. Clés et taux d'appariement** : la fusion garde bien les unités ; taux documenté, enquête si < 80 %
- [ ] **6. Mécanismes rivaux** : épuisement de la ressource, revenu, capacité administrative — testés, pas seulement invoqués
- [ ] **7. Le privé bouge en premier** : aucun récit où le coût du public saute au même endroit que celui du privé
- [ ] **8. Stabilité aux manquants** : missing = 0 vs listwise comparés, écart signalé
- [ ] **9. Verdict** écrit contre des critères fixés d'avance, avant toute discussion de variantes
- [ ] **10. Reproductibilité** : une commande depuis un clone propre

**Escalade immédiate au PI si :** premier stage ou choc trop faible ; pré-tendances qui divergent ; pas de fusion possible ; résultats qui s'inversent selon la spécification ou le traitement des manquants ; une piste qui bute sur des données non publiques ; tentation de garder une piste qui ne marche pas.

## Questions pour le PI

Points ouverts à regrouper dans un prochain mail, envoyé après l'inventaire, avec les faits trouvés.

**Mise à jour 23/09 :** liste triée après le pivot. Les points liés à la réplication de Sekhri (clés de fusion, estimateur du Stage A, puissance sur 1 171 villages, dispersion de l'habitat, numérotation des extensions) sont retirés — ils sont sans objet.

- [ ] **Mesure de l'adoption privée :** `private_gw` mélange « tubewell OU handpump », donc sans doute les India Mark II publiques, et sature près de 1 dans l'UP. Quelle mesure retenir pour la piste A ?
- [ ] **Périmètre et échelle :** shrid, district ou ville selon la piste ; l'Inde entière est-elle défendable pour un instrument géologique, ou faut-il se restreindre à une région ?
- [ ] **Accès aux données :** ASI pour les générateurs, IHDS et NFHS pour les filtres — a-t-il des accès ou des contacts à mobiliser ?
- [ ] **Langage :** analyse en R plutôt qu'en Python (rdrobust, rddensity, sf, gstat en implémentations de référence) — toujours à confirmer

## Journal des décisions

Une ligne par décision, la plus récente en haut ; noter qui a tranché.

| Date | Décision | Raison | Validée par |
| --- | --- | --- | --- |
| 23/09/2026 | Explorer trois pistes en parallèle : eau souterraine (géologie), groupes électrogènes, filtres domestiques | Phase d'exploration assumée : certaines ne marcheront pas, on ne présélectionne pas | Jack et Valentine (visio) |
| 23/09/2026 | Abandon de Sekhri et du RD à 8 m comme design de référence | Jack ne souhaite pas écrire à Sekhri ; la profondeur comme instrument n'était qu'une suggestion pour l'exploration | Jack (visio) |
| 18/09/2026 | Escalade : proposer la voie A (données de Sekhri) et préparer la voie B (E1) en parallèle | Packages 113902 et 113803 sans profondeur ni clés vers le recensement (0 % de match avec SHRUG) | Valentine ; en attente de Jack |
| 18/09/2026 | Analyse en R (renv, rdrobust, rddensity) | Implémentations de référence de l'estimateur RD | Valentine ; à confirmer par le PI |

## Journal des sessions Claude Code

Une ligne par session, avec son commit git, pour pouvoir revenir en arrière. Avant chaque session de construction : modèle le plus capable, Extended Thinking, Plan Mode (Shift+Tab) ; `/compact` entre les phases.

| Date | Session | Objectif | Résultat / ce que j'ai vérifié | Commit |
| --- | --- | --- | --- | --- |
|  | Session 1 | Dépôt, validation des fichiers, inventaire, réplication Stage A |  |  |
|  | Session 2 | Fusion, RD principales, validité minimale, verdict |  |  |

### Premier prompt de la Session 1 (Plan Mode)

Version de KICKOFF adaptée à R et aux deux packages Sekhri :

```
Read CLAUDE.md, PHASE0_SPEC.md, and FAST_PATH.md in full. This project is done in R only (see the Tooling section of CLAUDE.md). Then:
(a) summarize back the design, the sign conventions, the §8 decision gate, and the analysis-discipline constraints in your own words so I can check your understanding;
(b) inventory what is in raw/, i.e. BOTH Sekhri packages (2014, openICPSR 113902, and 2011, 2010-0056_data.zip): for each, the running variable and its vintage, the unit of analysis, the bandwidth and kernel, and the merge keys available to join our SHRUG/Census public-water outcomes. Report what you find; do not guess variable names;
(c) propose the repository scaffold, the renv setup, the ingest-validation plan, and a plan to replicate Sekhri (2014) Table 6 with HER estimator first (rectangular kernel, IK bandwidth, bandwidths 5 and 2) before any CCT re-estimation.
Do not write any analysis code beyond the Stage A replication plan yet, and do not start extensions.
```

## Extensions (seulement si 0a est vert)

Environ 3 à 5 semaines de plus (« Phase 0b »), dans l'ordre de FAST\_PATH, du moins cher au plus cher. Numérotation de FAST\_PATH, reprise par RA\_INSTRUCTIONS, CLAUDE.md et KICKOFF.

| Ordre | Extension | Contenu | Coût | Données |
| --- | --- | --- | --- | --- |
| 1 | E3 — Agriculture (mécanisme) | Répliquer son résultat irrigation / revenu ; « plus riches mais moins d'eau publique » ; jamais en contrôle | Faible | Souvent déjà dans les données Sekhri |
| 2 | E4 — Batterie de validité complète | Balayages bande / polynôme / donut, placebos routes / écoles / dispensaires, sous-échantillon proche des puits | Faible à moyen | Idem |
| 3 | E2 — Take-up JJM + type de schéma | Raccordement quand un schéma gratuit est offert ; timing via Wayback ; test « le piège colle » | Moyen | JJM IMIS + Wayback |
| 4 | E1 — Profondeur indépendante | Interpolation CGWB, 1er relevé pré-mousson, erreur de mesure | Moyen | India-WRIS / CGWB |
| Phase 1 | E5 — Lithologie | Bras §9 et figure géologie × décennie | Élevé | GSI Bhukosh ; numérisation DCHB |
| Phase 1 | E6 — Odisha / Drink-from-Tap | Tests sur l'ancienneté des équipements privés | Élevé | WATCO, partenariat à part |

## Ressources

**Documents du projet** (dossier Drive « research assistant ») : [dossier](https://drive.google.com/drive/folders/1C1xJhsl62NqJWLa06aM1xohioaimIK2d) · RA\_OVERVIEW (le pourquoi) · RA\_INSTRUCTIONS (le comment) · PHASE0\_SPEC (variables, régressions, §8) · CLAUDE.md (règles de l'agent) · FAST\_PATH et KICKOFF · README (ordre de lecture et règle de cohérence du packet).

**Articles**

- Sekhri (2014), « Wells, Water, and Welfare », *AEJ: Applied* 6(3) — [PDF dans le dossier](https://drive.google.com/file/d/1WI4E3f4VQWbgmEns188b9B5BbM71tr-q/view) ; réplication openICPSR 113902 (code, pauvreté et enquête ; pas de profondeur)
- Sekhri (2011), « Public Provision and Protection of Natural Resources », *AEJ: Applied* 3(4) — antécédent le plus proche, à citer en premier ; réplication openICPSR 113803 (code seulement)
- Blakeslee, Fishman et Srinivasan (2020), *AER* — contrepoint : l'échec des puits ne déclenche pas de provision publique
- Blakeslee et Fishman (2018, wp), inégalités et accès à l'eau qui s'épuise — version à retrouver
- Srinivasan et al. (2025), *PLOS Water* — mécanisme rival d'épuisement
- Ryan et Sudarshan (2022), « Rationing the Commons », *JPE* 130(1) — géologie (roche, fractures, aquifère) comme instrument de la profondeur ; modèle de la piste A
- Allcott, Collard-Wexler et O'Connell (2016), *AER* — pénuries d'électricité et auto-production dans l'ASI ; mesures réutilisables pour la piste B
- Blakeslee, Dar, Fishman, Malik, Pellegrina et Sekhri (JDE), et Blakeslee et al., « Way down in the hole » — géologie de socle et assèchement des puits
- Hirschman (1970), *Exit, Voice and Loyalty* — cadre du retrait politique, pistes B et C

**Données :** openICPSR · devdatalab.org (SHRUG) · docs.devdatalab.org/variable-search pour les noms de variables 2001/2011.
