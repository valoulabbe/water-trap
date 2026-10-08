# Outils externes — revue des dépôts GitHub

08/10/2026. Revue d'outillage pour les pistes ouvertes, confrontée à ce qui est
déjà dans `renv.lock`, dans `raw/` et aux contraintes de la section Tooling de
`CLAUDE.md`. Chaque dépôt a été ouvert et son README lu avant d'être listé ici.
Limite de la vérification : les pages récupérées n'affichent pas la date du
dernier commit, donc l'activité récente n'est pas certifiée. La recherche est
passée par le web, pas par l'API GitHub (bloquée) : la couverture n'est pas
exhaustive.

## Règle de lecture

Un seul filtre dur subsiste : **India-WRIS ne répond pas depuis cette machine**
(timeout TCP, `CLAUDE.md`). Tout outil dont le transport est
`arc.indiawris.gov.in` est inutilisable ici, quelle que soit sa qualité.

La règle « R seulement » de `CLAUDE.md` §Tooling est levée pour l'outillage
(décision de Valentine, 08/10). Conséquence à assumer, pas à oublier :
`renv.lock` ne décrit alors plus l'environnement complet. Un `requirements.txt`
(ou un lock `uv`) versionné devient nécessaire, et la règle de provenance de
`raw/README.md` — source, date, SHA256 — reste la seule garantie de
reproductibilité pour tout fichier qu'un outil Python dépose dans `raw/`.

## Déjà couvert — ne rien installer

| Besoin | Déjà en place | Conséquence |
| --- | --- | --- |
| Accès API DHS, téléchargement et mise en commun entre vagues | **`rdhs`**, déjà dans `renv.lock` | `ropensci/rdhs` était la recommandation évidente pour la piste C ; elle est redondante. `code/12_dhs_api_inventaire.R` s'en sert déjà. |
| Niveaux CGWB | `raw/cgwb`, `raw/cgwb_quality` | `craigdsouza/cgwb` est déjà dans `raw/` et déjà documenté comme copie non officielle sans licence. Vérification refaite le 08/10 : **2 commits, aucune licence**, et le scraper CGWB annoncé dans son README est un objectif, pas du code livré. |
| Commerce bilatéral (importations de groupes électrogènes) | `raw/comtrade` (JSON 1988-2000, SHA256 au `raw/README.md`) | `ropensci/comtradr` (R, 84 ★, revu rOpenSci) automatiserait la collecte, mais le tirage est fait et tracé. À garder en réserve si le périmètre pays/années s'élargit. |
| Puits Bangladesh géoréférencés, arsenic labo, profondeur, année d'installation | `raw/hydroshare` (Araihazar), `raw/vangeen2019` (BAMWSP, 44 865 villages) | Rien sur GitHub n'approche ces deux jeux. Les dépôts « arsenic Bangladesh » trouvés sont des projets étudiants sans données propres. |

## Candidats retenus

| Dépôt | Ce qu'il fait | Licence / taille | Pour quelle piste |
| --- | --- | --- | --- |
| [`devdatalab/masala-merge`](https://github.com/devdatalab/masala-merge) | Levenshtein modifiée pour noms de lieux et de personnes indiens : pénalités réduites sur les graphies alternatives hindi (« laxmi »/« lakshmi » → 0,4 au lieu de 3), combinée à `reclink`. Cœur en Stata, **port R `masala_merge.R`**, coûts de substitution dans `lev.py` | **Aucune licence déclarée**, 4 ★ | Transversal. Répond au blocage du 6e recensement MI (106 402 villages UP avec noms, sans code village). Le port R contourne le filtre 1 ; code à relire avant usage |
| [`devdatalab/parse-pdf-table`](https://github.com/devdatalab/parse-pdf-table) | Tableaux de PDF à couche texte ; écrit pour les *district handbooks* PC01 ; s'enchaîne avec `ocrmypdf` sur les scans | Python, fork, 0 ★, pas de licence | Tableaux village de forages 1993-94 ; numérisation DCHB (extension E5). Usage ponctuel |
| [`carderne/gridfinder`](https://github.com/carderne/gridfinder) | Infère le tracé du réseau de distribution : lumières nocturnes → arbre couvrant minimal, réseau routier en fonction de coût | **MIT**, 75 ★, Python | Piste électricité. Le seul candidat produisant une mesure d'accès **infra-État**, donc le seul compatible avec la contrainte retenue après la fermeture de la piste E. À prendre via `predictive-mapping-global-power` plutôt que seul |
| [`worldbank/blackmarbler`](https://github.com/worldbank/blackmarbler) | **Package R.** Télécharge les tuiles NASA Black Marble (LAADS DAAC), mosaïque, et agrège aux polygones via `exactextractr` (`bm_extract`) | 35 ★ | Piste électricité. Rentre dans `renv` (`exactextractr` à ajouter au lock) ; voir `blackmarblepy` si la chaîne est déjà en Python |

## Écartés, avec la raison

- **[`galib9690/pygeoglim`](https://github.com/galib9690/pygeoglim)** (GLiM/GLHYMPS par polygone) — annoncé pour le CONUS ; le mode `region="global"` exige un token HuggingFace et dépend de la disponibilité des tuiles. 2 ★, 18 commits — écarté sur la qualité et la couverture, pas sur le langage. Apport réel de la page, indépendant du code : **GLiM est en « personal research use only », redistribution sur autorisation écrite du CCGM** ; GLHYMPS 2.0 est en ODbL. À reporter dans `raw/README.md` si une version de ces couches atterrit dans `raw/geology`.
- **[Plugin QGIS « CGWB Groundwater Data Downloader »](https://plugins.qgis.org/plugins/wris_extractor/)** ([Zenodo](https://zenodo.org/records/20942324)) — extracteur INDIA WRIS. Éliminé par le filtre 2 : son transport est précisément l'hôte qui ne répond pas depuis cette machine.
- **[`worldbank/OpenNightLights`](https://github.com/worldbank/OpenNightLights)** (CC BY 4.0, 39 ★) — tutoriel Jupyter Book, pas une bibliothèque. À noter : la page ne mentionne **pas** les indicateurs HREA, contrairement à ce que laissait entendre un résultat de recherche.
- **[`DHSProgram/DHS-Indicators-R`](https://github.com/DHSProgram/DHS-Indicators-R)** (119 ★) — code de référence des indicateurs du Guide to DHS Statistics. Utile comme référence, pas comme dépendance. Point de repérage : les indicateurs **WASH sont au chapitre 16 du Guide mais dans le dossier `Chap02_PH`** du dépôt (un `Chap16_WS/DHS8` existe aussi, non décrit). La page ne documente pas d'indicateur de *méthode de traitement de l'eau* : le code de référence de la variable centrale de la piste C est à chercher dans le dossier, il n'est pas garanti.
- **[`ipums/ipumsr`](https://github.com/ipums/ipumsr)** (43 ★, statut « Active ») — dans IPUMS Global Health, l'API permet requête et téléchargement **pour DHS uniquement**. Redondant avec `rdhs` tant que le comparatif reste sur les recodes DHS ; à reprendre si on passe aux vagues harmonisées IPUMS DHS.
- **`devdatalab/code` n'existe pas** (404). L'organisation a 20 dépôts publics, surtout des réplications d'articles ; pour SHRUG le seul dépôt est [`devdatalab/shrug-public`](https://github.com/devdatalab/shrug-public), qui est un *issue tracker*, pas du code.

## Rouverts par la levée de la contrainte R (08/10)

| Dépôt | Ce qu'il fait | Licence / taille | Pour quelle piste |
| --- | --- | --- | --- |
| [`moj-analytical-services/splink`](https://github.com/moj-analytical-services/splink) | Appariement probabiliste Fellegi-Sunter. Backend **DuckDB** : ~1 million d'enregistrements en une minute sur portable ; Spark au-delà de 100 M. Comparateurs Jaro / Jaro-Winkler intégrés et **logique floue définie par l'utilisateur** | **MIT**, ~2,4 k ★ | Transversal, et le vrai candidat pour les 106 402 villages UP du 6e MI. Voir la note ci-dessous : complément de `masala-merge`, pas substitut |
| [`worldbank/blackmarblepy`](https://github.com/worldbank/blackmarblepy) | Équivalent Python de `blackmarbler` : tuiles LAADS DAAC, HDF5 → rasters géoréférencés mosaïqués, sorties `xarray.Dataset`, statistiques zonales via `exactextract`. Token NASA Earthdata requis | **MIT** + World Bank IGO Rider (ne restreint pas MIT), 65 ★ | Piste électricité. À préférer à la version R si la chaîne passe de toute façon par Python (`gridfinder`) : même famille d'outils, un seul token |
| [`carderne/predictive-mapping-global-power`](https://github.com/carderne/predictive-mapping-global-power) | Chaîne complète de l'article *Predictive mapping of the global power system using open data* : `runner.py`, `config.yml`, `scripts/`. S'appuie sur `gridfinder` **et `access-estimator`** | **MIT**, 36 ★ | Piste électricité. C'est l'usage encadré de `gridfinder` : le papier, ses sources et ses paramètres, plutôt que l'algorithme nu. Sorties annoncées sur Zenodo (doi 10.5281/zenodo.3369106) — **contenu de l'archive non vérifié** |
| [`Roche/pyreadstat`](https://github.com/Roche/pyreadstat) | Lecture/écriture SAS, SPSS, Stata vers pandas/polars via la bibliothèque C ReadStat. `read_dta(..., apply_value_formats=True)`, libellés dans `meta.variable_value_labels` | **Apache 2.0**, 425 ★ | Piste C et DHS. **Hypothèse à tester** : la politique Windows qui bloque les DLL du cache `renv` (d'où `haven` cassé et le détour `00_convert_dta.R`) ne porte pas sur une wheel Python ; si ça se vérifie, c'est une lecture directe des `.dta` SHRUG et des recodes DHS, sans conversion préalable |
| [`nsidc/earthaccess`](https://github.com/nsidc/earthaccess) | Recherche et téléchargement/streaming de données NASA Earthdata, « agnostique mission et domaine ». Compte Earthdata gratuit, Python ≥ 3.12 | **MIT**, 643 ★ | Piste eau souterraine, **si** elle rouvre : voie d'accès aux stocks d'eau GRACE. La page ne mentionne pas GRACE : support à confirmer sur un *short name* avant d'y compter |
| [`ipums/ipumspy`](https://github.com/ipums/ipumspy) | Outils IPUMS en Python | MPL-2.0, 15 ★ | Marginal. La page **ne dit rien** des extraits API ni de DHS/Global Health ; `rdhs`, déjà installé, couvre le besoin. À ne regarder que si on passe aux vagues harmonisées IPUMS DHS |

### splink et masala-merge ne font pas le même travail

`splink` apporte l'échelle et un modèle d'appariement calibré ; il ne sait rien
des graphies translittérées de l'hindi. `masala-merge` encode exactement cette
connaissance, dans `lev.py` (coûts de substitution : « laxmi »/« lakshmi » → 0,4
au lieu de 3), mais sur un cœur Stata et sans licence. La combinaison utile est
donc : `splink` pour le blocage et le score, avec les coûts de substitution de
`masala-merge` repris comme comparateur personnalisé — la fonctionnalité
« user-defined fuzzy matching logic » existe pour ça. C'est un développement à
faire, pas un outil à installer.

## Ce que cette revue ne résout pas

Aucun de ces outils n'est un décaleur de coût. `gridfinder` est le seul à produire
une variation plus fine que l'État, donc le seul candidat de la piste électricité
qui survivrait à l'argument qui a fermé la piste E — mais il produit un réseau
*inféré*, pas un prix, et son erreur de mesure est spatialement corrélée, ce qui
se discute avant toute estimation, pas après.

## Ce que ça résoudrait, case par case

08/10/2026. Confrontation des outils ci-dessus aux cases non cochées de
`docs/ROADMAP.md`. Une ligne par case ouverte que l'outillage touche réellement ;
les cases que rien ici ne débloque sont regroupées en fin de tableau, parce que
c'est l'information utile.

| Case ouverte (ROADMAP) | Ce qui bloque | Outil | Ce que ça résoud — et ce qui reste |
| --- | --- | --- | --- |
| Piste D : « Construire la table pays-année GIZ » | Les rounds antérieurs « n'existent qu'en PDF […] donc hors d'atteinte sans saisie manuelle, qu'on s'interdit » | `parse-pdf-table` | **Lève l'interdit.** Les rounds GIZ en PDF ont une couche texte ; l'outil est écrit pour ce cas précis (*district handbooks* PC01) et s'enchaîne avec `ocrmypdf` sur les scans. La saisie manuelle n'est plus l'alternative. Reste entier : le round 2018 n'existe que sous forme de **graphique**, qu'aucun extracteur de tableau ne lira |
| Piste D : « identification au niveau grappe (GPS) et d'un décaleur de coût » | Pas de covariable d'activité économique locale à la maille grappe | `blackmarblepy` / `blackmarbler` | Statistiques zonales de luminosité par grappe DHS, 1992-aujourd'hui, donc un contrôle d'activité locale **et** une datation de l'électrification là où elle manque. Attention au déplacement GPS DHS (2 km urbain, 5 km rural) : il impose un rayon d'agrégation supérieur au déplacement, sinon on moyenne du bruit |
| Piste D : « vérifier `HV202` vague par vague dès réception, Indonésie 2017 en premier » | Lecture des recodes ménages `.dta`, et `haven` cassé par la politique DLL Windows (`CLAUDE.md`) | `pyreadstat` (+ `rdhs`, déjà installé) | `rdhs` fait le téléchargement et la mise en commun ; `pyreadstat` lit les `.dta` avec libellés **sans passer par le cache `renv`**, donc contourne peut-être le blocage DLL qui a imposé `00_convert_dta.R`. **Hypothèse non testée** : à vérifier sur un fichier avant d'en dépendre |
| Piste C (**rouverte le 07/10**) / piste D : « Harmoniser les districts entre rounds », « toute comparaison inter-rounds exige une table de passage construite sur les noms » | 78 régions NSS → 88 avec codes réattribués ; districts renumérotés au 69e puis au 76e. Appariement sur les noms, à la main | `splink` + coûts de `masala-merge` | Le cœur du problème, et redevenu actif avec la réouverture de la piste C. `splink` donne l'échelle (DuckDB, ~1 M d'enregistrements/minute) et un score calibré ; les coûts de substitution hindi de `masala-merge` entrent comme comparateur personnalisé. Reste : un crosswalk apparié n'est pas un crosswalk **validé** — taux d'appariement documenté et inspection manuelle des non-appariés (checkpoint 5) |
| Constat Phase 0a : 6e recensement MI, 106 402 villages UP « noms sans code village » | Même problème, à plus grande échelle | `splink` + `masala-merge` | Idem. Débloque mécaniquement, mais la profondeur du 6e MI est **postérieure aux résultats** (2017-18) : l'outil résoud l'appariement, pas l'anachronisme qui avait disqualifié la source |
| Extension E5 : « numérisation DCHB » | Numérisation manuelle | `parse-pdf-table` | C'est son cas d'usage d'origine. Phase 1, donc sans urgence |
| Piste E (fermée) : « volumes *Tariff Schedules of Electric Power Utilities* » | Saisie depuis des volumes imprimés | `parse-pdf-table` | Rendrait la collecte faisable **si** la piste rouvrait. Elle ne rouvre pas : le motif de fermeture est le nombre de clusters traités, pas la donnée |

### Cases ouvertes que l'outillage ne touche pas

C'est la part importante du tableau. Les verrous qui décident aujourd'hui ne sont
pas des verrous d'outillage :

- **Piste H, données ARRP et Araihazar complètes** — « Prochaine action : une question à Jack, pas un prompt pour Claude Code ». Aucun outil ne substitue cet arbitrage. Les trois sources publiques sont déjà épuisées et documentées comme insuffisantes (lots d'enquête confondus avec les cohortes ; `yao-yl/As-measurement-code` tronqué à 30 m, donc la marge du seuil de 45 m est coupée).
- **Règle de non-contact** (décision de Jack, 02/10) — contrainte de méthode, pas de collecte.
- **Ravenscroft et al. (2014)**, payant sans version PMC — accès institutionnel, pas outil.
- **Microdonnées de l'enquête 2012-2013** (48 790 puits), non déposées — rien à scraper.
- **Fichier GIZ complet 1991-2020** sur le TUMI Mobility Data Hub, « injoignable depuis la machine de travail » — ce n'est pas un dépôt GitHub qui règle ça mais un téléchargement depuis un navigateur ; à noter que le conteneur cloud ne l'atteint pas non plus (réseau sur liste blanche).
- **Verrou 0 de la piste E** (carte du rationnement) — « travail de bureau, une page, aucune donnée ». Explicitement hors outillage.
- **Piste I, salinité** — fermée le 08/10 sur critère écrit d'avance. Aucun outil n'était en cause : le motif est que la moitié de la variance survivant aux effets fixes de district est du bruit de mesure.

### Point de procédure

La levée de la contrainte R du 08/10 porte sur l'outillage. Mais ROADMAP garde,
dans « Questions pour le PI », la case **« Langage : analyse en R plutôt qu'en
Python — toujours à confirmer »**, et le journal des décisions porte « Analyse en
R (renv, rdrobust, rddensity) — Valentine ; à confirmer par le PI ». La décision
n'est donc pas encore arbitrée avec Jack. Tant qu'elle ne l'est pas, la
distinction à tenir est : **outil de préparation en Python, estimation en R**.
Ça laisse `splink`, `parse-pdf-table`, `pyreadstat` et `blackmarblepy` du côté de
la préparation, où ils produisent un fichier versé dans `raw/` ou `build/` avec
sa provenance, et ça n'engage rien sur le langage de l'analyse.


## Pistes encore ouvertes — recherche du 08/10/2026

Après les fermetures du 08/10, deux pistes restent ouvertes (A et C) et la piste H
attend une question à Jack. Recherche ciblée sur leurs verrous propres.

### Piste A — verrou d'accès aux couches (Bhuvan, WFS désactivé)

**Le verrou est peut-être mal posé.** Le premier stage a besoin d'**une classe
lithologique par puits**, pas des polygones. Or un service WMS, même quand le WFS
est coupé, répond aux requêtes `GetFeatureInfo` : attributs du polygone sous un
point donné. Si Bhuvan sert la couche en WMS, l'information nécessaire est
accessible point par point sans jamais télécharger le vecteur.

| Outil | Ce qu'il fait | Licence / taille | Statut de vérification |
| --- | --- | --- | --- |
| [`geopython/OWSLib`](https://github.com/geopython/OWSLib) | Client Python des services OGC : WMS, WFS, WMTS, WCS, CSW, WPS. Lecture des métadonnées de service et requêtes | **BSD-3-Clause**, 428 ★ | Vérifié pour la liste des services. La page **ne nomme pas** `GetFeatureInfo` : à confirmer dans la doc avant d'y compter |
| [`openaddresses/pyesridump`](https://github.com/openaddresses/pyesridump) | Extrait les features d'un endpoint Esri REST en GeoJSON (`esri2geojson`, classe `EsriDumper`). Gère la limite `maxRecordCount` par quatre stratégies, dont un découpage en quadtree de l'emprise quand une requête atteint le plafond | **MIT**, 363 ★ | Vérifié. La page mentionne MapServer, **pas FeatureServer** |

**Test fait depuis le navigateur de Valentine le 08/10/2026 — la condition n'est
pas remplie.** `pyesridump` ne valait que si Bhukosh (GSI) exposait un ArcGIS REST
ouvert. Résultat :

| Hôte testé | Résultat |
| --- | --- |
| `bhukosh.gsi.gov.in/arcgis/rest/services` | **Injoignable** — page d'erreur, la navigation ne s'établit pas |
| `bhukosh.gsi.gov.in/Bhukosh/Public` | **Injoignable** — même page d'erreur, donc c'est l'hôte, pas le chemin |
| `bhuvan-app1.nrsc.gov.in` | **Joignable** — 404 propre renvoyé par le serveur, donc l'hôte répond et c'est le chemin qui est faux |

**Conclusion.** Le problème n'est pas seulement un WFS désactivé : l'hôte du GSI ne
répond pas depuis la machine de travail, comme India-WRIS. `pyesridump` reste sans
objet tant que cet hôte est inaccessible — à retester, parce qu'une indisponibilité
de ce genre est souvent temporaire. Côté Bhuvan en revanche les hôtes répondent,
donc la voie `GetFeatureInfo` reste ouverte ; elle demande l'URL exacte du service
et les noms de couches, que seul le portail où les couches sont visibles donne.

- [ ] **Reporter ici l'URL du portail Bhuvan où les couches sont visibles et le nom exact des couches**, puis lire le `GetCapabilities` du service et tester un `GetFeatureInfo` sur un puits connu
- [ ] Retester `bhukosh.gsi.gov.in` plus tard : s'il revient, `pyesridump` redevient le candidat le plus direct

**Résultat négatif, vérifié, qui ferme une fausse piste.** Macrostrat
([`UW-Macrostrat/macrostrat`](https://github.com/UW-Macrostrat/macrostrat),
Apache-2.0) est l'alternative évidente à Bhuvan, avec une API publique. J'ai
interrogé son endpoint `geologic_units/map` sur un point du Telangana
(17,5 N / 78,5 E) : il répond, mais l'unité renvoyée est « Archean crystalline
metamorphic rocks », de source **Chorlton, *Generalized geology of the world*,
Geological Survey of Canada Open File 5529** — une carte mondiale à petite
échelle. C'est **plus grossier que la carte au 1:2M qui a déjà échoué** sur
l'Andhra Pradesh le 23/09. Macrostrat ne sert donc à rien ici, et ce n'est pas la
peine d'y passer du temps.

Même raisonnement pour **OneGeology** : le GSI y est fournisseur, mais le profil
OneGeology est un **WMS de niveau 1**, donc une image et non des polygones. Ça
ramène au point ci-dessus — utile seulement par `GetFeatureInfo`, pas comme
source vectorielle.

**Deux exigences si la voie point-par-point est retenue.** Les réponses doivent
être **mises en cache dans `raw/`** avec leur date, sinon le pipeline n'est plus
reproductible (le service peut changer ou disparaître) ; et `GetFeatureInfo`
renvoie parfois le seul libellé de légende au lieu des attributs complets, ce qui
ne suffirait pas pour des classes fines à la Ryan & Sudarshan.

### Piste C — il manque un décaleur de coût, et aucun outil ne le fournit

Le verrou n'est pas instrumental. Mais une mise en garde ressort de la piste I,
et elle vaut plus qu'une suggestion d'outil :

**Ne pas réessayer avec un autre analyte du même fichier.** La décomposition qui
a tué la salinité — 45 % entre districts, 27 % entre stations, 28 % entre années
dans la même station — est une propriété du **réseau de stations CGWB** et de son
protocole de prélèvement, pas de la conductivité. Le fluorure, le nitrate ou
l'arsenic mesurés sur les mêmes stations, aux mêmes dates, hériteraient très
probablement du même rapport bruit/signal intra-district. Avant d'ouvrir une
piste J sur `raw/cgwb_quality`, refaire d'abord la décomposition de variance sur
l'analyte visé : c'est une demi-journée, et ça évite de reconstruire tout un
design sur du bruit.

Ce qui reste acquis et réutilisable, indépendamment : l'appariement
NFHS-stations (distance médiane 4,8 km, 78 % des grappes sous 10 km) et
l'inventaire du fichier CGWB avec ses trois anomalies.

**Un décaleur national ne marchera pas.** Par exemple les droits de douane sur
les membranes d'osmose inverse, accessibles via `comtradr` : c'est un choc
national à une date, soit exactement la configuration qui a fermé la piste G.
La contrainte posée après la piste E — un décaleur qui varie plus finement que
l'État — exclut cette famille entière.

### Piste H — rien à chercher

« Prochaine action : une question à Jack, pas un prompt pour Claude Code. »
Les trois sources publiques sont épuisées et documentées comme insuffisantes.
Aucun outil ne change ça.


## Verrou Bhuvan — résolu sur le mécanisme (test du 08/10/2026)

Testé depuis le navigateur de Valentine sur le portail GWIS
(`https://bhuvan-app1.nrsc.gov.in/gwis/gwis.php`), en lisant les requêtes réseau
de la page puis en interrogeant le service directement.

**1. Le WFS est bien coupé, et le serveur le dit mot pour mot.**

```
GET https://bhuvan-vec1.nrsc.gov.in/bhuvan/wfs?SERVICE=WFS&VERSION=1.0.0
    &REQUEST=GetFeature&typeName=cite:bhuvan_watershed&maxFeatures=1
    &outputFormat=application/json
→ <ows:Exception exceptionCode="ServiceUnavailable">
    <ows:ExceptionText>Service WFS is disabled</ows:ExceptionText>
```

Le diagnostic de la feuille de route est donc exact. Inutile de chercher un
contournement côté WFS : il est désactivé au niveau du service.

**2. Deux endpoints distincts, et c'est ce qui trompe.** Le portail charge
l'essentiel de ses couches depuis `…/bhuvan/gwc/service/wms/`, qui est un
**GeoWebCache** : il ne sert que des tuiles et ne répond pas aux requêtes
d'attributs. Mais une couche (`cite:bhuvan_watershed`) passe par
`…/bhuvan/wms/`, le **GeoServer** lui-même.

**3. Sur le GeoServer, `GetFeatureInfo` répond — avec les attributs ET la
géométrie.** Requête testée et réponse obtenue :

```
GET https://bhuvan-vec1.nrsc.gov.in/bhuvan/wms/?SERVICE=WMS&VERSION=1.1.1
    &REQUEST=GetFeatureInfo&LAYERS=cite:bhuvan_watershed
    &QUERY_LAYERS=cite:bhuvan_watershed&SRS=EPSG:4326
    &BBOX=78.4,17.4,78.6,17.6&WIDTH=101&HEIGHT=101&X=50&Y=50
    &INFO_FORMAT=application/json
```

Réponse : une `FeatureCollection` GeoJSON avec `id` (`AP_WS.30598`), la
**géométrie MultiPolygon complète** et les attributs (`WATERSHEDC`,
`NRISCODE`). Ce n'est donc **pas** un simple libellé de légende — la réserve que
j'avais posée est levée.

**Conséquence pour la piste A.** Le téléchargement vectoriel n'est plus
nécessaire : une requête `GetFeatureInfo` par puits donne la classe du polygone
sous le puits, ce qui est exactement l'intrant du premier stage. Et comme la
géométrie revient aussi, la couche pourrait à la limite être reconstituée
polygone par polygone — plus lent, mais sans WFS.

**Outils.** [`geopython/OWSLib`](https://github.com/geopython/OWSLib) est le
client propre pour ça (BSD-3-Clause, 428 ★). `pyesridump` est hors sujet ici :
il visait un ArcGIS REST, et Bhuvan est un GeoServer — en plus de l'hôte GSI
injoignable.

**Ce qui reste à établir, et qui décide maintenant.** Les 14 couches chargées par
GWIS sont des couches de base, d'administration, de transport, d'hydrographie et
de bassins versants : **aucune couche de géologie ou de lithologie**. Le verrou
n'est donc plus le format mais l'existence de la couche.

- [ ] **Identifier la couche visée** : son nom exact (`espace_de_travail:couche`) et le portail Bhuvan où elle est visible — un relevé des requêtes réseau avec la couche affichée le donne en une fois
- [ ] Vérifier qu'elle est servie par `…/bhuvan/wms/` et non seulement par le GeoWebCache : si elle n'est que sur le cache, `GetFeatureInfo` ne répondra pas et il faudra trouver le GeoServer qui la porte
- [ ] Vérifier l'échelle de la couche avant tout appel en masse : c'est l'échelle qui a tué la tentative du 23/09 (carte au 1:2M), et la résoudre n'a aucun intérêt si la couche Bhuvan est aussi grossière
- [ ] Mettre en cache les réponses dans `raw/` avec leur date — le service peut changer, et le pipeline doit rester reproductible
