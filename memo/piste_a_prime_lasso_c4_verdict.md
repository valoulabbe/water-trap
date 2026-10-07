# Piste A′-L-C4 — verdict de la porte (premier stage publié C4, hors échantillon)

07/10/2026. Critère : `memo/piste_a_prime_lasso_c4_critere.md`, commit 86d2bc3,
antérieur à l'exécution (11:52). Chiffres :
`output/logs/31_piste_a_prime_lasso_c4.log`, `output/tables/31_*.csv`.

## Verdict : PASSE

| Condition | Seuil | Obtenu | |
| --- | --- | --- | --- |
| Gain de R² hors échantillon, sélection refaite par pli (10 plis de départs, lignes agriculteur × culture) | ≥ 0,05 | **0,072** | remplie |

Sur l'échantillon et avec les contrôles du premier stage publié, la géologie
fine prédit la profondeur du puits hors échantillon, au sein des SDO. Le R²
vaut 0,062 avec la géologie contre −0,010 avec les seuls contrôles. La marge
au-dessus du seuil est plus mince que dans A′-L (0,109).

## La reproduction est exacte
- Échantillon : **8 973 lignes, 3 999 agriculteurs, 28 contrôles**, identiques
  au log des auteurs. Validation faite avant toute estimation.
- **F i.i.d. de la liste publiée de 16 instruments : 86,81, pour 86,82
  publié.** Données, échantillon et contrôles reproduisent donc C4. Le même F
  groupé par départ ne vaut que 18,3 ; le log des auteurs ne l'affiche pas.

## Magnitudes
- **Sélection :** 9 à 11 instruments par pli, sauf un pli à 4. Noyau stable,
  retenu dans au moins 8 plis sur 10 : `dist2fault_area116`, `aquifer_type_4`,
  `ltot1km_area1119`, `rock_area2_10`, `dist2fault_area1116`, `rock_area_6`,
  `rock_area_15`, `rock_area_14`.
- **Sur tout l'échantillon :** 9 instruments retenus, dont **6 sur les 16
  publiés**. C'est sous le seuil de signalement de 8 fixé d'avance. Notre
  `rlasso` retient moins d'instruments que lassopack sur le même échantillon :
  la pénalité ou les itérations diffèrent. F de notre sélection : 114,5 en
  i.i.d., 27,1 groupé par départ.
- **Variantes (hors critère) :**

| Variante | Gain de R² hors échantillon |
| --- | --- |
| Principal (rappel) | 0,072 |
| R² par agriculteur | 0,089 |
| Liste publiée de 16, fixe | 0,120 |
| Sans déciles de terre | 0,074 |
| **Un pli par SDO (6 plis)** | **−0,004** |

## Lecture
1. **Le premier stage publié tient hors échantillon, à l'échelle locale.** Le
   gain survit au passage à leur fichier et à leurs contrôles (0,072), et il
   est plus élevé compté par agriculteur (0,089). Les déciles de terre n'y
   changent rien (0,074).
2. **Notre implémentation est conservatrice.** Elle retient moins
   d'instruments que lassopack (9 contre 16). La liste publiée, appliquée
   telle quelle, fait mieux : 0,120. Ce chiffre fuit un peu, puisque la liste a
   été choisie sur tout l'échantillon, mais dans A′-L cette fuite ne pesait que
   0,003. L'écart d'implémentation joue donc **contre** le passage, pas pour.
3. **Aucun transport entre SDO : −0,004.** Dans A′-L, ce chiffre valait 0,026 ;
   avec les contrôles des auteurs, il tombe à zéro. Ce que la géologie prédit
   est appris dans le voisinage : les départs voisins du départ retiré restent
   dans l'apprentissage. Cela ne se transporte pas à 50–100 km. On ne peut pas
   encore trancher entre une géologie qui agit localement et une géologie qui
   repère la position.
4. **Ce que le point 3 implique pour la piste A :**
   - **Porte B :** le premier stage devra être estimé dans la région d'étude
     elle-même, sur des puits assez denses pour que chaque village ait des
     voisins dans l'apprentissage.
   - **Porte C :** si la géologie fine repère la position, elle repère aussi
     ce qui suit la position (éloignement, collines, part ST). L'équilibre des
     caractéristiques de 1991 doit donc se tester avec des effets fixes aussi
     fins que l'échelle à laquelle l'instrument varie (sous-district au
     moins).

**Ce qu'on peut dire à Jack :**
- Nous reproduisons exactement le premier stage publié de Ryan & Sudarshan
  (même échantillon, F = 86,8).
- En validation croisée par départ, il prédit la profondeur hors échantillon
  (gain de R² de 0,07, 0,12 avec leur liste d'instruments).
- La relation ne se transporte pas d'une sous-division à l'autre (gain nul).
- Le F publié est i.i.d. ; groupé par départ, il tombe à 18.

## Recommandation
- La pertinence au niveau fin est acquise sur leur terrain, sous les deux
  spécifications (A′-L et C4). Il n'y a plus de variante de pertinence à faire
  sur ces données.
- **Prochaine étape : la porte B, données.** Il faut obtenir les couches fines
  (cartes NRSC/RGNDWM au 1:50k, linéaments GSI) pour une région couverte par
  SHRUG et par des puits CGWB assez denses. C'est à mettre sur la liste de
  téléchargement de Valentine ; si ces couches ne sont pas publiques, escalade
  vers le PI.
- **La porte C** devra être écrite avec des effets fixes de sous-district au
  minimum, vu le point 3.
- Signaler au PI la différence de F (i.i.d. 86,8, groupé 18,3) si l'article de
  Ryan & Sudarshan est cité comme précédent de force de l'instrument.
