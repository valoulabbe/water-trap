# Piste A — critère de sortie du premier stage (fixé avant estimation)

Fixé le 24/09/2026 par Valentine, commité avant toute estimation.
Statut du test : **porte de faisabilité** (passe / échoue), pas un résultat.

## Échantillon
- Andhra Pradesh non divisé (pc11_state_id 28), puits CGWB.
- Profondeur = moyenne des lectures de mai **1996–2000** disponibles (au moins une).
- **Socle seulement** (`hard_rock == TRUE` dans `code/ref/hydrogeo_ap_2m.csv` :
  cristallin, basalte, sédimentaire consolidé), **khondalite exclue**.
  Alluvions et semi-consolidé (Gondwana, Rajahmundry, latérite) exclus.

## Spécification
profondeur ~ classe d'aquifère principal (bloc géologie) + contrôles de terrain
(CartoDEM) et de sol (SLUSI) + effets fixes de district ; erreurs types
groupées par district.

### Précision des contrôles (ajoutée le 24/09, avant exécution)
SLUSI ne fournit que des Soil Health Cards : analyses chimiques de parcelles,
vers 2015–2020, sans texture ni profondeur de sol.
- **Sol :** pH et carbone organique, en médiane des analyses à 5 km au plus
  (au moins 3 analyses, sinon puits écarté). EC, N, P, K et oligo-éléments sont
  exclus (post-traitement). Le pH reflète en partie la roche mère : le garder
  rend le test plus difficile à passer.
- **Terrain (CartoDEM v3r1, 1″) :** altitude au puits ; pente moyenne et
  altitude relative (altitude au puits − altitude moyenne) dans une fenêtre
  carrée de ±0,009° autour du puits.
- **Bloc géologie :** classes d'aquifère principal (référence : granite).

## Règle de passage (les deux conditions)
1. **Part intra-district** de la variance de profondeur (échantillon ci-dessus)
   **≥ 25 %**.
2. **Gain de R² hors échantillon** du bloc géologie au-delà des effets fixes de
   district **≥ 0,05**. Validation croisée avec des plis qui retirent des districts
   entiers ; profondeur et contrôles centrés par district ;
   gain = R²_CV(géologie + contrôles) − R²_CV(contrôles seuls).

Les deux chiffres sont rapportés avant tout F partiel. Le F partiel (Wald
groupé par district) est rapporté à titre d'information seulement.

Le contraste testé est interne au socle par construction de l'échantillon. Une
géologie qui ne prédirait qu'à travers la coupure alluvions/roche ne peut donc
pas passer ce test.

## Rapporté à côté du verdict (hors critère)
Écarts des classes du socle sur des caractéristiques économiques de base
(SHRUG 1991 ou 2001, effets fixes de district) : population du village,
alphabétisation, part en Scheduled Areas, irrigation par canal, distance à la
ville. Sert à juger la restriction d'exclusion, pas le passage du test.

## Hors périmètre de cette porte
Aucun second stage, aucune variable de résultat, aucun raffinement du codage,
aucune couche de lithologie plus fine ni de fractures.
