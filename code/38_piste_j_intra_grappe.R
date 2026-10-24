# ---------------------------------------------------------------------------
# 38_piste_j_intra_grappe.R -- piste J : a l'interieur d'une meme grappe et a
#   eau sur la parcelle, les menages plus riches sont-ils sur le souterrain
#   prive plutot que sur le reseau ? Test discriminant du piege.
#
# ===========================================================================
# CRITERE (ecrit avant tout chiffre ; A VALIDER PAR LA PI AVANT EXECUTION)
# ===========================================================================
# PROBLEME EVITE : un gradient de richesse sur "eau sur la parcelle" est
# presque tautologique (meilleur logement -> eau sur place, quelle qu'en
# soit l'origine) et ne dirait rien du piege.
#
# SOUS-POPULATION : menages dont l'eau est sur leur propre parcelle, qu'elle
# vienne du reseau (reseau_public_domicile : hv201 11-12) ou du souterrain
# (souterrain_prive : hv201 21/31/32 et hv235 dans {1, 2}). Tous les autres
# sont exclus. Classes reprises de code/ref/35_hv201_classes.csv, a
# l'identique du script 35.
#
# RESULTAT : y = 1 si souterrain_prive, 0 si reseau_public_domicile, soit
# "prive plutot que public, a conditions de logement comparables".
#
# SPECIFICATION : modele lineaire de probabilite, effets fixes de grappe
# (hv024 x hv001), regresseur z = hv271 standardise a l'interieur de chaque
# vague (moyenne et ecart-type ponderes hv005, calcules sur TOUS les menages
# de la vague, avant toute restriction), erreurs groupees a la grappe
# (fixest::feols). Une vague a la fois, jamais empilees. Effet marginal en
# points = 100 x coefficient (pour un ecart-type de richesse). IC a 95 %.
# Proposition a valider : estimation NON ponderee. Justification : le
# contraste est intra-grappe et hv005 est un poids de grappe ; ponderer ne
# ferait que reponderer les grappes entre elles. Aucune variante ponderee
# n'est produite, pour ne pas ouvrir de choix apres coup. (Valide par la PI.)
# CONTREPARTIE : le coefficient est un contraste intra-grappe agrege a POIDS
# EGAL entre grappes, pas une statistique representative de la population
# indienne. Il ne pourra pas etre enonce comme "en Inde, x % des menages...".
#
# RESTRICTION : grappes contenant au moins un menage de chaque cote (y = 0
# et y = 1). Sans elle, les grappes homogenes n'apportent rien au
# numerateur mais gonflent la variance intra de z et attenuent le
# coefficient. Rapporte par vague : grappes et menages avant / apres.
#
# CE QUI COMPTE POUR, ET CONTRE (consigne de la PI, telle quelle) :
#   Signature du piege : coefficient POSITIF. A l'interieur d'une meme
#   grappe, et a logement comparable, les menages plus riches sont sur le
#   souterrain prive plutot que sur le reseau. Ils sortent alors que le
#   reseau est present chez leurs voisins.
#   Contre le piege : coefficient NEGATIF. Les plus riches prennent le
#   raccordement et le souterrain prive est ce qu'on utilise faute de
#   mieux. C'est une echelle de provision, pas un piege, et c'est le
#   resultat le plus probable a priori : il faut l'ecrire avant, sinon on
#   le rationalisera apres.
#   Non concluant : coefficient dont l'intervalle de confiance contient
#   zero, ou dont l'ampleur est inferieure a 3 points de pourcentage pour
#   un ecart-type de richesse.
#   Le signe prime sur l'ampleur. Un negatif net ferme la piste J comme
#   design causal, meme si la description reste publiable.
#
# "NET" = IC a 95 % excluant zero ET |effet| >= 3 points.
#
# REGLE D'AGREGATION ENTRE VAGUES (validee et amendee par la PI) : verdict
# sur l'ENSEMBLE (rural + urbain) des deux vagues principales, NFHS-3 et
# NFHS-4, dans cet ordre de priorite :
#   SIGNE INSTABLE     si les deux vagues principales sont nettes et de
#                      signes opposes. Ce n'est ni une confirmation ni une
#                      fermeture. Le constat descriptif est rapporte, la
#                      pretention causale est suspendue, et NFHS-5 est
#                      regardee pour la DIRECTION du mouvement, jamais pour
#                      trancher le verdict. Ce cas ne rouvre rien par
#                      lui-meme : il appelle un troisieme point de mesure,
#                      pas une nouvelle specification.
#   CONTRE LE PIEGE    sinon, si au moins une vague principale est negative
#                      nette (le signe prime : un negatif net suffit).
#   SIGNATURE DU PIEGE si les DEUX vagues principales sont positives nettes.
#   NON CONCLUANT      dans tous les autres cas (dont : une positive nette et
#                      une non concluante).
# L'asymetrie est volontaire : deux positives pour confirmer, une seule
# negative pour fermer. Apres huit fermetures, le risque de ce projet n'est
# pas de fermer trop vite.
# Rural et urbain : rapportes, ne decident pas. NFHS-5 : robustesse
# seulement (code 13 "piped to neighbor" a 1.62 %, signature COVID) ; un
# signe net oppose au verdict principal est signale comme fragilite, il ne
# change pas le verdict. NFHS-2 : hors jeu (hv235 absent).
#
# DIRECTION DU BIAIS DE SELECTION (ecrite avant le run) : le biais va VERS
# la signature du piege. Si les menages pauvres n'entrent dans la
# sous-population que parce qu'un programme public leur a donne un robinet,
# les pauvres de l'echantillon sont sur-representes cote reseau et les
# riches cote prive, par selection et non par sortie. Cela produit un
# coefficient positif sans qu'aucun menage n'ait quitte le reseau.
# Consequences :
#   - Un coefficient POSITIF est compatible avec le piege mais ne l'etablit
#     pas, puisque la selection pousse dans ce sens. Il ne peut etre rapporte
#     que comme un resultat descriptif, a confirmer par un design qui ne
#     conditionne pas sur l'equipement.
#   - Un coefficient NEGATIF est en revanche un resultat fort, puisqu'il
#     apparait CONTRE le sens du biais.
#   - L'asymetrie de la regle d'agregation s'en trouve justifiee deux fois :
#     par le principe de prudence, et par la direction du biais.
#
# LIMITES, ecrites avant :
#   - Selection sur une variable que la richesse cause : avoir l'eau sur la
#     parcelle depend de la richesse. La sous-population n'a donc pas la
#     meme composition a chaque niveau de richesse ; le coefficient est un
#     contraste descriptif intra-grappe parmi les menages deja equipes, pas
#     un effet causal de la richesse.
#   - souterrain_prive mesure une LOCALISATION (script 36 : reconstruction
#     non disqualifiee, mais 99.5 % des sources sur parcelle ont un
#     financement inconnu dans le NSS 76).
#   - reseau_public_domicile peut contenir des forages prives raccordes a
#     des robinets et declares "piped into dwelling" (script 35, reserve sur
#     la pompe). CORRIGE APRES EXECUTION (la version initiale disait "vers
#     zero", ce qui etait faux) : un menage riche avec forage, cuve et
#     robinets declare "piped into dwelling", donc y = 0 alors qu'il est sur
#     du prive. Les riches sont mal classes vers le public, et ce biais
#     pousse le coefficient vers le NEGATIF. Il va donc dans le meme sens
#     que le resultat : c'est une explication CONCURRENTE du verdict, pas
#     une raison de le renforcer. Le verdict CONTRE tient contre le critere,
#     mais son interpretation reste ouverte entre deux lectures :
#       (1) la premisse du piege est fausse pour l'eau de boisson en Inde ;
#       (2) l'instrument ne voit pas la sortie des riches, parce qu'elle
#           passe par des robinets.
#     Le script 39 (charges d'eau, NSS 76) est construit pour les departager.
#   - hv271 est relatif a chaque vague ; NFHS-5 "combined" non etabli comme
#     le meme construit (script 37). Les coefficients se comparent en signe,
#     pas en niveau, entre vagues.
#
# ===========================================================================
# DONNEES
# ===========================================================================
# Entree : build/35_nfhs_menages.rds (etape 2 du script 35 : hv001, hv005,
# hv024, hv025, hv201, hv235, hv270, hv271 par vague) et
# code/ref/35_hv201_classes.csv. Le script s'arrete si l'un manque.
# hv201 = 99 -> manquant, comme au script 35.
#
# SORTIES : par vague (3, 4, 5) x champ (ensemble, rural, urbain) : grappes
# et menages avant / apres restriction, taux de base (part souterrain_prive
# dans l'echantillon d'estimation, non pondere ; et dans la sous-population
# entiere, pondere), coefficient, erreur type, IC 95 %, effet en points,
# qualification (positif net / negatif net / non concluant). Puis le
# verdict selon la regle ci-dessus.
#
# LANCEMENT (racine du depot), court :
#     Rscript code/38_piste_j_intra_grappe.R
#
# Sorties : output/tables/38_*.csv, output/logs/38_piste_j_intra_grappe.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("38_piste_j_intra_grappe.log"))
msg("ETAPE 38 -- PISTE J : TEST INTRA-GRAPPE, PRIVE PLUTOT QUE PUBLIC SUR LA PARCELLE")
msg("Critere ecrit dans l'en-tete avant tout chiffre.")

SEUIL_PTS  <- 3      # ampleur minimale, points pour un ecart-type
NIVEAU_IC  <- 0.95
PRINCIPALES <- c("nfhs3", "nfhs4")
ROBUSTESSE  <- "nfhs5"

if (!requireNamespace("fixest", quietly = TRUE))
  stop("PACKAGE INDISPONIBLE : fixest est requis. Arret.", call. = FALSE)

# --- entrees ------------------------------------------------------------------
hr("38a. Entrees")
f_men <- p_build("35_nfhs_menages.rds")
f_ref <- file.path("code", "ref", "35_hv201_classes.csv")
check(file.exists(f_men), paste0("sortie d'etape du script 35 presente -> ", f_men))
check(file.exists(f_ref), paste0("table de correspondance presente -> ", f_ref))
men <- readRDS(f_men)
REF <- fread(f_ref, colClasses = list(character = c("vague", "libelle_dhs", "note"),
                                      numeric = "hv201"))
for (v in c(PRINCIPALES, ROBUSTESSE))
  check_vars(men[[v]], c("hv001", "hv005", "hv024", "hv025", "hv201", "hv235", "hv271"),
             paste0(v, " (build 35)"))

# --- classement (identique au script 35) ----------------------------------------
classe <- function(d, v) {
  d <- copy(d)
  d[hv201 %in% 99, hv201 := NA_real_]
  d[REF[vague == v], on = "hv201", `:=`(l12 = i.loc_1_2, l3 = i.loc_3, lna = i.loc_na)]
  d[, classe := fcase(is.na(hv201),      "manquant",
                      hv235 %in% c(1, 2), l12,
                      hv235 %in% 3,       l3,
                      rep(TRUE, .N),      lna)]
  check(all(!is.na(d$classe)), paste0(v, " : chaque menage a une classe"))
  d[, grappe := paste(hv024, hv001, sep = "_")]
  # z : hv271 standardise sur TOUTE la vague, pondere, avant restriction
  w <- d$hv005 / 1e6; ok <- !is.na(d$hv271)
  mu <- sum(w[ok] * d$hv271[ok]) / sum(w[ok])
  s  <- sqrt(sum(w[ok] * (d$hv271[ok] - mu)^2) / sum(w[ok]))
  d[, z := (hv271 - mu) / s]
  d[, secteur := fifelse(hv025 == 1, "urbain", "rural")]
  d[]
}

# --- estimation -------------------------------------------------------------------
hr("38b. Estimation par vague et par champ")

estime <- function(v, champ) {
  d <- classe(men[[v]], v)
  if (champ != "ensemble") d <- d[secteur == champ]
  sp <- d[classe %in% c("souterrain_prive", "reseau_public_domicile") & !is.na(z)]
  sp[, y := as.integer(classe == "souterrain_prive")]
  base_pond <- 100 * sum(sp$hv005 * sp$y) / sum(sp$hv005)
  g <- sp[, .(n0 = sum(y == 0), n1 = sum(y == 1)), by = grappe]
  garde <- g[n0 >= 1 & n1 >= 1, grappe]
  est <- sp[grappe %in% garde]
  res <- data.table(vague = v, champ = champ,
                    grappes_souspop = nrow(g), menages_souspop = nrow(sp),
                    grappes_estim = length(garde), menages_estim = nrow(est),
                    base_estim_pct = 100 * mean(est$y), base_souspop_pond_pct = base_pond)
  if (length(garde) < 2L) {
    warn(v, " ", champ, " : moins de 2 grappes mixtes, pas d'estimation")
    return(res[, `:=`(coef = NA_real_, se = NA_real_, ic_bas = NA_real_, ic_haut = NA_real_)])
  }
  m  <- fixest::feols(y ~ z | grappe, data = est, cluster = ~grappe)
  ct <- fixest::coeftable(m)
  ic <- confint(m, level = NIVEAU_IC)
  res[, `:=`(coef = ct["z", "Estimate"], se = ct["z", "Std. Error"],
             ic_bas = ic["z", 1], ic_haut = ic["z", 2])]
  res
}

tab <- rbindlist(lapply(c(PRINCIPALES, ROBUSTESSE), function(v)
  rbindlist(lapply(c("ensemble", "rural", "urbain"), function(ch) estime(v, ch)))))
tab[, `:=`(effet_pts = 100 * coef, ic_bas_pts = 100 * ic_bas, ic_haut_pts = 100 * ic_haut)]
tab[, qualification := fcase(
  is.na(coef),                                          "non estime",
  ic_bas > 0 & effet_pts >=  SEUIL_PTS,                 "positif net",
  ic_haut < 0 & effet_pts <= -SEUIL_PTS,                "negatif net",
  rep(TRUE, .N),                                        "non concluant")]
tab[, role := fifelse(vague %in% PRINCIPALES, "principale", "robustesse")]
setcolorder(tab, c("vague", "role", "champ"))
op <- options(width = 250); print(tab); options(op)
fwrite(tab, p_tab("38_intra_grappe_coefficients.csv"))

# --- verdict ------------------------------------------------------------------------
hr("38c. VERDICT contre le critere de l'en-tete")
q <- setNames(tab[champ == "ensemble" & vague %in% PRINCIPALES, qualification],
              tab[champ == "ensemble" & vague %in% PRINCIPALES, vague])
verdict <- if (setequal(q, c("positif net", "negatif net"))) "SIGNE INSTABLE" else
           if (any(q == "negatif net")) "CONTRE LE PIEGE (echelle de provision)" else
           if (all(q == "positif net")) "SIGNATURE DU PIEGE" else "NON CONCLUANT"
for (v in PRINCIPALES) msg(v, " (ensemble) : ", q[[v]])
msg(""); msg("VERDICT : ", verdict)
if (verdict == "SIGNATURE DU PIEGE")
  msg("Rappel du critere : positif = compatible avec le piege, NON etabli (biais de selection vers le positif) ; descriptif a confirmer.")
q5 <- tab[champ == "ensemble" & vague == ROBUSTESSE, qualification]
msg("Robustesse NFHS-5 (ensemble) : ", q5)
if (verdict == "SIGNE INSTABLE")
  msg("SIGNE INSTABLE : NFHS-5 regardee pour la DIRECTION seulement (", q5,
      ") ; pretention causale suspendue ; appelle un troisieme point de mesure.")
if ((verdict == "SIGNATURE DU PIEGE" && q5 == "negatif net") ||
    (grepl("^CONTRE", verdict) && q5 == "positif net"))
  warn("NFHS-5 de signe net oppose au verdict principal : fragilite signalee, verdict inchange")
fwrite(data.table(verdict = verdict, nfhs3 = q[["nfhs3"]], nfhs4 = q[["nfhs4"]], nfhs5 = q5),
       p_tab("38_intra_grappe_verdict.csv"))

msg(""); msg("Termine. Tables dans output/tables/38_*.csv")
log_close()
