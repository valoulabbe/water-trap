# ---------------------------------------------------------------------------
# 01_ingest_validate.R -- ingest every raw file and VALIDATE before use.
#
# Phase 0 data preparation. Runs while Phase 0a is blocked (neither Sekhri
# package carries the depth running variable or Census keys). No RD here, and
# no depth value is ever joined to a water outcome.
#
# Validation policy (CLAUDE.md): row counts, key uniqueness, presence of the
# variables the spec names, shrid2 kept character. Any failure is a hard stop --
# we refuse to proceed rather than silently adapting.
#
# Step 1a validates the SHA256 manifest in raw/README.md ITSELF before trusting
# any hash: every manifest row must carry a real 64-hex digest. A placeholder or
# blank hash is a hard stop.
#
# Outputs: build/inventory_raw.csv, output/logs/01_ingest_validate.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
log_open(p_log("01_ingest_validate.log"))

msg("STEP 1 -- INGEST AND VALIDATE RAW DATA")
msg("Phase 0a is blocked; this prepares data every route will need.")
msg("No RD is estimated here and no depth value is joined to any water outcome.")

# ===========================================================================
# 1a. Validate the SHA256 manifest in raw/README.md
# ===========================================================================
hr("1a. SHA256 manifest in raw/README.md")

readme_path <- p_raw("README.md")
check(file.exists(readme_path), "raw/README.md exists")

readme <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

# parse_manifest() / validate_manifest() live in code/00_utils.R so the rule can
# be tested on doctored input without editing raw/ (which is immutable).
man <- parse_manifest(readme)
msg("  manifest file rows found: ", nrow(man))
validate_manifest(man)

# ===========================================================================
# 1b. Recompute SHA256 for every archive/csv in raw/ and compare
# ===========================================================================
hr("1b. SHA256 integrity of raw archives")

# Avoid a new package dependency: shell out to certutil on Windows,
# sha256sum elsewhere.
openssl_sha256 <- function(path) {
  if (.Platform$OS.type == "windows") {
    out <- suppressWarnings(system2("certutil", c("-hashfile", shQuote(path), "SHA256"),
                                    stdout = TRUE, stderr = FALSE))
    h <- gsub("[^0-9A-Fa-f]", "", out[2])
    h
  } else {
    out <- suppressWarnings(system2("sha256sum", shQuote(path), stdout = TRUE))
    sub(" .*$", "", out[1])
  }
}

raw_files <- c(
  list.files(p_raw("shrug"), pattern = "\\.zip$", full.names = TRUE),
  list.files(p_raw("cgwb"),  pattern = "\\.csv$", full.names = TRUE)
)

hash_tbl <- data.table(path = raw_files, file = basename(raw_files))
hash_tbl[, sha256 := vapply(path, function(p) toupper(openssl_sha256(p)), character(1))]
hash_tbl <- merge(hash_tbl, man[, .(file, manifest_hash = hash)], by = "file", all.x = TRUE)
hash_tbl[, status := fifelse(is.na(manifest_hash), "NOT_IN_MANIFEST",
                    fifelse(sha256 == manifest_hash, "MATCH", "MISMATCH"))]

for (i in seq_len(nrow(hash_tbl))) {
  note(sprintf("%-34s %s", hash_tbl$file[i], hash_tbl$status[i]))
}

n_mismatch <- hash_tbl[status == "MISMATCH", .N]
if (n_mismatch > 0) {
  for (f in hash_tbl[status == "MISMATCH", file]) warn("hash mismatch: ", f)
}
check(n_mismatch == 0, "no SHA256 mismatch against the manifest",
      sprintf("%d file(s) differ from their recorded hash", n_mismatch))

# Files present in raw/ but absent from the manifest are a PROVENANCE GAP, not
# a corrupted manifest. We cannot verify them, so we say so loudly and print
# the computed digest for the human to paste into raw/README.md. We do not stop:
# the manifest-row check above passed, and these files' contents are still
# validated below by row count, key uniqueness and variable presence.
unmanifested <- hash_tbl[status == "NOT_IN_MANIFEST"]
if (nrow(unmanifested) > 0) {
  hr("PROVENANCE GAP -- files in raw/ with no row in raw/README.md")
  warn("These files could NOT be integrity-checked. Add them to raw/README.md.")
  for (i in seq_len(nrow(unmanifested))) {
    note(unmanifested$file[i])
    note("    computed SHA256: ", unmanifested$sha256[i])
  }
  warn("Reported, not silently skipped. The build continues because these ",
       "files are still validated on row count, key uniqueness and variables.")
}

# ===========================================================================
# 1c. Expected shapes -- committed here, compared against the data
# ===========================================================================
hr("1c. File-by-file validation")

# Drinking-water variable names, verified 2026-09-18 against
# docs.devdatalab.org (vd11 / vd01 metadata pages) and the embedded Stata
# variable labels. Recorded here so no downstream script guesses a name.
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

inventory <- list()

validate_dta <- function(path, label, expected_rows, keys, vars) {
  note("")
  msg("  FILE: ", path)
  check(file.exists(path), paste0(label, ": file exists"))
  d <- read_dta_chk(path)
  src <- last_read_source()
  if (identical(src$source, "rds")) {
    note("source lue : ", src$path, "  [COPIE CONVERTIE]")
    note("  le contenu valide ci-dessous vient de la conversion, pas du .dta ;")
    note("  le SHA256 du .dta source est dans build/dta_conversion_manifest.csv")
  } else {
    note("source lue : ", path, "  [.dta d'origine]")
  }
  check_rows(d, expected_rows, label)
  check_vars(d, vars, label)
  check_unique(d, keys, label)
  if ("shrid2" %in% names(d)) check_chr_key(d, "shrid2", label)
  inventory[[label]] <<- data.table(
    label = label, path = path, rows = nrow(d), cols = ncol(d),
    key_vars = paste(keys, collapse = "+"), key_unique = TRUE
  )
  invisible(d)
}

# --- Village Directory, shrid level ---------------------------------------
validate_dta(p_raw("shrug", "shrug-vd91-dta", "pc91_vd_clean_shrid.dta"),
             "vd91", 564855L, "shrid2",
             c("shrid2", WAT91, "pc91_vd_drnk_wat_f", "pc91_vd_rang_wat_f",
               "pc91_vd_t_p", "pc91_vd_t_hh",
               "pc91_vd_tw_w_el", "pc91_vd_tw_wo_el",
               "pc91_vd_well_w_el", "pc91_vd_well_wo_el",
               "pc91_vd_canal_govt", "pc91_vd_canal_pvt",
               "pc91_vd_tank_irr", "pc91_vd_tot_irr",
               "_mean_p_miss"))

validate_dta(p_raw("shrug", "shrug-vd01-dta", "pc01_vd_clean_shrid.dta"),
             "vd01", 527920L, "shrid2",
             c("shrid2", WAT01, "pc01_vd_t_p", "pc01_vd_t_hh", "_mean_p_miss"))

validate_dta(p_raw("shrug", "shrug-vd11-dta", "pc11_vd_clean_shrid.dta"),
             "vd11", 588973L, "shrid2",
             c("shrid2", WAT11, "pc11_vd_t_p", "pc11_vd_t_hh",
               "pc11_vd_land_wl_tw_irr", "pc11_vd_land_canal_irr",
               "_mean_p_miss"))

# --- Rural village keys (give villages-per-shrid) -------------------------
#
# KEY CORRECTION (2026-09-18). The first draft of this script expected
# shrid2 + village_id to be unique. It is NOT: pc91r has 95 duplicate
# (shrid2, pc91_village_id) rows, because a Census village id is unique only
# WITHIN a subdistrict, and a shrid can span subdistricts. The true key is the
# full geographic id, state+district+subdistrict+village, which has 0
# duplicates in all three years (verified). The expectation was wrong, not the
# data -- recorded here rather than quietly relaxed.
geo_ids <- function(y) sprintf("pc%s_%s_id", y, c("state", "district",
                                                  "subdistrict", "village"))

validate_dta(p_raw("shrug", "shrug-pc-keys-dta", "pc91r_shrid_key.dta"),
             "pc91r_key", 570426L, geo_ids("91"),
             c("shrid2", geo_ids("91")))

validate_dta(p_raw("shrug", "shrug-pc-keys-dta", "pc01r_shrid_key.dta"),
             "pc01r_key", 591668L, geo_ids("01"),
             c("shrid2", geo_ids("01")))

validate_dta(p_raw("shrug", "shrug-pc-keys-dta", "pc11r_shrid_key.dta"),
             "pc11r_key", 597597L, geo_ids("11"),
             c("shrid2", geo_ids("11")))

# --- shrid keys ------------------------------------------------------------
validate_dta(p_raw("shrug", "shrug-shrid-keys-dta", "shrid_loc_names.dta"),
             "shrid_loc_names", 596389L, "shrid2",
             c("shrid2", "state_name", "district_name", "subdistrict_name",
               "village_name"))

validate_dta(p_raw("shrug", "shrug-shrid-keys-dta", "shrid2_spatial_stats.dta"),
             "shrid2_spatial_stats", 596358L, "shrid2",
             c("shrid2", "latitude", "longitude", "polysource", "high_quality",
               "area_laea"))

# --- CGWB monitoring wells -------------------------------------------------
note("")
cgwb_path <- p_raw("cgwb", "CGWB_data_wide.csv")
msg("  FILE: ", cgwb_path)
check(file.exists(cgwb_path), "cgwb: file exists")
cg <- fread(cgwb_path)
check_rows(cg, 28076L, "cgwb")
MAY_COLS <- paste("May", 1996:2016)
check_vars(cg, c("STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE", "WLCODE",
                 MAY_COLS), "cgwb")
check_unique(cg, "WLCODE", "cgwb")
check(sum(is.na(cg$LAT)) == 0 && sum(is.na(cg$LON)) == 0,
      "cgwb: no missing coordinates",
      sprintf("LAT NA=%d LON NA=%d", sum(is.na(cg$LAT)), sum(is.na(cg$LON))))
check(all(cg$LAT >= 6 & cg$LAT <= 38) && all(cg$LON >= 67 & cg$LON <= 98),
      "cgwb: all coordinates inside the India bounding box")
inventory[["cgwb"]] <- data.table(label = "cgwb", path = cgwb_path,
                                  rows = nrow(cg), cols = ncol(cg),
                                  key_vars = "WLCODE", key_unique = TRUE)

# --- shrid polygons --------------------------------------------------------
note("")
gpkg_path <- p_raw("shrug", "shrug-shrid-poly-gpkg", "shrid2_open.gpkg")
msg("  FILE: ", gpkg_path)
check(file.exists(gpkg_path), "shrid_poly: file exists")
suppressWarnings(suppressMessages(library(sf)))
lyrs <- sf::st_layers(gpkg_path)
check("shrid2" %in% lyrs$name, "shrid_poly: layer 'shrid2' present")
n_feat <- lyrs$features[match("shrid2", lyrs$name)]
check(n_feat == 595438L, "shrid_poly: feature count == 595,438",
      sprintf("observed %s", format(n_feat, big.mark = ",")))
poly_crs <- sf::st_crs(lyrs$crs[[match("shrid2", lyrs$name)]])
note("shrid_poly CRS: ", poly_crs$Name %||% "<unnamed>")
check(!is.na(poly_crs) && grepl("WGS\\s*84", poly_crs$Name %||% ""),
      "shrid_poly: CRS is WGS 84")
inventory[["shrid_poly"]] <- data.table(label = "shrid_poly", path = gpkg_path,
                                        rows = as.integer(n_feat),
                                        cols = NA_integer_,
                                        key_vars = "shrid2", key_unique = NA)

# ===========================================================================
# 1d. Write the inventory
# ===========================================================================
hr("1d. Inventory")

# Two separate views, deliberately not merged: the hash table covers the
# downloaded ARCHIVES (zip/csv), the inventory covers the EXTRACTED files that
# the analysis actually reads. They do not share a path.
inv <- rbindlist(inventory, fill = TRUE)
setcolorder(inv, c("label", "path", "rows", "cols", "key_vars", "key_unique"))
fwrite(inv, p_build("inventory_raw.csv"))
print(inv[, .(label, rows, cols, key_vars)])

note("")
fwrite(hash_tbl[, .(file, status, sha256, manifest_hash)],
       p_build("inventory_raw_hashes.csv"))
print(hash_tbl[, .(file, status)])

hr("STEP 1 COMPLETE -- all validations passed")
msg("Wrote build/inventory_raw.csv and build/inventory_raw_hashes.csv")
if (nrow(unmanifested) > 0) {
  warn("ACTION FOR THE HUMAN: ", nrow(unmanifested),
       " raw file(s) still have no SHA256 row in raw/README.md (listed above).")
}
log_close()
