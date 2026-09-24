# ---------------------------------------------------------------------------
# 10_piste_a_premier_stage_ap.R -- porte de faisabilite de la piste A :
#   la geologie predit-elle la profondeur de la nappe AU SEIN du socle, au-dela
#   des effets fixes de district ? (Andhra Pradesh non divise)
#
# CRITERE FIXE AVANT ESTIMATION : memo/piste_a_premier_stage_critere.md
# (commit 07a1e23). Les seuils ci-dessous en sont la copie ; ne pas les changer.
#
# PORTEE : premier stage seulement, comme test passe / echoue. AUCUN second
# stage, AUCUNE variable de resultat "eau". La section 10f (caracteristiques
# economiques de 1991 par classe geologique) sert a juger la restriction
# d'exclusion ; elle ne lit aucun resultat.
#
# ECHANTILLON : puits CGWB de l'AP (pc11_state_id 28), profondeur = moyenne des
# lectures de mai 1996-2000, socle seulement (code/ref/hydrogeo_ap_2m.csv,
# hard_rock == TRUE), khondalite exclue.
#
# CONTROLES (choix faits ici, dans le cadre fixe par le critere) :
#   terrain (CartoDEM v3r1, 1 seconde d'arc) : altitude au puits ; pente moyenne
#     et altitude moyenne dans une fenetre carree de +/-0.009 deg (~2 km de
#     cote) ; altitude relative = altitude au puits - altitude moyenne de la
#     fenetre (position de fond de vallee / de crete).
#   sol (SLUSI, Soil Health Cards) : voir l'etape 3.
#
# LANCEMENT (racine du depot, dans un terminal) :
#     Rscript code/10_piste_a_premier_stage_ap.R           # reprend
#     Rscript code/10_piste_a_premier_stage_ap.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 10_echantillon.rds   puits de l'echantillon + profondeur + classe
#   2. 10_terrain.rds       controles de terrain par puits
#   3. 10_sol.rds           controles de sol par puits
#   4. 10_villages.rds      villages AP du socle + classe + variables 1991
# Les estimations sont toujours recalculees (quelques secondes).
#
# Sorties : output/tables/10_*.csv, output/logs/10_piste_a_premier_stage_ap.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(sf)
  library(terra)
  library(arrow)
  library(fixest)
}))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("10_piste_a_premier_stage_ap.log"))

# --- seuils du critere (memo/piste_a_premier_stage_critere.md) ---------------
SEUIL_PART_INTRA <- 0.25
SEUIL_GAIN_R2CV  <- 0.05

AP        <- "28"
YR        <- 1996:2000
WIN_DEG   <- 0.009        # demi-cote de la fenetre de terrain, degres (~1 km)
REF_CLASS <- "Granite"    # classe de reference (la plus frequente)

msg("ETAPE 10 -- PISTE A : PORTE DE FAISABILITE DU PREMIER STAGE (ANDHRA PRADESH)")
msg("")
msg("Critere fixe avant estimation : memo/piste_a_premier_stage_critere.md")
msg(sprintf("  (1) part intra-district de la variance de profondeur >= %.2f", SEUIL_PART_INTRA))
msg(sprintf("  (2) gain de R2 hors echantillon (plis = districts) du bloc geologie >= %.2f",
            SEUIL_GAIN_R2CV))
msg("Aucun second stage, aucune variable de resultat.")

ref <- fread(file.path("code", "ref", "hydrogeo_ap_2m.csv"))
check(nrow(ref) == 54L, "recodage AP : 54 unites")

# ===========================================================================
# Etape 1 : echantillon
# ===========================================================================
hr("10a. Echantillon (etape 1)")

f_ech <- p_build("10_echantillon.rds")
ech <- stage("etape 1/4 echantillon", f_ech, function() {
  w <- as.data.table(readRDS(p_build("09_puits_geo.rds")))[pc11_state_id == AP]
  m <- as.data.table(readRDS(p_build("cgwb_may_long.rds")))
  d <- m[year %in% YR & !is.na(depth_mbgl), .(depth = mean(depth_mbgl), n_may = .N), by = WLCODE]
  s <- merge(w, ref[, .(unit, principal_aquifer, system, hard_rock)], by = "unit")
  s <- merge(s, d, by = "WLCODE")
  tmsg("    puits AP avec unite geologique et lecture de mai 1996-2000 : ", nrow(s))
  tmsg("    dont socle : ", s[hard_rock == TRUE, .N], " ; dont khondalite (exclue) : ",
       s[principal_aquifer == "Khondalite", .N])
  s[hard_rock == TRUE & principal_aquifer != "Khondalite",
    .(WLCODE, pc11_district_id, LON, LAT, SITE_TYPE, unit, principal_aquifer, system,
      depth, n_may)]
}, after = p_build("09_puits_geo.rds"))

check(nrow(ech) > 0, "echantillon non vide")
check(sum(duplicated(ech$WLCODE)) == 0, "echantillon : WLCODE unique")
check(all(ech$depth >= 0 & ech$depth <= 200), "profondeur dans [0, 200] m")
msg(sprintf("  puits : %d ; districts : %d", nrow(ech), uniqueN(ech$pc11_district_id)))
print(ech[, .N, by = principal_aquifer][order(-N)])

# ===========================================================================
# Etape 2 : terrain (CartoDEM)
# ===========================================================================
hr("10b. Terrain, CartoDEM (etape 2)")

f_ter <- p_build("10_terrain.rds")
ter <- stage("etape 2/4 terrain", f_ter, function() {
  tifs <- list.files(p_raw("cartodem"), "[.]tif$", full.names = TRUE)
  vrt  <- file.path(tempdir(), "cartodem_ap.vrt")
  sf::gdal_utils("buildvrt", tifs, vrt)
  dem  <- terra::rast(vrt)
  tmsg("    ", length(tifs), " tuiles ; ", nrow(ech), " puits a traiter")
  out <- vector("list", nrow(ech))
  for (i in seq_len(nrow(ech))) {
    e  <- terra::ext(ech$LON[i] - WIN_DEG, ech$LON[i] + WIN_DEG,
                     ech$LAT[i] - WIN_DEG, ech$LAT[i] + WIN_DEG)
    wn <- terra::crop(dem, e)
    sl <- terra::terrain(wn, v = "slope", unit = "degrees")
    z0 <- terra::extract(dem, cbind(ech$LON[i], ech$LAT[i]))[1, 1]
    zm <- terra::global(wn, "mean", na.rm = TRUE)[1, 1]
    out[[i]] <- data.table(WLCODE = ech$WLCODE[i], elev = z0,
                           slope_win = terra::global(sl, "mean", na.rm = TRUE)[1, 1],
                           relelev_win = z0 - zm)
    if (i %% 100L == 0L) tmsg("    ", i, "/", nrow(ech))
  }
  rbindlist(out)
}, after = f_ech)

check(nrow(ter) == nrow(ech), "terrain : une ligne par puits")
msg(sprintf("  valeurs manquantes -- altitude : %d, pente : %d, altitude relative : %d",
            sum(is.na(ter$elev)), sum(is.na(ter$slope_win)), sum(is.na(ter$relelev_win))))
print(round(sapply(ter[, .(elev, slope_win, relelev_win)], quantile,
                   c(0, .25, .5, .75, 1), na.rm = TRUE), 1))

# ===========================================================================
# Etape 3 : sol (SLUSI)
# ===========================================================================
hr("10c. Sol, SLUSI (etape 3)")

# SLUSI ne fournit que des Soil Health Cards : analyses chimiques de parcelles,
# vers 2015-2020, sans texture ni profondeur de sol. On garde pH et carbone
# organique (OC), mediane des analyses a 5 km au plus du puits, avec au moins
# 3 analyses (sinon manquant). Exclus : EC, N, P, K, oligo-elements, qui sont
# des resultats de l'irrigation et de la fertilisation (post-traitement). Le pH
# reflete en partie la roche mere : le garder rend le test PLUS difficile a
# passer (choix conservateur, note dans le memo du critere avant execution).
SOL_VARS <- c("soil_ph", "soil_oc")
SOL_R_M  <- 5000
SOL_MIN_N <- 3L
f_slusi <- p_raw("slusi", "SLUSI_SHC.parquet")
check(file.exists(f_slusi), paste0("source presente : ", f_slusi))

f_sol <- p_build("10_sol.rds")
sol <- stage("etape 3/4 sol", f_sol, function() {
  x0 <- min(ech$LON) - 0.1; x1 <- max(ech$LON) + 0.1
  y0 <- min(ech$LAT) - 0.1; y1 <- max(ech$LAT) + 0.1
  x <- arrow::open_dataset(f_slusi) |>
    dplyr::filter(bbox$xmin >= x0, bbox$xmax <= x1, bbox$ymin >= y0, bbox$ymax <= y1) |>
    dplyr::select(pH, OC, geometry) |> dplyr::collect() |> as.data.table()
  x[, `:=`(pH = suppressWarnings(as.numeric(pH)), OC = suppressWarnings(as.numeric(OC)))]
  tmsg("    analyses SHC dans l'emprise : ", format(nrow(x), big.mark = ","))
  x[!(pH %between% c(3, 11)), pH := NA]
  x[!(OC %between% c(0, 5)), OC := NA]
  laea <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"
  g  <- sf::st_transform(sf::st_as_sfc(structure(lapply(x$geometry, as.raw), class = "WKB"),
                                       crs = 4326), laea)
  wp <- sf::st_transform(sf::st_as_sf(ech, coords = c("LON", "LAT"), crs = 4326), laea)
  nb <- sf::st_is_within_distance(wp, g, SOL_R_M)
  out <- data.table(WLCODE = ech$WLCODE, n_shc = lengths(nb),
                    soil_ph = vapply(nb, function(k) median(x$pH[k], na.rm = TRUE), 0),
                    soil_oc = vapply(nb, function(k) median(x$OC[k], na.rm = TRUE), 0))
  out[n_shc < SOL_MIN_N, (SOL_VARS) := NA_real_]
  out
}, after = f_ech)

check(nrow(sol) == nrow(ech), "sol : une ligne par puits")
msg(sprintf("  puits avec moins de %d analyses a %d km (sol manquant) : %d",
            SOL_MIN_N, SOL_R_M / 1000, sol[is.na(soil_ph), .N]))
print(round(sapply(sol[, .(n_shc, soil_ph, soil_oc)], quantile, c(0, .25, .5, .75, 1),
                   na.rm = TRUE), 2))

# ===========================================================================
# Etape 4 : villages du socle et caracteristiques de 1991
# ===========================================================================
hr("10d. Villages du socle, SHRUG 1991 (etape 4)")

f_vil <- p_build("10_villages.rds")
vil <- stage("etape 4/4 villages", f_vil, function() {
  cen <- as.data.table(readRDS(p_build("shrid_centroids.rds")))
  k11 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-pc-keys-dta", "pc11r_shrid_key.dta")))
  cen <- merge(cen, unique(k11[pc11_state_id == AP, .(shrid2, pc11_district_id)]), by = "shrid2")
  geo <- sf::st_read(p_build("09_geologie_2m_laea.gpkg"), quiet = TRUE)
  pts <- sf::st_transform(sf::st_as_sf(cen, coords = c("lon_wgs84", "lat_wgs84"), crs = 4326),
                          sf::st_crs(geo))
  j <- sf::st_join(pts, geo[, "unit"], join = sf::st_intersects, left = TRUE)
  j <- as.data.table(sf::st_drop_geometry(j))[!duplicated(shrid2)]
  j <- merge(j, ref[, .(unit, principal_aquifer, hard_rock)], by = "unit")
  j <- j[hard_rock == TRUE & principal_aquifer != "Khondalite"]
  tmsg("    villages AP du socle (hors khondalite) : ", nrow(j))
  pca <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-pca91-dta", "pc91_pca_clean_shrid.dta")))
  vd  <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd91-dta", "pc91_vd_clean_shrid.dta")))
  x <- merge(j, pca[, .(shrid2, pc91_pca_area, pc91_pca_tot_p, pc91_pca_p_06, pc91_pca_p_lit, pc91_pca_p_st)],
             by = "shrid2", all.x = TRUE)
  # pc91_vd_area est vide pour l'AP en 1991 ; la surface vient de la PCA 1991
  # (pc91_pca_area, en hectares : rapport median a pc01_vd_area = 1,000).
  x <- merge(x, vd[, .(shrid2, pc91_vd_canal_govt, pc91_vd_canal_pvt,
                       pc91_vd_dist_town)], by = "shrid2", all.x = TRUE)
  x
}, after = p_build("09_geologie_2m_laea.gpkg"))

check(sum(duplicated(vil$shrid2)) == 0, "villages : shrid2 unique")
msg(sprintf("  villages : %s ; avec population 1991 : %s ; avec VD 1991 : %s",
            format(nrow(vil), big.mark = ","),
            format(vil[!is.na(pc91_pca_tot_p), .N], big.mark = ","),
            format(vil[!is.na(pc91_vd_dist_town), .N], big.mark = ",")))

# ===========================================================================
# Estimation : les deux conditions du critere
# ===========================================================================
hr("10e. Test du critere")

dat <- merge(merge(ech, ter, by = "WLCODE"), sol, by = "WLCODE")
ctrl <- c("elev", "slope_win", "relelev_win", SOL_VARS)
n0 <- nrow(dat)
dat <- dat[complete.cases(dat[, ..ctrl])]
msg(sprintf("  puits avec tous les controles : %d sur %d (%d ecartes pour controle manquant)",
            nrow(dat), n0, n0 - nrow(dat)))
dat[, cls := relevel(factor(principal_aquifer), ref = REF_CLASS)]
dat[, dist := factor(pc11_district_id)]

# (1) part intra-district de la variance de profondeur
ss_tot   <- sum((dat$depth - mean(dat$depth))^2)
ss_within <- sum((dat$depth - ave(dat$depth, dat$dist))^2)
part_intra <- ss_within / ss_tot
msg(sprintf("  (1) part intra-district de la variance : %.3f  (seuil %.2f) -> %s",
            part_intra, SEUIL_PART_INTRA, if (part_intra >= SEUIL_PART_INTRA) "PASSE" else "ECHOUE"))

# (2) R2 hors echantillon, plis = districts entiers (un pli par district).
# Tout est centre par district sur l'ensemble des puits du district (l'effet fixe
# est le point de comparaison) ; le modele est ajuste sur les autres districts et
# predit la profondeur centree du district retire. Un coefficient non identifie
# dans un pli (classe absente des districts d'entrainement) compte pour zero.
X_geo  <- model.matrix(~ cls, dat)[, -1, drop = FALSE]
X_ctrl <- as.matrix(dat[, ..ctrl])
demean <- function(M, g) M - apply(M, 2, function(v) ave(v, g))
y_dm   <- dat$depth - ave(dat$depth, dat$dist)
Xg_dm  <- demean(X_geo, dat$dist)
Xc_dm  <- demean(X_ctrl, dat$dist)

cv_r2 <- function(X) {
  pred <- numeric(length(y_dm))
  for (d in levels(dat$dist)) {
    te <- dat$dist == d
    b  <- stats::lm.fit(X[!te, , drop = FALSE], y_dm[!te])$coefficients
    b[is.na(b)] <- 0
    pred[te] <- X[te, , drop = FALSE] %*% b
  }
  1 - sum((y_dm - pred)^2) / sum(y_dm^2)
}
r2_ctrl <- cv_r2(Xc_dm)
r2_full <- cv_r2(cbind(Xg_dm, Xc_dm))
gain    <- r2_full - r2_ctrl
msg(sprintf("  (2) R2 hors echantillon (intra-district) : controles seuls %.3f ; geologie + controles %.3f",
            r2_ctrl, r2_full))
msg(sprintf("      gain du bloc geologie : %.3f  (seuil %.2f) -> %s",
            gain, SEUIL_GAIN_R2CV, if (gain >= SEUIL_GAIN_R2CV) "PASSE" else "ECHOUE"))
msg(sprintf("      (%d plis, un par district)", nlevels(dat$dist)))

# A titre d'information seulement : estimation sur tout l'echantillon et F partiel.
fml <- as.formula(paste("depth ~ cls +", paste(ctrl, collapse = " + "), "| dist"))
est <- feols(fml, data = dat, cluster = ~dist)
wt  <- wald(est, keep = "^cls", print = FALSE)
msg("")
msg("  Pour information (hors critere) : estimation sur tout l'echantillon,")
msg("  effets fixes de district, erreurs groupees par district.")
op <- options(width = 200); print(coeftable(est)); options(op)
msg(sprintf("  F partiel (Wald groupe) du bloc geologie : %.2f, p = %.3f, ddl = %d",
            wt$stat, wt$p, wt$df1))

verdict <- part_intra >= SEUIL_PART_INTRA && gain >= SEUIL_GAIN_R2CV
res <- data.table(
  n_puits = nrow(dat), n_districts = nlevels(dat$dist),
  part_intra = part_intra, seuil_part_intra = SEUIL_PART_INTRA,
  r2cv_controles = r2_ctrl, r2cv_geo_controles = r2_full, gain_r2cv = gain,
  seuil_gain = SEUIL_GAIN_R2CV, f_partiel = wt$stat, p_f_partiel = wt$p,
  verdict = if (verdict) "PASSE" else "ECHOUE")
fwrite(res, p_tab("10_premier_stage_verdict.csv"))
fwrite(as.data.table(coeftable(est), keep.rownames = "terme"), p_tab("10_premier_stage_coefs.csv"))

hr("10f. Classes du socle et economie locale en 1991 (hors critere)")

msg("Chaque caracteristique regressee sur les classes (reference : ", REF_CLASS, ")")
msg("avec effets fixes de district, erreurs groupees par district. Unite : village")
msg("(centroide du shrid dans une classe du socle, hors khondalite).")
msg("Scheduled Areas : absent de SHRUG ; proxy = part de population ST (a lire comme tel).")
v <- copy(vil)
v[, log_pop   := log(pc91_pca_tot_p)]
v[, lit_rate  := pc91_pca_p_lit / (pc91_pca_tot_p - pc91_pca_p_06)]
v[, st_share  := pc91_pca_p_st / pc91_pca_tot_p]
v[, canal_sh  := (pc91_vd_canal_govt + pc91_vd_canal_pvt) / pc91_pca_area]
v[, dist_town := pc91_vd_dist_town]
v[pc91_pca_tot_p <= 0, c("log_pop", "lit_rate", "st_share") := NA]
v[!(pc91_pca_area > 0), canal_sh := NA]
v[, cls := relevel(factor(principal_aquifer), ref = REF_CLASS)]
v[, dist := factor(pc11_district_id)]
EXCL <- c(log_pop = "log population", lit_rate = "taux d'alphabetisation (7 ans et +)",
          st_share = "part ST (proxy Scheduled Areas)", canal_sh = "part irriguee par canal",
          dist_town = "distance a la ville (km)")
ex <- rbindlist(lapply(names(EXCL), function(y) {
  e <- feols(as.formula(paste(y, "~ cls | dist")), data = v, cluster = ~dist)
  w <- wald(e, keep = "^cls", print = FALSE)
  ct <- as.data.table(coeftable(e), keep.rownames = "terme")
  ct[, `:=`(variable = y, libelle = EXCL[[y]], moyenne_ref = v[cls == REF_CLASS, mean(get(y), na.rm = TRUE)],
            n = nobs(e), wald_F = w$stat, wald_p = w$p,
            r2_within_classes = r2(e, "wr2"))]
  ct
}))
setnames(ex, c("Estimate", "Std. Error", "t value", "Pr(>|t|)"), c("coef", "se", "t", "p"))
fwrite(ex, p_tab("10_classes_economie_1991.csv"))
op <- options(width = 200)
print(ex[, .(variable, terme = sub("^cls", "", terme), coef = round(coef, 3), se = round(se, 3),
             p = round(p, 3))])
msg("")
msg("  Test joint des classes, par caracteristique :")
print(unique(ex[, .(variable, libelle, n, moyenne_ref = round(moyenne_ref, 3),
                    wald_F = round(wald_F, 2), wald_p = round(wald_p, 4),
                    r2_within = round(r2_within_classes, 4))]))
options(op)

hr("VERDICT")
msg(sprintf("Condition 1, part intra-district %.3f >= %.2f : %s", part_intra, SEUIL_PART_INTRA,
            if (part_intra >= SEUIL_PART_INTRA) "remplie" else "NON remplie"))
msg(sprintf("Condition 2, gain de R2 hors echantillon %.3f >= %.2f : %s", gain, SEUIL_GAIN_R2CV,
            if (gain >= SEUIL_GAIN_R2CV) "remplie" else "NON remplie"))
msg("PORTE : ", if (verdict) "PASSE" else "ECHOUE")
msg("La redaction du verdict et la lecture de 10f sont dans memo/, pas ici.")

hr("ETAPE 10 TERMINEE")
for (f in sort(list.files(p_tab(), pattern = "^10_"))) msg("  ", f)
log_close()
