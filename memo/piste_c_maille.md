# Piste C — maille géographique commune aux quatre vagues (06/10/2026)

## Décision

La maille retenue est **l'État de 1998 croisé urbain / rural** : 26 États au
NFHS-2, soit 52 cellules par vague. Les États scindés depuis sont regroupés
avec leur État d'origine :

- Bihar avec le Jharkhand ;
- Madhya Pradesh avec le Chhattisgarh ;
- Uttar Pradesh avec l'Uttarakhand ;
- Andhra Pradesh avec le Telangana ;
- Jammu-et-Cachemire avec le Ladakh.

Les territoires de l'Union non enquêtés en 1998 sont hors maille. Table de
jugement : `code/ref/piste_c_etats_1998.csv`.

Si l'on revient un jour à une maille plus fine, ce sera **par le code
district du NFHS lui-même**, sur les vagues qui en ont un, et **pas par
SHRUG**.

La vérification B (script 28) dit si cette maille a assez d'effectif pour
identifier quoi que ce soit. Son verdict est ajouté en fin de mémo.

## Deux constats distincts sur la maille district

### (i) Pas de maille district sur les quatre vagues : le NFHS-3 n'a pas de district

**La maille district sur les QUATRE vagues était exclue avant cette séance.**
Le Household Recode du NFHS-3 (2005-06) ne porte aucune variable de district :
attente C3 du script 26, vérifiée sur le dictionnaire complet.

C'est la raison principale. Elle ne dépend pas de SHRUG.

### (ii) Une limite en plus pour un raccord district 1998 / 2015 / 2019 par SHRUG

Les clés SHRUG shrid → district ne sont pas uniques (script 28). Une fois le
décompte fait en ménages (PCA au shrid) et non en shrids :

| Clé | Shrids en double | Ménages concernés | Part des ménages |
| --- | --- | --- | --- |
| 1991 | 30 | 1 016 902 | 0,69 % |
| 2011 | 108 | 6 763 967 | 2,71 % |

**Ce qui a été observé :**

- **Delhi (clé 2011, État 07).** Un shrid unique couvre 3 435 999 ménages,
  soit **100 % de l'État**, et il est rattaché à plusieurs districts.
- **Maharashtra (clé 2011, État 27).** Un shrid unique de 2 779 943 ménages
  (11,4 % de l'État) est à cheval sur deux districts. C'est vraisemblablement
  Mumbai, entre les districts de Mumbai et de Mumbai Suburban ; l'identité
  du shrid n'a pas été vérifiée par son nom.
- **Clé 1991, État 23.** Sept shrids comptent 806 488 ménages, soit 7,1 % de
  l'État.

Avec ces fichiers, SHRUG ne permet donc pas de répartir Delhi ni ce shrid du
Maharashtra entre districts. **Rien n'est affirmé sur les autres grandes
villes** : on n'a pas regardé si c'est un cas général.

Aucun doublon ne relie deux États. Au niveau de l'État, ces doublons ne
changent rien : c'est l'option (a), décidée par Valentine le 06/10.

## Vérification A : continuité des frontières (script 28)

- **Correspondance des codes.** Les codes d'État du NFHS-2 sont propres à
  cette vague. Ceux du NFHS-3 et du NFHS-5 sont les codes du recensement
  (attente E4). Le NFHS-4 numérote les États par ordre alphabétique. Le
  raccord passe donc par la table des noms (attente E1).
- **Scissions de 2000 (SHRUG, recensements 1991 → 2011).** Elles se font en
  districts entiers : chaque district de 1991 tombe à 100 % dans un seul État
  de 2011, ou à 99,95 % pour le Madhya Pradesh et le Chhattisgarh. Aucun
  autre État de 1991 n'a plus d'une destination en 2011, et il n'y a aucun
  flux résiduel.
- **Telangana (2014).** En NFHS-4, ses 10 districts sont tous dans l'Andhra
  Pradesh de 2011. En NFHS-5, ses 31 districts portent un code postérieur à
  2011 : le test est remplacé par celui du NFHS-4. C'est un **appui sur une
  connaissance extérieure**, non vérifiée dans ces données : le Telangana a
  été créé en 2014 par séparation d'avec l'Andhra Pradesh (Andhra Pradesh
  Reorganisation Act, 2014), et le redécoupage de 2016 est interne au
  Telangana. La frontière entre les deux États n'a donc pas bougé entre
  2015-16 et 2019-21. Décision de Valentine, 06/10.
- **Ladakh (2019).** Testé en NFHS-5 (résultat dans le log du script 28).

**Autres discontinuités signalées :**

- **Jammu-et-Cachemire en 1998.** Le libellé du NFHS-2 est « jammu » : la
  couverture du Cachemire et du Ladakh n'est pas vérifiée. Le recensement de
  1991 n'ayant pas eu lieu dans cet État, SHRUG ne permet pas non plus de
  vérifier sa frontière.
- **Dadra-et-Nagar-Haveli et Daman-et-Diu.** Fusionnés en 2020, hors maille
  dans tous les cas.
- **Mandals du Khammam (2014).** Quelques sous-districts sont passés à
  l'Andhra Pradesh. Ce transfert est invisible au niveau du district, et le
  regroupement Andhra Pradesh + Telangana l'absorbe.

## Verdict de la vérification B (script 28, seuil écrit avant exécution)

**Critère, écrit avant exécution.** Une cellule est exploitable si elle
compte au moins 300 ménages et au moins 15 grappes. Un État est utilisable
si sa cellule urbaine est exploitable dans les quatre vagues. La maille
tient si au moins 20 des 26 États sont utilisables.

**Verdict : la maille TIENT, mais à la limite exacte : 20 États
utilisables sur 26, sans aucune marge.**

- 199 cellules exploitables sur 208. En urbain : 98 sur 104 (1998-99 : 20 ;
  2005-06, 2015-16 et 2019-21 : 26).
- Les 6 États non utilisables échouent tous sur la seule vague de 1998-99,
  en urbain : Arunachal Pradesh (174 ménages / 6 grappes), Sikkim (164 / 5),
  Nagaland (237 / 9), Tripura (251 / 8), Meghalaya (256 / 9) et Manipur
  (536 / 14).
- Une seule cellule rurale échoue : Delhi rural, dans trois vagues.

**Ce que permettrait un regroupement, non construit.** Les six États
réunis en une unité « Nord-Est » compteraient 1 618 ménages urbains et
51 grappes en 1998-99, ce qui passe le seuil. On aurait alors 21 unités,
mais on perdrait la variation interne à ce groupe : le purificateur urbain
y va de 2,6 % (Manipur) à 15,3 % (Nagaland) en 2019-21. Un découpage en
grandes régions (cinq ou six zones) ne laisserait que cinq ou six unités.
