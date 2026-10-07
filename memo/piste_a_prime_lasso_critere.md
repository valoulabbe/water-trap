# Piste A′-L — la sélection LASSO des auteurs retrouve-t-elle un premier stage ? (critère fixé avant estimation)

Rédigé le 06/10/2026, après le verdict de A′
(`memo/piste_a_prime_geologie_fine_verdict.md`) et avant toute estimation.
C'est une variante discutée après verdict : elle reproduit la sélection des
instruments de Ryan & Sudarshan, que A′ avait écartée. Code en Python, à la
demande de Valentine (`code/30_piste_a_prime_lasso.py`).
Statut : **porte de faisabilité** (passe / échoue).

## Ce que la porte décide
- **Passe :** la géologie fine prédit la profondeur hors échantillon une fois
  les instruments choisis comme le font les auteurs. L'hypothèse d'échelle tient
  sur leur terrain, et les portes B (couches fines pour SHRUG) et C (équilibre
  de 1991) deviennent la question.
- **Échoue :** même avec leur sélection, aucun premier stage ne se transporte
  d'un départ à l'autre. C'est un résultat sur leur propre terrain, et la piste
  A reste close.

## Échantillon et plis
Identiques à A′ : 4 006 agriculteurs, 304 départs, 6 SDO. On reprend les plis
de A′ (`build/29_plis_departs.csv`, graine 20261006). Arrêt si l'échantillon
reconstruit en Python diffère de celui de A′ (effectif ou ensemble des `f_id`).

## Spécification (calquée sur `_lasso_iv_first.ado` et `rationing_main.log`)
- **Candidats :** l'ensemble `MAIN` des auteurs, soit 419 colonnes : fractures
  (3), parts de roche (65), types de roche (65), aquifères (20), carrés des
  fractures (3), carrés des parts (65), interactions entre fractures (3),
  fractures × parts de roche (195). Colonnes constantes retirées mécaniquement.
- **Contrôles non pénalisés, retirés avant sélection :** effets fixes de SDO,
  altitude, pente. Ce sont les contrôles de A′, pour la comparabilité.
- **LASSO « rigoureux » (Belloni, Chernozhukov et Hansen ; formules de
  `rlasso`/lassopack) :**
  - objectif (1/N)‖y − Zβ‖² + (λ/N) Σ ψⱼ|βⱼ| ;
  - λ = 2c√N Φ⁻¹(1 − γ/(2p)), avec c = 1,1, γ = 0,1/log(G) et G = 304
    départs ;
  - pondérations groupées par départ : ψⱼ = √[(1/N) Σ_g (Σ_{i∈g} zᵢⱼ eᵢ)²] ;
  - résidus initiaux : MCO de y sur les 5 candidats les plus corrélés ;
    15 itérations au plus, résidus post-lasso.

  Le journal des auteurs indique « cluster-lasso, 304 clusters », d'où le
  groupement par départ.
- **Prédiction :** MCO post-lasso sur les instruments retenus et les contrôles.
- **Validation croisée :** dans chaque pli, la sélection est **refaite sur les
  seuls départs d'apprentissage**, puis le pli retiré est prédit. Si rien n'est
  retenu, la prédiction est celle des seuls contrôles. Le centrage par SDO se
  fait sur tout l'échantillon, comme dans A′.

## Règle de passage
**Gain de R² hors échantillon ≥ 0,05**, soit
R²_CV(post-lasso + contrôles) − R²_CV(contrôles seuls), avec les 10 plis de A′.
La condition 1 (part intra-SDO 0,689) est déjà établie par A′.

## Rapporté à côté du verdict (hors critère)
- Instruments retenus sur tout l'échantillon, comparés à la liste des auteurs
  (`rationing_main.log`, l. 2157). C'est un contrôle de conformité de
  l'implémentation, pas une preuve : unité, contrôles et logiciel diffèrent.
- Fréquence de sélection de chaque instrument sur les 10 plis (stabilité).
- F partiel des instruments post-lasso sur tout l'échantillon, erreurs groupées
  par départ.
- Gain avec des pondérations hétéroscédastiques non groupées.
- Gain avec un pli par SDO (borne stricte de transport).
- Gain « naïf » : sélection faite une fois sur tout l'échantillon, puis
  validation croisée à liste fixe. Il fuit par construction et sert à mesurer
  ce que la sélection sur les données retirées ajoute.

## Limites écrites d'avance
- Pas de Stata ici : `rlasso` n'est pas reproduit à l'octet près. Deux choix
  sont non vérifiés contre lassopack : la convention de γ en présence de
  groupes, et la règle d'arrêt des pondérations.
- Les parts de roche sont des moyennes spatiales locales, très marquées par la
  localisation. Le gain par plis de départs peut donc refléter la position
  autant que la géologie, d'où le pli par SDO à côté.
- Contrôles de sol absents du fichier agriculteur ; déciles de terre exclus
  (comme dans A′).

## Hors périmètre
Aucune variable de résultat, aucun second stage, aucun appariement SHRUG.

**Erratum (07/10/2026).** La liste de la l. 2157 vient de la régression de
profit pondérée, pas du premier stage publié (C4, 16 instruments). Voir
l'erratum de `memo/piste_a_prime_lasso_verdict.md`.
