# ---------------------------------------------------------------------------
# 26_piste_c_questionnaire_districts.R -- piste C, deux controles descriptifs
#   sur le recul a 1998 :
#   Point 1  l'effet questionnaire 1998 -> 2005 est-il localise sur les
#            methodes de faible saillance ? Decomposition de l'ecart de la
#            part des menages declarant au moins une methode, par methode,
#            national et urbain.
#   Point 2  la variable sdist du NFHS-2 : couverture, menages par district,
#            raccord possible aux districts des NFHS-4/5 ; existence d'une
#            maille district dans le NFHS-3.
#
# DESCRIPTIF SEULEMENT : aucune regression, aucune issue construite.
#
# DONNEES : caches deja valides des scripts 24 et 25
#   build/25_cache_nfhs2.rds (sh32a-x, nhv005), build/24_cache_nfhs3.rds
#   (hv237a-z, hv005), build/24_cache_nfhs4.rds, build/24_cache_nfhs5.rds ;
#   SHRUG : raw/shrug/shrug-pc11dist-poly-gpkg/district.gpkg (noms des
#   districts du recensement 2011), shrid_pc91dist_key, shrid_pc11dist_key.
#
# ===========================================================================
# POINT 1 -- DEFINITIONS ET ATTENTES (ECRITES AVANT EXECUTION)
# ===========================================================================
# Methodes harmonisees (1998 sh32 ; 2005 hv237) :
#   ebullition sh32d / hv237a     tissu  sh32a / hv237c     alun sh32b / hv237g
#   filtre     sh32c / hv237d     purificateur sh32e / hv237h
#   chlore     -     / hv237b     decantation  -     / hv237f   (nouvelles en 2005)
#   autre      sh32x / hv237x     ne_sait_pas  -     / hv237z
# Groupes : FAIBLE SAILLANCE = ebullition, tissu, alun, chlore, decantation ;
#           APPAREILS = filtre, purificateur ; RESIDUEL = autre, ne_sait_pas.
# Traite (« au moins une methode ») : 1998 = une case sh32 de methode a 1 ;
#   2005 = hv237 = 1. Manquant si la reponse manque (1998 : aucune case ;
#   2005 : hv237 manquante ou 8, ou hv237 = 1 sans aucune methode ni z).
# Decomposition exacte (allocation fractionnaire) : chaque menage traite
#   declarant k methodes en attribue 1/k a chacune. Contribution c_m = moyenne
#   ponderee de y_m / k. Somme des c_m = part traitee ; Delta(traite) =
#   somme des Delta(c_m). Part de l'ecart absorbee par m : Delta(c_m) /
#   Delta(traite). Les Delta de prevalence brute par methode sont donnes a
#   cote (leur somme depasse Delta(traite) a cause des reponses multiples).
# Poids : nhv005 (1998, Tripura exclue) ; hv005 (2005, Tripura incluse --
#   1 290 menages en 1998, ecart negligeable, non corrige).
#
# S_bas = part de Delta(traite) absorbee par le groupe faible saillance.
# B_bas = part du groupe faible saillance dans le melange 1998 (somme de ses
#   c_m / part traitee 1998) : c'est ce que donnerait un effet questionnaire
#   UNIFORME (multiplicatif, identique pour toutes les methodes).
#
# Si l'hypothese est VRAIE (effet localise, purificateur epargne), on attend,
#   dans les DEUX domaines (national, urbain) :
#     S_bas >= 2/3  ET  S_bas - B_bas >= +10 points.
# Si l'hypothese est FAUSSE :
#   - effet uniforme : |S_bas - B_bas| < 10 points dans un domaine au moins ;
#   - effet porte par les appareils : S_bas - B_bas <= -10 points.
# Tout autre cas (S_bas >= B_bas + 10 mais < 2/3 ; domaines en desaccord) :
#   LIMITE, rapporte comme limite.
# Domaine ou |Delta(traite)| < 2 points : parts non interpretees (« ecart
#   trop faible »), le verdict ne porte que sur l'autre domaine et le dit.
# Regle de lecture (Valentine) : verdict VRAIE -> la serie du purificateur
#   est gardee a partir de 1998 ; FAUSSE -> le recul a 1998 ne tient pas
#   pour le purificateur ; LIMITE -> rapporte tel quel, decision a Valentine.
#
# CONFUSION CONNUE, ECRITE D'AVANCE : le Delta du purificateur 1998 -> 2005
#   melange diffusion reelle et effet questionnaire ; cette decomposition ne
#   les separe pas pour le purificateur lui-meme. Elle teste seulement si
#   l'effet questionnaire se voit la ou on l'attend. Chlore et decantation
#   n'existent pas en 1998 : leur niveau 2005 entier entre dans l'ecart, ce
#   qui est par construction un effet de liste (questionnaire).
#
# ===========================================================================
# POINT 2 -- ATTENTES (ECRITES AVANT EXECUTION)
# ===========================================================================
#   C1  sdist (NFHS-2) renseignee pour >= 99 % des menages.
#   C2  NFHS-4 : pour >= 80 % des 640 codes de shdistri, le libelle egale le
#       nom SHRUG du district 2011 de meme pc11_district_id (comparaison en
#       minuscules, lettres seules). Ecarts listes.
#   C3  NFHS-3 : aucune variable de district dans le dictionnaire HR
#       (constat du script 24 : seulement shcity / shslumc / shslums).
#   Rien n'est raccorde : on mesure si un raccord direct existe, et on dit
#   ce qu'il faudrait pour un raccord 1991 -> 2011 correct.
#
# LANCEMENT (racine du depot) : Rscript code/26_piste_c_questionnaire_districts.R
# Sorties : output/tables/26_*.csv (+ .tex) ;
#           output/logs/26_piste_c_questionnaire_districts.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("26_piste_c_questionnaire_districts.log"))
msg("ETAPE 26 -- PISTE C : EFFET QUESTIONNAIRE 1998/2005 ET MAILLE DISTRICT")
msg("Descriptif seulement : aucune regression, aucune issue construite.")

F_N2 <- p_build("25_cache_nfhs2.rds")
F_N3 <- p_build("24_cache_nfhs3.rds")
F_N4 <- p_build("24_cache_nfhs4.rds")
F_N5 <- p_build("24_cache_nfhs5.rds")
F_D11 <- p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg")
F_K91 <- p_raw("shrug", "shrug-pc-keys-dta", "shrid_pc91dist_key.dta")
F_K11 <- p_raw("shrug", "shrug-pc-keys-dta", "shrid_pc11dist_key.dta")

METH <- data.table(
  methode = c("ebullition", "tissu", "alun", "filtre", "purificateur",
              "chlore", "decantation", "autre", "ne_sait_pas"),
  v1998 = c("sh32d", "sh32a", "sh32b", "sh32c", "sh32e", NA, NA, "sh32x", NA),
  v2005 = c("hv237a", "hv237c", "hv237g", "hv237d", "hv237h", "hv237b", "hv237f", "hv237x", "hv237z"),
  groupe = c("faible saillance", "faible saillance", "faible saillance", "appareils", "appareils",
             "faible saillance", "faible saillance", "residuel", "residuel"))
SEUIL_S   <- 2 / 3
SEUIL_DIF <- 0.10
SEUIL_ECART_MIN <- 0.02
SEUIL_C1 <- 0.99
SEUIL_C2 <- 0.80

hr("Attentes ecrites avant execution")
msg("Point 1 : VRAIE si, national ET urbain, S_bas >= 2/3 et S_bas - B_bas >= +10 pts ;")
msg("          FAUSSE si |S_bas - B_bas| < 10 pts (uniforme) ou S_bas - B_bas <= -10 pts ;")
msg("          LIMITE sinon ; domaine ignore si |Delta(traite)| < 2 pts.")
msg("C1 sdist renseignee >= 99 % ; C2 NFHS-4 libelles = noms SHRUG 2011 >= 80 % ;")
msg("C3 aucune variable de district dans le HR du NFHS-3.")

num <- function(x) as.numeric(haven::zap_labels(x))
lib <- function(x) attr(x, "label", exact = TRUE) %||% NA_character_
etiquettes <- function(x) {
  l <- attr(x, "labels", exact = TRUE)
  if (is.null(l)) return(data.table(code = numeric(), libelle = character()))
  data.table(code = as.numeric(l), libelle = names(l))
}
norm_nom <- function(x) gsub("[^a-z]", "", tolower(x))
for (f in c(F_N2, F_N3, F_N4, F_N5)) check(file.exists(f), paste("cache present :", f))

# ===========================================================================
hr("Point 1a. Table menage harmonisee 1998 / 2005")
# ===========================================================================

d2 <- readRDS(F_N2)$d
d3 <- readRDS(F_N3)$d

m98 <- data.table(vague = "1998-99", w = num(d2$nhv005) / 1e6, urbain = num(d2$hv025) == 1)
for (i in seq_len(nrow(METH))) {
  v <- METH$v1998[i]
  m98[, (METH$methode[i]) := if (is.na(v)) 0 else fifelse(num(d2[[v]]) %in% c(0, 1), num(d2[[v]]), NA_real_)]
}
m98[, traite := as.numeric(rowSums(.SD == 1, na.rm = TRUE) > 0), .SDcols = METH$methode]
# Reponse absente : toutes les cases sh32 (methodes et « rien ») manquantes.
sans_reponse <- rowSums(is.na(as.data.table(lapply(c(METH$v1998[!is.na(METH$v1998)], "sh32f"),
                                                   function(k) num(d2[[k]]))))) == 7L
m98[sans_reponse, traite := NA_real_]
m98 <- m98[!is.na(w) & w > 0]
msg("1998 : ", nrow(m98), " menages a poids nhv005 positif ; traite manquant : ", sum(is.na(m98$traite)))

t05 <- num(d3$hv237)
m05 <- data.table(vague = "2005-06", w = num(d3$hv005) / 1e6, urbain = num(d3$hv025) == 1)
for (i in seq_len(nrow(METH))) {
  v <- METH$v2005[i]
  y <- num(d3[[v]])
  m05[, (METH$methode[i]) := fifelse(t05 == 0, 0, fifelse(t05 == 1 & y %in% c(0, 1), y, NA_real_))]
}
m05[, traite := fifelse(t05 %in% c(0, 1), t05, NA_real_)]
k05 <- rowSums(m05[, METH$methode, with = FALSE] == 1, na.rm = TRUE)
m05[traite == 1 & k05 == 0, traite := NA_real_]
msg("2005 : ", nrow(m05), " menages ; traite manquant : ", sum(is.na(m05$traite)),
    " (dont hv237 = 1 sans aucune methode : ", sum(t05 %in% 1 & k05 == 0), ")")

# ===========================================================================
hr("Point 1b. Decomposition de l'ecart de la part traitee")
# ===========================================================================

contributions <- function(m, dom) {
  x <- m[dom & !is.na(traite)]
  k <- rowSums(x[, METH$methode, with = FALSE] == 1, na.rm = TRUE)
  W <- sum(x$w)
  out <- rbindlist(lapply(METH$methode, function(me) {
    y <- fifelse(is.na(x[[me]]), 0, x[[me]])
    data.table(methode = me,
               prevalence = sum(x$w * y) / W,
               contribution = sum(x$w * fifelse(k > 0, y / pmax(k, 1), 0)) / W)
  }))
  list(t = out, traite = sum(x$w * x$traite) / W, n = nrow(x))
}

decomp <- list(); syn <- list()
for (dom in c("national", "urbain")) {
  a <- contributions(m98, if (dom == "national") rep(TRUE, nrow(m98)) else m98$urbain)
  b <- contributions(m05, if (dom == "national") rep(TRUE, nrow(m05)) else m05$urbain)
  check(abs(sum(a$t$contribution) - a$traite) < 1e-9 && abs(sum(b$t$contribution) - b$traite) < 1e-9,
        paste(dom, ": somme des contributions == part traitee (1998 et 2005)"))
  dt <- merge(a$t, b$t, by = "methode", suffixes = c("_1998", "_2005"))
  dt <- merge(METH[, .(methode, groupe)], dt, by = "methode")
  d_tr <- b$traite - a$traite
  dt[, `:=`(domaine = dom, delta_prevalence = prevalence_2005 - prevalence_1998,
            delta_contribution = contribution_2005 - contribution_1998)]
  dt[, part_ecart := delta_contribution / d_tr]
  dt[, part_melange_1998 := contribution_1998 / a$traite]
  decomp[[dom]] <- dt
  g <- dt[, .(delta = sum(delta_contribution), part_ecart = sum(part_ecart),
              part_melange_1998 = sum(part_melange_1998)), by = groupe]
  s_bas <- g[groupe == "faible saillance", part_ecart]
  b_bas <- g[groupe == "faible saillance", part_melange_1998]
  syn[[dom]] <- data.table(domaine = dom, n_1998 = a$n, n_2005 = b$n,
                           traite_1998 = a$traite, traite_2005 = b$traite, delta_traite = d_tr,
                           S_bas = s_bas, B_bas = b_bas, S_moins_B = s_bas - b_bas,
                           part_ecart_appareils = g[groupe == "appareils", part_ecart],
                           part_ecart_purificateur = dt[methode == "purificateur", part_ecart])
  msg("\n", dom, " : part traitee ", sprintf("%.2f %% (1998) -> %.2f %% (2005), ecart %+.2f points",
      100 * a$traite, 100 * b$traite, 100 * d_tr))
  print(dt[order(groupe, methode), .(groupe, methode,
           prev_1998 = round(100 * prevalence_1998, 2), prev_2005 = round(100 * prevalence_2005, 2),
           d_prev = round(100 * delta_prevalence, 2), d_contrib = round(100 * delta_contribution, 2),
           part_ecart = round(100 * part_ecart, 1), melange_1998 = round(100 * part_melange_1998, 1))],
        row.names = FALSE)
  print(g[, .(groupe, delta_points = round(100 * delta, 2), part_ecart = round(100 * part_ecart, 1),
              part_melange_1998 = round(100 * part_melange_1998, 1))], row.names = FALSE)
}
decomp <- rbindlist(decomp); syn <- rbindlist(syn)
fwrite(decomp, p_tab("26_point1_decomposition_methodes.csv"))

# Verdict mecanique contre les seuils ecrits en tete.
syn[, interpretable := abs(delta_traite) >= SEUIL_ECART_MIN]
syn[, lecture := fifelse(!interpretable, "ecart trop faible",
                 fifelse(S_bas >= SEUIL_S & S_moins_B >= SEUIL_DIF, "localise",
                 fifelse(abs(S_moins_B) < SEUIL_DIF, "uniforme",
                 fifelse(S_moins_B <= -SEUIL_DIF, "appareils", "limite"))))]
lect <- syn[interpretable == TRUE, lecture]
verdict <- if (!length(lect)) "NON DECIDABLE (aucun domaine interpretable)" else
  if (all(lect == "localise")) "VRAIE" else
  if (any(lect %in% c("uniforme", "appareils")) && !any(lect == "localise")) "FAUSSE" else "LIMITE"
syn[, verdict := verdict]
print(syn[, .(domaine, traite_1998 = round(100 * traite_1998, 2), traite_2005 = round(100 * traite_2005, 2),
              delta = round(100 * delta_traite, 2), S_bas = round(100 * S_bas, 1),
              B_bas = round(100 * B_bas, 1), S_moins_B = round(100 * S_moins_B, 1),
              appareils = round(100 * part_ecart_appareils, 1),
              purificateur = round(100 * part_ecart_purificateur, 1), lecture)], row.names = FALSE)
msg("VERDICT POINT 1 (contre les seuils ecrits avant execution) : ", verdict)
fwrite(syn, p_tab("26_point1_synthese.csv"))

# ===========================================================================
hr("Point 2a. sdist dans le NFHS-2 (C1)")
# ===========================================================================

msg("sdist : « ", lib(d2$sdist), " » ; modalites etiquetees : ", nrow(etiquettes(d2$sdist)))
sd <- data.table(etat = num(d2$hv024), sdist = num(d2$sdist), urbain = num(d2$hv025) == 1)
couv <- mean(!is.na(sd$sdist))
check(couv >= SEUIL_C1, sprintf("C1 sdist renseignee pour %.2f %% des menages (>= 99 %%)", 100 * couv))
etats <- etiquettes(d2$hv024)
par_dist <- sd[!is.na(sdist), .(menages = .N, urbains = sum(urbain)), by = .(etat, sdist)]
par_etat <- par_dist[, .(districts = .N, sdist_min = min(sdist), sdist_max = max(sdist),
                         menages_med = median(menages)), by = etat]
par_etat[, nom := etats$libelle[match(etat, etats$code)]]
msg("Districts distincts (Etat, sdist) : ", nrow(par_dist),
    " ; codes sdist distincts tous Etats confondus : ", uniqueN(sd$sdist),
    " ; un meme code dans plusieurs Etats : ", sd[!is.na(sdist), uniqueN(etat), by = sdist][V1 > 1, .N], " codes")
msg("Menages par district : ")
print(summary(par_dist$menages))
msg("Districts avec au moins un menage urbain : ", par_dist[urbains > 0, .N],
    " ; menages urbains par district (ces districts) :")
print(summary(par_dist[urbains > 0, urbains]))
print(par_etat[order(nom)], row.names = FALSE, nrows = 50)
fwrite(par_etat, p_tab("26_point2_sdist_par_etat.csv"))
fwrite(par_dist[, .N, by = .(tranche = cut(menages, c(0, 50, 100, 200, 400, 800, Inf)))][order(tranche)],
       p_tab("26_point2_sdist_taille.csv"))

# Recensement 1991 (SHRUG) : nombre de districts par code d'Etat 1991, pour
# situer l'ordre de grandeur (les codes d'Etat NFHS-2 et recensement ne sont
# PAS les memes : aucune jointure n'est faite ici).
k91 <- haven::read_dta(F_K91)
n91 <- unique(as.data.table(k91)[, .(pc91_state_id, pc91_district_id)])
msg("Recensement 1991 (SHRUG, shrid_pc91dist_key) : ", nrow(n91), " districts, ",
    uniqueN(n91$pc91_state_id), " Etats ; ids de district numerotes dans l'Etat : ",
    n91[, uniqueN(pc91_state_id), by = pc91_district_id][V1 > 1, .N] > 0)

# ===========================================================================
hr("Point 2b. NFHS-3 : maille district ? (C3)")
# ===========================================================================

dico3 <- readRDS(F_N3)$dico
dist3 <- dico3[grepl("district|dist", libelle, ignore.case = TRUE) | grepl("dist", variable)]
print(dist3, row.names = FALSE)
check(nrow(dist3) == 0L, "C3 NFHS-3 : aucune variable de district dans le dictionnaire HR",
      paste(dist3$variable, collapse = ", "))

# ===========================================================================
hr("Point 2c. NFHS-4 / NFHS-5 : raccord direct aux districts du recensement 2011 (C2)")
# ===========================================================================

shr <- as.data.table(sf::st_drop_geometry(sf::st_read(F_D11, quiet = TRUE)))
shr[, code := as.numeric(pc11_district_id)]
check_unique(shr[!is.na(code)], "code", "SHRUG district 2011")
msg("SHRUG district.gpkg : ", nrow(shr), " lignes, ", uniqueN(shr$code), " codes")

raccords <- list()
for (v in c("nfhs4", "nfhs5")) {
  d <- readRDS(if (v == "nfhs4") F_N4 else F_N5)$d
  vd <- intersect(c("shdistri", "shdist"), names(d))
  e <- etiquettes(d[[vd]])
  obs <- unique(num(d[[vd]]))
  e <- e[code %in% obs]
  e <- merge(e, shr[, .(code, district_name)], by = "code", all.x = TRUE)
  e[, statut := fifelse(is.na(district_name), "code absent du recensement 2011",
                fifelse(norm_nom(libelle) == norm_nom(district_name), "meme nom", "nom different"))]
  e[, vague := v]
  raccords[[v]] <- e
  msg(v, " (", vd, ") : ", nrow(e), " districts observes ; ",
      paste(names(table(e$statut)), table(e$statut), sep = " = ", collapse = " ; "))
}
raccords <- rbindlist(raccords)
r4 <- raccords[vague == "nfhs4" & code <= 640]
p4 <- mean(r4$statut == "meme nom")
msg("Noms differents (NFHS-4, extrait) :")
print(head(raccords[vague == "nfhs4" & statut == "nom different", .(code, libelle, district_name)], 40),
      row.names = FALSE)
msg("NFHS-5 : codes absents du recensement 2011 (nouveaux districts), extrait :")
print(head(raccords[vague == "nfhs5" & statut == "code absent du recensement 2011", .(code, libelle)], 40),
      row.names = FALSE)
msg("NFHS-5, codes du recensement 2011 au nom different (redecoupage possible), extrait :")
print(head(raccords[vague == "nfhs5" & statut == "nom different", .(code, libelle, district_name)], 40),
      row.names = FALSE)
fwrite(raccords[, .(vague, code, libelle, district_name, statut)], p_tab("26_point2_raccord_nfhs45_pc11.csv"))
syn2 <- raccords[, .N, by = .(vague, statut)][order(vague, statut)]
print(syn2, row.names = FALSE)
fwrite(syn2, p_tab("26_point2_raccord_synthese.csv"))
check(p4 >= SEUIL_C2, sprintf("C2 NFHS-4 : %.1f %% des codes <= 640 au nom SHRUG identique (>= 80 %%)", 100 * p4))

# Ponts disponibles en local pour un raccord 1991 -> 2011 (constat, pas de raccord).
k11 <- haven::read_dta(F_K11, col_select = c("shrid2"))
msg("Ponts SHRUG en local : shrid_pc91dist_key (", nrow(k91), " shrids) et shrid_pc11dist_key (",
    nrow(k11), " shrids) -- cle commune shrid2.")

hr("Limites a consigner")
msg("- point 1 : decomposition ponctuelle, sans intervalle ; diffusion reelle et effet")
msg("  questionnaire confondus pour le purificateur lui-meme ;")
msg("- point 2 : codes sdist sans etiquette ; codes d'Etat NFHS-2 differents du recensement ;")
msg("  aucun raccord construit.")

log_close()
