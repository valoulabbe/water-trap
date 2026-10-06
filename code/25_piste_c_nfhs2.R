# ---------------------------------------------------------------------------
# 25_piste_c_nfhs2.R -- piste C : le NFHS-2 (1998-99) porte-t-il une serie de
#   methodes de traitement de l'eau qui recule le point de depart a 1998 ?
#
# OBJET : DESCRIPTIF SEULEMENT. Aucune regression, aucune issue construite,
# aucun critere d'analyse.
#   Etape 0  inventaire des variables d'eau / de traitement du HR NFHS-2
#            (nom, libelle exact, modalites) ; serie hv237 ou equivalent sh*.
#            Structure des reponses : indicatrices multiples ou modalites
#            exclusives, comparee a celle de hv237 en 2005-2021.
#   Etape 1  taux d'adoption ponderes par methode, national / urbain / rural,
#            IC a 95 % ; effectifs et non-reponse ; serie a quatre vagues
#            (1998 + 2005-2021 repris de output/tables/24_etape1_adoption_national.csv).
#   Etape 2  modalites de hv201 en 1998 et raccord au codage des vagues
#            recentes (inventaire ; comptes NON ponderes ; la table de raccord
#            est un codage de jugement a relire, pas une variable construite).
#   Etape 3  fichier GE du NFHS-2 dans raw/ : oui / non.
#
# CONSTATS DEJA FAITS SUR L'EN-TETE (06/10, lecture n_max = 0) :
#   - Pas de serie hv237. Serie specifique Inde sh32a-sh32x, une variable
#     0/1 par methode : a = strain by cloth, b = alum, c = water filter,
#     d = boil, e = electronic purifier, f = use nothing, x = other.
#     Pas de question filtre « anything done to water ».
#   - hv202 et hv203 « na ». hv201 a un codage propre a la phase 4 (pompe a
#     main / puits « in residence » contre « public »).
#   - Trois poids : hv005 « sample weight », shv005 « state household
#     weight », nhv005 « all india sample hh weight (without tripura) ».
#   - Pas de fichier GE dans raw/dhs/india/1998.
#   - Le questionnaire du NFHS-2 n'est pas dans raw/ : formulation d'apres
#     les libelles du fichier.
#
# ATTENTES (ECRITES AVANT EXECUTION ; si l'une tombe, arret dur et question a
# Valentine, aucun ajustement) :
#   B1  Nombre de menages du HR a +/- 500 de 92 500 (chiffre publie du
#       NFHS-2, « environ 92 500 », transmis par Valentine) ; le nombre de
#       lignes est aussi controle contre l'en-tete binaire Stata.
#   B2  sh32a, sh32b, sh32c, sh32d, sh32e, sh32f, sh32x presentes ; libelle
#       de sh32c contient « filter », celui de sh32e « purifier ».
#   B3  Non-reponse de sh32c et de sh32e (valeur manquante ou hors 0/1)
#       <= 2 % des menages.
#   B4  Coherence interne : part des menages declarant sh32f = 1 (« use
#       nothing ») ET une methode de traitement = 1 <= 1 %.
#   B5  Les trois vagues 2005-2021 relues depuis la table du script 24 sont
#       celles qui ont passe ses attentes (fichier present, 18 lignes,
#       vagues nfhs3/4/5, zones ensemble/urbain/rural, methodes
#       filtre/purificateur).
#   Pas de repere publie disponible localement pour valider un taux 1998 :
#   aucune attente de niveau n'est donc ecrite, et aucun taux 1998 n'est
#   valide par une source externe (a consigner).
#
# REGLES DECIDEES AVANT EXECUTION
#   Poids : nhv005 (poids national documente) pour les taux de reference ;
#   la meme table avec hv005 est produite en parallele ; la relation entre
#   hv005, shv005 et nhv005 est journalisee. Un ecart de plus de 0,2 point
#   entre les deux ponderations est signale (pas resolu).
#   Adoption 1998 d'une methode m : sh32m (0/1), denominateur = ensemble des
#   menages a sh32m renseignee. Pas de filtre amont : la structure differe de
#   hv237 (filtre « anything done ? » puis methodes) -- signale comme rupture
#   de questionnaire, pas corrige.
#   Erreur-type : linearisation, grappe hv021 dans la strate hv022 (hv001 si
#   hv021 ne varie pas ; strate unique si hv022 ne varie pas ou manque).
#   Les deux identifiants sont pris DANS l'Etat (hv024) : numerotation par
#   Etat en NFHS-2 (corrige apres le premier passage, erreurs-types seules).
#
# LIMITES A CONSIGNER : adoption declaree ; comparabilite des questionnaires
# entre phases DHS eloignees de vingt ans (formulation, filtre amont,
# « electronic » contre « electric purifier ») ; le NFHS-1 (1992-93) n'est
# pas examine.
#
# LANCEMENT (racine du depot) :
#     Rscript code/25_piste_c_nfhs2.R           # reprend
#     Rscript code/25_piste_c_nfhs2.R --force   # relit le .DTA
# Depend de : build/24_cache_nfhs{3,4,5}.rds et
#             output/tables/24_etape1_adoption_national.csv (script 24).
# Etape resumable : build/25_cache_nfhs2.rds.
# Sorties : output/tables/25_*.csv (+ .tex) ; output/logs/25_piste_c_nfhs2.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("25_piste_c_nfhs2.log"))
msg("ETAPE 25 -- PISTE C : NFHS-2 (1998-99), SERIE DE TRAITEMENT DE L'EAU")
msg("Descriptif seulement : aucune regression, aucune issue, aucun critere.")

F_DTA  <- p_raw("dhs", "india", "1998", "IAHR42DT", "IAHR42FL.DTA")
D_1998 <- p_raw("dhs", "india", "1998")
F_T24  <- p_tab("24_etape1_adoption_national.csv")
CACHES_24 <- p_build(paste0("24_cache_", c("nfhs3", "nfhs4", "nfhs5"), ".rds"))

N_PUBLIE <- 92500L; TOL_N <- 500L                          # B1
SH32 <- c(tissu = "sh32a", alun = "sh32b", filtre = "sh32c", ebullition = "sh32d",
          purificateur = "sh32e", rien = "sh32f", autre = "sh32x")
METHODES <- c(filtre = "sh32c", purificateur = "sh32e")
SEUIL_NONREP <- 0.02                                       # B3
SEUIL_INCOH  <- 0.01                                       # B4
ECART_POIDS  <- 0.002

# Colonnes du cache : design, poids, milieu, eau, serie sh32.
VARS <- c("hhid", "hv000", "hv001", "hv002", "hv005", "shv005", "nhv005", "hv007",
          "hv021", "hv022", "hv023", "hv024", "hv025", "hv026", "sdist",
          "slumarea", "slumhh", "hv201", "hv202", "hv203", "hv204")
MOTIF_EAU_LIB <- "water|drink|treat|filter|purif|boil|pipe|tap|safe|cloth|alum|chlor|bleach|strain|settle"

hr("Attentes ecrites avant execution")
msg("B1  N menages a +/- ", TOL_N, " de ", N_PUBLIE)
msg("B2  sh32a-f, sh32x presentes ; sh32c ~ filter ; sh32e ~ purifier")
msg("B3  non-reponse de sh32c et sh32e <= ", SEUIL_NONREP * 100, " %")
msg("B4  sh32f = 1 et une methode = 1 : <= ", SEUIL_INCOH * 100, " % des menages")
msg("B5  table du script 24 : 18 lignes attendues (3 vagues x 3 zones x 2 methodes)")
msg("Aucun repere publie local pour un taux 1998 : pas d'attente de niveau.")

# --- utilitaires (repris des scripts 14 et 24) -------------------------------

num <- function(x) as.numeric(haven::zap_labels(x))
lib <- function(x) attr(x, "label", exact = TRUE) %||% NA_character_
etiquettes <- function(x) {
  l <- attr(x, "labels", exact = TRUE)
  if (is.null(l)) return(data.table(code = numeric(), libelle = character()))
  data.table(code = as.numeric(l), libelle = names(l))
}
modalites_txt <- function(x) {
  e <- etiquettes(x); if (!nrow(e)) return("")
  paste(paste0(e$code, "=", e$libelle), collapse = " | ")
}

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

taux_pondere <- function(w, strate, psu, y, dom) {
  ok <- dom & !is.na(y)
  if (!any(ok)) return(data.table(n = 0L, n_oui = 0L, taux = NA_real_, se = NA_real_))
  W <- sum(w[ok]); r <- sum(w[ok] * y[ok]) / W
  z <- numeric(length(y)); z[ok] <- w[ok] * (y[ok] - r) / W
  tt <- data.table(s = strate, p = psu, z = z)[, .(z = sum(z)), by = .(s, p)]
  v  <- tt[, .(nh = .N, ss = sum((z - mean(z))^2)), by = s][nh > 1, sum(nh / (nh - 1) * ss)]
  data.table(n = sum(ok), n_oui = as.integer(sum(y[ok] == 1)), taux = r, se = sqrt(v))
}

ecrire_tex <- function(d, f, alignement) {
  fmt <- function(x) if (is.integer(x)) formatC(x, format = "d", big.mark = ",") else
    if (is.numeric(x)) formatC(x, format = "f", digits = 1) else x
  corps <- apply(as.data.frame(lapply(d, fmt)), 1, paste, collapse = " & ")
  writeLines(c(paste0("\\begin{tabular}{", alignement, "}"), "\\toprule",
               paste(gsub("_", "\\\\_", names(d)), collapse = " & "), "\\\\", "\\midrule",
               paste(gsub("_", "\\\\_", corps), "\\\\"), "\\bottomrule", "\\end{tabular}"), f)
}

# ---------------------------------------------------------------------------
hr("Etape 0a. Cache allege du HR NFHS-2 (stage)")
# ---------------------------------------------------------------------------

check(requireNamespace("haven", quietly = TRUE), "haven se charge")
check(file.exists(F_DTA), "NFHS-2 : fichier HR present", F_DTA)
ent <- dta_entete(F_DTA)
msg("nfhs2 : ", basename(F_DTA), ", format Stata ", ent$format, ", ", ent$K,
    " variables, ", ent$N, " lignes (en-tete)")
x <- stage("cache nfhs2", p_build("25_cache_nfhs2.rds"), after = F_DTA, build = function() {
  d0 <- haven::read_dta(F_DTA, n_max = 0)
  dico <- data.table(variable = names(d0),
                     libelle = vapply(d0, lib, character(1)),
                     modalites = vapply(d0, modalites_txt, character(1)))
  eau <- dico[!grepl("_[0-9]+$", variable) &
                (grepl("^hv2[0-2][0-9]$", variable) | grepl("^sh32", variable) |
                   grepl(MOTIF_EAU_LIB, libelle, ignore.case = TRUE)), variable]
  d <- haven::read_dta(F_DTA, col_select = tidyselect::any_of(unique(c(VARS, eau))))
  list(d = d, dico = dico, eau = eau)
})
d <- x$d
check_rows(d, ent$N, "nfhs2 (N de l'en-tete Stata)")
check(abs(nrow(d) - N_PUBLIE) <= TOL_N,
      sprintf("B1 nfhs2 : %d menages, a +/- %d de %d", nrow(d), TOL_N, N_PUBLIE))
check_unique(as.data.table(d[, "hhid"]), "hhid", "nfhs2")
check(all(startsWith(as.character(haven::zap_labels(d$hv000)), "IA")), "nfhs2 : hv000 commence par IA")
msg("nfhs2 : annees d'entretien (hv007) ",
    paste(names(table(num(d$hv007))), table(num(d$hv007)), sep = ":", collapse = " "))

# ---------------------------------------------------------------------------
hr("Etape 0b. Inventaire : variables d'eau et de traitement (libelles exacts)")
# ---------------------------------------------------------------------------

inv <- x$dico[variable %in% x$eau]
inv[, part_non_manquante := vapply(variable, function(k) mean(!is.na(d[[k]])), numeric(1))]
print(inv, row.names = FALSE, nrows = 200)
fwrite(inv, p_tab("25_etape0_inventaire_variables.csv"))
msg("Serie hv237 presente : ", any(grepl("^hv237", x$dico$variable)))
msg("Variables sh32* : ", paste(grep("^sh32", x$dico$variable, value = TRUE), collapse = ", "))

check_vars(d, SH32, "B2 nfhs2")
check(grepl("filter", lib(d$sh32c), ignore.case = TRUE), paste("B2 sh32c =", lib(d$sh32c)))
check(grepl("purifier", lib(d$sh32e), ignore.case = TRUE), paste("B2 sh32e =", lib(d$sh32e)))

# ---------------------------------------------------------------------------
hr("Etape 0c. Structure des reponses : exclusives ou multiples ?")
# ---------------------------------------------------------------------------

s <- as.data.table(lapply(SH32, function(k) num(d[[k]])))
for (k in names(SH32)) msg(sprintf("  %-12s %-6s valeurs : %s", k, SH32[[k]],
                                   paste(names(table(s[[k]], useNA = "ifany")),
                                         table(s[[k]], useNA = "ifany"), sep = ":", collapse = " ")))
traitements <- setdiff(names(SH32), "rien")
s[, n_methodes := rowSums(.SD == 1, na.rm = TRUE), .SDcols = traitements]
s[, n_cases := rowSums(.SD == 1, na.rm = TRUE), .SDcols = names(SH32)]
msg("Nombre de methodes de traitement declarees par menage (hors « rien »), non pondere :")
print(s[, .N, by = n_methodes][order(n_methodes)][, part := round(N / sum(N), 4)], row.names = FALSE)
msg("Nombre total de cases cochees (y compris « rien ») : ")
print(s[, .N, by = n_cases][order(n_cases)][, part := round(N / sum(N), 4)], row.names = FALSE)
incoh <- mean(s$rien %in% 1 & s$n_methodes > 0)
check(incoh <= SEUIL_INCOH, sprintf("B4 « rien » et une methode : %.3f %% <= %.0f %%",
                                    100 * incoh, 100 * SEUIL_INCOH))

# Meme description pour hv237 (2005-2021), depuis les caches du script 24.
structure_n <- list(nfhs2 = s[, .(n_methodes)][, vague := "nfhs2"])
for (f in CACHES_24) {
  check(file.exists(f), paste("cache du script 24 present :", f))
  v <- sub("^24_cache_(.*)[.]rds$", "\\1", basename(f))
  c24 <- readRDS(f)$d
  meth <- grep("^hv237[a-x]$", names(c24), value = TRUE)
  meth <- meth[!grepl("^na - ", vapply(meth, function(k) lib(c24[[k]]), character(1)))]
  meth <- setdiff(meth, meth[grepl("s-na|c-na", vapply(meth, function(k) lib(c24[[k]]), character(1)))])
  m <- as.data.table(lapply(meth, function(k) num(c24[[k]])))
  structure_n[[v]] <- data.table(n_methodes = rowSums(m == 1, na.rm = TRUE), vague = v)
  msg(v, " : methodes hv237 comptees : ", paste(meth, collapse = ", "))
}
structure <- rbindlist(structure_n)[, .N, by = .(vague, n_methodes)][order(vague, n_methodes)]
structure[, part := N / sum(N), by = vague]
msg("Repartition du nombre de methodes declarees, par vague (non pondere) :")
print(dcast(structure, n_methodes ~ vague, value.var = "part", fill = 0), row.names = FALSE)
fwrite(structure, p_tab("25_etape0_structure_reponses.csv"))

# ---------------------------------------------------------------------------
hr("Etape 1a. Effectifs, non-reponse, poids (B3)")
# ---------------------------------------------------------------------------

w_n <- num(d$nhv005) / 1e6; w_h <- num(d$hv005) / 1e6; w_s <- num(d$shv005) / 1e6
msg("Poids : nhv005 manquant ou nul pour ", sum(is.na(w_n) | w_n == 0), " menages ; ",
    "hv005 manquant ou nul pour ", sum(is.na(w_h) | w_h == 0))
msg("hv005 == nhv005 pour ", round(100 * mean(abs(w_h - w_n) < 1e-9, na.rm = TRUE), 2), " % des menages ; ",
    "hv005 == shv005 pour ", round(100 * mean(abs(w_h - w_s) < 1e-9, na.rm = TRUE), 2), " %")
etats <- etiquettes(d$hv024)
st <- data.table(etat = num(d$hv024), wn = w_n)[, .(menages = .N, nhv005_nul = sum(is.na(wn) | wn == 0)), by = etat]
st[, nom := etats$libelle[match(etat, etats$code)]]
msg("Etats ou nhv005 est nul ou manquant :")
print(st[nhv005_nul > 0], row.names = FALSE)

# En NFHS-2, hv001/hv021 (1-333) et hv022 (1-164) sont numerotes DANS chaque
# Etat : grappe = (hv024, hv021), strate = (hv024, hv022). Constat du premier
# passage (496 grappes au lieu de 3 215) ; ne change que les erreurs-types.
etat_num <- num(d$hv024)
strate <- num(d$hv022); if (all(is.na(strate)) || uniqueN(strate) == 1L) strate <- rep(1, nrow(d))
strate <- paste(etat_num, strate)
psu <- paste(etat_num, if (uniqueN(num(d$hv021)) > 1L) num(d$hv021) else num(d$hv001))
check(uniqueN(paste(strate, psu)) == uniqueN(paste(etat_num, num(d$hv001))),
      "design : une grappe (Etat, hv021) par grappe (Etat, hv001)")
msg("Design : ", uniqueN(strate), " strates, ", uniqueN(paste(strate, psu)), " grappes")
urbain <- num(d$hv025) == 1

effectifs <- data.table(vague = "nfhs2", periode = "1998-99", menages = nrow(d),
                        menages_urbains = sum(urbain, na.rm = TRUE),
                        menages_ruraux = sum(!urbain, na.rm = TRUE),
                        nonrep_filtre = mean(!(s$filtre %in% c(0, 1))),
                        nonrep_purificateur = mean(!(s$purificateur %in% c(0, 1))),
                        poids_nhv005_nul = mean(is.na(w_n) | w_n == 0))
print(effectifs, row.names = FALSE)
fwrite(effectifs, p_tab("25_etape1_effectifs_nonreponse.csv"))
for (k in names(METHODES)) {
  nr <- effectifs[[paste0("nonrep_", k)]]
  check(nr <= SEUIL_NONREP, sprintf("B3 nfhs2 %s : non-reponse %.2f %% <= %.0f %%", k, 100 * nr,
                                    100 * SEUIL_NONREP))
}

# ---------------------------------------------------------------------------
hr("Etape 1b. Taux d'adoption 1998 par methode, ponderes")
# ---------------------------------------------------------------------------

zones <- list(ensemble = rep(TRUE, nrow(d)), urbain = urbain, rural = !urbain)
adopt98 <- rbindlist(lapply(c(nhv005 = "nhv005", hv005 = "hv005"), function(pw) {
  w <- if (pw == "nhv005") w_n else w_h
  okw <- !is.na(w) & w > 0
  rbindlist(lapply(names(zones), function(z) rbindlist(lapply(setdiff(names(SH32), "rien"), function(k) {
    y <- fifelse(s[[k]] %in% c(0, 1), s[[k]], NA_real_)
    cbind(data.table(poids = pw, vague = "nfhs2", periode = "1998-99", zone = z, methode = k),
          taux_pondere(fifelse(okw, w, 0), strate, psu, y, zones[[z]] & okw))
  }))))
}))
adopt98[, `:=`(pct = 100 * taux, ic_bas = 100 * (taux - 1.96 * se), ic_haut = 100 * (taux + 1.96 * se))]
print(adopt98[, .(poids, zone, methode, n, n_oui, pct = round(pct, 2), ic_bas = round(ic_bas, 2),
                  ic_haut = round(ic_haut, 2))], row.names = FALSE, nrows = 100)
fwrite(adopt98, p_tab("25_etape1_adoption_1998.csv"))
ec <- dcast(adopt98, zone + methode ~ poids, value.var = "taux")[, ecart := abs(nhv005 - hv005)]
msg("Ecart entre ponderations nhv005 et hv005 (points) :")
print(ec[, .(zone, methode, ecart_points = round(100 * ecart, 3))], row.names = FALSE)
if (any(ec$ecart > ECART_POIDS))
  warn("ecart > ", 100 * ECART_POIDS, " point entre nhv005 et hv005 : signale, non resolu")

# ---------------------------------------------------------------------------
hr("Etape 1c. Serie fine a quatre vagues : filtre et purificateur (B5)")
# ---------------------------------------------------------------------------

check(file.exists(F_T24), "B5 table du script 24 presente", F_T24)
t24 <- fread(F_T24)
check(nrow(t24) == 18L && setequal(t24$vague, c("nfhs3", "nfhs4", "nfhs5")) &&
        setequal(t24$zone, c("ensemble", "urbain", "rural")) &&
        setequal(t24$methode, names(METHODES)),
      "B5 table du script 24 : 18 lignes, 3 vagues x 3 zones x 2 methodes")
cols <- c("vague", "periode", "zone", "methode", "n", "n_oui", "pct", "ic_bas", "ic_haut")
serie <- rbind(adopt98[poids == "nhv005" & methode %in% names(METHODES), ..cols],
               t24[, ..cols])
serie[, variable := fifelse(vague == "nfhs2", unname(METHODES[methode]), fifelse(methode == "filtre", "hv237d", "hv237h"))]
serie[, structure_question := fifelse(vague == "nfhs2", "sh32 sans filtre amont", "hv237 filtre puis methodes")]
setorder(serie, methode, zone, vague)
print(serie[, .(methode, zone, periode, variable, n, pct = round(pct, 2), ic_bas = round(ic_bas, 2),
                ic_haut = round(ic_haut, 2))], row.names = FALSE)
fwrite(serie, p_tab("25_etape1_serie_quatre_vagues.csv"))
ecrire_tex(serie[, .(methode, zone, periode, variable, menages = n, pct, ic_bas, ic_haut)],
           p_tab("25_etape1_serie_quatre_vagues.tex"), "llllrrrr")

# ---------------------------------------------------------------------------
hr("Etape 2. Source d'eau en 1998 et raccord au codage recent (inventaire)")
# ---------------------------------------------------------------------------

for (k in c("hv201", "hv202", "hv203", "hv204"))
  msg(k, " : « ", lib(d[[k]]), " » ; non manquante ", round(100 * mean(!is.na(d[[k]])), 2), " %")
e201 <- etiquettes(d$hv201)
n201 <- data.table(code = num(d$hv201))[, .N, by = code]
mod98 <- merge(e201, n201, by = "code", all = TRUE)
mod98[is.na(N), N := 0L]
setnames(mod98, "N", "n_non_pondere")
print(mod98, row.names = FALSE)

# Raccord au codage 2005-2021 (CODAGE DE JUGEMENT, a relire) : code(s) des
# vagues recentes qui recouvrent la modalite 1998, et nature du raccord.
raccord <- data.table(
  code_1998 = c(10, 11, 12, 20, 21, 22, 23, 24, 25, 26, 30, 31, 32, 33, 34, 41, 51, 96),
  codes_recents = c("10", "11 + 12 (+ 13 voisin en NFHS-5)", "13 (NFHS-3/4) ; 14 (NFHS-5)",
                    "20, 30", "21 (sans distinction prive/public)", "21 (sans distinction prive/public)",
                    "31 ou 32", "31 ou 32", "31", "32",
                    "40", "41 ou 42", "43", "43", "43", "51", "61", "96"),
  nature = c("titre de groupe", "fusion : logement et cour reunis en 1998",
             "un a un, code deplace en NFHS-5",
             "titre de groupe ; puits et forages separes apres 1998",
             "propriete perdue : prive/public non distingue apres 1998",
             "propriete perdue : prive/public non distingue apres 1998",
             "propriete perdue ; protege/non protege non distingue en 1998",
             "protege/non protege non distingue en 1998",
             "propriete perdue ; « couvert » ~ protege (jugement)",
             "propriete perdue ; « ouvert » ~ non protege (jugement)",
             "titre de groupe", "protege/non protege non distingue en 1998",
             "un a un (riviere)", "un a un (etang, lac)", "un a un (barrage)",
             "un a un", "un a un (camion-citerne) ; charrette 62 sans equivalent 1998",
             "un a un"))
check(setequal(raccord$code_1998, e201$code),
      "table de raccord : chaque code etiquete de hv201 1998 y figure une fois",
      paste("etiquetes :", paste(e201$code, collapse = ",")))
mod98 <- merge(mod98, raccord, by.x = "code", by.y = "code_1998", all.x = TRUE)
print(mod98, row.names = FALSE)
fwrite(mod98, p_tab("25_etape2_hv201_1998_raccord.csv"))
msg("Modalites recentes sans equivalent en 1998 : 62 charrette, 71 eau en bouteille,")
msg("72/92 usine RO communautaire, 13 voisin (NFHS-5) -- d'apres output/tables/24_etape2_hv201_ruptures.csv.")

# ---------------------------------------------------------------------------
hr("Etape 3. Georeferencement")
# ---------------------------------------------------------------------------

ge <- list.files(D_1998, pattern = "GE", recursive = TRUE, ignore.case = FALSE)
msg("Fichiers GE sous ", D_1998, " : ", if (length(ge)) paste(ge, collapse = ", ") else "aucun")
fwrite(data.table(vague = "nfhs2", fichier_ge = if (length(ge)) paste(ge, collapse = ";") else NA_character_),
       p_tab("25_etape3_georeferencement.csv"))

hr("Limites a consigner")
msg("- adoption declaree par le repondant ;")
msg("- comparabilite des questionnaires entre phases DHS eloignees de vingt ans : pas de")
msg("  filtre amont en 1998, « electronic » contre « electric purifier », questionnaire absent de raw/ ;")
msg("- aucun repere publie local pour valider un taux 1998 ;")
msg("- le NFHS-1 (1992-93) n'est pas examine.")

log_close()
