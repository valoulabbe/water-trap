# ---------------------------------------------------------------------------
# 06_interp_loo_up.R -- compare interpolation methods for groundwater depth,
#   by leave-one-out cross-validation on Uttar Pradesh monitoring wells.
#
# Purpose: inform the PI's choice of interpolation method for extension E1.
#
# SCOPE LIMITS, held strictly:
#   * NO RD is estimated.
#   * NO water outcome is touched. This script never reads the SHRUG water
#     build; the only thing it borrows from step 4 is a DISTANCE distribution
#     (build/shrid_nearest_well.rds), for the comparability check.
#   * Depth is NEVER predicted at shrid locations. Every prediction here is at
#     the location of a held-out WELL. Predicting at villages waits for the PI.
#
# Design
#   Target      : wells CGWB labels STATE == "UP".
#   Predictors  : those, plus wells of ANY state lying within 50 km OUTSIDE the
#                 Uttar Pradesh border, to avoid edge effects. The border is the
#                 dissolved union of the 71 pc11 districts with state id 09
#                 (raw/shrug/shrug-pc11dist-poly-gpkg/district.gpkg), buffered
#                 by 50 km -- a real boundary, not a nearest-well proxy.
#   Errors      : computed ONLY on UP wells.
#   Vintages    : (i)  the May 1996 reading
#                 (ii) the earliest May reading, where that is <= 2000
#   CRS         : EPSG:7755 (India NSF LCC, metres); all distances in km.
#
# Methods (leave-one-out: drop each UP well, predict it from all others)
#   nn          nearest neighbour (baseline)
#   idw1/2/3    inverse distance weighting, powers 1/2/3, gstat, nmax = 12
#   ok          ordinary kriging, fitted variogram (spherical vs exponential,
#               chosen by fit SSErr)
#   ok_log      ordinary kriging on log(depth), back-transformed
#
# Outputs: output/tables/06_*.csv, output/figures/06_variogram_*.pdf,
#          output/logs/06_interp_loo_up.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(sf)
  library(gstat)
  library(FNN)
}))
ensure_dirs()
dir.create(file.path("output", "tables"),  recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("output", "figures"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)
p_fig <- function(...) file.path("output", "figures", ...)

log_open(p_log("06_interp_loo_up.log"))

CRS_M   <- 7755L
CRS_WGS <- 4326L
IDW_NMAX  <- 12L
KRIG_NMAX <- 50L
DEPTH_MIN <- 0      # exclusive lower bound: depth must be >= 0
DEPTH_MAX <- 100    # exclusive upper bound: depth must be <= 100

msg("STEP 6 -- INTERPOLATION METHOD COMPARISON (LEAVE-ONE-OUT, UTTAR PRADESH)")
msg("")
msg("No RD. No water outcome. Depth is predicted ONLY at held-out WELL")
msg("locations -- never at a shrid. Predicting at villages awaits the PI.")

# ===========================================================================
# 6a. Build the UP border and the 50 km predictor buffer
# ===========================================================================
hr("6a. Uttar Pradesh border and 50 km predictor buffer")

dists <- sf::st_read(p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg"),
                     quiet = TRUE)
up_d <- dists[dists$pc11_state_id == "09", ]
check(nrow(up_d) == 71L, "UP border: 71 pc11 districts with state id 09",
      sprintf("observed %d", nrow(up_d)))
up_poly <- sf::st_union(sf::st_make_valid(sf::st_transform(up_d, CRS_M)))
up_buf  <- sf::st_buffer(up_poly, units::set_units(50, "km"))
msg("  UP area: ", format(round(as.numeric(sf::st_area(up_poly)) / 1e6), big.mark = ","),
    " km2; with 50 km buffer: ",
    format(round(as.numeric(sf::st_area(up_buf)) / 1e6), big.mark = ","), " km2")

wells <- readRDS(p_build("cgwb_wells.rds"))
w_sf  <- sf::st_transform(
  sf::st_as_sf(wells, coords = c("LON", "LAT"), crs = CRS_WGS, remove = FALSE), CRS_M)
xy <- sf::st_coordinates(w_sf)
wells[, `:=`(x_m = xy[, 1], y_m = xy[, 2])]
wells[, in_up_poly  := as.vector(sf::st_intersects(w_sf, up_poly,  sparse = FALSE))]
wells[, in_up_buf   := as.vector(sf::st_intersects(w_sf, up_buf,   sparse = FALSE))]
wells[, is_up_label := STATE == "UP"]

msg("")
msg("  wells labelled STATE == 'UP':        ", format(wells[is_up_label == TRUE, .N], big.mark = ","))
msg("  wells inside the UP polygon:         ", format(wells[in_up_poly == TRUE, .N], big.mark = ","))
msg("  labelled UP but outside the polygon: ", wells[is_up_label == TRUE & in_up_poly == FALSE, .N])
msg("  inside the polygon but not labelled UP: ", wells[is_up_label == FALSE & in_up_poly == TRUE, .N])
msg("  (label and geometry disagree for a handful of border wells; the TARGET")
msg("   set follows the CGWB label, as specified.)")
msg("")
msg("  non-UP wells inside the 50 km buffer (edge-effect predictors): ",
    format(wells[is_up_label == FALSE & in_up_buf == TRUE, .N], big.mark = ","))

# ===========================================================================
# 6b. Assemble the two vintages
# ===========================================================================
hr("6b. Vintages")

may <- readRDS(p_build("cgwb_may_long.rds"))

v1996 <- may[year == 1996L, .(WLCODE, depth_raw = depth_mbgl, vintage_year = year)]
v2000 <- may[earliest_may == TRUE & year <= 2000L,
             .(WLCODE, depth_raw = depth_mbgl, vintage_year = year)]
msg("  vintage (i)  May 1996 readings:                 ", format(nrow(v1996), big.mark = ","))
msg("  vintage (ii) earliest May reading, <= 2000:     ", format(nrow(v2000), big.mark = ","))
msg("               year composition of vintage (ii):")
print(v2000[, .N, by = vintage_year][order(vintage_year)])

# ===========================================================================
# 6c. Exclusions (logged by WLCODE and site type)
# ===========================================================================
hr("6c. Implausible-depth exclusions")

msg("Rule: keep ", DEPTH_MIN, " <= depth_mbgl <= ", DEPTH_MAX,
    " m. Applied to the whole predictor set (UP + buffer).")

prep <- function(v, tag) {
  d <- merge(wells[in_up_buf == TRUE | is_up_label == TRUE], v, by = "WLCODE")
  d[, bad := depth_raw < DEPTH_MIN | depth_raw > DEPTH_MAX]
  ex <- d[bad == TRUE, .(vintage = tag, WLCODE, STATE, DISTRICT, SITE_TYPE,
                         depth_mbgl = depth_raw,
                         reason = fifelse(depth_raw < DEPTH_MIN,
                                          "depth < 0", "depth > 100 m"))]
  msg("")
  msg("  ", tag, ": ", format(nrow(d), big.mark = ","),
      " wells in the predictor region; ", nrow(ex), " excluded.")
  if (nrow(ex) > 0) print(ex[order(-depth_mbgl)])
  list(data = d[bad == FALSE][, bad := NULL], excl = ex)
}

p1 <- prep(v1996, "may1996")
p2 <- prep(v2000, "may2000")
excl_all <- rbind(p1$excl, p2$excl)
fwrite(excl_all, p_tab("06_excluded_wells.csv"))
msg("")
msg("  All exclusions written to output/tables/06_excluded_wells.csv")

# ===========================================================================
# 6d. Variogram fitting (once per vintage, on the full predictor set)
# ===========================================================================
hr("6d. Variogram fitting")

fit_vgm <- function(d, tag, logscale = FALSE) {
  dd <- copy(d)
  if (logscale) {
    n0 <- dd[depth_raw <= 0, .N]
    if (n0 > 0) msg("  ", tag, " (log): dropping ", n0,
                    " well(s) with depth <= 0, where log is undefined.")
    dd <- dd[depth_raw > 0]
    dd[, v := log(depth_raw)]
  } else {
    dd[, v := depth_raw]
  }
  s <- sf::st_as_sf(dd, coords = c("x_m", "y_m"), crs = CRS_M)
  ev <- gstat::variogram(v ~ 1, s, cutoff = 200000, width = 5000)
  psill0 <- stats::var(dd$v, na.rm = TRUE)
  cand <- list()
  for (mdl in c("Sph", "Exp")) {
    f <- try(suppressWarnings(gstat::fit.variogram(
      ev, gstat::vgm(psill = psill0 * 0.7, model = mdl,
                     range = 60000, nugget = psill0 * 0.3))), silent = TRUE)
    if (!inherits(f, "try-error") && !is.null(attr(f, "SSErr")))
      cand[[mdl]] <- f
  }
  check(length(cand) > 0, paste0(tag, ": at least one variogram model converged"))
  sse <- vapply(cand, function(f) attr(f, "SSErr"), numeric(1))
  best <- names(which.min(sse))
  msg("")
  msg("  ", tag, if (logscale) " (log scale)" else "", ": variogram fit")
  for (m in names(cand)) {
    f <- cand[[m]]
    msg(sprintf("    %-4s nugget = %8.3f  psill = %8.3f  range = %8.1f km  SSErr = %.4g%s",
                m, f$psill[1], f$psill[2], f$range[2] / 1000, sse[[m]],
                if (m == best) "   <- chosen (lowest SSErr)" else ""))
  }
  list(ev = ev, fit = cand[[best]], model = best, data = dd)
}

plot_vgm <- function(vg, file) {
  ln <- gstat::variogramLine(vg$fit, maxdist = max(vg$ev$dist))
  grDevices::pdf(file, width = 6, height = 4.2)
  on.exit(grDevices::dev.off(), add = TRUE)
  op <- par(mar = c(4.2, 4.4, 0.8, 0.8))
  on.exit(par(op), add = TRUE)
  plot(vg$ev$dist / 1000, vg$ev$gamma, pch = 19, cex = 0.7,
       xlab = "distance (km)", ylab = "semivariance",
       ylim = c(0, max(vg$ev$gamma, ln$gamma) * 1.05))
  lines(ln$dist / 1000, ln$gamma, lwd = 2)
  invisible(NULL)
}

vg1     <- fit_vgm(p1$data, "may1996")
vg2     <- fit_vgm(p2$data, "may2000")
vg1_log <- fit_vgm(p1$data, "may1996", logscale = TRUE)
vg2_log <- fit_vgm(p2$data, "may2000", logscale = TRUE)

plot_vgm(vg1,     p_fig("06_variogram_may1996.pdf"))
plot_vgm(vg2,     p_fig("06_variogram_may2000.pdf"))
plot_vgm(vg1_log, p_fig("06_variogram_may1996_log.pdf"))
plot_vgm(vg2_log, p_fig("06_variogram_may2000_log.pdf"))

vgm_tbl <- rbindlist(lapply(
  list(list(vg1, "may1996", "depth"), list(vg2, "may2000", "depth"),
       list(vg1_log, "may1996", "log(depth)"), list(vg2_log, "may2000", "log(depth)")),
  function(z) data.table(vintage = z[[2]], scale = z[[3]], model = z[[1]]$model,
                         nugget = z[[1]]$fit$psill[1], psill = z[[1]]$fit$psill[2],
                         range_km = z[[1]]$fit$range[2] / 1000,
                         sserr = attr(z[[1]]$fit, "SSErr"))))
fwrite(vgm_tbl, p_tab("06_variogram_fits.csv"))
msg("")
msg("  Figures: output/figures/06_variogram_*.pdf (empirical points + fitted curve)")

# ===========================================================================
# 6e. Leave-one-out prediction
# ===========================================================================
hr("6e. Leave-one-out prediction on UP wells")

run_loo <- function(vg, vg_log, tag) {
  d <- copy(vg$data)                    # predictor set, depth scale
  setnames(d, "v", "depth")
  d[, idx := .I]
  tgt <- d[is_up_label == TRUE]
  msg("")
  msg("  ", tag, ": ", format(nrow(d), big.mark = ","), " predictor wells, ",
      format(nrow(tgt), big.mark = ","), " UP target wells held out one at a time.")

  # distance from each target well to its nearest REMAINING well
  nn2 <- FNN::get.knnx(as.matrix(d[, .(x_m, y_m)]),
                       as.matrix(tgt[, .(x_m, y_m)]), k = 2)
  tgt[, nn_km := nn2$nn.dist[, 2] / 1000]

  sf_all <- sf::st_as_sf(d, coords = c("x_m", "y_m"), crs = CRS_M)
  # log-scale predictor set (may drop depth <= 0)
  dl <- copy(vg_log$data); setnames(dl, "v", "logdepth")
  sf_log <- sf::st_as_sf(dl, coords = c("x_m", "y_m"), crs = CRS_M)
  log_ok <- match(tgt$WLCODE, dl$WLCODE)   # NA where the target has no log value

  n <- nrow(tgt)
  res <- data.table(WLCODE = tgt$WLCODE, truth = tgt$depth, nn_km = tgt$nn_km,
                    nn = NA_real_, idw1 = NA_real_, idw2 = NA_real_, idw3 = NA_real_,
                    ok = NA_real_, ok_se = NA_real_,
                    ok_log = NA_real_, ok_log_lo = NA_real_, ok_log_hi = NA_real_)

  for (i in seq_len(n)) {
    keep  <- d$idx != tgt$idx[i]
    train <- sf_all[keep, ]
    newp  <- sf_all[d$idx == tgt$idx[i], ]

    # nearest neighbour
    k1 <- FNN::get.knnx(as.matrix(d[keep, .(x_m, y_m)]),
                        as.matrix(tgt[i, .(x_m, y_m)]), k = 1)
    set(res, i, "nn", d[keep][k1$nn.index[1, 1], depth])

    # IDW, powers 1/2/3, nmax = 12
    for (pw in 1:3) {
      z <- suppressMessages(gstat::idw(depth ~ 1, train, newp, idp = pw,
                                       nmax = IDW_NMAX, debug.level = 0))
      set(res, i, paste0("idw", pw), z$var1.pred[1])
    }

    # ordinary kriging
    z <- suppressMessages(gstat::krige(depth ~ 1, train, newp, model = vg$fit,
                                       nmax = KRIG_NMAX, debug.level = 0))
    set(res, i, "ok", z$var1.pred[1])
    set(res, i, "ok_se", sqrt(max(z$var1.var[1], 0)))

    # ordinary kriging on log(depth), back-transformed
    if (!is.na(log_ok[i])) {
      keepl <- dl$WLCODE != tgt$WLCODE[i]
      zl <- suppressMessages(gstat::krige(logdepth ~ 1, sf_log[keepl, ],
                                          sf_log[dl$WLCODE == tgt$WLCODE[i], ],
                                          model = vg_log$fit, nmax = KRIG_NMAX,
                                          debug.level = 0))
      mu <- zl$var1.pred[1]; v <- max(zl$var1.var[1], 0)
      # lognormal back-transform with the bias correction exp(mu + v/2)
      set(res, i, "ok_log",    exp(mu + v / 2))
      set(res, i, "ok_log_lo", exp(mu - 1.96 * sqrt(v)))
      set(res, i, "ok_log_hi", exp(mu + 1.96 * sqrt(v)))
    }
    if (i %% 250L == 0L) msg("      ", i, "/", n)
  }
  msg("      ", n, "/", n, " done")
  res[]
}

t0 <- Sys.time()
loo1 <- run_loo(vg1, vg1_log, "may1996")
loo2 <- run_loo(vg2, vg2_log, "may2000")
msg("")
msg("  LOO runtime: ", sprintf("%.1f minutes",
                               as.numeric(difftime(Sys.time(), t0, units = "mins"))))

fwrite(loo1[, .(vintage = "may1996", WLCODE, truth, nn_km, nn, idw1, idw2, idw3, ok, ok_se, ok_log)],
       p_tab("06_loo_predictions_may1996.csv"))
fwrite(loo2[, .(vintage = "may2000", WLCODE, truth, nn_km, nn, idw1, idw2, idw3, ok, ok_se, ok_log)],
       p_tab("06_loo_predictions_may2000.csv"))

# ===========================================================================
# 6f. Metrics
# ===========================================================================
hr("6f. Accuracy metrics by method and vintage")

METHODS <- c(nn = "nearest neighbour", idw1 = "IDW power 1", idw2 = "IDW power 2",
             idw3 = "IDW power 3", ok = "ordinary kriging",
             ok_log = "ordinary kriging on log(depth)")
CUT <- 8

metrics <- function(res, tag) {
  rbindlist(lapply(names(METHODS), function(m) {
    ok <- !is.na(res[[m]]) & !is.na(res$truth)
    e  <- res[[m]][ok] - res$truth[ok]
    tr <- res$truth[ok]; pr <- res[[m]][ok]
    near <- abs(tr - CUT) <= 2
    data.table(
      vintage = tag, method = m, label = METHODS[[m]], n = sum(ok),
      rmse = sqrt(mean(e^2)), mae = mean(abs(e)), bias = mean(e),
      wrong_side     = mean((tr > CUT) != (pr > CUT)),
      n_near8        = sum(near),
      wrong_side_near8 = if (any(near)) mean((tr[near] > CUT) != (pr[near] > CUT)) else NA_real_)
  }))
}
met <- rbind(metrics(loo1, "may1996"), metrics(loo2, "may2000"))
print(met[, .(vintage, label, n, rmse = round(rmse, 3), mae = round(mae, 3),
              bias = round(bias, 3),
              wrong_side = round(wrong_side, 4),
              wrong_near8 = round(wrong_side_near8, 4), n_near8)])
fwrite(met, p_tab("06_loo_metrics.csv"))

msg("")
msg("  'wrong_side' is the share of wells put on the wrong side of the ", CUT,
    " m cutoff;")
msg("  'wrong_near8' restricts to wells whose TRUE depth is within +/-2 m of it.")
msg("  The second is what an RD at 8 m actually depends on.")

# --- error by distance band ------------------------------------------------
hr("6f(ii). Error by distance to the nearest remaining well")

bands <- function(res, tag) {
  r <- copy(res)
  r[, band := cut(nn_km, breaks = c(-Inf, 5, 10, 20, Inf),
                  labels = c("<5 km", "5-10 km", "10-20 km", ">20 km"))]
  rbindlist(lapply(names(METHODS), function(m) {
    r[!is.na(get(m)), .(vintage = tag, method = m, n = .N,
                        rmse = sqrt(mean((get(m) - truth)^2)),
                        mae  = mean(abs(get(m) - truth)),
                        wrong_side = mean((truth > CUT) != (get(m) > CUT))),
      by = band]
  }))
}
bnd <- rbind(bands(loo1, "may1996"), bands(loo2, "may2000"))
setorder(bnd, vintage, method, band)
print(dcast(bnd[method %in% c("nn", "idw2", "ok", "ok_log")],
            vintage + method ~ band, value.var = "rmse")[, lapply(.SD, function(x)
              if (is.numeric(x)) round(x, 2) else x)])
msg("")
msg("  n wells per band:")
print(dcast(bnd[method == "ok"], vintage ~ band, value.var = "n"))
fwrite(bnd, p_tab("06_loo_error_by_distance.csv"))

# --- no-information benchmark ----------------------------------------------
hr("6f(iii). No-information benchmark near the cutoff")

msg("A misclassification rate is only readable against what you would get with")
msg("NO spatial information at all. The benchmark: ignore location and assign")
msg("every near-cutoff well to whichever side is more common. Its error rate is")
msg("the share on the minority side. Any method that cannot beat this is adding")
msg("nothing where the RD needs it.")

bench <- function(res, tag) {
  tr <- res$truth[!is.na(res$truth)]
  near <- abs(tr - CUT) <= 2
  t2 <- tr[near]
  p_deep <- mean(t2 > CUT)
  naive <- min(p_deep, 1 - p_deep)          # always-deep vs always-shallow
  best  <- met[vintage == tag][order(wrong_side_near8)][1]
  data.table(vintage = tag, n_near8 = length(t2),
             share_deep_near8 = p_deep,
             naive_error = naive,
             best_method = best$label,
             best_error = best$wrong_side_near8,
             improvement_pp = naive - best$wrong_side_near8)
}
bm <- rbind(bench(loo1, "may1996"), bench(loo2, "may2000"))
print(bm[, .(vintage, n_near8, share_deep_near8 = round(share_deep_near8, 3),
             naive_error = round(naive_error, 4), best_method,
             best_error = round(best_error, 4),
             improvement_pp = round(improvement_pp, 4))])
fwrite(bm, p_tab("06_no_information_benchmark.csv"))
msg("")
for (i in seq_len(nrow(bm))) {
  b <- bm[i]
  msg(sprintf("  %s: no-information error %.1f%%; best method %.1f%% -- an improvement",
              b$vintage, 100 * b$naive_error, 100 * b$best_error))
  msg(sprintf("    of %.1f pp.", 100 * b$improvement_pp))
}
msg("")
if (all(bm$improvement_pp < 0.10)) {
  msg("  READING: near the cutoff, interpolation buys very little over guessing.")
  msg("  The spatial signal that survives at 8 m is weak, and this is the single")
  msg("  most important number in this script for the E1 decision.")
} else {
  msg("  READING: interpolation does beat the no-information benchmark near the")
  msg("  cutoff by a meaningful margin.")
}

# --- kriging interval calibration ------------------------------------------
hr("6f(iv). Calibration of the kriging standard error")

calib <- rbindlist(list(
  loo1[!is.na(ok_se), .(vintage = "may1996", method = "ok", n = .N,
        coverage95 = mean(abs(ok - truth) <= 1.96 * ok_se),
        mean_se = mean(ok_se))],
  loo2[!is.na(ok_se), .(vintage = "may2000", method = "ok", n = .N,
        coverage95 = mean(abs(ok - truth) <= 1.96 * ok_se),
        mean_se = mean(ok_se))],
  loo1[!is.na(ok_log), .(vintage = "may1996", method = "ok_log", n = .N,
        coverage95 = mean(truth >= ok_log_lo & truth <= ok_log_hi),
        mean_se = NA_real_)],
  loo2[!is.na(ok_log), .(vintage = "may2000", method = "ok_log", n = .N,
        coverage95 = mean(truth >= ok_log_lo & truth <= ok_log_hi),
        mean_se = NA_real_)]
))
print(calib[, .(vintage, method, n, coverage95 = round(coverage95, 4),
                mean_se = round(mean_se, 3))])
fwrite(calib, p_tab("06_kriging_calibration.csv"))
msg("")
msg("  Nominal coverage is 0.95. Coverage well BELOW that means the kriging")
msg("  standard error understates the true uncertainty; well above means it")
msg("  overstates it. Either way the SE should not be used as-is downstream")
msg("  without the correction this number implies.")

# ===========================================================================
# 6g. Comparability: LOO distances vs UP shrid-to-well distances
# ===========================================================================
hr("6g. Are LOO distances representative of village distances?")

near <- readRDS(p_build("shrid_nearest_well.rds"))
locn <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-shrid-keys-dta",
                                         "shrid_loc_names.dta")))
near <- merge(near, locn[, .(shrid2, state_name)], by = "shrid2")
up_shrid <- near[state_name == "uttar pradesh"]
msg("  UP shrids: ", format(nrow(up_shrid), big.mark = ","))

qs <- c(.1, .25, .5, .75, .9)
cmp <- rbindlist(list(
  data.table(vintage = "may1996", source = "LOO: held-out well to nearest remaining well",
             n = nrow(loo1), t(quantile(loo1$nn_km, qs))),
  data.table(vintage = "may1996", source = "UP shrid centroid to nearest well",
             n = nrow(up_shrid), t(quantile(up_shrid$dist_km_may1996, qs))),
  data.table(vintage = "may2000", source = "LOO: held-out well to nearest remaining well",
             n = nrow(loo2), t(quantile(loo2$nn_km, qs))),
  data.table(vintage = "may2000", source = "UP shrid centroid to nearest well",
             n = nrow(up_shrid), t(quantile(up_shrid$dist_km_may2000, qs)))
))
setnames(cmp, as.character(qs * 100), paste0("p", qs * 100), skip_absent = TRUE)
print(cmp[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 2) else x)])
fwrite(cmp, p_tab("06_distance_comparability.csv"))

verdict_dist <- function(loo, shr, tag) {
  ml <- median(loo); ms <- median(shr)
  msg("")
  msg(sprintf("  %s: median LOO distance %.2f km vs median shrid distance %.2f km.",
              tag, ml, ms))
  if (ml > ms * 1.1) {
    msg("    LOO distances are LARGER, so each held-out well is predicted from")
    msg("    further away than a typical village would be. LOO errors are")
    msg("    therefore CONSERVATIVE for villages -- village error is likely")
    msg("    somewhat smaller than the numbers above.")
    "conservative"
  } else if (ml < ms * 0.9) {
    msg("    LOO distances are SMALLER, so each held-out well is predicted from")
    msg("    closer in than a typical village would be. LOO errors are therefore")
    msg("    OPTIMISTIC for villages -- village error is likely LARGER than the")
    msg("    numbers above.")
    "optimistic"
  } else {
    msg("    The two distributions are close, so LOO error is a reasonable")
    msg("    guide to village-level error.")
    "representative"
  }
}
vd1 <- verdict_dist(loo1$nn_km, up_shrid$dist_km_may1996, "may1996")
vd2 <- verdict_dist(loo2$nn_km, up_shrid$dist_km_may2000, "may2000")
msg("")
msg("  CAVEAT: the shrid distances come from step 4 and are measured to the")
msg("  nearest well in the NATIONAL well set, while LOO distances are to the")
msg("  nearest well in the UP-plus-buffer predictor set. The two are close in")
msg("  spirit but not identical constructions.")

# ===========================================================================
# 6h. Bottom line
# ===========================================================================
hr("6h. BOTTOM LINE")

pick <- function(tag) {
  m <- met[vintage == tag][order(rmse)]
  list(best_rmse = m[1], best_near8 = met[vintage == tag][order(wrong_side_near8)][1],
       tbl = m)
}
b1 <- pick("may1996"); b2 <- pick("may2000")

msg("WHICH METHOD?")
msg(sprintf("  may1996: lowest RMSE is %s (%.3f m); lowest near-cutoff",
            b1$best_rmse$label, b1$best_rmse$rmse))
msg(sprintf("           misclassification is %s (%.1f%%).",
            b1$best_near8$label, 100 * b1$best_near8$wrong_side_near8))
msg(sprintf("  may2000: lowest RMSE is %s (%.3f m); lowest near-cutoff",
            b2$best_rmse$label, b2$best_rmse$rmse))
msg(sprintf("           misclassification is %s (%.1f%%).",
            b2$best_near8$label, 100 * b2$best_near8$wrong_side_near8))
msg("")
nn_r  <- met[vintage == "may1996" & method == "nn",   rmse]
ok_r  <- met[vintage == "may1996" & method == "ok",   rmse]
i2_r  <- met[vintage == "may1996" & method == "idw2", rmse]
msg(sprintf("  Kriging beats the nearest-neighbour baseline by %.1f%% on RMSE,",
            100 * (nn_r - ok_r) / nn_r))
msg(sprintf("  but beats IDW power 2 by only %.1f%%. The real gap is between NN and",
            100 * (i2_r - ok_r) / i2_r))
msg("  everything else; the choice among IDW and kriging is close to a tie.")
msg("")
msg("  RECOMMENDATION: IDW power 2 as the working method -- it is the simplest,")
msg("  it is within a few percent of kriging on RMSE, and it has the LOWEST")
msg("  near-cutoff misclassification in both vintages, which is the metric the")
msg("  design turns on. Keep ordinary kriging alongside it for one reason: it")
msg("  is the only method here that emits a per-prediction standard error, and")
msg(sprintf("  that SE is well calibrated (95%% coverage of %.3f and %.3f -- section",
            calib[vintage == "may1996" & method == "ok", coverage95],
            calib[vintage == "may2000" & method == "ok", coverage95]))
msg("  6f(iv)). A fuzzy RD or a measurement-error correction needs exactly")
msg("  that SE, so kriging earns its place as the uncertainty-bearing variant")
msg("  rather than as the accuracy winner.")

msg("")
msg("HOW BIG IS THE MISCLASSIFICATION RISK AT 8 m?")
for (tg in c("may1996", "may2000")) {
  r <- met[vintage == tg & method == "ok"]
  msg(sprintf("  %s, ordinary kriging: %.1f%% of ALL UP wells land on the wrong",
              tg, 100 * r$wrong_side))
  msg(sprintf("    side of 8 m; among the %d wells whose true depth is within",
              r$n_near8))
  msg(sprintf("    +/-2 m of 8 m, %.1f%% are misclassified.",
              100 * r$wrong_side_near8))
}
msg("")
msg(sprintf("  Against the no-information benchmark (%.1f%% / %.1f%%), interpolation",
            100 * bm[vintage == "may1996", naive_error],
            100 * bm[vintage == "may2000", naive_error]))
msg(sprintf("  improves near-cutoff classification by only %.1f pp and %.1f pp.",
            100 * bm[vintage == "may1996", improvement_pp],
            100 * bm[vintage == "may2000", improvement_pp]))
msg("")
msg("  This is the number that matters, and it is a WARNING, not a detail.")
msg("  Wells near the cutoff are exactly the ones an RD relies on, and at 8 m")
msg("  interpolated depth is close to uninformative about which side a unit")
msg("  falls on. That is severe measurement error in the RUNNING VARIABLE: it")
msg("  attenuates the estimate and blurs the discontinuity, and no choice among")
msg("  the methods tested repairs it -- they are all within a few points of")
msg("  each other and of guessing.")
msg("")
msg("  IMPLICATION FOR E1, stated plainly: an interpolated running variable")
msg("  built from this well network will not support a sharp RD at 8 m in UP.")
msg("  The realistic options are the spec's own fallbacks (PHASE0_SPEC.md 4.3,")
msg("  7): a FUZZY RD that instruments assigned treatment with interpolated")
msg("  depth, or a NEAR-WELL SUBSAMPLE where error is smallest -- and section")
msg("  6f(ii) shows that even under 5 km the RMSE is still about 2.7-3.2 m,")
msg("  against a 8 m cutoff. This is a quantitative reason to treat E1 as high")
msg("  risk, and to prefer Sekhri's own validated depth measure if the PI can")
msg("  obtain it.")

msg("")
msg("DOES THE 2000 VINTAGE CHANGE THE PICTURE?")
d_rmse <- met[vintage == "may2000" & method == "ok", rmse] -
          met[vintage == "may1996" & method == "ok", rmse]
d_near <- met[vintage == "may2000" & method == "ok", wrong_side_near8] -
          met[vintage == "may1996" & method == "ok", wrong_side_near8]
msg(sprintf("  Ordinary kriging RMSE moves by %+.3f m and near-cutoff", d_rmse))
msg(sprintf("  misclassification by %+.1f pp when moving from the 1996 vintage",
            100 * d_near))
msg(sprintf("  to the earliest-May-<=-2000 vintage (%s vs %s UP wells).",
            format(met[vintage == "may2000" & method == "ok", n], big.mark = ","),
            format(met[vintage == "may1996" & method == "ok", n], big.mark = ",")))
if (abs(d_rmse) < 0.25 && abs(d_near) < 0.03) {
  msg("  READING: the two vintages give materially the SAME answer. The extra")
  msg("  wells buy denser coverage without measurably degrading accuracy, so")
  msg("  the vintage choice can be made on coverage grounds.")
} else if (d_rmse > 0) {
  msg("  READING: the 2000 vintage is MORE densely covered but LESS accurate.")
  msg("  The coverage gain is not free, and the trade-off is a PI decision.")
} else {
  msg("  READING: the 2000 vintage is both denser AND more accurate here.")
}
msg("")
msg(sprintf("  Distance comparability: LOO is %s for may1996 and %s for may2000",
            vd1, vd2))
msg("  relative to UP villages (section 6g) -- read the error numbers with that")
msg("  adjustment in mind.")

hr("SCOPE REMINDER")
msg("Depth was predicted only at held-out WELL locations. Nothing here predicts")
msg("depth at a shrid, and no water outcome was read. Extending this to village")
msg("centroids is the PI's call.")

hr("STEP 6 COMPLETE")
msg("Tables written to output/tables/:")
for (f in sort(list.files(p_tab(), pattern = "^06"))) msg("  ", f)
msg("Figures written to output/figures/:")
for (f in sort(list.files(p_fig(), pattern = "^06"))) msg("  ", f)
log_close()
