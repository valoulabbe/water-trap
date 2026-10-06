# Piste A′ — verdict de la porte (géologie fine, Rajasthan)

06/10/2026. Critère : `memo/piste_a_prime_geologie_fine_critere.md` (commit
ca37974, 17:03:50, antérieur à l'exécution de 17:04). Chiffres :
`output/logs/29_piste_a_prime_geologie_fine.log`, `output/tables/29_*.csv`.

## Verdict : ÉCHOUE

| Condition | Seuil | Obtenu | |
| --- | --- | --- | --- |
| 1. Part intra-SDO de la variance de profondeur | ≥ 0,25 | **0,689** | remplie |
| 2. Gain de R² hors échantillon du bloc géologie (10 plis de départs) | ≥ 0,05 | **−4,08** | **non remplie** |

Au sens du critère, la porte échoue. **Ce verdict porte sur notre
spécification (MCO sur tout le bloc), pas sur l'instrument de Ryan &
Sudarshan.** La lecture ci-dessous l'explique.

## Magnitudes

- **Échantillon :** 4 006 agriculteurs, 304 départs, 6 SDO, 118 colonnes de
  géologie non constantes. Profondeur moyenne de 62 pieds (Dug) à 382 pieds
  (Kotputli).
- **R² hors échantillon :** −0,000 avec les seuls contrôles, −4,08 avec la
  géologie. Dans l'échantillon, le R² intra passe de 0,003 à 0,196. F partiel
  non calculable : la matrice de variance est singulière, 4 colonnes
  colinéaires.
- **Hors critère :**

| Variante | N | Gain de R² hors échantillon |
| --- | --- | --- |
| Un pli par SDO | 4 006 | −42,1 |
| Profondeur winsorisée | 4 006 | −4,27 |
| **Fractures seules (3 variables)** | 4 006 | **−0,002** |
| Roches et aquifères seuls | 4 006 | −5,29 |
| Échantillon apparié à l'année de forage | 2 799 | −0,24 |
| Avec effets fixes d'année de forage | 2 799 | −0,18 |

## Lecture

- **−4,08 mesure une instabilité, pas la géologie.** Un R² hors échantillon
  aussi négatif signifie que les prédictions sur les départs retirés explosent,
  bien au-delà d'un simple surajustement. Les MCO sans pénalité estiment 118
  colonnes, dont beaucoup sont rares (une roche présente sous quelques départs)
  ou quasi colinéaires (indicatrice de roche et part de la même roche). Elles
  reçoivent des coefficients énormes, que rien ne discipline hors de leur
  support. Le −42 du pli par SDO va dans le même sens.
- **Ce n'est pas la méthode des auteurs.** Ryan & Sudarshan sélectionnent
  leurs instruments par post-double-sélection LASSO, pénalité groupée par
  départ, parmi 419 candidats (ce bloc plus carrés et interactions). Ils en
  gardent environ 13, surtout des parts de roche continues (`rock_area_4`,
  `_6`, `_15`…) et leurs interactions avec les fractures
  (`rationing_main.log`, l. 1944 et 2157). Notre critère a écarté le lasso
  pour éviter une recherche de spécification. Il a donc testé une variante
  que les auteurs n'utilisent pas.
- **L'énoncé propre, à ce stade : fractures seules, gain −0,002.** Trois
  variables continues ne peuvent pas surajuster, et elles n'apportent rien
  hors échantillon au-delà des effets fixes de SDO, de l'altitude et de la
  pente. À rapprocher de la colonne « Fractures » de leur tableau C4 (2SLS,
  F = 137 dans l'échantillon), sans conclure, car l'unité (agriculteur ×
  culture), les contrôles (déciles de terre, sol) et la nature du test
  diffèrent.
- **Ce qu'on peut dire à Jack :** notre implémentation ne retrouve pas de
  premier stage hors échantillon. On ne peut pas dire que leur instrument ne
  tient pas tant que la sélection LASSO n'a pas été reproduite.

## Suite

Une variante LASSO conforme au code des auteurs, avec un critère écrit avant
exécution : `memo/piste_a_prime_lasso_critere.md`. Les portes B et C restent
sans objet tant qu'aucune version de A′ ne passe.
