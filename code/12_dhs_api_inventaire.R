# ---------------------------------------------------------------------------
# 12_dhs_api_inventaire.R -- piste D : agregats nationaux DHS (API publique)
#   substituts prives de l'eau courante contre provision publique, par pays.
#
# CRITERE DE SELECTION FIXE AVANT EXECUTION : memo/piste_d_critere_selection.md
# Les seuils ci-dessous en sont la copie ; ne pas les changer. La provision
# publique ne joue AUCUN role dans la selection.
#
# PORTEE : descriptif national seulement. Aucune estimation, aucune regression,
# rien au niveau grappe. Ces series choisissent le cas, elles n'identifient rien.
#
# SOURCE : API DHS (api.dhsprogram.com) via rdhs, sans inscription : agregats
# publies (indicateurs deja calcules par le programme DHS), pas de microdonnees.
# Cache rdhs dans build/rdhs_cache/ (build/ est ignore par git).
#
# LANCEMENT (racine du depot) :
#     Rscript code/12_dhs_api_inventaire.R           # reprend
#     Rscript code/12_dhs_api_inventaire.R --force   # refait les appels API
#
# ETAPES RESUMABLES (build/) :
#   1. 12_indicateurs.rds  dhs_indicators() complet
#   2. 12_donnees.rds      dhs_data(), niveau national, tous types d'enquete (brut)
#   3. 12_ge.rds           dhs_datasets(fileType = "GE") (brut)
# Filtre DHS, tableaux et figures sont recalcules a chaque passage.
#
# Sorties : output/tables/12_*.csv|.tex, output/figures/12_*.pdf,
#           output/logs/12_dhs_api_inventaire.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(ggplot2)
}))
ensure_dirs()
for (d in file.path("output", c("tables", "figures")))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)
p_fig <- function(...) file.path("output", "figures", ...)

log_open(p_log("12_dhs_api_inventaire.log"))
msg("ETAPE 12 -- PISTE D : AGREGATS NATIONAUX DHS (API)")
msg("Descriptif seulement. Critere de selection : memo/piste_d_critere_selection.md")

# --- critere (memo/piste_d_critere_selection.md) ----------------------------
SEUIL_DELTA     <- 20   # points, derniere - premiere vague DHS
SEUIL_VAGUES    <- 4    # vagues DHS ou le substitut est observe
SEUIL_DECOLLAGE <- 10   # decollage = premiere vague > 10 points
SEUIL_AVANT     <- 2    # vagues observees avant le decollage
MIN_VAGUES_FIG  <- 3    # figures : pays a 3 vagues DHS ou plus (demande (b))

SUBST <- c(BOT = "WS_SRCE_H_BOT", SCH = "WS_SRCE_H_SCH", VND = "WS_SRCE_H_VND",
           TNK = "WS_SRCE_H_TNK", TUB = "WS_SRCE_H_TUB", CER = "WS_WTRT_H_CER")
LIB_SUBST <- c(BOT = "Eau en bouteille", SCH = "Eau en sachet", VND = "Vendeur",
               TNK = "Citerne (operateur inconnu)",
               TUB = "Forage (propriete inconnue)", CER = "Filtre ceramique/sable")
PUB   <- c(PIP = "WS_SRCE_H_PIP", PYD = "WS_SRCE_H_PYD", TAP = "WS_SRCE_H_TAP")
AUTRE <- c(PNB = "WS_SRCE_H_PNB", POY = "WS_SRCE_H_POY", IMP = "WS_SRCE_H_IMP")
IDS   <- c(SUBST, PUB, AUTRE)
CAS_FEUILLE <- c("GH", "NG", "DR", "JO", "ID", "LB", "MW", "UG", "CM")  # ID = Indonesie ; IA = Inde

# --- configuration rdhs -------------------------------------------------------
# rdhs exige que le fichier de configuration existe deja hors de la racine, et
# reecrit .gitignore (ajout d'une ligne, suppression des lignes vides) : on le
# sauvegarde octet pour octet et on le restaure. build/ couvre deja le cache.
cache <- p_build("rdhs_cache")
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
cfg <- file.path(cache, "rdhs.json")
if (!file.exists(cfg)) writeLines("{}", cfg)
gi <- readBin(".gitignore", "raw", file.size(".gitignore"))
invisible(capture.output(rdhs::set_rdhs_config(
  cache_path = cache, config_path = cfg, global = FALSE, prompt = FALSE,
  verbose_setup = FALSE, data_frame = "data.table::as.data.table")))
if (!identical(gi, readBin(".gitignore", "raw", file.size(".gitignore")))) {
  writeBin(gi, ".gitignore")
  note("rdhs a modifie .gitignore : version d'origine restauree")
}

# ===========================================================================
# Etapes 1-3 : appels API
# ===========================================================================
hr("12a. Appels API (etapes 1 a 3)")

ind_all <- stage("etape 1/3 indicateurs", p_build("12_indicateurs.rds"),
                 function() as.data.table(rdhs::dhs_indicators()))
check(all(IDS %in% ind_all$IndicatorId), "les 15 indicateurs demandes existent",
      paste("absents :", paste(setdiff(IDS, ind_all$IndicatorId), collapse = ", ")))
ws <- ind_all[startsWith(IndicatorId, "WS_")]
msg(sprintf("  %d indicateurs au total, %d de la famille WS_", nrow(ind_all), nrow(ws)))
fwrite(ws[, .(IndicatorId, Label, Definition, Denominator, MeasurementType)],
       p_tab("12_indicateurs_ws.csv"))

brut <- stage("etape 2/3 donnees nationales", p_build("12_donnees.rds"), function()
  as.data.table(rdhs::dhs_data(indicatorIds = unname(IDS), breakdown = "national")))
ge <- stage("etape 3/3 fichiers GE", p_build("12_ge.rds"),
            function() as.data.table(rdhs::dhs_datasets(fileType = "GE")))

# ===========================================================================
# Validation et filtre DHS
# ===========================================================================
hr("12b. Validation, filtre SurveyType == DHS")

check_vars(brut, c("SurveyId", "SurveyType", "SurveyYear", "DHS_CountryCode", "CountryName",
                   "IndicatorId", "Value", "IsPreferred", "CharacteristicLabel"), "dhs_data")
check(all(brut$CharacteristicLabel == "Total"), "dhs_data : niveau national seulement (Total)")
check(all(brut$IsPreferred == 1), "dhs_data : une valeur preferee par enquete et indicateur")
check_unique(brut, c("SurveyId", "IndicatorId"), "dhs_data")
msg("  Types d'enquete dans dhs_data :")
print(brut[, .N, keyby = SurveyType])

d <- brut[SurveyType == "DHS", .(pays = CountryName, code = DHS_CountryCode, SurveyId,
          annee = as.integer(SurveyYear), IndicatorId, valeur = as.numeric(Value))]
check(!anyNA(d$valeur), "valeurs numeriques, sans manquant")
role <- data.table(IndicatorId = IDS, cle = names(IDS),
                   role = rep(c("substitut", "public", "autre"), c(length(SUBST), length(PUB), length(AUTRE))))
d <- merge(d, role, by = "IndicatorId")
d <- merge(d, ind_all[, .(IndicatorId, libelle = Label)], by = "IndicatorId")
setcolorder(d, c("pays", "code", "SurveyId", "annee", "cle", "IndicatorId", "role", "libelle", "valeur"))
setorder(d, pays, annee, cle)
fwrite(d, p_tab("12_dhs_ws_national.csv"))
msg(sprintf("  Table tidy : %d lignes, %d pays, %d enquetes DHS",
            nrow(d), uniqueN(d$code), uniqueN(d$SurveyId)))
# plusieurs enquetes DHS la meme annee dans un pays rendraient l'axe ambigu
check_unique(unique(d[, .(code, annee, SurveyId)]), c("code", "annee"), "une enquete DHS par pays-annee")

check_vars(ge, c("SurveyId", "SurveyType", "DHS_CountryCode", "FileType"), "dhs_datasets GE")
msg("  Types d'enquete dans les fichiers GE :")
print(ge[, .N, keyby = SurveyType])
ge_dhs <- unique(ge[SurveyType == "DHS", .(code = DHS_CountryCode, SurveyId)])

# ===========================================================================
# Couverture
# ===========================================================================
hr("12c. Couverture par pays et indicateur")

autres_types <- brut[SurveyType != "DHS", .(n_mis_ais_exclues = uniqueN(SurveyId)),
                     by = .(code = DHS_CountryCode, IndicatorId)]
couv <- d[, .(n_vagues_dhs = uniqueN(SurveyId), premiere = min(annee), derniere = max(annee)),
          by = .(pays, code, cle, IndicatorId)]
couv <- merge(couv, autres_types, by = c("code", "IndicatorId"), all.x = TRUE)
couv[is.na(n_mis_ais_exclues), n_mis_ais_exclues := 0L]
couv <- merge(couv, ge_dhs[, .(n_vagues_ge_dhs = .N), by = code], by = "code", all.x = TRUE)
couv[is.na(n_vagues_ge_dhs), n_vagues_ge_dhs := 0L]
setorder(couv, pays, cle)
fwrite(couv, p_tab("12_couverture.csv"))
n3 <- couv[cle %in% names(SUBST) & n_vagues_dhs >= MIN_VAGUES_FIG, .N, keyby = cle]
msg("  Pays a 3 vagues DHS ou plus, par substitut :"); print(n3)

# ===========================================================================
# Composite public (somme des composantes presentes, jamais de 0 impute)
# ===========================================================================
pub <- d[cle %in% names(PUB), .(public = sum(valeur),
          composition = paste(sort(cle), collapse = "+")), by = .(pays, code, SurveyId, annee)]
pnb <- d[cle == "PNB", .(code, SurveyId, pnb = valeur)]
pub <- merge(pub, pnb, by = c("code", "SurveyId"), all.x = TRUE)
pub[, public_pnb := public + fifelse(is.na(pnb), 0, pnb)]
pub[is.na(pnb), public_pnb := NA_real_]  # variante definie seulement si PNB publie
rupture <- d[cle == "PNB", .(annee_pnb = min(annee)), by = code]
fwrite(pub, p_tab("12_public_composite.csv"))
msg(sprintf("  Composite public : %d enquetes ; compositions :", nrow(pub)))
print(pub[, .N, keyby = composition])

# ===========================================================================
# Selection des cas (cote prive et couverture seulement)
# ===========================================================================
hr("12d. Selection des cas selon le critere fixe")

sel <- d[cle %in% names(SUBST)][order(annee), {
  dec <- which(valeur > SEUIL_DECOLLAGE)[1]
  .(n_vagues = .N, premiere = annee[1], derniere = annee[.N],
    v_premiere = valeur[1], v_derniere = valeur[.N], delta = valeur[.N] - valeur[1],
    annee_decollage = if (is.na(dec)) NA_integer_ else annee[dec],
    n_avant = if (is.na(dec)) .N else dec - 1L)
}, by = .(pays, code, cle)]
sel[, `:=`(c1_delta = delta >= SEUIL_DELTA, c2_vagues = n_vagues >= SEUIL_VAGUES,
           c3_avant = !is.na(annee_decollage) & n_avant >= SEUIL_AVANT)]
sel[, retenu := c1_delta & c2_vagues & c3_avant]
sel[, substitut := LIB_SUBST[cle]]
setorder(sel, -retenu, -delta, -n_vagues, -n_avant)
sel[retenu == TRUE, rang := seq_len(.N)]
fwrite(sel, p_tab("12_substituts_delta.csv"))

ret <- sel[retenu == TRUE]
msg(sprintf("  Cas retenus : %d (sur %d couples pays x substitut)", nrow(ret), nrow(sel)))
op <- options(width = 200)
print(ret[, .(rang, pays, substitut, n_vagues, premiere, derniere,
              v_premiere = round(v_premiere, 1), v_derniere = round(v_derniere, 1),
              delta = round(delta, 1), annee_decollage, n_avant)])
msg("  Echecs par condition (couples a 3 vagues ou plus) :")
print(sel[n_vagues >= MIN_VAGUES_FIG, .(n = .N, c1 = sum(c1_delta), c2 = sum(c2_vagues),
                                         c3 = sum(c3_avant), retenus = sum(retenu)), keyby = cle])
options(op)

tex <- c("\\begin{tabular}{rllrrrrr}", "\\toprule",
         "Rang & Pays & Substitut & Vagues & P\\'eriode & D\\'ebut & Fin & $\\Delta$ (pts) \\\\",
         "\\midrule",
         ret[, sprintf("%d & %s & %s & %d & %d--%d & %.1f & %.1f & %.1f \\\\", rang, pays,
                       substitut, n_vagues, premiere, derniere, v_premiere, v_derniere, delta)],
         "\\bottomrule",
         sprintf("\\multicolumn{8}{l}{\\footnotesize N = %d cas retenus sur %d couples pays $\\times$ substitut. Crit\\`ere : $\\Delta \\geq %d$ pts, $\\geq %d$ vagues DHS, $\\geq %d$ vagues $\\leq %d$ pts avant le d\\'ecollage.} \\\\",
                 nrow(ret), nrow(sel), SEUIL_DELTA, SEUIL_VAGUES, SEUIL_AVANT, SEUIL_DECOLLAGE),
         "\\end{tabular}")
writeLines(tex, p_tab("12_selection_cas.tex"))

# ===========================================================================
# Figures (une passe, apres le classement)
# ===========================================================================
hr("12e. Figures")

COL <- c(prive = "#eb6834", public = "#2a78d6", ref = "grey55")  # palette de reference, slots 2 et 1
th <- theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(linewidth = 0.2),
        legend.position = "bottom", strip.text = element_text(face = "bold", hjust = 0),
        legend.key.width = unit(1.4, "lines"))

series_pays <- function(cles) {  # cles = cles courtes (BOT, TUB...), pas les IndicatorId
  s <- d[cle %in% cles, .(pays, code, annee, serie = "prive", cle, valeur)]
  p <- pub[code %in% s$code]
  rbind(s,
        p[, .(pays, code, annee, serie = "public", cle = "PUB", valeur = public)],
        p[!is.na(public_pnb), .(pays, code, annee, serie = "public_pnb", cle = "PUB", valeur = public_pnb)],
        d[code %in% s$code & cle == "IMP", .(pays, code, annee, serie = "ameliore", cle = "IMP", valeur)])
}
LAB <- c(prive = "Substitut prive", public = "Public : PIP + PYD + TAP",
         public_pnb = "Public + robinet du voisin (PNB)", ameliore = "Source amelioree (reference)")

trace_pays <- function(cle_s, codes, ordre) {
  x <- series_pays(cle_s)[code %in% codes]
  x[, pays := factor(pays, levels = ordre)]
  comp <- pub[code %in% codes][, pays := factor(pays, levels = ordre)]
  rup <- merge(rupture[code %in% codes], unique(x[, .(code, pays)]), by = "code")
  ggplot(x, aes(annee, valeur, colour = serie, linetype = serie)) +
    geom_vline(data = rup, aes(xintercept = annee_pnb), colour = "grey70", linewidth = 0.3,
               linetype = "dotted", inherit.aes = FALSE) +
    geom_line(aes(linewidth = serie)) +
    geom_point(data = x[serie == "prive"], size = 1.3) +
    geom_point(data = comp, aes(annee, public, shape = composition), colour = COL[["public"]],
               size = 1.3, inherit.aes = FALSE) +
    facet_wrap(~ pays, ncol = 5) +
    scale_colour_manual(values = c(prive = COL[["prive"]], public = COL[["public"]],
                                   public_pnb = COL[["public"]], ameliore = COL[["ref"]]), labels = LAB) +
    scale_linetype_manual(values = c(prive = "solid", public = "solid", public_pnb = "dashed",
                                     ameliore = "dotted"), labels = LAB) +
    scale_linewidth_manual(values = c(prive = 0.6, public = 0.6, public_pnb = 0.4, ameliore = 0.3),
                           guide = "none") +
    scale_y_continuous(limits = c(0, 100), breaks = c(0, 50, 100)) +
    labs(x = NULL, y = "% des menages", colour = NULL, linetype = NULL,
         shape = "Composantes publiques") + th
}

trace_composantes <- function(cle_s, codes, ordre) {
  x <- rbind(d[code %in% codes & cle %in% c(cle_s, names(PUB), "PNB"), .(pays, annee, cle, valeur)])
  x[, pays := factor(pays, levels = ordre)]
  x[, cle := factor(cle, levels = c(cle_s, "PIP", "PYD", "TAP", "PNB"))]
  ggplot(x, aes(annee, valeur, colour = cle)) + geom_line(linewidth = 0.5) + geom_point(size = 1) +
    facet_wrap(~ pays, ncol = 5) +
    scale_colour_manual(values = setNames(c(COL[["prive"]], "#2a78d6", "#1baf7a", "#eda100", "#e87ba4"),
                                          c(cle_s, "PIP", "PYD", "TAP", "PNB")), drop = TRUE) +
    scale_y_continuous(limits = c(0, 100), breaks = c(0, 50, 100)) +
    labs(x = NULL, y = "% des menages", colour = NULL) + th
}

etiquette <- function(s) s[, sprintf("%s  (%+.0f)%s", pays, delta, fifelse(retenu, "  *", ""))]

fig_substitut <- function(cle_s, f) {
  s <- sel[cle == cle_s & n_vagues >= MIN_VAGUES_FIG][order(-delta)]
  if (!nrow(s)) { note("pas de pays a 3 vagues pour ", cle_s); return(invisible()) }
  s[, lab := etiquette(s)]
  lab_map <- setNames(s$lab, s$pays)
  h <- 1.6 * ceiling(nrow(s) / 5) + 1.2
  pdf(f, width = 9, height = h)
  for (p in list(trace_pays(cle_s, s$code, s$pays), trace_composantes(cle_s, s$code, s$pays)))
    print(p + facet_wrap(~ pays, ncol = 5, labeller = as_labeller(lab_map)))
  dev.off()
  msg(sprintf("  %s : %d pays (page 1 composite, page 2 composantes)", basename(f), nrow(s)))
}

# la bouteille d'abord : famille la plus solide (achat a l'unite, sans ambiguite de propriete)
fig_substitut("BOT", p_fig("12_traj_BOT.pdf"))
for (k in setdiff(names(SUBST), "BOT")) fig_substitut(k, p_fig(sprintf("12_traj_%s.pdf", k)))

# pays de la feuille de route : un panneau par pays, facettes par substitut
x <- rbindlist(lapply(names(SUBST), function(k) series_pays(k)[, substitut := LIB_SUBST[[k]]]))
x <- x[code %in% CAS_FEUILLE]
avec_prive <- unique(x[serie == "prive", .(code, substitut)])
x <- x[avec_prive, on = .(code, substitut)]
x[, substitut := factor(substitut, levels = LIB_SUBST)]
p <- ggplot(x, aes(annee, valeur, colour = serie, linetype = serie)) +
  geom_line(linewidth = 0.5) + geom_point(data = x[serie == "prive"], size = 1) +
  facet_grid(pays ~ substitut) +
  scale_colour_manual(values = c(prive = COL[["prive"]], public = COL[["public"]],
                                 public_pnb = COL[["public"]], ameliore = COL[["ref"]]), labels = LAB) +
  scale_linetype_manual(values = c(prive = "solid", public = "solid", public_pnb = "dashed",
                                   ameliore = "dotted"), labels = LAB) +
  scale_y_continuous(limits = c(0, 100), breaks = c(0, 50, 100)) +
  labs(x = NULL, y = "% des menages", colour = NULL, linetype = NULL) + th +
  theme(strip.text.y = element_text(angle = 0, hjust = 0))
ggsave(p_fig("12_cas_feuille_de_route.pdf"), p, width = 10, height = 12)
msg("  12_cas_feuille_de_route.pdf : ", uniqueN(x$code), " pays")

hr("ETAPE 12 TERMINEE")
for (f in sort(c(list.files(p_tab(), pattern = "^12_"), list.files(p_fig(), pattern = "^12_"))))
  msg("  ", f)
log_close()
