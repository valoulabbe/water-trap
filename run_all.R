# ---------------------------------------------------------------------------
# run_all.R -- master script. Reproduces every build output from raw/ with no
#              manual steps and no hand-entered numbers (CLAUDE.md).
#
#   Rscript run_all.R
#
# Scope: Phase 0 DATA PREPARATION only, run while Phase 0a is blocked (neither
# Sekhri package carries the depth running variable or keys to Census codes;
# awaiting the PI's decision).
#
#   NO RD IS ESTIMATED ANYWHERE IN THIS PIPELINE, and no depth value is ever
#   joined to a water outcome. The nearest-well output carries distances only.
#
# REPOSITORY LAYOUT NOTE: CLAUDE.md's "Repository layout" block puts build
# scripts in build/, but .gitignore ignores build/ wholesale, so scripts there
# would never be committed. Scripts therefore live in code/, build/ holds data
# outputs only, and this master script sits at the repository root. Flagged for
# a CLAUDE.md fix.
#
# Steps
#   code/01_ingest_validate.R      validate every raw file; hard stop on failure
#   code/02_shrug_water.R          public-water outcomes, 1991/2001/2011
#   code/03_cgwb_long.R            CGWB May (pre-monsoon) panel + QC
#   code/04_shrid_centroids_dist.R shrid centroids; distance to nearest well
#   code/05_diag_missing_tap.R     missingness diagnostics
#   code/08_wells_in_villages.R    CGWB well -> village link (st_within)
#   (06, 07 frozen: interpolation for the dropped RD design; see STEPS below)
#
# Logs: output/logs/
# ---------------------------------------------------------------------------

t0 <- Sys.time()

if (!file.exists("CLAUDE.md"))
  stop("run_all.R must be run from the repository root.", call. = FALSE)

dir.create(file.path("output", "logs"), recursive = TRUE, showWarnings = FALSE)
dir.create("build", showWarnings = FALSE)

STEPS <- c(
  "code/01_ingest_validate.R",
  "code/02_shrug_water.R",
  "code/03_cgwb_long.R",
  "code/04_shrid_centroids_dist.R",
  "code/05_diag_missing_tap.R",
  # 06 and 07 FROZEN (2026-09-23): interpolation built for the dropped 8 m RD
  # design. Kept as committed, with their logs and tables; not rerun.
  # Findings carried forward: within-well SD of May depth (median 0.73 m) and
  # variogram range 30-70 km. Run by hand if ever needed.
  "code/08_wells_in_villages.R"
)

run_log <- file.path("output", "logs", "run_all.log")
con <- file(run_log, open = "wt", encoding = "UTF-8")
writeLines(c(
  strrep("=", 78),
  "run_all.R",
  paste("Started:", format(t0, "%Y-%m-%d %H:%M:%S")),
  strrep("=", 78), ""
), con)

results <- data.frame(step = STEPS, status = NA_character_,
                      seconds = NA_real_, stringsAsFactors = FALSE)

for (i in seq_along(STEPS)) {
  s <- STEPS[i]
  message("\n>>> ", s)
  writeLines(paste0(">>> ", s), con); flush(con)
  ts <- Sys.time()
  ok <- tryCatch({
    # Fresh environment per step: no state leaks between steps.
    sys.source(s, envir = new.env(parent = globalenv()))
    TRUE
  }, error = function(e) {
    # Make sure a failing step cannot leave a sink open and swallow output.
    while (sink.number() > 0) sink()
    message("!!! FAILED: ", conditionMessage(e))
    writeLines(paste0("!!! FAILED: ", conditionMessage(e)), con)
    FALSE
  })
  while (sink.number() > 0) sink()
  results$seconds[i] <- as.numeric(difftime(Sys.time(), ts, units = "secs"))
  results$status[i]  <- if (ok) "OK" else "FAILED"
  writeLines(sprintf("    %s in %.1fs", results$status[i], results$seconds[i]), con)
  flush(con)
  if (!ok) {
    writeLines("\nPipeline halted on failure. Later steps not run.", con)
    close(con)
    stop("Pipeline halted at ", s, call. = FALSE)
  }
}

writeLines(c("", strrep("-", 78), "SUMMARY", strrep("-", 78)), con)
writeLines(capture.output(print(results, row.names = FALSE)), con)

writeLines(c("", strrep("-", 78), "sessionInfo()", strrep("-", 78)), con)
writeLines(capture.output(print(sessionInfo())), con)

writeLines(c("", paste("Finished:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
             sprintf("Total: %.1f minutes",
                     as.numeric(difftime(Sys.time(), t0, units = "mins")))), con)
close(con)

message("\n", strrep("-", 60))
print(results, row.names = FALSE)
message(sprintf("Total: %.1f minutes",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
message("Logs in output/logs/ -- review 02_shrug_water.log first:")
message("  it opens with a DEVIATION notice (2001/2011 anchor) pending PI approval.")
