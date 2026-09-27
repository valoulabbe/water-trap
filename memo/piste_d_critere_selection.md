# Piste D — critère de sélection des cas (fixé avant tout graphique)

27/09/2026. Critère donné par Valentine avant l'écriture du script
`code/12_dhs_api_inventaire.R`. Recopié ici avant toute exécution ; les seuils du
script en sont la copie. Les précisions opérationnelles ci-dessous sont celles
de Claude, écrites au même moment, avant lecture des données.

## Règle

Un cas (pays × substitut privé) est retenu sur le **côté privé et la couverture
des données seulement**. La provision publique ne joue **aucun** rôle dans la
sélection.

1. Variation du substitut privé d'**au moins 20 points** entre la première et la
   dernière vague DHS.
2. **Au moins 4 vagues DHS.**
3. **Au moins 2 vagues avant le décollage**, le décollage étant la première vague
   où le substitut dépasse 10 points : une période « avant » doit exister.

Les cas retenus sont classés selon ces trois critères, le classement est
rapporté, puis tout est tracé en une seule passe.

## Précisions opérationnelles

- **Vague DHS** : enquête de type `SurveyType == "DHS"` dans l'API
  (MIS, AIS et autres exclues), pour laquelle l'indicateur du substitut a une
  valeur publiée au niveau national. Une vague sans valeur pour cet indicateur
  ne compte pas.
- **Première et dernière vague** : première et dernière vague DHS où le
  substitut est observé. Variation = dernière − première, en points de
  pourcentage ; seule une hausse de 20 points ou plus qualifie.
- **Décollage** : première vague observée où la valeur est **strictement
  supérieure à 10**. Vagues « avant » = vagues observées antérieures au
  décollage (donc toutes ≤ 10). Si la première vague observée dépasse déjà 10,
  il n'y a aucune vague avant : le cas échoue au critère 3.
- **Substituts examinés** : bouteille `WS_SRCE_H_BOT`, sachet `_SCH`,
  vendeur `_VND`, citerne `_TNK`, forage `_TUB`, filtre `WS_WTRT_H_CER`. Même
  règle pour tous. Libellés d'interprétation, sans effet sur la sélection :
  - `_TUB` = « forage, propriété inconnue », pas adoption privée : la DHS ne
    distingue pas forage privé et forage communautaire ou financé par un
    bailleur (même ambiguïté que `private_gw` en Inde) ;
  - `_TNK` = « citerne, opérateur inconnu » : la DHS ne distingue pas citerne
    publique et privée (le NSS indien les sépare) ;
  - `_SCH` et `_VND` : trop peu de pays pour former une famille (2 et 1 pays à
    3 vagues ou plus) ; un cas éventuel est un cas isolé.
- **Classement** : lexicographique, dans l'ordre des critères — variation
  (décroissante), puis nombre de vagues DHS, puis nombre de vagues avant
  décollage.
