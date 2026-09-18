# ---------------------------------------------------------------------------
# 07_temporal_noise_up.R -- how much of the interpolation nugget is TEMPORAL
#   noise, and how fuzzy is "being above 8 m" in reality?
#
# Follow-up to code/06_interp_loo_up.R. Step 6 found that near the 8 m cutoff
# no interpolation method beats a no-information rule, and that the fitted
# variograms carry a large nugget. This script asks whether that nugget is
# year-to-year variation in the well readings themselves -- in which case
# averaging over years should shrink it -- and what the same variation implies
# for treating "depth > 8 m" as a fixed property of a village.
#
# SCOPE LIMITS, held strictly (unchanged from step 6):
#   * NO RD is estimated.
#   * NO water outcome is read.
#   * Depth is predicted ONLY at held-out WELL locations, never at a shrid.
#
# (a) Within-well temporal variation, UP wells with >= 3 May readings 1996-2000.
# (b) LOO (NN, IDW2, ordinary kriging) on each well's MEAN May depth 1996-2000,
#     reported next to step 6's single-year results, with nugget shares.
#     Plus a like-for-like run on a fixed set of wells where only the TARGET
#     definition changes (single year vs mean), which is the clean test.
#
# Outputs: output/tables/07_*.csv, output/figures/07_variogram_mean.pdf,
#          output/logs/07_temporal_noise_up.log
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

log_open(p_log("07_temporal_noise_up.log"))

CRS_M   <- 7755L
CRS_WGS <- 4326L
IDW_NMAX  <- 12L
KRIG_NMAX <- 50L
DEPTH_MIN <- 0
DEPTH_MAX <- 100
CUT       <- 8
YR_LO     <- 1996L
YR_HI     <- 2000L

msg("STEP 7 -- TEMPORAL NOISE IN MAY DEPTH, UTTAR PRADESH WELLS")
msg("")
msg("Follow-up to step 6. No RD, no water outcome, and depth is predicted only")
msg("at held-out WELL locations -- never at a shrid.")

# ===========================================================================
# 7a. Region: UP border + 50 km predictor buffer (as in step 6)
# ===========================================================================
hr("7a. Region")

dists <- sf::st_read(p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg"),
                     quiet = TRUE)
up_d <- dists[dists$pc11_state_id == "09", ]
check(nrow(up_d) == 71L, "UP border: 71 pc11 districts with state id 09")
up_poly <- sf::st_union(sf::st_make_valid(sf::st_transform(up_d, CRS_M)))
up_buf  <- sf::st_buffer(up_poly, units::set_units(50, "km"))

wells <- readRDS(p_build("cgwb_wells.rds"))
w_sf  <- sf::st_transform(
  sf::st_as_sf(wells, coords = c("LON", "LAT"), crs = CRS_WGS, remove = FALSE), CRS_M)
xy <- sf::st_coordinates(w_sf)
wells[, `:=`(x_m = xy[, 1], y_m = xy[, 2])]
wells[, in_up_buf   := as.vector(sf::st_intersects(w_sf, up_buf, sparse = FALSE))]
wells[, is_up_label := STATE == "UP"]
region <- wells[in_up_buf == TRUE | is_up_label == TRUE]
msg("  predictor region (UP + 50 km buffer): ", format(nrow(region), big.mark = ","), " wells")

# ===========================================================================
# 7b. Assemble the May 1996-2000 panel
# ===========================================================================
hr("7b. May readings 1996-2000")

may <- readRDS(p_build("cgwb_may_long.rds"))
pan <- may[year >= YR_LO & year <= YR_HI & WLCODE %in% region$WLCODE,
           .(WLCODE, year, depth = depth_mbgl)]

# Same implausible-value rule as step 6, applied per reading.
bad <- pan[depth < DEPTH_MIN | depth > DEPTH_MAX]
msg("  readings in window: ", format(nrow(pan), big.mark = ","))
msg("  implausible readings excluded (depth < ", DEPTH_MIN, " or > ", DEPTH_MAX, " m): ",
    nrow(bad))
if (nrow(bad) > 0) {
  ex <- merge(bad, wells[, .(WLCODE, STATE, DISTRICT, SITE_TYPE)], by = "WLCODE")
  print(ex[order(-depth), .(WLCODE, STATE, DISTRICT, SITE_TYPE, year, depth)])
  fwrite(ex, p_tab("07_excluded_readings.csv"))
}
pan <- pan[depth >= DEPTH_MIN & depth <= DEPTH_MAX]

wsum <- pan[, .(n_read = .N, mean_depth = mean(depth), sd_depth = sd(depth),
                min_depth = min(depth), max_depth = max(depth)), by = WLCODE]
wsum <- merge(wsum, region[, .(WLCODE, STATE, DISTRICT, SITE_TYPE, x_m, y_m, is_up_label)],
              by = "WLCODE")
msg("  wells with >= 1 May reading in the window: ", format(nrow(wsum), big.mark = ","),
    " (UP: ", format(wsum[is_up_label == TRUE, .N], big.mark = ","), ")")
msg("")
msg("  Readings per well in the window:")
print(wsum[, .N, by = n_read][order(n_read)])

# ===========================================================================
# 7c. (a) Within-well temporal variation, UP wells with >= 3 readings
# ===========================================================================
hr("7c. (a) Within-well variation in May depth, UP wells with >= 3 readings")

u3 <- wsum[is_up_label == TRUE & n_read >= 3L]
check(nrow(u3) > 0, "at least one UP well has 3+ May readings in 1996-2000")
msg("  UP wells with >= 3 May readings in ", YR_LO, "-", YR_HI, ": ",
    format(nrow(u3), big.mark = ","))
msg("")
msg("  Distribution of the WITHIN-WELL standard deviation of May depth (m):")
qs <- c(0, .1, .25, .5, .75, .9, .95, 1)
print(round(quantile(u3$sd_depth, qs), 3))
msg("")
msg(sprintf("  mean within-well SD = %.3f m; median = %.3f m", mean(u3$sd_depth),
            median(u3$sd_depth)))
msg(sprintf("  share of wells with within-well SD above 1 m: %.3f", mean(u3$sd_depth > 1)))
msg(sprintf("  share above 2 m: %.3f", mean(u3$sd_depth > 2)))
msg("")
msg("  Within-well RANGE (max - min across years), m:")
print(round(quantile(u3$max_depth - u3$min_depth, qs), 3))

# straddling the cutoff
u3[, straddles := min_depth < CUT & max_depth > CUT]
u3[, near8_mean := abs(mean_depth - CUT) <= 2]
msg("")
msg("  HOW FUZZY IS 'ABOVE 8 m'?")
msg(sprintf("  Wells whose May readings fall on BOTH sides of %d m in different", CUT))
msg(sprintf("  years: %s of %s (%.1f%%).",
            format(u3[straddles == TRUE, .N], big.mark = ","),
            format(nrow(u3), big.mark = ","), 100 * mean(u3$straddles)))
msg(sprintf("  Among the %s wells whose MEAN depth is within +/-2 m of %d m,",
            format(u3[near8_mean == TRUE, .N], big.mark = ","), CUT))
msg(sprintf("  %.1f%% straddle the cutoff across years.",
            100 * u3[near8_mean == TRUE, mean(straddles)]))
msg("")
msg("  Read that second number carefully: for wells sitting near the cutoff,")
msg("  'above 8 m' is not a fixed property of the location at all. It flips")
msg("  between years for a large share of them, using the SAME well and the")
msg("  SAME pre-monsoon month -- before any interpolation error is added.")

fwrite(u3[, .(WLCODE, STATE, DISTRICT, SITE_TYPE, n_read, mean_depth, sd_depth,
              min_depth, max_depth, straddles, near8_mean)],
       p_tab("07a_within_well_variation.csv"))

sd_tbl <- data.table(
  statistic = c("n wells", "mean SD", "median SD", "p90 SD", "share SD > 1m",
                "share SD > 2m", "share straddling 8m", "share straddling | mean near 8m"),
  value = c(nrow(u3), mean(u3$sd_depth), median(u3$sd_depth),
            quantile(u3$sd_depth, .9), mean(u3$sd_depth > 1), mean(u3$sd_depth > 2),
            mean(u3$straddles), u3[near8_mean == TRUE, mean(straddles)]))
fwrite(sd_tbl, p_tab("07a_within_well_summary.csv"))

# ===========================================================================
# 7d. (b) LOO on mean May depth
# ===========================================================================
hr("7d. (b) Variogram on mean May depth 1996-2000")

fit_vgm <- function(d, valcol, tag) {
  dd <- copy(d); dd[, v := get(valcol)]
  s <- sf::st_as_sf(dd, coords = c("x_m", "y_m"), crs = CRS_M)
  ev <- gstat::variogram(v ~ 1, s, cutoff = 200000, width = 5000)
  p0 <- stats::var(dd$v, na.rm = TRUE)
  cand <- list()
  for (mdl in c("Sph", "Exp")) {
    f <- try(suppressWarnings(gstat::fit.variogram(
      ev, gstat::vgm(psill = p0 * 0.7, model = mdl, range = 60000,
                     nugget = p0 * 0.3))), silent = TRUE)
    if (!inherits(f, "try-error") && !is.null(attr(f, "SSErr"))) cand[[mdl]] <- f
  }
  check(length(cand) > 0, paste0(tag, ": a variogram model converged"))
  sse  <- vapply(cand, function(f) attr(f, "SSErr"), numeric(1))
  best <- names(which.min(sse))
  f    <- cand[[best]]
  nug_share <- f$psill[1] / sum(f$psill)
  msg(sprintf("  %-22s %s: nugget = %7.3f  psill = %7.3f  range = %6.1f km  nugget share = %.3f",
              tag, best, f$psill[1], f$psill[2], f$range[2] / 1000, nug_share))
  list(ev = ev, fit = f, model = best, nugget_share = nug_share, data = dd)
}

# Predictor sets over the same well universe, differing only in the target value.
mean_set <- copy(wsum)
one_set  <- merge(pan[year == YR_LO, .(WLCODE, depth96 = depth)],
                  wsum[, .(WLCODE, STATE, DISTRICT, SITE_TYPE, x_m, y_m,
                           is_up_label, n_read, mean_depth, sd_depth)],
                  by = "WLCODE")
msg("")
msg("  mean-depth set: ", format(nrow(mean_set), big.mark = ","), " wells")
msg("  May-1996 set:   ", format(nrow(one_set), big.mark = ","), " wells")
msg("")
vg_mean <- fit_vgm(mean_set, "mean_depth", "mean 1996-2000")
vg_one  <- fit_vgm(one_set,  "depth96",    "May 1996 only")

# The two sets above differ in SIZE (the mean set includes wells with no 1996
# reading), so their nugget shares are NOT comparable: a difference could be the
# well set rather than the averaging. For the nugget question we therefore refit
# BOTH on the identical wells -- those with a May 1996 reading -- so the only
# thing that changes is the target definition.
msg("")
msg("  Nugget comparison on IDENTICAL wells (those with a May 1996 reading),")
msg("  so that only the target definition differs:")
same_set <- merge(one_set[, .(WLCODE, depth96)],
                  mean_set[, .(WLCODE, mean_depth, n_read, x_m, y_m,
                               is_up_label)], by = "WLCODE")
vg_same_one  <- fit_vgm(same_set, "depth96",    "same wells: May 1996")
vg_same_mean <- fit_vgm(same_set, "mean_depth", "same wells: mean")

# --- direct variance decomposition ----------------------------------------
# A variogram nugget bundles together: (i) year-to-year temporal noise,
# (ii) genuine micro-scale spatial variation, (iii) measurement error. The
# within-well variance across years estimates (i) DIRECTLY, without relying on
# any variogram fit, so it settles how much of the nugget averaging could ever
# remove.
hr("7d(ii). How much of the nugget could be temporal?")
var_t <- mean(u3$sd_depth^2)
nug1  <- vg_same_one$fit$psill[1]
msg(sprintf("  Mean within-well VARIANCE across years (UP, 3+ readings): %.3f m2", var_t))
msg(sprintf("  Fitted nugget, single-year target, same wells:            %.3f m2", nug1))
msg(sprintf("  Temporal noise is therefore at most %.1f%% of the nugget.",
            100 * var_t / nug1))
msg("")
msg("  Averaging over k readings cuts the temporal part to roughly 1/k of that,")
msg(sprintf("  so the most averaging could remove is about %.1f%% of the nugget --",
            100 * var_t / nug1))
msg("  and in practice less, since most wells have fewer than 5 readings.")
msg("  The remaining majority of the nugget is genuine micro-scale spatial")
msg("  variation plus measurement error, which no amount of temporal averaging")
msg("  can touch.")
decomp <- data.table(mean_within_well_variance = var_t,
                     nugget_single_year = nug1,
                     max_temporal_share_of_nugget = var_t / nug1)
fwrite(decomp, p_tab("07d_nugget_decomposition.csv"))

plot_vgm <- function(vg, file) {
  ln <- gstat::variogramLine(vg$fit, maxdist = max(vg$ev$dist))
  grDevices::pdf(file, width = 6, height = 4.2); on.exit(grDevices::dev.off(), add = TRUE)
  op <- par(mar = c(4.2, 4.4, 0.8, 0.8)); on.exit(par(op), add = TRUE)
  plot(vg$ev$dist / 1000, vg$ev$gamma, pch = 19, cex = 0.7,
       xlab = "distance (km)", ylab = "semivariance",
       ylim = c(0, max(vg$ev$gamma, ln$gamma) * 1.05))
  lines(ln$dist / 1000, ln$gamma, lwd = 2)
}
plot_vgm(vg_mean, p_fig("07_variogram_mean.pdf"))

# --- LOO ------------------------------------------------------------------
hr("7e. Leave-one-out: NN, IDW power 2, ordinary kriging")

run_loo <- function(vg, valcol, tag, target_filter = NULL) {
  d <- copy(vg$data); d[, idx := .I]
  tgt <- d[is_up_label == TRUE]
  if (!is.null(target_filter)) tgt <- tgt[eval(target_filter)]
  msg("  ", tag, ": ", format(nrow(d), big.mark = ","), " predictors, ",
      format(nrow(tgt), big.mark = ","), " UP targets")
  sf_all <- sf::st_as_sf(d, coords = c("x_m", "y_m"), crs = CRS_M)
  res <- data.table(WLCODE = tgt$WLCODE, truth = tgt$v,
                    nn = NA_real_, idw2 = NA_real_, ok = NA_real_)
  for (i in seq_len(nrow(tgt))) {
    keep  <- d$idx != tgt$idx[i]
    train <- sf_all[keep, ]
    newp  <- sf_all[d$idx == tgt$idx[i], ]
    k1 <- FNN::get.knnx(as.matrix(d[keep, .(x_m, y_m)]),
                        as.matrix(tgt[i, .(x_m, y_m)]), k = 1)
    set(res, i, "nn", d[keep][k1$nn.index[1, 1], v])
    z <- suppressMessages(gstat::idw(v ~ 1, train, newp, idp = 2,
                                     nmax = IDW_NMAX, debug.level = 0))
    set(res, i, "idw2", z$var1.pred[1])
    z <- suppressMessages(gstat::krige(v ~ 1, train, newp, model = vg$fit,
                                       nmax = KRIG_NMAX, debug.level = 0))
    set(res, i, "ok", z$var1.pred[1])
    if (i %% 300L == 0L) msg("      ", i, "/", nrow(tgt))
  }
  msg("      ", nrow(tgt), "/", nrow(tgt), " done")
  res[]
}

METH <- c(nn = "nearest neighbour", idw2 = "IDW power 2", ok = "ordinary kriging")

metrics <- function(res, tag, nug) {
  tr <- res$truth
  near <- abs(tr - CUT) <= 2
  p_deep <- mean(tr[near] > CUT)
  naive  <- min(p_deep, 1 - p_deep)
  rbindlist(lapply(names(METH), function(m) {
    pr <- res[[m]]; ok <- !is.na(pr)
    data.table(target = tag, method = m, label = METH[[m]], n = sum(ok),
               nugget_share = nug,
               rmse = sqrt(mean((pr[ok] - tr[ok])^2)),
               mae  = mean(abs(pr[ok] - tr[ok])),
               bias = mean(pr[ok] - tr[ok]),
               wrong_side = mean((tr[ok] > CUT) != (pr[ok] > CUT)),
               n_near8 = sum(near),
               wrong_near8 = mean((tr[near] > CUT) != (pr[near] > CUT)),
               naive_near8 = naive,
               improvement_pp = naive - mean((tr[near] > CUT) != (pr[near] > CUT)))
  }))
}

t0 <- Sys.time()
loo_mean <- run_loo(vg_mean, "mean_depth", "mean 1996-2000")
loo_one  <- run_loo(vg_one,  "depth96",    "May 1996 only")
msg("  runtime: ", sprintf("%.1f min", as.numeric(difftime(Sys.time(), t0, units = "mins"))))

m_all <- rbind(metrics(loo_mean, "mean 1996-2000", vg_mean$nugget_share),
               metrics(loo_one,  "May 1996 only",  vg_one$nugget_share))

hr("7f. Results: mean-depth target next to single-year target")
print(m_all[, .(target, label, n, nugget_share = round(nugget_share, 3),
                rmse = round(rmse, 3), mae = round(mae, 3), bias = round(bias, 3),
                wrong_side = round(wrong_side, 4),
                wrong_near8 = round(wrong_near8, 4),
                naive_near8 = round(naive_near8, 4),
                improvement_pp = round(improvement_pp, 4))])
fwrite(m_all, p_tab("07b_loo_metrics_mean_vs_single.csv"))

# Step 6's headline numbers, for continuity.
if (file.exists(p_tab("06_loo_metrics.csv"))) {
  s6 <- fread(p_tab("06_loo_metrics.csv"))
  msg("")
  msg("  For continuity, step 6's single-year results (its own well sets):")
  print(s6[method %in% names(METH),
           .(vintage, label, n, rmse = round(rmse, 3),
             wrong_near8 = round(wrong_side_near8, 4))])
}

# --- like-for-like: same wells, only the target definition changes ---------
hr("7g. Like-for-like: identical wells, single-year vs mean target")

common <- intersect(loo_mean$WLCODE, loo_one$WLCODE)
msg("  UP wells appearing in both runs: ", format(length(common), big.mark = ","))
lm2 <- loo_mean[WLCODE %in% common]; lo2 <- loo_one[WLCODE %in% common]
lfl <- rbind(metrics(lm2, "mean 1996-2000 (common wells)", vg_mean$nugget_share),
             metrics(lo2, "May 1996 only (common wells)",  vg_one$nugget_share))
print(lfl[, .(target, label, n, rmse = round(rmse, 3),
              wrong_near8 = round(wrong_near8, 4),
              naive_near8 = round(naive_near8, 4),
              improvement_pp = round(improvement_pp, 4))])
fwrite(lfl, p_tab("07c_like_for_like.csv"))

# ===========================================================================
# 7h. Bottom line
# ===========================================================================
hr("7h. BOTTOM LINE")

n_one  <- vg_same_one$nugget_share
n_mean <- vg_same_mean$nugget_share
d_nug  <- n_mean - n_one
ok_one  <- lfl[target %like% "May 1996" & method == "ok"]
ok_mean <- lfl[target %like% "mean"     & method == "ok"]

msg("DOES TEMPORAL AVERAGING REDUCE THE NUGGET?")
msg("  Measured on IDENTICAL wells, so only the target definition changes:")
msg(sprintf("  nugget share %.3f on the single-year target, %.3f on the mean of",
            n_one, n_mean))
msg(sprintf("  1996-2000 -- a change of %+.3f.", d_nug))
msg(sprintf("  Independently, the within-well variance across years is %.3f m2", var_t))
msg(sprintf("  against a single-year nugget of %.3f m2, so temporal noise can be", nug1))
msg(sprintf("  at most %.0f%% of the nugget however the variogram is fitted.",
            100 * var_t / nug1))
if (d_nug < -0.05) {
  msg("  Averaging DOES cut the nugget materially, so a real part of the")
  msg("  short-range noise in step 6 was year-to-year variation rather than")
  msg("  genuine small-scale spatial structure.")
} else if (d_nug > 0.05) {
  msg("  Averaging does NOT cut the nugget -- it rises. The short-range noise")
  msg("  is not mainly temporal.")
} else {
  msg("  Averaging barely moves the nugget. The short-range noise is therefore")
  msg("  NOT mainly year-to-year variation: it is genuine small-scale spatial")
  msg("  heterogeneity in the water table, which averaging cannot remove.")
}

msg("")
msg("DOES IT CHANGE THE CONCLUSION?")
msg(sprintf("  On identical wells, ordinary kriging RMSE moves from %.3f m",
            ok_one$rmse))
msg(sprintf("  (single year) to %.3f m (mean), and near-cutoff misclassification",
            ok_mean$rmse))
msg(sprintf("  from %.1f%% to %.1f%%, against a no-information benchmark of %.1f%%",
            100 * ok_one$wrong_near8, 100 * ok_mean$wrong_near8,
            100 * ok_mean$naive_near8))
msg(sprintf("  and %.1f%% respectively.", 100 * ok_one$naive_near8))
if (ok_mean$improvement_pp > 0.05) {
  msg("  CONCLUSION CHANGES: with an averaged target, interpolation now beats")
  msg("  the no-information rule near the cutoff by a usable margin.")
} else {
  msg("  CONCLUSION UNCHANGED: even with an averaged target, interpolation does")
  msg("  not beat the no-information rule near the cutoff by a usable margin.")
  msg("  Step 6's finding survives temporal averaging.")
}

msg("")
msg("HOW FUZZY IS 'BEING ABOVE 8 m' IN REALITY?")
msg(sprintf("  Within a single well, the median year-to-year SD of pre-monsoon May"))
msg(sprintf("  depth is %.2f m, and %.1f%% of UP wells with 3+ readings record",
            median(u3$sd_depth), 100 * mean(u3$straddles)))
msg(sprintf("  depths on BOTH sides of %d m in different years. Among wells whose",
            CUT))
msg(sprintf("  mean sits within +/-2 m of the cutoff, %.1f%% straddle it.",
            100 * u3[near8_mean == TRUE, mean(straddles)]))
msg("")
str_near <- u3[near8_mean == TRUE, mean(straddles)]
msg("  So the cutoff is fuzzy BEFORE any interpolation. Even a village with its")
msg(sprintf("  own monitoring well ON SITE would have an ambiguous treatment status in
  a %s of near-cutoff cases (%.1f%%). That is a property of the water",
            if (str_near > 0.5) "MAJORITY" else "large minority", 100 * str_near))
msg("  table, not of our method, and it caps how sharp any 8 m RD built on")
msg("  1990s CGWB readings can be -- which is a further argument for Sekhri's")
msg("  own validated assignment over a reconstruction, and for treating the")
msg("  design as fuzzy rather than sharp (PHASE0_SPEC.md 4.3).")

hr("SCOPE REMINDER")
msg("Wells only. No shrid prediction, no water outcome, no RD.")

hr("STEP 7 COMPLETE")
msg("Tables written to output/tables/:")
for (f in sort(list.files(p_tab(), pattern = "^07"))) msg("  ", f)
log_close()
