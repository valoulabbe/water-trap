# Piste C — recul de la série du purificateur à 1998 (décision du 06/10/2026)

## Verdict contre le critère écrit, puis décision

- **Verdict du critère du point 1 (script 26, commit `e45f89e`) : FAUSSE.**
  Il est conservé tel quel dans `output/logs/26_piste_c_questionnaire_districts.log`
  et dans `output/tables/26_point1_synthese.csv`.
- **Décision de Valentine (06/10) : le recul à 1998 TIENT pour la série
  urbaine.** Le verdict FAUSSE ne porte aucune information sur les données,
  parce que **le critère était mal spécifié par Valentine** : il décomposait
  un écart qui n'existe pas en ville.
- **C'est la deuxième fois sur cette piste qu'un critère est mal spécifié.**
  La première était le repère « 16,7 % / 3,3 % » de l'attente A4 du script 24,
  rapporté à un mauvais dénominateur et remplacé par le repère officiel du
  Bihar urbain (commit `9916fa0`). Cette décision est consignée pour être
  visible, pas lissée.

## La prémisse fausse

Le critère partait d'un écart de 7,7 points dans la part des ménages ne
déclarant aucune méthode : 62,5 % en 1998 contre 54,8 % en 2005. Ce chiffre
était **non pondéré**. Il sortait de `25_etape0_structure_reponses.csv`, et
le résumé du script 25 l'avait repris sans le préciser ; c'est la part de
l'assistant dans l'erreur. Il reflète surtout la composition de
l'échantillon : le NFHS-3 surreprésente les villes.

Une fois pondéré (script 26), l'écart de la part des ménages déclarant au
moins une méthode est :

| Domaine | 1998-99 | 2005-06 | Écart |
| --- | --- | --- | --- |
| Urbain | 49,6 % | 49,0 % | −0,6 point |
| National | 31,6 % | 34,4 % | +2,8 points |

- **En ville, il n'y a pas d'écart à décomposer.** Le critère lui-même
  déclarait non interprétable un écart inférieur à 2 points.
- **Le verdict FAUSSE vient du seul national.** Là, l'écart reste de
  2,8 points, et le purificateur en absorbe 26 %. Or ce chiffre mélange
  diffusion réelle et effet de questionnaire, confusion écrite d'avance dans
  l'en-tête du script 26.
- **Le national n'est pas le terrain de la piste, qui est urbaine.**

## Ce que la décision engage

- **La série fine du purificateur commence en 1998-99 pour l'urbain** :
  1,16 % (1998-99), 3,38 %, 11,05 % puis 12,82 %.
- **Le national et le rural restent sans décision de recul.** On ne s'appuie
  pas sur leur point de 1998.

### Limite qui demeure

En ville, la part totale déclarée ne bouge pas, mais la composition des
méthodes, elle, change :

| Méthode (urbain) | 1998 → 2005 |
| --- | --- |
| Tissu | −6,0 points |
| Ébullition | +2,4 points |
| Chlore (nouveau en 2005) | +2,2 points |
| Filtre | −1,3 point |
| Purificateur | +2,2 points |

Une partie de ces mouvements peut venir du changement de liste de modalités.
Pour le purificateur, ni le test du point 1 ni aucun autre ne peut séparer la
diffusion de l'effet de questionnaire.
