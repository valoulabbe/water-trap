# Piste A′ — la géologie fine prédit-elle la profondeur ? (critère fixé avant estimation)

Rédigé le 06/10/2026, avant toute estimation. Valentine a validé la séquence
A′ → B → C et délégué le choix des plis ; le contrôle par année de forage est
rapporté à côté, hors règle.
Statut du test : **porte de faisabilité** (passe / échoue), pas un résultat.

## Pourquoi cette porte
La piste A a échoué le 24/09 (`memo/piste_a_premier_stage_verdict.md`) sur deux
points : (1) la carte GSI au 1:2M, recodée en classes, ne prédit rien hors
échantillon ; (2) au sein des districts, ses classes recoupent l'économie de
1991. A′ teste seulement l'hypothèse que (1) tient à l'échelle de la carte.
Elle utilise les instruments fins de Ryan & Sudarshan (2022) : cartes de
potentiel en eau souterraine au 1:50k, linéaments de fracture.

**Ce que la porte décide.** Passer A′ ne rouvre pas la piste A. Il faut encore
la porte B (couches fines disponibles en données publiques pour des villages
SHRUG) et la porte C (équilibre économique de 1991 à cette échelle, critère à
écrire avant). Échouer A′ rejette l'hypothèse d'échelle sur ces données ; la
piste A reste close.

## Échantillon
- `raw/nicholasryan2021/.../data/work/marginal_analysis_sample.dta`, un
  agriculteur par ligne (6 215), Rajasthan, 6 SDO.
- Gardés : `farmer_well_depth` > 0 et non manquant, bloc géologie non manquant,
  `elevation` et `slope` numériques, départ électrique (`sdo_feeder_code`, pris
  dans le fichier agriculteur × culture) connu. Attendu : environ 4 000
  agriculteurs, environ 300 départs. Arrêt si moins de 3 800.
- Profondeur du puits en pieds, telle que déclarée (le R² ne dépend pas de
  l'unité). C'est la profondeur **creusée**, un choix de l'agriculteur, pas le
  niveau de la nappe : même endogène que chez Ryan & Sudarshan.

## Spécification
profondeur ~ bloc géologie + altitude + pente + effets fixes de SDO.

- **Bloc géologie** : jeu des auteurs « fractures + roches + aquifères » sans
  interactions, soit `dist2fault_km`, `ltot_1km`, `ltot_5km`,
  `rock_type_1-65`, `rock_area_1-65`, `aquifer_type_1-20`. Colonnes constantes
  dans l'échantillon retirées mécaniquement. MCO, sans lasso ni sélection.
- **Contrôles** : `elevation`, `slope`, effets fixes de SDO. Pas de déciles de
  terre : caractéristique de l'agriculteur, pas de la surface, et
  potentiellement post-traitement.

## Règle de passage (les deux conditions)
1. **Part intra-SDO** de la variance de profondeur **≥ 25 %**.
2. **Gain de R² hors échantillon** du bloc géologie au-delà des effets fixes de
   SDO **≥ 0,05**.
   - 10 plis ; chaque départ électrique est affecté entier à un pli, au hasard
     (graine 20261006).
   - Profondeur et régresseurs centrés par SDO sur tout l'échantillon.
   - Un coefficient non identifié dans un pli compte pour zéro.
   - Gain = R²_CV(géologie + contrôles) − R²_CV(contrôles seuls).

Les seuils sont ceux de la porte de l'AP, pour que les deux résultats se
comparent. Le F partiel (Wald groupé par départ) est rapporté pour information
seulement.

**Limite connue, écrite d'avance.** Avec des plis par départ, les départs
voisins d'un départ retiré restent dans l'apprentissage. Une partie du gain
peut donc venir de la localisation plutôt que d'une géologie qui se transporte.
D'où la variante stricte ci-dessous, qui ne décide pas du verdict.

## Rapporté à côté du verdict (hors critère)
- Gain de R² avec un pli par SDO (6 plis) : borne stricte de transport.
- Gain de R² quand on ajoute des effets fixes d'année de forage
  (`depth_data.txt`) aux deux modèles, sur les agriculteurs appariés.
- Gain de R² avec la profondeur winsorisée (`farmer_well_depth_wins`).
- Gains séparés : fractures seules ; roches et aquifères seuls.

## Hors périmètre
Aucune variable de résultat, aucun second stage, aucun appariement aux villages
SHRUG, aucun lasso, aucune interaction des instruments.
