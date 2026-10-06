# ---------------------------------------------------------------------------
# 24_piste_c_nfhs_purificateurs.R -- piste C rouverte : adoption du filtre a eau
#   et du purificateur electrique dans les NFHS-3 (2005-06), NFHS-4 (2015-16)
#   et NFHS-5 (2019-21), fichiers menages DHS (HR).
#
# OBJET : DESCRIPTIF SEULEMENT. Aucune regression, aucun critere de sortie.
# Question : la piste C est-elle rouvrable, et sur quel perimetre ?
#   Etape 0  disponibilite de la serie hv237 (suffixes, libelles), effectifs,
#            non-reponse.
#   Etape 1  taux d'adoption ponderes (hv005) du filtre (hv237d) et du
#            purificateur electrique (hv237h) : national, urbain, rural ; puis
#            les huit villes du NFHS-3, bidonville / hors bidonville.
#   Etape 2  inventaire des variables de source d'eau (hv201 et apparentees),
#            modalites par vague et ruptures de codage. Rien n'est construit :
#            comptes NON ponderes seulement (precedent : script 11).
#   Etape 3  georeferencement : fichier GE par vague, grappes a coordonnees
#            valides.
#
# CONSTATS DEJA FAITS SUR LES EN-TETES (06/10, lecture d'une ligne) :
#   - hv237d = « use water filter », hv237h = « use electric purifier »
#     (NFHS-3, NFHS-4) puis « electronic purifier » (NFHS-5). Codes 0/1/8.
#   - Bidonville : shslumc (NFHS-3 : 1 = slum, 2 = non-slum ; NFHS-4 :
#     0 = non-slum, 1 = slum). Aucune variable de bidonville en NFHS-5.
#   - Villes : shcity en NFHS-3 seulement. NFHS-4 : district shdistri ;
#     NFHS-5 : shdist.
#   - Fichier GE : NFHS-4 (IAGE71FL), NFHS-5 (IAGE7AFL). Aucun pour le NFHS-3
#     dans raw/dhs/india/2005.
#   - Les questionnaires NFHS ne sont pas dans raw/ : la formulation de la
#     question est rapportee d'apres les libelles DHS du fichier.
#
# ATTENTES (ECRITES AVANT EXECUTION ; si l'une tombe, arret dur et question a
# Valentine, aucun ajustement) :
#   A1  Nombre de menages du fichier HR == effectif publie des rapports
#       nationaux : NFHS-3 109 041 ; NFHS-4 601 509 ; NFHS-5 636 699. Le nombre
#       de lignes est aussi controle contre l'en-tete binaire Stata.
#   A2  hv237, hv237d, hv237h presentes dans les trois vagues ; libelle de
#       hv237d contient « filter », celui de hv237h « electric » ou
#       « electronic » et « purifier ».
#   A3  Non-reponse de chaque indicateur d'adoption (hv237 manquante ou « ne
#       sait pas », ou hv237 = 1 et la methode manquante ou « ne sait pas »)
#       <= 2 % des menages, par vague.
#   A4  (REECRITE le 06/10 avant relance ; historique ci-dessous) NFHS-5,
#       Bihar urbain (hv024 = « bihar », trouve exactement une fois ;
#       hv025 = 1), pondere par hv005, denominateur = ensemble des menages
#       (celui de la table DHS) : purificateur electronique (hv237h) = 9,5 %
#       a +/- 0,5 point. Source : rapport d'Etat NFHS-5 Bihar (serie FR374,
#       dhsprogram.com), table « Water treatment prior to drinking », ligne
#       « Use electronic purifier », colonne urbain.
#       Historique : la premiere A4 (ensemble des menages, filtre 16,7 %,
#       purificateur 3,3 %) a echoue au premier passage (6,97 % ; 5,57 %).
#       Repere mal transmis : Kumar et al. (2025, Water Quality &
#       Sustainability) rapportent ces parts aux seuls menages qui traitent
#       leur eau (41,7 %), et leur chiffre du purificateur ne se reconcilie
#       pas (incoherence interne a l'article selon Valentine). Remplacee par
#       une source officielle, pas par un ajustement a nos chiffres.
#   A5  shcity (NFHS-3) porte exactement les huit villes ; en NFHS-4/5 chaque
#       libelle de district de la table VILLES_DIST est trouve exactement une
#       fois, et l'Etat de Delhi exactement une fois.
#   A6  NFHS-4 et NFHS-5 : chaque grappe (hv001) du fichier HR a une ligne
#       dans le fichier GE.
#
# DEFINITIONS
#   Adoption d'une methode m : 1 si hv237 = 1 et m = 1 ; 0 si hv237 = 0, ou
#   hv237 = 1 et m = 0 ; manquant sinon. Taux = moyenne ponderee par hv005
#   sur les non-manquants. Erreur-type par linearisation (grappe hv021 dans
#   la strate hv022, estimation par domaine ; une strate a une seule grappe ne
#   contribue pas a la variance). Si hv021 ne varie pas (NFHS-3 : constante,
#   libelle « see sh021 »), la grappe est hv001 (correction approuvee le 06/10).
#   Huit villes : NFHS-3 = echantillon urbain shcity (definition de
#   l'enquete). NFHS-4/5 = APPROXIMATION : menages urbains (hv025 = 1) des
#   districts de VILLES_DIST, Delhi = Etat entier urbain. Ce n'est pas le
#   perimetre municipal du NFHS-3 ; les niveaux ne sont pas strictement
#   comparables d'une vague a l'autre.
#
# LIMITES A CONSIGNER : adoption declaree ; la question porte sur ce que le
# menage fait « habituellement » ; les coordonnees DHS sont deplacees
# aleatoirement (jusqu'a 2 km en urbain, 5 km en rural, 10 km pour 1 % des
# grappes rurales) ; les grappes SOURCE = GAZ sont placees au gazetier.
#
# LANCEMENT (racine du depot, dans un terminal) :
#     Rscript code/24_piste_c_nfhs_purificateurs.R           # reprend
#     Rscript code/24_piste_c_nfhs_purificateurs.R --force   # relit les .DTA
#
# Etapes resumables : build/24_cache_<vague>.rds (une lecture par .DTA).
# Sorties : output/tables/24_*.csv (+ .tex pour les tables d'adoption) ;
#           output/logs/24_piste_c_nfhs_purificateurs.log
# Microdonnees : seulement dans build/ (gitignore). Les tables sont agregees.
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("24_piste_c_nfhs_purificateurs.log"))
msg("ETAPE 24 -- PISTE C : FILTRE ET PURIFICATEUR ELECTRIQUE, NFHS-3/4/5")
msg("Descriptif seulement : aucune regression, aucune issue, aucun critere.")

VAGUES <- data.table(
  vague   = c("nfhs3", "nfhs4", "nfhs5"),
  periode = c("2005-06", "2015-16", "2019-21"),
  dta     = p_raw("dhs", "india", c("2005/IAHR52DT/IAHR52FL.dta",
                                    "2015/IAHR74DT/IAHR74FL.DTA",
                                    "2019/IAHR7EDT/IAHR7EFL.DTA")),
  ge      = c(NA_character_,
              p_raw("dhs", "india", "2015", "IAGE71FL", "IAGE71FL.shp"),
              p_raw("dhs", "india", "2019", "IAGE7AFL", "IAGE7AFL.shp")),
  n_doc   = c(109041L, 601509L, 636699L)          # A1
)

# Colonnes gardees dans le cache, en plus des variables d'eau reperees dans le
# dictionnaire (etape 2) et de la serie hv237a-z.
VARS <- c("hhid", "hv000", "hv001", "hv002", "hv005", "hv007", "hv021",
          "hv022", "hv024", "hv025", "hv026",
          "shcity", "shslumc", "shdistri", "shdist")
MOTIF_HV237 <- "^hv237[a-z]?$"
# Variables d'eau du dictionnaire : par nom (hv20x, hv23x) ou par libelle ;
# variables par membre (suffixe _NN) exclues.
MOTIF_EAU_NOM <- "^hv(20[0-9]|23[0-9])[a-z]?$"
MOTIF_EAU_LIB <- "water|drink|pipe|tap|purif|filter|tanker|bottled"

METHODES <- c(filtre = "hv237d", purificateur = "hv237h")

SEUIL_NONREP <- 0.02                                       # A3
REPERE_BIHAR_URBAIN <- 0.095                               # A4 (reecrite)
TOL_REPERE   <- 0.005

VILLES <- c("chennai", "delhi", "hyderabad", "indore", "kolkata",
            "meerut", "mumbai", "nagpur")
VILLES_DIST <- list(chennai = "chennai", hyderabad = "hyderabad",
                    indore = "indore", kolkata = "kolkata", meerut = "meerut",
                    mumbai = c("mumbai", "mumbai suburban"), nagpur = "nagpur")
DELHI_ETAT  <- c("delhi", "nct of delhi")

hr("Attentes ecrites avant execution")
msg("A1  N menages HR == rapports : ", paste(VAGUES$vague, VAGUES$n_doc, sep = " = ", collapse = " ; "))
msg("A2  hv237, hv237d (filter), hv237h (electric|electronic purifier) presentes partout")
msg("A3  non-reponse de chaque indicateur <= ", SEUIL_NONREP * 100, " % par vague")
msg("A4  (reecrite 06/10) NFHS-5 Bihar urbain, purificateur electronique ",
    REPERE_BIHAR_URBAIN * 100, " % (rapport d'Etat FR374), a +/- ", TOL_REPERE * 100, " point")
msg("    premiere A4 (16,7 % / 3,3 %, ensemble des menages) : echec, repere mal transmis")
msg("A5  shcity = les 8 villes ; districts et Etat de Delhi trouves exactement une fois")
msg("A6  toute grappe HR presente dans le GE (NFHS-4, NFHS-5)")

# --- utilitaires -----------------------------------------------------------

num <- function(x) as.numeric(haven::zap_labels(x))
lib <- function(x) attr(x, "label", exact = TRUE) %||% NA_character_
etiquettes <- function(x) {
  l <- attr(x, "labels", exact = TRUE)
  if (is.null(l)) return(data.table(code = numeric(), libelle = character()))
  data.table(code = as.numeric(l), libelle = names(l))
}

# En-tete binaire Stata, formats 111-115 (repris du script 14) : sert de
# controle independant du nombre de lignes.
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

# Taux pondere et erreur-type linearisee, estimation par domaine.
taux_pondere <- function(m, y, dom) {
  ok <- dom & !is.na(y)
  if (!any(ok)) return(data.table(n = 0L, n_oui = 0L, taux = NA_real_, se = NA_real_))
  W <- sum(m$w[ok]); r <- sum(m$w[ok] * y[ok]) / W
  z <- numeric(nrow(m)); z[ok] <- m$w[ok] * (y[ok] - r) / W
  tt <- data.table(s = m$strate, p = m$psu, z = z)[, .(z = sum(z)), by = .(s, p)]
  v  <- tt[, .(nh = .N, ss = sum((z - mean(z))^2)), by = s][nh > 1, sum(nh / (nh - 1) * ss)]
  data.table(n = sum(ok), n_oui = as.integer(sum(y[ok] == 1)), taux = r, se = sqrt(v))
}

ecrire_tex <- function(d, f, alignement) {
  fmt <- function(x) if (is.numeric(x)) formatC(x, format = "f", digits = 1, big.mark = ",") else x
  corps <- apply(as.data.frame(lapply(d, fmt)), 1, paste, collapse = " & ")
  writeLines(c(paste0("\\begin{tabular}{", alignement, "}"), "\\toprule",
               paste(gsub("_", "\\\\_", names(d)), collapse = " & "), "\\\\", "\\midrule",
               paste(gsub("_", "\\\\_", corps), "\\\\"), "\\bottomrule", "\\end{tabular}"), f)
}

# ---------------------------------------------------------------------------
hr("Etape 0a. Cache allege : une lecture par .DTA (stage)")
# ---------------------------------------------------------------------------

check(requireNamespace("haven", quietly = TRUE), "haven se charge")
caches <- list(); dicos <- list()
for (i in seq_len(nrow(VAGUES))) {
  r <- VAGUES[i]
  check(file.exists(r$dta), paste(r$vague, ": fichier HR present"), r$dta)
  ent <- dta_entete(r$dta)
  msg(r$vague, " : ", basename(r$dta), ", format Stata ", ent$format, ", ",
      ent$K, " variables, ", ent$N, " lignes (en-tete)")
  x <- stage(paste("cache", r$vague), p_build(paste0("24_cache_", r$vague, ".rds")),
             after = r$dta, build = function() {
    d0 <- haven::read_dta(r$dta, n_max = 0)
    dico <- data.table(variable = names(d0),
                       libelle = vapply(d0, lib, character(1)))
    eau <- dico[!grepl("_[0-9]+$", variable) &
                  (grepl(MOTIF_EAU_NOM, variable) |
                     grepl(MOTIF_EAU_LIB, libelle, ignore.case = TRUE)), variable]
    tmsg(r$vague, " : lecture de ", length(unique(c(VARS, eau))), " colonnes + serie hv237")
    d <- haven::read_dta(r$dta, col_select = c(tidyselect::any_of(unique(c(VARS, eau))),
                                               tidyselect::matches(MOTIF_HV237)))
    list(d = d, dico = dico, eau = eau)
  })
  check_rows(x$d, ent$N, paste(r$vague, "(N de l'en-tete Stata)"))
  check(nrow(x$d) == r$n_doc, sprintf("A1 %s : %d menages == %d publies", r$vague, nrow(x$d), r$n_doc))
  check_unique(as.data.table(x$d[, "hhid"]), "hhid", r$vague)
  check(all(startsWith(as.character(haven::zap_labels(x$d$hv000)), "IA")),
        paste(r$vague, ": hv000 commence par IA"))
  msg(r$vague, " : annees d'entretien (hv007) ",
      paste(names(table(num(x$d$hv007))), table(num(x$d$hv007)), sep = ":", collapse = " "))
  caches[[r$vague]] <- x$d; dicos[[r$vague]] <- x
}

# ---------------------------------------------------------------------------
hr("Etape 0b. Disponibilite de la serie hv237 (A2)")
# ---------------------------------------------------------------------------

dispo <- rbindlist(lapply(VAGUES$vague, function(v) {
  dico <- dicos[[v]]$dico
  s <- dico[grepl(MOTIF_HV237, variable)]
  s[, codes := vapply(variable, function(k) {
    e <- etiquettes(caches[[v]][[k]]); paste(paste0(e$code, "=", e$libelle), collapse = " | ")
  }, character(1))]
  s[, vague := v]
  s[, .(vague, variable, libelle, codes)]
}))
print(dispo, row.names = FALSE, nrows = 200)
fwrite(dispo, p_tab("24_etape0_disponibilite_hv237.csv"))
for (v in VAGUES$vague) {
  check_vars(caches[[v]], c("hv237", METHODES), paste("A2", v))
  check(grepl("filter", lib(caches[[v]]$hv237d), ignore.case = TRUE),
        paste("A2", v, ": hv237d =", lib(caches[[v]]$hv237d)))
  check(grepl("(electric|electronic) purifier", lib(caches[[v]]$hv237h), ignore.case = TRUE),
        paste("A2", v, ": hv237h =", lib(caches[[v]]$hv237h)))
}
msg("Formulation (libelles DHS du fichier ; questionnaires absents de raw/) :")
for (v in VAGUES$vague) msg("  ", v, " hv237 : « ", lib(caches[[v]]$hv237), " » ; methodes : « ",
                            sub(":.*$", ":", lib(caches[[v]]$hv237d)), " ... » (une variable 0/1 par methode)")

# ---------------------------------------------------------------------------
hr("Etape 0c. Table menage harmonisee, univers et non-reponse (A3)")
# ---------------------------------------------------------------------------

recode_bidonville <- function(x) {
  e <- etiquettes(x)
  check(setequal(tolower(e$libelle), c("slum", "non-slum")),
        "shslumc : libelles slum / non-slum", paste(e$libelle, collapse = ", "))
  code_slum <- e[tolower(libelle) == "slum", code]
  y <- num(x)
  fifelse(is.na(y), NA_character_, fifelse(y == code_slum, "bidonville", "hors bidonville"))
}

menages <- list()
for (v in VAGUES$vague) {
  d <- caches[[v]]
  m <- data.table(vague = v, w = num(d$hv005) / 1e6, strate = num(d$hv022),
                  psu = if ("hv021" %in% names(d) && uniqueN(num(d$hv021)) > 1L)
                          num(d$hv021) else num(d$hv001),
                  grappe = num(d$hv001), urbain = num(d$hv025) == 1,
                  t = num(d$hv237))
  for (k in names(METHODES)) {
    mm <- num(d[[METHODES[[k]]]])
    m[, (paste0("brut_", k)) := mm]
    m[, (k) := fifelse(t == 0, 0, fifelse(t == 1 & mm %in% c(0, 1), mm, NA_real_))]
  }
  m[, bidonville := if ("shslumc" %in% names(d)) recode_bidonville(d$shslumc) else NA_character_]
  menages[[v]] <- m
  msg(v, " : univers -- croisement non pondere hv237 x hv237d puis hv237 x hv237h")
  print(m[, .N, by = .(hv237 = t, hv237d = brut_filtre)][order(hv237, hv237d)], row.names = FALSE)
  print(m[, .N, by = .(hv237 = t, hv237h = brut_purificateur)][order(hv237, hv237h)], row.names = FALSE)
}

effectifs <- rbindlist(lapply(VAGUES$vague, function(v) {
  m <- menages[[v]]
  data.table(vague = v, periode = VAGUES[vague == v, periode], menages = nrow(m),
             menages_urbains = sum(m$urbain), menages_ruraux = sum(!m$urbain),
             part_hv237_manquante = mean(is.na(m$t)),
             part_hv237_nsp = mean(m$t %in% 8),
             part_traite = mean(m$t %in% 1),
             part_methode_nr_filtre = mean(m$t %in% 1 & !(m$brut_filtre %in% c(0, 1))),
             part_methode_nr_purificateur = mean(m$t %in% 1 & !(m$brut_purificateur %in% c(0, 1))),
             nonrep_filtre = mean(is.na(m$filtre)),
             nonrep_purificateur = mean(is.na(m$purificateur)))
}))
print(effectifs, row.names = FALSE)
fwrite(effectifs, p_tab("24_etape0_effectifs_nonreponse.csv"))
for (v in VAGUES$vague) for (k in names(METHODES)) {
  nr <- effectifs[vague == v][[paste0("nonrep_", k)]]
  check(nr <= SEUIL_NONREP, sprintf("A3 %s %s : non-reponse %.2f %% <= %.0f %%", v, k,
                                    100 * nr, 100 * SEUIL_NONREP))
}

# ---------------------------------------------------------------------------
hr("Etape 1a. Taux d'adoption ponderes : ensemble, urbain, rural (A4)")
# ---------------------------------------------------------------------------

adoption <- rbindlist(lapply(VAGUES$vague, function(v) {
  m <- menages[[v]]
  zones <- list(ensemble = rep(TRUE, nrow(m)), urbain = m$urbain, rural = !m$urbain)
  rbindlist(lapply(names(zones), function(z) rbindlist(lapply(names(METHODES), function(k)
    cbind(data.table(vague = v, periode = VAGUES[vague == v, periode], zone = z, methode = k),
          taux_pondere(m, m[[k]], zones[[z]]))))))
}))
adoption[, `:=`(pct = 100 * taux, ic_bas = 100 * (taux - 1.96 * se), ic_haut = 100 * (taux + 1.96 * se))]
print(adoption[, .(vague, zone, methode, n, n_oui, pct = round(pct, 2),
                   ic_bas = round(ic_bas, 2), ic_haut = round(ic_haut, 2))], row.names = FALSE)
fwrite(adoption, p_tab("24_etape1_adoption_national.csv"))
ecrire_tex(adoption[, .(periode, zone, methode, menages = n, pct, ic_bas, ic_haut)],
           p_tab("24_etape1_adoption_national.tex"), "lllrrrr")
es5 <- etiquettes(caches[["nfhs5"]]$hv024)
c_bihar <- es5[tolower(trimws(libelle)) == "bihar", code]
check(length(c_bihar) == 1L, sprintf("A4 nfhs5 : Etat « bihar » trouve une fois (code %s)",
                                     paste(c_bihar, collapse = ",")))
m5 <- menages[["nfhs5"]]
bihar <- taux_pondere(m5, m5$purificateur, m5$urbain & num(caches[["nfhs5"]]$hv024) == c_bihar)
msg("nfhs5 Bihar urbain, purificateur : n = ", bihar$n, ", ", sprintf("%.2f %% [%.2f ; %.2f]",
    100 * bihar$taux, 100 * (bihar$taux - 1.96 * bihar$se), 100 * (bihar$taux + 1.96 * bihar$se)))
check(abs(bihar$taux - REPERE_BIHAR_URBAIN) <= TOL_REPERE,
      sprintf("A4 NFHS-5 Bihar urbain purificateur : %.2f %% contre repere %.1f %% (+/- %.1f)",
              100 * bihar$taux, 100 * REPERE_BIHAR_URBAIN, 100 * TOL_REPERE))

# ---------------------------------------------------------------------------
hr("Etape 1b. Les huit villes du NFHS-3, bidonville / hors bidonville (A5)")
# ---------------------------------------------------------------------------

# NFHS-3 : echantillon de ville de l'enquete.
d3 <- caches[["nfhs3"]]
e3 <- etiquettes(d3$shcity)
e3[, ville := sub(" city$", "", tolower(libelle))]
check(setequal(e3$ville, VILLES), "A5 shcity porte exactement les huit villes",
      paste(e3$libelle, collapse = ", "))
menages[["nfhs3"]][, ville := e3$ville[match(num(d3$shcity), e3$code)]]
msg("nfhs3 : menages de l'echantillon des villes : ", sum(!is.na(menages$nfhs3$ville)),
    " ; dont urbains (hv025) : ", sum(!is.na(menages$nfhs3$ville) & menages$nfhs3$urbain),
    " ; bidonville renseigne : ", sum(!is.na(menages$nfhs3$ville) & !is.na(menages$nfhs3$bidonville)))

# NFHS-4/5 : approximation district urbain (Delhi = Etat urbain).
for (v in c("nfhs4", "nfhs5")) {
  d <- caches[[v]]
  vd <- intersect(c("shdistri", "shdist"), names(d))
  check(length(vd) == 1L, paste(v, ": une variable de district"), paste(vd, collapse = ", "))
  ed <- etiquettes(d[[vd]]); ed[, l := tolower(trimws(libelle))]
  es <- etiquettes(d$hv024); es[, l := tolower(trimws(libelle))]
  dist <- num(d[[vd]]); etat <- num(d$hv024)
  ville <- rep(NA_character_, nrow(d))
  for (cv in names(VILLES_DIST)) for (lb in VILLES_DIST[[cv]]) {
    cd <- ed[l == lb, code]
    check(length(cd) == 1L, sprintf("A5 %s : district « %s » trouve une fois (code %s)", v, lb,
                                    paste(cd, collapse = ",")))
    ville[dist == cd] <- cv
  }
  cdel <- es[l %in% DELHI_ETAT, code]
  check(length(cdel) == 1L, sprintf("A5 %s : Etat de Delhi trouve une fois (code %s)", v,
                                    paste(cdel, collapse = ",")))
  ville[etat == cdel] <- "delhi"
  menages[[v]][, ville := fifelse(urbain, ville, NA_character_)]
  msg(v, " : menages urbains des huit villes (approximation district) : ",
      sum(!is.na(menages[[v]]$ville)))
}

villes <- rbindlist(lapply(VAGUES$vague, function(v) {
  m <- menages[[v]]
  defn <- if (v == "nfhs3") "echantillon shcity" else "district urbain (approx.)"
  rbindlist(lapply(c("8 villes", VILLES), function(cv) {
    dom_v <- if (cv == "8 villes") !is.na(m$ville) else m$ville %in% cv
    strates <- list(ensemble = dom_v)
    if (!all(is.na(m$bidonville[dom_v]))) {
      strates$bidonville <- dom_v & m$bidonville %in% "bidonville"
      strates$`hors bidonville` <- dom_v & m$bidonville %in% "hors bidonville"
    }
    rbindlist(lapply(names(strates), function(b) rbindlist(lapply(names(METHODES), function(k)
      cbind(data.table(vague = v, periode = VAGUES[vague == v, periode], definition = defn,
                       ville = cv, bidonville = b, methode = k),
            taux_pondere(m, m[[k]], strates[[b]]))))))
  }))
}))
villes[, `:=`(pct = 100 * taux, ic_bas = 100 * (taux - 1.96 * se), ic_haut = 100 * (taux + 1.96 * se))]
print(villes[, .(vague, ville, bidonville, methode, n, n_oui, pct = round(pct, 2),
                 ic_bas = round(ic_bas, 2), ic_haut = round(ic_haut, 2))], row.names = FALSE, nrows = 500)
fwrite(villes, p_tab("24_etape1_adoption_villes.csv"))
ecrire_tex(villes[ville == "8 villes", .(periode, definition, bidonville, methode, menages = n,
                                          pct, ic_bas, ic_haut)],
           p_tab("24_etape1_adoption_8villes.tex"), "llllrrrr")

# ---------------------------------------------------------------------------
hr("Etape 2. Inventaire des variables de source d'eau (comptes NON ponderes)")
# ---------------------------------------------------------------------------

vars_eau <- rbindlist(lapply(VAGUES$vague, function(v) {
  d <- caches[[v]]; e <- dicos[[v]]$eau
  e <- e[!grepl(MOTIF_HV237, e)]
  data.table(vague = v, variable = e,
             libelle = vapply(e, function(k) lib(d[[k]]), character(1)),
             part_non_manquante = vapply(e, function(k) mean(!is.na(d[[k]])), numeric(1)),
             n_modalites_etiquetees = vapply(e, function(k) nrow(etiquettes(d[[k]])), integer(1)))
}))
print(vars_eau, row.names = FALSE, nrows = 300)
fwrite(vars_eau, p_tab("24_etape2_variables_eau.csv"))

modalites <- rbindlist(lapply(VAGUES$vague, function(v) {
  rbindlist(lapply(intersect(c("hv201", "hv202"), names(caches[[v]])), function(k) {
    x <- caches[[v]][[k]]; e <- etiquettes(x)
    n <- data.table(code = num(x))[, .N, by = code]
    out <- merge(e, n, by = "code", all = TRUE)
    out[is.na(N), N := 0L]
    out[, `:=`(vague = v, variable = k)]
    out[, .(vague, variable, code, libelle, n_non_pondere = N)]
  }))
}))
print(modalites, row.names = FALSE, nrows = 300)
fwrite(modalites, p_tab("24_etape2_hv201_hv202_modalites.csv"))

# Ruptures : un meme code avec des libelles differents, ou un meme libelle
# sous des codes differents, entre vagues (hv201).
h201 <- modalites[variable == "hv201"]
large <- dcast(h201, code ~ vague, value.var = "libelle")
large[, rupture_code := apply(.SD, 1, function(z) length(unique(na.omit(z))) > 1L |
                                any(is.na(z))), .SDcols = VAGUES$vague]
par_lib <- h201[, .(codes = paste(sort(unique(code)), collapse = ",")), by = .(libelle = tolower(libelle))]
par_lib <- par_lib[grepl(",", codes)]
msg("hv201 : codes par vague (libelle absent = code non etiquete dans la vague)")
print(large, row.names = FALSE)
msg("hv201 : libelles portes par plusieurs codes selon la vague")
print(par_lib, row.names = FALSE)
fwrite(large, p_tab("24_etape2_hv201_ruptures.csv"))

# ---------------------------------------------------------------------------
hr("Etape 3. Georeferencement (fichiers GE) (A6)")
# ---------------------------------------------------------------------------

geo <- rbindlist(lapply(VAGUES$vague, function(v) {
  r <- VAGUES[vague == v]
  grappes_hr <- unique(menages[[v]]$grappe)
  if (is.na(r$ge) || !file.exists(r$ge)) {
    msg(v, " : aucun fichier GE dans raw/dhs/india")
    return(data.table(vague = v, fichier_ge = NA_character_, grappes_hr = length(grappes_hr)))
  }
  g <- as.data.table(sf::st_drop_geometry(sf::st_read(r$ge, quiet = TRUE)))
  check_unique(g, "DHSCLUST", paste(v, "GE"))
  g[, valide := SOURCE != "MIS" & !(LATNUM == 0 & LONGNUM == 0) & !is.na(LATNUM)]
  absentes <- setdiff(grappes_hr, g$DHSCLUST)
  check(length(absentes) == 0L, sprintf("A6 %s : toute grappe HR presente dans le GE", v),
        paste(length(absentes), "grappes absentes"))
  data.table(vague = v, fichier_ge = basename(r$ge), grappes_hr = length(grappes_hr),
             grappes_ge = nrow(g), ge_sans_menage = sum(!g$DHSCLUST %in% grappes_hr),
             valides = sum(g$valide), source_gps = sum(g$SOURCE == "GPS"),
             source_gaz = sum(g$SOURCE == "GAZ"), source_mis = sum(g$SOURCE == "MIS"),
             valides_parmi_hr = sum(g$valide & g$DHSCLUST %in% grappes_hr),
             valides_urbaines = sum(g$valide & g$URBAN_RURA == "U"))
}), fill = TRUE)
print(geo, row.names = FALSE)
fwrite(geo, p_tab("24_etape3_georeferencement.csv"))

hr("Limites a consigner")
msg("- adoption declaree par le repondant ;")
msg("- la question porte sur ce que le menage fait « habituellement » ;")
msg("- coordonnees DHS deplacees aleatoirement (2 km urbain, 5 km rural, 10 km pour 1 % du rural) ;")
msg("  grappes GAZ placees au gazetier ;")
msg("- huit villes en NFHS-4/5 : approximation district urbain, pas le perimetre du NFHS-3.")

log_close()
