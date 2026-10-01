# ---------------------------------------------------------------------------
# 14_dhs_hv201_hv202.R -- DHS : cache allege des fichiers menages (HR) et
#   controle de couverture de hv201 (source d'eau de boisson) et hv202 (source
#   d'eau hors boisson), pour les neuf enquetes deposees dans raw/dhs/.
#
# OBJET : descriptif de couverture seulement. Aucune analyse, aucun graphique,
# aucune fusion. Motif : la carte standard des recodes place hv202 dans les
# recodes 2, 3, 5, 6, 7 mais PAS dans le recode 4 (Ghana 1998 et 2003,
# Indonesie 2003 a risque). La carte ne tranche pas : une variable peut etre
# presente hors carte, ou presente mais vide (question non posee). Seul le
# controle empirique decide ; le chiffre decisif est la part non manquante.
#
# CRITERE DE SIGNALEMENT (ecrit avant execution) :
#   hv202 presente et part non manquante (non NA) == 0      -> "VIDE"
#   hv202 presente et part non manquante (non NA) <  5 %    -> "QUASI VIDE"
#   hv202 absente du fichier                                -> "ABSENTE"
#   sinon                                                   -> "" (rien)
# « Non manquante » = valeur non NA. Les codes etiquetes « missing » sont
# comptes a part (colonne part_code_manquant) ; ils ne rendent pas la variable
# utilisable. Une part faible peut aussi venir d'un filtre du questionnaire
# (hv202 posee seulement si l'eau de boisson est en bouteille, en sachet ou
# rechargee) :
# la colonne hv202_nonNA_si_emballee le montre, sans rien decider.
#
# CACHE : chaque .DTA est lu UNE fois, en ne gardant que les colonnes VARS
# (haven::read_dta, col_select), et ecrit dans build/14_dhs_<ARCHIVE>.rds
# (etiquettes de valeurs conservees). Tout l'aval travaille sur ce cache.
# Une colonne demandee absente du fichier est journalisee, pas inventee.
#
# VALIDATION (arret dur) : nombre de lignes == nombre d'observations lu dans
# l'en-tete Stata (lecture binaire independante de haven) ; hhid unique ;
# hhid, hv000, hv007, hv201 presentes ; hv000 commence par le code pays du
# nom de fichier.
#
# AJOUT (01/10, apres le constat que hv202 change d'univers) :
#   14b' table de correspondance des codes (code/ref/dhs_codes_source_eau.csv),
#        validee contre chaque code observe ; arret si un code ou un libelle
#        manque ou differe.
#   14e  Ghana 2022, Indonesie 2017 : distribution de hv202 chez les menages
#        buvant de l'eau emballee, et part declarant la canalisation (facteur
#        de correction : reallocation contre retrait). Niveau dans une seule
#        vague, aucune comparaison entre vagues.
#   14f  hv201a (eau indisponible >= 1 jour sur deux semaines, recode 7+) :
#        presence, part non manquante, univers.
#   14g  Ghana 2008 contre 2022 a univers constant (emballes) : part declarant
#        la canalisation hors boisson, stricte (titre) et large (variante),
#        ponderee et non, IC par linearisation. Critere CONTAMINE (sens
#        seulement) : memo/piste_d_dhs_hv201_hv202.md. Verdict (Valentine) :
#        la stricte est disqualifiee (rupture « voisin ») ; seule la large
#        compte.
#   14h  Composition des emballes 2008 contre 2022 (richesse hv270, milieu
#        hv025, instruction du chef hv106 via hv101) : indice de dissimilarite,
#        regle du memo. Sorties 14_composition_*.csv.
#
# LANCEMENT (racine du depot) :
#     Rscript code/14_dhs_hv201_hv202.R           # reprend
#     Rscript code/14_dhs_hv201_hv202.R --force   # relit les .DTA
#
# Sorties : build/14_dhs_*.rds ;
#           output/tables/14_hv201_hv202_couverture.csv|.tex ;
#           output/tables/14_hv201_hv202_frequences.csv ;
#           output/tables/14_hv202_emballee_distribution.csv,
#             14_hv202_emballee_canalisation.csv|.tex ;
#           output/tables/14_hv201a_couverture.csv, _frequences.csv, _univers.csv ;
#           output/tables/14_ghana_2008_2022_emballee_canalisation.csv,
#             14_ghana_2008_2022_difference.csv|.tex ;
#           output/logs/14_dhs_hv201_hv202.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("14_dhs_hv201_hv202.log"))
msg("ETAPE 14 -- DHS : CACHE HR ALLEGE ET COUVERTURE DE hv201 / hv202")
msg("Descriptif seulement : ni analyse, ni graphique, ni fusion.")

# Colonnes gardees dans le cache. hv001 = identifiant de grappe.
VARS     <- c("hhid", "hv000", "hv001", "hv005", "hv007", "hv021",
              "hv024", "hv025", "hv201", "hv202", "hv201a", "hv270")
# Variables par membre (14h) : lien au chef (hv101_xx) et instruction (hv106_xx).
MOTIFS_MEMBRES <- "^hv10[16]_[0-9]+$"
CACHE_SPEC <- list(vars = VARS, motifs = MOTIFS_MEMBRES)
REQUISES <- c("hhid", "hv000", "hv005", "hv007", "hv201")
SEUIL_QUASI_VIDE <- 0.05

# Table de correspondance des codes de source d'eau entre vagues (codage de
# jugement, relu ligne a ligne ; lignes de jugement relues par Valentine le
# 01/10, colonnes `jugement` et `categories_possibles`). Chaque code observe
# doit y figurer avec le libelle exact du fichier, sinon arret.
F_CODES <- file.path("code", "ref", "dhs_codes_source_eau.csv")

# 14e : enquetes ou hv202 n'est posee qu'aux menages buvant de l'eau emballee
# (constat de la passe precedente), et definitions de la canalisation.
PORTEE_EMB    <- c("ghana_2022", "indonesia_2017")
CANAL_STRICTE <- c("canalisation_logement", "canalisation_cour", "borne_publique")
CANAL_LARGE   <- c(CANAL_STRICTE, "canalisation_voisin")

# Ordre de presentation demande : Ghana 2003, 2008, Indonesie 2003, 2017, puis
# le reste dans l'ordre pays-annee.
ORDRE_TETE <- c("ghana_2003", "ghana_2008", "indonesia_2003", "indonesia_2017")

# ---------------------------------------------------------------------------
hr("14a. Inventaire des fichiers HR extraits")
# ---------------------------------------------------------------------------

# Nombre d'observations et de variables lus dans l'en-tete binaire Stata
# (formats 110-115 : version, ordre des octets, type, inutilise, K sur 2 octets,
# N sur 4 octets). Independant de haven : sert de controle du nombre de lignes.
dta_entete <- function(f) {
  con <- file(f, "rb"); on.exit(close(con))
  h <- readBin(con, "raw", 10)
  fmt <- as.integer(h[1])
  check(fmt >= 110 && fmt <= 115, sprintf("%s : format Stata %d lisible par l'en-tete", basename(f), fmt),
        "format 117+ : lecteur d'en-tete a etendre")
  end <- if (as.integer(h[2]) == 2L) "little" else "big"
  list(format = fmt,
       K = readBin(h[5:6], "integer", size = 2, endian = end, signed = FALSE),
       N = readBin(h[7:10], "integer", size = 4, endian = end))
}

fs <- sort(list.files(p_raw("dhs"), pattern = "^[A-Z]{2}HR[0-9A-Z]{2}FL[.]DTA$",
                      recursive = TRUE, full.names = TRUE))
check(length(fs) == 9L, "9 fichiers HR .DTA trouves sous raw/dhs/",
      paste("trouves :", length(fs)))

inv <- data.table(dta = fs)
inv[, archive := basename(dirname(dta))]
inv[, annee   := as.integer(basename(dirname(dirname(dta))))]
inv[, pays    := basename(dirname(dirname(dirname(dta))))]
inv[, enquete := paste(pays, annee, sep = "_")]
inv[, code_pays := substr(basename(dta), 1, 2)]
check_unique(inv, "enquete", "inventaire HR")
ent <- rbindlist(lapply(inv$dta, function(f) as.data.table(dta_entete(f))))
inv <- cbind(inv, ent)
inv[, rang := match(enquete, ORDRE_TETE)]
setorder(inv, rang, pays, annee, na.last = TRUE)
inv[, rang := NULL]
print(inv[, .(enquete, archive, fichier = basename(dta), format, K, N)], row.names = FALSE)

# ---------------------------------------------------------------------------
hr("14b. Cache allege : une lecture par .DTA (stage)")
# ---------------------------------------------------------------------------

caches <- list()
for (i in seq_len(nrow(inv))) {
  r <- inv[i]
  out <- p_build(paste0("14_dhs_", r$archive, ".rds"))
  # Le cache connait la liste de colonnes demandee a sa construction : si VARS a
  # change depuis, il est reconstruit (une relecture du .DTA), jamais complete
  # en douce.
  if (file.exists(out) && !FORCE &&
      !identical(attr(readRDS(out), "colonnes_demandees"), CACHE_SPEC)) {
    tmsg("cache ", r$enquete, " : liste de colonnes changee, reconstruction")
    file.remove(out)
  }
  d <- stage(paste0("cache ", r$enquete), out, after = r$dta, build = function() {
    if (!requireNamespace("haven", quietly = TRUE))
      stop("PACKAGE INDISPONIBLE : haven n'a pas pu etre charge ; ", r$dta,
           " illisible. Arret -- aucune relance automatique.", call. = FALSE)
    x <- haven::read_dta(r$dta, col_select = c(tidyselect::any_of(VARS),
                                               tidyselect::matches(MOTIFS_MEMBRES)))
    attr(x, "colonnes_absentes") <- setdiff(VARS, names(x))
    attr(x, "colonnes_demandees") <- CACHE_SPEC
    x
  })
  absentes <- attr(d, "colonnes_absentes") %||% setdiff(VARS, names(d))
  msg(r$enquete, " : ", nrow(d), " lignes, colonnes gardees : ",
      paste(grep(MOTIFS_MEMBRES, names(d), value = TRUE, invert = TRUE), collapse = ", "),
      " + ", length(grep(MOTIFS_MEMBRES, names(d))), " colonnes par membre (hv101_*, hv106_*)")
  if (length(absentes)) warn(r$enquete, " : colonnes absentes du fichier : ",
                             paste(absentes, collapse = ", "))
  check_rows(d, r$N, paste(r$enquete, "(N de l'en-tete Stata)"))
  check_vars(d, REQUISES, r$enquete)
  check_unique(d, "hhid", r$enquete)
  h0 <- unique(as.character(haven::zap_labels(d$hv000)))
  check(length(h0) == 1L && startsWith(h0, r$code_pays),
        sprintf("%s : hv000 unique et prefixe %s", r$enquete, r$code_pays),
        paste("hv000 observe :", paste(h0, collapse = ", ")))
  caches[[r$enquete]] <- d
}

# ---------------------------------------------------------------------------
hr("14b'. Table de correspondance des codes (code/ref/dhs_codes_source_eau.csv)")
# ---------------------------------------------------------------------------

codes <- fread(F_CODES, colClasses = list(character = c("libelle", "lieu", "note")))
check_vars(codes, c("archive", "variable", "code", "libelle", "categorie", "groupe"),
           "table de correspondance")
check_unique(codes, c("archive", "variable", "code"), "table de correspondance")
check(!anyNA(codes$categorie) && !anyNA(codes$groupe),
      "table de correspondance : categorie et groupe toujours renseignes")
sans_na <- function(x) fifelse(is.na(x), "", x)
for (s in names(caches)) {
  d <- caches[[s]]; a <- inv[enquete == s, archive]
  for (v in intersect(c("hv201", "hv202"), names(d))) {
    l <- attr(d[[v]], "labels")
    x <- as.numeric(haven::zap_labels(d[[v]]))
    obs <- sort(unique(x[!is.na(x)]))
    lk <- codes[archive == a & variable == v]
    manque <- setdiff(obs, lk$code)
    check(length(manque) == 0L,
          sprintf("%s %s : %d codes observes tous dans la table", s, v, length(obs)),
          paste("codes absents de la table :", paste(manque, collapse = ", ")))
    lib_fichier <- sans_na(names(l)[match(obs, unname(l))])
    lib_table   <- sans_na(lk$libelle[match(obs, lk$code)])
    ecart <- obs[lib_fichier != lib_table]
    check(length(ecart) == 0L, sprintf("%s %s : libelles identiques au fichier", s, v),
          paste("codes au libelle different :", paste(ecart, collapse = ", ")))
  }
}

# Categorie et groupe harmonises d'une variable de source, via la table.
classe <- function(d, s, v) {
  lk <- codes[archive == inv[enquete == s, archive] & variable == v]
  x <- as.numeric(haven::zap_labels(d[[v]]))
  i <- match(x, lk$code)
  data.table(code = x, libelle = lk$libelle[i], categorie = lk$categorie[i],
             groupe = lk$groupe[i])
}

# Statut d'une variable dans le dictionnaire .MAP livre avec le fichier (texte,
# pas les donnees). La DHS prefixe « NA - » le libelle d'une variable gardee
# dans la structure mais non posee.
statut_dico <- function(dta, var) {
  lignes <- readLines(sub("[.]DTA$", ".MAP", dta), warn = FALSE)
  l <- grep(paste0("^", toupper(var), "[[:space:]]"), lignes, value = TRUE)
  if (!length(l)) return("absente du dictionnaire")
  if (grepl("[[:space:]]NA - ", l[1])) "marquee NA (non posee)" else "presente"
}

# ---------------------------------------------------------------------------
hr("14c. Couverture de hv201 et hv202 (depuis le cache)")
# ---------------------------------------------------------------------------

etiquettes <- function(x) {
  l <- attr(x, "labels")
  if (is.null(l)) return(data.table(code = numeric(), libelle = character()))
  data.table(code = as.numeric(unname(l)), libelle = names(l))
}

# Codes dont l'etiquette dit « manquant » : comptes a part, jamais requalifies.
codes_manquants <- function(x) {
  e <- etiquettes(x)
  e[grepl("missing|manquant", libelle, ignore.case = TRUE), code]
}

couv_var <- function(d, v) {
  if (!v %in% names(d))
    return(list(present = FALSE, n_nonNA = NA_integer_, part_nonNA = NA_real_,
                part_code_manquant = NA_real_, n_codes_observes = NA_integer_))
  x <- as.numeric(haven::zap_labels(d[[v]]))
  list(present = TRUE,
       n_nonNA = sum(!is.na(x)),
       part_nonNA = mean(!is.na(x)),
       part_code_manquant = mean(x %in% codes_manquants(d[[v]])),
       n_codes_observes = uniqueN(x[!is.na(x)]))
}

couv <- rbindlist(lapply(names(caches), function(s) {
  d <- caches[[s]]
  a <- couv_var(d, "hv201"); b <- couv_var(d, "hv202")
  # hv202 parmi les menages dont l'eau de boisson est emballee (bouteille,
  # sachet, rechargee : groupe « emballee » de la table) : montre un eventuel
  # filtre de questionnaire.
  emb <- classe(d, s, "hv201")[, groupe %in% "emballee"]
  n_emb <- sum(emb)
  nonNA_emb <- if (b$present && n_emb > 0) mean(!is.na(d$hv202[emb])) else NA_real_
  dta <- inv[enquete == s, dta]
  data.table(
    enquete = s, archive = inv[enquete == s, archive], N = nrow(d),
    hv202_dictionnaire = statut_dico(dta, "hv202"),
    hv201_present = a$present, hv201_part_nonNA = a$part_nonNA,
    hv201_part_code_manquant = a$part_code_manquant, hv201_n_codes = a$n_codes_observes,
    hv202_present = b$present, hv202_part_nonNA = b$part_nonNA,
    hv202_part_code_manquant = b$part_code_manquant, hv202_n_codes = b$n_codes_observes,
    n_hv201_emballee = n_emb, hv202_nonNA_si_emballee = nonNA_emb,
    signal = if (!b$present) "ABSENTE" else if (b$n_nonNA == 0) "VIDE"
             else if (b$part_nonNA < SEUIL_QUASI_VIDE) "QUASI VIDE" else ""
  )
}))
print(couv, row.names = FALSE)
fwrite(couv, p_tab("14_hv201_hv202_couverture.csv"))

pct <- function(x) ifelse(is.na(x), "--", sprintf("%.1f", 100 * x))
oui <- function(x) ifelse(x, "oui", "non")
tex <- c("\\begin{tabular}{lrlrrlrrrl}", "\\toprule",
         paste0("Enqu\\^ete & N & hv201 & non NA (\\%) & code manq. (\\%) & ",
                "hv202 & non NA (\\%) & code manq. (\\%) & non NA si emball\\'ee (\\%) & Signal \\\\"),
         "\\midrule",
         couv[, sprintf("%s & %s & %s & %s & %s & %s & %s & %s & %s & %s \\\\",
                        gsub("_", " ", enquete), format(N, big.mark = "\\,"),
                        oui(hv201_present), pct(hv201_part_nonNA), pct(hv201_part_code_manquant),
                        oui(hv202_present), pct(hv202_part_nonNA), pct(hv202_part_code_manquant),
                        pct(hv202_nonNA_si_emballee), signal)],
         "\\bottomrule", "\\end{tabular}")
writeLines(tex, p_tab("14_hv201_hv202_couverture.tex"))

# ---------------------------------------------------------------------------
hr("14d. Tables de frequence des codes, avec etiquettes")
# ---------------------------------------------------------------------------

freq_var <- function(d, s, v) {
  if (!v %in% names(d))
    return(data.table(enquete = s, variable = v, code = NA_real_,
                      libelle = "(variable absente du fichier)", n = NA_integer_, part = NA_real_))
  x <- as.numeric(haven::zap_labels(d[[v]]))
  f <- data.table(code = x)[, .(n = .N), by = code]
  f <- merge(f, etiquettes(d[[v]]), by = "code", all.x = TRUE)
  f[is.na(code), libelle := "(NA systeme)"]
  f[is.na(libelle), libelle := "(sans etiquette)"]
  f[, part := n / nrow(d)]
  setorder(f, code, na.last = TRUE)
  cbind(data.table(enquete = s, variable = v), f)
}

freq <- rbindlist(lapply(names(caches), function(s)
  rbind(freq_var(caches[[s]], s, "hv201"), freq_var(caches[[s]], s, "hv202"))))
fwrite(freq, p_tab("14_hv201_hv202_frequences.csv"))
for (s in names(caches)) {
  msg("\n== ", s)
  print(freq[enquete == s, .(variable, code, libelle, n, part = round(part, 4))],
        row.names = FALSE)
}

# ---------------------------------------------------------------------------
hr("14e. hv202 dans l'univers restreint : menages buvant de l'eau emballee")
# ---------------------------------------------------------------------------
# Ghana 2022 et Indonesie 2017 : hv202 n'est posee qu'aux menages dont hv201 est
# emballee. Distribution de hv202 dans cet univers, non ponderee et ponderee
# (hv005 / 1e6), et part declarant la canalisation pour les usages hors boisson.
# Canalisation stricte = logement, cour, borne publique ; large = + voisin.

distrib <- list(); canal <- list()
for (s in PORTEE_EMB) {
  d <- caches[[s]]
  c201 <- classe(d, s, "hv201"); c202 <- classe(d, s, "hv202")
  emb <- c201$groupe %in% "emballee"
  w <- as.numeric(d$hv005) / 1e6
  # Premisse verifiee, pas supposee : hv202 posee aux emballes, a eux seuls.
  check(mean(!is.na(c202$code[!emb])) < 0.01 && mean(!is.na(c202$code[emb])) > 0.99,
        sprintf("%s : hv202 renseignee pour > 99 %% des emballes et < 1 %% des autres", s),
        sprintf("non NA : %.4f chez les emballes, %.4f chez les autres",
                mean(!is.na(c202$code[emb])), mean(!is.na(c202$code[!emb]))))
  e <- cbind(c202[emb], w = w[emb])
  e[is.na(code), `:=`(libelle = "(NA systeme)", categorie = "manquant", groupe = "manquant")]
  dist <- e[, .(n = .N, w = sum(w)), by = .(code, libelle, categorie, groupe)]
  dist[, `:=`(part = n / sum(n), part_ponderee = w / sum(w))][, w := NULL]
  setorder(dist, code, na.last = TRUE)
  distrib[[s]] <- cbind(data.table(enquete = s, N_emballee = nrow(e)), dist)
  for (def in c("stricte", "large")) {
    cats <- if (def == "stricte") CANAL_STRICTE else CANAL_LARGE
    k <- e$categorie %in% cats
    canal[[paste(s, def)]] <- data.table(
      enquete = s, definition = def, categories = paste(cats, collapse = "+"),
      N_emballee = nrow(e), n_hv202_nonNA = sum(!is.na(e$code)),
      n_canalisation = sum(k), part = mean(k), part_ponderee = sum(e$w[k]) / sum(e$w))
  }
}
distrib <- rbindlist(distrib); canal <- rbindlist(canal)
for (s in PORTEE_EMB) {
  msg("\n== ", s, " : distribution de hv202 chez les menages buvant de l'eau emballee")
  print(distrib[enquete == s, .(code, libelle, categorie, n,
                                part = round(part, 4), part_ponderee = round(part_ponderee, 4))],
        row.names = FALSE)
}
msg("")
print(canal, row.names = FALSE)
fwrite(distrib, p_tab("14_hv202_emballee_distribution.csv"))
fwrite(canal, p_tab("14_hv202_emballee_canalisation.csv"))
tex <- c("\\begin{tabular}{llrrrrr}", "\\toprule",
         paste0("Enqu\\^ete & Canalisation & N emball\\'ee & hv202 non NA & n canalis\\'ee & ",
                "Part (\\%) & Part pond\\'er\\'ee (\\%) \\\\"), "\\midrule",
         canal[, sprintf("%s & %s & %s & %s & %s & %.1f & %.1f \\\\",
                         gsub("_", " ", enquete), definition,
                         format(N_emballee, big.mark = "\\,"), format(n_hv202_nonNA, big.mark = "\\,"),
                         format(n_canalisation, big.mark = "\\,"), 100 * part, 100 * part_ponderee)],
         "\\bottomrule", "\\end{tabular}")
writeLines(tex, p_tab("14_hv202_emballee_canalisation.tex"))

# ---------------------------------------------------------------------------
hr("14f. hv201a : eau indisponible au moins un jour sur les deux dernieres semaines")
# ---------------------------------------------------------------------------
# Presence (fichier et dictionnaire), part non manquante, codes, et univers :
# part non NA selon le groupe de la source de boisson (hv201) et, chez les
# emballes, selon le groupe de la source hors boisson (hv202).

a_couv <- rbindlist(lapply(names(caches), function(s) {
  d <- caches[[s]]; pres <- "hv201a" %in% names(d)
  data.table(enquete = s, dictionnaire = statut_dico(inv[enquete == s, dta], "hv201a"),
             present = pres, N = nrow(d),
             part_nonNA = if (pres) mean(!is.na(d$hv201a)) else NA_real_)
}))
print(a_couv, row.names = FALSE)
fwrite(a_couv, p_tab("14_hv201a_couverture.csv"))

a_freq <- rbindlist(lapply(a_couv[present == TRUE, enquete], function(s)
  freq_var(caches[[s]], s, "hv201a")))
if (nrow(a_freq)) {
  print(a_freq[, .(enquete, code, libelle, n, part = round(part, 4))], row.names = FALSE)
  fwrite(a_freq, p_tab("14_hv201a_frequences.csv"))
}

a_univ <- rbindlist(lapply(a_couv[present == TRUE & part_nonNA > 0, enquete], function(s) {
  d <- caches[[s]]; c201 <- classe(d, s, "hv201")
  u1 <- data.table(groupe = c201$groupe, ok = !is.na(d$hv201a))[
    , .(n = .N, n_nonNA = sum(ok), part_nonNA = mean(ok)), by = groupe]
  u1 <- cbind(data.table(enquete = s, selon = "hv201 (tous menages)"), u1)
  out <- list(u1)
  if ("hv202" %in% names(d)) {
    emb <- c201$groupe %in% "emballee"
    c202 <- classe(d, s, "hv202")
    g2 <- fifelse(is.na(c202$groupe[emb]), "(hv202 NA)", c202$groupe[emb])
    u2 <- data.table(groupe = g2, ok = !is.na(d$hv201a[emb]))[
      , .(n = .N, n_nonNA = sum(ok), part_nonNA = mean(ok)), by = groupe]
    out[[2]] <- cbind(data.table(enquete = s, selon = "hv202 (emballes seulement)"), u2)
  }
  rbindlist(out)
}))
if (nrow(a_univ)) {
  setorder(a_univ, enquete, selon, groupe)
  print(a_univ[, .(enquete, selon, groupe, n, n_nonNA, part_nonNA = round(part_nonNA, 4))],
        row.names = FALSE)
  fwrite(a_univ, p_tab("14_hv201a_univers.csv"))
}

# ---------------------------------------------------------------------------
hr("14g. Ghana 2008 contre 2022, univers constant : emballes, canalisation hors boisson")
# ---------------------------------------------------------------------------
# Critere : memo/piste_d_dhs_hv201_hv202.md, section « Critere : reallocation
# contre retrait » (CONTAMINE : ecrit apres avoir vu 2022 ; sens seulement,
# aucun seuil). Titre = stricte, variante = large. 2008 : hv202 universelle,
# restreinte ici aux emballes ; 2022 : univers restreint par le questionnaire.
# IC 95 % par linearisation, grappes = hv021, domaine estime sur l'echantillon
# complet (z = 0 hors domaine), strates ignorees (absentes du cache).

part_ic <- function(y, dom, w, psu) {
  wd <- w * dom
  p <- sum(wd * y) / sum(wd)
  z <- wd * (y - p) / sum(wd)
  zc <- tapply(z, psu, sum)
  nc <- length(zc)
  list(p = p, se = sqrt(nc / (nc - 1) * sum(zc^2)), n_psu = nc)
}

COMPARE <- c("ghana_2008", "ghana_2022")
cmp <- rbindlist(lapply(COMPARE, function(s) {
  d <- caches[[s]]
  c201 <- classe(d, s, "hv201"); c202 <- classe(d, s, "hv202")
  dom <- as.numeric(c201$groupe %in% "emballee")
  check(!anyNA(d$hv021), sprintf("%s : hv021 (PSU) sans NA", s))
  check(sum(!is.na(c202$code[dom == 1])) / sum(dom) > 0.99,
        sprintf("%s : hv202 renseignee pour > 99 %% des emballes", s))
  rbindlist(lapply(c("stricte", "large"), function(def) {
    cats <- if (def == "stricte") CANAL_STRICTE else CANAL_LARGE
    y <- as.numeric(c202$categorie %in% cats)
    rbindlist(lapply(c("non ponderee", "ponderee"), function(pd) {
      w <- if (pd == "ponderee") as.numeric(d$hv005) / 1e6 else rep(1, nrow(d))
      r <- part_ic(y, dom, w, d$hv021)
      data.table(enquete = s, definition = def, ponderation = pd,
                 categories_presentes = paste(intersect(cats, unique(c202$categorie[dom == 1])),
                                              collapse = "+"),
                 N_emballee = sum(dom), n_canalisation = sum(y * dom),
                 part = r$p, se = r$se, ic_bas = r$p - 1.96 * r$se,
                 ic_haut = r$p + 1.96 * r$se, n_psu = r$n_psu)
    }))
  }))
}))
print(cmp[, .(enquete, definition, ponderation, N_emballee, n_canalisation,
              part = round(part, 4), ic_bas = round(ic_bas, 4), ic_haut = round(ic_haut, 4),
              n_psu, categories_presentes)], row.names = FALSE)

dif <- dcast(cmp, definition + ponderation ~ enquete, value.var = c("part", "se"))
dif[, `:=`(diff = part_ghana_2022 - part_ghana_2008,
           se_diff = sqrt(se_ghana_2022^2 + se_ghana_2008^2))]
dif[, `:=`(ic_bas = diff - 1.96 * se_diff, ic_haut = diff + 1.96 * se_diff)]
setorder(dif, -definition, ponderation)
msg("\nDifference 2022 - 2008 (points de part, IC 95 %) :")
print(dif[, .(definition, ponderation, part_2008 = round(part_ghana_2008, 4),
              part_2022 = round(part_ghana_2022, 4), diff = round(diff, 4),
              ic_bas = round(ic_bas, 4), ic_haut = round(ic_haut, 4))], row.names = FALSE)
fwrite(cmp, p_tab("14_ghana_2008_2022_emballee_canalisation.csv"))
fwrite(dif, p_tab("14_ghana_2008_2022_difference.csv"))
tex <- c("\\begin{tabular}{llrrrrr}", "\\toprule",
         paste0("D\\'efinition & Pond\\'eration & 2008 (\\%) & 2022 (\\%) & ",
                "Diff. (pts) & IC 95 \\% bas & IC 95 \\% haut \\\\"), "\\midrule",
         dif[, sprintf("%s & %s & %.1f & %.1f & %.1f & %.1f & %.1f \\\\", definition,
                       ponderation, 100 * part_ghana_2008, 100 * part_ghana_2022,
                       100 * diff, 100 * ic_bas, 100 * ic_haut)],
         "\\bottomrule", "\\end{tabular}",
         sprintf("%% N emballes : 2008 = %d, 2022 = %d. IC par linearisation, grappes hv021, strates ignorees.",
                 cmp[enquete == "ghana_2008", N_emballee[1]], cmp[enquete == "ghana_2022", N_emballee[1]]))
writeLines(tex, p_tab("14_ghana_2008_2022_difference.tex"))

# ---------------------------------------------------------------------------
hr("14h. Composition : emballes 2008 contre emballes 2022 (Ghana)")
# ---------------------------------------------------------------------------
# Critere : memo/piste_d_dhs_hv201_hv202.md, « Test de composition ». Indice de
# dissimilarite D = 1/2 somme |p2008 - p2022| par dimension ; D >= 0,20 sur une
# dimension -> populations differentes, exercice nul ; [0,10 ; 0,20) -> limite ;
# sinon comparables. Pondere en titre, non pondere rapporte.
SEUIL_D_NUL <- 0.20
SEUIL_D_LIMITE <- 0.10

# Instruction du chef : hv106 du membre dont hv101 = 1 (« head »).
instruction_chef <- function(d, s) {
  rel <- grep("^hv101_[0-9]+$", names(d), value = TRUE)
  edu <- sub("^hv101_", "hv106_", rel)
  check(length(rel) > 0 && all(edu %in% names(d)),
        sprintf("%s : %d paires hv101_xx / hv106_xx dans le cache", s, length(rel)))
  l <- attr(d[[rel[1]]], "labels")
  check(grepl("head", names(l)[match(1, unname(l))], ignore.case = TRUE),
        sprintf("%s : hv101 = 1 etiquete « head »", s),
        paste("etiquette de 1 :", names(l)[match(1, unname(l))]))
  num <- function(v) sapply(d[v], function(x) as.numeric(haven::zap_labels(x)))
  R <- num(rel); E <- num(edu)
  chef <- !is.na(R) & R == 1
  n_chef <- rowSums(chef)
  e <- E[cbind(seq_len(nrow(E)), max.col(chef, ties.method = "first"))]
  e[n_chef == 0] <- NA
  list(code = e, n_chef = n_chef, labels = attr(d[[edu[1]]], "labels"))
}

comp_dist <- list(); comp_d <- list()
dims <- list()
for (s in COMPARE) {
  d <- caches[[s]]
  check_vars(d, c("hv270", "hv025"), s)
  dom <- classe(d, s, "hv201")$groupe %in% "emballee"
  ic <- instruction_chef(d, s)
  part1 <- mean(ic$n_chef[dom] == 1)
  check(part1 > 0.99, sprintf("%s : un seul chef pour > 99 %% des emballes", s),
        sprintf("part avec exactement un chef : %.4f", part1))
  note(s, " : emballes sans chef identifie : ", sum(ic$n_chef[dom] == 0),
       " ; avec plus d'un : ", sum(ic$n_chef[dom] > 1))
  lab <- function(x) attr(x, "labels")
  dims[[s]] <- list(
    richesse = list(code = as.numeric(haven::zap_labels(d$hv270)), labels = lab(d$hv270)),
    milieu = list(code = as.numeric(haven::zap_labels(d$hv025)), labels = lab(d$hv025)),
    instruction_chef = list(code = ic$code, labels = ic$labels))
  w <- as.numeric(d$hv005) / 1e6
  for (dm in names(dims[[s]])) {
    x <- dims[[s]][[dm]]
    t <- data.table(code = x$code[dom], w = w[dom])[, .(n = .N, w = sum(w)), by = code]
    t[, `:=`(part = n / sum(n), part_ponderee = w / sum(w))][, w := NULL]
    t[, libelle := names(x$labels)[match(code, unname(x$labels))]]
    t[is.na(code), libelle := "(manquant)"]
    comp_dist[[paste(s, dm)]] <- cbind(data.table(enquete = s, dimension = dm,
                                                  N_emballee = sum(dom)), t)
  }
}
comp_dist <- rbindlist(comp_dist)
setorder(comp_dist, dimension, enquete, code, na.last = TRUE)

# Memes codes, memes libelles entre les deux vagues : sinon la comparaison
# categorie par categorie n'a pas de sens -> arret. Seule exception : les
# equivalences de libelle ci-dessous, une par une, justifiees et journalisees
# (premiere execution arretee sur ce point le 01/10 ; validee par Valentine).
EQUIV_LIBELLES <- list(
  instruction_chef = c(
    "no education, preschool/early childhood education" = "no education, preschool"))
for (dm in unique(comp_dist$dimension)) {
  l8 <- dims[[COMPARE[1]]][[dm]]$labels; l22 <- dims[[COMPARE[2]]][[dm]]$labels
  obs <- unique(comp_dist[dimension == dm & !is.na(code), code])
  n8 <- tolower(names(l8)[match(obs, l8)]); n22 <- tolower(names(l22)[match(obs, l22)])
  eq <- EQUIV_LIBELLES[[dm]]
  if (length(eq)) for (k in names(eq)) if (any(n22 == k)) {
    warn("[EQUIV] ", dm, " : « ", k, " » (2022) traite comme « ", eq[[k]], " » (2008) ;",
         " « early childhood education » = prescolaire, code 0 dans les deux vagues")
    n22[n22 == k] <- eq[[k]]
  }
  same <- identical(n8, n22)
  check(same, sprintf("%s : codes observes de meme libelle en 2008 et 2022", dm),
        paste("2008 :", paste(names(l8)[match(obs, l8)], collapse = "/"),
              "| 2022 :", paste(names(l22)[match(obs, l22)], collapse = "/")))
}

# Libelle ajoute apres coup (il peut differer par la casse, verifie ci-dessus).
wide <- dcast(comp_dist, dimension + code ~ enquete,
              value.var = c("n", "part", "part_ponderee"), fill = 0)
libs <- unique(comp_dist[order(-(enquete == COMPARE[1]))], by = c("dimension", "code"))
wide[libs, libelle := i.libelle, on = .(dimension, code)]
D <- wide[, .(D_ponderee = 0.5 * sum(abs(part_ponderee_ghana_2008 - part_ponderee_ghana_2022)),
              D_non_ponderee = 0.5 * sum(abs(part_ghana_2008 - part_ghana_2022))),
          by = dimension]
classe_D <- function(x) fifelse(x >= SEUIL_D_NUL, "differentes",
                                fifelse(x >= SEUIL_D_LIMITE, "limite", "comparables"))
D[, `:=`(classe_ponderee = classe_D(D_ponderee), classe_non_ponderee = classe_D(D_non_ponderee))]

for (dm in unique(wide$dimension)) {
  msg("\n== ", dm, " (emballes : 2008 N = ", comp_dist[enquete == "ghana_2008", N_emballee[1]],
      ", 2022 N = ", comp_dist[enquete == "ghana_2022", N_emballee[1]], ")")
  print(wide[dimension == dm, .(code, libelle, n_2008 = n_ghana_2008, n_2022 = n_ghana_2022,
                                p_2008 = round(part_ghana_2008, 4), p_2022 = round(part_ghana_2022, 4),
                                pw_2008 = round(part_ponderee_ghana_2008, 4),
                                pw_2022 = round(part_ponderee_ghana_2022, 4))], row.names = FALSE)
}
msg("")
print(D[, .(dimension, D_ponderee = round(D_ponderee, 3), classe_ponderee,
            D_non_ponderee = round(D_non_ponderee, 3), classe_non_ponderee)], row.names = FALSE)
pire <- function(cl) if ("differentes" %in% cl) "differentes" else if ("limite" %in% cl) "limite" else "comparables"
v_p <- pire(D$classe_ponderee); v_np <- pire(D$classe_non_ponderee)
verdict_compo <- if (v_p != v_np) paste0("INSTABLE (pondere : ", v_p, " ; non pondere : ", v_np, ")") else
  switch(v_p, differentes = "POPULATIONS DIFFERENTES -- exercice nul",
         limite = "LIMITE", comparables = "COMPARABLES")
msg("\nVERDICT COMPOSITION (critere du memo) : ", verdict_compo)
fwrite(wide, p_tab("14_composition_emballes.csv"))
fwrite(D, p_tab("14_composition_dissimilarite.csv"))

hr("Signalements (critere ecrit en tete de script)")
sig <- couv[signal != ""]
if (nrow(sig)) for (i in seq_len(nrow(sig)))
  warn(sig$enquete[i], " : hv202 ", sig$signal[i],
       " (part non NA = ", pct(sig$hv202_part_nonNA[i]), " %)") else
  note("aucun")

hr("Fichiers ecrits")
for (f in c(p_build(paste0("14_dhs_", inv$archive, ".rds")),
            p_tab(c("14_hv201_hv202_couverture.csv", "14_hv201_hv202_couverture.tex",
                    "14_hv201_hv202_frequences.csv", "14_hv202_emballee_distribution.csv",
                    "14_hv202_emballee_canalisation.csv", "14_hv202_emballee_canalisation.tex",
                    "14_hv201a_couverture.csv", "14_hv201a_frequences.csv",
                    "14_hv201a_univers.csv")))) note(f)
log_close()
