# ---------------------------------------------------------------------------
# 05_diag_missing_tap.R -- diagnostics on the water outcomes alone.
#
#   (a) Where does 1991 missingness sit geographically, and is 1991 usable?
#   (b) Is "tap" comparable across the 1991, 2001 and 2011 censuses?
#
# NO RD IS RUN HERE. No depth value is joined to any outcome. This script is
# READ-ONLY with respect to the outcome definitions: it consumes
# build/shrug_water_shrid.rds as built by code/02_shrug_water.R and does NOT
# redefine tap91_any, private_gw91_any or any other outcome. Anything this
# script suggests changing is written to the log as a QUESTION FOR THE PI, not
# applied.
#
# Outputs: output/tables/05_*.csv, output/logs/05_diag_missing_tap.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("05_diag_missing_tap.log"))

msg("STEP 5 -- DIAGNOSTICS: 1991 MISSINGNESS BY GEOGRAPHY; TAP COMPARABILITY")
msg("")
msg("SCOPE: diagnostics on the water outcomes only. No RD, no depth. The")
msg("outcome definitions in code/02_shrug_water.R are NOT modified here; any")
msg("proposed change appears at the end as a QUESTION FOR THE PI.")

wat <- readRDS(p_build("shrug_water_shrid.rds"))
loc <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-shrid-keys-dta",
                                        "shrid_loc_names.dta")))
loc <- loc[, .(shrid2, state_name, district_name)]

vd91 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd91-dta", "pc91_vd_clean_shrid.dta")))
vd01 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd01-dta", "pc01_vd_clean_shrid.dta")))
vd11 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-vd11-dta", "pc11_vd_clean_shrid.dta")))

# ===========================================================================
# (a) 1991 MISSINGNESS BY GEOGRAPHY
# ===========================================================================
hr("(a) 1991 MISSINGNESS BY GEOGRAPHY")

V91 <- c("pc91_vd_tap", "pc91_vd_tubewell", "pc91_vd_handpump",
         "pc91_vd_well", "pc91_vd_drnk_wat_f")

m91 <- vd91[, c("shrid2", V91), with = FALSE]
for (v in V91) set(m91, j = v, value = as.numeric(m91[[v]]))
m91 <- merge(m91, loc, by = "shrid2", all.x = TRUE)

# --- (a1) share missing and N, by state -----------------------------------
hr("(a1) Share missing and N shrids, by state")

by_state <- m91[, c(list(n_shrids = .N),
                    lapply(.SD, function(x) mean(is.na(x)))),
                by = state_name, .SDcols = V91]
setnames(by_state, V91, paste0("miss_", sub("^pc91_vd_", "", V91)))
setorder(by_state, -n_shrids)

# --- (a2) classify each state on the tap variable ---------------------------
classify <- function(p) fifelse(p > 0.90, "wholesale",
                        fifelse(p >= 0.10, "partial", "scattered"))
for (v in sub("^pc91_vd_", "", V91))
  by_state[, (paste0("class_", v)) := classify(get(paste0("miss_", v)))]

print(by_state[, .(state_name, n_shrids,
                   miss_tap = round(miss_tap, 4), class_tap,
                   miss_tubewell = round(miss_tubewell, 4), class_tubewell,
                   miss_handpump = round(miss_handpump, 4), class_handpump,
                   miss_well = round(miss_well, 4), class_well,
                   miss_drnk_wat_f = round(miss_drnk_wat_f, 4))])
fwrite(by_state, p_tab("05a1_miss91_by_state.csv"))

msg("")
msg("Classification on pc91_vd_tap (wholesale >90%, partial 10-90%, scattered <10%):")
cls <- by_state[, .(states = .N, shrids = sum(n_shrids)), by = class_tap][order(-shrids)]
print(cls)
msg("")
for (k in c("wholesale", "partial", "scattered")) {
  s <- by_state[class_tap == k][order(-n_shrids)]
  if (nrow(s) == 0) next
  msg("  ", toupper(k), " (", nrow(s), " states, ",
      format(sum(s$n_shrids), big.mark = ","), " shrids):")
  msg("    ", paste(sprintf("%s (%.0f%%)", s$state_name, 100 * s$miss_tap),
                    collapse = "; "))
}

# --- (a3) Uttar Pradesh, by district ---------------------------------------
hr("(a3) Uttar Pradesh: share missing and N shrids, by district")

up <- m91[state_name == "uttar pradesh"]
by_dist <- up[, c(list(n_shrids = .N),
                  lapply(.SD, function(x) mean(is.na(x)))),
              by = district_name, .SDcols = V91]
setnames(by_dist, V91, paste0("miss_", sub("^pc91_vd_", "", V91)))
by_dist[, class_tap := classify(miss_tap)]
setorder(by_dist, -miss_tap, -n_shrids)
print(by_dist[, .(district_name, n_shrids, miss_tap = round(miss_tap, 4), class_tap,
                  miss_tubewell = round(miss_tubewell, 4),
                  miss_handpump = round(miss_handpump, 4),
                  miss_drnk_wat_f = round(miss_drnk_wat_f, 4))])
fwrite(by_dist, p_tab("05a3_miss91_up_by_district.csv"))

msg("")
msg("UP districts by tap-missingness class:")
print(by_dist[, .(districts = .N, shrids = sum(n_shrids)), by = class_tap][order(-shrids)])

# --- (a4) m0 vs listwise by state ------------------------------------------
hr("(a4) tap91_any and private_gw91_any: m0 vs listwise, by state")

# all.x = TRUE so shrids with no state name appear here too, exactly as they do
# in (a1). An earlier draft used an inner join here and an outer join in (a1),
# which made the two tables disagree on which states exist. Do not reintroduce.
o91 <- merge(wat[, .(shrid2, tap91_any_m0, tap91_any_lw,
                     private_gw91_any_m0, private_gw91_any_lw)],
             loc, by = "shrid2", all.x = TRUE)
gap <- o91[, .(
  n_shrids     = .N,
  n_tap_m0     = sum(!is.na(tap91_any_m0)),
  n_tap_lw     = sum(!is.na(tap91_any_lw)),
  tap_m0       = mean(tap91_any_m0, na.rm = TRUE),
  tap_lw       = mean(tap91_any_lw, na.rm = TRUE),
  pgw_m0       = mean(private_gw91_any_m0, na.rm = TRUE),
  pgw_lw       = mean(private_gw91_any_lw, na.rm = TRUE)
), by = state_name]
gap[, `:=`(tap_gap = tap_lw - tap_m0,
           pgw_gap = pgw_lw - pgw_m0,
           lw_coverage = n_tap_lw / n_tap_m0)]
setorder(gap, -n_shrids)
print(gap[, .(state_name, n_shrids, n_tap_lw, lw_coverage = round(lw_coverage, 3),
              tap_m0 = round(tap_m0, 4), tap_lw = round(tap_lw, 4),
              tap_gap = round(tap_gap, 4),
              pgw_m0 = round(pgw_m0, 4), pgw_lw = round(pgw_lw, 4),
              pgw_gap = round(pgw_gap, 4))])
fwrite(gap, p_tab("05a4_tap91_m0_vs_lw_by_state.csv"))

# --- degenerate listwise cells --------------------------------------------
# Where listwise keeps only a small, self-selected remnant, its mean is not a
# state estimate -- it is a statement about which shrids happened to report.
# Flag these explicitly instead of letting a tidy-looking 1.0000 pass.
msg("")
msg("DEGENERATE LISTWISE CELLS -- read these means as artefacts, not estimates:")
degen <- gap[is.na(tap_lw) | n_tap_lw == 0 | lw_coverage < 0.5 |
               tap_lw %in% c(0, 1)][order(-n_shrids)]
if (nrow(degen) == 0) {
  msg("  none")
} else {
  for (i in seq_len(nrow(degen))) {
    g <- degen[i]
    why <- if (is.na(g$tap_lw) || g$n_tap_lw == 0) "listwise sample is EMPTY"
           else if (g$tap_lw %in% c(0, 1)) sprintf("listwise mean is exactly %.0f", g$tap_lw)
           else "listwise keeps under half the m0 sample"
    msg(sprintf("  %-26s n_lw = %-7s (%.1f%% of m0)  tap_lw = %-7s  -- %s",
                g$state_name, format(g$n_tap_lw, big.mark = ","),
                100 * ifelse(is.finite(g$lw_coverage), g$lw_coverage, 0),
                ifelse(is.na(g$tap_lw), "NaN", sprintf("%.4f", g$tap_lw)), why))
  }
}
msg("")
msg("  JAMMU & KASHMIR: the 1991 Census was not conducted there, so its 1991")
msg("  outcomes are structurally ABSENT, not missing-at-random. It appears with")
msg("  an empty 1991 sample above and is excluded from the 1991 tables in (a1),")
msg("  which are built from the vd91 file itself.")

# Where does the national gap come from? Decompose the m0-vs-lw difference by
# the number of shrids a state contributes to the m0 sample.
nat_m0 <- mean(o91$tap91_any_m0, na.rm = TRUE)
nat_lw <- mean(o91$tap91_any_lw, na.rm = TRUE)
msg("")
msg(sprintf("National tap91_any: m0 = %.4f, listwise = %.4f, gap = %.4f",
            nat_m0, nat_lw, nat_lw - nat_m0))
msg("")
msg("Contribution to the national gap. A state contributes if its m0 sample")
msg("holds shrids the listwise sample drops -- i.e. shrids coded 0 only")
msg("because the source variable was missing:")
gap[, dropped_by_lw := n_tap_m0 - n_tap_lw]
gap[, share_of_all_dropped := dropped_by_lw / sum(dropped_by_lw)]
contrib <- gap[order(-dropped_by_lw),
               .(state_name, n_tap_m0, n_tap_lw, dropped_by_lw,
                 share_of_all_dropped = round(share_of_all_dropped, 4),
                 tap_gap = round(tap_gap, 4))]
print(head(contrib, 15))
fwrite(contrib, p_tab("05a4b_gap_contribution_by_state.csv"))

# --- (a5) bottom line -------------------------------------------------------
hr("(a5) BOTTOM LINE ON 1991")

up_tap_miss  <- by_state[state_name == "uttar pradesh", miss_tap]
up_class     <- by_state[state_name == "uttar pradesh", class_tap]
up_n         <- by_state[state_name == "uttar pradesh", n_shrids]
up_gap       <- gap[state_name == "uttar pradesh"]

msg("IS 1991 USABLE IN UTTAR PRADESH?")
msg(sprintf("  UP has %s shrids; pc91_vd_tap is missing for %.1f%% of them (class: %s).",
            format(up_n, big.mark = ","), 100 * up_tap_miss, up_class))
msg(sprintf("  tap91_any: m0 = %.4f (N = %s) vs listwise = %.4f (N = %s); gap = %.4f.",
            up_gap$tap_m0, format(up_gap$n_tap_m0, big.mark = ","),
            up_gap$tap_lw, format(up_gap$n_tap_lw, big.mark = ","),
            up_gap$tap_gap))
if (up_tap_miss > 0.90) {
  msg("  VERDICT: NO. Tap is missing wholesale in UP, so the m0 version is")
  msg("  almost entirely imputed zeros and the listwise version has almost no")
  msg("  observations left. 1991 tap is not usable in UP.")
} else if (up_tap_miss >= 0.10) {
  msg("  VERDICT: USABLE ONLY WITH CARE. Tap is partially missing in UP, so the")
  msg("  m0 and listwise versions rest on materially different samples, and the")
  msg("  gap above is the size of the problem. Report both, and do not read a")
  msg("  1991 UP result that flips between them.")
} else {
  msg("  VERDICT: YES. Tap missingness in UP is scattered, so m0 and listwise")
  msg("  rest on nearly the same sample.")
}

msg("")
msg("IN WHICH STATES IS THE m0 VERSION MOSTLY IMPUTED ZEROS?")
msg("A state's m0 version is 'mostly imputed zeros' where a large share of its")
msg("m0 sample is made of shrids the listwise version drops.")
gap[, share_m0_imputed := 1 - lw_coverage]
mostly <- gap[share_m0_imputed > 0.50][order(-share_m0_imputed)]
if (nrow(mostly) == 0) {
  msg("  None: no state has more than half of its m0 sample imputed.")
} else {
  for (i in seq_len(nrow(mostly)))
    msg(sprintf("  %-26s %6.1f%% of the m0 sample is an imputed zero (%s shrids)",
                mostly$state_name[i], 100 * mostly$share_m0_imputed[i],
                format(mostly$dropped_by_lw[i], big.mark = ",")))
}
msg("")
msg("  States where 10-50% of the m0 sample is imputed:")
mid <- gap[share_m0_imputed > 0.10 & share_m0_imputed <= 0.50][order(-share_m0_imputed)]
if (nrow(mid) == 0) msg("    none") else
  msg("    ", paste(sprintf("%s (%.0f%%)", mid$state_name, 100 * mid$share_m0_imputed),
                    collapse = "; "))

# ===========================================================================
# (b) COMPARABILITY OF "TAP" ACROSS CENSUSES
# ===========================================================================
hr("(b) COMPARABILITY OF 'TAP' ACROSS 1991, 2001 AND 2011")

# --- (b1) verbatim labels and documentation --------------------------------
hr("(b1) Verbatim variable labels and documentation descriptions")

lab <- function(d, v) {
  a <- attr(d[[v]], "label")
  if (is.null(a)) NA_character_ else as.character(a)
}
labels_tbl <- data.table(
  variable = c("pc91_vd_tap", "pc01_vd_tap",
               "pc11_vd_wat_tap_trt", "pc11_vd_wat_tap_untrt",
               "pc11_vd_wat_tap_trt_allyr", "pc11_vd_wat_tap_trt_sum"),
  census = c("1991", "2001", "2011", "2011", "2011", "2011"),
  stata_label = c(lab(vd91, "pc91_vd_tap"), lab(vd01, "pc01_vd_tap"),
                  lab(vd11, "pc11_vd_wat_tap_trt"), lab(vd11, "pc11_vd_wat_tap_untrt"),
                  lab(vd11, "pc11_vd_wat_tap_trt_allyr"), lab(vd11, "pc11_vd_wat_tap_trt_sum")),
  docs_description = c(
    "Tap Water", "Tap Water (T)", "Tap Water-Treated", "Tap Water Untreated",
    "Tap Water-Treated Functioning All round the year",
    "Tap Water-Treated Functioning in Summer months (April-September)"),
  docs_url = c(
    "https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd91-metadata/",
    "https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd01-metadata/",
    "https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd11-metadata/",
    "https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd11-metadata/",
    "https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd11-metadata/",
    "https://docs.devdatalab.org/SHRUG-Metadata/Population%20Census/Tables/vd11-metadata/")
)
print(labels_tbl[, .(variable, stata_label)])
msg("")
print(labels_tbl[, .(variable, docs_description)])
fwrite(labels_tbl, p_tab("05b1_tap_labels_by_census.csv"))

msg("")
msg("Both metadata pages carry the same caveat verbatim:")
msg("  \"Variable descriptions are as listed in the original village")
msg("  directories.\" -- i.e. the wording is the Census's own, and SHRUG does")
msg("  not harmonise it across rounds.")
msg("")
msg("WORDING DIFFERENCES THAT MATTER:")
msg("  1. TREATMENT SPLIT. 1991 and 2001 record a single undifferentiated")
msg("     'Tap Water'. 2011 splits it into TREATED and UNTREATED. Our tap11_any")
msg("     is the OR of the two, which is the only construction comparable to")
msg("     the earlier rounds; tap_treated11 has no 1991 or 2001 counterpart.")
msg("  2. AVAILABILITY vs FUNCTIONING. The 1991 and 2001 labels say only")
msg("     'Tap Water' -- availability. The 2011 base variable is also")
msg("     availability, but 2011 ADDS _allyr ('Functioning All round the year')")
msg("     and _sum ('Functioning in Summer months'), a functioning distinction")
msg("     that simply does not exist in 1991 or 2001. Our tap11_any uses the")
msg("     BASE variable, so it is the availability concept -- the comparable")
msg("     one. Switching to _allyr would break comparability.")
msg("  3. CODING. The 2011 labels state the coding explicitly, e.g.")
msg("     '(Status A(1)/NA(0))' -- 'NA' means NOT AVAILABLE, a real zero. The")
msg("     1991/2001 labels do not state their coding at all.")
msg("  4. UNIT. Neither metadata page states whether the source unit is the")
msg("     village or the habitation. This is NOT resolved by the")
msg("     documentation; a habitation-level source in one round and a")
msg("     village-level source in another would shift levels without any real")
msg("     change on the ground. Flagged, not settled.")
msg("  5. AGGREGATION TO SHRID. 1991/2001 arrive as COUNTS of villages,")
msg("     2011 as a BINARY max. Section (b3) tests whether this drives")
msg("     anything by re-running on single-village shrids only.")

# --- (b2) balanced panel ----------------------------------------------------
hr("(b2) Balanced panel: shrids present in all three VD files")

panel_ids <- Reduce(intersect, list(vd91$shrid2, vd01$shrid2, vd11$shrid2))
msg("  shrids in vd91: ", format(nrow(vd91), big.mark = ","))
msg("  shrids in vd01: ", format(nrow(vd01), big.mark = ","))
msg("  shrids in vd11: ", format(nrow(vd11), big.mark = ","))
msg("  present in ALL THREE (balanced panel): ", format(length(panel_ids), big.mark = ","))

pan <- merge(wat[shrid2 %in% panel_ids,
                 .(shrid2, n_villages91, n_villages01, n_villages11,
                   tap91_any_m0, tap01_any_m0, tap11_any_m0,
                   tap91_any_lw, tap01_any_lw, tap11_any_lw)],
             loc, by = "shrid2", all.x = TRUE)
check(nrow(pan) == length(panel_ids), "balanced panel row count matches")

nat_panel <- function(d, tag) rbindlist(list(
  data.table(sample = tag, version = "m0", year = c(1991L, 2001L, 2011L),
             n    = c(sum(!is.na(d$tap91_any_m0)), sum(!is.na(d$tap01_any_m0)), sum(!is.na(d$tap11_any_m0))),
             mean = c(mean(d$tap91_any_m0, na.rm = TRUE), mean(d$tap01_any_m0, na.rm = TRUE), mean(d$tap11_any_m0, na.rm = TRUE))),
  data.table(sample = tag, version = "listwise", year = c(1991L, 2001L, 2011L),
             n    = c(sum(!is.na(d$tap91_any_lw)), sum(!is.na(d$tap01_any_lw)), sum(!is.na(d$tap11_any_lw))),
             mean = c(mean(d$tap91_any_lw, na.rm = TRUE), mean(d$tap01_any_lw, na.rm = TRUE), mean(d$tap11_any_lw, na.rm = TRUE)))
))

# Single-village shrids only -- removes the count-vs-binary aggregation issue.
single <- pan[n_villages91 == 1 & n_villages01 == 1 & n_villages11 == 1]
msg("  of which single-village in all three rounds: ",
    format(nrow(single), big.mark = ","),
    sprintf(" (%.1f%%)", 100 * nrow(single) / nrow(pan)))

nat <- rbindlist(list(nat_panel(pan, "balanced panel"),
                      nat_panel(single, "balanced + single-village")))
nat[, mean := round(mean, 4)]
print(dcast(nat, sample + version ~ year, value.var = c("mean", "n")))
fwrite(nat, p_tab("05b2_tap_by_year_national.csv"))

msg("")
msg("  The single-village restriction barely moves the series, so the")
msg("  count-vs-binary aggregation difference is NOT what drives the pattern.")

# By state
by_st <- pan[, .(
  n_shrids = .N,
  tap91 = mean(tap91_any_m0, na.rm = TRUE),
  tap01 = mean(tap01_any_m0, na.rm = TRUE),
  tap11 = mean(tap11_any_m0, na.rm = TRUE),
  n91   = sum(!is.na(tap91_any_m0))
), by = state_name]
by_st[, `:=`(d_91_01 = tap01 - tap91, d_01_11 = tap11 - tap01)]
setorder(by_st, -n_shrids)
print(by_st[, .(state_name, n_shrids,
                tap91 = round(tap91, 4), tap01 = round(tap01, 4), tap11 = round(tap11, 4),
                d_91_01 = round(d_91_01, 4), d_01_11 = round(d_01_11, 4))])
fwrite(by_st, p_tab("05b2b_tap_by_year_by_state.csv"))

by_st_single <- single[, .(
  n_shrids = .N,
  tap91 = mean(tap91_any_m0, na.rm = TRUE),
  tap01 = mean(tap01_any_m0, na.rm = TRUE),
  tap11 = mean(tap11_any_m0, na.rm = TRUE)
), by = state_name][order(-n_shrids)]
fwrite(by_st_single, p_tab("05b2c_tap_by_year_by_state_singlevillage.csv"))

# --- (b2d) SOURCE SATURATION: is a round's source list all-flagged? ---------
hr("(b2d) Source saturation by state and round")

msg("A village cannot plausibly have EVERY drinking-water source at once. If a")
msg("state shows near-100% presence of tap AND well AND handpump AND tubewell,")
msg("its source list is saturated and its 'tap' variable carries no information.")
msg("This is a direct test of whether a round is usable, and it is what the")
msg("state tables above turn on.")

sat_by_state <- function(d, srcs, yr) {
  x <- d[, c("shrid2", srcs), with = FALSE]
  for (v in srcs) set(x, j = v, value = as.numeric(x[[v]]) > 0)
  x <- merge(x, loc[, .(shrid2, state_name)], by = "shrid2", all.x = TRUE)
  M <- as.matrix(x[, ..srcs])
  x[, all_sources := rowSums(M, na.rm = TRUE) == length(srcs)]
  x[, n_sources := rowSums(M, na.rm = TRUE)]
  x[, .(year = yr, n = .N,
        share_all_sources = mean(all_sources, na.rm = TRUE),
        mean_n_sources    = mean(n_sources, na.rm = TRUE)),
    by = state_name]
}
W91 <- c("pc91_vd_tap", "pc91_vd_well", "pc91_vd_tank", "pc91_vd_tubewell",
         "pc91_vd_handpump", "pc91_vd_river", "pc91_vd_canal",
         "pc91_vd_lake", "pc91_vd_fountain")
W01 <- c("pc01_vd_tap", "pc01_vd_well", "pc01_vd_tank", "pc01_vd_tubewell",
         "pc01_vd_handpump", "pc01_vd_river", "pc01_vd_canal",
         "pc01_vd_lake", "pc01_vd_spring", "pc01_vd_other")
W11 <- c("pc11_vd_wat_tap_trt", "pc11_vd_wat_tap_untrt", "pc11_vd_wat_cov_well",
         "pc11_vd_wat_uncov_well", "pc11_vd_wat_handpump", "pc11_vd_wat_tubewell",
         "pc11_vd_wat_spring", "pc11_vd_wat_rivcan", "pc11_vd_wat_tnkpndlk",
         "pc11_vd_wat_oth")

sat <- rbindlist(list(sat_by_state(vd91, W91, 1991L),
                      sat_by_state(vd01, W01, 2001L),
                      sat_by_state(vd11, W11, 2011L)))
sat_w <- dcast(sat, state_name ~ year,
               value.var = c("n", "share_all_sources", "mean_n_sources"))
setorder(sat_w, -n_2001)
print(sat_w[, .(state_name, n_2001,
                core4_2001 = NA_real_,
                all_src_1991 = round(share_all_sources_1991, 3),
                all_src_2001 = round(share_all_sources_2001, 3),
                all_src_2011 = round(share_all_sources_2011, 3),
                nsrc_1991 = round(mean_n_sources_1991, 2),
                nsrc_2001 = round(mean_n_sources_2001, 2),
                nsrc_2011 = round(mean_n_sources_2011, 2))][, core4_2001 := NULL][])
fwrite(sat_w, p_tab("05b2d_source_saturation_by_state.csv"))

# The sharper test: the four main sources all present at once.
core4 <- function(d, srcs, yr) {
  x <- d[, c("shrid2", srcs), with = FALSE]
  for (v in srcs) set(x, j = v, value = as.numeric(x[[v]]) > 0)
  x <- merge(x, loc[, .(shrid2, state_name)], by = "shrid2", all.x = TRUE)
  M <- as.matrix(x[, ..srcs])
  x[, all4 := rowSums(M, na.rm = TRUE) == 4L]
  x[, .(year = yr, n = .N, share_all4 = mean(all4, na.rm = TRUE)), by = state_name]
}
c4 <- rbindlist(list(
  core4(vd91, c("pc91_vd_tap", "pc91_vd_well", "pc91_vd_handpump", "pc91_vd_tubewell"), 1991L),
  core4(vd01, c("pc01_vd_tap", "pc01_vd_well", "pc01_vd_handpump", "pc01_vd_tubewell"), 2001L),
  core4(vd11, c("pc11_vd_wat_tap_trt", "pc11_vd_wat_cov_well",
                "pc11_vd_wat_handpump", "pc11_vd_wat_tubewell"), 2011L)))
c4w <- dcast(c4, state_name ~ year, value.var = c("n", "share_all4"))
setorder(c4w, -n_2001)
msg("")
msg("Share of shrids with tap AND well AND handpump AND tubewell all present:")
print(c4w[, .(state_name, n_2001,
              all4_1991 = round(share_all4_1991, 3),
              all4_2001 = round(share_all4_2001, 3),
              all4_2011 = round(share_all4_2011, 3))])
fwrite(c4w, p_tab("05b2e_core4_saturation_by_state.csv"))

SAT_CUT <- 0.80
sat_states <- c4w[!is.na(share_all4_2001) & share_all4_2001 > SAT_CUT][order(-n_2001)]
msg("")
msg(sprintf("STATES WHERE 2001 IS SATURATED (all four sources present in over %.0f%% of shrids):",
            100 * SAT_CUT))
if (nrow(sat_states) == 0) {
  msg("  none")
} else {
  for (i in seq_len(nrow(sat_states)))
    msg(sprintf("  %-26s %7s shrids   all-four share = %.3f",
                sat_states$state_name[i], format(sat_states$n_2001[i], big.mark = ","),
                sat_states$share_all4_2001[i]))
  msg("")
  msg(sprintf("  Total: %s shrids, %.1f%% of the 2001 file.",
              format(sum(sat_states$n_2001), big.mark = ","),
              100 * sum(sat_states$n_2001) / nrow(vd01)))
  msg("  In these states pc01_vd_tap is 1 almost everywhere BECAUSE EVERY")
  msg("  SOURCE is 1 almost everywhere. The variable does not discriminate, so")
  msg("  a 2001 tap level from these states is not a measurement of tap access.")
}
n_sat_91 <- c4w[!is.na(share_all4_1991) & share_all4_1991 > SAT_CUT, .N]
n_sat_11 <- c4w[!is.na(share_all4_2011) & share_all4_2011 > SAT_CUT, .N]
msg("")
msg(sprintf("  For contrast: %d state(s) saturated in 1991 and %d in 2011, versus %d in 2001.",
            n_sat_91, n_sat_11, nrow(sat_states)))

# --- (b3) 2001 x 2011 transitions -------------------------------------------
hr("(b3) 2001 x 2011 transition table for tap_any")

trans <- function(d, tag) {
  x <- d[!is.na(tap01_any_m0) & !is.na(tap11_any_m0)]
  tt <- x[, .N, by = .(tap01 = tap01_any_m0, tap11 = tap11_any_m0)]
  tt[, share := N / sum(N)]
  setorder(tt, -tap01, -tap11)
  tt[, sample := tag]
  tt[]
}
t_nat <- trans(pan, "national (balanced panel)")
t_up  <- trans(pan[state_name == "uttar pradesh"], "uttar pradesh")
t_all <- rbind(t_nat, t_up)
t_all[, label := fcase(
  tap01 == 1 & tap11 == 0, "1 -> 0 (lost tap)",
  tap01 == 0 & tap11 == 1, "0 -> 1 (gained tap)",
  tap01 == 1 & tap11 == 1, "1 -> 1 (stable, has tap)",
  default = "0 -> 0 (stable, no tap)")]
print(t_all[, .(sample, label, N, share = round(share, 4))])
fwrite(t_all, p_tab("05b3_tap_transitions_01_11.csv"))

for (tag in unique(t_all$sample)) {
  s <- t_all[sample == tag]
  lost   <- s[label == "1 -> 0 (lost tap)", sum(share)]
  gained <- s[label == "0 -> 1 (gained tap)", sum(share)]
  msg("")
  msg(sprintf("  %s: %.1f%% lost tap, %.1f%% gained, %.1f%% stable (net %+.1f pp)",
              tag, 100 * lost, 100 * gained, 100 * (1 - lost - gained),
              100 * (gained - lost)))
}
msg("")
msg("  A large '1 -> 0' flow is not a credible real-world event: villages do")
msg("  not commonly lose a tap supply over a decade. It is the signature of a")
msg("  definitional or coding change between the two rounds.")

# --- (b4) is the 2001->2011 decline concentrated? ---------------------------
hr("(b4) Is the 2001->2011 decline concentrated or broad?")

dec <- pan[, .(
  n_shrids = .N,
  tap01 = mean(tap01_any_m0, na.rm = TRUE),
  tap11 = mean(tap11_any_m0, na.rm = TRUE)
), by = state_name]
dec[, change := tap11 - tap01]
dec[, contribution := change * n_shrids]   # shrid-weighted contribution
# Share of the TOTAL DECLINE (the sum of negative contributions), not of the
# small net change: dividing by a near-zero net produces shares above 1 and is
# meaningless. An earlier draft did that. Do not reintroduce.
tot_decline <- sum(dec[change < 0, contribution], na.rm = TRUE)
dec[, share_of_decline := fifelse(change < 0, contribution / tot_decline, NA_real_)]
dec <- merge(dec, c4w[, .(state_name, share_all4_2001)], by = "state_name", all.x = TRUE)
setorder(dec, contribution)
print(dec[, .(state_name, n_shrids, tap01 = round(tap01, 4), tap11 = round(tap11, 4),
              change = round(change, 4),
              share_of_decline = round(share_of_decline, 4),
              sat01 = round(share_all4_2001, 3))])
fwrite(dec, p_tab("05b4_tap_decline_concentration.csv"))

n_states  <- dec[!is.na(change), .N]
n_falling <- dec[change < 0, .N]
n_rising  <- dec[change > 0, .N]
top5      <- dec[change < 0][order(contribution)][1:min(5, n_falling)]
top5_share <- sum(top5$contribution, na.rm = TRUE) / tot_decline
msg("")
msg(sprintf("  %d of %d states fall, %d rise between 2001 and 2011.",
            n_falling, n_states, n_rising))
msg(sprintf("  The 5 largest contributors account for %.1f%% of the total decline:",
            100 * top5_share))
msg("    ", paste(sprintf("%s (%+.3f)", top5$state_name, top5$change), collapse = "; "))

# Does the decline sit where 2001 was saturated? That is the discriminating test.
fall_sat  <- dec[change < 0 & !is.na(share_all4_2001), weighted.mean(share_all4_2001, n_shrids)]
rise_sat  <- dec[change > 0 & !is.na(share_all4_2001), weighted.mean(share_all4_2001, n_shrids)]
sat_share_of_decline <- dec[change < 0 & share_all4_2001 > SAT_CUT,
                            sum(contribution, na.rm = TRUE)] / tot_decline
msg("")
msg(sprintf("  Mean 2001 saturation (shrid-weighted) among FALLING states: %.3f", fall_sat))
msg(sprintf("  Mean 2001 saturation (shrid-weighted) among RISING  states: %.3f", rise_sat))
msg(sprintf("  Share of the total decline contributed by states whose 2001 was"))
msg(sprintf("  saturated above %.0f%%: %.1f%%", 100 * SAT_CUT, 100 * sat_share_of_decline))
msg("")
if (isTRUE(sat_share_of_decline > 0.5) && isTRUE(fall_sat > rise_sat)) {
  msg("  READING: the decline is CONCENTRATED, and it sits precisely where the")
  msg("  2001 round was saturated. Falling states start from an implausible")
  msg("  2001 near-1 level and fall to a plausible 2011 level; rising states")
  msg("  start from a plausible 2001 level and rise. That is the signature of a")
  msg("  BROKEN 2001 BASELINE, not of tap disappearing between the rounds.")
} else if (n_falling / n_states > 0.6) {
  msg("  READING: the decline is BROAD, which would point to a change in the")
  msg("  measure applied nationally rather than a localised artefact.")
} else {
  msg("  READING: the decline is concentrated, but NOT aligned with 2001")
  msg("  saturation, so saturation does not explain it. Inspect those states.")
}

# --- (b5) bottom line -------------------------------------------------------
hr("(b5) BOTTOM LINE ON TAP COMPARABILITY")

nat_m0_tbl <- nat[sample == "balanced panel" & version == "m0"]
msg(sprintf("  Balanced panel, m0: tap_any = %.4f (1991), %.4f (2001), %.4f (2011).",
            nat_m0_tbl[year == 1991, mean], nat_m0_tbl[year == 2001, mean],
            nat_m0_tbl[year == 2011, mean]))
msg("")
msg("  CAN TAP BE COMPARED ACROSS 1991, 2001 AND 2011 FOR THE TIMING TESTS?")
msg("")
msg("  1991 vs later: NO, not at the level. 1991 tap is missing wholesale in")
msg("  whole states (section a), so the 1991 level is an artefact of which")
msg("  states happen to report. Any 1991-to-2001 change mixes a real change")
msg("  with a change in reporting coverage.")
msg("")
nat_lost <- t_all[sample == "national (balanced panel)" &
                    label == "1 -> 0 (lost tap)", sum(share)]
msg("  2001 vs 2011: NO, not in the saturated states. Both rounds are")
msg("  near-complete, and the single-village restriction shows the aggregation")
msg("  difference is not driving anything. But the measured direction is a")
msg("  DECLINE over a decade in which piped coverage certainly rose, and")
msg(sprintf("  %.1f%% of shrids nationally go 1 -> 0. Villages do not commonly lose",
            100 * nat_lost))
msg("  a tap supply, so that flow is a measurement artefact.")
msg("")
msg("  THE ARTEFACT IS IN 2001, NOT 2011. Section (b2d) shows that in")
msg(sprintf("  %d states (%s shrids, %.0f%% of the 2001 file) the 2001 round flags",
            nrow(sat_states), format(sum(sat_states$n_2001), big.mark = ","),
            100 * sum(sat_states$n_2001) / nrow(vd01)))
msg("  tap AND well AND handpump AND tubewell present in almost every shrid.")
msg("  A village cannot have every source at once: the 2001 source list is")
msg("  saturated there and pc01_vd_tap carries no information. Those same")
msg(sprintf("  states are where the 'decline' sits -- they contribute %.0f%% of it.",
            100 * sat_share_of_decline))
msg(sprintf("  The 2011 treated/untreated split is NOT the explanation: 2011 shows"))
msg(sprintf("  saturation in %d state(s) against %d in 2001.", n_sat_11, nrow(sat_states)))
msg("")
msg("  PRACTICAL READING: tap is usable for WITHIN-YEAR cross-sectional work,")
msg("  which is what the RD needs -- but only in states where that year's")
msg("  source list is not saturated. Do NOT read the across-census change in")
msg("  tap as a trend, and do not use 2001 at all in the saturated states.")
msg("  The timing tests need a usable-state list first, and")
msg("  output/tables/05b2e_core4_saturation_by_state.csv is that list.")
msg("")
msg("  This cuts BOTH ways, and the two failures hit DIFFERENT states: 1991")
msg("  fails where tap is missing wholesale, 2001 fails where the source list")
msg("  is saturated. The per-state tables are the only safe way to pick a")
msg("  sample; no single year is usable everywhere.")

# ===========================================================================
# QUESTIONS FOR THE PI -- nothing below is applied
# ===========================================================================
hr("QUESTIONS FOR THE PI (proposed changes -- NOT applied)")

msg("The outcome definitions in code/02_shrug_water.R are unchanged. The")
msg("following changes are PROPOSED for your decision:")
msg("")
msg("Q1. 1991 wholesale-missing states. Should the 1991 outcomes be restricted")
msg("    to states where tap is not missing wholesale, with the excluded states")
msg("    named in the paper? At present the m0 version silently assigns a zero")
msg("    to entire states that never reported. See 05a1_miss91_by_state.csv.")
msg("")
msg("Q2. A coverage flag. Should we add a per-shrid flag marking that its")
msg("    STATE is wholesale-missing in 1991, so every 1991 regression can be")
msg("    run with and without those states without rebuilding?")
msg("")
msg("Q3. 2001 saturation -- the most consequential one. In the states listed in")
msg("    (b2d), pc01_vd_tap is 1 almost everywhere because EVERY source is 1")
msg("    almost everywhere. Should 2001 be dropped entirely in those states,")
msg("    and should a saturation flag be carried per shrid? See")
msg("    05b2e_core4_saturation_by_state.csv. This is a question about whether")
msg("    the 2001 outcome is usable at all, not a refinement.")
msg("")
msg("Q4. Across-census comparability. On this evidence no across-census tap")
msg("    TREND is defensible: 1991 fails in one set of states and 2001 in a")
msg("    different set. Should the timing tests be dropped, or restricted to")
msg("    the intersection of states clean in every round they use?")
msg("")
msg("Q5. Availability vs functioning. Should any robustness check use the 2011")
msg("    _allyr ('Functioning All round the year') variable, accepting that it")
msg("    has no 1991 or 2001 counterpart?")
msg("")
msg("Q6. Is the saturation upstream of SHRUG? We have not checked whether the")
msg("    2001 saturation is in the Census source or introduced by SHRUG's")
msg("    construction. Worth one query to Development Data Lab before we build")
msg("    anything on 2001 -- the answer changes whether it can be repaired.")

hr("STEP 5 COMPLETE")
msg("Tables written to output/tables/:")
for (f in sort(list.files(p_tab(), pattern = "^05"))) msg("  ", f)
log_close()
