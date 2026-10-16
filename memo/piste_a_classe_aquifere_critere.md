# Piste A — la couche Bhujal porte-t-elle une classe d'aquifère utilisable ? (critère fixé avant tout chiffre)

Rédigé le 16/10/2026, avant toute lecture des valeurs des colonnes candidates
et de `aquifer_type_*`. Seuls les **schémas** ont été lus (noms de colonnes,
nombres de lignes). Script : `code/34_piste_a_classe_aquifere.R`.

Statut : **travail descriptif sur l'instrument**. Aucune variable de
fourniture publique n'est lue ni régressée. Aucune profondeur de puits non
plus : la question porte sur la couche, pas sur le premier stage.

## La question
L'instrument de Ryan & Sudarshan (JPE 2022) a trois composantes : type de
roche, fractures, et classe d'aquifère (`AQ_MAT`, 20 classes, dans les
shapefiles de bloc `HYDROGEOMORPHIC_DIVISION.shp`). On a les deux premières
(lithologie NGDR 1:50k, linéaments 1:50k). Il manque la troisième. La couche
Bhujal LGEOM contient-elle une colonne qui en tienne lieu ?

## Constat préalable (16/10) : la vérité terrain prévue n'existe pas sur disque
Le paquet de réplication (`raw/nicholasryan2021/20200932data.zip`, 875
fichiers) **ne contient aucun shapefile**. `code/maps/depth_maps.R` lit
`HYDROGEOMORPHIC_DIVISION.shp` dans un `input_path` non déposé, à côté d'un
fichier PII de localisation des agriculteurs. La jointure spatiale bloc ×
Bhujal est donc impossible.

Substitut retenu (décision de Valentine, 16/10) :
`data/work/marginal_analysis_sample.dta` (6 215 agriculteurs, Rajasthan,
6 SDO) porte `AQ_MAT` en indicatrices `aquifer_type_1..20` (sans étiquettes),
`rock_type_1..65`, et les noms `village`, `block`, `district`, mais pas de
coordonnées. On géolocalise donc **au village**, par les noms SHRUG.

## Candidats
Colonnes brutes, chacune évaluée seule : `GWMP_CODE`, `GWMAP_CODE`,
`Descr_L1..L5`, `DESCR1..5`, `DESCR_L1_1..DESCR_L5_1`, `Landform`,
`PHYSIOGRAP`, `geom_landf`, `GEOM_UNIT`, `GEOM_CODE`.

Familles fusionnées (LGEOM est une union de couches d'État non harmonisée :
même concept sous plusieurs noms). Première valeur non manquante, dans
l'ordre indiqué :

| Famille | Membres, par ordre de priorité |
| --- | --- |
| `GWP` | `GWMP_CODE`, `GWMAP_CODE` |
| `DL1` … `DL5` | `Descr_Lk`, `DESCR_Lk_1`, `DESCRk` (k = 1..5) |
| `LANDF` | `Landform`, `geom_landf` |
| `PHYS` | `PHYSIOGRAP`, `Physiograp_1` |
| `GEOMC` | `GEOM_CODE`, `Geom_Code_1` |

`GEOM_UNIT` n'est pas fusionné avec `GEOM_CODE` : l'un est probablement un
libellé, l'autre un code, et les mélanger créerait de fausses classes. Quand
deux membres d'une famille sont renseignés et diffèrent sur un même
polygone, le taux de conflit est rapporté.

**Normalisation des valeurs** (toutes les colonnes) : majuscules, espaces
réduits et rognés. **Manquant** = NA, chaîne vide, ou l'un de `0`, `-`,
`NA`, `N/A`, `NULL`, `<NULL>`, `NIL`, `NONE` après normalisation.

## Périmètre
C1–C3 sont évalués **séparément dans chacun de trois groupes d'États**, ceux de
l'arbitrage de périmètre ouvert : **AP non divisé** (`sname` contenant ANDHRA
ou TELANGANA), **Rajasthan**, **Uttar Pradesh** (UTTAR PRADESH, sans
Uttarakhand). Le script s'arrête si l'un des trois groupes ne compte aucun
polygone. Les autres États sont rapportés à titre descriptif (pondération par
polygones seulement), hors critère.

Polygones dupliqués à l'identique (géométrie identique octet pour octet, cf.
constat du 07/10 sur NGDR) : retirés avant calcul dans les trois groupes, avec
le nombre retiré. Aires en LAEA centrée sur l'Inde, après `st_make_valid`.

## Règle (par candidat × groupe d'États)

**C1 — couverture.** Part des polygones où le candidat est renseigné
**≥ 0,80**, **et** part de la surface **≥ 0,80**. Les deux sont exigées : une
couverture par polygones pourrait tenir à de petits éclats.

**C2 — cardinalité.** Une *classe effective* porte au moins 0,5 % de la
surface renseignée du groupe. Il faut **entre 5 et 60 classes effectives**,
**et** que celles-ci couvrent **≥ 95 %** de la surface renseignée. La seconde
condition écarte le texte libre et les identifiants, dont la masse se perd en
longue traîne. Le nombre brut de valeurs distinctes est rapporté à côté.

**C3 — discrimination à roche donnée (condition qui tranche).** Roche =
`lithologic` de la lithologie NGDR 1:50k (normalisé comme ci-dessus) au point
intérieur (`st_point_on_surface`) de chaque polygone Bhujal : c'est la
composante roche que notre instrument utilise réellement. Sur les polygones
où le candidat et la roche sont renseignés, pondéré par la surface :

  part résiduelle **R = H(candidat | roche) / H(candidat)** (entropies de
  Shannon).

R = 0 : le candidat est une fonction déterministe de la roche et n'ajoute
rien. **C3 tenue si R ≥ 0,25.** Rapportés à côté, sans valeur de décision :
la pureté moyenne (part modale du candidat au sein de chaque roche), R avec la
roche interne à Bhujal (`Rock_type`, `Rock_Type_1`, `ROCK_TYPE_2`, fusionnés
dans cet ordre), et R conditionnel à roche × district.

Un candidat est **utilisable dans un groupe** s'il tient C1, C2 et C3 dans ce
groupe.

## Validation V (Rajasthan seulement)

**Appariement, sur les noms uniquement** (aucune valeur `aquifer_type_*` lue à
cette étape) :
1. districts : nom normalisé (majuscules, lettres seules) de Ryan = nom de
   district SHRUG au Rajasthan. Un district sans correspondance exacte arrête
   le script avec la liste ; une table de correspondance de noms est alors
   ajoutée au script et rapportée dans le verdict.
2. villages, dans le district : (a) égalité exacte des noms normalisés ;
   (b) sinon, distance de Levenshtein ≤ 1, noms de 5 lettres ou plus, meilleur
   candidat unique. Plusieurs shrid possibles : on garde celui dont la
   sous-division SHRUG porte le nom normalisé du `block` de Ryan s'il est
   unique, sinon le village est écarté comme ambigu.

**Plancher de faisabilité :** au moins **60 %** des agriculteurs à classe
d'aquifère connue appariés à un shrid unique, **et au moins 30 villages**.
Sinon V = **INFAISABLE** : ni réussite ni échec, et on remonte au PI.

**Classe d'aquifère de l'agriculteur :** l'indicatrice `aquifer_type_j` égale
à 1. Arrêt si une ligne en porte plus d'une. Aucune à 1 : manquant.

**Code du village :** pour chaque candidat, la valeur qui couvre la plus
grande surface du polygone shrid (manquant si la surface non renseignée
dépasse la moitié du village). Même règle pour la roche NGDR du village.

**Mesures au niveau agriculteur, toutes en « un village laissé de côté »** :
la classe prédite pour un village est la classe modale des agriculteurs des
*autres* villages qui portent le même code, ou la classe modale globale des
autres villages si aucun ne le porte.
- `K0` : exactitude de la classe modale globale.
- `Plafond` : Σ_v max_j n_vj / N, la meilleure exactitude possible pour un
  prédicteur au village (AQ_MAT varie entre agriculteurs d'un même village).
- `A_code`, `A_roche`, `A_code×roche` : exactitudes avec le code, la roche
  NGDR, et la cellule code × roche.
- Ratio de récupération **ρ = (A_code − K0) / (Plafond − K0)**.

**V réussie si ρ ≥ 0,50 et A_code×roche − A_roche ≥ 0,05.** La seconde
condition est le pendant de C3 sur la vérité terrain : le code doit apporter
de l'information sur AQ_MAT au-delà de la roche. **Zone limite :** ρ dans
[0,40 ; 0,50) ou gain dans [0,03 ; 0,05) ; elle est rapportée comme telle.

Hors critère : V(Cramér) code × classe, et, sur les seules données de Ryan,
R(AQ_MAT | rock_type), pour savoir si la troisième composante varie à roche
donnée chez eux.

**Portée de V.** LGEOM n'est pas harmonisée : un code validé au Rajasthan ne
l'est pas dans le schéma de l'AP ou de l'UP. Une réussite de V ne se transporte
pas hors du Rajasthan.

## Verdict, par candidat

| Issue | Condition |
| --- | --- |
| **OUI, validé** | utilisable au Rajasthan et V réussie |
| **OUI, non validé** | utilisable dans au moins un groupe, et V infaisable ou hors Rajasthan |
| **NON — pas un aquifère** | utilisable, mais V échoue au Rajasthan |
| **NON** | utilisable dans aucun groupe |

Verdict global : **OUI** s'il existe au moins un candidat « OUI, validé » ou
« OUI, non validé », en nommant les groupes d'États. Sinon **NON**. Un candidat
en zone limite rend le verdict **LIMITE**, sans arrondi.

## Ce que ce critère ne décide pas
- **L'exclusion.** Les cartes de prospects croisent lithologie et forme de
  relief. Si le candidat varie à roche donnée par la forme de relief (vallée,
  pédiplaine…), cette variation touche la topographie et donc peut-être
  l'économie locale (constat du 23/09 sur l'AP). C'est à tester plus tard,
  avec un critère écrit avant.
- **Le premier stage.** Aucune profondeur n'est lue ici.
