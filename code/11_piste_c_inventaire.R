# ---------------------------------------------------------------------------
# 11_piste_c_inventaire.R -- piste C : inventaire des donnees menages
#   NSS Schedule 1.2 (58e 2002, 69e 2012, 76e 2018) et IHDS-I / IHDS-II.
#
# PORTEE : INVENTAIRE SEULEMENT. Aucune fusion entre sources, aucune
# estimation, aucune part ponderee d'une variable de resultat. Les comptes par
# code sont NON ponderes et ne servent qu'a verifier que les codes observes
# sont ceux des questionnaires (code/ref/11_nss_codes_documentes.csv). Les
# poids ne sont sommes que pour valider leur echelle (nombre de menages).
#
# CORRESPONDANCE VARIABLE -> ITEM DU QUESTIONNAIRE
#   58 : Block4-records.csv ; B4_q1..B4_q4 = items 1-4 du bloc 4
#        (confirme par IHSN_study_report_NSS_58_Round_Sch1pt2.pdf).
#   69 : "Block - 4 ... level 4.csv" ; b4_qN = item N du bloc 4. Pas de
#        dictionnaire de donnees publie : correspondance deduite de l'ordre des
#        colonnes, qui reproduit exactement la numerotation du questionnaire
#        (b4_q3_1..12, b4_q19_1..2, b4_q26_1..4, b4_q30_1..4). b4_q3_k = mois k
#        (janvier = 1) : deduit, a confirmer.
#   76 : L05_Particulars_of_living_facilities.csv, noms explicites
#        (Data_Layout_NSS76_120.xlsx).
#   IHDS : fichiers menage ICPSR (DS0002), noms des codebooks.
#
# LANCEMENT (racine du depot, dans un terminal) :
#     Rscript code/11_piste_c_inventaire.R           # reprend
#     Rscript code/11_piste_c_inventaire.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 11_nss_fichiers.rds  dimensions et noms de colonnes de chaque csv NSS
#   2. 11_nss_eau.rds       bloc eau de chaque round : ids, geo, poids, eau
#   3. 11_ihds.rds          IHDS-I et II : ids, geo, poids, eau (codes + libelles)
# Les tableaux sont toujours recalcules (quelques secondes).
#
# Sorties : output/tables/11_*.csv, output/logs/11_piste_c_inventaire.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("11_piste_c_inventaire.log"))

msg("ETAPE 11 -- PISTE C : INVENTAIRE NSS 58/69/76 ET IHDS-I/II")
msg("Inventaire seulement : aucune fusion, aucune estimation, aucune part ponderee.")

# --- effectifs documentes ----------------------------------------------------
# 58 : IHSN_study_report_NSS_58_Round_Sch1pt2.pdf ("a total of 97882 households")
# 69 : kye_indi_of_water_Sanitation69rou_24dec13.pdf, tableau 2.1 (53393 + 42155)
# 76 : Report_584_final.pdf ("1,06,838 households (63,736 rural, 43,102 urban)")
# IHDS : manifestes ICPSR 22626 et 36151 (DS0002 Household)
N_DOC <- list(nss58 = 97882L, nss69 = 95548L, nss76 = 106838L,
              ihds1 = 41554L, ihds2 = 42152L)
N_DOC_SECTEUR <- list(nss69 = c(`1` = 53393L, `2` = 42155L),
                      nss76 = c(`1` = 63736L, `2` = 43102L))

NSS <- list(
  nss58 = list(
    fichier = p_raw("nss", "58", "Block4-records.csv"),
    cle = "Key_hhold",
    geo = c(secteur = "Sector", etat = "State", region = "Region", district = "District",
            strate = "Stratum", fsu = "FSU"),
    poids = c("Wgt_SS", "Wgt_Combined", "WGT_posted", "nss", "nsc"),
    eau = c(source = "B4_q1", suffisance = "B4_q2", acces = "B4_q3", distance = "B4_q4")),
  nss69 = list(
    fichier = p_raw("nss", "69",
      "Block - 4 Particulars of living facilities - drinking water, bathroom, sanitation etc - level 4.csv"),
    cle = "Key_hhold",
    geo = c(secteur = "Sector", etat = "State_code", region = "State_region",
            district = "District", district_4c = "District_Code", strate = "Stratum",
            fsu = "FSU_Serial_No"),
    poids = c("MLT", "NSS", "NSC", "Combined_Weight"),
    eau = c(source = "b4_q1", suffisance = "b4_q2", setNames(paste0("b4_q3_", 1:12),
            paste0("mois_", 1:12)), acces = "b4_q4", distance = "b4_q5",
            source_suppl = "b4_q11", traitement = "b4_q12")),
  nss76 = list(
    fichier = p_raw("nss", "76", "L05_Particulars_of_living_facilities.csv"),
    cle = "HHID",
    geo = c(secteur = "Sector", etat = "State", region = "NSS_Region", district = "District",
            district_4c = "District_Code", strate = "Stratum", fsu = "FSUSerialNo"),
    poids = c("Multiplier", "NSC"),
    eau = c(source = "source_drinking_water", suffisance = "water_sufficient_drink",
            setNames(paste0("Insufficiency_water_", month.abb), paste0("mois_", 1:12)),
            acces = "Access_source_water", distance = "Distance_source_water",
            source_suppl = "Supplementary_source_water", traitement = "Method_treatment"))
)

# ===========================================================================
# Etape 1 : tous les csv NSS -- dimensions et noms
# ===========================================================================
hr("11a. Fichiers NSS (etape 1)")

f_fic <- p_build("11_nss_fichiers.rds")
fic <- stage("etape 1/3 fichiers NSS", f_fic, function() {
  fs <- list.files(p_raw("nss"), pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
  rbindlist(lapply(fs, function(f) {
    tmsg("  lecture ", f)
    h <- names(fread(f, nrows = 0L))
    n <- nrow(fread(f, select = 1L, colClasses = "character", showProgress = FALSE))
    data.table(round = basename(dirname(f)), fichier = basename(f), lignes = n,
               colonnes = length(h), noms = paste(h, collapse = " "))
  }))
})
op <- options(width = 200)
print(fic[, .(round, fichier = substr(fichier, 1, 70), lignes, colonnes)])
options(op)
fwrite(fic, p_tab("11_nss_fichiers.csv"))

# ===========================================================================
# Etape 2 : bloc eau de chaque round NSS
# ===========================================================================
hr("11b. Blocs eau NSS (etape 2)")

f_eau <- p_build("11_nss_eau.rds")
nss <- stage("etape 2/3 blocs eau NSS", f_eau, function() {
  lapply(names(NSS), function(r) {
    s <- NSS[[r]]
    tmsg("  lecture ", s$fichier)
    d <- fread(s$fichier, colClasses = "character", showProgress = FALSE)
    vars <- c(s$cle, s$geo, s$poids, s$eau)
    check_vars(d, vars, r)
    d[, ..vars]
  }) |> setNames(names(NSS))
})

for (r in names(NSS)) {
  d <- nss[[r]]; s <- NSS[[r]]
  msg(""); msg(r, " : ", basename(s$fichier))
  check_rows(d, N_DOC[[r]], r)
  check_unique(d, s$cle, r)
  if (!is.null(N_DOC_SECTEUR[[r]])) {
    obs <- d[, .N, keyby = c(s$geo[["secteur"]])]
    check(identical(setNames(obs$N, obs[[1]]), N_DOC_SECTEUR[[r]]),
          sprintf("%s : menages par secteur (1 rural, 2 urbain) == documentation", r),
          paste("observe :", paste(obs[[1]], obs$N, collapse = ", ")))
  }
}

# --- codes observes contre codes documentes (comptes NON ponderes) ----------
hr("11c. Codes observes contre codes des questionnaires (non ponderes)")

ref <- fread(file.path("code", "ref", "11_nss_codes_documentes.csv"))
check(nrow(ref) > 0L, "liste de codes documentes lue")
codes <- rbindlist(lapply(names(NSS), function(r) {
  rn <- as.integer(sub("nss", "", r))
  rbindlist(lapply(unique(ref[round == rn, variable]), function(v) {
    x <- trimws(nss[[r]][[v]])
    t <- data.table(code_brut = x)[, .N, by = code_brut]
    t[, code := suppressWarnings(as.integer(code_brut))]
    t <- merge(t, ref[round == rn & variable == v, .(code, libelle)], by = "code", all = TRUE)
    t[is.na(N), N := 0L]
    t[, `:=`(round = rn, concept = ref[round == rn & variable == v, concept[1]], variable = v,
             documente = !is.na(libelle))]
    setcolorder(t, c("round", "concept", "variable", "code", "code_brut", "libelle", "N", "documente"))
    t[order(code, na.last = TRUE)]
  }))
}))
op <- options(width = 200)
print(codes[, .(round, concept, variable, code, libelle = substr(libelle, 1, 55), N)])
options(op)
fwrite(codes, p_tab("11_nss_codes_observes.csv"))

hors <- codes[!documente & N > 0L & !(is.na(code) & code_brut %in% c("", NA))]
if (nrow(hors)) {
  warn("codes observes absents du questionnaire (a expliquer avant tout usage) :")
  print(hors)
}
manq <- codes[is.na(code) & code_brut %in% c("", NA), .(round, variable, manquants = N)]
msg("  Valeurs vides par variable :"); print(manq)

# mois d'insuffisance : seules valeurs attendues = vide ou 1, et seulement si suffisance = non
for (r in c("nss69", "nss76")) {
  d <- nss[[r]]; s <- NSS[[r]]
  mois <- s$eau[grepl("^mois_", names(s$eau))]
  vals <- unique(unlist(lapply(mois, function(m) unique(trimws(d[[m]])))))
  msg(sprintf("  %s : valeurs des colonnes de mois = {%s}", r, paste(sort(vals), collapse = ", ")))
  un_mois <- d[, Reduce(`|`, lapply(mois, function(m) trimws(get(m)) == "1"))]
  suff <- trimws(d[[s$eau[["suffisance"]]]])
  print(table(suffisance = suff, au_moins_un_mois = un_mois, useNA = "ifany"))
}

# --- poids -------------------------------------------------------------------
hr("11d. Poids NSS : sommes (validation d'echelle seulement)")

num <- function(x) as.numeric(trimws(x))
poids <- rbindlist(list(
  nss58 = nss$nss58[, .(menages = .N, Wgt_Combined = sum(num(Wgt_Combined)),
                        Wgt_SS = sum(num(Wgt_SS)), WGT_posted = sum(num(WGT_posted)),
                        WGT_posted_sur_100 = sum(num(WGT_posted)) / 100),
                    keyby = .(secteur = Sector)],
  nss69 = nss$nss69[, .(menages = .N, Combined_Weight = sum(num(Combined_Weight)),
                        MLT_regle_NSS = sum(ifelse(NSS == NSC, num(MLT) / 100, num(MLT) / 200)),
                        ecart_max_regle = max(abs(num(Combined_Weight) -
                          ifelse(NSS == NSC, num(MLT) / 100, num(MLT) / 200)))),
                    keyby = .(secteur = Sector)],
  nss76 = nss$nss76[, .(menages = .N, Multiplier = sum(num(Multiplier)),
                        Multiplier_sur_100 = sum(num(Multiplier)) / 100,
                        NSC_valeurs = paste(sort(unique(NSC)), collapse = "/")),
                    keyby = .(secteur = Sector)]
), idcol = "round", fill = TRUE)
op <- options(width = 200, scipen = 20); print(poids); options(op)
fwrite(poids, p_tab("11_nss_poids.csv"))
msg("  Reference 76 : 271,10 millions de menages estimes (Report 584, Statement 1 :",
    " rural 178,38 ; urbain 92,72).")

# --- geographie --------------------------------------------------------------
hr("11e. Identifiants geographiques NSS")

geo <- rbindlist(lapply(names(NSS), function(r) {
  d <- nss[[r]]; g <- NSS[[r]]$geo
  data.table(round = r, etats = uniqueN(d[[g[["etat"]]]]),
             regions = uniqueN(d[, c(g[["etat"]], g[["region"]]), with = FALSE]),
             districts = uniqueN(d[, c(g[["etat"]], g[["district"]]), with = FALSE]),
             fsu = uniqueN(d[[g[["fsu"]]]]),
             exemple_region = d[[g[["region"]]]][1], exemple_district = d[[g[["district"]]]][1])
}))
print(geo)
fwrite(geo, p_tab("11_nss_geo.csv"))

# nombre de districts et de regions par etat et par round : les changements
# signalent les redecoupages (codes non comparables)
par_etat <- rbindlist(lapply(names(NSS), function(r) {
  d <- nss[[r]]; g <- NSS[[r]]$geo
  d[, .(districts = uniqueN(get(g[["district"]])), regions = uniqueN(get(g[["region"]]))),
    by = .(etat = as.integer(get(g[["etat"]])))][, round := r]
}))
par_etat <- dcast(par_etat, etat ~ round, value.var = c("districts", "regions"))
op <- options(width = 200); print(par_etat); options(op)
fwrite(par_etat, p_tab("11_nss_geo_par_etat.csv"))

# ===========================================================================
# Etape 3 : IHDS
# ===========================================================================
hr("11f. IHDS-I et IHDS-II (etape 3)")

IHDS <- list(
  ihds1 = list(fichier = p_raw("ihds", "2005", "DS0002", "22626-0002-Data.rda"),
               ids = c("STATEID", "DISTID", "PSUID", "HHID", "HHSPLITID", "IDHH", "IDPSU"),
               geo = c("DIST01", "URBAN"), poids = "SWEIGHT",
               eau = c("WA1", "WA2", "WA2A", "WA4", "WA5", "WA7", "WA8", "WA10")),
  ihds2 = list(fichier = p_raw("ihds", "2011", "DS0002", "36151-0002-Data.rda"),
               ids = c("STATEID", "DISTID", "PSUID", "HHID", "HHSPLITID", "IDHH", "IDPSU"),
               geo = c("DIST01", "DISTRICT", "URBAN2011"), poids = c("WT", "FWT"),
               eau = c("WA1A", "WA1B", "WA2A", "WA2B", "WA4A", "WA5A", "WA5B", "WA7"))
)

# facteur ICPSR "(01) Piped" -> code entier 1 ; les libelles sont gardes a part
code_icpsr <- function(x) {
  if (!is.factor(x)) return(as.numeric(x))
  as.numeric(sub("^\\((-?[0-9]+)\\).*$", "\\1", as.character(x)))
}

f_ihds <- stage("etape 3/3 IHDS", p_build("11_ihds.rds"), function() {
  lapply(IHDS, function(s) {
    tmsg("  lecture ", s$fichier)
    e <- new.env()
    obj <- load(s$fichier, envir = e)
    d <- e[[obj]]
    vars <- c(s$ids, s$geo, s$poids, s$eau)
    check_vars(d, vars, basename(s$fichier))
    lab <- attr(d, "variable.labels")
    niv <- rbindlist(lapply(c(s$geo, s$eau), function(v)
      if (is.factor(d[[v]])) data.table(variable = v, niveau = levels(d[[v]]),
                                        N = as.integer(table(d[[v]])))))
    out <- as.data.table(lapply(setNames(vars, vars), function(v)
      if (v == "IDHH") as.character(d[[v]]) else code_icpsr(d[[v]])))
    list(d = out, libelles = data.table(variable = vars, libelle = unname(lab[vars])),
         niveaux = niv, n_var = ncol(d))
  })
})

for (w in names(IHDS)) {
  x <- f_ihds[[w]]
  msg(""); msg(w, " : ", basename(IHDS[[w]]$fichier), " (", x$n_var, " variables)")
  check_rows(x$d, N_DOC[[w]], w)
  check_unique(x$d, c("STATEID", "DISTID", "PSUID", "HHID", "HHSPLITID"), w)
  check_unique(x$d, "IDHH", w)
  print(x$libelles)
}
ihds_codes <- rbindlist(lapply(f_ihds, `[[`, "niveaux"), idcol = "vague")
op <- options(width = 200); print(ihds_codes); options(op)
fwrite(ihds_codes, p_tab("11_ihds_codes_observes.csv"))

# --- panel : lien menage IHDS-II -> IHDS-I ------------------------------------
# Deduit des donnees, non documente dans les fichiers ICPSR : dans IHDS-II,
# HHID = 10 x HHID(IHDS-I) + HHSPLITID(IHDS-I), et HHSPLITID = numero de
# scission 2012 (1 = menage d'origine, 2-6 = scissions, 9 = echantillon ajoute
# ou remplacant, SANS lien de panel meme si sa cle tombe sur un menage IHDS-I).
hr("11g. Lien de panel IHDS-II -> IHDS-I")

a <- f_ihds$ihds1$d; b <- f_ihds$ihds2$d
a[, cle := paste(STATEID, DISTID, PSUID, 10 * HHID + HHSPLITID)]
b[, cle := paste(STATEID, DISTID, PSUID, HHID)]
b[, `:=`(nouveau = HHSPLITID == 9, dans_I = cle %in% a$cle)]
lien <- b[, .N, keyby = .(HHSPLITID, nouveau, dans_I)]
print(lien)
check(b[nouveau == FALSE, all(dans_I)],
      "tout menage IHDS-II hors code 9 retrouve un menage IHDS-I par la cle recodee",
      sprintf("%d sans correspondant", b[nouveau == FALSE & !dans_I, .N]))
n_suivis <- a[cle %in% b[nouveau == FALSE, cle], .N]
msg(sprintf("  Menages IHDS-I re-enquetes : %d sur %d (%.1f %%) ; guide : 83 %%",
            n_suivis, nrow(a), 100 * n_suivis / nrow(a)))
msg(sprintf("  Menages IHDS-I scindes (>1 menage IHDS-II) : %d",
            b[nouveau == FALSE, .N, by = cle][N > 1, .N]))
m <- merge(b[nouveau == FALSE, .(cle, DIST01_II = DIST01)], a[, .(cle, DIST01_I = DIST01)], by = "cle")
msg(sprintf("  DIST01 identique entre vagues pour les menages lies : %.2f %%",
            100 * m[, mean(DIST01_I == DIST01_II, na.rm = TRUE)]))
fwrite(lien, p_tab("11_ihds_lien_panel.csv"))

hr("11h. Poids IHDS (validation d'echelle)")
pw <- rbind(
  a[, .(vague = "ihds1", poids = "SWEIGHT", menages = .N, somme = sum(SWEIGHT, na.rm = TRUE),
        manquants = sum(is.na(SWEIGHT)))],
  b[, .(vague = "ihds2", poids = "WT", menages = .N, somme = sum(WT, na.rm = TRUE),
        manquants = sum(is.na(WT)))],
  b[, .(vague = "ihds2", poids = "FWT", menages = .N, somme = sum(FWT, na.rm = TRUE),
        manquants = sum(is.na(FWT)))])
op <- options(scipen = 20); print(pw); options(op)
fwrite(pw, p_tab("11_ihds_poids.csv"))

hr("ETAPE 11 TERMINEE")
for (f in sort(list.files(p_tab(), pattern = "^11_"))) msg("  ", f)
log_close()
