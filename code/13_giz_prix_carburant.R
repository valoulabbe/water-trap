# ---------------------------------------------------------------------------
# 13_giz_prix_carburant.R -- piste D : panel des prix des carburants (GIZ)
#   et variation propre a chaque pays entre deux vagues DHS, six cas retenus.
#
# OBJET (decision du 30/09) : MESURER la variation idiosyncratique des prix,
# pas construire un decaleur de cout. Le diesel deplace aussi le cout du cote
# public (pompage, groupes electrogenes) : cas interdit. Aucune mesure
# d'exposition, aucune interaction, aucune estimation.
#
# CRITERE : memo/piste_d_carburant_critere.md. Les seuils y sont LUS ; la
# section 13c refuse de tourner tant que le memo ne dit pas « Statut : FIXÉ ».
#
# SOURCES
#   raw/wdi_archive/ : archive WDI version 202407, EP.PMP.DESL.CD et
#                      EP.PMP.SGAS.CD (US$/litre, source GIZ), JSON de l'API.
#   raw/giz/*.xlsx   : fichier GIZ/TUMI « Fuel prices from 1991 to 2020 »
#                      (depot manuel). Structure non encore verifiee : tant que
#                      GIZ_FORMAT_VERIFIE vaut FALSE, le script en fait
#                      l'inventaire (feuilles, premieres lignes) et s'ARRETE.
#   API DHS (rdhs)   : dates de terrain des vagues et codes ISO3.
#   output/tables/12_substituts_delta.csv, 12_dhs_ws_national.csv : cas et vagues.
#
# COMPOSANTE FISCALE : la GIZ ne publie pas de montant de taxe par pays (seulement
# une categorie 1-4 derivee du prix lui-meme). Le WDI n'a que le prix. Aucune
# colonne fiscale n'est donc construite ; voir le journal des lacunes.
#
# LANCEMENT (racine du depot) :
#     Rscript code/13_giz_prix_carburant.R           # reprend
#     Rscript code/13_giz_prix_carburant.R --force   # refait les etapes
#
# ETAPES RESUMABLES (build/) :
#   1. 13_wdi.rds          archive WDI lue et validee (pays seulement)
#   2. 13_dhs_enquetes.rds dhs_surveys() + dhs_countries() (API)
# Sections : 13a sources, 13b table pays-annee + lacunes, 13c-pre calendrier
# des relevees par rapport aux vagues (sans valeur de prix), 13c variation
# (bloquee par le critere).
#
# Sorties : output/tables/13_*.csv|.tex, output/figures/13_*.pdf,
#           output/logs/13_giz_prix_carburant.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(ggplot2)
}))
ensure_dirs()
for (d in file.path("output", c("tables", "figures")))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)
p_fig <- function(...) file.path("output", "figures", ...)

log_open(p_log("13_giz_prix_carburant.log"))
msg("ETAPE 13 -- PISTE D : PRIX DES CARBURANTS (GIZ), VARIATION ENTRE VAGUES DHS")
msg("Mesure seulement. Critere : memo/piste_d_carburant_critere.md")

GIZ_FORMAT_VERIFIE <- FALSE  # passe a TRUE une fois le lecteur GIZ ecrit sur le vrai fichier

F_WDI  <- c(diesel = p_raw("wdi_archive", "wdi_arch_202407_EP.PMP.DESL.CD.json"),
            essence = p_raw("wdi_archive", "wdi_arch_202407_EP.PMP.SGAS.CD.json"))
F_PAYS <- p_raw("wdi_archive", "wdi_pays_metadata.json")
MEMO   <- file.path("memo", "piste_d_carburant_critere.md")

# Releves GIZ attendus, d'apres les publications (rapport 1999 : 1991, 1993,
# 1995, 1998 ; puis biennal 2000-2020, dernier releve novembre 2020).
RELEVES_GIZ <- c(1991L, 1993L, 1995L, 1998L, seq(2000L, 2020L, by = 2L))
JOUR_RELEVE <- "-11-15"  # enquete GIZ « mid-November »

# SHA256 attendu : lu dans raw/README.md, ligne du tableau dont la 1re cellule
# est le chemin relatif a raw/. Pas de hash, pas de lecture.
sha_attendu <- function(chemin) {
  rel <- sub("^raw/", "", chemin)
  lig <- grep(paste0("^\\|\\s*", gsub("([.])", "\\\\\\1", rel), "\\s*\\|"),
              readLines(p_raw("README.md"), encoding = "UTF-8"), value = TRUE)
  check(length(lig) == 1L, paste0("raw/README.md : une ligne de manifeste pour ", rel),
        sprintf("%d ligne(s) trouvee(s)", length(lig)))
  h <- regmatches(lig, regexpr("[0-9A-Fa-f]{64}", lig))
  check(length(h) == 1L, paste0("raw/README.md : SHA256 renseigne pour ", rel))
  toupper(h)
}
check_sha <- function(chemin) {
  # as.vector : l'objet hash d'openssl garde des attributs que identical() verrait
  obs <- toupper(as.vector(as.character(openssl::sha256(file(chemin)))))
  check(identical(obs, as.vector(sha_attendu(chemin))), paste0("SHA256 conforme : ", chemin),
        paste("observe", obs))
}

# ===========================================================================
# 13a. Sources
# ===========================================================================
hr("13a. Sources : archive WDI, fichier GIZ/TUMI, API DHS")

for (f in c(F_WDI, F_PAYS)) {
  check(file.exists(f), paste("present :", f))
  check_sha(f)
}

wdi <- stage("etape 1/2 archive WDI", p_build("13_wdi.rds"), function() {
  pays <- jsonlite::fromJSON(F_PAYS)
  check(length(pays) == 2L && pays[[1]]$pages == 1L, "metadonnees pays : une seule page")
  pays <- pays[[2]]  # data.frame a colonne imbriquee region (id, iso2code, value)
  check_vars(pays, c("id", "name", "region"), "metadonnees pays")
  meta <- data.table(iso3 = pays$id, nom_wdi = pays$name, region = pays$region$value)
  check(!anyNA(meta$region) && any(meta$region == "Aggregates"),
        "metadonnees pays : region renseignee, categorie Aggregates presente")
  check_unique(meta, "iso3", "metadonnees pays")
  out <- rbindlist(lapply(names(F_WDI), function(carb) {
    j <- jsonlite::fromJSON(F_WDI[[carb]], simplifyVector = FALSE)
    check(j$pages == 1L && j$total == 19564L && length(j$source$data) == 19564L,
          sprintf("WDI %s : une page, 19 564 lignes", carb),
          sprintf("pages %s, total %s, lignes %d", j$pages, j$total, length(j$source$data)))
    rows <- j$source$data
    v <- function(r, concept) {
      x <- Filter(function(z) z$concept == concept, r$variable)
      if (length(x) == 1L) x[[1]]$id else NA_character_
    }
    data.table(iso3 = vapply(rows, v, "", concept = "Country"),
               temps = vapply(rows, v, "", concept = "Time"),
               version = vapply(rows, v, "", concept = "Version"),
               prix_usd = vapply(rows, function(r) if (is.null(r$value)) NA_real_ else as.numeric(r$value), 0),
               carburant = carb)
  }))
  check(all(out$version == "202407"), "WDI : toutes les lignes en version 202407")
  check(all(grepl("^YR[0-9]{4}$", out$temps)), "WDI : champ Time au format YRyyyy")
  out[, annee := as.integer(sub("^YR", "", temps))]
  out[, c("temps", "version") := NULL]
  # L'archive porte 28 codes absents des metadonnees courantes (anciens codes
  # ZAR, ROM, TMP..., DOM francais, agregats retires). Verifie le 30/09 : un
  # seul porte des valeurs, FCS (agregat « Fragile and conflict affected
  # situations »), exclu ici par son nom. Tout autre code inconnu AVEC valeur
  # arrete le script.
  AGREGATS_ARCHIVE <- "FCS"
  inconnus <- setdiff(out[!is.na(prix_usd), iso3], meta$iso3)
  check(setequal(inconnus, AGREGATS_ARCHIVE),
        "WDI : codes avec valeur hors metadonnees = agregats d'archive connus (FCS)",
        paste("observes :", paste(inconnus, collapse = ", ")))
  note(sprintf("codes d'archive sans aucune valeur, ignores : %d",
               length(setdiff(unique(out$iso3), c(meta$iso3, AGREGATS_ARCHIVE)))))
  out <- out[!iso3 %in% AGREGATS_ARCHIVE]
  out <- merge(out, meta, by = "iso3")
  n_agr <- uniqueN(out[region == "Aggregates", iso3])
  note(sprintf("agregats regionaux exclus : %d codes", n_agr))
  out <- out[region != "Aggregates" & !is.na(prix_usd)]
  check_unique(out, c("iso3", "annee", "carburant"), "WDI pays")
  check(all(out$prix_usd > 0), "WDI : prix strictement positifs")
  out[, source := "wdi"]
  out[]
})
msg(sprintf("  WDI : %d valeurs pays (diesel %d, essence %d), %d pays",
            nrow(wdi), wdi[carburant == "diesel", .N], wdi[carburant == "essence", .N],
            uniqueN(wdi$iso3)))
print(dcast(wdi[, .N, by = .(annee, carburant)], annee ~ carburant, value.var = "N"))

# --- fichier GIZ/TUMI ---------------------------------------------------------
f_giz <- list.files(p_raw("giz"), pattern = "\\.xlsx$", full.names = TRUE)
giz <- NULL
if (length(f_giz) == 0L) {
  warn("raw/giz/ : aucun .xlsx. Source principale ABSENTE : la table 13b est")
  warn("construite sur le WDI seul et la section 13c ne tournera pas.")
} else {
  check(length(f_giz) == 1L, "raw/giz/ : un seul fichier .xlsx",
        paste(basename(f_giz), collapse = ", "))
  check_sha(f_giz)
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("PACKAGE INDISPONIBLE : readxl. Installer : renv::install('readxl') puis ",
         "renv::snapshot(). Arret.", call. = FALSE)
  if (!GIZ_FORMAT_VERIFIE) {
    hr("13a-bis. Inventaire du fichier GIZ/TUMI (structure a verifier)")
    feuilles <- readxl::excel_sheets(f_giz)
    inv <- rbindlist(lapply(feuilles, function(s) {
      x <- suppressMessages(readxl::read_excel(f_giz, sheet = s, col_names = FALSE, n_max = 6))
      msg(sprintf("\n  Feuille « %s » : %d colonnes lues (6 premieres lignes)", s, ncol(x)))
      print(as.data.frame(x[, seq_len(min(12L, ncol(x)))]))
      dims <- suppressMessages(readxl::read_excel(f_giz, sheet = s, col_names = FALSE))
      data.table(feuille = s, n_lignes = nrow(dims), n_colonnes = ncol(dims),
                 entete = paste(head(as.character(unlist(x[1, ])), 30), collapse = " | "))
    }))
    fwrite(inv, p_tab("13_giz_inventaire_feuilles.csv"))
    msg("\n  Inventaire ecrit : output/tables/13_giz_inventaire_feuilles.csv")
    log_close()
    stop("ARRET VOULU : structure du fichier GIZ a verifier avant tout usage. ",
         "Transmettre le log ; le lecteur sera ecrit sur les noms reels.", call. = FALSE)
  }
  # Lecteur GIZ : ecrit apres verification de la structure (GIZ_FORMAT_VERIFIE).
}

px <- rbindlist(list(wdi[, .(iso3, pays = nom_wdi, annee, carburant, source, prix_usd)], giz),
                use.names = TRUE)

# --- API DHS : dates de terrain et ISO3 --------------------------------------
cache <- p_build("rdhs_cache")
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
cfg <- file.path(cache, "rdhs.json")
if (!file.exists(cfg)) writeLines("{}", cfg)
gi <- readBin(".gitignore", "raw", file.size(".gitignore"))
invisible(capture.output(rdhs::set_rdhs_config(
  cache_path = cache, config_path = cfg, global = FALSE, prompt = FALSE,
  verbose_setup = FALSE, data_frame = "data.table::as.data.table")))
if (!identical(gi, readBin(".gitignore", "raw", file.size(".gitignore")))) {
  writeBin(gi, ".gitignore")
  note("rdhs a modifie .gitignore : version d'origine restauree")
}
dhs <- stage("etape 2/2 enquetes et pays DHS", p_build("13_dhs_enquetes.rds"), function()
  list(enquetes = as.data.table(rdhs::dhs_surveys()),
       pays = as.data.table(rdhs::dhs_countries())))

# --- six cas et leurs vagues --------------------------------------------------
sel <- fread(p_tab("12_substituts_delta.csv"))[retenu == TRUE]
check_rows(sel, 6L, "cas retenus a l'etape 12")
vg <- fread(p_tab("12_dhs_ws_national.csv"))
vg <- unique(vg[sel[, .(code, cle)], on = .(code, cle), nomatch = NULL][
  , .(code, cle, SurveyId, annee)])
check_vars(dhs$enquetes, c("SurveyId", "FieldworkStart", "FieldworkEnd"), "dhs_surveys")
check_vars(dhs$pays, c("DHS_CountryCode", "ISO3_CountryCode"), "dhs_countries")
vg <- merge(vg, dhs$enquetes[, .(SurveyId, debut = as.IDate(FieldworkStart),
                                 fin = as.IDate(FieldworkEnd))], by = "SurveyId", all.x = TRUE)
check(!anyNA(vg$debut) && !anyNA(vg$fin), "dates de terrain presentes pour toutes les vagues",
      paste(vg[is.na(debut) | is.na(fin), SurveyId], collapse = ", "))
# FieldworkEnd est un 1er du mois : fin de terrain = dernier jour de ce mois.
vg[, fin := as.IDate(seq(as.Date(fin), by = "month", length.out = 2L)[2L] - 1L), by = SurveyId]
vg <- merge(vg, dhs$pays[, .(code = DHS_CountryCode, iso3 = ISO3_CountryCode)], by = "code")
check(uniqueN(vg[, .(code, cle)]) == 6L, "vagues retrouvees pour les six cas")
check(all(vg$iso3 %in% px$iso3), "les six pays presents dans les prix",
      paste(setdiff(vg$iso3, px$iso3), collapse = ", "))
setorder(vg, code, debut)
cas <- merge(sel[, .(code, cle, pays_dhs = pays, substitut, rang)],
             vg[, .(iso3 = iso3[1], fen_debut = min(debut), fen_fin = max(fin),
                    n_vagues = .N), by = .(code, cle)], by = c("code", "cle"))
setorder(cas, rang)
print(vg[, .(code, cle, SurveyId, debut, fin)])

# ===========================================================================
# 13b. Table pays-annee et journal des lacunes
# ===========================================================================
hr("13b. Table pays-annee et journal des lacunes")

tab <- dcast(px, iso3 + pays + annee ~ paste(carburant, source, sep = "_"),
             value.var = "prix_usd")
for (v in c("diesel_giz", "essence_giz")) if (!v %in% names(tab)) tab[, (v) := NA_real_]
setcolorder(tab, c("iso3", "pays", "annee", "diesel_giz", "essence_giz", "diesel_wdi", "essence_wdi"))
setorder(tab, iso3, annee)
fwrite(tab, p_tab("13_prix_carburant_pays_annee.csv"))
msg(sprintf("  13_prix_carburant_pays_annee.csv : %d lignes pays-annee, %d pays", nrow(tab), uniqueN(tab$iso3)))
note("Colonnes fiscales : aucune (non publiees par pays par la GIZ ni le WDI).")

sources_presentes <- unique(px$source)
lac <- list()
for (s in c("giz", "wdi")) for (carb in c("diesel", "essence")) {
  d <- px[source == s & carburant == carb]
  if (!nrow(d)) {
    lac[[length(lac) + 1L]] <- data.table(source = s, carburant = carb, iso3 = NA_character_,
      annee = NA_integer_, type = "source_absente",
      detail = if (s == "giz") "fichier raw/giz/ absent ou non lu" else "")
    next
  }
  rel <- sort(unique(d$annee))
  manq <- setdiff(RELEVES_GIZ, rel)
  if (length(manq)) lac[[length(lac) + 1L]] <- data.table(source = s, carburant = carb,
    iso3 = NA_character_, annee = manq, type = "releve_absent_de_la_source", detail = "")
  hors <- setdiff(rel, RELEVES_GIZ)
  if (length(hors)) lac[[length(lac) + 1L]] <- data.table(source = s, carburant = carb,
    iso3 = NA_character_, annee = hors, type = "annee_ambigue",
    detail = "annee absente des releves publies par la GIZ (ex. WDI 1992 contre GIZ 1993)")
  trous <- d[, .(annee = setdiff(rel[rel >= min(annee) & rel <= max(annee)], annee)), by = iso3]
  if (nrow(trous)) lac[[length(lac) + 1L]] <- trous[, .(source = s, carburant = carb, iso3, annee,
    type = "pays_manquant_dans_sa_periode", detail = "")]
}
lac <- rbindlist(lac, use.names = TRUE)
if ("giz" %in% sources_presentes) {
  cmp <- merge(px[source == "giz"], px[source == "wdi"], by = c("iso3", "annee", "carburant"),
               suffixes = c("_giz", "_wdi"))
  ec <- cmp[abs(log(prix_usd_giz / prix_usd_wdi)) > 0.01]
  msg(sprintf("  GIZ contre WDI : %d paires communes, %d ecarts > 1 %%", nrow(cmp), nrow(ec)))
  if (nrow(ec)) lac <- rbind(lac, ec[, .(source = "giz_vs_wdi", carburant, iso3, annee,
    type = "ecart_entre_sources", detail = sprintf("giz %.3f / wdi %.3f", prix_usd_giz, prix_usd_wdi))])
}
fwrite(lac, p_tab("13_lacunes.csv"))
msg("  13_lacunes.csv, decompte par type :")
print(lac[, .N, keyby = .(source, carburant, type)])
msg("  Lacunes des six pays :")
print(lac[iso3 %in% cas$iso3 | is.na(iso3)][order(source, carburant, iso3, annee)])

# ===========================================================================
# 13c-pre. Calendrier : position de chaque releve par rapport aux vagues
#          (aucune valeur de prix ; disponibilite seulement)
# ===========================================================================
hr("13c-pre. Releves par rapport aux vagues DHS (sans valeur de prix)")

position <- function(date_rel, v) {
  v <- v[order(debut)]
  for (k in seq_len(nrow(v))) if (date_rel >= v$debut[k] && date_rel <= v$fin[k])
    return(paste("pendant", v$SurveyId[k]))
  if (date_rel < v$debut[1]) return("avant la 1re vague")
  if (date_rel > v$fin[nrow(v)]) return("apres la derniere vague")
  k <- max(which(v$fin < date_rel))
  paste("entre", v$SurveyId[k], "et", v$SurveyId[k + 1L])
}
cal <- rbindlist(lapply(seq_len(nrow(cas)), function(i) {
  cc <- cas[i]; v <- vg[code == cc$code & cle == cc$cle]
  rel <- sort(unique(c(RELEVES_GIZ, px$annee)))
  rbindlist(lapply(rel, function(a) {
    dr <- as.IDate(paste0(a, JOUR_RELEVE))
    data.table(pays = cc$pays_dhs, substitut = cc$substitut, iso3 = cc$iso3, releve = a,
               date_releve = dr, position = position(dr, v),
               dans_fenetre = dr >= cc$fen_debut & dr <= cc$fen_fin,
               diesel_wdi_observe = nrow(px[source == "wdi" & carburant == "diesel" &
                                              iso3 == cc$iso3 & annee == a]) > 0,
               diesel_giz_observe = nrow(px[source == "giz" & carburant == "diesel" &
                                              iso3 == cc$iso3 & annee == a]) > 0)
  }))
}))
fwrite(cal, p_tab("13_fenetres_dhs.csv"))
print(cal[dans_fenetre == TRUE, .(pays, releve, position, diesel_wdi_observe, diesel_giz_observe)])

# ===========================================================================
# 13c. Variation dans les fenetres -- BLOQUEE par le critere
# ===========================================================================
hr("13c. Variation brute et nette dans les fenetres DHS")

memo <- readLines(MEMO, encoding = "UTF-8")
statut <- trimws(sub("^Statut\\s*:", "", grep("^Statut\\s*:", memo, value = TRUE)))
check(length(statut) == 1L, "memo : une ligne « Statut : »")
if (!identical(statut, "FIXÉ")) {
  warn(sprintf("critere au statut « %s » : section 13c NON executee.", statut))
  warn("Fixer les seuils puis ecrire « Statut : FIXÉ » dans le memo.")
  log_close()
  quit(save = "no", status = 0L)
}
check("giz" %in% sources_presentes, "source principale GIZ/TUMI lue",
      "13c exige le fichier GIZ/TUMI (critere : source principale)")
seuil <- function(nom) {
  l <- grep(paste0("`", nom, "\\s*=\\s*[0-9.]+`"), memo, value = TRUE)
  check(length(l) == 1L, paste("memo : seuil", nom, "defini une seule fois"))
  as.numeric(sub(paste0(".*`", nom, "\\s*=\\s*([0-9.]+)`.*"), "\\1", l))
}
S_SD <- seuil("SEUIL_SD_NET"); S_SAUT <- seuil("SEUIL_SAUT_NET"); MIN_CAS <- seuil("MIN_CAS")
msg(sprintf("  Seuils lus dans le memo : SD net >= %.2f, saut net >= %.2f, au moins %d cas",
            S_SD, S_SAUT, as.integer(MIN_CAS)))

mesures <- function(src, moy) {
  d <- px[source == src & carburant == "diesel"]
  d[, lp := log(prix_usd)]
  d[, date_rel := as.IDate(paste0(annee, JOUR_RELEVE))]
  rbindlist(lapply(seq_len(nrow(cas)), function(i) {
    cc <- cas[i]; v <- vg[code == cc$code & cle == cc$cle]
    rel_f <- sort(unique(d[date_rel >= cc$fen_debut & date_rel <= cc$fen_fin, annee]))
    base <- d[annee %in% rel_f]
    if (moy == "equilibre") {
      # Panel equilibre sur les releves ou le pays du cas est observe : sinon un
      # pays a trou (Haiti 2006, 2010) sortirait de son propre panel.
      rel_c <- base[iso3 == cc$iso3, annee]
      base <- base[annee %in% rel_c]
      pl <- base[, .N, by = iso3][N == length(rel_c), iso3]
      base <- base[iso3 %in% pl]
    }
    base[, r := lp - mean(lp), by = annee]
    x <- base[iso3 == cc$iso3][order(annee)]
    x[, entre := vapply(date_rel, function(z) startsWith(position(z, v), "entre"), TRUE)]
    saut <- function(y) {
      if (nrow(x) < 2L) return(list(val = NA_real_, de = NA_integer_, a = NA_integer_))
      dd <- data.table(de = x$annee[-nrow(x)], a = x$annee[-1L], dv = diff(x[[y]]),
                       entre = x$entre[-1L])[entre == TRUE]
      if (!nrow(dd)) return(list(val = NA_real_, de = NA_integer_, a = NA_integer_))
      k <- which.max(abs(dd$dv)); list(val = abs(dd$dv[k]), de = dd$de[k], a = dd$a[k])
    }
    sb <- saut("lp"); sn <- saut("r")
    data.table(source = src, moyenne = moy, rang = cc$rang, pays = cc$pays_dhs,
               substitut = cc$substitut, fenetre = sprintf("%s -- %s", cc$fen_debut, cc$fen_fin),
               n_releves_fenetre = length(rel_f), n_obs_pays = nrow(x),
               n_pays_moyenne = uniqueN(base$iso3),
               sd_brut = if (nrow(x) >= 3L) sd(x$lp) else NA_real_,
               sd_net = if (nrow(x) >= 3L) sd(x$r) else NA_real_,
               saut_brut = sb$val, saut_net = sn$val,
               saut_net_releves = if (is.na(sn$de)) NA_character_ else sprintf("%d-%d", sn$de, sn$a))
  }))
}
res <- rbindlist(lapply(c("giz", "wdi"), function(s)
  rbindlist(lapply(c("tous", "equilibre"), function(m) mesures(s, m)))))
res[, passe := !is.na(sd_net) & !is.na(saut_net) & sd_net >= S_SD & saut_net >= S_SAUT]
fwrite(res, p_tab("13_variation_cas.csv"))

verdicts <- res[, .(n_passe = sum(passe), cas_passes = paste(pays[passe], collapse = ", ")),
                by = .(source, moyenne)]
verdicts[, voie := fifelse(n_passe >= MIN_CAS, "non close", "CLOSE")]
msg("  Verdict mecanique par combinaison (memo : stabilite declaree d'avance) :")
print(verdicts)
if (uniqueN(verdicts$voie) > 1L) {
  warn("VERDICT INSTABLE entre combinaisons : rapporte tel quel, aucune n'est choisie.")
} else msg(sprintf("  Verdict stable sur les quatre combinaisons : voie %s.", verdicts$voie[1]))

pr <- res[source == "giz" & moyenne == "tous"][order(rang)]
tex <- c("\\begin{tabular}{rllrrrrrl}", "\\toprule",
  "Rang & Pays & Substitut & Relev\\'es & SD brut & SD net & Saut brut & Saut net & Relev\\'es du saut \\\\",
  "\\midrule",
  pr[, sprintf("%d & %s & %s & %d & %.3f & %.3f & %.3f & %.3f & %s \\\\", rang, pays, substitut,
               n_obs_pays, sd_brut, sd_net, saut_brut, saut_net,
               fifelse(is.na(saut_net_releves), "--", saut_net_releves))],
  "\\bottomrule",
  sprintf(paste0("\\multicolumn{9}{l}{\\footnotesize N = %d cas. Diesel, log US\\$/litre, source GIZ/TUMI ; ",
                 "net = \\'ecart \\`a la moyenne des pays au m\\^eme relev\\'e (%d \\`a %d pays). ",
                 "Seuils : SD net $\\geq %.2f$, saut net $\\geq %.2f$ entre deux vagues.} \\\\"),
          nrow(pr), min(pr$n_pays_moyenne), max(pr$n_pays_moyenne), S_SD, S_SAUT),
  "\\end{tabular}")
writeLines(tex, p_tab("13_variation_cas.tex"))

# Trajectoires brute et nette, bandes = terrain des vagues (pas de titre)
tr <- rbindlist(lapply(seq_len(nrow(cas)), function(i) {
  cc <- cas[i]
  d <- px[source == "giz" & carburant == "diesel"][, lp := log(prix_usd)]
  d[, r := lp - mean(lp), by = annee]
  d[iso3 == cc$iso3, .(pays = cc$pays_dhs, annee, brut = lp - mean(lp), net = r - mean(r))]
}))
tr <- melt(tr, id.vars = c("pays", "annee"), variable.name = "serie", value.name = "valeur")
bandes <- merge(vg, cas[, .(code, cle, pays = pays_dhs)], by = c("code", "cle"))
g <- ggplot(tr, aes(annee, valeur, linetype = serie)) +
  geom_rect(data = bandes, inherit.aes = FALSE, fill = "grey85",
            aes(xmin = year(debut) + (month(debut) - 1) / 12, xmax = year(fin) + month(fin) / 12,
                ymin = -Inf, ymax = Inf)) +
  geom_hline(yintercept = 0, colour = "grey60") + geom_line() + geom_point(size = 1) +
  facet_wrap(~pays) +
  labs(x = NULL, y = "log prix diesel, centre sur le pays (net : moins la moyenne du releve)",
       linetype = NULL) +
  theme_minimal(base_size = 9) + theme(legend.position = "bottom")
ggsave(p_fig("13_traj_diesel_cas.pdf"), g, width = 8, height = 5)

hr("ETAPE 13 TERMINEE")
for (f in c("13_prix_carburant_pays_annee.csv", "13_lacunes.csv", "13_fenetres_dhs.csv",
            "13_variation_cas.csv", "13_variation_cas.tex", "13_traj_diesel_cas.pdf")) note(f)
log_close()
