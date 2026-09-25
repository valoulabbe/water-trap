# Piste A — verdict de la porte du premier stage (Andhra Pradesh)

24/09/2026. Critère : `memo/piste_a_premier_stage_critere.md` (commits 07a1e23
et 904389c, antérieurs à l'exécution). Chiffres : `output/logs/10_piste_a_premier_stage_ap.log`,
`output/tables/10_*.csv`.

## Verdict : ÉCHOUE

| Condition | Seuil | Obtenu | |
| --- | --- | --- | --- |
| 1. Part intra-district de la variance de profondeur | ≥ 0,25 | **0,849** | remplie |
| 2. Gain de R² hors échantillon du bloc géologie (plis = districts) | ≥ 0,05 | **−0,006** | **non remplie** |

Les deux conditions sont requises, donc la porte échoue. Il y a beaucoup de
variation de profondeur à expliquer au sein des districts (85 %), mais les
classes géologiques du socle n'en prédisent rien hors échantillon. Le R²
intra-district hors échantillon vaut 0,033 avec les seuls contrôles et 0,027
avec la géologie en plus : ajouter la géologie dégrade légèrement la prédiction.

**Au sens du critère, la piste A n'est pas viable comme IV sur ces données :
socle de l'AP, carte GSI au 1:2M, puits CGWB 1996–2000.**

## Magnitudes

- **Échantillon :** 825 puits, 23 districts (843 puits de socle hors khondalite,
  moins 18 sans contrôle de sol). Profondeur de mai : moyenne 7,8 m, écart-type
  3,9 m.
- **Sur tout l'échantillon** (hors critère, pour information) : F partiel groupé
  du bloc géologie = 12,3 (9 ddl, p < 0,001). Il repose sur deux classes :
  - calcaire (Kurnool/Cuddapah) : **+1,2 m** par rapport au granite (52 puits) ;
  - grès consolidé : **−1,7 m** (5 puits seulement).

  Granite et gneiss, qui font 77 % de l'échantillon, ne diffèrent pas
  (−0,5 m, non significatif). Les écarts entre classes sont d'environ 1 m pour
  un écart-type de 3,9 m : visibles dans l'échantillon, mais ils ne se
  transportent pas d'un district à l'autre. Un F élevé sans pouvoir prédictif
  hors échantillon, c'est exactement le cas que le critère devait écarter.

## Hors critère : classes du socle et économie locale en 1991

19 897 villages de l'AP dont le centroïde est dans une classe du socle (hors
khondalite). Chaque caractéristique est régressée sur les classes (référence :
granite) avec effets fixes de district et erreurs groupées par district.

| Caractéristique (1991) | Test joint des classes | R² intra dû aux classes |
| --- | --- | --- |
| log population | F = 10,7, p < 0,001 | 0,022 |
| taux d'alphabétisation | F = 5,3, p < 0,001 | 0,014 |
| part ST (proxy des Scheduled Areas) | F = 2,7, p = 0,028 | 0,053 |
| distance à la ville | F = 6,1, p < 0,001 | 0,042 |
| part irriguée par canal | F = 2,1, p = 0,085 | 0,001 |

Le motif est cohérent. Par rapport au granite, les villages sur charnockite,
quartzite, intrusifs et schistes argileux sont :
- plus petits (log population : −0,7 à −0,8) ;
- plus éloignés d'une ville (+8 à +19 km) ;
- plus peuplés de ST (+0,2 à +0,33 de part) ;
- moins alphabétisés.

Ce sont les zones de collines et de forêt. **Même si le premier stage était
passé, la restriction d'exclusion serait en difficulté** : au sein même des
districts, les classes du socle recoupent l'éloignement et la composition
tribale, qui pèsent directement sur la provision publique.

## Réserves (aucune ne renverse le verdict)

- **Altitude :** 104 des 843 puits ont une altitude CartoDEM négative, ce qui
  est impossible dans le socle de l'AP. Il s'agit probablement de vides ou d'un
  décalage dans certaines tuiles. Un contrôle faussé laisse plus de variation
  à la géologie, ce qui pousse vers un passage à tort, pas vers un échec à tort.
  Non corrigé, conformément à la règle de périmètre de cette session.
- **Irrigation par canal :** mesure bruitée. La surface irriguée est rapportée
  à la surface PCA 1991 ; 13 villages sur 17 154 dépassent 1, jusqu'à 733,8.
  Ces valeurs aberrantes expliquent les gros coefficients non significatifs ;
  ne pas en tirer de conclusion.
- **Scheduled Areas :** absentes de SHRUG ; la part ST est un proxy.
- **Portée :** ce test porte sur la carte au 1:2M et le recodage en classes.
  Il ne dit rien d'une couche lithologique fine ni des fractures, volontairement
  hors périmètre. Changer de couche pour « sauver » la piste serait une variante
  discutée après le verdict.

## Non poursuivi (piste A close le 25/09/2026)

Variantes envisageables, consignées ici et **pas exécutées**. Chacune serait
une variante discutée après le verdict :
- **Lithologie au 1:50k (NGDR) ou lignes de fractures (GSI Bhukosh).** Un
  premier stage peut-être meilleur, mais le diagnostic d'exclusion ne dépend
  pas de l'échelle : collines, forêt et part ST suivent le terrain de socle
  lui-même.
- **Autres États de socle** (Karnataka, Tamil Nadu, Odisha) : même objection
  sur l'exclusion.
- **Bloc géologie au niveau des 54 unités** plutôt que des classes : beaucoup
  de cellules de moins de 10 puits, et c'est une recherche de spécification.
- **Correction des altitudes CartoDEM négatives** (104 puits) : biais attendu
  vers le passage, pas vers l'échec.
- **Contraste alluvions/roche** : exclu d'avance par le critère, car il porte
  le clivage économique delta/plateau.
- **Différence de différences géologie × choc temporel** (diffusion des pompes
  submersibles, électrification rurale ; ROADMAP) : un autre design, qui
  hériterait du même problème d'exclusion tant que le choc n'est pas propre au
  coût de l'eau.

## Arrêt

Pas de second stage, pas de variable de résultat.
