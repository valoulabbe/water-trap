# ---------------------------------------------------------------------------
# 18_puissance_descriptive.R -- Piste E : le plan tarif x exposition a-t-il de
#   la puissance ? Comptes d'Etats et de villages identifiants par intervalle
#   censitaire. AUCUNE regression, aucune variable de resultat.
#
# LOGIQUE : le tarif agricole varie par Etat x date ; l'exposition varie entre
#   villages (SHRUG, etape 17) ou districts (CGWB, etape 16) au sein de l'Etat.
#   Un Etat n'identifie que s'il a (i) assez d'unites et (ii) assez d'ecart
#   d'exposition en son sein. Les changements de tarif ne sont pas encore
#   collectes : les comptes ci-dessous sont des BORNES SUPERIEURES (un Etat
#   sans changement de tarif dans l'intervalle n'identifiera pas).
#
# CRITERE (ecrit le 02/10/2026, avant tout compte ; ne pas modifier apres)
#   Bras village (SHRUG), par intervalle 1991-2001 (expo 1991), 2001-2011 (expo 2001) :
#     village identifiant = shrid present dans les deux repertoires de
#       l'intervalle, exposition de debut non manquante, Etat-annee sans
#       drapeau MANQUANT / ZEROS_SUSPECTS / SATURE / QUASI_NUL (etape 17).
#     Etat identifiant = >= 100 villages identifiants ET p90 - p10 de
#       l'exposition (tous villages, non irrigue = 0) >= 0,30.
#   Bras district (CGWB, fenetre 1996-2000) :
#     Etat identifiant = >= 5 districts a >= 5 puits ET ecart (max - min) des
#       profondeurs moyennes de district >= 5 m.
#     Pour 1991-2001 la profondeur de base est mesuree EN COURS d'intervalle :
#       signale, compte quand meme.
#   Verdict par bras et par intervalle :
#     PUISSANCE si >= 15 Etats identifiants ; MINCE si 8 a 14 ; AUCUNE si < 8.
#   Lecture : la collecte des tarifs ne vaut la peine que si le bras village
#     est PUISSANCE pour au moins un intervalle.
#
# PREALABLE : etapes 16 et 17 terminees sans echec de controle.
# LANCEMENT : Rscript code/18_puissance_descriptive.R
# Sorties : output/tables/18_*.csv, output/logs/18_puissance_descriptive.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("18_puissance_descriptive.log"))
msg("ETAPE 18 -- PISTE E : PUISSANCE DESCRIPTIVE (comptes seulement)")

MIN_VIL <- 100L; MIN_P9010 <- 0.30
MIN_DIST <- 5L; MIN_PUITS <- 5L; MIN_ECART_M <- 5
DRAP_EXCLUS <- c("MANQUANT", "ZEROS_SUSPECTS", "SATURE", "QUASI_NUL")
verdict <- function(n) if (n >= 15) "PUISSANCE" else if (n >= 8) "MINCE" else "AUCUNE"

# --- prealables ---------------------------------------------------------------
f17v <- p_build("17_exposition_village.rds"); f17d <- p_tab("17_drapeaux.csv")
f16  <- p_tab("16_profondeur_district.csv")
check(all(file.exists(c(f17v, f17d, f16))), "sorties des etapes 16 et 17 presentes")
check(file.mtime(f17d) >= file.mtime(f17v), "17_drapeaux.csv posterieur a l'exposition village (etape 17 allee au bout)")

vil  <- as.data.table(readRDS(f17v))
drap <- fread(f17d)
noms <- as.data.table(readRDS(p_build("shrid_loc_names.rds")))[, .(shrid2, state_name)]
vil  <- merge(vil, noms, by = "shrid2")
# exposition : meme definition qu'a l'etape 17 (non stockee dans le .rds)
vil[, expo := fifelse(tot_irr > 0, pmin(tw_w_el / tot_irr, 1),
              fifelse(tot_irr == 0 & tw_w_el == 0, 0, NA_real_))]
present <- lapply(c(`1991` = "pc91", `2001` = "pc01", `2011` = "pc11"), function(p)
  readRDS(p_build(sprintf("%s_vd_clean_shrid.rds", p)))$shrid2)

# ===========================================================================
hr("18a. Bras village (SHRUG)")
# ===========================================================================
INTERVALLES <- list(`1991-2001` = c(1991, 2001), `2001-2011` = c(2001, 2011))

vv <- rbindlist(lapply(names(INTERVALLES), function(i) {
  a <- INTERVALLES[[i]]
  x <- vil[annee == a[1]]
  x[, panel := shrid2 %in% present[[as.character(a[2])]]]
  x <- merge(x, drap[annee == a[1], .(state_name, drapeaux)], by = "state_name", all.x = TRUE)
  x[, exclu := grepl(paste(DRAP_EXCLUS, collapse = "|"), drapeaux) | is.na(drapeaux)]
  x[, ident := panel & !is.na(expo) & !exclu]
  x[, intervalle := i]
}))

cascade <- vv[, .(villages_debut = .N, panel = sum(panel), panel_expo_connue = sum(panel & !is.na(expo)),
                  identifiants = sum(ident)), by = intervalle]
print(cascade)
fwrite(cascade, p_tab("18_cascade_villages.csv"))

ev <- vv[, .(villages = .N, panel = sum(panel), identifiants = sum(ident),
             drapeaux = drapeaux[1],
             p10 = if (sum(ident)) quantile(expo[ident], .1, names = FALSE) else NA_real_,
             p90 = if (sum(ident)) quantile(expo[ident], .9, names = FALSE) else NA_real_,
             sd  = if (sum(ident) > 1) sd(expo[ident]) else NA_real_),
         by = .(intervalle, state_name)]
ev[, p90_p10 := round(p90 - p10, 3)]
ev[, etat_identifiant := identifiants >= MIN_VIL & (p90_p10 >= MIN_P9010) %in% TRUE]
setorder(ev, intervalle, -identifiants)
op <- options(width = 220); print(ev); options(op)
fwrite(ev, p_tab("18_village_par_etat.csv"))

# ===========================================================================
hr("18b. Bras district (CGWB, fenetre 1996-2000)")
# ===========================================================================
dd <- fread(f16)[fenetre == "base_1996_2000"]
ed <- dd[, .(districts = .N, districts_5_puits = sum(n_puits >= MIN_PUITS),
             ecart_m = if (any(n_puits >= MIN_PUITS))
               diff(range(prof_moy[n_puits >= MIN_PUITS])) else NA_real_),
         by = state_name]
ed[, etat_identifiant := districts_5_puits >= MIN_DIST & (ecart_m >= MIN_ECART_M) %in% TRUE]
setorder(ed, -districts_5_puits)
print(ed)
fwrite(ed, p_tab("18_district_par_etat.csv"))

# ===========================================================================
hr("18c. Verdict contre le critere ecrit")
# ===========================================================================
ver <- rbind(
  ev[, .(bras = "village (SHRUG)", etats_identifiants = sum(etat_identifiant),
         villages_identifiants = sum(identifiants[etat_identifiant])), by = intervalle],
  data.table(intervalle = c("1991-2001 (base CGWB en cours d'intervalle)", "2001-2011"),
             bras = "district (CGWB)", etats_identifiants = sum(ed$etat_identifiant),
             villages_identifiants = NA_integer_))
ver[, verdict := vapply(etats_identifiants, verdict, character(1))]
print(ver)
fwrite(ver, p_tab("18_verdict.csv"))
msg("  Bornes superieures : les Etats sans changement de tarif dans l'intervalle n'identifient pas.")

hr("ETAPE 18 TERMINEE")
log_close()
