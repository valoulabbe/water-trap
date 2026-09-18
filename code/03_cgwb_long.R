# ---------------------------------------------------------------------------
# 03_cgwb_long.R -- reshape the CGWB monitoring-well panel to long, keep the
#                   PRE-MONSOON (May) readings, flag each well's EARLIEST May
#                   reading, and QC.
#
# NO RD IS RUN HERE. No depth value is joined to any water outcome.
#
# Source: raw/cgwb/CGWB_data_wide.csv -- 28,076 wells, quarterly levels
# May 1996 - Jan 2017, with lat/lon. Provenance (raw/README.md): obtained from
# github.com/craigdsouza/cgwb; CGWB data received by e-mail by T. Hora
# (U. Waterloo). UNOFFICIAL COPY, NO LICENCE -- flagged here because it
# constrains redistribution and should be re-sourced from India-WRIS before
# anything is published.
#
# Spec basis: PHASE0_SPEC.md 3.2 and CLAUDE.md -- "Use the EARLIEST available
# vintage (mid-1990s) and the pre-monsoon reading (the deeper, pump-binding
# measure)"; never contemporary depth for assignment.
#
# QC policy: anomalies are FLAGGED AND LOGGED, never silently dropped.
#
# Outputs: build/cgwb_may_long.rds, build/cgwb_wells.rds,
#          build/cgwb_state_counts.csv, output/logs/03_cgwb_long.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
log_open(p_log("03_cgwb_long.log"))

msg("STEP 3 -- CGWB MONITORING WELLS: LONG PANEL, PRE-MONSOON (MAY) READINGS")
msg("")
msg("PROVENANCE WARNING: raw/cgwb/CGWB_data_wide.csv is an UNOFFICIAL copy with")
msg("NO LICENCE (see raw/README.md). Fine for internal Phase 0 preparation;")
msg("re-source from India-WRIS/CGWB before publication or redistribution.")

cg <- fread(p_raw("cgwb", "CGWB_data_wide.csv"))

# The source CSV's first column is an unnamed row index; fread names it V1.
# Drop it and nothing else.
if ("V1" %in% names(cg)) cg[, V1 := NULL]
check(all(c("STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE", "WLCODE") %in% names(cg)),
      "cgwb: identifier columns intact after dropping the row index")

MAY_COLS <- paste("May", 1996:2016)
check(all(MAY_COLS %in% names(cg)), "cgwb: all 21 May columns present")
check(nrow(cg) == 28076L, "cgwb: 28,076 wells")
check(sum(duplicated(cg$WLCODE)) == 0, "cgwb: WLCODE unique")

# ===========================================================================
# 3a. Reshape to long, May only
# ===========================================================================
hr("3a. Reshape wide -> long (May readings only)")

long <- melt(cg,
             id.vars = c("WLCODE", "STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE"),
             measure.vars = MAY_COLS,
             variable.name = "reading", value.name = "depth_mbgl",
             variable.factor = FALSE)
long[, year  := as.integer(sub("^May ", "", reading))]
long[, month := "May"]
long[, reading := NULL]
setcolorder(long, c("WLCODE", "STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE",
                    "year", "month", "depth_mbgl"))

check(nrow(long) == 28076L * 21L, "long: 28,076 wells x 21 May columns")
msg("  long rows (incl. missing): ", format(nrow(long), big.mark = ","))
msg("  non-missing May readings:  ", format(long[!is.na(depth_mbgl), .N], big.mark = ","))

# Keep only rows with an actual reading for the analysis panel.
may <- long[!is.na(depth_mbgl)]
setorder(may, WLCODE, year)

# ===========================================================================
# 3b. Earliest May reading per well
# ===========================================================================
hr("3b. Earliest pre-monsoon (May) reading per well")

may[, earliest_may := year == min(year), by = WLCODE]
check(may[earliest_may == TRUE, .N] == uniqueN(may$WLCODE),
      "exactly one earliest-May row per well with any May reading")

first_yr <- may[earliest_may == TRUE, .(WLCODE, earliest_may_year = year)]
msg("  wells with >= 1 May reading: ", format(nrow(first_yr), big.mark = ","))
msg("  wells with NO May reading:   ",
    format(28076L - nrow(first_yr), big.mark = ","))
msg("")
msg("  Wells by earliest May reading year:")
print(first_yr[, .N, by = earliest_may_year][order(earliest_may_year)])

n_1996 <- cg[!is.na(`May 1996`), .N]
n_2000 <- first_yr[earliest_may_year <= 2000, .N]
msg("")
msg("  wells with a May 1996 reading:            ", format(n_1996, big.mark = ","))
msg("  wells with earliest May reading <= 2000:  ", format(n_2000, big.mark = ","),
    sprintf("  (+%.0f%%)", 100 * (n_2000 / n_1996 - 1)))

check(n_1996 == 11091L, "cgwb: 11,091 wells have a May 1996 reading")
check(n_2000 == 13883L, "cgwb: 13,883 wells have an earliest May reading <= 2000")

# ===========================================================================
# 3c. QC -- flag, do not drop
# ===========================================================================
hr("3c. QC (anomalies are FLAGGED, never silently dropped)")

qc <- data.table(check = character(), n = integer(), action = character())
add_qc <- function(what, n, action) qc <<- rbind(qc, data.table(check = what, n = as.integer(n), action = action))

add_qc("duplicate WLCODE", sum(duplicated(cg$WLCODE)), "hard stop if > 0")
colocated <- sum(duplicated(cg[, .(LAT, LON)]))
add_qc("rows sharing LAT/LON with another well", colocated,
       "flagged: co-located wells; relevant to the spec's clustering rule")
add_qc("wells with no May reading at all", 28076L - nrow(first_yr), "flagged, retained")
add_qc("blank SITE_TYPE", cg[trimws(SITE_TYPE) == "", .N], "flagged, retained")
add_qc("May readings with depth_mbgl < 0", may[depth_mbgl < 0, .N],
       "flagged, retained (artesian/rounding)")
add_qc("May readings with depth_mbgl > 100", may[depth_mbgl > 100, .N], "flagged, retained")
add_qc("May readings with depth_mbgl > 300", may[depth_mbgl > 300, .N], "flagged, retained")
add_qc("coordinates outside India bbox", cg[!(LAT %between% c(6, 38) & LON %between% c(67, 98)), .N],
       "hard stop if > 0")
print(qc)

check(qc[check == "duplicate WLCODE", n] == 0, "QC: no duplicate WLCODE")
check(qc[check == "coordinates outside India bbox", n] == 0,
      "QC: all coordinates inside the India bounding box")

msg("")
msg("  Extreme May 1996 values (the 10 above 100 m and the 1 negative):")
print(may[year == 1996 & (depth_mbgl < 0 | depth_mbgl > 100),
          .(WLCODE, STATE, DISTRICT, SITE_TYPE, depth_mbgl)][order(-depth_mbgl)])
msg("")
msg("  These are retained. A 534 m reading on a Dug Well is not physically")
msg("  credible and would need excluding before any depth construction, but")
msg("  that is a decision for the depth step, not for ingestion.")

# Per-reading QC flags carried into the output.
may[, `:=`(
  flag_negative  = depth_mbgl < 0,
  flag_gt_100m   = depth_mbgl > 100,
  flag_gt_300m   = depth_mbgl > 300
)]

# Per-well flags.
wells <- unique(cg[, .(WLCODE, STATE, DISTRICT, LAT, LON, SITE_TYPE)])
wells <- merge(wells, first_yr, by = "WLCODE", all.x = TRUE)
wells[, has_may1996 := WLCODE %in% cg[!is.na(`May 1996`), WLCODE]]
wells[, has_any_may := !is.na(earliest_may_year)]
wells[, earliest_may_le_2000 := !is.na(earliest_may_year) & earliest_may_year <= 2000]
coloc_key <- cg[, .N, by = .(LAT, LON)][N > 1]
wells[, flag_colocated := paste(LAT, LON) %in% coloc_key[, paste(LAT, LON)]]
wells[, flag_blank_site_type := trimws(SITE_TYPE) == ""]

check(nrow(wells) == 28076L, "wells table: 28,076 rows")
check(sum(duplicated(wells$WLCODE)) == 0, "wells table: WLCODE unique")

# ===========================================================================
# 3d. Counts by state
# ===========================================================================
hr("3d. Counts by state")

st <- wells[, .(
  wells            = .N,
  with_any_may     = sum(has_any_may),
  with_may1996     = sum(has_may1996),
  with_may_le_2000 = sum(earliest_may_le_2000),
  median_earliest_may = as.numeric(median(earliest_may_year, na.rm = TRUE))
), by = STATE][order(-wells)]
print(st)
fwrite(st, p_build("cgwb_state_counts.csv"))
msg("")
msg("  states represented: ", nrow(st))
check(nrow(st) == 24L, "cgwb: 24 states represented")

# ===========================================================================
# 3e. Write
# ===========================================================================
hr("3e. Write outputs")

saveRDS(may,   p_build("cgwb_may_long.rds"))
saveRDS(wells, p_build("cgwb_wells.rds"))
fwrite(wells,  p_build("cgwb_wells.csv"))

msg("build/cgwb_may_long.rds : ", format(nrow(may), big.mark = ","),
    " non-missing May readings (one row per well-year)")
msg("build/cgwb_wells.rds    : ", format(nrow(wells), big.mark = ","),
    " wells (one row per WLCODE)")

hr("STEP 3 COMPLETE")
log_close()
