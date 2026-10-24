# ---------------------------------------------------------------------------
# 36_piste_j_validation_nss.R -- piste J : la distinction prive / partage du
#   NFHS (souterrain_prive = hv201 x hv235) resiste-t-elle aux items de
#   financement du NSS round 76 ? CONTROLE DE VALIDITE DE LA MESURE, pas un
#   resultat de la question de recherche.
#
# POURQUOI : dans le NFHS, souterrain_prive est reconstruit par la
# LOCALISATION de la source (hv235 dans {1, 2}), pas par sa propriete. Une
# pompe a main publique sur une parcelle y entre comme du prive. Les deux
# validations internes au NFHS sont closes (script 35) : hv235 est absent de
# NFHS-2, et la pompe a eau mesure la richesse, pas la source.
#
# CE QUE PORTE LE NSS 76 (verifie sur le questionnaire NSS_76_sch_1.2.pdf, le
# manuel NSS_76_ins_Ch3.pdf et code/ref/11_nss_codes_documentes.csv) :
#   - item 1, source : tube well (6) et hand pump (7) separes ; le round 69
#     (code 5) et le NFHS (hv201 = 21) les fusionnent.
#   - item 4, acces : 1 usage exclusif, 2 commun a l'immeuble, 3 source du
#     voisin, puis usage collectif 4-5 source creee sur FONDS PUBLICS
#     (restreinte / non restreinte), 6-7 sur FONDS PRIVES, 9 autre. Manuel
#     76, 3.5.4.1 : la ventilation en quatre existe "to have information on
#     source of funding for the creation of the facility". Les codes 1, 2, 3
#     ne portent AUCUNE information de financement.
#   - item 5, distance : 1 dans le logement, 2 hors logement dans la
#     parcelle ; 1-2 = equivalent NSS de hv235 dans {1, 2}.
#   - item 15.1 (bloc 3), TROIS colonnes : (a) a deja beneficie d'un
#     programme public d'eau potable (1 oui, 2 non, 3 non connu) ; (b) si
#     oui, dans les 3 dernieres annees (1 oui, 2 non, 3 non connu) ; (c)
#     programme du principal benefice (NRDWP 1, AMRUT 2, Smart Cities 3,
#     autre 9, non connu 5). Manuel NSS_76_ins_Ch3.pdf 3.4.9.1 : le benefice
#     n'est compte que si l'equipement cree est A L'USAGE EXCLUSIF du menage ;
#     les equipements crees pour un usage public ou communautaire (borne,
#     pompe publique de quartier) sont explicitement exclus. 3.4.9.3 : la
#     premiere colonne porte sur "whether ever received any benefit", SANS
#     fenetre de temps, pour tous les programmes, y compris ceux des
#     collectivites locales : un equipement public ancien a usage exclusif
#     entre dans 15.1 (relu et confirme par la PI). 15.1
#     vise donc precisement le cas que l'item 4 ne voit pas (equipement
#     public a usage d'un seul menage, code 1), mais il ne dit pas QUEL
#     equipement : ce peut etre un raccordement au robinet alors que la
#     source principale est une pompe sur la parcelle.
#
# ===========================================================================
# CRITERE (ecrit avant tout chiffre ; SEUILS A VALIDER PAR LA PI AVANT
# EXECUTION)
# ===========================================================================
# Population U : menages du round 76 dont la source principale est
# souterraine (codes 6, 7, 8, 9) ET sur la parcelle (distance 1 ou 2) :
# l'equivalent NSS du souterrain_prive du NFHS (hv201 21/31/32 x hv235 1-2).
# Parts ponderees dans U, all-India :
#   C_bas  = part avec acces 4 ou 5 (source creee sur fonds publics).
#            Borne BASSE de la contamination : les codes 1 a 3 n'ont pas
#            d'information de financement.
#   C_haut = part avec acces 4 ou 5 OU benefice 15.1 = oui (jamais
#            restreint aux 3 ans). Mesure GENEREUSE : le benefice peut porter
#            sur un autre equipement que la source principale.
#   I      = part avec acces 1, 2 ou 3 (financement inconnu), rapportee a
#            cote, jamais absorbee.
# Verdict (all-India) :
#   DISQUALIFIEE       si C_bas  >= 10 %
#   NON DISQUALIFIEE   si C_haut <  5 %
#   INDETERMINEE       sinon (borderline, rapportee comme telle)
# Rural et urbain sont rapportes a part ; si le rural seul franchit 10 % en
# C_bas, la reconstruction est declaree disqualifiee POUR LE RURAL.
#
# QUANTITE RAPPORTEE (pas un seuil de verdict) : DELTA C_bas = C_bas(76,
# 2018) - C_bas(69, 2012), meme population U au round 69 (source 5, 6, 7 et
# distance 1-2 ; tube well et hand pump y sont fusionnes en 5). Une
# contamination constante biaise le NIVEAU de souterrain_prive sans fausser
# sa tendance ; ce qui corromprait une lecture en evolution, c'est une
# contamination qui bouge. Si |DELTA C_bas| < 2 points, le constat de niveau
# ne disqualifie pas les comparaisons entre vagues, et le verdict le dit.
#
# CE QU'ENTRAINE "INDETERMINEE" (ecrit avant tout chiffre, position de la PI
# consignee telle quelle) :
#   En cas d'indeterminee, la piste J continue, mais la categorie est
#   renommee et la pretention est reduite. "souterrain_prive" devient
#   "souterrain_parcelle", parce que ce qui est mesure est un acces exclusif
#   et non un financement prive. Un acces exclusif satisfait bien la
#   condition 2 du cadre commun, qui demande un substitut individuel,
#   excluable et indivisible ; ce qu'on ne peut plus affirmer, c'est que le
#   menage a paye. Toute formulation parlant de substitution privee financee
#   par le menage est a retirer tant qu'une autre source ne la retablit pas.
# Le renommage (script 35 et code/ref/35_hv201_classes.csv) n'est fait que
# si le verdict tombe en indeterminee ou en disqualifiee, pas avant.
#
# ===========================================================================
# APRES EXECUTION (ajoute apres le verdict ; le critere ci-dessus est inchange)
# ===========================================================================
# VERDICT : NON DISQUALIFIEE (all-India C_bas 0.12 %, C_haut 1.84 % ; rural
# et urbain idem). 99.5 % de U a un financement INCONNU (acces 1-3) : le
# verdict repose sur 15.1, ou 98.2 % de U declare n'avoir jamais beneficie.
#
# LIMITE, DELTA C_bas : 2.25 % (2012) -> 0.12 % (2018), -2.13 points de taux
# dans U (rural -2.53, urbain -0.70). U pese environ 28 % des menages. Une
# derive de C_bas de 2.13 points de taux deplace donc environ 0.6 point de
# menages. Le mouvement de souterrain_prive entre NFHS-4 et NFHS-5 etant de
# 1.8 point, jusqu'a un tiers de ce mouvement peut relever de la derive de
# mesure et non d'un changement de comportement. Deux lectures restent
# ouvertes et ne se departagent pas avec ces donnees : une baisse reelle des
# sources partagees sur parcelle entre 2012 et 2018, ou une derive de
# pratique d'enquete non ecrite, le manuel etant inchange.
# (Le seuil "stable a moins de 2 points" etait en points de taux dans U,
# alors que les seuils 10 / 5 % sont justifies en points de menages :
# l'enonce "franchit le seuil de 0.13 point" n'est pas interpretable et est
# retire.)
#
# EXPLICATIONS TESTEES ET REJETEES :
#   - Changement d'instruction aux enqueteurs : ins69chap3.pdf 3.4.4 / 3.4.4.1
#     (round 69) et NSS_76_ins_Ch3.pdf 3.5.4 / 3.5.4.1 (round 76) sont
#     identiques en substance (comparaison mot a mot) : definition de
#     l'acces, liste des codes, texte sur le financement des codes 4-7,
#     exemple du code 9 (menages de deux batiments distincts). Seuls ecarts :
#     le code 9 est introduit par "In all other remaining cases" (69) contre
#     "If access ... is not covered by any of the codes 1 to 7" (76), et
#     deux reformulations mineures ("household's" / "of household"). Aucun
#     ne touche les codes 4-7.
#   - Erreur de plage de codes : code/ref/36_nss_codes_source_acces.csv relu,
#     groupe souterrain du round 69 = 5, 6, 7 ; sources 8 et 9 en "autre".
# La decomposition C_bas = (part collective 4-7) x (part publique parmi les
# collectives) est en 36l : elle dit OU est la variation, pas POURQUOI.
#
# ATTENDU MECANIQUE, signale avant execution : les codes 4-5 designent un
# usage COLLECTIF ; une source sur la parcelle en usage collectif est rare
# par construction. C_bas sera donc faible et la branche "disqualifiee"
# presque inatteignable : le verdict se jouera entre "non disqualifiee" et
# "indeterminee", c'est-a-dire sur C_haut, donc sur 15.1.
#
# JUSTIFICATION DES SEUILS : souterrain_prive pese 27 a 29 % des menages
# NFHS en 2015-2021 (script 35, table par vague). Une contamination de c %
# deplace c x 0.28 point de menages : 5 % -> 1.4 point, 10 % -> 2.8 points.
# 2.8 points depassent le mouvement de souterrain_prive entre NFHS-4 et
# NFHS-5 (+1.8 point) : au-dela de 10 %, la contamination suffit a produire
# seule les variations qu'on voudrait lire. Sous 5 %, elle reste inferieure.
#
# CE QUI N'ENTRE PAS DANS LE CRITERE : la part de hand pump. Une pompe a main
# n'est pas un marqueur de financement public : le rapport 584 (definition
# 2.22) la definit par l'actionnement manuel, et les pompes a main privees
# peu profondes sont courantes dans la plaine gangetique. La repartition
# tube well / hand pump est produite (table 2), pas utilisee comme seuil.
#
# LIMITES :
#   - Le round 76 date de 2018 (juillet-decembre) : il mesure la
#     contamination en fin de periode, apres NFHS-4 (2015-16) et pendant
#     NFHS-5 (2019-21). Il ne dit rien du taux en 2005-06.
#   - Le financement n'est code que pour l'usage collectif (4-7). Une pompe
#     publique utilisee par un seul menage est en code 1 et n'est visible
#     que via 15.1, si le menage la rapporte comme benefice d'un programme.
#     C_bas est une borne basse, pas une mesure complete.
#   - 15.1 ne localise pas l'equipement beneficie : C_haut peut compter un
#     menage dont le benefice est un robinet et la source principale une
#     pompe privee.
#
# ===========================================================================
# DONNEES ET POIDS
# ===========================================================================
# Round 76 : L01 (poids, secteur), L03 (depense, taille), L04 (item 15),
# L05 (source, acces, distance). Cle HHID, gardee en texte.
# Round 69 : Block 1 (poids) et Block 4 (b4_q1 source, b4_q4 acces, b4_q5
# distance). Cle Key_hhold. Sert au seul croisement acces x distance.
# Poids : AUCUN diviseur suppose. Plusieurs candidats sont testes contre les
# effectifs publies (section 36c) et le seul qui les reproduit est
# retenu ; zero ou plusieurs candidats -> arret.
#   - R76 : rapport 584, Statement 1 : 178.38 M menages ruraux, 92.72 M
#     urbains (tolerance 0.01 M, arrondi publie au centieme de million).
#   - R69 : Key Indicators 69/1.2, table A1 p. A1-A2 (lue sur l'image de la
#     page) : 1 740 127 (00) ruraux, 805 246 (00) urbains, echantillon
#     central 53 393 + 42 155 (tolerance 1 unite de (00)).
# Le poids retenu est ecrit dans le log a chaque execution.
#
# CONTROLE DUR : rapport 584, Statement 2, p. 18-19, repartition des menages
# par source principale, rural / urbain / ensemble, 17 lignes (une par code).
# Tolerance 0.05 point, ligne par ligne.
#
# QUINTILES : depense mensuelle par tete (L03 Total_Monthly_expenditure /
# HH_size), quintiles ponderes all-India, round 76 seulement. Pooles rural +
# urbain sans correction de prix : positions relatives, pas niveaux de vie.
# Round 69 : non construits (variable de depense non identifiee ici).
#
# LANCEMENT (racine du depot), court (quelques dizaines de secondes) :
#     Rscript code/36_piste_j_validation_nss.R           # reprend
#     Rscript code/36_piste_j_validation_nss.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 36_nss76_menages.rds  L01 + L03 + L04 + L05 fusionnes
#   2. 36_nss69_menages.rds  Block 1 + Block 4 fusionnes
#
# Sorties : output/tables/36_*.csv, output/logs/36_piste_j_validation_nss.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("36_piste_j_validation_nss.log"))

msg("ETAPE 36 -- PISTE J : VALIDATION DE LA DISTINCTION PRIVE / PARTAGE PAR LE NSS 76")
msg("Controle de validite de la mesure. Critere ecrit dans l'en-tete avant tout chiffre.")

# --- critere (repris de l'en-tete) -------------------------------------------
SEUIL_DISQUALIFIE <- 10   # C_bas  >= 10 % -> disqualifiee
SEUIL_TENABLE     <-  5   # C_haut <   5 % -> non disqualifiee

N76 <- c(total = 106838L, rural = 63736L, urbain = 43102L)
N69 <- c(total = 95548L,  rural = 53393L, urbain = 42155L)
EFF76 <- c(rural = 178.38e6, urbain = 92.72e6);  TOL76 <- 0.01e6
EFF69 <- c(rural = 1740127 * 100, urbain = 805246 * 100); TOL69 <- 100

d76 <- function(f) p_raw("nss", "76", f)
d69 <- function(f) p_raw("nss", "69", f)

# --- table de codes ------------------------------------------------------------
hr("36a. Table de codes (code/ref)")
f_ref <- file.path("code", "ref", "36_nss_codes_source_acces.csv")
check(file.exists(f_ref), paste0("table de codes presente -> ", f_ref))
REF <- fread(f_ref, colClasses = list(character = c("item", "libelle", "groupe", "source"),
                                      integer = c("round", "code")))
check_vars(REF, c("round", "item", "code", "libelle", "groupe"), "ref")
check_unique(REF, c("round", "item", "code"), "ref")
print(REF[, .N, by = .(round, item)])
grp <- function(r, it) REF[round == r & item == it, .(code, groupe, libelle)]

# --- lecture ---------------------------------------------------------------------
lit <- function(f, cols, cle) {
  check(file.exists(f), paste0("fichier present -> ", f))
  tete <- names(fread(f, nrows = 0L))
  check(all(cols %in% tete), paste0(basename(f), " : colonnes presentes"),
        paste("absentes :", paste(setdiff(cols, tete), collapse = ", ")))
  d <- fread(f, select = cols, colClasses = list(character = cle))
  check_unique(d, cle, basename(f))
  d
}

hr("36b. Lecture NSS 76 et 69 (etapes 1 et 2)")

f76 <- p_build("36_nss76_menages.rds")
m76 <- stage("etape 1/2 NSS 76", f76, function() {
  l01 <- lit(d76("L01_sample_household.csv"),
             c("HHID", "Sector", "State", "NSC", "Multiplier"), "HHID")
  l03 <- lit(d76("L03_Household_characteristics.csv"),
             c("HHID", "HH_size", "Total_Monthly_expenditure"), "HHID")
  l04 <- lit(d76("L04_Household characteristics_15_1_to_15_5.csv"),
             c("HHID", "Drinking_water_anybenefit", "Drinking_water_benefit_3yrs",
               "Drinking_water_scheme_max_benefi"), "HHID")
  l05 <- lit(d76("L05_Particulars_of_living_facilities.csv"),
             c("HHID", "source_drinking_water", "Access_source_water",
               "Distance_source_water"), "HHID")
  for (x in list(l01, l03, l04, l05)) check_rows(x, N76[["total"]], "NSS 76 fichier menage")
  d <- Reduce(function(a, b) merge(a, b, by = "HHID", all = FALSE), list(l01, l03, l04, l05))
  check_rows(d, N76[["total"]], "NSS 76 apres fusion L01-L05")
  setnames(d, c("source_drinking_water", "Access_source_water", "Distance_source_water",
                "Drinking_water_anybenefit", "Drinking_water_benefit_3yrs",
                "Drinking_water_scheme_max_benefi"),
           c("source", "acces", "distance", "benef", "benef_3ans", "programme"))
  d
})

f69 <- p_build("36_nss69_menages.rds")
m69 <- stage("etape 2/2 NSS 69", f69, function() {
  b1 <- lit(d69("Block - 1 Identification of sample household - level 1.csv"),
            c("Key_hhold", "Sector", "NSS", "NSC", "MLT", "Combined_Weight"), "Key_hhold")
  b4 <- lit(d69("Block - 4 Particulars of living facilities - drinking water, bathroom, sanitation etc - level 4.csv"),
            c("Key_hhold", "b4_q1", "b4_q4", "b4_q5"), "Key_hhold")
  for (x in list(b1, b4)) check_rows(x, N69[["total"]], "NSS 69 fichier menage")
  d <- merge(b1, b4, by = "Key_hhold", all = FALSE)
  check_rows(d, N69[["total"]], "NSS 69 apres fusion Block 1 + 4")
  setnames(d, c("b4_q1", "b4_q4", "b4_q5"), c("source", "acces", "distance"))
  d
})

# secteur : effectifs d'echantillon publies (fixent 1 = rural, 2 = urbain)
for (r in c("76", "69")) {
  d <- if (r == "76") m76 else m69; N <- if (r == "76") N76 else N69
  check(sum(d$Sector == 1) == N[["rural"]] && sum(d$Sector == 2) == N[["urbain"]],
        sprintf("NSS %s : Sector 1 = %d menages ruraux, 2 = %d urbains (echantillon publie)",
                r, N[["rural"]], N[["urbain"]]),
        sprintf("observe 1 = %d, 2 = %d", sum(d$Sector == 1), sum(d$Sector == 2)))
}

# --- poids : determination empirique -------------------------------------------
hr("36c. Poids : candidat qui reproduit les effectifs publies")

choisit_poids <- function(d, cand, eff, tol, r) {
  res <- rbindlist(lapply(names(cand), function(k) {
    w <- cand[[k]]
    data.table(candidat = k,
               rural = sum(w[d$Sector == 1]), urbain = sum(w[d$Sector == 2]))
  }))
  res[, ok := abs(rural - eff[["rural"]]) <= tol & abs(urbain - eff[["urbain"]]) <= tol]
  msg("NSS ", r, " : effectifs publies rural ", format(eff[["rural"]], big.mark = " "),
      ", urbain ", format(eff[["urbain"]], big.mark = " "), " (tolerance ", format(tol, big.mark = " "), ")")
  op <- options(width = 200); print(res[, .(candidat, rural = round(rural), urbain = round(urbain), ok)]); options(op)
  check(sum(res$ok) >= 1L, paste0("NSS ", r, " : au moins un candidat de poids reproduit les effectifs"),
        "aucun candidat valide")
  # plusieurs candidats valides : admis seulement s'ils sont le MEME poids,
  # menage par menage (ex. round 69 : Combined_Weight == regle NSS/NSC)
  k <- res[ok == TRUE, candidat]
  ecart <- max(vapply(k, function(x) max(abs(cand[[x]] - cand[[k[1]]])), numeric(1)))
  check(ecart < 0.01, paste0("NSS ", r, " : les candidats valides sont identiques menage par menage"),
        sprintf("ecart max %.4f entre %s", ecart, paste(k, collapse = " / ")))
  note("NSS ", r, " : poids retenu -> ", k[1],
       if (length(k) > 1) paste0(" (identique a : ", paste(k[-1], collapse = ", "), ")") else "")
  cand[[k[1]]]
}

m76[, w := choisit_poids(m76, list(
  "Multiplier"             = m76$Multiplier,
  "Multiplier / NSC"       = m76$Multiplier / m76$NSC,
  "Multiplier / 100"       = m76$Multiplier / 100,
  "Multiplier / (100 NSC)" = m76$Multiplier / (100 * m76$NSC)), EFF76, TOL76, "76")]

m69[, w := choisit_poids(m69, list(
  "Combined_Weight"            = m69$Combined_Weight,
  "MLT / 100"                  = m69$MLT / 100,
  "MLT / (100 NSC)"            = m69$MLT / (100 * m69$NSC),
  "MLT/100 si NSS==NSC, /200"  = ifelse(m69$NSS == m69$NSC, m69$MLT / 100, m69$MLT / 200)),
  EFF69, TOL69, "69")]

# --- codes observes contre la table -----------------------------------------------
hr("36d. Codes observes contre la table de codes")
for (r in c(76L, 69L)) {
  d <- if (r == 76L) m76 else m69
  for (it in c("source", "acces", "distance")) {
    hors <- setdiff(unique(d[[it]][!is.na(d[[it]])]), grp(r, it)$code)
    check(length(hors) == 0L, sprintf("NSS %d : tout code %s observe est dans la table", r, it),
          paste("hors table :", paste(hors, collapse = ", ")))
    note(sprintf("NSS %d %s : %d manquant(s)", r, it, sum(is.na(d[[it]]))))
  }
}
for (it in c("benef", "benef_3ans", "programme")) {
  ref_it <- c(benef = "benefice_eau", benef_3ans = "benefice_eau_3ans", programme = "programme_eau")[[it]]
  hors <- setdiff(unique(m76[[it]][!is.na(m76[[it]])]), grp(76L, ref_it)$code)
  check(length(hors) == 0L, sprintf("NSS 76 : tout code %s observe est dans la table", it),
        paste("hors table :", paste(hors, collapse = ", ")))
}

# --- classement -------------------------------------------------------------------
cl <- function(d, r) {
  d[grp(r, "source"),   on = c(source = "code"),   g_source   := i.groupe]
  d[grp(r, "acces"),    on = c(acces = "code"),    g_acces    := i.groupe]
  d[grp(r, "distance"), on = c(distance = "code"), g_distance := i.groupe]
  d[is.na(g_acces), g_acces := "manquant"]
  d[is.na(g_distance), g_distance := "manquant"]
  d[, secteur := fifelse(Sector == 1, "rural", "urbain")]
  d[, souterrain := g_source %like% "^souterrain_"]
  d[, U := souterrain & g_distance == "sur_parcelle"]
  d[]
}
m76 <- cl(copy(m76), 76L)
m69 <- cl(copy(m69), 69L)
m76[, g_benef := fcase(benef %in% 2, "jamais",
                       benef %in% 1 & benef_3ans %in% 1, "oui_3_dernieres_annees",
                       benef %in% 1 & benef_3ans %in% 2, "oui_avant_3_ans",
                       benef %in% 1, "oui_date_inconnue",
                       benef %in% 3, "non_connu",
                       rep(TRUE, .N), "manquant")]

# quintile de depense par tete, pondere, all-India (round 76)
m76[, mpce := Total_Monthly_expenditure / HH_size]
ok_q <- m76[!is.na(mpce) & HH_size > 0]
o <- order(ok_q$mpce); cw <- cumsum(ok_q$w[o]) / sum(ok_q$w)
br <- c(-Inf, sapply(1:4 / 5, function(p) ok_q$mpce[o][which(cw >= p)[1]]), Inf)
m76[, quintile := cut(mpce, br, labels = FALSE, right = TRUE)]
note("NSS 76 : quintile de depense par tete manquant pour ", sum(is.na(m76$quintile)), " menages")

# --- parts ponderees : outil commun --------------------------------------------------
# Parts en % de la population de la ligne, ensemble / rural / urbain empiles.
parts <- function(d, var, by = character()) {
  d2 <- rbind(copy(d)[, secteur := "ensemble"], d)
  t <- d2[, .(n = .N, w = sum(w)), by = c("secteur", by, var)]
  t[, pct := 100 * w / sum(w), by = c("secteur", by)]
  t[, w := NULL]
  setorderv(t, c("secteur", by, var))
  t[]
}
ecrit <- function(t, f, titre) {
  msg(""); msg(titre)
  op <- options(width = 220); print(t, nrows = 300); options(op)
  fwrite(t, p_tab(f))
}

# ===========================================================================
# Sortie 1 : distribution de la source, code par code (audit)
# ===========================================================================
hr("36e. Sortie 1 -- distribution de la source principale, code par code")
for (r in c(76L, 69L)) {
  d <- if (r == 76L) m76 else m69
  t <- parts(d, "source")
  t <- merge(t, grp(r, "source")[, .(source = code, libelle, groupe)], by = "source", all.x = TRUE)
  t[, dans_table := !is.na(libelle)]
  setcolorder(t, c("secteur", "source", "libelle", "groupe", "dans_table", "n", "pct"))
  setorderv(t, c("secteur", "source"))
  ecrit(t, sprintf("36_nss%d_distribution_source.csv", r),
        sprintf("NSS %d : source principale, %% des menages", r))
}

# ===========================================================================
# Controle dur : rapport 584, Statement 2
# ===========================================================================
hr("36f. Controle pondere, NSS 76 contre le rapport 584 (Statement 2)")
PUBLIE_584 <- rbindlist(list(
  list(1L,  "Bottled water",               4.0, 12.2,  6.8),
  list(2L,  "Piped water into dwelling",  11.3, 40.9, 21.4),
  list(3L,  "Piped water to yard/plot",   10.3, 16.0, 12.3),
  list(4L,  "Piped water from neighbour",  1.0,  1.0,  1.0),
  list(5L,  "Public tap/stand pipe",      10.3,  7.1,  9.2),
  list(6L,  "Tube well",                  10.9, 10.4, 10.7),
  list(7L,  "Hand pump",                  42.9,  6.7, 30.5),
  list(8L,  "Protected well",              2.9,  1.7,  2.5),
  list(9L,  "Unprotected well",            4.4,  2.4,  3.7),
  list(10L, "Public tanker truck",         0.1,  0.8,  0.3),
  list(11L, "Private tanker truck",        0.4,  0.5,  0.4),
  list(12L, "Protected spring",            0.3,  0.1,  0.2),
  list(13L, "Unprotected spring",          0.3,  0.0,  0.2),
  list(14L, "Rainwater collection",        0.2,  0.0,  0.2),
  list(15L, "Surface water: tank/pond",    0.4,  0.0,  0.3),
  list(16L, "Surface water: other",        0.3,  0.0,  0.2),
  list(19L, "Others",                      0.2,  0.2,  0.2)))
setnames(PUBLIE_584, c("code", "ligne", "rural", "urbain", "ensemble"))
TOL_PART <- 0.05

for (s in c("rural", "urbain", "ensemble")) {
  d <- if (s == "ensemble") m76 else m76[secteur == s]
  for (i in seq_len(nrow(PUBLIE_584))) {
    att <- PUBLIE_584[[s]][i]
    o   <- 100 * sum(d$w[d$source %in% PUBLIE_584$code[i]]) / sum(d$w)
    check(abs(o - att) <= TOL_PART,
          sprintf("NSS 76 : source %d %s, %s == %.1f (tol. %.2f)",
                  PUBLIE_584$code[i], PUBLIE_584$ligne[i], s, att, TOL_PART),
          sprintf("source %d %s : attendu %.1f, observe %.4f, ecart %.4f",
                  PUBLIE_584$code[i], s, att, o, o - att))
  }
}

# ===========================================================================
# Population U : souterrain sur la parcelle (round 76)
# ===========================================================================
U76 <- m76[U == TRUE]
msg(""); msg("Population U (NSS 76) : source 6-9 et distance 1-2 -> ",
             format(nrow(U76), big.mark = " "), " menages")

hr("36g. Sortie 2 -- U : tube well / hand pump / puits protege / non protege")
ecrit(parts(U76, "g_source"), "36_nss76_U_type_source.csv",
      "NSS 76, U : repartition par type de source (% de U)")
ecrit(parts(U76, "g_source", "quintile"), "36_nss76_U_type_source_quintile.csv",
      "NSS 76, U : type de source par quintile de depense par tete")

hr("36h. Sortie 3 -- U x acces (item 4) ; financement INCONNU = codes 1-3")
t3 <- parts(U76, "g_acces", "g_source")
ecrit(t3, "36_nss76_U_acces_par_source.csv",
      "NSS 76, U : acces par type de source (% du type de source)")
inc <- function(d, by = character()) {
  d2 <- rbind(copy(d)[, secteur := "ensemble"], d)
  d2[, .(n = .N,
         financement_inconnu_1_3 = 100 * sum(w[g_acces %like% "financement_inconnu"]) / sum(w),
         fonds_publics_4_5       = 100 * sum(w[g_acces == "fonds_publics"]) / sum(w),
         fonds_prives_6_7        = 100 * sum(w[g_acces == "fonds_prives"]) / sum(w),
         autre_ou_manquant       = 100 * sum(w[g_acces %in% c("autre_acces", "manquant")]) / sum(w)),
     by = c("secteur", by)][order(secteur)]
}
ecrit(inc(U76, "g_source"), "36_nss76_U_financement_par_source.csv",
      "NSS 76, U : part au financement INCONNU (acces 1-3), public, prive, par type de source")
ecrit(inc(U76, "quintile")[order(secteur, quintile)], "36_nss76_U_financement_quintile.csv",
      "NSS 76, U : financement par quintile de depense par tete")

hr("36i. Sortie 4 -- U x item 15.1 (benefice d'un programme public d'eau)")
ecrit(parts(U76, "g_benef"), "36_nss76_U_benefice.csv",
      "NSS 76, U : benefice 15.1 (jamais / 3 dernieres annees / avant / non connu)")
ecrit(parts(U76, "g_benef", "g_source"), "36_nss76_U_benefice_par_source.csv",
      "NSS 76, U : benefice 15.1 par type de source")
ecrit(parts(U76, "g_benef", "quintile"), "36_nss76_U_benefice_quintile.csv",
      "NSS 76, U : benefice 15.1 par quintile de depense par tete")
b3 <- U76[g_benef == "oui_3_dernieres_annees"]
b3[grp(76L, "programme_eau"), on = c(programme = "code"), g_programme := i.groupe]
b3[is.na(g_programme), g_programme := "manquant"]
ecrit(parts(b3, "g_programme"), "36_nss76_U_programme.csv",
      "NSS 76, U, beneficiaires dans les 3 ans : programme du principal benefice")

hr("36j. Sortie 5 -- acces x distance, sources souterraines, rounds 69 et 76")
ad <- rbind(parts(m69[souterrain == TRUE], "g_acces", "g_distance")[, round := 69L],
            parts(m76[souterrain == TRUE], "g_acces", "g_distance")[, round := 76L])
setcolorder(ad, "round")
setorderv(ad, c("round", "secteur", "g_distance", "g_acces"))
ecrit(ad, "36_nss_acces_x_distance_souterrain.csv",
      "Sources souterraines : acces par distance (% de la case distance), rounds 69 et 76")

# ===========================================================================
# Verdict contre le critere
# ===========================================================================
hr("36k. VERDICT contre le critere de l'en-tete")
crit <- rbind(copy(U76)[, secteur := "ensemble"], U76)[, .(
  n      = .N,
  C_bas  = 100 * sum(w[g_acces == "fonds_publics"]) / sum(w),
  C_haut = 100 * sum(w[g_acces == "fonds_publics" | benef %in% 1]) / sum(w),
  I      = 100 * sum(w[g_acces %like% "financement_inconnu"]) / sum(w)),
  by = secteur][order(secteur)]
crit[, verdict := fcase(C_bas >= SEUIL_DISQUALIFIE, "DISQUALIFIEE",
                        C_haut < SEUIL_TENABLE,     "NON DISQUALIFIEE",
                        rep(TRUE, .N),              "INDETERMINEE")]
op <- options(width = 200); print(crit); options(op)
fwrite(crit, p_tab("36_nss76_verdict.csv"))
v <- crit[secteur == "ensemble", verdict]
msg(""); msg("VERDICT all-India : ", v,
             sprintf(" (C_bas %.2f %%, C_haut %.2f %%, financement inconnu %.1f %%)",
                     crit[secteur == "ensemble", C_bas], crit[secteur == "ensemble", C_haut],
                     crit[secteur == "ensemble", I]))
if (crit[secteur == "rural", C_bas] >= SEUIL_DISQUALIFIE && v != "DISQUALIFIEE")
  msg("Rural : C_bas >= ", SEUIL_DISQUALIFIE, " % -> reconstruction DISQUALIFIEE POUR LE RURAL")

# quantite rapportee : DELTA C_bas entre 2012 (round 69) et 2018 (round 76)
SEUIL_DELTA <- 2
U69 <- m69[U == TRUE]
msg(""); msg("Population U (NSS 69) : source 5-7 et distance 1-2 -> ",
             format(nrow(U69), big.mark = " "), " menages")
cb <- function(d) rbind(copy(d)[, secteur := "ensemble"], d)[, .(
  n = .N, C_bas = 100 * sum(w[g_acces == "fonds_publics"]) / sum(w)), by = secteur]
delta <- merge(cb(U69), cb(U76), by = "secteur", suffixes = c("_69", "_76"))
delta[, delta_C_bas := C_bas_76 - C_bas_69]
delta[, stable := abs(delta_C_bas) < SEUIL_DELTA]
op <- options(width = 200); print(delta[order(secteur)]); options(op)
fwrite(delta, p_tab("36_nss_delta_C_bas.csv"))
de <- delta[secteur == "ensemble"]
msg(sprintf("DELTA C_bas all-India : %.2f %% (2012) -> %.2f %% (2018), ecart %+.2f point -> %s",
            de$C_bas_69, de$C_bas_76, de$delta_C_bas,
            if (de$stable) "STABLE a moins de 2 points : le constat de niveau ne disqualifie pas les comparaisons entre vagues"
            else "INSTABLE : la contamination bouge, les comparaisons entre vagues sont exposees"))
msg(sprintf("En points de menages (U ~ 28 %% des menages) : derive ~ %.1f point, a comparer a +1.8 point de souterrain_prive NFHS-4 -> 5",
            abs(de$delta_C_bas) * 0.28))

# --- decomposition de C_bas -----------------------------------------------------
# C_bas = a x b : a = part de U en usage collectif (acces 4-7), b = part sur
# fonds publics (4-5) parmi ces collectives. Aucune conclusion tiree ici :
# la table dit OU est la variation, pas POURQUOI.
hr("36l. Decomposition de C_bas : usage collectif x fonds publics, rounds 69 et 76")
decomp <- function(d, r) rbind(copy(d)[, secteur := "ensemble"], d)[, {
  coll <- g_acces %in% c("fonds_publics", "fonds_prives")
  list(round = r, n = .N, n_collectif = sum(coll),
       a_collectif_4_7      = 100 * sum(w[coll]) / sum(w),
       b_publics_parmi_coll = if (any(coll)) 100 * sum(w[g_acces == "fonds_publics"]) / sum(w[coll]) else NA_real_,
       C_bas                = 100 * sum(w[g_acces == "fonds_publics"]) / sum(w))
}, by = secteur]
dec <- rbind(decomp(U69, 69L), decomp(U76, 76L))
setcolorder(dec, c("round", "secteur"))
setorderv(dec, c("secteur", "round"))
op <- options(width = 200); print(dec); options(op)
fwrite(dec, p_tab("36_nss_decomposition_C_bas.csv"))

msg(""); msg("Termine. Tables dans output/tables/36_*.csv")
log_close()
