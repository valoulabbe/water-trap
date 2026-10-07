# Piste A — verdict du premier stage de l'AP avec les couches fines

07/10/2026. Critère : `memo/piste_a_ap_fine_critere.md`, commit 9b7eccc,
antérieur à toute construction. Scripts : `code/32_piste_a_ap_couches_fines.R`
(variables aux puits) et `code/33_piste_a_ap_lasso.py` (porte). Chiffres :
`output/logs/32_*.log`, `output/logs/33_*.log`, `output/tables/33_*.csv`.
Exécution valide : 15:16:57, sur la table du 32 terminée à 15:16:47, avec
toutes les validations passées.

## Verdict : ÉCHOUE

| Condition | Seuil | Obtenu | |
| --- | --- | --- | --- |
| Part intra-district de la variance de profondeur (établie le 24/09) | ≥ 0,25 | 0,849 | remplie |
| Gain de R² hors échantillon du bloc L (lithologie GSI 1:50k + linéaments 1:50k), 10 plis de cellules de 20 km | ≥ 0,05 | **0,000** | **non remplie** |

Même avec les couches fines, la géologie ne prédit pas la profondeur de la
nappe aux puits CGWB de l'AP hors échantillon. **Le LASSO ne retient aucun
instrument**, ni dans les 10 plis ni sur l'échantillon entier. La prédiction
se réduit donc à celle des contrôles.

## Magnitudes

- **Échantillon :** 825 puits de socle, 23 districts, 448 cellules de 20 km.
  Identique à la porte du 24/09.
- **Bloc L :** 214 colonnes non constantes :
  - 26 classes de lithologie gardées sur 57 présentes aux puits (au moins 5
    puits chacune) ;
  - parts à 1 et 5 km et leurs carrés ;
  - 3 mesures de fractures, leurs carrés, et leurs interactions avec les parts
    à 1 km.
- **Linéaments au 1:50k autour des puits :** distance médiane au plus proche
  1,2 km ; longueur médiane à 5 km 14,3 km. La couche n'est pas vide autour
  des puits.
- **R² hors échantillon intra-district :** 0,038 avec les seuls contrôles,
  0,038 avec la géologie.

| Variante (hors critère) | Gain de R² hors échantillon |
| --- | --- |
| Bloc L, principal (rappel) | 0,000 |
| Bloc P (Groundwater Prospects) | sans objet (voir ci-dessous) |
| Bloc L+P | 0,000 |
| Bloc L avec linéaments au 1:250k | −0,000 |
| Lithologie seule | 0,000 |
| Fractures seules | 0,000 |
| Bloc L, un pli par district (règle du 24/09) | 0,000 |
| Bloc L, plis de puits au hasard | 0,000 |
| Bloc L, pondérations groupées par district | −0,003 |

**Bloc P sans objet.** Selon la règle fixée d'avance, le champ des prospects
le plus souvent renseigné dans l'emprise est `Geom_Code_1`. Il ne l'est que
pour 8,6 % des polygones, et les 825 puits tombent tous dans la classe « non
renseigné ». Le bloc ne distingue donc aucun puits. Pour l'AP, la couche des
prospects republiée n'est pas exploitable telle quelle.

## Lecture
1. **L'hypothèse de granularité est rejetée sur l'AP.** Le 24/09 au 1:2M, le
   gain était de −0,006 ; avec la lithologie au 1:50k et les linéaments au
   1:50k, il est de 0,000. Passer à une carte 40 fois plus fine ne change rien.
2. **La contrainte est la densité des puits, pas la carte.** Ce verdict est
   cohérent avec A′-L-C4 :
   - chez Ryan & Sudarshan, la relation s'apprend entre agriculteurs voisins
     (environ 13 par départ électrique) et ne se transporte pas d'une
     sous-division à l'autre (−0,004) ;
   - ici, les puits CGWB sont espacés d'environ 16 km. Même avec des plis de
     puits au hasard, qui laissent les voisins dans l'apprentissage, le gain
     est nul.
3. **Ce n'est pas un défaut de mise en œuvre détectable.**
   - La même fonction `rlasso` retrouve les instruments sur données simulées
     et passe A′-L et A′-L-C4.
   - Les variables construites ont été validées : classe unique par puits,
     somme des parts égale à 1 au plus, couches dédoublonnées.
   - Le LASSO rigoureux est prudent avec 825 observations. Mais même les
     fractures seules (6 colonnes, pénalité faible) ne retiennent rien.
4. **Incident de procédure, pour mémoire :**
   - Une exécution du script 33 à 12:41 a tourné sur une table périmée, où les
     parts étaient comptées 11 fois. Sa sortie a été vue (gain 0,000, aucune
     sélection).
   - Le code a été corrigé ensuite : dédoublonnage, superpositions,
     extraction des surfaces, bloc dégénéré, contrôle de fraîcheur. Ces
     corrections portent sur la construction des données et ne pouvaient pas
     orienter le résultat. Les parts multipliées par une constante ne changent
     ni la sélection ni les prédictions, et la sortie valide est identique.

## Recommandation
- **La piste A est close pour l'AP**, au 1:2M comme au 1:50k. La porte C
  (équilibre des caractéristiques de 1991) est sans objet.
- **À escalader au PI**, comme le prévoit CLAUDE.md (premier stage trop
  faible). La question qui reste n'est pas la carte, mais une **mesure de
  profondeur assez dense** pour apprendre une relation locale. Les puits des
  départements d'État des eaux souterraines, bien plus denses que le réseau
  CGWB, pourraient l'être, mais leur accès public n'est pas établi. Ce serait
  une nouvelle variante, à discuter avec le PI et à cadrer par un critère
  avant tout travail.
- Un autre État de socle (Karnataka, Tamil Nadu) aurait la même densité de
  puits CGWB (12–13 km d'espacement). Sans source plus dense, rien n'indique
  qu'il ferait mieux. Le tester sans raison nouvelle serait de la recherche
  de spécification.
