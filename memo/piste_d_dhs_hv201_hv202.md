# Piste D — DHS : couverture de hv201 / hv202 / hv201a (Ghana, Indonésie)

01/10/2026. Contrôle de couverture sur les neuf fichiers ménages (HR) déposés
dans `raw/dhs/`. Script `code/14_dhs_hv201_hv202.R` ; tables
`output/tables/14_*` ; journal `output/logs/14_dhs_hv201_hv202.log`.
Descriptif seulement : ni régression, ni graphique, ni fusion.

## Verdict de la piste D (01/10/2026, Valentine) : CLOSE sous sa forme actuelle

Trois échecs empilés ; **aucun n'est réparable avec ces données.**

1. **Réallocation** : hv201 seule gonfle la baisse apparente de la provision
   publique — une part des ménages passés à l'eau emballée pour boire reste
   raccordée pour les autres usages (Ghana 2022 : 46 % des emballés, déf.
   stricte).
2. **Nomenclature** : la comparaison stricte 2008 → 2022 est cassée par
   l'apparition de la catégorie « piped to neighbor » (rupture `_PNB`, la même
   que dans la série agrégée).
3. **Composition** : la comparaison large, seule restante, oppose deux
   populations différentes — l'eau en sachet passe d'un produit des ménages
   aisés à un produit de masse.

**Ce qui reste** : le gradient de richesse dans le temps est le tri par le
revenu que suppose le cadre — le substitut privé commence chez les ménages
solvables et descend dans la distribution (part des emballés dans le quintile
le plus riche : 65 % en 2008, 44 % en 2022). Le mécanisme est observé du côté
du substitut ; la réponse publique, jamais.

Aucun nouveau pays, aucune nouvelle vague, aucun nouveau dispositif dans cette
session.

## Verdict contre le critère de signalement

Critère écrit en tête du script avant exécution : hv202 absente → « ABSENTE » ;
présente et 0 % non manquant → « VIDE » ; < 5 % → « QUASI VIDE ».

| Enquête | Recode | N | hv202 (dictionnaire .MAP) | hv202 non NA | Signal |
| --- | --- | --- | --- | --- | --- |
| Ghana 2003 | 4 | 6 251 | absente | — | **ABSENTE** |
| Ghana 2008 | 5 | 11 778 | présente | 100 % | |
| Indonésie 2003 | 4 | 33 088 | absente | — | **ABSENTE** |
| Indonésie 2017 | 7 | 47 963 | présente | 36,3 % | (univers restreint) |
| Ghana 1993 | 3 | 5 822 | présente | 100 % | |
| Ghana 1998 | 4 | 6 003 | présente | 100 % | |
| Ghana 2014 | 7 | 11 835 | « NA - » (non posée) | **0 %** | **VIDE** |
| Ghana 2022 | 8 | 17 933 | présente | 29,9 % | (univers restreint) |
| Indonésie 2007 | 5 | 40 701 | présente | 100 % | |

- La carte standard des recodes se trompe dans les deux sens : Ghana 1998
  (recode 4) porte hv202 pleine ; Ghana 2014 (recode 7) la porte vide.
- **Ghana 2014 est le piège silencieux** : variable présente, étiquetée, 100 %
  NA, y compris chez les 2 611 ménages buvant de l'eau en sachet ou en
  bouteille. Ce n'est pas un filtre : la question n'a pas été posée (le .MAP le
  dit, préfixe « NA - »).

## Constat décisif : hv202 n'est pas une série temporelle

hv202 est posée à **tous** les ménages avant le décollage du sachet (Ghana 1993,
1998, 2008 ; Indonésie 2007) et **seulement aux ménages buvant de l'eau
emballée** (bouteille, sachet, rechargée) après (Ghana 2022, Indonésie 2017 :
renseignée pour > 99,9 % d'entre eux, < 1 % des autres — prémisse vérifiée par
le script). Le sens de la variable change avec l'univers ; toute comparaison
entre vagues mélange les deux. hv202 est donc **inutilisable comme série**.

## L'univers restreint : canalisation pour les usages hors boisson

Ménages dont hv201 est emballée ; part déclarant la canalisation comme source
hors boisson. Pondéré = hv005 / 10⁶. Stricte = logement + cour + borne
publique ; large = + « piped to neighbor » (catégorie DHS-7/8). Les deux sont
rapportées, aucune n'est choisie.

| Enquête | Définition | Ménages emballés | hv202 non NA | n canalisation | Part | Part pondérée |
| --- | --- | --- | --- | --- | --- | --- |
| Ghana 2022 | stricte | 5 360 | 5 358 | 2 466 | 46,0 % | 49,1 % |
| Ghana 2022 | large | 5 360 | 5 358 | 3 047 | 56,8 % | 63,5 % |
| Indonésie 2017 | stricte | 17 406 | 17 387 | 5 265 | 30,2 % | 24,8 % |
| Indonésie 2017 | large | 17 406 | 17 387 | 5 437 | 31,2 % | 25,6 % |

Lecture : ces ménages sont comptés « hors canalisation » par hv201 seul alors
qu'une partie reste raccordée pour les autres usages — c'est la part de la
baisse apparente qui relève de la réallocation (boisson vers l'emballé) et non
du retrait du réseau. En effectifs bruts (non pondérés), les ménages emballés
mais canalisés (déf. stricte) font 13,8 % de l'échantillon ghanéen 2022
(2 466 / 17 933) et 11,0 % de l'indonésien 2017 (5 265 / 47 963).

- Au Ghana, la définition pèse : « voisin » ajoute 11 points (14 pondérés).
- En Indonésie, la pondération pèse : −5 points ; la canalisation hors boisson
  y est surtout « dans le logement » (26 %), le forage domine (35 %, 42 %
  pondéré).
- Distribution complète de hv202 dans cet univers :
  `output/tables/14_hv202_emballee_distribution.csv`.

## hv201a — eau indisponible ≥ 1 jour sur les deux dernières semaines

| Enquête | Dictionnaire | Non NA |
| --- | --- | --- |
| Ghana 2014 | absente | — |
| Ghana 2022 | « NA - » (non posée) | 0 % |
| Indonésie 2017 | présente | 47,2 % |

- Seule Indonésie 2017 porte une mesure de fiabilité utilisable. Codes :
  0 « no » 18 993 ; 1 « yes, interrupted for a full day or more » 3 587 ;
  8 « don't know » 78.
- **Univers (Indonésie 2017)** : posée si et seulement si la source
  *effective* — hv201, ou hv202 pour les ménages buvant de l'eau emballée — est
  canalisée (logement, cour, voisin, borne) ou un forage. Aucun ménage hors de
  cet univers n'est renseigné ; 435 des 23 093 ménages de l'univers sont NA
  (1,9 % ; borne publique 11 %). Puits, sources, surface, pluie, citernes : jamais interrogés.
- Pour le Ghana, aucune vague ne porte hv201a : la mesure de Brehm, Johnston et
  Milton n'est pas disponible sur ce pays dans ces fichiers.
- **Décision (Valentine, 01/10)** : un seul pays, donc pas de résultat de
  fiabilité comparé entre pays. hv201a reste un descriptif indonésien ; rien
  n'est construit dessus.

## Table de correspondance des codes entre vagues

`code/ref/dhs_codes_source_eau.csv` : une ligne par enquête × variable × code
observé (230 lignes), libellé d'origine, `categorie` fine, `groupe` grossier,
`lieu`, `note`. Le script s'arrête si un code observé y manque ou si son
libellé diffère du fichier. **Codage de jugement, rédigé par Claude, à relire.**
Points saillants :

- sachet : code 81 « satchel water » en 2003, 72 « sachet water » dès 2008 ;
- Indonésie 2017 : 72 = « refilled water » (eau rechargée), rangée dans
  l'emballé ;
- DHS-7/8 : 13 = « piped to neighbor », la borne publique passe à 14 ;
- Indonésie 2007 : puits codés 33–38 (21–33 en 2003) ;
- recodes 2–4 au Ghana : « piped into residence » (logement ou cour, non
  séparables), « public tap/neighbours house » (Ghana 1998, borne et voisin
  confondus), puits sans indication de protection ;
- révision du 01/10 (Valentine) : « public tap/neighbours house » passe au
  groupe `non_resoluble` (plus de rattachement par défaut à la
  canalisation) ; colonne `categories_possibles` : `borne_publique|canalisation_voisin`
  pour celui-ci, `canalisation_logement|canalisation_cour` pour « piped into
  residence », de sorte que la question de reclassement puisse être rouverte ;
  colonne `jugement` : motif de chaque ligne de jugement (84 lignes, 24 cas
  distincts dans `code/ref/dhs_codes_source_eau_a_revoir.csv`) ;
- code 99 sans étiquette : traité comme manquant.

## Ce qui a été vu (transparence pour tout critère futur)

Les parts de canalisation hors boisson ci-dessus sont des **niveaux de
provision publique** dans une seule vague, chez les ménages buvant de l'eau
emballée, au Ghana 2022 et en Indonésie 2017. Aucune comparaison entre vagues,
aucune autre vague, aucun autre sous-groupe n'a été calculé. Un critère futur
sur « réallocation contre retrait » doit le mentionner.

## Critère : réallocation contre retrait, Ghana 2008 → 2022 (CONTAMINÉ)

01/10/2026. Critère donné par Valentine, recopié ici **avant tout calcul sur
2008**. Il est écrit **après** avoir vu les niveaux 2022 ci-dessus : il est
déclaré contaminé et ne fixe que le **sens** de la lecture, pas un seuil de
réussite. Aucun seuil numérique, précisément parce que 2022 a été vu.

- **Mesure** : à univers constant — ménages dont hv201 est emballée (bouteille
  ou sachet) —, part déclarant la canalisation pour les usages hors boisson
  (hv202), Ghana 2008 (957 ménages, hv202 universelle, restreinte ici aux
  emballés) contre Ghana 2022 (5 360, univers restreint par le questionnaire).
- **Titre** : définition stricte (logement, cour, borne publique). **Variante** :
  large (+ « piped to neighbor », catégorie qui n'existe pas en 2008 : la
  rupture de code ne doit pas entrer dans la mesure de titre). Pondéré et non
  pondéré.
- **Lecture** : part à peu près stable → la baisse de la provision publique
  mesurée par hv201 est surtout de la réallocation (boisson vers l'emballé), le
  fait brut est en grande partie un artefact. Part en baisse marquée → les
  ménages perdent le raccordement lui-même, le retrait est réel.
- Précisions de Claude, écrites au même moment, avant calcul : poids hv005/10⁶
  propres à chaque vague ; intervalles à 95 % par linéarisation, grappes = PSU
  (hv021), domaine « emballés » estimé sur l'échantillon complet, strates
  ignorées faute d'être dans le cache (en général conservateur) ; différence
  2022 − 2008 avec échantillons indépendants. L'intervalle sert à dire si
  « stable » ou « en baisse » se distingue du bruit, pas de seuil.

### Verdict (critère contaminé, sens seulement)

**On ne distingue pas le retrait du bruit ; le fait brut ghanéen ne tient
pas.**

Raisonnement de Valentine (01/10), qui fixe le verdict : en 2008 il n'existe
pas de catégorie « voisin », ces ménages étaient donc dans la définition
stricte ; en 2022 ils en sont sortis. La comparaison stricte mesure un
changement de nomenclature en plus de ce qui serait réel — la même rupture
`_PNB` que dans la série agrégée, qui réapparaît au niveau micro. Elle est
**disqualifiée comme titre**. Reste la variante large, seule comparaison à
univers constant : **−8,0 points pondérés, IC 95 % [−17,0 ; +1,1]**, qui
contient zéro.

Première lecture du même jour, remplacée : la stricte avait été prise pour
titre (« baisse marquée, retrait réel »), comme prévu par le critère. La
rupture de nomenclature la rend inutilisable ; elle reste dans la table pour
mémoire.

| Définition | Pondération | 2008 | 2022 | 2022 − 2008 | IC 95 % |
| --- | --- | --- | --- | --- | --- |
| **large** | **pondérée** | 71,5 % | 63,5 % | **−8,0 pts** | **[−17,0 ; +1,1]** |
| large | non pondérée | 70,7 % (677 / 957) | 56,8 % (3 047 / 5 360) | −13,9 pts | [−22,8 ; −5,0] |
| stricte (disqualifiée) | non pondérée | 70,7 % | 46,0 % (2 466 / 5 360) | −24,7 pts | [−33,5 ; −16,0] |
| stricte (disqualifiée) | pondérée | 71,5 % | 49,1 % | −22,4 pts | [−31,2 ; −13,6] |

En 2008, « large » = « stricte » : la catégorie « piped to neighbor »
n'existe pas. PSU : 411 (2008), 618 (2022). Tables :
`output/tables/14_ghana_2008_2022_*`.

### Points ouverts sous le verdict

- **Où étaient les « voisins » en 2008 ?** Sans catégorie propre, ils étaient
  codés ailleurs — borne publique, cour, ou hors canalisation. S'ils étaient
  dans la borne ou la cour (lecture retenue par le verdict), la variante large
  est bien à univers constant. S'ils étaient hors canalisation (« other »,
  par exemple), la large 2022 en inclut que 2008 n'avait pas, et même elle
  n'est pas tout à fait comparable. Non vérifié ; le questionnaire 2008
  (consigne d'enquêteur) peut le dire.
- **Composition** : l'univers est constant par définition, pas par
  population. Les emballés passent de 8,1 % des ménages (957 / 11 778) à
  29,9 % (5 360 / 17 933) ; en 2022 l'emballé atteint des ménages moins
  raccordés au départ. Une baisse de la part peut venir de cette composition
  sans qu'aucun ménage perde son raccordement. Rival à tester avant de lire
  le verdict comme « perte du raccordement ».

## Test de composition : les emballés 2008 et 2022 sont-ils la même population ?

01/10/2026. Demandé par Valentine : les emballés passent de 8,1 % à 29,9 % des
ménages — niche en 2008, marché de masse en 2022. **Si les deux groupes
diffèrent nettement, la comparaison porte sur deux populations différentes et
tout l'exercice est nul.** Rien d'autre n'est calculé : ni repondération, ni
autre vague, ni autre pays.

Précisions de Claude, écrites **avant tout calcul** :

- **Dimensions** : quintile de richesse (hv270 ; quintiles nationaux propres à
  chaque enquête, donc position relative dans le pays — c'est la bonne mesure
  pour « niche contre masse ») ; milieu urbain/rural (hv025) ; niveau
  d'instruction du chef de ménage (hv106 du membre dont hv101 = chef ; aucun,
  primaire, secondaire, supérieur ; « ne sait pas » et manquant comptés à
  part).
- **Mesure** : indice de dissimilarité D = ½ Σ |p₂₀₀₈ − p₂₀₂₂| sur les
  catégories d'une dimension (part de l'un des groupes à déplacer pour égaler
  l'autre). Pondéré (hv005) en titre, non pondéré rapporté.
- **Règle** (traduction proposée de « diffèrent nettement » ; validée par
  Valentine le 01/10, après calcul) : **D ≥ 0,20 sur au moins une dimension → populations
  différentes, exercice nul.** D maximal dans [0,10 ; 0,20) → limite, rapporté
  comme limite. Tous les D < 0,10 → comparables. Si pondéré et non pondéré ne
  tombent pas dans la même classe → rapporté instable, sans choisir.

### Verdict : populations différentes — l'exercice est nul

**La part des emballés dans le quintile le plus riche passe de 65 % à 44 %
(pondéré : 65,3 % → 44,1 %).** Ce déplacement suffit à lui seul (Valentine,
01/10) : l'eau en sachet est passée d'un produit des ménages aisés à un produit
de masse, et les deux groupes ne sont pas comparables, quelle que soit la
statistique de synthèse retenue. La comparaison 2008 → 2022 à « univers
constant » oppose deux populations ; l'exercice est nul — y compris la variante
large qui portait le verdict précédent. La règle écrite avant calcul donne le
même verdict (D richesse = 0,212 pondéré, 0,231 non pondéré, seuil 0,20), mais
la conclusion n'en dépend pas.

| Dimension | D pondéré | D non pondéré | Classe |
| --- | --- | --- | --- |
| **Quintile de richesse** | **0,212** | **0,231** | **différentes** |
| Milieu urbain/rural | 0,048 | 0,096 | comparables |
| Instruction du chef | 0,034 | 0,051 | comparables |

- **Richesse** (part pondérée, 2008 → 2022) : quintile le plus riche
  65,3 % → 44,1 % ; « richer » 27,1 % → 36,8 % ; « middle » 7,1 % → 14,9 % ;
  deux quintiles du bas 0,5 % → 4,3 %. N : 957 et 5 360 ménages emballés.
- **Milieu** : urbain 87,2 % → 82,4 % pondéré (86,8 % → 77,2 % non pondéré ;
  le non pondéré frôle la limite à 0,096).
- **Instruction du chef** : secondaire 64,7 % → 61,8 %, supérieur 22,3 % →
  21,7 % pondéré.
- **Seuil** : le D pondéré ne dépasse 0,20 que de 1,2 point ; c'est pourquoi
  le verdict s'appuie sur le déplacement du quintile le plus riche et non sur
  la comparaison de D au seuil.
- La différence est concentrée sur la richesse, pas sur le milieu ni
  l'instruction : en 2022 l'emballé descend dans la distribution de la
  richesse ; la part rurale ne monte que de 12,8 % à 17,6 % (pondéré).
- Équivalence de libellé admise (journalisée `[EQUIV]`) : instruction code 0,
  « no education, preschool » (2008) = « no education, preschool/early
  childhood education » (2022). La première exécution s'est arrêtée sur cet
  écart ; équivalence validée par Valentine le 01/10.

Tables : `output/tables/14_composition_emballes.csv`,
`14_composition_dissimilarite.csv`.

## Points ouverts

- Ghana 2003 (début de la série sachet) n'a aucune source hors boisson.
- Relire la table de correspondance (`categorie`, `lieu`) avant tout usage.
