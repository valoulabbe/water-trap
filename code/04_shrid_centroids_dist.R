# ---------------------------------------------------------------------------
# 04_shrid_centroids_dist.R -- shrid centroids from the SHRUG polygons, and the
#   distance from each centroid to the nearest CGWB monitoring well.
#
# NO RD IS RUN HERE. The nearest-well output carries shrid2, well id and
# distance ONLY -- deliberately NOT the water level -- so that the join which
# would create a running variable cannot happen by accident while Phase 0a is
# blocked pending the PI's decision.
#
# Two well sets, so the coverage cost of the vintage rule is visible:
#   dist_km_may1996 -- wells with a non-missing May 1996 reading (11,091)
#   dist_km_may2000 -- wells whose EARLIEST May reading is 2000 or earlier
#                      (13,883, +25%)
# The second is a diagnostic on coverage only; it commits us to nothing.
#
# CRS: EPSG:7755 (India NSF Lambert Conformal Conic, metres) for all distance
# work, per CLAUDE.md; stored coordinates are WGS 84.
#
# Centroids use st_point_on_surface, not st_centroid: a village polygon can be
# concave or multipart, and st_centroid may fall outside it.
#
# Outputs: build/shrid_centroids.rds, build/shrid_nearest_well.rds,
#          build/shrid_nearest_well_state.csv, output/logs/04_shrid_centroids_dist.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(sf)
  library(FNN)
}))
ensure_dirs()
log_open(p_log("04_shrid_centroids_dist.log"))

CRS_M   <- 7755L   # India NSF LCC, metres
CRS_WGS <- 4326L

msg("STEP 4 -- SHRID CENTROIDS AND DISTANCE TO NEAREST CGWB WELL")
msg("Distances only. No water level is written to any output here.")

gpkg <- p_raw("shrug", "shrug-shrid-poly-gpkg", "shrid2_open.gpkg")

# ===========================================================================
# 4a. Centroids from the shrid polygons (chunked)
# ===========================================================================
hr("4a. Centroids from shrid polygons")

lyrs <- sf::st_layers(gpkg)
n_feat <- as.integer(lyrs$features[match("shrid2", lyrs$name)])
check(n_feat == 595438L, "shrid_poly: 595,438 features")
msg("  reading ", format(n_feat, big.mark = ","), " polygons in chunks")

CHUNK <- 25000L
offsets <- seq(0L, n_feat - 1L, by = CHUNK)
parts <- vector("list", length(offsets))

for (i in seq_along(offsets)) {
  q <- sprintf("SELECT shrid2, geom FROM shrid2 LIMIT %d OFFSET %d", CHUNK, offsets[i])
  g <- sf::st_read(gpkg, query = q, quiet = TRUE)
  g <- sf::st_transform(g, CRS_M)
  # Repair invalid rings so point_on_surface cannot fail on a self-intersection.
  bad <- !sf::st_is_valid(g)
  if (any(bad, na.rm = TRUE)) g$geom[which(bad)] <- sf::st_make_valid(g$geom[which(bad)])
  pt <- suppressWarnings(sf::st_point_on_surface(sf::st_geometry(g)))
  xy <- sf::st_coordinates(pt)
  parts[[i]] <- data.table(shrid2 = as.character(g$shrid2),
                           x_m = xy[, 1], y_m = xy[, 2],
                           n_invalid = sum(bad, na.rm = TRUE))
  if (i %% 6L == 0L || i == length(offsets))
    msg("    chunk ", i, "/", length(offsets), "  cumulative rows: ",
        format(sum(vapply(parts[seq_len(i)], function(z) if (is.null(z)) 0L else nrow(z), integer(1))),
               big.mark = ","))
}

cent <- rbindlist(parts)
n_invalid_total <- sum(vapply(parts, function(z) z$n_invalid[1], numeric(1)))
msg("  invalid geometries repaired before centroiding: ", n_invalid_total)

check(nrow(cent) == n_feat, "centroids: one row per polygon feature",
      sprintf("observed %d", nrow(cent)))
check(is.character(cent$shrid2), "centroids: shrid2 is character")
check_unique(cent, "shrid2", "centroids")
check(cent[!is.finite(x_m) | !is.finite(y_m), .N] == 0,
      "centroids: all coordinates finite")

# Back to WGS 84 for storage.
cent_sf <- sf::st_as_sf(cent, coords = c("x_m", "y_m"), crs = CRS_M, remove = FALSE)
ll <- sf::st_coordinates(sf::st_transform(cent_sf, CRS_WGS))
cent[, `:=`(lon_wgs84 = ll[, 1], lat_wgs84 = ll[, 2])]

check(cent[lat_wgs84 < 6 | lat_wgs84 > 38 | lon_wgs84 < 67 | lon_wgs84 > 98, .N] == 0,
      "centroids: all inside the India bounding box",
      sprintf("%d outside", cent[lat_wgs84 < 6 | lat_wgs84 > 38 |
                                   lon_wgs84 < 67 | lon_wgs84 > 98, .N]))

# ===========================================================================
# 4b. Cross-check against SHRUG's own shipped shrid coordinates
# ===========================================================================
hr("4b. Cross-check vs shrid2_spatial_stats latitude/longitude")

sp <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-shrid-keys-dta",
                                       "shrid2_spatial_stats.dta")))
sp <- sp[, .(shrid2, sp_lat = as.numeric(latitude), sp_lon = as.numeric(longitude),
             polysource, high_quality)]

msg("  polygons: ", format(nrow(cent), big.mark = ","),
    " | spatial_stats: ", format(nrow(sp), big.mark = ","))
msg("  in polygons only:       ", format(length(setdiff(cent$shrid2, sp$shrid2)), big.mark = ","))
msg("  in spatial_stats only:  ", format(length(setdiff(sp$shrid2, cent$shrid2)), big.mark = ","))

cmp <- merge(cent[, .(shrid2, lon_wgs84, lat_wgs84)], sp, by = "shrid2")
cmp <- cmp[is.finite(sp_lat) & is.finite(sp_lon)]
msg("  comparable on both:     ", format(nrow(cmp), big.mark = ","))

a <- sf::st_transform(sf::st_as_sf(cmp, coords = c("lon_wgs84", "lat_wgs84"), crs = CRS_WGS), CRS_M)
b <- sf::st_transform(sf::st_as_sf(cmp, coords = c("sp_lon", "sp_lat"), crs = CRS_WGS), CRS_M)
ca <- sf::st_coordinates(a); cb <- sf::st_coordinates(b)
cmp[, delta_km := sqrt((ca[, 1] - cb[, 1])^2 + (ca[, 2] - cb[, 2])^2) / 1000]

msg("")
msg("  Distance between our point_on_surface centroid and SHRUG's shipped point (km):")
print(round(quantile(cmp$delta_km, c(0, .25, .5, .75, .9, .99, 1), na.rm = TRUE), 3))
msg("  share above 5 km:  ", sprintf("%.4f", mean(cmp$delta_km > 5, na.rm = TRUE)))
msg("  share above 25 km: ", sprintf("%.4f", mean(cmp$delta_km > 25, na.rm = TRUE)))

med_delta <- median(cmp$delta_km, na.rm = TRUE)
check(med_delta < 5,
      sprintf("cross-check: median divergence below 5 km (observed %.3f km)", med_delta),
      "A large systematic divergence would mean one of the two point sets is wrong.")
if (mean(cmp$delta_km > 25, na.rm = TRUE) > 0.01)
  warn("more than 1% of shrids diverge by >25 km from SHRUG's shipped point -- inspect")

# ===========================================================================
# 4c. Distance to the nearest CGWB well
# ===========================================================================
hr("4c. Distance to nearest CGWB monitoring well")

wells <- readRDS(p_build("cgwb_wells.rds"))
w_sf  <- sf::st_transform(
  sf::st_as_sf(wells, coords = c("LON", "LAT"), crs = CRS_WGS, remove = FALSE), CRS_M)
wxy <- sf::st_coordinates(w_sf)
wells[, `:=`(x_m = wxy[, 1], y_m = wxy[, 2])]

nearest_to <- function(sub, label) {
  check(nrow(sub) > 0, paste0("well set '", label, "' is non-empty"))
  msg("  well set '", label, "': ", format(nrow(sub), big.mark = ","), " wells")
  nn <- FNN::get.knnx(as.matrix(sub[, .(x_m, y_m)]),
                      as.matrix(cent[, .(x_m, y_m)]), k = 1)
  data.table(wlcode = sub$WLCODE[nn$nn.index[, 1]],
             dist_km = nn$nn.dist[, 1] / 1000)
}

s96 <- wells[has_may1996 == TRUE]
s00 <- wells[earliest_may_le_2000 == TRUE]
check(nrow(s96) == 11091L, "well set may1996: 11,091 wells")
check(nrow(s00) == 13883L, "well set may2000: 13,883 wells")

n96 <- nearest_to(s96, "may1996")
n00 <- nearest_to(s00, "may2000")

near <- data.table(
  shrid2          = cent$shrid2,
  wlcode_may1996  = n96$wlcode,
  dist_km_may1996 = n96$dist_km,
  wlcode_may2000  = n00$wlcode,
  dist_km_may2000 = n00$dist_km
)

# The may2000 well set is a strict superset of may1996, so its distance can
# never be larger. This is a real check on the nearest-neighbour call.
check(nrow(s96[!WLCODE %in% s00$WLCODE]) == 0,
      "may2000 well set is a superset of may1996")
tol <- 1e-6
check(near[dist_km_may2000 > dist_km_may1996 + tol, .N] == 0,
      "dist_km_may2000 <= dist_km_may1996 everywhere",
      sprintf("%d violations", near[dist_km_may2000 > dist_km_may1996 + tol, .N]))
check(near[!is.finite(dist_km_may1996) | !is.finite(dist_km_may2000), .N] == 0,
      "no missing or infinite distances")

msg("")
msg("  Distance to nearest well, km:")
qs <- c(.1, .25, .5, .75, .9, .99, 1)
print(rbind(
  may1996 = round(quantile(near$dist_km_may1996, qs), 2),
  may2000 = round(quantile(near$dist_km_may2000, qs), 2)
))
msg("")
msg("  Share of shrids beyond a threshold:")
thr <- data.table(
  threshold_km = c(10, 25, 50),
  share_may1996 = sapply(c(10, 25, 50), function(t) mean(near$dist_km_may1996 > t)),
  share_may2000 = sapply(c(10, 25, 50), function(t) mean(near$dist_km_may2000 > t))
)
print(thr)
msg("")
msg("  COVERAGE GAIN from accepting an earliest May reading up to 2000:")
msg(sprintf("   median distance %.2f km -> %.2f km; share beyond 25 km %.4f -> %.4f",
            median(near$dist_km_may1996), median(near$dist_km_may2000),
            mean(near$dist_km_may1996 > 25), mean(near$dist_km_may2000 > 25)))

# ===========================================================================
# 4d. Coverage by state
# ===========================================================================
hr("4d. Distance by state")

loc <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-shrid-keys-dta",
                                        "shrid_loc_names.dta")))
near_st <- merge(near, loc[, .(shrid2, state_name)], by = "shrid2", all.x = TRUE)
st <- near_st[, .(
  shrids            = .N,
  med_km_may1996    = round(median(dist_km_may1996), 2),
  med_km_may2000    = round(median(dist_km_may2000), 2),
  p90_km_may1996    = round(quantile(dist_km_may1996, .9), 2),
  share_gt25_may1996 = round(mean(dist_km_may1996 > 25), 4),
  share_gt25_may2000 = round(mean(dist_km_may2000 > 25), 4)
), by = state_name][order(-shrids)]
print(st)
fwrite(st, p_build("shrid_nearest_well_state.csv"))
msg("")
msg("  COVERAGE WARNING. The CGWB file covers 24 states; several SHRUG states")
msg("  have no monitoring well at all, so their shrids take a nearest well from")
msg("  an adjacent state and the distance is large by construction. States with")
msg("  a median nearest-well distance above 25 km (may1996 set):")
far <- st[med_km_may1996 > 25][order(-shrids)]
for (i in seq_len(nrow(far)))
  msg(sprintf("    %-26s %7s shrids   median %8.1f km",
              far$state_name[i], format(far$shrids[i], big.mark = ","),
              far$med_km_may1996[i]))
msg("  Total shrids in those states: ",
    format(sum(far$shrids), big.mark = ","),
    sprintf(" (%.1f%% of all shrids)", 100 * sum(far$shrids) / nrow(near)))
msg("  Read the per-state table before applying any distance cutoff.")

# ===========================================================================
# 4e. Write
# ===========================================================================
hr("4e. Write outputs")

out_cent <- cent[, .(shrid2, lon_wgs84, lat_wgs84)]
saveRDS(out_cent, p_build("shrid_centroids.rds"))
fwrite(out_cent, p_build("shrid_centroids.csv"))
saveRDS(near, p_build("shrid_nearest_well.rds"))
fwrite(near, p_build("shrid_nearest_well.csv"))

# Guard the boundary: the nearest-well file must not carry a water level.
banned <- c("depth_mbgl", "depth", "level", "wl", "z")
check(length(intersect(tolower(names(near)), banned)) == 0,
      "nearest-well output carries NO water level column",
      paste("found:", paste(intersect(tolower(names(near)), banned), collapse = ", ")))

msg("build/shrid_centroids.rds   : ", format(nrow(out_cent), big.mark = ","), " shrids")
msg("build/shrid_nearest_well.rds: ", format(nrow(near), big.mark = ","), " shrids")
msg("  columns: ", paste(names(near), collapse = ", "))

hr("STEP 4 COMPLETE")
log_close()
