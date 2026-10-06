# Piste A′-L — verdict de la porte (sélection LASSO des auteurs, Rajasthan)

06/10/2026. Critère : `memo/piste_a_prime_lasso_critere.md`. Chiffres :
`output/logs/30_piste_a_prime_lasso.log`, `output/tables/30_*.csv`.

**Antériorité du critère.** Le critère n'a pas été commité avant l'exécution.
Son dernier enregistrement date de 17:12:30, le script de 17:13:57, et
l'exécution a commencé à 17:15:18. Tous deux sont commités ensemble ensuite,
inchangés.

## Verdict : PASSE

| Condition | Seuil | Obtenu | |
| --- | --- | --- | --- |
| Gain de R² hors échantillon, sélection refaite par pli (10 plis de départs) | ≥ 0,05 | **0,109** | remplie |

Avec la sélection des instruments telle que les auteurs la pratiquent, la
géologie fine prédit la profondeur du puits hors échantillon, au sein des SDO.
Le R² intra-SDO hors échantillon vaut 0,109 avec la géologie, contre 0,000
avec l'altitude et la pente seules.

## Magnitudes

- **Échantillon :** 4 006 agriculteurs, 304 départs, 6 SDO. Échantillon et plis
  identiques à A′ (vérifiés). 341 des 419 candidats ne sont pas constants.
- **Sélection :** de 9 à 13 instruments selon le pli. Le noyau est stable :
  `rock_area_6`, `rock_area2_10`, `aquifer_type_4` et `dist2fault_area1116`
  sont retenus dans les 10 plis, `rock_area_14` dans 9, `rock_area_4` et
  `ltot1km_area1119` dans 8.
- **Sur tout l'échantillon :**
  - 10 instruments retenus ;
  - F partiel post-lasso de 28,5, erreurs groupées par départ (q = 10) ;
  - 5 instruments en commun avec les 13 des auteurs (`rock_area_6`,
    `rock_area2_4`, `rock_area2_10`, `ltot5km_area1115`, `aquifer_type_4`).
- **Variantes (hors critère) :**

| Variante | Gain de R² hors échantillon |
| --- | --- |
| Principal (rappel) | 0,109 |
| Pondérations hétéroscédastiques | 0,115 |
| Liste des auteurs, fixe | 0,118 |
| Liste fixe choisie sur tout l'échantillon (fuit) | 0,112 |
| **Un pli par SDO (6 plis)** | **0,026** |

## Lecture

1. **L'échec de A′ venait de la méthode, pas de l'information.** Les mêmes
   variables passent de −4,08 en MCO à +0,109 une fois régularisées. Le signal
   tient à une dizaine de parts de roche et d'interactions fractures × roche.
   Les fractures seules ne prédisent rien (−0,002 dans A′) : elles ne comptent
   qu'à travers la roche qui les porte.
2. **Le résultat ne dépend pas des détails de l'implémentation.** Ni les
   pondérations (0,115), ni notre liste plutôt que celle des auteurs (0,118),
   ni la fuite de sélection (0,112, contre 0,109 avec la sélection refaite par
   pli) ne déplacent le gain. Que seuls 5 instruments sur 13 soient communs
   s'explique par l'unité et les contrôles : les auteurs travaillent par
   agriculteur × culture, avec sol et déciles de terre. Cela ne change pas la
   conclusion.
3. **Réserve principale : le transport est faible.** Une relation apprise sur 5
   SDO ne prédit l'intra-SDO du sixième qu'à 0,026, sous le seuil. C'était la
   limite écrite d'avance. Les parts de roche sont des moyennes spatiales
   locales, et les départs voisins d'un départ retiré restent dans
   l'apprentissage. Une partie du 0,109 peut donc refléter la position plutôt
   qu'une loi géologique générale. Pour nous, la conséquence est précise : le
   premier stage devra être **estimé dans chaque région d'étude**, sur ses
   propres puits. On ne pourra pas transporter des coefficients du Rajasthan.
4. **Ce qui est mesuré est la profondeur creusée**, choix de l'agriculteur
   (vers 2012, puits forés 1990–2016), et non le niveau de la nappe. C'est la
   variable que la piste A doit instrumenter (le coût du substitut privé), mais
   le premier stage SHRUG aurait une autre variable dépendante.

**Ce qu'on peut dire à Jack :** avec leur méthode de sélection, l'instrument
de Ryan & Sudarshan tient hors échantillon sur leur terrain (gain 0,11 au sein
des SDO, F = 28,5), mais il se transporte mal d'une sous-division à l'autre
(0,03). La finesse de la carte compte, mais la méthode aussi : MCO sur le même
bloc donne −4,08.

## Recommandation

A′-L lève l'objection de pertinence au niveau fin. Ce n'est pas une
réouverture de la piste A ; deux portes restent :
- **Porte B, données (bloquante, à faire d'abord) :** obtenir en données
  publiques les couches fines sur lesquelles reposent ces instruments, pour une
  région couvrant des villages SHRUG. Il s'agit des cartes de potentiel en eau
  souterraine NRSC/RGNDWM au 1:50k (roche, aquifère) et des linéaments GSI. Le
  paquet de réplication ne les contient pas. Liste de téléchargement pour
  Valentine ; si elles ne sont pas publiques, escalade vers le PI.
- **Porte C, exclusion :** écrire avant tout calcul le critère d'équilibre des
  caractéristiques de 1991 (population, alphabétisation, part ST, distance à
  la ville) sur la profondeur prédite à l'échelle fine, avec effets fixes de
  sous-district. C'est là que la piste A a échoué dans l'AP.
- Vu le point 3, le premier stage de la région retenue devra repasser une
  porte du même type (sélection refaite par pli, seuil 0,05), sur ses propres
  puits.
