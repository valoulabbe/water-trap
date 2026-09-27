# Piste C — inventaire des données ménages (NSS 58/69/76, IHDS-I/II)

27/09/2026. Inventaire seulement : aucune fusion, aucune estimation, aucune part
pondérée d'une variable de résultat. Chiffres : `output/logs/11_piste_c_inventaire.log`,
`output/tables/11_*.csv` (script `code/11_piste_c_inventaire.R`, 8 s). Libellés
et codes relevés dans les questionnaires et consignes aux enquêteurs rangés dans
`raw/nss/<round>/docs/` et `raw/ihds/` (provenance et SHA256 : `raw/README.md`).
Les codes documentés sont transcrits dans `code/ref/11_nss_codes_documentes.csv`,
et chaque code observé y est confronté.

## (a) NSS Schedule 1.2 — items eau de boisson

Fichiers : 58 = 7 csv (`Block3` à `Block9-records.csv`, **pas de bloc 1/2** : les
identifiants sont répétés dans chaque bloc) ; 69 = 8 csv (`Block - 1` à `Block - 7`,
niveaux 1 à 8) ; 76 = 9 csv (`L01` à `L09`). Liste complète, lignes et colonnes :
`11_nss_fichiers.csv`. Bloc eau : **58 `Block4-records.csv`** (bloc 4,
« particulars of living facilities ») ; **69 `Block - 4 … level 4.csv`** (bloc 4,
« drinking water, bathroom, sanitation etc. ») ; **76 `L05_Particulars_of_living_facilities.csv`**
(bloc 5). Période de terrain : juillet–décembre de 2002, 2012 et 2018.

Correspondance variable → item : 58 confirmée par le rapport IHSN (dictionnaire
variable par variable) ; 76 par noms explicites et `Data_Layout_NSS76_120.xlsx` ;
**69 sans dictionnaire publié**. Pour le 69, la correspondance est déduite de
l'ordre des colonnes, qui reproduit exactement la numérotation du questionnaire.
Que `b4_q3_1` soit janvier est une déduction, cohérente avec les données : un mois
est coché si et seulement si la suffisance vaut « non », 13 693 sur 13 693.

| Concept | 58e (2002) | 69e (2012) | 76e (2018) |
| --- | --- | --- | --- |
| **Source principale** — variable | `B4_q1` | `b4_q1` | `source_drinking_water` |
| libellé | « major source of drinking water » | « principal source of drinking water » | idem 69 |
| définition de « principale » (consignes) | celle « in major use », toutes saisons des 365 derniers jours | celle « used most commonly (in terms of frequency) » | celle « from which most of the drinking water … was obtained » (volume) |
| codes | tap 1 ; tube well / hand pump 2 ; well 3 ; tank/pond (reserved for drinking) 4 ; other tank/pond 5 ; river/canal/lake 6 ; spring 7 ; others 9 | bottled 01 ; piped into dwelling 02 ; piped to yard/plot 03 ; public tap/standpipe 04 ; tube well/borehole 05 ; well protected 06 / unprotected 07 ; spring protected 08 / unprotected 09 ; rainwater 10 ; tank/pond 11 ; other surface water 12 ; others (tanker-truck, cart…) 19 | bottled 01 ; piped into dwelling 02 ; piped to yard/plot 03 ; **piped from neighbour 04** ; public tap/standpipe 05 ; **tube well 06 ; hand pump 07** ; well protected 08 / unprotected 09 ; **tanker public 10 / private 11** ; spring 12 / 13 ; rainwater 14 ; tank/pond 15 ; other surface water 16 ; others 19 |
| **Accès** — variable | `B4_q3` (« facility of drinking water ») | `b4_q4` (« access to the principal source ») | `Access_source_water`, libellé identique au 69 |
| codes | exclusive use 1 ; common use in building 2 ; community use 3 | exclusive 1 ; common in building 2 ; neighbour's source 3 ; community use : **public source** restricted 4 / unrestricted 5 ; **private source** restricted 6 / unrestricted 7 ; others 9 | identique au 69 |
| public/privé = financement ? | **absent** | oui : les consignes définissent 4–5 comme source « created with the public fund », 6–7 « with the private fund » ; **seulement pour les sources communautaires** (1–3 ne disent rien du financement) | identique au 69, mot pour mot |
| **Suffisance** — variable | `B4_q2` | `b4_q2` + mois `b4_q3_1`…`b4_q3_12` | `water_sufficient_drink` + `Insufficiency_water_Jan`…`_Dec` |
| libellé | « whether availability of drinking water is sufficient throughout the year? » (jugement de l'informateur) | « … from the principal source is sufficient throughout the year? » | identique au 69 |
| codes | yes 1, no 2 ; pas de mois | yes 1, no 2 ; mois cochés = 1 | identique au 69 |
| **Distance** — variable | `B4_q4` | `b4_q5` | `Distance_source_water` |
| codes | within dwelling 1 ; within premises 2 ; outside : < 0,2 km 3 ; 0,2–0,5 4 ; 0,5–1,0 5 ; **1,0–1,6 6 ; ≥ 1,6 7** | idem, mais **1,0–1,5 6 ; ≥ 1,5 7** | identique au 69 |
| **Traitement** — variable | **absent** (aussi absent du 65e, 2008-09, vérifié sur son questionnaire) | `b4_q12` | `Method_treatment` |
| libellé | — | « method of treatment of drinking water by the household » ; méthode utilisée « normally, for most of the drinking water » ; si plusieurs, **le premier code de la liste** | identique au 69, même règle de priorité |
| codes | — | electronic purifier 1 ; boiling 2 ; alum 3 ; bleach/chlorine tablets 4 ; **filtered with water filter (candle, ceramic, sand, etc.) 5** ; cloth 6 ; others 9 ; not treated 7 | **electric purifier 1** (RO, UV) ; boiling 2 ; alum 3 ; bleach/chlorine 4 ; **non-electric purifier 5** (« activated carbon, sediment, ultra filtration ») ; cloth 6 ; others 9 ; not treated 7 |

Codes observés hors questionnaire (`11_nss_codes_observes.csv`) : rien au 69 ni au
76. Au 58 : distance code 8 (261 ménages), suffisance code 9 (14), et quatre
autres valeurs isolées. Valeurs vides : ≤ 41 par item, sauf la distance au 69
(948) et au 76 (619).

Autres items utiles, non détaillés ici : source supplémentaire (69 `b4_q11`,
76 `Supplementary_source_water`) ; qualité de l'eau (69 `b4_q9`, **non reprise au
76**) ; au 76 seulement, bénéfices de programmes publics d'eau potable
(`L04 Drinking_water_anybenefit`, `…_benefit_3yrs`, `…_scheme_max_benefi` :
NRDWP 1, AMRUT 2, Smart Cities 3).

## (b) IHDS-I (2004-05) et IHDS-II (2011-12)

Fichier ménage : IHDS-I `22626-0002-Data.rda` (objet `da22626.0002`, 41 554 × 945) ;
IHDS-II `36151-0002-Data.rda` (`da36151.0002`, 42 152 × 758). Le module eau est
dans le questionnaire Education-Health en IHDS-I (section EH9 5) et dans le
questionnaire multi-module en IHDS-II (EQ9 5).

| Concept | IHDS-I | IHDS-II |
| --- | --- | --- |
| Source, habituelle | `WA1` « What is the main source of water for drinking? » | `WA1A` « What is the main source of water for drinking in your house? » (normally) |
| Source, été | `WA4` « same in summer? » (0/1), puis `WA5` si non | `WA1B` posée à tous |
| codes source | Piped 01 ; Tube well 02 ; Hand pump 03 ; Dug, open well 04 ; Covered well 05 ; River, canal, stream 06 ; Pond 07 ; Tanker truck 08 ; Rainwater 09 ; Bottled 10 ; Other 11 | mêmes codes ; **01 devient « Piped (public supply) »** |
| Dans le logement | `WA2` « inside the house or compound? » No = 0, Yes = 1 | `WA2A`/`WA2B` « inside or outside? » **Outside = 1, Inside = 2** |
| Distance | `WA2A` minutes de marche, aller | `WA4A`/`WA4B` minutes de marche, aller |
| Suffisance | `WA7` « normally adequate? », `WA8` été ; No 0 / Yes 1 | `WA5A`, `WA5B` ; même libellé, mêmes codes |
| **Traitement** | `WA10` « During a normal week, do you ever treat or purify your drinking water by boiling the water OR by filtering the water with a purchased filter OR by using Aquaguard OR by adding chemicals? [DO NOT COUNT A CLOTH OR STRAINER] » | `WA7`, **libellé identique** |
| codes traitement | questionnaire : Never 0, Rarely 1, Usually 2, Always 3. **Données et codebook ICPSR : « (0) Rarely/Never, (1) Sometimes »** : contradiction non résolue | Never 1, Rarely 2, Usually 3, Always 4 |
| Accès / financement public-privé | absent | absent |

**Aucune des deux vagues ne relève la méthode de traitement** : l'item est une
fréquence d'un traitement quelconque, ébullition, filtre acheté, Aquaguard et
produits chimiques confondus. Attention aussi aux homonymes : `WA7` est la
suffisance en IHDS-I et le traitement en IHDS-II.

**Lien de panel.** Le fichier ICPSR d'IHDS-II ne contient **aucune** des variables
de lien décrites par le guide (`hhbase`, `hhid2005`, `hhsplitid2005`…), et le
fichier de suivi (ihds.umd.edu/panel2012.html) n'est pas téléchargé. Clé déduite
des données, à confirmer par ce fichier :
IHDS-II (`STATEID`, `DISTID`, `PSUID`, `HHID %/% 10`, `HHID %% 10`) =
IHDS-I (`STATEID`, `DISTID`, `PSUID`, `HHID`, `HHSPLITID`). `HHSPLITID` d'IHDS-II
est le numéro de scission 2012 (1 = ménage d'origine ; 2–6 = scissions ; 9 =
échantillon ajouté ou remplaçant). Résultat :
- les 40 018 ménages IHDS-II hors code 9 retrouvent tous un ménage IHDS-I ;
- 34 643 ménages IHDS-I sur 41 554 sont ré-enquêtés (83,4 %, le guide dit 83 %) ;
- 4 181 ménages IHDS-I se sont scindés.

2 108 des 2 134 ménages codés 9 tombent sur une clé IHDS-I. Ce sont des
remplaçants : **ils ne doivent pas être liés**. Les clés IHDS-I
(5 variables, et `IDHH`) et IHDS-II (5 variables, et `IDHH`, chaîne de 10
caractères) sont uniques.

## (c) Identifiants géographiques

| | 58e | 69e | 76e | IHDS-I | IHDS-II |
| --- | --- | --- | --- | --- | --- |
| État | `State` | `State_code` | `State` | `STATEID` | `STATEID` |
| Région NSS | `Region` (1 chiffre dans l'État) : 78 | `State_region` (3 chiffres) : 88 | `NSS_Region` (3 chiffres) : 88 | — | — |
| District | `District` (2 chiffres dans l'État) : 509 | `District` et `District_Code` (État + district) : 635 | `District` et `District_Code` (`DistrictCode` dans les autres fichiers) : 682 | `DISTID` (code IHDS) ; `DIST01` (district du recensement 2001) | `DISTID` ; `DIST01` ; `DISTRICT` (État + district 2001, étiqueté) |
| Urbain/rural | `Sector` 1/2 | `Sector` 1/2 | `Sector` 1/2 | `URBAN` (village/ville du recensement 2001) | `URBAN2011` |

Comparabilité entre rounds :
- **États** : mêmes codes de recensement partout. Mais au 76 le Telangana (36) est
  sorti de l'Andhra Pradesh (28) : AP 2018 ≠ AP 2002/2012.
- **Régions NSS : non comparables entre 58 et 69.** Elles ont été redessinées
  (78 → 88) et les codes réattribués. Exemple : l'AP a 4 régions au 58 et 5 au 69,
  et 281–284 ne couvrent pas les mêmes districts. Changent aussi J&K, Himachal
  Pradesh, Rajasthan, UP, Assam, Bengale occidental, Jharkhand et Chhattisgarh. Entre 69 et 76, le
  nombre de régions par État est identique hors AP/Telangana ; composition non
  vérifiée district par district. **L'idée de la feuille de route (« régions NSS,
  plus stables ») ne tient donc pas pour 58 → 69.**
- **Districts : non comparables comme codes.**
  - 58 et 69 partent tous deux de la base 2001, mais le 69 ajoute les districts
    créés depuis (509 → 635). Un code peut donc survivre sur un territoire amputé.
  - Au moins un code change de sens : Andaman 01 = « Andamans » au 58,
    « South Andaman » au 69.
  - Le 76 renumérote selon la base 2011 : Srikakulam = 11 au 58 et au 69, 01 au 76 ;
    Andaman 01 = Nicobars.
  - Toute comparaison demande une table de passage par noms vers une base fixe,
    à construire (les annexes « list of NSS regions » donnent noms et codes pour
    chaque round).
- **IHDS** : `DIST01` situe les deux vagues sur les districts 2001. Il est identique
  entre vagues pour 99,1 % des ménages liés. Pas de région NSS.

## (d) Effectifs et poids

| | Ménages (non pondéré) | Rural / urbain | Poids | Somme des poids | Contrôle |
| --- | --- | --- | --- | --- | --- |
| NSS 58 | 97 882 | 55 966 / 41 916 | `Wgt_Combined` | 206,6 M | effectif = rapport IHSN ; somme non confrontée à un chiffre officiel (Report 488 non téléchargé) |
| NSS 69 | 95 548 | 53 393 / 42 155 | `Combined_Weight` | 254,5 M | effectifs = Key Indicators, tableau 2.1 ; `Combined_Weight` = `MLT`/100 si `NSS = NSC`, sinon `MLT`/200, à l'identique |
| NSS 76 | 106 838 | 63 736 / 43 102 | `Multiplier` (déjà final, **ne pas diviser par 100**) | 271,1 M (178,38 + 92,72) | = Report 584, Statement 1, à l'unité près |
| IHDS-I | 41 554 | 26 734 / 14 820 (`URBAN`) | `SWEIGHT` | 192,1 M | = manifeste ICPSR |
| IHDS-II | 42 152 | — | `WT` (`FWT` = version entière) | 255,2 M | = manifeste ICPSR |

Au 58, `Wgt_SS` est le multiplicateur par sous-échantillon (somme 411 M, le double) ;
`WGT_posted` vaut 200 × `Wgt_Combined`. Au 69, les fichiers des blocs 2, 5, 6 et 7
ont 34 à 43 lignes de moins que le bloc eau ; au 76, `L06`–`L08` en ont 34 de
moins et `L09` 154 de plus. Sans effet sur le bloc eau, qui est complet dans les
trois rounds, mais à documenter avant toute jointure entre blocs.

## Points ouverts

1. Provenance des csv NSS (portail, date, version) : à compléter dans `raw/README.md`.
2. Fichier de suivi IHDS-I → IHDS-II, pour confirmer la clé de panel déduite ici.
3. Codes `WA10` d'IHDS-I : questionnaire (Never/Rarely) contre étiquettes ICPSR
   (Rarely-Never/Sometimes). À trancher sur la documentation d'origine NCAER.
4. Distance code 8 au 58 (261 ménages) : non documenté.

## Jugement : les variables de traitement et de source sont-elles comparables entre 2004-05, 2012 et 2018 sans faire violence aux libellés ?

**Non pour le traitement, et c'est la comparaison 2004-05 → 2012 qui casse.**

- **Traitement, 2004-05 → 2012 : cassé.** La seule mesure de 2004-05 (`WA10`
  d'IHDS-I) est une fréquence d'un traitement quelconque : ébullition, filtre
  acheté, Aquaguard et produits chimiques en une seule question. Elle ne dit pas
  *quelle* méthode. Le NSS 69 enregistre la méthode habituelle. Ce ne sont ni le
  même concept ni le même instrument, et le NSS n'a aucun item de traitement avant
  2012 (absent aux 58e et 65e). **Dans ces données, l'adoption du filtre ou du
  purificateur n'est donc observée ni avant le choc Pureit/Swach (2008-09), ni à
  aucune date par IHDS.** Seule reste comparable, dans IHDS-I → IHDS-II, « traite
  son eau habituellement ou toujours » (libellé identique, échelle décalée de 0–3
  à 1–4). Elle est dominée par l'ébullition et ne sépare pas le substitut privé.
- **Traitement, 2012 → 2018 : comparable seulement en agrégé.** « Appareil
  (codes 1 + 5) » passe ; la distinction électrique / non électrique ne passe pas.
  - Le code 1 passe de « electronic purifier », non défini au 69, à « electric
    purifier (RO, UV) » au 76.
  - Le code 5 passe de « water filter (candle, ceramic, sand) » à « non-electric
    purifier (activated carbon, sediment, UF) ».
  - Un purificateur à gravité de type Pureit ou Swach est ambigu en 2012 (1 ou 5).
    Un filtre à bougie n'a plus de case explicite en 2018 (5 ou 9).
  - Les deux points sont de toute façon postérieurs au choc.
- **Source : comparable en catégories regroupées.** Le regroupement
  canalisation / forage + pompe à main / puits / eaux de surface / autre passe sur
  2002, 2004-05, 2012 et 2018, avec deux réserves :
  - la définition de « principale » dérive (usage majeur au 58, fréquence au 69,
    volume au 76, « main » dans IHDS) ;
  - le libellé IHDS-II ajoute « (public supply) » à « Piped ».
  
  Le détail fin ne passe pas : bouteille, citerne, voisin et forage séparé de
  pompe à main n'ont de code propre qu'à partir du 69 ou du 76.
- **Source publique contre privée (financement) : 2012 et 2018 seulement.** Le
  code n'existe qu'au 69 et au 76 (libellé et consignes identiques), et seulement
  pour les sources communautaires. Ni le 58, ni le 65, ni IHDS ne l'ont. La
  variable de gauche « source publique contre privée » n'a donc pas non plus de
  point avant le choc.

En l'état, la piste C n'a de période « avant » ni pour le substitut privé
(méthode de traitement) ni pour le financement de la source. Les deux séries
exploitables sont (i) le panel IHDS sur « traite habituellement » et « eau
canalisée », et (ii) NSS 69 → 76 sur les appareils et le financement, qui est
une comparaison après/après. Au sens de CLAUDE.md, c'est un cas d'escalade au PI :
la mesure du choc sur le substitut privé manque avant 2012. Les sources
candidates pour un avant sur la méthode sont hors de cet inventaire et non
vérifiées ici : NFHS-3 (2005-06) et le Schedule 31 du 54e round (1998).

## Addendum (27/09) — NFHS-3, 4, 5 : la méthode de traitement avant le choc

Le jugement ci-dessus porte sur NSS et IHDS et reste vrai pour ces sources. NFHS-3
comble le trou qu'il signale. Sources : documentation publiée seulement, **aucune
donnée téléchargée** (accès DHS sur inscription). Documents lus :
- rapport final NFHS-3 (FRIND3, vol. I–II, questionnaire ménage en annexe) ;
- questionnaire ménage NFHS-4 (FR339.H, via Banque mondiale, catalogue 2949) ;
- rapports finaux NFHS-4 (FR339) et NFHS-5 (FR375, vol. I et II ; FR374, Kerala) ;
- manuels de recodage DHS-V et DHS-VII ;
- fiches IPUMS-DHS `TRFILTER`, `TRELECPUR` et `TRALUM`.

### (a–b) Items de traitement

| | NFHS-3 (nov. 2005 – août 2006) | NFHS-4 (janv. 2015 – déc. 2016) | NFHS-5 (juin 2019 – avr. 2021) |
| --- | --- | --- | --- |
| Filtre | Q37 « Do you treat your water in any way to make it safer to drink? » (oui / non / NSP) | Q29 « Does this household do anything to the water to make it safer to drink? » | même structure d'après les tableaux du rapport ; **libellé exact non vérifié** (questionnaire en ligne introuvable) |
| Méthode | Q38 « What do you usually do…? Anything else? RECORD ALL MENTIONED » | Q30, libellé identique à un mot près (« this household ») | idem |
| Codes | boil A ; **use alum B** ; bleach/chlorine C ; strain through cloth D ; **use water filter (ceramic/sand/composite/etc.) E** ; **use electronic purifier F** ; let it stand and settle G ; other X ; don't know Z | **identiques, mêmes lettres** | mêmes catégories, **plus « solar disinfection »** (catégorie standard DHS) |

Points à retenir :
- **Réponses multiples dans les trois vagues.** C'est le contraire du NSS, qui ne
  garde que le premier code applicable. Un ménage qui fait bouillir *et* filtre est
  compté dans les deux cases ; au NSS, il n'est compté que comme bouillant.
- **Recodage** : il y a une indicatrice 0/1 par méthode, `HV237A`–`Z`, sous le
  filtre `HV237`. Le filtre céramique/sable est le code standard (`HV237D`, noté
  `TRFILTER` chez IPUMS). **L'alun et le purificateur électronique sont des codes
  propres au pays**, rangés dans l'une des cases `HV237G`–`K`. Laquelle, seul le
  `.MAP` du fichier indien le dit, et il vient avec les données.
  - IPUMS-DHS les harmonise (`TRALUM`, `TRELECPUR`) pour l'Inde 1998, 2005, 2015 et
    2019, et signale que le libellé du purificateur varie légèrement d'une vague à
    l'autre, sans détail.
  - Le rapport NFHS-4 écrit « electric purifier », mais son questionnaire dit
    « electronic ».
- **Où tombe un Pureit ou un Swach ?** Aucune définition dans les questionnaires.
  Un purificateur à gravité peut être codé E (filtre) ou F (« electronic ») par
  l'enquêteur, et une unité RO/UV va en F. **Comparable entre vagues : « appareil »
  = E ou F.** La répartition E/F d'un Pureit n'est pas identifiée, comme au NSS 69.
- **L'avant n'est pas propre partout.** Pureit est lancé à Chennai en 2005 puis
  dans le Sud. Les États du Sud ont été enquêtés entre fin 2005 et mi-2006, donc
  la date 2005-06 n'est pas un « avant » pur pour eux (TN, AP, Karnataka, Kerala).
- **Une seconde période pré-choc existe peut-être** : IPUMS liste l'Inde 1998
  (NFHS-2) pour les trois variables. Elle permettrait de regarder une pré-tendance
  1998 → 2005. Libellé NFHS-2 non vérifié.

### (c) Unités géographiques et tailles d'échantillon

| | NFHS-3 | NFHS-4 | NFHS-5 |
| --- | --- | --- | --- |
| Ménages | 109 041 | 601 509 | 636 699 (rapport) ; 636 669 (fiche DHS) : écart à éclaircir |
| État | `HV024`, 29 États (Delhi et Goa compris, pas les autres UT) | 29 États + 7 UT | 28 États + 8 UT (Telangana séparé ; J&K et Ladakh) |
| District | **absent** | 640 districts (recensement 2011), 38–44 UPE par district, soit ~940 ménages | 707 districts (au 31/03/2017) |
| Urbain/rural | `HV025` | oui | oui |
| Grappe | `HV001` ; les UPE ne sont pas les mêmes d'une vague à l'autre | oui | oui |
| GPS | non | oui (« GPS/georeferenced ») | oui |

Pour le GPS, la fiche DHS le signale. Les coordonnées sont brouillées selon la
règle générale DHS : 0–2 km en ville, 0–5 km à la campagne, jusqu'à 10 km pour 1 %
des grappes rurales.

**Tailles par État en NFHS-3** (rapport, tableau 1.2 ; la somme refait 109 041) :
de 1 513 (Mizoram) à 10 026 (Uttar Pradesh), médiane 3 216, quartiles 2 483 et
3 910. Les États suréchantillonnés pour le VIH (AP, Karnataka, Maharashtra,
Manipur, Nagaland, TN) et l'UP sont en haut de la distribution. Erreur d'échantillonnage
d'une part d'État, avec un effet de plan supposé de 2 : pour une part de 10 %,
±1,1 point dans le plus petit État et ±0,75 point à la médiane.

NFHS-4 : ~940 ménages par district, donc les États vont d'environ un millier (petites
UT) à plusieurs dizaines de milliers. Le tableau par État du rapport ne s'extrait
pas proprement et n'est pas recopié ici.

### Ce qu'une comparaison par État 2005-06 → 2015-16 permettrait, ou non, d'identifier

Le cadre : environ 29 unités (États de NFHS-3, NFHS-4 remis dans les frontières de
2005 : Telangana réintégré dans l'AP, UT exclues), deux dates, donc une différence
longue par État.

**Ce qu'elle peut donner.** Une description propre : la hausse de l'adoption
d'appareils (E ou F) entre 2005-06 et 2015-16, État par État, avec un point de départ
antérieur au lancement national (sauf dans le Sud). Si NFHS-2 tient, une
pré-tendance 1998 → 2005 sur le même indicateur, qui permet de montrer les
trajectoires avant toute estimation.

**Ce qu'elle ne peut pas donner :**

1. **Pas de variation du coût du substitut privé entre États.** Le choc est une
   date nationale, à prix national : Swach à moins de 1 000 ₹ partout. Deux dates
   et des effets fixes d'État ne laissent que des différences de *dose*. Toute dose
   observable ici (revenu, électrification, pour le RO, part non raccordée, qualité
   de l'eau) est une variable de **demande**, précisément ce que la règle d'analyse
   exclut. La seule variation de coût visible, la diffusion précoce dans le Sud,
   contamine la période « avant » de 4 États au lieu de fournir un traitement
   propre.
2. **Puissance.** Avec 29 unités, un test bilatéral à 5 % et une puissance de 80 %
   ne détectent qu'une corrélation d'au moins **0,50** entre la variation
   d'adoption et la variation de la provision publique. C'est 25 % de la variance
   entre États, qu'il faudrait attribuer au mécanisme. Avec 2 contrôles le seuil
   passe à 0,52, avec 4 à 0,54. Découper par État × urbain/rural (58 cellules)
   l'abaisserait à 0,36 en théorie, mais les cellules d'un même État partagent
   leurs chocs : l'inférence reste à 29 grappes, avec bootstrap sauvage.
3. **Confusion contemporaine à l'échelle de l'État.** La JNNURM (déc. 2005 – 2014)
   et le programme rural d'eau potable ont investi dans les réseaux avec une
   intensité qui varie d'un État à l'autre dans la même fenêtre. La croissance du
   revenu pousse à la fois l'achat d'appareils et le raccordement. Avec 29
   observations, on ne peut en contrôler que deux ou trois, et le revenu est
   post-traitement.
4. **La variable de gauche n'est pas au même endroit.** NFHS mesure l'accès du
   ménage (eau canalisée dans le logement, robinet public), pas le financement
   public ou privé de la source, qui n'existe qu'au NSS 69/76 (2012, 2018). Les
   dates ne s'emboîtent pas : NFHS 2005-06/2015-16, recensement 2001/2011, NSS
   2012/2018.
5. **Rien sous l'État en 2005-06.** Pas de district, et des grappes différentes à
   chaque vague : pas de panel de lieux. La maille district et le GPS n'arrivent
   qu'avec NFHS-4, donc après le choc.

**Bilan de puissance.** À 29 unités, le design ne peut conclure que si le
mécanisme explique au moins un quart de la variance des évolutions entre États.
Même dans ce cas, il ne sépare pas le piège de la demande commune (revenu,
électrification) ni des investissements publics de la même période. Un résultat
nul n'y serait pas informatif. Un résultat positif ne serait pas causal sans une
source de variation du coût du dispositif entre États, que ces données ne montrent
pas.
