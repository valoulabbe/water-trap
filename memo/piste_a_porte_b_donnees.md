# Piste A — porte B : inventaire des données (couches fines, puits)

07/10/2026. Travail descriptif seulement : aucune estimation, aucune variable
de résultat. Sources vérifiées une à une, sur disque ou par lecture à distance
du pied des fichiers Parquet (nombre de lignes, colonnes, emprise), sans
téléchargement.

## 1. Ce qu'on a déjà sur disque (vérifié dans `raw/` et `build/`)

| Donnée | Emplacement | Utile pour la piste A ? |
| --- | --- | --- |
| Géologie GSI au 1:2M (stratigraphique) | `raw/geology/ngdr/` | Oui, mais trop grossière : c'est l'échec de l'AP |
| Puits CGWB, 28 076, mai 1996 – janv. 2017 | `raw/cgwb/`, `build/cgwb_*` | Oui : la profondeur de la **nappe**, la bonne variable pour nous |
| CartoDEM 30 m | `raw/cartodem/`, **34 tuiles seulement** (socle de l'AP) | Oui, pour l'AP uniquement |
| Sol SLUSI (Soil Health Cards), Inde entière | `raw/slusi/` | Contrôles |
| SHRUG : polygones des shrid, PCA et VD 1991/2001/2011, clés avec `pc11_subdistrict_id` | `raw/shrug/` | Résultats, et effets fixes de sous-district pour la porte C |
| Sekhri (2014) | `raw/sekhri/` | Non : panel district × année (`dmaq1-4`, `alt`), trop grossier |
| Ryan & Sudarshan (2022) | `raw/nicholasryan2021/` | Non pour la suite : ni coordonnées, ni cartes sources |

**Absents, contrairement à ce que coche `docs/ROADMAP.md` (« [x] Récupérer les
couches publiques : aquifères principaux CGWB, lithologie GSI/Bhukosh ; GLiM et
WHYMAP en secours ») :** aucune couche des aquifères CGWB (India-WRIS ne répond
pas, script 09), aucune lithologie Bhukosh, ni GLiM, ni WHYMAP. Sur le disque,
la seule géologie est la carte au 1:2M.

Autres écarts relevés dans `raw/` :
- `raw/topalova2010/` n'a pas d'entrée dans `raw/README.md` ;
- `raw/comtrade/` et `raw/dhs/` ont leurs propres fichiers de provenance
  (`SHA256SUMS.txt`, `README.md`), sans renvoi depuis le README principal.

## 2. Ce qui existe en accès public, non téléchargé

Toutes ces couches viennent du même republieur que notre carte au 1:2M
(`github.com/ramSeraph/indian_land_features`) :
- licence annoncée « CC0 1.0, attribuer DataMeet et la source
  gouvernementale » ;
- même rangement « not-so-open » ;
- GeoParquet, lisible avec `arrow` comme le 1:2M ;
- serveur joignable depuis cette machine (pieds de fichiers lus le 07/10).

| Couche | Fichier (release) | Taille | Contenu vérifié |
| --- | --- | --- | --- |
| **Groundwater Prospects, lithologie × géomorphologie** (NRSC/RGNDWM, 1:50k), la source de Ryan & Sudarshan | `Bhuvan_Groundwater_Prospects_LGEOM.00/.01.parquet` (`groundwater-prospects`) | 1 707 + 868 Mo | 408 657 polygones dans la partie .00 (emprise ouest 70,9–81,6° E) ; 141 colonnes **hétérogènes d'un État à l'autre** (`Rock_type`, `Lith_Unit`, `GEOM_UNIT`, `Landform`, `LG_*`, `ROCK_GROUP`…) |
| Groundwater Prospects, structures (linéaments) | `Bhuvan_Groundwater_Prospects_STRU.parquet` | 69 Mo | 859 695 lignes ; schéma lui aussi hétérogène |
| **Lithologie GSI au 1:50k** (NGDR) | `NGDR_Lithology_50k.parquet` (`geology`) | 587 Mo | 3 966 842 polygones ; `lithologic`, `formation`, `group_name`, `supergroup`, `age`, `toposheet_` ; emprise Inde entière |
| **Linéaments au 1:50k** (Bhuvan, 2005-06) | `Bhuvan_Lineament_50k_0506.parquet` (`geomorphology`) | 28 Mo | 236 334 lignes ; `Level1`, `Level2` (codes à décoder avec la documentation Bhuvan `gm.pdf`), `st_code` |
| Linéaments au 1:250k (NGDR) | `NGDR_Lineament_250k.parquet` (`geomorphology`) | 8 Mo | 35 330 lignes ; `l1descript`, `l2descript` |

**Couverture des prospects par État :** non vérifiée. Les deux parties couvrent
toute l'Inde en emprise, mais le fichier n'a pas de champ d'État. Selon NRSC,
les cartes de la première phase couvrent AP, Assam, Chhattisgarh, Gujarat, HP,
J&K, Jharkhand, Karnataka, Kerala, MP, Odisha, Pendjab, Rajasthan et
Uttarakhand. À vérifier après téléchargement.

## 3. Puits et linéaments par État

Puits CGWB avec un relevé de mai 1996–2000 (`output/tables/09_etats_geologie_puits.csv`),
croisés avec le nombre de linéaments au 1:50k par `st_code` (lecture à
distance). L'espacement est celui d'une grille régulière de même densité.

| État | Part alluviale | Puits 1996–2000 | Puits / 1 000 km² | Espacement | Linéaments 1:50k |
| --- | --- | --- | --- | --- | --- |
| Karnataka | 0,00 | 1 131 | 5,9 | 13 km | 43 244 |
| Andhra Pradesh (non divisé) | 0,08 | 1 114 | 4,1 | 16 km | 35 355 |
| Odisha | 0,20 | 968 | 6,3 | 13 km | 25 073 |
| Madhya Pradesh | 0,12 | 1 137 | 3,7 | 16 km | 21 711 |
| Maharashtra | 0,06 | 1 268 | 4,1 | 16 km | 18 965 |
| Tamil Nadu | 0,17 | 940 | 7,3 | 12 km | 16 247 |
| Gujarat | 0,51 | 1 106 | 6,1 | 13 km | 15 863 |
| Rajasthan | 0,70 | 955 | 2,8 | 19 km | 14 648 |
| Chhattisgarh | 0,00 | 592 | 4,4 | 15 km | 12 597 |
| Uttar Pradesh | 0,92 | 1 307 | 5,4 | 14 km | 1 571 |

Les linéaments sont presque absents de la plaine alluviale (UP, Bihar, Pendjab,
Haryana). C'est cohérent : la piste A ne peut vivre qu'en socle.

## 4. Trois points de rigueur avant d'aller plus loin

1. **Densité des puits.** A′-L-C4 montre que la relation entre géologie et
   profondeur s'apprend entre voisins proches et ne se transporte pas d'une
   sous-division à l'autre (−0,004). Les puits CGWB sont espacés de 12 à
   16 km en socle. Rien ne garantit que ce réseau suffise à apprendre une
   relation aussi locale. C'est la question que doit trancher le premier
   stage sur les puits CGWB, avec un critère écrit avant.
2. **Variable dépendante.** Avec les puits CGWB, on mesure la profondeur de la
   **nappe**, et non la profondeur **creusée** de Ryan & Sudarshan. C'est la
   bonne variable pour le coût de l'eau privée. Le résultat de Rajasthan ne
   se transfère donc pas mécaniquement.
3. **Exclusion : une menace propre à ces cartes.**
   - Les Groundwater Prospects ont été produits pour le programme d'eau
     potable (ARWSP/RGNDWM), pour localiser des sources « dans un rayon de
     1,5 km de toutes les habitations ».
   - Leur contenu (rendement, profondeur probable des forages) guide donc
     aussi l'implantation des forages **publics**.
   - Plus généralement, rendement et fractures conditionnent le coût d'un
     forage public autant que celui d'un forage privé. L'asymétrie de la RD,
     où l'aspiration ne touchait que le privé, ne tient pas d'office ici.
   - Cela touche directement la règle de CLAUDE.md : « No story in which the
     public cost jumps at the same place as the private cost ».
   - Il faudra trancher avant la porte C quelles variables géologiques
     entrent dans l'instrument. La lithologie GSI, indépendante du programme
     d'eau potable, est sans doute plus défendable que les classes de
     rendement des prospects.

## 5. Proposition (à décider par Valentine)

**Région :** l'**Andhra Pradesh non divisé** en premier.
- Pour : 1 114 puits avec relevé de mai 1996–2000, 35 355 linéaments au 1:50k.
- Déjà sur disque : CartoDEM et sol pour son socle, et la chaîne de traitement
  du script 10.
- Surtout, l'échec du 24/09 y a été obtenu au 1:2M : refaire le même test avec
  les couches fines teste directement l'hypothèse de granularité, sur les
  données de la cible.

Alternative : Karnataka (1 131 puits, densité de linéaments la plus forte),
mais il faudrait télécharger les tuiles CartoDEM.

**Téléchargements nécessaires**, sur GitHub, joignable d'ici : environ 3,3 Go
au total, dont 2,6 Go pour les prospects.

| Fichier | Taille |
| --- | --- |
| `NGDR_Lithology_50k.parquet` | 587 Mo |
| `Bhuvan_Lineament_50k_0506.parquet` | 28 Mo |
| `NGDR_Lineament_250k.parquet` | 8 Mo |
| `Bhuvan_Groundwater_Prospects_STRU.parquet` | 69 Mo |
| `Bhuvan_Groundwater_Prospects_LGEOM.00.parquet` | 1,7 Go |
| `Bhuvan_Groundwater_Prospects_LGEOM.01.parquet` | 0,9 Go |

**Ensuite, dans l'ordre :**
1. Écrire le critère du premier stage CGWB en AP avec les couches fines.
2. Après seulement, coder la lithologie et décoder les linéaments, pour éviter
   une recherche de spécification sur le codage.
3. Estimer.
4. Porte C, avec effets fixes de sous-district.
