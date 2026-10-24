# ---------------------------------------------------------------------------
# 15_piste_c_nfhs_traitement.R -- piste C : adoption du traitement prive de
#   l'eau dans les NFHS (DHS Inde), Household Recode, vagues 2 a 5.
#
# MOTIF : le NSS ne permet pas de suivre l'adoption des purificateurs. La
# methode de traitement y est a reponse unique (premier code applicable), et
# le code 5 change de definition entre le round 69 ("filtered with water
# filter (candle, ceramic, sand)") et le round 76 ("non-electric purifier").
# IHDS ne le permet pas non plus : l'item est une questi on unique groupee
# (bouillir OU filtre achete OU Aquaguard OU produits chimiques) posee en
# frequence, sans ventilation par methode -- IHDS-I WA10, IHDS-II WA7. Les
# echelles different en plus entre vagues (I : Rarely/Never, Sometimes,
# Usually, Always ; II : Never, Rarely, Usually, Always).
# Les NFHS, elles, portent la serie hv237a..hv237x en REPONSES MULTIPLES, donc
# sans deplacement mecanique entre categories, avec filtre non electrique
# (hv237d) et purificateur electrique (hv237h) separes.
#
# PORTEE : parts ponderees descriptives par vague, par quintile de richesse et
# par secteur. Aucune fusion entre sources, aucune estimation causale.
#
# PIEGE PRINCIPAL -- DENOMINATEUR : hv237a..hv237x ne sont renseignees que pour
# les menages ayant repondu oui au filtre d'entree hv237 ("anything done to
# water to make safe to drink"). Pour les autres elles sont en NotAppl (NA),
# PAS en zero. Les lire telles quelles calcule les parts sur les seuls
# menages traitants et surestime tout d'un facteur deux. On recode donc a 0
# les composantes quand hv237 vaut non, et on ne garde en manquant que les
# vrais manquants (hv237 inconnu).
# Les parts suivent ensuite la CONVENTION DHS : tous les menages au
# denominateur, statut inconnu (hv237 = 8/9, ~0.05 % en NFHS-3) compte comme
# non traite. C'est la seule convention qui reproduit le tableau 2.11 du
# rapport NFHS-3 (controle 15h) ; hors NA, hv237d urbain sort a 13.459 contre
# 13.4 publie.
#
# NOMENCLATURE : les questionnaires menage NFHS-3 (q. 37-38) et NFHS-4
# (q. 29-30) ont ete lus. Liste de modalites identique, meme ordre, meme
# parenthese : bouillir, alun, chlore, tissu, filtre a eau (ceramique, sable,
# composite, etc.), purificateur electronique, laisser decanter, autre, ne
# sait pas. Aucune rupture de nomenclature entre ces deux vagues,
# contrairement au NSS entre les rounds 69 et 76. Seul le cadrage du
# repondant change : NFHS-3 interroge la personne ("do you treat your
# water"), NFHS-4 le menage ("does this household do anything to the water").
# Aucune des deux listes n'a de modalite pour un purificateur de marque non
# electrique (Pureit, Swach). Le manuel de l'enqueteur n'a pas pu etre obtenu :
# la convention de codage effective de ces appareils reste INCONNUE.
#
# VARIABLE DERIVEE traitement_prive = hv237d OU hv237h. Les composantes etant a
# reponses multiples, les parts separees ne bornent l'adoption d'un dispositif
# prive que par [max, somme], intervalles qui se chevauchent entre vagues.
# L'union se lit directement ; le croisement d x h en quatre cases (15f) dit
# comment elle se decompose.
#
# REPERE DE CONTROLE (NFHS-3, non pondere, fichier IAHR52FL.frq livre avec les
# donnees) : 11 845 menages au filtre (hv237d) et 1 964 au purificateur
# electrique (hv237h), sur 109 041 menages. Des ordres de grandeur tres
# differents en pondere signalent presque toujours un denominateur mal traite.
#
# NFHS-2 (1998) : la serie hv237* est ABSENTE (verifie), ainsi que le quintile
# hv270. La vague porte en revanche une serie indienne sh32a..sh32x (tissu,
# alun, filtre, ebullition, purificateur electronique, rien, autre) et un
# indice shsli, NON ENCORE RAPPROCHES de hv237* / hv270. En attendant, la
# vague est lue pour memoire et sort avec des parts manquantes (NA), pas avec
# des zeros.
#
# NUMERO : 15 est aussi pris par code/15_ihds_prive_public_inventaire.R sur
# les branches piste-e-exposition et piste-ihds-inventaire. Noms differents,
# pas de conflit git ; a trancher si les deux arrivent sur la meme branche.
#
# LANCEMENT (racine du depot) :
#     Rscript code/15_piste_c_nfhs_traitement.R          # reprend
#     Rscript code/15_piste_c_nfhs_traitement.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 15_nfhs_libelles.rds  nom et libelle de chaque variable, par vague
#   2. 15_nfhs_menages.rds   colonnes utiles de chaque Household Recode
#
# Sorties : output/tables/15_*.csv, output/logs/15_piste_c_nfhs_traitement.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("15_piste_c_nfhs_traitement.log"))

msg("ETAPE 15 -- PISTE C : TRAITEMENT DE L'EAU DANS LES NFHS (vagues 2 a 5)")
msg("Parts ponderees descriptives. Aucune fusion, aucune estimation causale.")

# --- vagues ----------------------------------------------------------------
# Household Recode (HR) de chaque vague. Les effectifs documentes servent de
# controle dur : un fichier tronque ou une mauvaise vague s'arrete ici.
VAGUES <- list(
  nfhs2 = list(annee = "1998-99",  fichier = p_raw("dhs", "india", "1998", "IAHR42DT", "IAHR42FL.DTA")),
  nfhs3 = list(annee = "2005-06",  fichier = p_raw("dhs", "india", "2005", "IAHR52DT", "IAHR52FL.dta")),
  nfhs4 = list(annee = "2015-16",  fichier = p_raw("dhs", "india", "2015", "IAHR74DT", "IAHR74FL.DTA")),
  nfhs5 = list(annee = "2019-21",  fichier = p_raw("dhs", "india", "2019", "IAHR7EDT", "IAHR7EFL.DTA"))
)

# Composantes de traitement suivies. On les nomme explicitement plutot que de
# prendre tout hv237* : les codes e, i, j, k sont des emplacements "NA" propres
# a chaque pays et ne veulent rien dire ici.
COMPOSANTES <- c(bouillir = "hv237a", chlore = "hv237b", tissu = "hv237c",
                 filtre = "hv237d", decantation = "hv237f", alun = "hv237g",
                 purificateur_elec = "hv237h", autre = "hv237x")
BASE  <- "hv237"                       # filtre d'entree
DERIVEES <- c(traitement_prive = "traitement_prive")   # hv237d OU hv237h
# Identifiants obligatoires dans toutes les vagues (arret si absents) et
# optionnels (avertissement nommant vague et variable) : hv270 et hv237
# manquent en NFHS-2.
IDENT_OBLIG <- c(poids = "hv005", etat = "hv024", secteur = "hv025")
IDENT_OPT   <- c(quintile = "hv270", source_eau = "hv201", traite = BASE)
IDENT <- c(IDENT_OBLIG, IDENT_OPT[names(IDENT_OPT) != "traite"])

if (!requireNamespace("haven", quietly = TRUE))
  stop("PACKAGE INDISPONIBLE : haven est requis pour lire les .DTA des NFHS. ",
       "Arret -- aucune relance automatique.", call. = FALSE)

# ===========================================================================
# Etape 1 : libelles de chaque vague
# ===========================================================================
# On lit zero ligne pour recuperer noms et libelles sans charger les donnees :
# les HR font plusieurs milliers de colonnes et une lecture complete sature la
# memoire. C'est aussi ce qui permet de CONSTATER la presence des variables
# plutot que de la supposer.
hr("15a. Variables disponibles par vague (etape 1)")

f_lib <- p_build("15_nfhs_libelles.rds")
libs <- stage("etape 1/2 libelles NFHS", f_lib, function() {
  rbindlist(lapply(names(VAGUES), function(v) {
    f <- VAGUES[[v]]$fichier
    tmsg("  lecture des entetes ", f)
    check(file.exists(f), paste0(v, " : fichier present -> ", f))
    d <- haven::read_dta(f, n_max = 0L)
    data.table(vague = v,
               variable = names(d),
               libelle = vapply(d, function(x) attr(x, "label") %||% "", character(1)))
  }))
})

for (v in names(VAGUES)) {
  dispo <- libs[vague == v, variable]
  msg(""); msg(v, " (", VAGUES[[v]]$annee, ") : ", length(dispo), " variables")
  check_vars(data.table::setnames(data.table(matrix(nrow = 0, ncol = length(dispo))), dispo),
             IDENT_OBLIG, v)
  for (k in names(IDENT_OPT)[!IDENT_OPT %in% dispo])
    warn(v, " : variable optionnelle absente -> ", IDENT_OPT[[k]], " (", k, ")")
  manquantes <- setdiff(COMPOSANTES, dispo)
  if (length(manquantes))
    warn(v, " : composantes absentes -> ", paste(names(COMPOSANTES)[COMPOSANTES %in% manquantes],
                                                 collapse = ", "))
}

# Libelles effectivement observes pour les composantes suivies : a relire dans
# le log avant d'interpreter quoi que ce soit, un meme code hv237* pouvant
# changer de sens d'une vague a l'autre.
hr("15b. Libelles des composantes de traitement, vague par vague")
lib_comp <- libs[variable %in% c(BASE, COMPOSANTES)][order(variable, vague)]
op <- options(width = 200); print(lib_comp); options(op)
fwrite(lib_comp, p_tab("15_nfhs_libelles_traitement.csv"))

# ===========================================================================
# Etape 2 : colonnes utiles de chaque vague
# ===========================================================================
hr("15c. Lecture des Household Recode (etape 2)")

f_men <- p_build("15_nfhs_menages.rds")
men <- stage("etape 2/2 menages NFHS", f_men, function() {
  lapply(names(VAGUES), function(v) {
    f <- VAGUES[[v]]$fichier
    dispo <- libs[vague == v, variable]
    vars <- intersect(c(IDENT, BASE, COMPOSANTES), dispo)
    tmsg("  lecture ", f, " (", length(vars), " colonnes)")
    d <- as.data.table(haven::read_dta(f, col_select = all_of(vars)))
    # haven renvoie des vecteurs etiquetes ; on repasse en numerique nu pour
    # que les comparaisons de codes ci-dessous ne dependent pas des etiquettes.
    for (cc in names(d)) set(d, j = cc, value = as.numeric(d[[cc]]))
    d[, vague := v]
    d[]
  }) |> setNames(names(VAGUES))
})

for (v in names(VAGUES)) {
  d <- men[[v]]
  msg(""); msg(v, " (", VAGUES[[v]]$annee, ") : ", format(nrow(d), big.mark = " "), " menages")
  check(nrow(d) > 0L, paste0(v, " : au moins un menage lu"))
  check(all(!is.na(d$hv005)) && all(d$hv005 >= 0),
        paste0(v, " : poids hv005 present et positif"))
}

# --- recodage du denominateur ----------------------------------------------
# hv237 : 0 = non, 1 = oui, 8 = ne sait pas (selon vague). Les composantes ne
# sont posees qu'aux menages a hv237 == 1.
#   hv237 == 0            -> composante = 0 (le menage ne traite pas)
#   hv237 == 1            -> composante telle quelle (0/1), NA si vraie non-reponse
#   hv237 autre ou NA     -> composante = NA (statut de traitement inconnu)
hr("15d. Recodage du denominateur (NotAppl -> 0 quand hv237 == non)")

recode_composantes <- function(d, v) {
  comp <- intersect(COMPOSANTES, names(d))
  if (!length(comp)) { warn(v, " : aucune composante a recoder"); return(d) }
  na_avant <- sapply(comp, function(cc) sum(is.na(d[[cc]])))
  for (cc in comp) {
    x <- d[[cc]]
    x[d[[BASE]] %in% 0] <- 0
    x[!(d[[BASE]] %in% c(0, 1))] <- NA_real_
    x[!(x %in% c(0, 1))] <- NA_real_
    set(d, j = cc, value = x)
  }
  na_apres <- sapply(comp, function(cc) sum(is.na(d[[cc]])))
  for (cc in comp)
    note(v, " ", cc, " : NA ", format(na_avant[[cc]], big.mark = " "), " -> ",
         format(na_apres[[cc]], big.mark = " "))
  d
}
men <- lapply(names(men), function(v) recode_composantes(men[[v]], v)) |> setNames(names(men))

# --- variable derivee : traitement prive (filtre OU purificateur) -----------
# Construite APRES le recodage, donc meme regle de denominateur que les
# composantes : hv237 == non -> 0 ; statut inconnu -> NA.
#   1  si hv237d == 1 ou hv237h == 1
#   0  si hv237d == 0 et hv237h == 0
#   NA sinon
for (v in names(men)) {
  d <- men[[v]]
  if (!all(c("hv237d", "hv237h") %in% names(d))) {
    warn(v, " : hv237d ou hv237h absent, traitement_prive non construit")
    next
  }
  d[, traitement_prive := fifelse(hv237d %in% 1 | hv237h %in% 1, 1,
                          fifelse(hv237d %in% 0 & hv237h %in% 0, 0, NA_real_))]
  note(v, " traitement_prive : 1 = ", format(sum(d$traitement_prive %in% 1), big.mark = " "),
       ", 0 = ", format(sum(d$traitement_prive %in% 0), big.mark = " "),
       ", NA = ", format(sum(is.na(d$traitement_prive)), big.mark = " "))
  men[[v]] <- d   # := sur un objet relu d'un .rds peut realloquer : on reassigne
}

# --- parts ponderees --------------------------------------------------------
# Poids DHS : hv005 / 1e6. Convention DHS : tous les menages au denominateur,
# un statut inconnu (NA) compte comme non traite. Composantes non exclusives
# entre elles.
hr("15e. Parts ponderees")

part <- function(x, w) {
  ok <- !is.na(w)
  if (!any(ok) || all(is.na(x))) return(NA_real_)
  sum(w[ok] * (x[ok] %in% 1)) / sum(w[ok]) * 100
}

parts_par <- function(by = NULL) {
  rbindlist(lapply(names(men), function(v) {
    d <- men[[v]]
    comp <- intersect(c(BASE, COMPOSANTES, DERIVEES), names(d))
    if (!is.null(by) && !all(by %in% names(d))) return(NULL)
    d[, c(list(n = .N, menages_ponderes = sum(hv005 / 1e6)),
          lapply(.SD, part, w = hv005 / 1e6)),
      by = c("vague", by), .SDcols = comp]
  }), fill = TRUE)
}

tab_vague    <- parts_par()
# Les colonnes portent les codes DHS (hv270, hv025), pas les noms de IDENT.
tab_quintile <- parts_par(IDENT[["quintile"]])
tab_secteur  <- parts_par(IDENT[["secteur"]])
setorderv(tab_quintile, c("vague", IDENT[["quintile"]]))
setorderv(tab_secteur,  c("vague", IDENT[["secteur"]]))

op <- options(width = 220)
msg(""); msg("Parts ponderees par vague (%)"); print(tab_vague)
msg(""); msg("Par quintile de richesse hv270 (1 = plus pauvre, 5 = plus riche)"); print(tab_quintile)
msg(""); msg("Par secteur hv025 (1 = urbain, 2 = rural)"); print(tab_secteur)
options(op)

fwrite(tab_vague,    p_tab("15_nfhs_parts_par_vague.csv"))
fwrite(tab_quintile, p_tab("15_nfhs_parts_par_quintile.csv"))
fwrite(tab_secteur,  p_tab("15_nfhs_parts_par_secteur.csv"))

# --- croisement filtre x purificateur ---------------------------------------
# Quatre cases ponderees, en % des menages (convention DHS : statut inconnu
# range dans "aucun"). Par vague, puis par vague x quintile. Le script ne
# tranche pas entre substitution filtre -> purificateur et mouvements
# independants : il produit seulement le tableau.
hr("15f. Croisement hv237d x hv237h (quatre cases ponderees)")

croise_par <- function(by = NULL) {
  rbindlist(lapply(names(men), function(v) {
    d <- men[[v]]
    if (!all(c("hv237d", "hv237h", by) %in% names(d))) return(NULL)
    d[, {
      w <- hv005 / 1e6; f <- hv237d %in% 1; p <- hv237h %in% 1
      list(n = .N,
           aucun          = sum(w[!f & !p]) / sum(w) * 100,
           filtre_seul    = sum(w[ f & !p]) / sum(w) * 100,
           purif_seul     = sum(w[!f &  p]) / sum(w) * 100,
           filtre_et_purif = sum(w[ f &  p]) / sum(w) * 100)
    }, by = c("vague", by)]
  }))
}
crois_vague    <- croise_par()
crois_quintile <- croise_par(IDENT[["quintile"]])
setorderv(crois_quintile, c("vague", IDENT[["quintile"]]))

op <- options(width = 220)
msg(""); msg("Croisement par vague (% des menages)"); print(crois_vague)
msg(""); msg("Croisement par vague x quintile hv270 (% des menages du quintile)"); print(crois_quintile)
options(op)

fwrite(crois_vague,    p_tab("15_nfhs_croisement_filtre_purif_vague.csv"))
fwrite(crois_quintile, p_tab("15_nfhs_croisement_filtre_purif_quintile.csv"))

# --- controle non pondere contre le fichier .frq de NFHS-3 ------------------
hr("15g. Controle non pondere, NFHS-3 contre IAHR52FL.frq")

d3 <- men[["nfhs3"]]
if (!is.null(d3) && all(c("hv237d", "hv237h") %in% names(d3))) {
  obs <- c(filtre = sum(d3$hv237d == 1, na.rm = TRUE),
           purificateur_elec = sum(d3$hv237h == 1, na.rm = TRUE))
  att <- c(filtre = 11845L, purificateur_elec = 1964L)
  for (k in names(att))
    check(obs[[k]] == att[[k]],
          sprintf("NFHS-3 : %s, effectif non pondere == %s (fichier .frq)", k,
                  format(att[[k]], big.mark = " ")),
          sprintf("observe %s", format(obs[[k]], big.mark = " ")))
  check(nrow(d3) == 109041L, "NFHS-3 : 109 041 menages (fichier .frq)",
        sprintf("observe %s", format(nrow(d3), big.mark = " ")))
} else {
  warn("NFHS-3 : composantes absentes, controle impossible")
}

# --- controle pondere contre le rapport officiel NFHS-3 ---------------------
# Rapport final NFHS-3, vol. 1, tableau 2.11 "Household drinking water", p. 35.
# Parts en % des menages, total / urbain / rural. hv237 est le complement a
# 100 de la ligne "No treatment" publiee (65.6 / 51.0 / 72.7).
# Le tableau est arrondi au dixieme : tolerance 0.05 point, jamais d'egalite
# stricte. Les effectifs ponderes publies fixent aussi le codage du secteur
# (hv025 : 1 = urbain, 2 = rural), verifie ici plutot que suppose.
hr("15h. Controle pondere, NFHS-3 contre le rapport (tableau 2.11)")

PUBLIE_NFHS3 <- rbindlist(list(
  list("hv237",  34.4, 49.0, 27.3),
  list("hv237a", 10.4, 16.0,  7.7),
  list("hv237g",  1.3,  2.1,  0.9),
  list("hv237b",  2.3,  2.2,  2.4),
  list("hv237c", 16.6, 19.1, 15.4),
  list("hv237d",  6.6, 13.4,  3.3),
  list("hv237h",  1.2,  3.4,  0.1),
  list("hv237f",  0.6,  0.8,  0.5),
  list("hv237x",  0.4,  0.5,  0.3)))
setnames(PUBLIE_NFHS3, c("variable", "total", "urbain", "rural"))
EFFECTIFS_NFHS3 <- c(total = 109041, urbain = 35579, rural = 73462)
TOL_PART <- 0.05
TOL_EFF  <- 1

obs3 <- list(total  = tab_vague[vague == "nfhs3"],
             urbain = tab_secteur[vague == "nfhs3" & get(IDENT[["secteur"]]) == 1],
             rural  = tab_secteur[vague == "nfhs3" & get(IDENT[["secteur"]]) == 2])
for (s in names(obs3))
  check(nrow(obs3[[s]]) == 1L, paste0("NFHS-3 : une ligne ", s, " dans les tables"),
        sprintf("observe %d", nrow(obs3[[s]])))

# effectifs ponderes : verifient a la fois les poids et le codage de hv025
for (s in names(EFFECTIFS_NFHS3)) {
  o <- obs3[[s]]$menages_ponderes
  check(abs(o - EFFECTIFS_NFHS3[[s]]) <= TOL_EFF,
        sprintf("NFHS-3 : menages ponderes %s == %s (a %d pres)", s,
                format(EFFECTIFS_NFHS3[[s]], big.mark = " "), TOL_EFF),
        sprintf("attendu %s, observe %.2f", format(EFFECTIFS_NFHS3[[s]], big.mark = " "), o))
}

for (i in seq_len(nrow(PUBLIE_NFHS3))) {
  vv <- PUBLIE_NFHS3$variable[i]
  for (s in names(obs3)) {
    att <- PUBLIE_NFHS3[[s]][i]
    o   <- obs3[[s]][[vv]]
    check(abs(o - att) <= TOL_PART,
          sprintf("NFHS-3 : %s %s == %.1f (tol. %.2f)", vv, s, att, TOL_PART),
          sprintf("%s %s : attendu %.1f, observe %.4f, ecart %.4f", vv, s, att, o, o - att))
  }
}

msg(""); msg("Termine. Tables dans output/tables/15_*.csv")
log_close()
