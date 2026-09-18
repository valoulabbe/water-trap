# ---------------------------------------------------------------------------
# 00_utils.R -- shared helpers for the Phase 0 data-preparation build.
#
# Logging + hard-stop validation helpers. Sourced by every code/NN_*.R script.
#
# NOTE ON REPOSITORY LAYOUT: CLAUDE.md's "Repository layout" block puts build
# scripts in build/, but .gitignore ignores build/ wholesale, so scripts placed
# there would never be committed. Scripts therefore live in code/ and build/
# holds data outputs only. Flagged for a CLAUDE.md fix.
# ---------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  library(haven)
  library(data.table)
}))

`%||%` <- function(a, b) if (is.null(a)) b else a

# Resolve project paths relative to the working directory, which run_all.R sets
# to the repository root.
p_raw    <- function(...) file.path("raw", ...)
p_build  <- function(...) file.path("build", ...)
p_log    <- function(...) file.path("output", "logs", ...)

ensure_dirs <- function() {
  for (d in c("build", "output", file.path("output", "logs"))) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }
}

# --- logging ---------------------------------------------------------------

.log_con <- NULL

log_open <- function(file) {
  ensure_dirs()
  .log_con <<- file(file, open = "wt", encoding = "UTF-8")
  sink(.log_con, split = TRUE)
  cat(strrep("=", 78), "\n", sep = "")
  cat("LOG: ", file, "\n", sep = "")
  cat("Run started: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
  cat(strrep("=", 78), "\n\n", sep = "")
}

# Idempotent: safe to call twice (e.g. normal end plus an error handler).
log_close <- function() {
  if (is.null(.log_con)) return(invisible(NULL))
  cat("\nRun finished: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
  while (sink.number() > 0) sink()
  try(close(.log_con), silent = TRUE)
  .log_con <<- NULL
  invisible(NULL)
}

hr <- function(title) {
  cat("\n", strrep("-", 78), "\n", title, "\n", strrep("-", 78), "\n", sep = "")
}

msg  <- function(...) cat(..., "\n", sep = "")
note <- function(...) cat("  ", ..., "\n", sep = "")
warn <- function(...) cat("  [WARNING] ", ..., "\n", sep = "")

# --- validation ------------------------------------------------------------

# Hard stop on failed validation. CLAUDE.md: "refuse to proceed past a failed
# validation rather than silently adapting".
check <- function(cond, what, detail = "") {
  if (isTRUE(cond)) {
    cat("  [OK]   ", what, "\n", sep = "")
    invisible(TRUE)
  } else {
    cat("  [FAIL] ", what, "\n", sep = "")
    if (nzchar(detail)) cat("         ", detail, "\n", sep = "")
    stop("VALIDATION FAILED: ", what,
         if (nzchar(detail)) paste0(" -- ", detail) else "",
         call. = FALSE)
  }
}

# Assert every named variable is present, by exact name.
check_vars <- function(d, vars, label) {
  missing <- setdiff(vars, names(d))
  check(length(missing) == 0,
        sprintf("%s: all %d named variables present", label, length(vars)),
        if (length(missing)) paste("absent:", paste(missing, collapse = ", ")) else "")
}

check_unique <- function(d, keys, label) {
  # as.data.frame so this works for tibbles (haven) and data.tables (fread) alike
  n_dup <- sum(duplicated(as.data.frame(d)[, keys, drop = FALSE]))
  check(n_dup == 0,
        sprintf("%s: key (%s) unique", label, paste(keys, collapse = "+")),
        sprintf("%d duplicate key rows", n_dup))
}

check_rows <- function(d, expected, label) {
  check(nrow(d) == expected,
        sprintf("%s: row count == %s", label, format(expected, big.mark = ",")),
        sprintf("observed %s", format(nrow(d), big.mark = ",")))
}

check_chr_key <- function(d, key, label) {
  check(is.character(d[[key]]),
        sprintf("%s: %s is character", label, key),
        sprintf("observed class: %s", class(d[[key]])[1]))
}

# Read a .dta keeping shrid2 a string. haven preserves Stata strings as
# character; we assert rather than coerce.
read_dta_chk <- function(path) {
  d <- haven::read_dta(path)
  d
}

# --- SHA256 manifest -------------------------------------------------------

# Parse the markdown tables in raw/README.md into (file, hash) rows. A manifest
# row is any table row whose first cell is a .zip/.csv file name; the digest is
# the last cell. Kept here, separate from I/O, so it can be tested directly on
# doctored input without ever touching raw/ (which is immutable).
parse_manifest <- function(readme_lines) {
  tbl_rows <- grep("^\\s*\\|", readme_lines, value = TRUE)
  parse_row <- function(x) {
    trimws(strsplit(sub("^\\s*\\|", "", sub("\\|\\s*$", "", x)), "\\|")[[1]])
  }
  cells <- lapply(tbl_rows, parse_row)
  keep <- vapply(cells, function(c) length(c) >= 2 &&
                   grepl("\\.(zip|csv)$", c[1], ignore.case = TRUE), logical(1))
  cells <- cells[keep]
  if (!length(cells)) return(data.table::data.table(file = character(),
                                                    hash = character(),
                                                    hash_ok = logical()))
  m <- data.table::data.table(
    file = vapply(cells, function(c) c[1], character(1)),
    hash = vapply(cells, function(c) c[length(c)], character(1))
  )
  m[, hash := toupper(gsub("[^0-9A-Fa-f]", "", hash))]
  m[, hash_ok := nchar(hash) == 64L]
  m[]
}

# Hard stop unless EVERY manifest row carries a real 64-hex digest. A blank or
# placeholder hash means we cannot verify that file, so we stop and say which,
# rather than quietly skipping the integrity check for it.
validate_manifest <- function(m) {
  check(nrow(m) > 0, "manifest contains at least one file row")
  bad <- m[hash_ok == FALSE]
  if (nrow(bad) > 0) {
    warn("manifest rows without a real 64-hex SHA256:")
    for (i in seq_len(nrow(bad))) note("    ", bad$file[i], "  ->  '", bad$hash[i], "'")
  }
  check(nrow(bad) == 0,
        sprintf("all %d manifest rows carry a real 64-hex SHA256", nrow(m)),
        sprintf("%d row(s) with a missing/placeholder hash: %s",
                nrow(bad), paste(bad$file, collapse = ", ")))
  invisible(m)
}
