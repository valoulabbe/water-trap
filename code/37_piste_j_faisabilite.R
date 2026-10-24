# ---------------------------------------------------------------------------
# 37_piste_j_faisabilite.R -- piste J : note de faisabilite AVANT le critere
#   de la question de fond (partage public / prive par richesse). Comptes
#   d'unites identifiantes et de variation, rien d'autre.
#
# CONSTATS ETABLIS PAR DOCUMENTATION (plus importants que les comptes) :
#   1. NFHS-3 ne porte AUCUN identifiant de district : NFHS3SUP.PDF 1.5 a)
#      et 5.0 (confidentialite du test VIH ; "no district-level
#      identification is possible with NFHS-3 data").
#   2. PAS DE PANEL : les grappes ne se reapparient pas entre vagues. NFHS-3
#      a des PSU brouilles et renumerotes, lien a la base de sondage detruit
#      (NFHS3SUP 5.0) ; aucune cle de liaison entre vagues, GPS deplaces a
#      chaque enquete. Toute comparaison dans le temps passe par des unites
#      agregees, et NFHS-3 n'en a pas sous l'Etat.
#   3. hv270 de NFHS-5 ("wealth index combined") N'EST PAS ETABLI comme le
#      meme construit que hv270 de NFHS-3 et NFHS-4 (Recode Manual DHS-7
#      inaccessible depuis cette machine ; detail plus bas).
#
# INTERDICTION : aucune variable reseau_public_*, souterrain_* ni derivee
# n'est lue, croisee ni tabulee (CLAUDE.md : pas de resultat avant le
# critere). Seules variables lues : identifiants geographiques (hv001,
# hv002, hv024, district), poids (hv005), richesse (hv270, hv271). Le point
# f reprend une table DEJA produite par le script 35 (distribution brute de
# hv201), sans relire hv201.
#
# SORTIES (quatre vagues) :
#   a. grappes : nombre, menages par grappe (min, quartiles, max, < 10 / 15 /
#      20). Cle de grappe : (hv024, hv001). NFHS3SUP.PDF 1.6 : en NFHS-3 les
#      numeros de PSU ne sont uniques qu'a l'interieur de chaque Etat, malgre
#      le libelle "psu number (national)". Le script compare hv001 seul et
#      (hv024, hv001).
#   b. variance de hv271 (score continu) decomposee en intra / inter grappe,
#      ponderee par hv005 ; part de grappes a au moins trois quintiles hv270
#      distincts. NFHS-2 n'a ni hv270 ni hv271.
#   c. districts : nombre, menages et grappes par district, districts a au
#      moins 30 / 50 / 100 menages. Cle (hv024, district).
#   d. appariement des districts NFHS-3 / NFHS-4 : IMPOSSIBLE, constate sans
#      calcul. NFHS-3 n'a AUCUNE variable district dans son fichier menage
#      (seulement sh025 ville / bourg / campagne). NFHS3SUP.PDF 1.5 a) et 5.0
#      : pour la confidentialite liee au test VIH, aucun identifiant de
#      district n'a ete collecte ni diffuse, et "no district-level
#      identification is possible with NFHS-3 data". Arret sur ce point,
#      comme demande. (NFHS-2 sdist : codes sans etiquettes de nom ; NFHS-4
#      shdistri : 640 noms ; NFHS-5 shdist : 707 noms.)
#   e. panel : NON pour NFHS-3, etabli par la documentation. NFHS3SUP.PDF 5.0
#      : apres saisie, numeros de PSU et de menage brouilles puis renumerotes
#      sequentiellement dans chaque Etat, questionnaires et fichiers
#      anterieurs detruits, "sever the link between the data and the
#      original sampling frame". NFHS-4 / NFHS-5 : meme base de sondage
#      (recensement 2011) mais aucune variable de liaison entre vagues dans
#      les fichiers, et des coordonnees GPS deplacees aleatoirement a chaque
#      enquete (urbain jusqu'a 2 km, rural 5 km, 1 % jusqu'a 10 km, dans le
#      meme district ; GPS_Displacement_README.txt) : aucun reappariement de
#      grappes n'est possible avec ces donnees. Que la selection des PSU de
#      NFHS-5 soit independante de NFHS-4 n'est PAS documente localement
#      (annexe A du rapport NFHS-5 vol. II inaccessible depuis cette machine,
#      HTTP 403) : a ajouter a la liste de telechargement.
#   f. distribution brute de hv201 : deja produite (script 35, section 35c
#      bis, output/tables/35_nfhs_distribution_hv201.csv). Le poids du code
#      13 "piped to neighbor" en NFHS-5 est relu dans ce fichier.
#
# RICHESSE, A NE PAS SUPPOSER : hv270 / hv271 sont relatifs a chaque vague
# (scores d'une ACP propre a chaque enquete, quintiles recoupes a chaque
# fois). NFHS-5 libelle hv270 "wealth index combined" et porte en plus
# hv270a "wealth index for urban/rural" ; NFHS-3 et NFHS-4 libellent hv270
# "wealth index" (NFHS-4 porte aussi sv270u / sv270r, scores urbain et
# rural propres a l'enquete). Le DHS Recode Manual (DHS-7, 2018) n'a PAS pu
# etre consulte (HTTP 403 depuis cette machine). Source secondaire non
# verifiee : reponses du personnel DHS sur le forum utilisateurs, selon
# lesquelles hv270 est l'indice "combined" et hv271a est construit comme
# deux fonctions lineaires de hv271 (urbain, rural). Que hv270 de NFHS-5
# soit le meme construit que celui de NFHS-3 et NFHS-4 reste donc NON
# ETABLI. A ajouter a la liste de telechargement : Recode Manual DHS-7 et
# Rutstein (2008), DHS Working Paper 60.
#
# FORME : un resume des chiffres qui decident est imprime EN TETE du log,
# avant le detail. Aucune recommandation de design.
#
# LANCEMENT (racine du depot), environ 2 a 4 min (relecture de 4 HR) :
#     Rscript code/37_piste_j_faisabilite.R           # reprend
#     Rscript code/37_piste_j_faisabilite.R --force   # refait tout
#
# ETAPE RESUMABLE (build/) :
#   1. 37_nfhs_geo_richesse.rds  identifiants, poids et richesse par vague
#
# Sorties : output/tables/37_*.csv, output/logs/37_piste_j_faisabilite.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("37_piste_j_faisabilite.log"))

VAGUES <- list(
  nfhs2 = list(annee = "1998-99", district = "sdist",
               fichier = p_raw("dhs", "india", "1998", "IAHR42DT", "IAHR42FL.DTA")),
  nfhs3 = list(annee = "2005-06", district = NA_character_,
               fichier = p_raw("dhs", "india", "2005", "IAHR52DT", "IAHR52FL.dta")),
  nfhs4 = list(annee = "2015-16", district = "shdistri",
               fichier = p_raw("dhs", "india", "2015", "IAHR74DT", "IAHR74FL.DTA")),
  nfhs5 = list(annee = "2019-21", district = "shdist",
               fichier = p_raw("dhs", "india", "2019", "IAHR7EDT", "IAHR7EFL.DTA"))
)
# Liste fermee des variables autorisees (cf. INTERDICTION).
AUTORISEES <- c("hv001", "hv002", "hv005", "hv024", "hv270", "hv271",
                "sdist", "shdistri", "shdist")

if (!requireNamespace("haven", quietly = TRUE))
  stop("PACKAGE INDISPONIBLE : haven est requis. Arret.", call. = FALSE)

# ===========================================================================
# Etape 1 : lecture (identifiants, poids, richesse seulement)
# ===========================================================================
f_geo <- p_build("37_nfhs_geo_richesse.rds")
geo <- stage("etape 1/1 identifiants, poids, richesse", f_geo, function() {
  lapply(names(VAGUES), function(v) {
    f <- VAGUES[[v]]$fichier
    check(file.exists(f), paste0(v, " : fichier present -> ", f))
    dispo <- names(haven::read_dta(f, n_max = 0L))
    vars <- intersect(AUTORISEES, dispo)
    tmsg("  lecture ", f, " : ", paste(vars, collapse = ", "))
    d <- as.data.table(lapply(haven::read_dta(f, col_select = all_of(vars)), as.numeric))
    dv <- VAGUES[[v]]$district
    if (!is.na(dv) && dv %in% names(d)) setnames(d, dv, "district")
    d[, vague := v]
    d[]
  }) |> setNames(names(VAGUES))
})

for (v in names(geo)) {
  d <- geo[[v]]
  check(all(names(d) %in% c(AUTORISEES, "district", "vague")),
        paste0(v, " : seules des variables autorisees sont chargees"))
  check(all(c("hv001", "hv002", "hv005", "hv024") %in% names(d)),
        paste0(v, " : identifiants et poids presents"))
  check(all(!is.na(d$hv001)) && all(!is.na(d$hv024)) && all(d$hv005 >= 0),
        paste0(v, " : hv001, hv024 renseignes, hv005 positif"))
  check_unique(d, c("hv024", "hv001", "hv002"), paste0(v, " menages"))
}

# ===========================================================================
# Calculs (imprimes apres le resume)
# ===========================================================================
qs <- function(x) as.list(setNames(as.numeric(quantile(x, c(0, .25, .5, .75, 1), type = 7)),
                                   c("min", "q1", "mediane", "q3", "max")))

# a. grappes
tab_a <- rbindlist(lapply(names(geo), function(v) {
  d <- geo[[v]]
  g <- d[, .N, by = .(hv024, hv001)]
  c(list(vague = v, menages = nrow(d), hv001_distincts = uniqueN(d$hv001),
         grappes = nrow(g)),
    qs(g$N),
    list(sous_10 = sum(g$N < 10), sous_15 = sum(g$N < 15), sous_20 = sum(g$N < 20)))
}))

# b. variance de hv271, intra / inter grappe, ponderee
tab_b <- rbindlist(lapply(names(geo), function(v) {
  d <- geo[[v]]
  if (!all(c("hv271", "hv270") %in% names(d)))
    return(data.table(vague = v, n = nrow(d), part_intra = NA_real_, part_inter = NA_real_,
                      grappes = NA_integer_, part_grappes_3_quintiles = NA_real_))
  d <- d[!is.na(hv271)]
  d[, w := hv005 / 1e6]
  m  <- sum(d$w * d$hv271) / sum(d$w)
  d[, mc := sum(w * hv271) / sum(w), by = .(hv024, hv001)]
  tot   <- sum(d$w * (d$hv271 - m)^2)
  intra <- sum(d$w * (d$hv271 - d$mc)^2)
  q <- d[, .(nq = uniqueN(hv270)), by = .(hv024, hv001)]
  data.table(vague = v, n = nrow(d), part_intra = 100 * intra / tot,
             part_inter = 100 * (tot - intra) / tot, grappes = nrow(q),
             part_grappes_3_quintiles = 100 * mean(q$nq >= 3))
}))

# c. districts
tab_c <- rbindlist(lapply(names(geo), function(v) {
  d <- geo[[v]]
  if (!"district" %in% names(d))
    return(data.table(vague = v, districts = NA_integer_, note = "pas de variable district (NFHS3SUP 1.5, 5.0)"))
  t <- d[, .(menages = .N, grappes = uniqueN(hv001)), by = .(hv024, district)]
  qm <- qs(t$menages); qg <- qs(t$grappes)
  data.table(vague = v, districts = nrow(t), district_codes_distincts = uniqueN(d$district),
             menages_min = qm$min, menages_q1 = qm$q1, menages_mediane = qm$mediane,
             menages_q3 = qm$q3, menages_max = qm$max,
             grappes_min = qg$min, grappes_q1 = qg$q1, grappes_mediane = qg$mediane,
             grappes_q3 = qg$q3, grappes_max = qg$max,
             districts_30_menages = sum(t$menages >= 30), districts_50_menages = sum(t$menages >= 50),
             districts_100_menages = sum(t$menages >= 100), note = "")
}), fill = TRUE)

# f. code 13 NFHS-5, relu dans la table du script 35
f35 <- p_tab("35_nfhs_distribution_hv201.csv")
p13 <- NA_real_
if (file.exists(f35)) {
  t35 <- fread(f35)
  p13 <- t35[vague == "nfhs5" & hv201 == 13, pct]
}

# ===========================================================================
# RESUME (en tete)
# ===========================================================================
hr("RESUME -- chiffres qui decident (detail en 37a a 37f)")
for (v in names(geo)) {
  a <- tab_a[vague == v]; b <- tab_b[vague == v]; cc <- tab_c[vague == v]
  msg(sprintf("%s (%s) : %s grappes, mediane %s menages/grappe ; variance hv271 intra-grappe %s ; grappes >= 3 quintiles %s ; districts %s (>= 50 menages : %s)",
              v, VAGUES[[v]]$annee, format(a$grappes, big.mark = " "), a$mediane,
              if (is.na(b$part_intra)) "n.d." else sprintf("%.1f %%", b$part_intra),
              if (is.na(b$part_grappes_3_quintiles)) "n.d." else sprintf("%.1f %%", b$part_grappes_3_quintiles),
              if (is.na(cc$districts)) "aucun" else format(cc$districts, big.mark = " "),
              if (is.na(cc$districts)) "-" else cc$districts_50_menages))
}
msg("Panel : NON. NFHS-3 a PSU brouilles et lien a la base de sondage detruit (NFHS3SUP 5.0) ; aucune cle de liaison entre vagues, GPS deplaces a chaque enquete.")
msg("Districts NFHS-3 / NFHS-4 : appariement IMPOSSIBLE, NFHS-3 sans identifiant de district (NFHS3SUP 1.5, 5.0).")
msg("hv201 = 13 piped to neighbor, NFHS-5 : ",
    if (is.na(p13)) "table du script 35 absente" else sprintf("%.2f %% des menages", p13))
msg("hv270 NFHS-5 = meme construit que NFHS-3/4 : NON ETABLI (Recode Manual inaccessible).")

# ===========================================================================
# Detail
# ===========================================================================
op <- options(width = 220)
hr("37a. Grappes : nombre et menages par grappe (cle hv024 x hv001)")
print(tab_a)
for (v in names(geo)) if (tab_a[vague == v, hv001_distincts != grappes])
  note(v, " : hv001 seul (", tab_a[vague == v, hv001_distincts], ") != (hv024, hv001) (",
       tab_a[vague == v, grappes], ") -> hv001 n'est pas unique nationalement")
fwrite(tab_a, p_tab("37_grappes.csv"))

hr("37b. Variance de hv271 : intra / inter grappe (ponderee hv005) ; grappes a >= 3 quintiles")
print(tab_b)
fwrite(tab_b, p_tab("37_variance_richesse_grappe.csv"))

hr("37c. Districts (cle hv024 x district)")
print(tab_c)
fwrite(tab_c, p_tab("37_districts.csv"))

hr("37d. Appariement des districts NFHS-3 / NFHS-4")
msg("IMPOSSIBLE : NFHS-3 n'a aucune variable district dans le fichier menage ; NFHS3SUP.PDF 1.5 a) et 5.0.")
msg("Arret sur ce point. NFHS-4 (shdistri, 640 noms) et NFHS-5 (shdist, 707 noms) portent des noms.")

hr("37e. Panel ou coupes successives")
msg("NFHS-3 : PSU et menages brouilles puis renumerotes par Etat, lien a la base de sondage rompu (NFHS3SUP 5.0).")
msg("NFHS-4 / NFHS-5 : aucune variable de liaison ; GPS deplaces aleatoirement a chaque enquete (2 / 5 / 10 km).")
msg("Independance de la selection NFHS-5 vs NFHS-4 : non documentee localement (rapport NFHS-5 vol. II, annexe A, a telecharger).")

hr("37f. Distribution brute de hv201 (deja produite, script 35)")
if (is.na(p13)) {
  warn("output/tables/35_nfhs_distribution_hv201.csv absent : relancer le script 35")
} else {
  msg(sprintf("NFHS-5, hv201 = 13 piped to neighbor : %.2f %% des menages (table complete : %s)", p13, f35))
}
options(op)

msg(""); msg("Termine. Tables dans output/tables/37_*.csv")
log_close()
