# Piste A — premier stage de l'AP avec les couches géologiques fines (critère fixé avant estimation)

Rédigé le 07/10/2026, avant le téléchargement des couches fines et avant toute
construction de variable géologique aux puits. Fait suite à
`memo/piste_a_porte_b_donnees.md`. Valentine a demandé de traiter l'AP et
d'« essayer les instruments pertinents ». Pour que ces essais ne deviennent pas
une recherche de spécification :
- tous les blocs d'instruments sont fixés ici ;
- leur codage suit une règle mécanique, sans recodage à la main ;
- **un seul bloc décide du verdict** ;
- les autres sont rapportés à côté.

Statut : **porte de faisabilité** (passe / échoue). Code :
`code/32_piste_a_ap_couches_fines.R` (variables aux puits) et
`code/33_piste_a_ap_lasso.py` (porte).

## Ce que la porte décide
- **Passe :** à l'échelle fine, la géologie prédit la profondeur de la nappe
  aux puits CGWB de l'AP hors échantillon. L'échec du 24/09 tenait à la carte
  au 1:2M. On passe à la porte C (équilibre des caractéristiques de 1991,
  effets fixes de sous-district), dont le critère sera écrit avant tout calcul.
- **Échoue :** même avec les couches fines, le réseau CGWB, espacé de 12 à
  16 km, ne permet pas d'apprendre la relation. La piste A reste close pour
  l'AP.

## Échantillon : identique à la porte du 24/09
Échantillon du script 10, sans changement :
- puits CGWB de l'AP non divisé (`pc11_state_id` 28) ;
- profondeur = moyenne des relevés de mai 1996–2000 ;
- socle seulement selon `code/ref/hydrogeo_ap_2m.csv`, khondalite exclue ;
- contrôles complets ;
- soit **825 puits**. Arrêt si l'effectif diffère.

## Contrôles : identiques au script 10
Altitude, pente moyenne et altitude relative (CartoDEM, fenêtre de ±0,009°),
pH et carbone organique du sol (SLUSI, médiane à 5 km, au moins 3 analyses),
effets fixes de district. Les 104 altitudes négatives sont gardées telles
quelles, comme le 24/09.

## Couches et règles de codage (mécaniques, fixées ici)
Sources : `ramSeraph/indian_land_features`, documentées dans `raw/README.md`.
Calculs de surface et de distance en LAEA (convention CLAUDE.md), géométries
réparées par `st_make_valid` dans ce système.

- **Lithologie GSI au 1:50k** (`NGDR_Lithology_50k.parquet`) :
  - champ `lithologic`, normalisé seulement en minuscules, espaces réduits et
    rognés ;
  - une classe est gardée si **au moins 5 puits** de l'échantillon y tombent ;
    les autres sont regroupées en « autres ».
- **Linéaments au 1:50k** (Bhuvan 2005-06, `Bhuvan_Lineament_50k_0506.parquet`) :
  tous types confondus.
- **Linéaments au 1:250k** (NGDR) : variante seulement.
- **Groundwater Prospects** (`LGEOM`) : on prend le champ d'unité qui est le
  plus souvent renseigné parmi les polygones de l'AP. Ce choix est mécanique et
  noté dans le log. Même seuil de 5 puits par classe.

Variables construites à chaque puits, sur le modèle de Ryan & Sudarshan :
- **classe** du polygone qui contient le puits (indicatrices) ;
- **parts de surface** de chaque classe gardée dans un rayon de **1 km** et de
  **5 km** ;
- **fractures** :
  - distance au linéament le plus proche (km) ;
  - longueur totale de linéaments dans un rayon de 1 km et de 5 km ;
  - carrés de ces trois mesures ;
  - leurs produits avec les parts à 1 km (interactions de premier ordre).

## Blocs d'instruments
| Bloc | Contenu | Rôle |
| --- | --- | --- |
| **L (décide)** | Lithologie GSI 1:50k (indicatrices, parts à 1 et 5 km, carrés des parts) + fractures Bhuvan 1:50k (3 mesures, carrés, interactions avec les parts à 1 km) | Verdict |
| P | Prospects : indicatrices et parts de l'unité retenue, à 1 et 5 km | À côté |
| L+P | Union | À côté |
| L-250k | Bloc L avec les linéaments NGDR au 1:250k | À côté |
| Lithologie seule | Partie lithologie de L | À côté |
| Fractures seules | Partie fractures de L | À côté |

**Pourquoi L décide.** La lithologie GSI et les linéaments sont des cartes
géologiques. Les Groundwater Prospects, eux, ont été faits pour localiser les
sources **publiques** d'eau potable. Leur effet passerait aussi par le coût
public, ce qui est contraire à la règle de CLAUDE.md.

## Estimation
- **LASSO rigoureux** (`rlasso` de `code/30_piste_a_prime_lasso.py`), sur
  le modèle de Ryan & Sudarshan :
  - pondérations hétéroscédastiques, l'unité étant le puits ;
  - contrôles et effets fixes de district non pénalisés, retirés avant
    sélection ;
  - MCO post-lasso pour prédire.
- **Validation croisée :**
  - 10 plis formés de **cellules de 20 km** entières (grille LAEA), affectées
    au hasard (graine 20261007) ;
  - la sélection est refaite dans chaque pli ;
  - centrage par district sur tout l'échantillon.
- **Pourquoi des cellules de 20 km :** l'usage visé est de prédire la
  profondeur d'un village à partir des puits du même district, qui sont à une
  dizaine de km. Avec des cellules de 20 km, aucun puits retiré n'a de voisin
  très proche dans l'apprentissage.

## Règle de passage
**Gain de R² hors échantillon du bloc L ≥ 0,05**, soit
R²_CV(post-lasso + contrôles) − R²_CV(contrôles seuls). C'est le seuil de la
porte du 24/09. La condition 1 (part intra-district de 0,849) est déjà établie
et reste inchangée.

## Rapporté à côté du verdict (hors critère)
- Les autres blocs (P, L+P, L-250k, lithologie seule, fractures seules).
- Bloc L avec un **pli par district**, la règle du 24/09 : borne stricte de
  transport. Après A′-L-C4, on s'attend à ce qu'elle soit plus basse.
- Bloc L avec des plis de **puits au hasard**.
- Bloc L avec des pondérations groupées par district.
- Instruments retenus sur tout l'échantillon, fréquence de sélection par pli,
  F partiel post-lasso (i.i.d. et groupé par district).

## Hors périmètre
Aucune variable de résultat, aucun second stage, aucun village SHRUG. La porte
C a son propre critère, à écrire avant.
