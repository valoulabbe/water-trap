# ---------------------------------------------------------------------------
# 29_piste_a_prime_geologie_fine.R -- porte A' de la piste A :
#   la geologie FINE (Ryan & Sudarshan 2022 : potentiel en eau souterraine au
#   1:50k, lineaments) predit-elle la profondeur du puits hors echantillon,
#   au-dela des effets fixes de SDO ? (Rajasthan, 6 SDO)
#
# CRITERE FIXE AVANT ESTIMATION : memo/piste_a_prime_geologie_fine_critere.md
# Les seuils ci-dessous en sont la copie ; ne pas les changer.
#
# PORTEE : premier stage seulement, test passe / echoue. AUCUNE variable de
# resultat, AUCUN second stage, AUCUN appariement aux villages SHRUG.
#
# DONNEES : raw/nicholasryan2021/20200932data/rationing_commons/data/work/
#   marginal_analysis_sample.dta            un agriculteur par ligne (6 215)
#   marginal_analysis_sample_crop_level.dta  pour sdo_feeder_code seulement
#   depth_data.txt                           annee de forage (hors critere)
#
# LANCEMENT (racine du depot) :
#     Rscript code/29_piste_a_prime_geologie_fine.R           # reprend
#     Rscript code/29_piste_a_prime_geologie_fine.R --force   # refait tout
#
# ETAPE RESUMABLE (build/) :
#   1. 29_echantillon.rds   agriculteurs + profondeur + geologie + depart
# Les estimations sont toujours recalculees (quelques secondes).
#
# Sorties : output/tables/29_*.csv, output/logs/29_piste_a_prime_geologie_fine.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(fixest)
}))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("29_piste_a_prime_geologie_fine.log"))

# --- seuils du critere (memo/piste_a_prime_geologie_fine_critere.md) ---------
SEUIL_PART_INTRA <- 0.25
SEUIL_GAIN_R2CV  <- 0.05
N_PLIS           <- 10L
GRAINE           <- 20261006L
N_MIN            <- 3800L

RS <- p_raw("nicholasryan2021", "20200932data", "rationing_commons", "data", "work")
f_far  <- file.path(RS, "marginal_analysis_sample.dta")
f_crop <- file.path(RS, "marginal_analysis_sample_crop_level.dta")
f_dug  <- file.path(RS, "depth_data.txt")

msg("ETAPE 29 -- PISTE A' : LA GEOLOGIE FINE PREDIT-ELLE LA PROFONDEUR ? (RAJASTHAN)")
msg("")
msg("Critere fixe avant estimation : memo/piste_a_prime_geologie_fine_critere.md")
msg(sprintf("  (1) part intra-SDO de la variance de profondeur >= %.2f", SEUIL_PART_INTRA))
msg(sprintf("  (2) gain de R2 hors echantillon (%d plis de departs entiers) >= %.2f",
            N_PLIS, SEUIL_GAIN_R2CV))
msg("Aucun second stage, aucune variable de resultat.")

# ===========================================================================
# Etape 1 : echantillon
# ===========================================================================
hr("29a. Echantillon (etape 1)")

f_ech <- p_build("29_echantillon.rds")
ech <- stage("etape 1/1 echantillon", f_ech, function() {
  nm <- names(haven::read_dta(f_far, n_max = 1))
  geo <- c("dist2fault_km", "ltot_1km", "ltot_5km",
           grep("^rock_type_[0-9]+$", nm, value = TRUE),
           grep("^rock_area_[0-9]+$", nm, value = TRUE),
           grep("^aquifer_type_[0-9]+$", nm, value = TRUE))
  vars <- c("f_id", "SDO", "farmer_well_depth", "farmer_well_depth_wins",
            "elevation", "slope", geo)
  check_vars(setNames(as.list(nm), nm), vars, "marginal_analysis_sample")
  check(length(grep("^rock_type_", geo)) == 65L && length(grep("^rock_area_", geo)) == 65L &&
          length(grep("^aquifer_type_", geo)) == 20L,
        "bloc geologie : 65 types de roche, 65 parts de roche, 20 aquiferes")
  tmsg("lecture de ", f_far)
  d <- as.data.table(haven::zap_labels(haven::read_dta(f_far, col_select = all_of(vars))))
  check_rows(d, 6215L, "marginal_analysis_sample")
  check_unique(d, "f_id", "marginal_analysis_sample")

  tmsg("lecture des departs dans ", f_crop)
  fe <- unique(as.data.table(haven::zap_labels(haven::read_dta(
    f_crop, col_select = c("f_id", "sdo_feeder_code")))))
  check_unique(fe, "f_id", "departs (un depart par agriculteur)")

  d <- merge(d, fe, by = "f_id", all.x = TRUE)
  d[, elevation := suppressWarnings(as.numeric(elevation))]
  d[, slope     := suppressWarnings(as.numeric(slope))]

  n0 <- nrow(d)
  d <- d[!is.na(farmer_well_depth) & farmer_well_depth > 0]
  msg(sprintf("  profondeur > 0 et renseignee : %d / %d", nrow(d), n0))
  n1 <- nrow(d)
  d <- d[complete.cases(d[, ..geo])]
  msg(sprintf("  bloc geologie complet : %d / %d", nrow(d), n1))
  n2 <- nrow(d)
  d <- d[!is.na(elevation) & !is.na(slope)]
  msg(sprintf("  altitude et pente numeriques : %d / %d", nrow(d), n2))
  n3 <- nrow(d)
  d <- d[!is.na(sdo_feeder_code)]
  msg(sprintf("  depart connu : %d / %d", nrow(d), n3))
  d
}, after = c(f_far, f_crop))

geo <- grep("^(dist2fault_km|ltot_[15]km|rock_type_[0-9]+|rock_area_[0-9]+|aquifer_type_[0-9]+)$",
            names(ech), value = TRUE)
check(nrow(ech) >= N_MIN, sprintf("echantillon >= %d agriculteurs (critere)", N_MIN),
      sprintf("observe %d", nrow(ech)))
msg(sprintf("  N = %d agriculteurs, %d departs, %d SDO", nrow(ech),
            uniqueN(ech$sdo_feeder_code), uniqueN(ech$SDO)))
print(ech[, .(agriculteurs = .N, departs = uniqueN(sdo_feeder_code),
              prof_moy_pieds = round(mean(farmer_well_depth), 1),
              prof_et = round(sd(farmer_well_depth), 1)), by = SDO])

# ===========================================================================
# Porte
# ===========================================================================
hr("29b. Porte du premier stage")

dat <- copy(ech)
dat[, sdo := factor(SDO)]
# colonnes constantes retirees mecaniquement (critere)
geo <- geo[vapply(geo, function(v) uniqueN(dat[[v]]) > 1L, logical(1))]
msg(sprintf("  bloc geologie : %d colonnes non constantes", length(geo)))
ctrl <- c("elevation", "slope")

# plis : departs entiers, affectation aleatoire (graine du critere)
set.seed(GRAINE)
dep <- sort(unique(dat$sdo_feeder_code))
pli_dep <- data.table(sdo_feeder_code = dep,
                      pli = sample(rep_len(seq_len(N_PLIS), length(dep))))
dat <- merge(dat, pli_dep, by = "sdo_feeder_code")
setorder(dat, f_id)

demean <- function(M, g) M - apply(M, 2, function(v) ave(v, g))

# R2 hors echantillon, tout centre par SDO sur l'echantillon entier ; un
# coefficient non identifie dans un pli compte pour zero.
cv_r2 <- function(y, X, fold) {
  pred <- numeric(length(y))
  for (k in sort(unique(fold))) {
    te <- fold == k
    b  <- stats::lm.fit(X[!te, , drop = FALSE], y[!te])$coefficients
    b[is.na(b)] <- 0
    pred[te] <- X[te, , drop = FALSE] %*% b
  }
  1 - sum((y - pred)^2) / sum(y^2)
}

gain_r2 <- function(d, yvar, geo_cols, ctrl_cols, fold, fe = d$sdo) {
  y  <- d[[yvar]] - ave(d[[yvar]], fe)
  Xc <- demean(as.matrix(d[, ..ctrl_cols]), fe)
  Xg <- demean(as.matrix(d[, ..geo_cols]), fe)
  r_c <- cv_r2(y, Xc, fold)
  r_f <- cv_r2(y, cbind(Xg, Xc), fold)
  c(r2cv_controles = r_c, r2cv_geo_controles = r_f, gain = r_f - r_c)
}

# (1) part intra-SDO
y <- dat$farmer_well_depth
part_intra <- sum((y - ave(y, dat$sdo))^2) / sum((y - mean(y))^2)
msg(sprintf("  (1) part intra-SDO de la variance : %.3f  (seuil %.2f) -> %s",
            part_intra, SEUIL_PART_INTRA, if (part_intra >= SEUIL_PART_INTRA) "PASSE" else "ECHOUE"))

# (2) gain de R2 hors echantillon
g <- gain_r2(dat, "farmer_well_depth", geo, ctrl, dat$pli)
msg(sprintf("  (2) R2 hors echantillon (intra-SDO) : controles seuls %.3f ; geologie + controles %.3f",
            g["r2cv_controles"], g["r2cv_geo_controles"]))
msg(sprintf("      gain du bloc geologie : %.3f  (seuil %.2f) -> %s",
            g["gain"], SEUIL_GAIN_R2CV, if (g["gain"] >= SEUIL_GAIN_R2CV) "PASSE" else "ECHOUE"))
msg(sprintf("      (%d plis, %d departs)", N_PLIS, length(dep)))

# Pour information : estimation sur tout l'echantillon et F partiel.
fml <- as.formula(paste("farmer_well_depth ~", paste(c(geo, ctrl), collapse = " + "), "| sdo"))
est <- feols(fml, data = dat, cluster = ~sdo_feeder_code)
wt  <- wald(est, keep = paste0("^(", paste(geo, collapse = "|"), ")$"), print = FALSE)
r2_in <- r2(est, "wr2")
est_c <- feols(as.formula(paste("farmer_well_depth ~", paste(ctrl, collapse = " + "), "| sdo")),
               data = dat)
msg("")
msg("  Pour information (hors critere) : tout l'echantillon, effets fixes de SDO,")
msg("  erreurs groupees par depart.")
msg(sprintf("  R2 intra dans l'echantillon : controles seuls %.3f ; geologie + controles %.3f",
            r2(est_c, "wr2"), r2_in))
msg(sprintf("  F partiel (Wald groupe) du bloc geologie : %.2f, p = %.3g, ddl = %d",
            wt$stat, wt$p, wt$df1))
msg(sprintf("  coefficients non identifies (colineaires) : %d", length(est$collin.var)))

verdict <- part_intra >= SEUIL_PART_INTRA && g["gain"] >= SEUIL_GAIN_R2CV
res <- data.table(
  n_agriculteurs = nrow(dat), n_departs = length(dep), n_sdo = nlevels(dat$sdo),
  n_col_geologie = length(geo),
  part_intra = part_intra, seuil_part_intra = SEUIL_PART_INTRA,
  r2cv_controles = g[["r2cv_controles"]], r2cv_geo_controles = g[["r2cv_geo_controles"]],
  gain_r2cv = g[["gain"]], seuil_gain = SEUIL_GAIN_R2CV,
  r2_intra_echantillon = r2_in, f_partiel = wt$stat, p_f_partiel = wt$p,
  verdict = if (verdict) "PASSE" else "ECHOUE")
fwrite(res, p_tab("29_premier_stage_verdict.csv"))

# ===========================================================================
# Hors critere
# ===========================================================================
hr("29c. Rapporte a cote du verdict (hors critere)")

cote <- list()
add <- function(lab, n, gg) cote[[length(cote) + 1L]] <<- data.table(
  variante = lab, n = n, r2cv_controles = gg[["r2cv_controles"]],
  r2cv_geo_controles = gg[["r2cv_geo_controles"]], gain = gg[["gain"]])
add("principal (rappel)", nrow(dat), g)

# un pli par SDO : borne stricte de transport. Le centrage par SDO fait que
# la moyenne du SDO retire est connue ; seul l'intra-SDO est a predire.
add("un pli par SDO (6 plis)", nrow(dat),
    gain_r2(dat, "farmer_well_depth", geo, ctrl, as.integer(dat$sdo)))

# profondeur winsorisee
add("profondeur winsorisee", nrow(dat),
    gain_r2(dat, "farmer_well_depth_wins", geo, ctrl, dat$pli))

# fractures seules ; roches et aquiferes seuls
frac <- intersect(c("dist2fault_km", "ltot_1km", "ltot_5km"), geo)
add("fractures seules", nrow(dat), gain_r2(dat, "farmer_well_depth", frac, ctrl, dat$pli))
add("roches et aquiferes seuls", nrow(dat),
    gain_r2(dat, "farmer_well_depth", setdiff(geo, frac), ctrl, dat$pli))

# annee de forage : depth_data.txt a parfois plusieurs puits par agriculteur ;
# on garde le puits dont la profondeur egale farmer_well_depth (la plus
# ancienne annee si plusieurs). Agriculteurs sans correspondance : retires de
# cette variante seulement.
dug <- fread(f_dug)
check_vars(dug, c("SDO", "f_id", "year_dug", "depth"), "depth_data.txt")
m <- merge(dat[, .(f_id, farmer_well_depth)], dug[, .(f_id, year_dug, depth)], by = "f_id")
m <- m[depth == farmer_well_depth, .(year_dug = min(year_dug)), by = f_id]
dd <- merge(dat, m, by = "f_id")
msg(sprintf("  annee de forage appariee (meme profondeur) : %d / %d agriculteurs",
            nrow(dd), nrow(dat)))
yr <- model.matrix(~ factor(year_dug), dd)[, -1, drop = FALSE]
yr_cols <- make.names(colnames(yr))
dd[, (yr_cols) := as.data.table(yr)]
add("sans annee de forage, echantillon apparie", nrow(dd),
    gain_r2(dd, "farmer_well_depth", geo, ctrl, dd$pli))
add("avec effets fixes d'annee de forage (2 modeles)", nrow(dd),
    gain_r2(dd, "farmer_well_depth", geo, c(ctrl, yr_cols), dd$pli))

cote <- rbindlist(cote)
op <- options(width = 200)
print(cote[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 3) else v)])
options(op)
fwrite(cote, p_tab("29_premier_stage_variantes.csv"))

hr("29d. Verdict")
msg(sprintf("Condition 1, part intra-SDO %.3f >= %.2f : %s", part_intra, SEUIL_PART_INTRA,
            if (part_intra >= SEUIL_PART_INTRA) "remplie" else "NON remplie"))
msg(sprintf("Condition 2, gain de R2 hors echantillon %.3f >= %.2f : %s", g["gain"],
            SEUIL_GAIN_R2CV, if (g["gain"] >= SEUIL_GAIN_R2CV) "remplie" else "NON remplie"))
msg(sprintf("VERDICT DE LA PORTE A' : %s", if (verdict) "PASSE" else "ECHOUE"))
msg("Rappel : passer A' ne rouvre pas la piste A (portes B et C restent).")

log_close()
