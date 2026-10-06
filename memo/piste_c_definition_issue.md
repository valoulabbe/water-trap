# Piste C — définition de l'issue (décision du 06/10/2026)

Statut : **décision écrite et commitée avant toute construction.** Aucune
variable d’issue n’existe encore dans le dépôt. Les deux cas d’abord marqués
AMBIGU ont été **tranchés par Valentine le 06/10** (section « Cas tranchés »),
selon les recommandations ci-dessous, chacun avec sa variante de robustesse.

## Décision

**L'issue est le raccordement au réseau public, quelle qu'en soit la forme** :
eau courante dans le logement, dans la cour, ou borne publique, regroupés en
une seule catégorie « réseau ». Le reste est « hors réseau ». Ce n'est **pas**
l'eau courante dans le logement.

## Raison

C'est la seule frontière qui ne bouge pas avec les ruptures de codage de
`hv201` déjà repérées (scripts 24 et 25) :

- 1998 : logement et cour réunis dans un seul code (11) ;
- borne publique codée 12 (1998), 13 (2005, 2015), 14 (2019-21) ;
- 2019-21 : le code 13 devient « piped to neighbor ».

La distinction fine logement / cour / borne n'est pas comparable sur vingt ans.
C'est le type de rupture qui a fait tomber la piste D.

## Codes de chaque côté, par vague

Table complète, avec libellés exacts : `code/ref/piste_c_hv201_reseau.csv`.
Les codes « titre » (10, 20, 30, 40) n'ont aucune observation.

| Vague | Réseau | Hors réseau | Variante de robustesse |
| --- | --- | --- | --- |
| NFHS-2 1998-99 | 11, 12 | 21–26, 31–34, 41, 51, 96 | — |
| NFHS-3 2005-06 | 11, 12, 13 | 21, 31, 32, 41–43, 51, 61, 62, 71, 96 | — |
| NFHS-4 2015-16 | 11, 12, 13 | 21, 31, 32, 41–43, 51, 61, 62, **72**, 71, 96 | 72 exclu |
| NFHS-5 2019-21 | 11, 12, **13**, 14 | 21, 31, 32, 41–43, 51, 61, 62, 71, **92**, 96 | 13 hors réseau ; 92 exclu |

La colonne `cote_variante` de la table porte la variante.

## Cas tranchés (décision de Valentine, 06/10/2026)

- **« Piped to neighbor » (NFHS-5, 13) : côté réseau.** Variante de
  robustesse : hors réseau.
- **Usine RO communautaire (NFHS-4, 72 ; NFHS-5, 92) : hors réseau.**
  Variante de robustesse : ménages exclus de l’échantillon.

Les deux variantes sont rapportées à côté du résultat principal ; une
instabilité entre les deux est un signal à rapporter, pas à résoudre.

La discussion qui a motivé ces choix est conservée ci-dessous.

## Discussion des cas d’abord ambigus

### « Piped to neighbor » (NFHS-5, code 13)

- **Pour le côté réseau.** L'eau vient du réseau public. La définition dit
  « quelle qu'en soit la forme ». Un ménage qui puise au robinet du voisin
  dépend du réseau autant qu'un ménage qui va à la borne.
- **Pour le côté hors réseau.** Le ménage n'a pas de raccordement à lui. Pour
  le mécanisme exit/voice, ce qui compte est le ménage abonné, et celui-ci
  n'est pas abonné.
- **Ce qui décide en pratique : la comparabilité.** Le code n'existe qu'en
  2019-21. Avant, ces ménages se déclaraient ailleurs : probablement dans
  « cour » ou « borne publique » (côté réseau), possiblement dans « autre »
  (hors réseau). On ne peut pas le vérifier. Si la plupart se déclaraient
  côté réseau, les classer hors réseau en 2019-21 crée une baisse
  artificielle du raccordement à la dernière vague, au moment même où le
  purificateur se diffuse.
- Recommandation, retenue le 06/10 : côté réseau, avec une variante hors
  réseau rapportée à côté.

### Usine RO communautaire (NFHS-4 code 72, NFHS-5 code 92)

- **Elle est hors réseau par nature** : l'eau est puisée et transportée.
  Elle est pourtant souvent publique (panchayat, municipalité) ou associative.
- **Elle porte le même mécanisme que la piste C.** C'est un substitut à la
  qualité du réseau, comme le purificateur, mais collectif. La classer côté
  réseau mélangerait le substitut et l'issue.
- **Comparabilité.** Le code apparaît en 2015-16. Avant, ces ménages se
  déclaraient probablement « borne publique » (réseau) ou « forage » (hors
  réseau). Le sens de la rupture est inconnu.
- Recommandation, retenue le 06/10 : hors réseau, conformément à la
  définition, avec une variante qui exclut ces ménages de l’échantillon.

### Autres cas, signalés et non ambigus au sens de la définition

- **Camion-citerne (51 en 1998, 61 ensuite).** Souvent municipal, donc public,
  mais hors réseau. Le code existe à toutes les vagues : pas d'effet de
  rupture.
- **Pompes et puits publics de 1998 (22, 25, 26).** Publics mais hors réseau.
  « Public » n'est pas « réseau ».
- **Autre (96).** Résiduel. Il peut cacher une forme de réseau, ce qui n'est
  pas vérifiable.

## Limite principale : `hv201` est la source d'eau de BOISSON

L'issue mesure la source de l'eau bue, pas le raccordement. Un ménage
raccordé qui boit de l'eau en bouteille ou de l'eau d'une usine RO tombe hors
réseau, alors que son raccordement existe. C'était le premier échec de la
piste D (réallocation).

`hv202` (source hors boisson) est vide en 1998, 2015-16 et 2019-21. La
correction n'est donc possible qu'en 2005-06.

Ce biais épargne le purificateur : un ménage équipé d'un purificateur
traite l’eau du robinet, donc continue de déclarer le réseau. Il touche en
revanche l’eau en bouteille et les usines RO, deux substituts privés ou
collectifs concurrents.

## Ce qui n'est pas fait

Aucune variable n'est construite et aucune part n'est calculée. La table
`code/ref/piste_c_hv201_reseau.csv` est contrôlée contre les libellés
observés par le script 27 (couverture et libellés exacts seulement).
