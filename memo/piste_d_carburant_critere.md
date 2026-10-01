# Piste D — variation idiosyncratique des prix des carburants : critère

Statut : PROPOSITION

> Le script `code/13_giz_prix_carburant.R` refuse d'exécuter la section 13c
> (variation dans les fenêtres DHS) tant que la ligne ci-dessus ne se lit pas
> exactement `Statut : FIXÉ`. Les seuils sont lus dans ce fichier (lignes
> `SEUIL_...` en police fixe) : les modifier ici suffit, le script n'en a pas
> de copie.

30/09/2026. Rédigé par Claude à la demande de Valentine, **avant tout calcul de
la variation nette**. Les seuils sont des propositions à trancher par Valentine.

## Objet

Décision du 30/09 : le prix du diesel déplace aussi le coût du côté public
(pompage des régies, groupes électrogènes). C'est le cas interdit par la règle
« la variation doit déplacer le coût du substitut **privé** ». La série GIZ ne
sert donc **pas** de décaleur de coût. Elle sert à **mesurer** combien de
variation propre à chaque pays existe entre deux vagues DHS pour les six cas
retenus à l'étape 12 (`output/tables/12_substituts_delta.csv`, `retenu == TRUE`).
Si cette variation nette est faible, toute la voie « prix des carburants » est
close et on le dit.

Aucune mesure d'exposition, aucune interaction, aucune estimation.

## Ce qui a été vu avant la rédaction (transparence)

- Session du 30/09, reconnaissance des sources : les prix bruts du diesel en
  US$ de l'archive WDI pour les six pays (1991–2016) ont été affichés lors d'un
  test de l'API. **Aucune valeur nette de la moyenne annuelle n'a été calculée.**
- Aucune valeur du fichier GIZ/TUMI n'a été vue (fichier pas encore déposé).
- Base mensuelle Banque mondiale (déc. 2015 – avr. 2025) : les séries diesel en
  monnaie locale des six pays ont été profilées (nombre de changements, plus
  grands sauts). Elle ne sert pas au calcul ci-dessous.

## Définitions

- **Série** : diesel, prix de détail en US$ par litre, en logarithme. Source
  principale : fichier GIZ/TUMI (`raw/giz/`). Contrôle : archive WDI,
  version 202407 (`raw/wdi_archive/`). L'essence est rapportée, sans rôle dans
  le verdict.
- **Date d'un relevé** : le relevé GIZ de l'année Y est daté au 15 novembre Y
  (enquête « mid-November »). Les relevés antérieurs à 1998 ont une année
  ambiguë (le WDI dit 1992, le rapport GIZ 1999 dit 1993) : signalés dans le
  journal des lacunes, conservés tels quels.
- **Moyenne annuelle** : moyenne du log-prix sur tous les pays observés à ce
  relevé dans la même source (agrégats régionaux exclus).
  **Écart net** : r(c,t) = log p(c,t) − moyenne(t).
- **Fenêtre d'un cas** : du début de terrain de la première vague DHS au fin de
  terrain de la dernière (vagues où le substitut est observé, étape 12).
  Dates de terrain : API DHS (`FieldworkStart`, `FieldworkEnd`).
- **Relevé entre deux vagues** : strictement après la fin de terrain de la
  vague k et strictement avant le début de terrain de la vague k+1.

## Mesures (par cas, sur la fenêtre)

- **M1** : écart-type de r(c,t) sur les relevés de la fenêtre.
- **M2** : plus grande variation absolue de r(c,t) entre deux relevés
  consécutifs observés, le second tombant **entre deux vagues**. L'écart en
  années entre les deux relevés est rapporté (un relevé manquant allonge
  l'intervalle).

## Critère (propositions)

Un cas **passe** si M1 et M2 atteignent les deux seuils :

- `SEUIL_SD_NET = 0.10`   (écart-type net de 0,10 log, soit environ 10 %)
- `SEUIL_SAUT_NET = 0.20` (un saut net d'au moins 0,20 log, environ 22 %, entre deux relevés)

La voie « prix des carburants » est **close** si moins de `MIN_CAS = 2` cas
passent sur six.

Justification des propositions : l'écart net moyen sert de décaleur seulement
s'il dépasse le bruit de change et de calendrier ; 10 % d'écart-type et un
saut de 20 % en deux ans sont des mouvements qu'on verrait à l'œil sur un
graphique de trajectoire. Une alternative serait un seuil relatif (M1 au-dessus
de la médiane de tous les pays) : à choisir maintenant, pas après.

## Stabilité (déclarée d'avance)

Le verdict est calculé sur quatre combinaisons : source GIZ/TUMI ou WDI
(chacune sur ses propres relevés ; le WDI s'arrête en 2016) × moyenne sur tous
les pays ou sur le panel équilibré de la fenêtre (pays observés à tous les
relevés de la fenêtre où le pays du cas est lui-même observé, dans cette
source ; sans cette restriction Haïti, qui manque en 2006 et 2010, sortirait
de son propre panel — corrigé le 30/09 après un test sur prix aléatoires,
avant tout calcul sur les vrais prix). Si le verdict
diffère entre ces combinaisons, il est rapporté **instable**, sans en choisir
une.

## Limite connue

Les prix sont en US$ : une dévaluation compte comme variation propre au pays.
Elle n'est pas séparable ici (le WDI n'a pas de monnaie locale ; celle du
fichier TUMI est à vérifier). Brut et net sont rapportés côte à côte.
