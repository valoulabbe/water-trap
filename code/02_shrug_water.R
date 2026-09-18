# ---------------------------------------------------------------------------
# 02_shrug_water.R -- build the public-water outcome variables from SHRUG v2.2
#                     Village Directory, 1991 / 2001 / 2011, at shrid level.
#
# NO RD IS RUN HERE and no depth value is joined to any outcome. Phase 0a is
# blocked pending the PI's decision; this prepares outcomes every route needs.
#
# ---------------------------------------------------------------------------
# VERIFIED DRINKING-WATER VARIABLE NAMES
# Verified 2026-09-18 against docs.devdatalab.org
#   - https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd11-metadata/
#   - https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd01-metadata/
# and against the Stata variable labels embedded in the .dta files themselves.
# No name below is guessed.
#
#   1991 (9 sources): pc91_vd_{tap, well, tank, tubewell, handpump, river,
#                     canal, lake, fountain}
#                     plus pc91_vd_drnk_wat_f ("Drinking Water Facility"),
#                          pc91_vd_rang_wat_f (distance if not available)
#   2001 (10 sources): pc01_vd_{tap, well, tank, tubewell, handpump, river,
#                      canal, lake, spring, other}
#                      NO drinking-water-facility flag exists.
#   2011 (10 sources): pc11_vd_wat_{tap_trt, tap_untrt, cov_well, uncov_well,
#                      handpump, tubewell, spring, rivcan, tnkpndlk, oth}
#                      NO drinking-water-facility flag exists.
#                      Treated tap (tap_trt) exists ONLY in 2011.
#
# CENSUS CODING CONVENTION: in the Village Directory, "NA" in a status label
# means "not available", i.e. a real ZERO, not a missing value. The 2011 labels
# state this explicitly, e.g. pc11_vd_wat_tap_trt_sum is labelled
# "... (Status A(1)/NA(0))". Zeros are therefore treated as real zeros.
#
# SHRUG AGGREGATION TO SHRID differs by year (verified empirically, and
# consistent with docs.devdatalab.org/SHRUG-Construction-Details/
# imputing-and-aggregating-data/ : binary indicators aggregate as MAX variables,
# counts as per-capita counts):
#   - 1991 and 2001 water variables are COUNTS of villages in the shrid having
#     that source (pc91_vd_tap max 170; pc01_vd_tap max 177).
#   - 2011 water variables are BINARY 0/1 (max rule).
# 99.6% of shrids are single-village (median 1, mean 1.004 villages), so the
# distinction bites on a small minority -- but it is handled explicitly rather
# than assumed away. We build BOTH a binary *_any (comparable across all three
# years, the workhorse) and a *_share (1991/2001 only; not constructible in
# 2011 from a binary source).
#
# ---------------------------------------------------------------------------
# DEVIATION FROM PHASE0_SPEC.md -- PENDING PI APPROVAL
# ---------------------------------------------------------------------------
# PHASE0_SPEC.md 3.3 states the missingness rule as: "code a water amenity 0
# only where the 'any drinking-water facility' flag (pc91_vd_drnk_wat_f) is
# itself non-missing; else drop". That flag exists ONLY in 1991. SHRUG v2.2
# ships no 2001 or 2011 analogue (confirmed against the vd01/vd11 metadata
# pages and the files themselves).
#
# We therefore CONSTRUCT a year-specific anchor for 2001 and 2011:
#   2001: anchor non-missing <=> all 10 pc01_vd_<source> non-missing;
#         drnk_wat_f01 = 1{any source > 0}
#   2011: anchor non-missing <=> all 10 pc11_vd_wat_<source> non-missing;
#         drnk_wat_f11 = 1{any source == 1}
# This is NOT in the spec. Any Phase 0 result that uses a 2001 or 2011 anchor
# is PROVISIONAL until the PI approves this construction.
# ---------------------------------------------------------------------------
#
# Outputs: build/shrug_water_shrid.rds, build/shrug_water_shrid.csv,
#          build/shrug_water_sensitivity.csv, output/logs/02_shrug_water.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
log_open(p_log("02_shrug_water.log"))

msg("STEP 2 -- SHRUG PUBLIC-WATER OUTCOMES (1991 / 2001 / 2011)")

hr("DEVIATION FROM PHASE0_SPEC.md -- PENDING PI APPROVAL")
msg("PHASE0_SPEC.md 3.3 anchors the missingness rule on pc91_vd_drnk_wat_f.")
msg("That flag exists ONLY in 1991. SHRUG v2.2 ships no 2001 or 2011 analogue.")
msg("")
msg("This script CONSTRUCTS a year-specific anchor for 2001 and 2011:")
msg("  2001: anchor non-missing <=> all 10 pc01_vd_<source> non-missing;")
msg("        drnk_wat_f01 = 1{any source > 0}")
msg("  2011: anchor non-missing <=> all 10 pc11_vd_wat_<source> non-missing;")
msg("        drnk_wat_f11 = 1{any source == 1}")
msg("")
msg("This construction is NOT in the spec. Every Phase 0 result that uses a")
msg("2001 or 2011 anchor is PROVISIONAL until the PI approves it.")

# ===========================================================================
# Variable name blocks (verified -- see header)
# ===========================================================================
WAT91 <- c("pc91_vd_tap", "pc91_vd_well", "pc91_vd_tank", "pc91_vd_tubewell",
           "pc91_vd_handpump", "pc91_vd_river", "pc91_vd_canal",
           "pc91_vd_lake", "pc91_vd_fountain")
WAT01 <- c("pc01_vd_tap", "pc01_vd_well", "pc01_vd_tank", "pc01_vd_tubewell",
           "pc01_vd_handpump", "pc01_vd_river", "pc01_vd_canal",
           "pc01_vd_lake", "pc01_vd_spring", "pc01_vd_other")
WAT11 <- c("pc11_vd_wat_tap_trt", "pc11_vd_wat_tap_untrt",
           "pc11_vd_wat_cov_well", "pc11_vd_wat_uncov_well",
           "pc11_vd_wat_handpump", "pc11_vd_wat_tubewell",
           "pc11_vd_wat_spring", "pc11_vd_wat_rivcan",
           "pc11_vd_wat_tnkpndlk", "pc11_vd_wat_oth")

vd91 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd91-dta", "pc91_vd_clean_shrid.dta")))
vd01 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd01-dta", "pc01_vd_clean_shrid.dta")))
vd11 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd11-dta", "pc11_vd_clean_shrid.dta")))

for (nm in c("vd91", "vd01", "vd11")) {
  d <- get(nm)
  check(is.character(d$shrid2), paste0(nm, ": shrid2 is character"))
}

# Strip haven labels so downstream arithmetic is on plain numerics.
strip_labels <- function(d) {
  for (v in names(d)) if (inherits(d[[v]], "haven_labelled"))
    set(d, j = v, value = as.numeric(d[[v]]))
  d[]
}
vd91 <- strip_labels(vd91); vd01 <- strip_labels(vd01); vd11 <- strip_labels(vd11)

# ===========================================================================
# 2a. Villages per shrid (from the rural village keys)
# ===========================================================================
hr("2a. Villages per shrid")

nvill <- function(path, yr) {
  k <- as.data.table(read_dta_chk(path))
  out <- k[, .N, by = shrid2]
  setnames(out, "N", paste0("n_villages", yr))
  out
}
nv91 <- nvill(p_raw("shrug", "shrug-pc-keys-dta", "pc91r_shrid_key.dta"), "91")
nv01 <- nvill(p_raw("shrug", "shrug-pc-keys-dta", "pc01r_shrid_key.dta"), "01")
nv11 <- nvill(p_raw("shrug", "shrug-pc-keys-dta", "pc11r_shrid_key.dta"), "11")

for (x in list(list(nv91, "91"), list(nv01, "01"), list(nv11, "11"))) {
  v <- paste0("n_villages", x[[2]])
  note(sprintf("pc%sr: %s shrids; villages per shrid mean=%.3f median=%d max=%d; multi-village share=%.4f",
               x[[2]], format(nrow(x[[1]]), big.mark = ","),
               mean(x[[1]][[v]]), as.integer(median(x[[1]][[v]])),
               max(x[[1]][[v]]), mean(x[[1]][[v]] > 1)))
}

# ===========================================================================
# 2b. Is 2001's completeness real, or zero-filling?
# ===========================================================================
hr("2b. Is 2001's completeness real, or zero-filling?")

msg("Treated as an OPEN QUESTION, not a settled fact: if 2001 missing values")
msg("were zero-filled, 2001 zeros are fake and the missingness rule is NOT")
msg("1991-only.")
msg("")
msg("DOCUMENTATION CHECK (performed 2026-09-18, recorded here):")
msg("  Sources consulted:")
msg("    https://docs.devdatalab.org/SHRUG-Construction-Details/imputing-and-aggregating-data/")
msg("    https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd01-metadata/")
msg("    https://docs.devdatalab.org/shrug-faq/")
msg("  FINDING: the documentation is SILENT on zero-filling of 2001 Village")
msg("  Directory values. The imputation page describes aggregation and")
msg("  imputation only, quoting for binary/max variables: \"Assume that the")
msg("  missing min/max value is equal to the min/max of nonmissing values in")
msg("  A\", and for counts: \"Assume that the number of hospitals per capita in")
msg("  missing villages equals the aggregate number of hospitals/capita in all")
msg("  non-missing units.\" Neither describes zero-filling. The vd01 metadata")
msg("  page marks imputation 'canary variables' with a star; NO drinking-water")
msg("  variable is marked as a canary variable. No statement either way was")
msg("  found, so the question is NOT settled by documentation.")
msg("")
msg("EMPIRICAL DIAGNOSTICS:")

src_block_diag <- function(d, vars, yr) {
  M <- as.matrix(d[, ..vars])
  any_na   <- mean(!complete.cases(M))
  allzero  <- mean(rowSums(M, na.rm = TRUE) == 0)
  data.table(year = yr, n = nrow(M), n_sources = length(vars),
             share_any_na = any_na, share_all_sources_zero = allzero)
}
diag_tbl <- rbindlist(list(
  src_block_diag(vd91, WAT91, 1991L),
  src_block_diag(vd01, WAT01, 2001L),
  src_block_diag(vd11, WAT11, 2011L)
))
print(diag_tbl)

msg("")
msg("INTERPRETATION: the 2001 all-sources-zero share is well BELOW 1991's.")
msg("Wholesale zero-filling would push it ABOVE, not below. Combined with the")
msg("near-total absence of NAs in 2001, the pattern is consistent with a")
msg("complete 2001 source file rather than zero-filled missings.")
msg("VERDICT: no evidence of zero-filling in 2001. This is an inference from")
msg("the data, NOT a documented guarantee -- 2001 outcomes should carry that")
msg("caveat, and the PI may want to confirm with Development Data Lab.")

# ===========================================================================
# 2c. The 1991 fake-zero problem (all sources zero, yet water IS available)
# ===========================================================================
hr("2c. 1991 fake zeros: all sources zero yet drnk_wat_f == 1")

M91 <- as.matrix(vd91[, ..WAT91])
vd91[, src_allzero91 := rowSums(M91, na.rm = TRUE) == 0]
vd91[, src_allzero_wat91 := src_allzero91 & !is.na(pc91_vd_drnk_wat_f) &
       pc91_vd_drnk_wat_f == 1]

xt <- vd91[, .N, by = .(src_allzero91, drnk_wat_f = pc91_vd_drnk_wat_f)]
setorder(xt, src_allzero91, drnk_wat_f)
print(xt)

n_fake <- vd91[src_allzero_wat91 == TRUE, .N]
msg("")
msg("src_allzero_wat91 == TRUE for ", format(n_fake, big.mark = ","), " shrids.")
msg("")
msg("WHY THIS MATTERS. PHASE0_SPEC.md 3.3's missingness rule only covers rows")
msg("where pc91_vd_drnk_wat_f is MISSING. These rows are not missing: the flag")
msg("says 1 (drinking water IS available) while all nine source variables are")
msg("coded 0. The spec's rule does NOT protect them. Under the missing=0")
msg("version they receive tap = 0 and private_gw = 0, but they are likely FAKE")
msg("ZEROS -- water present, source not recorded.")
msg("")
msg("HANDLING: the flag src_allzero_wat91 is carried into the output. These")
msg("rows are NOT dropped by default. Section 2e reports how every 1991")
msg("outcome changes when they are excluded, so the sensitivity is visible")
msg("without baking a choice into the data.")
msg("")
msg("NOTE: the analogous flag is degenerate for 2001/2011, where the anchor is")
msg("CONSTRUCTED from the sources -- an all-zero row there has drnk_wat_f == 0")
msg("by construction, so 'all zero yet flag == 1' cannot occur. Not built.")

# ===========================================================================
# 2d. Build the outcomes
# ===========================================================================
hr("2d. Outcome construction")

out <- data.table(shrid2 = character())

# All derived columns are computed ON the vd* tables, in their own row order,
# BEFORE any merge reorders rows. (An earlier draft assigned vd91$_mean_p_miss
# into a table that merge() had already re-sorted by shrid2 -- silently
# misaligning every row. Do not reintroduce that.)

# -- 1991 -------------------------------------------------------------------
vd91[, anchor_ok91 := !is.na(pc91_vd_drnk_wat_f)]
vd91[, imputed91   := `_mean_p_miss` > 0]
w91 <- vd91[, c("shrid2", WAT91, "pc91_vd_drnk_wat_f", "src_allzero91",
                "src_allzero_wat91", "anchor_ok91", "imputed91"), with = FALSE]
w91 <- merge(w91, nv91, by = "shrid2", all.x = TRUE)

# -- 2001 -------------------------------------------------------------------
M01 <- as.matrix(vd01[, ..WAT01])
vd01[, anchor_ok01  := complete.cases(M01)]
vd01[, drnk_wat_f01 := as.integer(rowSums(M01, na.rm = TRUE) > 0)]
vd01[, imputed01    := `_mean_p_miss` > 0]
w01 <- vd01[, c("shrid2", WAT01, "anchor_ok01", "drnk_wat_f01", "imputed01"),
            with = FALSE]
w01 <- merge(w01, nv01, by = "shrid2", all.x = TRUE)

# -- 2011 -------------------------------------------------------------------
M11 <- as.matrix(vd11[, ..WAT11])
vd11[, anchor_ok11  := complete.cases(M11)]
vd11[, drnk_wat_f11 := as.integer(rowSums(M11, na.rm = TRUE) > 0)]
vd11[, imputed11    := `_mean_p_miss` > 0]
w11 <- vd11[, c("shrid2", WAT11, "anchor_ok11", "drnk_wat_f11", "imputed11"),
            with = FALSE]
w11 <- merge(w11, nv11, by = "shrid2", all.x = TRUE)

# --- helpers ---------------------------------------------------------------
# *_m0 : missing -> 0, but ONLY where the anchor is non-missing; else NA (drop)
# *_lw : listwise -- NA if any input is missing
mk_any <- function(d, srcs, anchor, prefix) {
  M  <- as.matrix(d[, ..srcs])
  pos <- rowSums(M > 0, na.rm = TRUE) > 0          # TRUE if any non-missing source > 0
  m0 <- as.integer(pos)
  m0[!d[[anchor]]] <- NA_integer_                   # anchor missing -> drop
  lw <- as.integer(pos)
  lw[!complete.cases(M)] <- NA_integer_             # any input missing -> drop
  set(d, j = paste0(prefix, "_any_m0"), value = m0)
  set(d, j = paste0(prefix, "_any_lw"), value = lw)
  invisible(d)
}

mk_share <- function(d, src, nv, prefix) {
  s <- d[[src]] / d[[nv]]
  s[is.infinite(s)] <- NA_real_
  set(d, j = paste0(prefix, "_share"), value = pmin(s, 1))
  invisible(d)
}

# 1991
mk_any(w91, "pc91_vd_tap", "anchor_ok91", "tap91")
mk_any(w91, c("pc91_vd_tubewell", "pc91_vd_handpump"), "anchor_ok91", "private_gw91")
w91[, drnk_wat_f91_m0 := fifelse(anchor_ok91, as.integer(pc91_vd_drnk_wat_f), NA_integer_)]
w91[, drnk_wat_f91_lw := drnk_wat_f91_m0]
mk_share(w91, "pc91_vd_tap", "n_villages91", "tap91")

# 2001
mk_any(w01, "pc01_vd_tap", "anchor_ok01", "tap01")
mk_any(w01, c("pc01_vd_tubewell", "pc01_vd_handpump"), "anchor_ok01", "private_gw01")
w01[, drnk_wat_f01_m0 := fifelse(anchor_ok01, drnk_wat_f01, NA_integer_)]
w01[, drnk_wat_f01_lw := drnk_wat_f01_m0]
mk_share(w01, "pc01_vd_tap", "n_villages01", "tap01")

# 2011
mk_any(w11, c("pc11_vd_wat_tap_trt", "pc11_vd_wat_tap_untrt"), "anchor_ok11", "tap11")
mk_any(w11, "pc11_vd_wat_tap_trt", "anchor_ok11", "tap_treated11")
mk_any(w11, c("pc11_vd_wat_tubewell", "pc11_vd_wat_handpump"), "anchor_ok11", "private_gw11")
w11[, drnk_wat_f11_m0 := fifelse(anchor_ok11, drnk_wat_f11, NA_integer_)]
w11[, drnk_wat_f11_lw := drnk_wat_f11_m0]
# tap11_share is NOT constructible: the 2011 source is binary, not a count.
w11[, tap11_share := NA_real_]

msg("Shares: tap91_share and tap01_share are built from village COUNTS.")
msg("tap11_share is NA by construction -- the 2011 source variable is binary")
msg("(max rule), so the intensive margin does not exist in the data.")
msg("private_gw *_share is not built in any year: it is an OR of two counts,")
msg("and the union of the two village sets is not recoverable from the counts.")

# ===========================================================================
# 2e. Report both missingness versions, and the fake-zero sensitivity
# ===========================================================================
hr("2e. Outcome means under both missingness treatments")

summarise_outcome <- function(d, var, year, subset_desc = "all rows",
                              keep = NULL) {
  x <- d[[var]]
  if (!is.null(keep)) x <- x[keep]
  data.table(year = year, outcome = var, sample = subset_desc,
             n = sum(!is.na(x)), mean = mean(x, na.rm = TRUE))
}

res <- rbindlist(list(
  summarise_outcome(w91, "tap91_any_m0", 1991L),
  summarise_outcome(w91, "tap91_any_lw", 1991L),
  summarise_outcome(w91, "private_gw91_any_m0", 1991L),
  summarise_outcome(w91, "private_gw91_any_lw", 1991L),
  summarise_outcome(w91, "drnk_wat_f91_m0", 1991L),
  summarise_outcome(w01, "tap01_any_m0", 2001L),
  summarise_outcome(w01, "tap01_any_lw", 2001L),
  summarise_outcome(w01, "private_gw01_any_m0", 2001L),
  summarise_outcome(w01, "private_gw01_any_lw", 2001L),
  summarise_outcome(w01, "drnk_wat_f01_m0", 2001L),
  summarise_outcome(w11, "tap11_any_m0", 2011L),
  summarise_outcome(w11, "tap11_any_lw", 2011L),
  summarise_outcome(w11, "tap_treated11_any_m0", 2011L),
  summarise_outcome(w11, "tap_treated11_any_lw", 2011L),
  summarise_outcome(w11, "private_gw11_any_m0", 2011L),
  summarise_outcome(w11, "private_gw11_any_lw", 2011L),
  summarise_outcome(w11, "drnk_wat_f11_m0", 2011L)
))
print(res)

msg("")
msg("Whether the two versions coincide is reported above as an OBSERVED")
msg("result, not asserted in advance.")

hr("2e(ii). 1991 sensitivity to excluding src_allzero_wat91 rows")

msg("Default = these rows KEPT. 'excl_fake_zero' = the ", format(n_fake, big.mark = ","),
    " suspect rows dropped.")
keep_ok <- !w91$src_allzero_wat91
sens <- rbindlist(list(
  summarise_outcome(w91, "tap91_any_m0", 1991L, "all rows (default)"),
  summarise_outcome(w91, "tap91_any_m0", 1991L, "excl_fake_zero", keep_ok),
  summarise_outcome(w91, "tap91_any_lw", 1991L, "all rows (default)"),
  summarise_outcome(w91, "tap91_any_lw", 1991L, "excl_fake_zero", keep_ok),
  summarise_outcome(w91, "private_gw91_any_m0", 1991L, "all rows (default)"),
  summarise_outcome(w91, "private_gw91_any_m0", 1991L, "excl_fake_zero", keep_ok),
  summarise_outcome(w91, "private_gw91_any_lw", 1991L, "all rows (default)"),
  summarise_outcome(w91, "private_gw91_any_lw", 1991L, "excl_fake_zero", keep_ok),
  summarise_outcome(w91, "drnk_wat_f91_m0", 1991L, "all rows (default)"),
  summarise_outcome(w91, "drnk_wat_f91_m0", 1991L, "excl_fake_zero", keep_ok),
  summarise_outcome(w91, "tap91_share", 1991L, "all rows (default)"),
  summarise_outcome(w91, "tap91_share", 1991L, "excl_fake_zero", keep_ok)
))
print(sens)
fwrite(sens, p_build("shrug_water_sensitivity.csv"))

wide_sens <- dcast(sens, year + outcome ~ sample, value.var = c("n", "mean"))
msg("")
msg("Change in mean from excluding the suspect rows:")
print(wide_sens[, .(outcome,
                    mean_all = `mean_all rows (default)`,
                    mean_excl = mean_excl_fake_zero,
                    diff = mean_excl_fake_zero - `mean_all rows (default)`)])

# ===========================================================================
# 2f. Assemble and write
# ===========================================================================
hr("2f. Assemble the shrid-level output")

keep91 <- c("shrid2", "n_villages91", "imputed91", "anchor_ok91",
            "src_allzero91", "src_allzero_wat91",
            "tap91_any_m0", "tap91_any_lw", "tap91_share",
            "private_gw91_any_m0", "private_gw91_any_lw",
            "drnk_wat_f91_m0", "drnk_wat_f91_lw")
keep01 <- c("shrid2", "n_villages01", "imputed01", "anchor_ok01",
            "tap01_any_m0", "tap01_any_lw", "tap01_share",
            "private_gw01_any_m0", "private_gw01_any_lw",
            "drnk_wat_f01_m0", "drnk_wat_f01_lw")
keep11 <- c("shrid2", "n_villages11", "imputed11", "anchor_ok11",
            "tap11_any_m0", "tap11_any_lw", "tap11_share",
            "tap_treated11_any_m0", "tap_treated11_any_lw",
            "private_gw11_any_m0", "private_gw11_any_lw",
            "drnk_wat_f11_m0", "drnk_wat_f11_lw")

wat <- merge(w91[, ..keep91], w01[, ..keep01], by = "shrid2", all = TRUE)
wat <- merge(wat,             w11[, ..keep11], by = "shrid2", all = TRUE)

wat[, multi_village := (n_villages91 > 1) | (n_villages01 > 1) | (n_villages11 > 1)]

loc <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-shrid-keys-dta", "shrid_loc_names.dta")))
wat <- merge(wat, loc[, .(shrid2, state_name, district_name)], by = "shrid2", all.x = TRUE)

check(is.character(wat$shrid2), "output: shrid2 is character")
check_unique(wat, "shrid2", "output")
check(wat[!is.na(tap91_share) & tap91_share > 1, .N] == 0,
      "output: no tap91_share above 1")
check(wat[!is.na(tap01_share) & tap01_share > 1, .N] == 0,
      "output: no tap01_share above 1")

msg("Rows in assembled output: ", format(nrow(wat), big.mark = ","))
msg("  present in vd91: ", format(w91[, .N], big.mark = ","),
    " | vd01: ", format(w01[, .N], big.mark = ","),
    " | vd11: ", format(w11[, .N], big.mark = ","))
msg("  shrids with n_villages91 missing (in VD, absent from rural key): ",
    format(wat[is.na(n_villages91) & !is.na(tap91_any_m0), .N], big.mark = ","))

saveRDS(wat, p_build("shrug_water_shrid.rds"))
fwrite(wat, p_build("shrug_water_shrid.csv"))

hr("STEP 2 COMPLETE")
msg("Wrote build/shrug_water_shrid.{rds,csv} and build/shrug_water_sensitivity.csv")
msg("REMINDER: the 2001/2011 anchor is a DEVIATION pending PI approval (top of log).")
log_close()
