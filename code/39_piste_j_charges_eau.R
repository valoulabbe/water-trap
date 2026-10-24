# ---------------------------------------------------------------------------
# 39_piste_j_charges_eau.R -- piste J : departager les deux lectures du
#   verdict du script 38 (CONTRE LE PIEGE) avec les charges d'eau du NSS 76.
#
# LES DEUX LECTURES (script 38, en-tete corrige) :
#   (1) la premisse du piege est fausse pour l'eau de boisson en Inde ;
#   (2) l'instrument ne voit pas la sortie des riches : un menage riche avec
#       forage, cuve et robinets declare "piped into dwelling", donc y = 0
#       alors qu'il est sur du prive.
# Si (2) est vraie, les menages "eau courante sur place" riches devraient
# etre plus souvent SANS facture d'eau (pas de fournisseur a payer).
#
# ITEMS (verifies sur NSS_76_sch_1.2.pdf bloc 5 et NSS_76_ins_Ch3.pdf) :
#   item 21.1 -> colonne amt_paid_water : "whether any amount is usually
#     paid in a month" : 1 paye, montant complet connu ; 2 paye, montant
#     partiel connu ; 3 paye, montant non disponible separement ; 4 PAS TENU
#     DE PAYER. Non-payant = code 4. Manuel 3.5.21 : pose a TOUS les
#     menages ; couvre l'achat d'eau ET les charges a l'organisme
#     fournisseur, pour la boisson ET les autres usages ; "delivery agency"
#     inclut corporation, municipalite, panchayat, lotissement prive ou
#     public, vendeur d'eau.
#   item 21.2 -> avg_amoun_month_rs : montant mensuel moyen (codes 1-2).
#   item 20 -> water_metered : compteur individuel (1 oui, 2 non), pose aux
#     menages 02/03, donc exactement a notre population (manuel 3.5.20 : un
#     compteur collectif d'immeuble compte "non").
# L'ordre des colonnes de L05 suit celui du questionnaire (items 19, 20,
# 21.1, 21.2) ; le script verifie que les codes observes de amt_paid_water
# sont bien dans {1, 2, 3, 4}.
#
# POPULATION : menages du round 76 dont la source PRINCIPALE de boisson est
# l'eau courante dans le logement (02) ou dans la parcelle (03).
#
# INDICATEURS, par quintile de depense par tete (all-India, pondere, comme
# le script 36), ensemble / rural / urbain, avec effectifs non ponderes et
# ponderes :
#   PRINCIPAL (le seul auquel s'applique le critere) : part des menages SANS
#     COMPTEUR (item 20 = 2) ET SANS CHARGE (21.1 = 4). Un raccordement
#     municipal urbain est en general compte, un forage domestique ne l'est
#     jamais : le compteur augmente la specificite.
#   Rapportes a cote, sans critere : sans charge seul (21.1 = 4) ; sans
#     compteur seul (item 20 = 2).
#   Denominateur : menages de la population avec 21.1 et item 20 renseignes
#   (manquants rapportes).
# Poids : Multiplier, re-verifie contre le rapport 584, Statement 1
# (178.38 M / 92.72 M).
#
# ===========================================================================
# LECTURE PREVUE (ecrite avant tout chiffre ; validee et amendee par la PI)
# ===========================================================================
# Le test est ASYMETRIQUE : 21.1 couvre l'achat d'eau a tout fournisseur (y
# compris un vendeur ou une copropriete) ; un menage aise sur forage qui
# achete des bidons ou paie des charges collectives est compte payant.
# Ajoute aux biais ci-dessous, qui poussent deja vers le plat, le test ne
# peut pas etablir que la premisse est fausse : il ne peut que reveler le
# contraire. Deux issues seulement, sur l'indicateur PRINCIPAL, champ
# ENSEMBLE, avec D = part(Q5) - part(Q1) en points :
#   CROISSANTE NETTE (D >= +10 points ET Q5 > Q4 > Q3) : lecture
#     "instrument aveugle". Le verdict du 38 ne peut pas etre presente comme
#     une refutation de la premisse du piege. Resultat fort, puisqu'il
#     apparait contre le sens des biais.
#   NON DISCRIMINANT (tout le reste, plat comme decroissant) : le test n'a
#     rien tranche. L'interpretation du verdict du 38 reste ouverte entre
#     "premisse fausse" et "instrument aveugle" ; c'est ce qui est ecrit,
#     pas "soutient premisse fausse". Une forme decroissante est exactement
#     ce que predit le biais des reseaux ruraux gratuits en bas de
#     distribution : elle n'apporte aucune information.
# Si l'indicateur principal et "sans charge seul" donnent des issues
# differentes, c'est signale ; l'indicateur principal decide.
# Rural et urbain : rapportes, ne decident pas. Le mecanisme (2) (forage +
# cuve + robinets) est plausiblement surtout urbain et periurbain : une
# divergence urbain croissant / ensemble non discriminant est signalee.
#
# DIRECTION DES BIAIS (ecrite avant) : tous poussent vers NON DISCRIMINANT,
# aucun vers un faux positif :
#   - un service public gratuit ou subventionne (schemas ruraux du
#     panchayat) donne aussi "pas tenu de payer", plus frequent en bas de la
#     distribution ;
#   - un menage riche sur forage qui ACHETE de l'eau (bouteilles, bidons,
#     camion) ou paie des charges collectives est compte payant ;
#   - les reseaux ruraux sont souvent non comptes ET gratuits : l'indicateur
#     principal attrape aussi ces schemas publics, ce qui pousse vers le bas
#     de la distribution.
#
# LIMITES :
#   - Une absence de charge peut venir d'un service public gratuit ou
#     subventionne, pas seulement d'un forage prive.
#   - Le round 76 est de 2018 : il qualifie NFHS-5 (2019-21) mieux que
#     NFHS-3 (2005-06), ou le 38 trouve son plus fort negatif.
#   - 21.1 couvre toute depense d'eau (achat inclus) et tous les usages.
#
# LANCEMENT (racine du depot), court :
#     Rscript code/39_piste_j_charges_eau.R
#
# Sorties : output/tables/39_*.csv, output/logs/39_piste_j_charges_eau.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("39_piste_j_charges_eau.log"))
msg("ETAPE 39 -- PISTE J : CHARGES D'EAU DES MENAGES A EAU COURANTE SUR PLACE (NSS 76)")
msg("Lecture prevue ecrite dans l'en-tete avant tout chiffre.")

SEUIL_D <- 10
N76   <- 106838L
EFF76 <- c(rural = 178.38e6, urbain = 92.72e6); TOL76 <- 0.01e6
d76   <- function(f) p_raw("nss", "76", f)

# --- lecture ------------------------------------------------------------------
hr("39a. Lecture et controles")
lit <- function(f, cols) {
  check(file.exists(f), paste0("fichier present -> ", f))
  tete <- names(fread(f, nrows = 0L))
  check(all(cols %in% tete), paste0(basename(f), " : colonnes presentes"),
        paste("absentes :", paste(setdiff(cols, tete), collapse = ", ")))
  d <- fread(f, select = cols, colClasses = list(character = "HHID"))
  check_unique(d, "HHID", basename(f)); check_rows(d, N76, basename(f))
  d
}
l01 <- lit(d76("L01_sample_household.csv"), c("HHID", "Sector", "Multiplier"))
l03 <- lit(d76("L03_Household_characteristics.csv"), c("HHID", "HH_size", "Total_Monthly_expenditure"))
l05 <- lit(d76("L05_Particulars_of_living_facilities.csv"),
           c("HHID", "source_drinking_water", "water_metered", "amt_paid_water", "avg_amoun_month_rs"))
d <- Reduce(function(a, b) merge(a, b, by = "HHID"), list(l01, l03, l05))
check_rows(d, N76, "NSS 76 apres fusion")
d[, w := Multiplier]
for (s in 1:2) {
  o <- sum(d$w[d$Sector == s]); e <- EFF76[[s]]
  check(abs(o - e) <= TOL76, sprintf("poids Multiplier : Sector %d == %s menages (rapport 584, Statement 1)",
                                     s, format(e, big.mark = " ")),
        sprintf("observe %.0f", o))
}
d[, secteur := fifelse(Sector == 1, "rural", "urbain")]

# quintile de depense par tete, pondere, all-India, sur TOUS les menages
d[, mpce := Total_Monthly_expenditure / HH_size]
o <- order(d$mpce); cw <- cumsum(d$w[o]) / sum(d$w)
br <- c(-Inf, sapply(1:4 / 5, function(p) d$mpce[o][which(cw >= p)[1]]), Inf)
d[, quintile := cut(mpce, br, labels = FALSE, right = TRUE)]
check(all(!is.na(d$quintile)), "quintile defini pour tous les menages")

pop <- d[source_drinking_water %in% c(2, 3)]
msg("Population : source principale 02 ou 03 -> ", format(nrow(pop), big.mark = " "), " menages")
codes <- sort(unique(pop$amt_paid_water[!is.na(pop$amt_paid_water)]))
note("codes observes de amt_paid_water dans la population : ", paste(codes, collapse = ", "),
     " ; manquants : ", sum(is.na(pop$amt_paid_water)))
check(all(codes %in% 1:4), "amt_paid_water dans {1, 2, 3, 4} (item 21.1)")
cm <- sort(unique(pop$water_metered[!is.na(pop$water_metered)]))
note("codes observes de water_metered : ", paste(cm, collapse = ", "),
     " ; manquants : ", sum(is.na(pop$water_metered)))
check(all(cm %in% 1:2), "water_metered dans {1, 2} (item 20)")
pop <- pop[!is.na(amt_paid_water) & !is.na(water_metered)]
msg("Denominateur (21.1 et item 20 renseignes) : ", format(nrow(pop), big.mark = " "), " menages")
pop[, `:=`(sans_charge   = as.integer(amt_paid_water == 4),
           sans_compteur = as.integer(water_metered == 2))]
pop[, principal := sans_charge * sans_compteur]

# --- sortie ---------------------------------------------------------------------
hr("39b. Indicateurs par quintile de depense par tete")
empile <- function(x) rbind(copy(x)[, secteur := "ensemble"], x)
tab <- empile(pop)[, .(
  n = .N, menages_ponderes = sum(w),
  principal_sans_compteur_ni_charge = 100 * sum(w * principal) / sum(w),
  sans_charge_seul                  = 100 * sum(w * sans_charge) / sum(w),
  sans_compteur_seul                = 100 * sum(w * sans_compteur) / sum(w)),
  by = .(secteur, quintile)]
setorderv(tab, c("secteur", "quintile"))
op <- options(width = 200); print(tab); options(op)
fwrite(tab, p_tab("39_indicateurs_par_quintile.csv"))

# --- lecture contre la regle ----------------------------------------------------------
hr("39c. LECTURE contre la regle de l'en-tete")
forme <- function(s, var) {
  p <- tab[secteur == s][order(quintile)][[var]]
  D <- p[5] - p[1]
  data.table(secteur = s, indicateur = var, Q1 = p[1], Q3 = p[3], Q4 = p[4], Q5 = p[5],
             D_Q5_Q1 = D,
             issue = if (D >= SEUIL_D && p[5] > p[4] && p[4] > p[3]) "CROISSANTE NETTE" else "NON DISCRIMINANT")
}
lec <- rbindlist(lapply(c("principal_sans_compteur_ni_charge", "sans_charge_seul"), function(var)
  rbindlist(lapply(c("ensemble", "rural", "urbain"), forme, var = var))))
op <- options(width = 200); print(lec); options(op)
fwrite(lec, p_tab("39_lecture.csv"))
i_p <- lec[secteur == "ensemble" & indicateur == "principal_sans_compteur_ni_charge", issue]
i_c <- lec[secteur == "ensemble" & indicateur == "sans_charge_seul", issue]
msg(""); msg("ISSUE (indicateur principal, ensemble) : ", i_p)
msg("LECTURE : ", if (i_p == "CROISSANTE NETTE")
  "'instrument aveugle'. Le verdict du 38 ne peut pas etre presente comme une refutation de la premisse du piege."
  else "NON DISCRIMINANT. Le test n'a rien tranche : l'interpretation du verdict du 38 reste ouverte entre 'premisse fausse' et 'instrument aveugle'.")
if (i_p != i_c)
  warn("Indicateur principal (", i_p, ") et 'sans charge seul' (", i_c, ") divergent -- l'indicateur principal decide.")
u <- lec[secteur == "urbain" & indicateur == "principal_sans_compteur_ni_charge", issue]
if (i_p != "CROISSANTE NETTE" && u == "CROISSANTE NETTE")
  warn("Divergence : urbain CROISSANTE NETTE, ensemble NON DISCRIMINANT -- signalee, ne change pas la lecture.")

msg(""); msg("Termine. Tables dans output/tables/39_*.csv")
log_close()
