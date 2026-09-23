# ---------------------------------------------------------------------------
# 00_convert_dta.R -- convertir les .dta de raw/shrug/ en .rds dans build/.
#
# A LANCER SEUL, PAS DANS run_all.R :
#     Rscript code/00_convert_dta.R                # les 59 tables
#     Rscript code/00_convert_dta.R --used-only    # les 8 tables du pipeline
#     ... --force                                  # reconvertir meme si a jour
#
# OBSERVABILITE. Chaque sous-etape (chargement de haven, hachage, lecture,
# ecriture) est horodatee et ecrite sur disque aussitot : si le script se
# bloque, la derniere ligne du log nomme l'etape et la table en cause. Les
# erreurs sont recopiees dans le log (sinon elles ne vont qu'au terminal).
#
# POURQUOI. Sur cette machine, une politique de controle d'application Windows
# bloque par INTERMITTENCE le chargement des DLL de packages R depuis le cache
# renv (message : "LoadLibrary failure : Une strategie de controle
# d'application a bloque ce fichier", typiquement sur cli.dll). haven devient
# alors indisponible sans preavis et toute lecture de .dta echoue. Un .rds se
# lit avec readRDS(), sans aucun package tiers : une fois la conversion faite,
# le pipeline ne depend plus de haven.
#
# Les .rds sont des COPIES DERIVEES, jamais la source de verite. raw/ reste
# immuable et n'est ouvert qu'en lecture. Les objets sont enregistres tels que
# haven les renvoie, etiquettes Stata comprises, pour que la lecture via .rds
# et via .dta donnent exactement le meme objet.
#
# IDEMPOTENCE. Le SHA256 de chaque .dta source est enregistre dans
# build/dta_conversion_manifest.csv. Une table est reconvertie seulement si son
# .rds manque ou si le hachage de la source a change. Le script est donc
# relancable sans frais, et reprend ou il s'etait arrete -- ce qui compte, vu
# que le blocage decrit plus haut peut l'interrompre en cours de route.
#
# Sorties : build/*.rds, build/dta_conversion_manifest.csv,
#           output/logs/00_convert_dta.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
log_open(p_log("00_convert_dta.log"))

args      <- commandArgs(trailingOnly = TRUE)
used_only <- "--used-only" %in% args
force     <- "--force" %in% args

# Les tables effectivement lues par run_all.R (etapes 1, 2, 4, 5, 6, 8).
TABLES_PIPELINE <- c(
  "pc91_vd_clean_shrid.dta", "pc01_vd_clean_shrid.dta", "pc11_vd_clean_shrid.dta",
  "pc91r_shrid_key.dta", "pc01r_shrid_key.dta", "pc11r_shrid_key.dta",
  "shrid_loc_names.dta", "shrid2_spatial_stats.dta")

msg("CONVERSION DES .dta SHRUG EN .rds")
msg("")
msg("Motif : une politique de controle d'application bloque par intermittence")
msg("le chargement des DLL de packages depuis le cache renv, ce qui rend haven")
msg("indisponible sans preavis. Un .rds se lit sans aucun package tiers.")
msg("")
msg("raw/ reste immuable : ouvert en LECTURE SEULE. Les .rds de build/ sont des")
msg("copies derivees, jamais la source de verite.")
msg("")
msg("Mode : ", if (used_only) "--used-only (tables du pipeline seulement)"
              else "complet (toutes les tables de raw/shrug/)",
    if (force) " + --force (tout reconvertir)" else "")

# ===========================================================================
# Inventaire
# ===========================================================================
hr("Inventaire des sources")

dta <- list.files(p_raw("shrug"), pattern = "\\.dta$", recursive = TRUE,
                  full.names = TRUE)
check(length(dta) > 0, "au moins un .dta trouve dans raw/shrug/")

bn <- basename(dta)
check(sum(duplicated(bn)) == 0,
      "noms de base uniques (build/<base>.rds ne peut pas collisionner)",
      sprintf("%d doublon(s) : %s", sum(duplicated(bn)),
              paste(unique(bn[duplicated(bn)]), collapse = ", ")))

if (used_only) {
  dta <- dta[bn %in% TABLES_PIPELINE]
  bn  <- basename(dta)
  manquantes <- setdiff(TABLES_PIPELINE, bn)
  check(length(manquantes) == 0, "toutes les tables du pipeline sont presentes",
        sprintf("absentes : %s", paste(manquantes, collapse = ", ")))
}

# Les tables du pipeline d'abord : ainsi une interruption laisse quand meme le
# pipeline utilisable.
ordre <- order(!(bn %in% TABLES_PIPELINE), bn)
dta   <- dta[ordre]
bn    <- bn[ordre]

taille <- file.size(dta)
msg("  tables a examiner : ", length(dta))
msg(sprintf("  volume source    : %.1f Mo", sum(taille) / 1048576))
msg("  dont tables du pipeline : ", sum(bn %in% TABLES_PIPELINE), " (converties en premier)")

# ===========================================================================
# Manifeste existant
# ===========================================================================
hr("Manifeste")

man_path <- p_build("dta_conversion_manifest.csv")
man <- if (file.exists(man_path)) {
  fread(man_path, colClasses = "character")
} else {
  data.table(dta = character(), sha256 = character(),
             size_bytes = character(), rows = character(),
             cols = character(), rds = character(),
             converted_at = character())
}
msg("  ", man_path, if (file.exists(man_path)) paste0(" : ", nrow(man), " entrees")
                    else " : absent, il sera cree")

sha256_of <- function(path) {
  if (.Platform$OS.type == "windows") {
    out <- suppressWarnings(system2("certutil", c("-hashfile", shQuote(path), "SHA256"),
                                    stdout = TRUE, stderr = FALSE))
    toupper(gsub("[^0-9A-Fa-f]", "", out[2]))
  } else {
    toupper(sub(" .*$", "", suppressWarnings(system2("sha256sum", shQuote(path),
                                                     stdout = TRUE))[1]))
  }
}

# ===========================================================================
# Conversion
# ===========================================================================
hr("Chargement de haven")

# Etape isolee et chronometree : c'est ici que le blocage des DLL par la
# politique de controle d'application se manifeste, pas dans la lecture.
t_h <- Sys.time()
tmsg("chargement de l'espace de noms haven ...")
haven_ok <- requireNamespace("haven", quietly = TRUE)
tmsg("haven ", if (haven_ok) "charge" else "INDISPONIBLE", " (", secs_since(t_h), ")")
check(haven_ok, "haven se charge",
      "probablement le blocage des DLL par la politique de controle d'application")

hr("Conversion")

# Restes d'une ecriture interrompue : jamais pris pour un .rds valide.
parts <- list.files("build", pattern = "\\.rds\\.part$", full.names = TRUE)
if (length(parts) > 0) {
  msg("  fichiers partiels d'une execution interrompue, supprimes :")
  for (f in parts) note("    ", f)
  file.remove(parts)
}

res <- vector("list", length(dta))
n_conv <- 0L; n_skip <- 0L

for (i in seq_along(dta)) {
  src <- dta[i]
  rel <- sub("^raw/", "", src)
  rds <- dta_rds_path(src)
  lab <- sprintf("[%d/%d] %s", i, length(dta), bn[i])

  t_s <- Sys.time()
  tmsg(lab, " : hachage SHA256 (", sprintf("%.0f Mo", taille[i] / 1048576), ") ...")
  sha <- sha256_of(src)
  tmsg(lab, " : hachage fait (", secs_since(t_s), ")")

  prev <- man[dta == rel]
  a_jour <- !force && file.exists(rds) && nrow(prev) == 1L &&
    identical(prev$sha256[1], sha)

  if (a_jour) {
    n_skip <- n_skip + 1L
    res[[i]] <- data.table(dta = rel, sha256 = sha,
                           size_bytes = as.character(file.size(src)),
                           rows = prev$rows[1], cols = prev$cols[1],
                           rds = rds, converted_at = prev$converted_at[1])
    msg(sprintf("  [inchange] %-38s %s lignes", bn[i], prev$rows[1]))
    next
  }

  # Lecture DIRECTE du .dta : prefer_rds = FALSE, sinon on relirait la copie
  # qu'on est justement en train de reconstruire.
  # Les erreurs sont recopiees dans le log avant d'arreter le script.
  t_r <- Sys.time()
  tmsg(lab, " : lecture du .dta ...")
  d <- withCallingHandlers(
    read_dta_chk(src, prefer_rds = FALSE),
    error = function(e) tmsg(lab, " : ERREUR a la lecture : ", conditionMessage(e)))
  tmsg(lab, " : lu, ", format(nrow(d), big.mark = ","), " x ", ncol(d),
       " (", secs_since(t_r), ")")

  # Ecriture atomique : .part puis renommage. Un arret pendant saveRDS laisse
  # un .part (supprime a la relance), jamais un .rds tronque qui passerait
  # pour valide.
  t_w <- Sys.time()
  tmsg(lab, " : ecriture de ", rds, " ...")
  tmp <- paste0(rds, ".part")
  withCallingHandlers({
    saveRDS(d, tmp, compress = TRUE)
    if (file.exists(rds)) file.remove(rds)
    check(file.rename(tmp, rds), paste0(lab, " : renommage .part -> .rds"))
  }, error = function(e) tmsg(lab, " : ERREUR a l'ecriture : ", conditionMessage(e)))
  tmsg(lab, " : ecrit, ", sprintf("%.0f Mo", file.size(rds) / 1048576),
       " (", secs_since(t_w), ")")
  n_conv <- n_conv + 1L

  res[[i]] <- data.table(dta = rel, sha256 = sha,
                         size_bytes = as.character(file.size(src)),
                         rows = as.character(nrow(d)), cols = as.character(ncol(d)),
                         rds = rds,
                         converted_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  msg(sprintf("  [converti] %-38s %9s lignes x %3s col.  SHA256 source %s...",
              bn[i], format(nrow(d), big.mark = ","), ncol(d), substr(sha, 1, 16)))

  # Manifeste ecrit au fil de l'eau : une interruption ne perd pas le travail
  # deja fait, et la relance reprend proprement.
  fwrite(rbindlist(res[seq_len(i)]), man_path)
  rm(d); invisible(gc(verbose = FALSE))
}

man_new <- rbindlist(res)
fwrite(man_new, man_path)

# ===========================================================================
# Bilan
# ===========================================================================
hr("BILAN")

msg("  tables converties : ", n_conv)
msg("  tables inchangees : ", n_skip)
msg("  manifeste         : ", man_path)
rds_faits <- file.exists(man_new$rds)
msg("  .rds presents     : ", sum(rds_faits), " / ", nrow(man_new))
if (any(!rds_faits)) {
  warn("fichiers .rds attendus mais absents :")
  for (f in man_new$rds[!rds_faits]) note("    ", f)
}
msg(sprintf("  volume .rds       : %.1f Mo",
            sum(file.size(man_new$rds[rds_faits])) / 1048576))

msg("")
msg("  Lignes par table :")
print(man_new[, .(table = basename(dta), lignes = rows, col = cols)])

msg("")
msg("  Les etapes du pipeline liront desormais ces .rds automatiquement :")
msg("  read_dta_chk() prefere build/<base>.rds et ne retombe sur le .dta que si")
msg("  le .rds est absent. Aucun appel a modifier dans les etapes.")
msg("")
msg("  Pour forcer une reconversion : relancer avec --force (ou supprimer le .rds")
msg("  concerne).")

hr("CONVERSION TERMINEE")
log_close()
