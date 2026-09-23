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

# haven n'est PAS charge ici : il n'est requis que par read_dta_chk(), qui le
# charge a la demande via son espace de noms. Les etapes qui ne lisent aucun
# .dta n'ont donc aucune dependance a haven.
suppressWarnings(suppressMessages({
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

# Message horodate, force sur disque aussitot : apres un arret brutal, la
# derniere ligne du log dit exactement quelle etape etait en cours.
tmsg <- function(...) {
  cat("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", ..., "\n", sep = "")
  if (!is.null(.log_con)) flush(.log_con)
}

# Duree ecoulee depuis t0, en secondes, pour les messages de fin d'etape.
secs_since <- function(t0) sprintf("%.1f s", as.numeric(difftime(Sys.time(), t0, units = "secs")))

# --- etapes resumables -----------------------------------------------------
# stage(label, path, build, after) : si `path` existe, le relit ; sinon appelle
# build(), ecrit le resultat dans `path` et le renvoie. L'etape est refaite si
# --force est passe au script, si `path` manque, ou si l'un des fichiers amont
# `after` est plus recent que `path` (une etape refaite invalide donc l'aval).
# Ecriture atomique (.part puis renommage) : un arret en cours d'ecriture ne
# laisse jamais un fichier tronque qui passerait pour valide.
# Format selon l'extension : .gpkg (sf) ou .rds (tout le reste).
FORCE <- "--force" %in% commandArgs(trailingOnly = TRUE)

stage_read <- function(path) {
  if (grepl("\\.gpkg$", path)) return(sf::st_read(path, quiet = TRUE))
  x <- readRDS(path)
  if (data.table::is.data.table(x)) data.table::setalloccol(x)
  x
}

stage_write <- function(x, path, layer) {
  if (grepl("\\.gpkg$", path)) {
    sf::st_write(x, path, layer = layer, quiet = TRUE, delete_dsn = TRUE)
  } else {
    saveRDS(x, path)
  }
}

stage <- function(label, path, build, after = character()) {
  t0 <- Sys.time()
  stale_up <- after[file.exists(after) & file.exists(path) &
                      file.mtime(after) > file.mtime(path)]
  if (file.exists(path) && !FORCE && length(stale_up) == 0L) {
    tmsg(label, " : deja fait, relu depuis ", path, " (ecrit le ",
         format(file.mtime(path), "%Y-%m-%d %H:%M"), ")")
    out <- stage_read(path)
    tmsg(label, " : relu (", secs_since(t0), ")")
    return(out)
  }
  why <- if (FORCE) "--force" else if (length(stale_up)) paste("amont plus recent :",
    paste(stale_up, collapse = ", ")) else "sortie absente"
  tmsg(label, " : debut (", why, ")")
  out <- withCallingHandlers(build(), error = function(e)
    tmsg(label, " : ERREUR : ", conditionMessage(e)))
  tmp <- sub("(\\.[^.]+)$", ".part\\1", path)
  if (file.exists(tmp)) file.remove(tmp)
  stage_write(out, tmp, layer = sub("\\.[^.]+$", "", basename(path)))
  if (file.exists(path)) file.remove(path)
  check(file.rename(tmp, path), paste0(label, " : sortie ecrite -> ", path))
  tmsg(label, " : fini (", secs_since(t0), ")")
  out
}
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
# character; we assert rather than coerce. haven is loaded on demand here, not
# at the top of this file, so steps that read no .dta do not depend on it.
# Chemin de la copie convertie correspondant a un .dta de raw/shrug/.
# Les noms de base des 59 .dta sont uniques (verifie), donc build/<base>.rds
# ne peut pas entrer en collision.
dta_rds_path <- function(dta_path)
  file.path("build", paste0(sub("\\.dta$", "", basename(dta_path)), ".rds"))

# Provenance de la derniere lecture, pour journalisation par l'appelant.
.read_src <- new.env(parent = emptyenv())
last_read_source <- function() as.list(.read_src)

read_dta_chk <- function(path, prefer_rds = TRUE) {
  rds <- dta_rds_path(path)
  if (prefer_rds && file.exists(rds)) {
    assign("source", "rds", envir = .read_src)
    assign("path", rds, envir = .read_src)
    return(readRDS(rds))
  }
  if (!requireNamespace("haven", quietly = TRUE))
    stop("PACKAGE INDISPONIBLE : haven n'a pas pu etre charge et ", rds,
         " est absent, donc ", path, " est illisible. ",
         "Lancer d'abord : Rscript code/00_convert_dta.R . ",
         "Arret -- aucune relance automatique.", call. = FALSE)
  assign("source", "dta", envir = .read_src)
  assign("path", path, envir = .read_src)
  haven::read_dta(path)
}

# Lire une table SHRUG en preferant une conversion .rds deja faite, avec repli
# sur le .dta d'origine via haven. Motif : sur cette machine une politique de
# controle d'application bloque par intermittence le chargement des DLL de
# packages depuis le cache renv, ce qui rend haven indisponible sans preavis.
# Le .rds se lit sans aucun package tiers.
# Renvoie une liste : $data (data.table) et $source ("rds" ou "dta").
# Habillage de read_dta_chk() qui renvoie aussi la provenance, pour les appelants
# qui veulent la journaliser. Une seule logique de repli, ici comme ailleurs.
read_shrug_key <- function(rds_path, dta_path) {
  d <- read_dta_chk(dta_path)
  src <- last_read_source()
  list(data = data.table::as.data.table(d),
       source = src$source %||% "dta",
       path   = src$path %||% dta_path)
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
