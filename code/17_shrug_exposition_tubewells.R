# ---------------------------------------------------------------------------
# 17_shrug_exposition_tubewells.R -- Piste E : exposition du village au tarif
#   electrique agricole = part de la surface irriguee arrosee par forage
#   electrique (tube-well with electricity), recensements 1991 et 2001.
#
# PORTEE : DESCRIPTIF. Aucune variable d'eau potable / provision publique lue.
#
# CONSTRUCTION (fixee avant execution)
#   expo = tw_w_el / tot_irr        si tot_irr > 0
#        = 0                        si tot_irr == 0 et tw_w_el == 0 (village non
#                                   irrigue : pas expose au tarif agricole)
#        = NA                       sinon (tw_w_el ou tot_irr manquant)
#   Denominateur tot_irr et non la surface du village : pc91_vd_area manque
#   pour 49 % des villages (constate a l'inventaire du 02/10, avant ce script).
#   pc01 n'a PAS de well_w_el (puits ouvert avec electricite) : la somme des
#   sources n'a donc pas la meme liste en 1991 et 2001 (journalise).
#   Etat : state_name de shrid_loc_names (frontieres 2011).
#   DECISION 02/10/2026 (accord explicite) : le seuil initial de 99 % de shrid
#     nommes a echoue (1991 : 98,77 % ; 2001 : 98,90 %). Les shrid sans nom sont
#     tous absents de la cle rurale 2011 (villages sortis du cadre : fusion,
#     urbanisation, recodage). Couverture acceptee, seuil abaisse a 98,5 %, ces
#     villages sont exclus et leur nombre est journalise.
#
# DIAGNOSTICS PAR VILLAGE
#   ventil_vide : tot_irr > 0 mais somme des sources d'irrigation == 0
#                 (ventilation non saisie : tw_w_el = 0 est un faux zero)
#   sol_vide    : tot_irr == 0 et un_irr == 0 (bloc d'occupation du sol vide :
#                 tot_irr = 0 est possiblement un faux zero)
#   incoherent  : tw_w_el > tot_irr + 0,5 ha
#
# DRAPEAUX PAR ETAT x ANNEE (Etats d'au moins 100 villages ; seuils fixes ici)
#   MANQUANT        tw_w_el manquant pour > 30 % des villages
#   ZEROS_SUSPECTS  (ventil_vide + sol_vide) >= 15 % des villages renseignes
#   SATURE          >= 50 % des villages irrigues (hors ventil_vide) ont expo >= 0,95
#   QUASI_NUL       < 5 % des villages irrigues (hors ventil_vide) ont tw_w_el > 0
#   INCOHERENT      > 5 % des villages renseignes incoherents
#
# ATTENDUS (ecrits avant la premiere execution)
#   Bloquants (check) : nombres de lignes SHRUG (564 855 / 527 920), cle shrid2
#     unique et chaine, variables presentes par nom exact, >= 98,5 % des shrid
#     avec un nom d'Etat, unite plausible (mediane de tot_irr / area <= 1 la
#     ou les deux sont > 0).
#   Descriptifs (non bloquants, ecart signale) :
#     A1. 1991 : tw_w_el manquant ~34 % au national (vu a l'inventaire).
#     A2. 2001 : quasi aucun manquant (0,2 %) -> on attend des ZEROS_SUSPECTS
#         dans plusieurs Etats en 2001 (blancs probablement codes 0).
#     A3. Punjab, Haryana, Uttar Pradesh : exposition mediane des villages
#         irrigues > 0,5, au moins un SATURE parmi eux.
#     A4. Nord-Est, Kerala, Etats de collines : QUASI_NUL.
#
# LANCEMENT : Rscript code/17_shrug_exposition_tubewells.R [--force]
# ETAPE RESUMABLE : build/17_exposition_village.rds (micro, jamais dans git)
# Sorties : output/tables/17_*.csv (agregats par Etat), log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("17_shrug_exposition_tubewells.log"))
msg("ETAPE 17 -- PISTE E : EXPOSITION FORAGE ELECTRIQUE (SHRUG 1991, 2001)")
msg("Descriptif : aucune variable d'eau potable lue.")

ANNEES <- list(
  "1991" = list(f = "shrug-vd91-dta/pc91_vd_clean_shrid.dta", n = 564855L, p = "pc91_vd_",
                src = c("tw_w_el", "tw_wo_el", "well_w_el", "well_wo_el", "canal_govt",
                        "canal_pvt", "tank_irr", "river_irr", "lake_irr", "oth_irr")),
  "2001" = list(f = "shrug-vd01-dta/pc01_vd_clean_shrid.dta", n = 527920L, p = "pc01_vd_",
                src = c("tw_w_el", "tw_wo_el", "well_wo_el", "canal_govt",
                        "canal_pvt", "tank_irr", "river_irr", "lake_irr", "oth_irr")))
MIN_VIL <- 100L

ecart <- function(ok, quoi, obs) {
  if (isTRUE(ok)) msg("  [ATTENDU]  ", quoi, " -- observe : ", obs)
  else            msg("  [ECART]    ", quoi, " -- observe : ", obs, "  <-- a signaler")
}

# ===========================================================================
hr("17a. Construction de l'exposition par village (etape resumable)")
# ===========================================================================

noms <- as.data.table(readRDS(p_build("shrid_loc_names.rds")))[, .(shrid2, state_name)]
check_unique(noms, "shrid2", "shrid_loc_names")

f_v <- p_build("17_exposition_village.rds")
vil <- stage("etape 1/1 exposition village", f_v, function() {
  rbindlist(lapply(names(ANNEES), function(a) {
    s <- ANNEES[[a]]
    d <- as.data.table(read_dta_chk(p_raw("shrug", s$f)))
    tmsg("  ", a, " : lu depuis ", last_read_source()$path)
    v <- paste0(s$p, c(s$src, "tot_irr", "un_irr", "area", "power_agr"))
    check_rows(d, s$n, paste("pc", a))
    check_chr_key(d, "shrid2", paste("pc", a))
    check_unique(d, "shrid2", paste("pc", a))
    check_vars(d, v, paste("pc", a))
    x <- d[, c("shrid2", v), with = FALSE]
    setnames(x, v, sub(s$p, "", v, fixed = TRUE))
    x[, somme_src := rowSums(.SD, na.rm = TRUE), .SDcols = s$src]
    x[, src_tout_na := rowSums(!is.na(.SD)) == 0, .SDcols = s$src]
    x[, annee := as.integer(a)]
    x[, c("shrid2", "annee", "tw_w_el", "tot_irr", "un_irr", "area", "power_agr",
          "somme_src", "src_tout_na"), with = FALSE]
  }))
})

vil <- merge(vil, noms, by = "shrid2", all.x = TRUE)
for (a in names(ANNEES)) {
  p_nom <- vil[annee == as.integer(a), mean(!is.na(state_name))]
  check(p_nom >= 0.985, sprintf("%s : >= 98,5 %% des shrid ont un nom d'Etat", a),
        sprintf("observe %.2f %%", 100 * p_nom))
  r <- vil[annee == as.integer(a) & tot_irr > 0 & area > 0, median(tot_irr / area)]
  check(r <= 1, sprintf("%s : mediane tot_irr / area <= 1 (memes unites)", a),
        sprintf("observe %.3f", r))
  msg(sprintf("  %s : mediane tot_irr / area (villages irrigues a surface connue) = %.3f", a, r))
}
msg(sprintf("  shrid sans nom d'Etat exclus : 1991 = %d ; 2001 = %d",
            vil[annee == 1991 & is.na(state_name), .N], vil[annee == 2001 & is.na(state_name), .N]))
vil <- vil[!is.na(state_name)]

vil[, ventil_vide := tot_irr > 0 & somme_src == 0]
vil[, sol_vide    := tot_irr == 0 & un_irr %in% 0]
vil[, incoherent  := tw_w_el > tot_irr + 0.5]
vil[, expo := fifelse(tot_irr > 0, pmin(tw_w_el / tot_irr, 1),
              fifelse(tot_irr == 0 & tw_w_el == 0, 0, NA_real_))]
vil[, irrigue := tot_irr > 0 & !ventil_vide]
msg("  expo plafonnee a 1 quand tw_w_el > tot_irr (comptes dans 'incoherent').")

# ===========================================================================
hr("17b. Distribution nationale par annee")
# ===========================================================================

q <- function(x, p) as.numeric(quantile(x, p, na.rm = TRUE, names = FALSE))
resume <- function(d) d[, .(
  villages = .N,
  tw_manquant_pct = round(100 * mean(is.na(tw_w_el)), 1),
  tot_irr_manquant_pct = round(100 * mean(is.na(tot_irr)), 1),
  irrigues_pct = round(100 * mean(irrigue %in% TRUE), 1),
  ventil_vide_pct = round(100 * mean(ventil_vide %in% TRUE), 1),
  sol_vide_pct = round(100 * mean(sol_vide %in% TRUE), 1),
  incoherent_pct = round(100 * mean(incoherent %in% TRUE), 1),
  zeros_susp_pct = round(100 * mean((ventil_vide | sol_vide)[!is.na(tw_w_el)], na.rm = TRUE), 1),
  tw_pos_parmi_irrigues_pct = round(100 * mean(tw_w_el[irrigue %in% TRUE] > 0, na.rm = TRUE), 1),
  # parmi les villages irrigues (ventilation saisie)
  expo_moy_irr = round(mean(expo[irrigue %in% TRUE], na.rm = TRUE), 3),
  expo_med_irr = round(q(expo[irrigue %in% TRUE], .5), 3),
  expo_p10_irr = round(q(expo[irrigue %in% TRUE], .1), 3),
  expo_p90_irr = round(q(expo[irrigue %in% TRUE], .9), 3),
  expo_sd_irr  = round(sd(expo[irrigue %in% TRUE], na.rm = TRUE), 3),
  sature_pct_irr = round(100 * mean(expo[irrigue %in% TRUE] >= 0.95, na.rm = TRUE), 1),
  interieur_pct_irr = round(100 * mean(expo[irrigue %in% TRUE] > 0.05 &
                                         expo[irrigue %in% TRUE] < 0.95, na.rm = TRUE), 1),
  # tous villages renseignes (non irrigue = 0)
  expo_moy_tous = round(mean(expo, na.rm = TRUE), 3),
  expo_sd_tous  = round(sd(expo, na.rm = TRUE), 3),
  expo_p90_tous = round(q(expo, .9), 3))]

nat <- vil[, resume(.SD), by = annee]
op <- options(width = 220); print(nat); options(op)
fwrite(nat, p_tab("17_national.csv"))

ecart(abs(nat[annee == 1991, tw_manquant_pct] - 34) <= 3, "A1 : 1991, tw_w_el manquant ~34 %",
      paste0(nat[annee == 1991, tw_manquant_pct], " %"))
ecart(nat[annee == 2001, tw_manquant_pct] < 1, "A2 : 2001, tw_w_el presque jamais manquant",
      paste0(nat[annee == 2001, tw_manquant_pct], " %"))

# ===========================================================================
hr("17c. Par Etat et par annee, avec drapeaux")
# ===========================================================================

et <- vil[, resume(.SD), by = .(annee, state_name)]
et[, drapeaux := ""]
add <- function(cond, lab) et[villages >= MIN_VIL & cond %in% TRUE,
                              drapeaux := trimws(paste(drapeaux, lab))]
add(et$tw_manquant_pct > 30, "MANQUANT")
add(et$zeros_susp_pct >= 15, "ZEROS_SUSPECTS")
add(et$sature_pct_irr >= 50, "SATURE")
add(et$tw_pos_parmi_irrigues_pct < 5, "QUASI_NUL")
add(et$incoherent_pct > 5, "INCOHERENT")
et[villages < MIN_VIL, drapeaux := "(moins de 100 villages)"]
et[drapeaux == "", drapeaux := "-"]
setorder(et, annee, -villages)
op <- options(width = 260)
print(et[, .(annee, state_name, villages, tw_manquant_pct, zeros_susp_pct, irrigues_pct,
             tw_pos_parmi_irrigues_pct, expo_med_irr, expo_p10_irr, expo_p90_irr, expo_sd_irr,
             sature_pct_irr, interieur_pct_irr, expo_sd_tous, drapeaux)])
options(op)
fwrite(et, p_tab("17_par_etat_annee.csv"))

hr("17d. Drapeaux : recapitulatif")
dr <- et[villages >= MIN_VIL & drapeaux != "-",
         .(etats = paste(state_name, collapse = ", ")),
         by = .(annee, drapeau = drapeaux)]
setorder(dr, annee, drapeau)
op <- options(width = 220); print(dr); options(op)
fwrite(et[villages >= MIN_VIL, .(annee, state_name, villages, drapeaux)],
       p_tab("17_drapeaux.csv"))

# A3 / A4
pp <- et[state_name %in% c("punjab", "haryana", "uttar pradesh")]
ecart(all(pp$expo_med_irr > 0.5) && any(grepl("SATURE", pp$drapeaux)),
      "A3 : Punjab/Haryana/UP, mediane > 0,5 et au moins un SATURE",
      paste(sprintf("%s %d med=%.2f [%s]", pp$state_name, pp$annee, pp$expo_med_irr, pp$drapeaux),
            collapse = " ; "))
ne <- et[state_name %in% c("assam", "meghalaya", "kerala", "himachal pradesh", "uttarakhand",
                           "arunachal pradesh", "nagaland", "manipur", "mizoram", "tripura",
                           "sikkim", "jammu kashmir") & villages >= MIN_VIL]
ecart(all(grepl("QUASI_NUL", ne$drapeaux)), "A4 : Nord-Est / Kerala / collines QUASI_NUL",
      paste(sprintf("%s %d [%s]", ne$state_name, ne$annee, ne$drapeaux), collapse = " ; "))

hr("ETAPE 17 TERMINEE")
for (f in sort(list.files(file.path("output", "tables"), "^17_"))) note(f)
log_close()
