# ---------------------------------------------------------------------------
# 27_piste_c_hv201_reseau_controle.R -- piste C : controle de la table de
#   reference code/ref/piste_c_hv201_reseau.csv (decision du 06/10, memo
#   memo/piste_c_definition_issue.md) contre les codes hv201 observes dans
#   les caches des scripts 24 et 25.
#
# CONTROLE SEULEMENT : aucune variable construite, aucune part calculee,
# aucun compte par cote de la frontiere.
#
# ATTENTES (ECRITES AVANT EXECUTION ; arret dur si l'une tombe) :
#   R1  cle (vague, code) unique ; cote dans {reseau, hors reseau, titre} --
#       plus aucun AMBIGU depuis la decision du 06/10 ; cote_variante dans
#       {reseau, hors reseau, exclu, titre} et differente de cote seulement
#       pour NFHS-5 13 et le RO communautaire (NFHS-4 72, NFHS-5 92).
#   R2  chaque code etiquete de hv201, dans chaque vague, figure dans la table
#       avec le libelle exact du fichier ; et inversement.
#   R3  chaque code observe (non manquant) est etiquete, sauf les codes
#       non etiquetes deja connus : 99 en NFHS-3 (9 menages, manquant de fait).
#   R4  les codes « titre » n'ont aucune observation.
#
# LANCEMENT : Rscript code/27_piste_c_hv201_reseau_controle.R
# Sorties : output/logs/27_piste_c_hv201_reseau_controle.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
log_open(p_log("27_piste_c_hv201_reseau_controle.log"))
msg("ETAPE 27 -- PISTE C : CONTROLE DE LA TABLE RESEAU / HORS RESEAU (hv201)")

F_REF <- file.path("code", "ref", "piste_c_hv201_reseau.csv")
CACHES <- c(nfhs2 = p_build("25_cache_nfhs2.rds"), nfhs3 = p_build("24_cache_nfhs3.rds"),
            nfhs4 = p_build("24_cache_nfhs4.rds"), nfhs5 = p_build("24_cache_nfhs5.rds"))
NON_ETIQUETES_CONNUS <- list(nfhs3 = 99)
COTES <- c("reseau", "hors reseau", "titre")
COTES_VAR <- c("reseau", "hors reseau", "exclu", "titre")
VARIANTES_ATTENDUES <- c("nfhs5 13", "nfhs4 72", "nfhs5 92")

num <- function(x) as.numeric(haven::zap_labels(x))

ref <- fread(F_REF, colClasses = list(character = c("libelle", "note")))
check_vars(ref, c("vague", "code", "libelle", "cote", "cote_variante", "note"), "table de reference")
check_unique(ref, c("vague", "code"), "R1 table de reference")
check(all(ref$cote %in% COTES), "R1 cote dans {reseau, hors reseau, titre} (plus d'AMBIGU)",
      paste(setdiff(unique(ref$cote), COTES), collapse = ", "))
check(all(ref$cote_variante %in% COTES_VAR), "R1 cote_variante dans {reseau, hors reseau, exclu, titre}")
check(setequal(ref[cote != cote_variante, paste(vague, code)], VARIANTES_ATTENDUES),
      "R1 variante differente de cote seulement pour NFHS-5 13, NFHS-4 72, NFHS-5 92")
check(setequal(unique(ref$vague), names(CACHES)), "table de reference : quatre vagues")

for (v in names(CACHES)) {
  hr(v)
  check(file.exists(CACHES[[v]]), paste("cache present :", CACHES[[v]]))
  x <- readRDS(CACHES[[v]])$d$hv201
  l <- attr(x, "labels", exact = TRUE)
  e <- data.table(code = as.numeric(l), libelle = names(l))
  r <- ref[vague == v]
  m <- merge(e, r[, .(code, libelle_ref = libelle, cote)], by = "code", all = TRUE)
  ko <- m[is.na(libelle) | is.na(libelle_ref) | libelle != libelle_ref]
  if (nrow(ko)) print(ko, row.names = FALSE)
  check(nrow(ko) == 0L, sprintf("R2 %s : %d codes etiquetes = table, libelles exacts", v, nrow(e)))
  obs <- sort(unique(num(x)[!is.na(num(x))]))
  hors <- setdiff(obs, e$code)
  check(setequal(hors, NON_ETIQUETES_CONNUS[[v]] %||% numeric()),
        sprintf("R3 %s : codes observes non etiquetes = connus (%s)", v,
                if (length(hors)) paste(hors, collapse = ",") else "aucun"))
  titres <- r[cote == "titre", code]
  check(!any(num(x) %in% titres), sprintf("R4 %s : codes titre sans observation", v))
  msg(v, " : reseau = ", paste(r[cote == "reseau", code], collapse = ", "),
      " ; variante = ", if (any(r$cote != r$cote_variante)) paste(r[cote != cote_variante, paste0(code, " -> ", cote_variante)], collapse = ", ") else "aucune",
      " ; hors reseau = ", paste(r[cote == "hors reseau", code], collapse = ", "))
}

log_close()
