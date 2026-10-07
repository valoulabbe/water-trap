# Piste A′-L-C4 — le premier stage du tableau C4 tient-il hors échantillon ? (critère fixé avant estimation)

Rédigé le 07/10/2026, avant toute estimation, après les verdicts A′ (ÉCHOUE)
et A′-L (PASSE, 0,109) et leurs errata. A′-L reprenait la méthode de sélection
des auteurs, mais pas leur fichier ni leurs contrôles. Cette variante
reproduit le premier stage publié (tableau C4, colonne « Main ») : même
fichier, même échantillon, mêmes contrôles, même ensemble de candidats. On lui
ajoute la validation croisée par départ de A′-L. Code :
`code/31_piste_a_prime_lasso_c4.py`, qui réutilise les fonctions de
`code/30_piste_a_prime_lasso.py`.
Statut : **porte de faisabilité** (passe / échoue).

## Ce que la porte décide
- **Passe :** le premier stage tel que les auteurs l'ont publié prédit la
  profondeur hors échantillon. Le résultat de A′-L ne dépend pas de nos
  écarts à leur spécification.
- **Échoue :** le gain de A′-L tenait à nos écarts (unité agriculteur, absence
  du sol et des déciles). On le rapporte comme tel. A′-L reste passée selon
  son propre critère, mais la conclusion « l'instrument des auteurs tient hors
  échantillon » est retirée.

Dans les deux cas, les portes B (couches fines pour SHRUG) et C (équilibre de
1991) restent la question pour la piste A.

## Échantillon : reproduction de `rationing_data_preparation.do`, `rationing_summary_statistics.do` et du `e(sample)` d'`ivlasso`
- **Fichier :** `marginal_analysis_sample_crop_level.dta`, une ligne par
  agriculteur × culture.
- **Lignes retirées :** `d1_tot_land` ou `b7_3_3_avg_surce_dpth_resp_ft`
  manquant (l. 93 ; dans le code des auteurs, `b7_3_3_avg_surce_dpth` est une
  abréviation Stata de cette variable).
- **Déciles de terre :** `xtile` sur `d1_tot_land`, 10 groupes, calculés sur
  les lignes restantes. Indicatrices 2 à 10.
- **Contrôles de sol :** ils sont construits exactement comme aux l. 129–224,
  sans corriger la coquille des auteurs (`prop_med_p = M_P/Tot_K`). Quand
  `missing_soil_controls` vaut 1, les proportions sont mises à 0. Cela donne 12
  contrôles : `prop_sufficient_{s,zn,fe,cu,mn}`, `prop_high_{k,p}`,
  `prop_med_{k,p}`, `prop_acidic`, `prop_mildly_alkaline`,
  `missing_soil_controls`.
- **Échantillon d'estimation :** profondeur, 419 candidats, 28 contrôles et
  variable dépendante de profit non manquants, comme le `e(sample)`
  d'`ivlasso`. La variable de profit (`profit_cashwown`, construite comme aux
  l. 41–52) **ne sert qu'à reproduire ce schéma de valeurs manquantes**. Elle
  n'est jamais estimée ni lue comme résultat.
- **Validation (arrêt sinon) :** exactement **8 973 lignes et 3 999
  agriculteurs**, et **28** contrôles non constants, comme dans
  `rationing_main.log` (l. 33515 et suivantes). Un écart signifie que la
  reproduction est ratée : on s'arrête et on le rapporte, sans ajuster.

## Spécification
- **Candidats :** l'ensemble `MAIN` de 419 colonnes (identique à A′-L).
- **Contrôles non pénalisés retirés avant sélection :** déciles de terre,
  effets fixes de SDO, altitude, pente, 12 contrôles de sol.
- **LASSO :** fonction `rlasso` de A′-L, pondérations groupées par départ
  (304) et calculées sur les lignes. C'est ce que fait la pénalité
  « cluster-lasso, 304 clusters » du log.
- **Prédiction :** MCO post-lasso sur les instruments retenus et les
  contrôles.
- **Validation croisée :** les 10 plis de A′ (`build/29_plis_departs.csv`).
  Un départ retiré l'est avec toutes ses lignes. La sélection est refaite sur
  les seules lignes d'apprentissage. Le centrage par SDO se fait sur tout
  l'échantillon.
- **R² compté sur les lignes** (agriculteur × culture), l'unité d'estimation
  des auteurs.

## Règle de passage
**Gain de R² hors échantillon ≥ 0,05**, soit
R²_CV(post-lasso + contrôles) − R²_CV(contrôles seuls), avec les 10 plis de A′.
Même seuil que A′ et A′-L.

## Rapporté à côté du verdict (hors critère)
- **Conformité de l'implémentation :** instruments retenus sur tout
  l'échantillon, comparés à la liste publiée de 16 (C4, « Main »). Il n'y a
  pas de seuil, mais un recouvrement de moins de 8 sur 16 sera signalé :
  l'implémentation diffère alors de lassopack sur l'échantillon même des
  auteurs.
- **F de faible identification i.i.d.** des instruments post-lasso sur tout
  l'échantillon, à comparer aux 86,8 publiés. Également la version groupée par
  départ.
- **R² compté par agriculteur :** prédictions moyennées par agriculteur.
- **Un pli par SDO** (borne stricte de transport).
- **Liste publiée de 16, fixe**, en validation croisée.
- **Sans déciles de terre** (contrôles de A′ plus sol).

## Hors périmètre
Aucune variable de résultat de notre question, aucun second stage, aucun
appariement SHRUG.
