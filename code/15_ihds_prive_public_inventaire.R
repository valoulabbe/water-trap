# ---------------------------------------------------------------------------
# 15_ihds_prive_public_inventaire.R -- IHDS-I (2004-05) / IHDS-II (2011-12) :
#   ce que le panel porte cote substitut prive (groupe electrogene, forage et
#   pompe du menage agricole) et cote provision publique (source d'eau du
#   menage, fichier village 2011 : sources d'eau, electricite, programme d'eau
#   potable).
#
# PORTEE : COUVERTURE ET COTE PRIVE SEULEMENT. Aucune part de provision
# publique n'est calculee (ni par menage ni par village, ni en niveau ni en
# evolution) : les codes de source d'eau et du fichier village ne sont
# comptes que NON ponderes, pour verifier la couverture. Le cote prive
# (groupe electrogene) est decrit en parts ponderees, comme l'a ete la
# selection des cas DHS (etape 12).
#
# CORRESPONDANCE DES VARIABLES (libelles relus dans les fichiers ICPSR)
#   Groupe electrogene : IHDS-I CG4 « HH22 13.4 Own: Generator set » ;
#     IHDS-II CG6 « HQ26 15.6 Own: Generator set ». ATTENTION : CG4 en
#     IHDS-II est la bicyclette -- la liste des biens a ete renumerotee.
#   Electricite du menage : FU1 (oui/non), FU1A (heures par jour), deux vagues.
#   Source d'eau : IHDS-I WA1 (code 01 « Piped ») ; IHDS-II WA1A (code 01
#     « Piped (public supply) ») : libelle different, a garder en tete.
#   Equipement agricole : IHDS-I FM32A/B/C (forages, pompes electriques,
#     pompes diesel ; seules les valeurs >= 1 sont saisies, NA sinon) ;
#     IHDS-II FM40A/B/C (0 saisi). Univers different entre vagues : non
#     comparable sans reconstruction de l'univers agricole.
#   Fichier village : seulement IHDS-II (DS0012, 1 410 villages). Le fichier
#     village IHDS-I (DS0007) n'a PAS ete telecharge : seuls codebook et
#     questionnaire sont dans raw/ihds/2005/DS0007.
#     VI4A part (%) des menages electrifies (et non oui/non malgre le libelle) ;
#     VI4B premiere annee d'electricite ; VI4C nombre d'annees ; VI4D heures
#     par jour ; VI10A-C sources d'eau de boisson 1 a 3 ; VI18K programme
#     « Safe Drinking Water » ; VQ9Y annee d'entretien.
#   Cle village : IDPSU est vide dans DS0012 ; lien par STATEID + DISTID + PSUID.
#
# LANCEMENT (racine du depot) :
#     Rscript code/15_ihds_prive_public_inventaire.R           # reprend
#     Rscript code/15_ihds_prive_public_inventaire.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 15_ihds_menages.rds  extraits menages des deux vagues
#   2. 15_ihds_village.rds  extrait village IHDS-II
# Les tableaux sont toujours recalcules (quelques secondes).
#
# Sorties : output/tables/15_*.csv, output/logs/15_ihds_prive_public_inventaire.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("15_ihds_prive_public_inventaire.log"))

msg("ETAPE 15 -- IHDS : SUBSTITUT PRIVE ET COUVERTURE DE LA PROVISION PUBLIQUE")
msg("Couverture et cote prive seulement : aucune part de provision publique calculee.")

N_DOC <- list(ihds1 = 41554L, ihds2 = 42152L, village2 = 1410L)

IHDS <- list(
  ihds1 = list(fichier = p_raw("ihds", "2005", "DS0002", "22626-0002-Data.rda"),
               ids = c("STATEID", "DISTID", "PSUID", "HHID", "HHSPLITID"),
               urbain = "URBAN", poids = "SWEIGHT", conso = "COPC",
               generateur = "CG4", elec = "FU1", elec_h = "FU1A", eau = "WA1",
               agri = c(forages = "FM32A", pompes_elec = "FM32B", pompes_diesel = "FM32C")),
  ihds2 = list(fichier = p_raw("ihds", "2011", "DS0002", "36151-0002-Data.rda"),
               ids = c("STATEID", "DISTID", "PSUID", "HHID", "HHSPLITID"),
               urbain = "URBAN2011", poids = "WT", conso = "COPC",
               generateur = "CG6", elec = "FU1", elec_h = "FU1A", eau = "WA1A",
               agri = c(forages = "FM40A", pompes_elec = "FM40B", pompes_diesel = "FM40C"))
)
# libelle attendu de la variable groupe electrogene : arret si la renumerotation
# des biens n'est pas celle relue ci-dessus
LIB_GEN <- "Generator set"

VILLAGE <- list(fichier = p_raw("ihds", "2011", "DS0012", "36151-0012-Data.rda"),
                ids = c("STATEID", "DISTID", "PSUID"),
                vars = c("VQ9Y", "VI4A", "VI4B", "VI4C", "VI4D",
                         "VI10A", "VI10B", "VI10C", "VI18K"))

# facteur ICPSR "(01) Piped" -> code entier 1 (meme regle qu'a l'etape 11)
code_icpsr <- function(x) {
  if (!is.factor(x)) return(as.numeric(x))
  as.numeric(sub("^\\((-?[0-9]+)\\).*$", "\\1", as.character(x)))
}
charge_rda <- function(f) { e <- new.env(); o <- load(f, envir = e); e[[o]] }

# ===========================================================================
# Etape 1 : menages
# ===========================================================================
hr("15a. Extraits menages (etape 1)")

men <- stage("etape 1/2 menages IHDS", p_build("15_ihds_menages.rds"), function() {
  lapply(IHDS, function(s) {
    tmsg("  lecture ", s$fichier)
    d <- charge_rda(s$fichier)
    vars <- c(s$ids, s$urbain, s$poids, s$conso, s$generateur, s$elec, s$elec_h, s$eau, s$agri)
    check_vars(d, vars, basename(s$fichier))
    lab <- attr(d, "variable.labels")
    check(grepl(LIB_GEN, lab[[s$generateur]], fixed = TRUE),
          sprintf("%s : %s est bien le groupe electrogene", basename(s$fichier), s$generateur),
          paste("libelle observe :", lab[[s$generateur]]))
    niv <- rbindlist(lapply(c(s$urbain, s$generateur, s$elec, s$eau), function(v)
      data.table(variable = v, niveau = levels(d[[v]]))))
    out <- as.data.table(lapply(setNames(vars, vars), function(v) code_icpsr(d[[v]])))
    list(d = out, libelles = data.table(variable = vars, libelle = unname(lab[vars])),
         niveaux = niv)
  })
})

for (w in names(IHDS)) {
  msg(""); msg(w, " : ", basename(IHDS[[w]]$fichier))
  check_rows(men[[w]]$d, N_DOC[[w]], w)
  check_unique(men[[w]]$d, IHDS[[w]]$ids, w)
  print(men[[w]]$libelles)
}

# --- couverture --------------------------------------------------------------
hr("15b. Couverture des variables menage (non NA, non pondere)")

couv <- rbindlist(lapply(names(IHDS), function(w) {
  d <- men[[w]]$d; lab <- men[[w]]$libelles
  data.table(vague = w, variable = lab$variable, libelle = lab$libelle,
             non_na_pct = round(100 * sapply(lab$variable, function(v) mean(!is.na(d[[v]]))), 1))
}))
op <- options(width = 200); print(couv); options(op)
fwrite(couv, p_tab("15_couverture_menages.csv"))

# codes de la source d'eau : comptes NON ponderes seulement (couverture)
eau_codes <- rbindlist(lapply(names(IHDS), function(w) {
  s <- IHDS[[w]]
  t <- men[[w]]$d[, .N, keyby = .(code = get(s$eau))]
  niv <- men[[w]]$niveaux[variable == s$eau]
  niv[, code := code_icpsr(factor(niveau))]
  merge(t, niv[, .(code, niveau)], by = "code", all = TRUE)[, `:=`(vague = w, variable = s$eau)]
}))
setcolorder(eau_codes, c("vague", "variable", "code", "niveau", "N"))
msg("  Source d'eau de boisson, codes observes (non pondere) :")
print(eau_codes)
fwrite(eau_codes, p_tab("15_eau_codes_menages.csv"))

# ===========================================================================
# Cote prive : groupe electrogene
# ===========================================================================
hr("15c. Groupe electrogene : niveau par vague (cote prive)")

gen <- rbindlist(lapply(names(IHDS), function(w) {
  s <- IHDS[[w]]; d <- men[[w]]$d
  d[!is.na(get(s$generateur)),
    .(menages = .N, possesseurs = sum(get(s$generateur) == 1),
      part_brute_pct = round(100 * mean(get(s$generateur) == 1), 2),
      part_ponderee_pct = round(100 * weighted.mean(get(s$generateur) == 1, get(s$poids),
                                                    na.rm = TRUE), 2)),
    keyby = .(urbain = get(s$urbain))][, vague := w]
}))
gen[, urbain := fifelse(urbain == 1, "urbain", "rural")]
setcolorder(gen, "vague")
print(gen)
fwrite(gen, p_tab("15_generateur_par_vague.csv"))

# gradient de revenu : quintiles de consommation par tete, au sein de chaque
# vague et de chaque secteur, ponderes
hr("15d. Groupe electrogene par quintile de consommation (pondere)")
quint <- function(x, w) {
  o <- order(x); cw <- cumsum(w[o]) / sum(w[o])
  q <- integer(length(x)); q[o] <- pmin(5L, 1L + floor(5 * (cw - 1e-12)))
  q
}
gq <- rbindlist(lapply(names(IHDS), function(w) {
  s <- IHDS[[w]]
  d <- men[[w]]$d[!is.na(get(s$generateur)) & !is.na(get(s$conso)) & !is.na(get(s$poids))]
  d[, q := quint(get(s$conso), get(s$poids)), by = .(u = get(s$urbain))]
  d[, .(menages = .N, possesseurs = sum(get(s$generateur) == 1),
        part_ponderee_pct = round(100 * weighted.mean(get(s$generateur) == 1, get(s$poids)), 2)),
    keyby = .(urbain = fifelse(get(s$urbain) == 1, "urbain", "rural"), quintile = q)][, vague := w]
}))
setcolorder(gq, "vague")
print(gq)
fwrite(gq, p_tab("15_generateur_quintile.csv"))

# --- panel : transitions -----------------------------------------------------
# Cle de panel etablie a l'etape 11 : HHID(II) = 10 x HHID(I) + HHSPLITID(I) ;
# HHSPLITID(II) = 9 -> menage ajoute, sans lien.
hr("15e. Groupe electrogene : transitions dans le panel (non pondere)")
a <- men$ihds1$d; b <- men$ihds2$d
a[, cle := paste(STATEID, DISTID, PSUID, 10 * HHID + HHSPLITID)]
b[, cle := paste(STATEID, DISTID, PSUID, HHID)]
lie <- merge(b[HHSPLITID != 9, .(cle, gen_II = CG6, urbain_II = URBAN2011)],
             a[, .(cle, gen_I = CG4)], by = "cle")
check(nrow(lie) > 30000L, "panel : plus de 30 000 menages IHDS-II relies a IHDS-I",
      sprintf("observe : %d", nrow(lie)))
trans <- lie[!is.na(gen_I) & !is.na(gen_II), .N, keyby = .(gen_I, gen_II)]
trans[, part_pct := round(100 * N / sum(N), 2)]
print(trans)
fwrite(trans, p_tab("15_generateur_panel.csv"))

# ===========================================================================
# Etape 2 : fichier village IHDS-II
# ===========================================================================
hr("15f. Fichier village IHDS-II (etape 2)")

vil <- stage("etape 2/2 village IHDS-II", p_build("15_ihds_village.rds"), function() {
  tmsg("  lecture ", VILLAGE$fichier)
  d <- charge_rda(VILLAGE$fichier)
  vars <- c(VILLAGE$ids, VILLAGE$vars)
  check_vars(d, vars, basename(VILLAGE$fichier))
  lab <- attr(d, "variable.labels")
  niv <- rbindlist(lapply(c("VI10A", "VI10B", "VI10C", "VI18K", "VI4B"), function(v)
    data.table(variable = v, niveau = levels(d[[v]]))))
  # VI4B : facteur dont les niveaux sont des annees ou "" -> annee numerique
  out <- as.data.table(lapply(setNames(vars, vars), function(v)
    if (v == "VI4B") suppressWarnings(as.numeric(as.character(d[[v]]))) else code_icpsr(d[[v]])))
  list(d = out, libelles = data.table(variable = vars, libelle = unname(lab[vars])), niveaux = niv)
})
v <- vil$d
check_rows(v, N_DOC$village2, "village IHDS-II")
check_unique(v, VILLAGE$ids, "village IHDS-II")
print(vil$libelles)
couv_v <- data.table(variable = vil$libelles$variable, libelle = vil$libelles$libelle,
                     non_na_pct = round(100 * sapply(vil$libelles$variable,
                                                     function(x) mean(!is.na(v[[x]]))), 1))
print(couv_v)
fwrite(couv_v, p_tab("15_couverture_village.csv"))

# --- lien menages -> village ---------------------------------------------------
hr("15g. Lien des menages ruraux au fichier village (STATEID + DISTID + PSUID)")
v[, cle_psu := paste(STATEID, DISTID, PSUID)]
a[, cle_psu := paste(STATEID, DISTID, PSUID)]
b[, cle_psu := paste(STATEID, DISTID, PSUID)]
lien_v <- rbind(
  b[, .(menages = .N, psu = uniqueN(cle_psu),
        menages_lies = sum(cle_psu %in% v$cle_psu),
        psu_lies = uniqueN(cle_psu[cle_psu %in% v$cle_psu])),
    keyby = .(urbain = URBAN2011)][, vague := "ihds2"],
  a[, .(menages = .N, psu = uniqueN(cle_psu),
        menages_lies = sum(cle_psu %in% v$cle_psu),
        psu_lies = uniqueN(cle_psu[cle_psu %in% v$cle_psu])),
    keyby = .(urbain = URBAN)][, vague := "ihds1"])
lien_v[, urbain := fifelse(urbain == 1, "urbain", "rural")]
setcolorder(lien_v, "vague")
print(lien_v)
check(lien_v[vague == "ihds2" & urbain == "rural", menages_lies / menages] > 0.8,
      "IHDS-II : plus de 80 % des menages ruraux relies a un village",
      "lien par STATEID + DISTID + PSUID insuffisant -- arret, cle a revoir")
fwrite(lien_v, p_tab("15_village_lien.csv"))

# Classement de chaque fiche village selon le statut de ses menages aux deux
# vagues (diagnostic du 02/10 : 48 PSU urbains en 2011 sont relies a une fiche
# village). rural_rural : rural aux deux vagues ; reclasse : rural en IHDS-I
# (recensement 2001), urbain en IHDS-II (recensement 2011), attendu pour les
# villes de recensement ; urbain_urbain : urbain aux deux vagues, NON explique
# (collision de numerotation village / bloc urbain possible) -- signale, a
# exclure de tout travail au niveau village.
st1 <- a[, .(urbain_I = max(URBAN)), by = cle_psu]
st2 <- b[, .(urbain_II = max(URBAN2011)), by = cle_psu]
check(a[, uniqueN(URBAN), by = cle_psu][, all(V1 == 1L)] &&
        b[, uniqueN(URBAN2011), by = cle_psu][, all(V1 == 1L)],
      "chaque PSU est tout rural ou tout urbain au sein d'une vague")
v[st1, urbain_I := i.urbain_I, on = "cle_psu"]
v[st2, urbain_II := i.urbain_II, on = "cle_psu"]
v[, statut_psu := fcase(
  is.na(urbain_II), "sans menage IHDS-II",
  urbain_II == 0 & (is.na(urbain_I) | urbain_I == 0), "rural_rural",
  urbain_II == 1 & !is.na(urbain_I) & urbain_I == 0, "reclasse_rural_vers_urbain",
  urbain_II == 1 & !is.na(urbain_I) & urbain_I == 1, "urbain_urbain_inexplique",
  urbain_II == 0 & urbain_I == 1, "urbain_vers_rural",
  default = "urbain_II_absent_de_I")]
cls <- v[, .N, keyby = statut_psu]
print(cls)
check(sum(cls$N) == N_DOC$village2 && !("sans menage IHDS-II" %in% cls$statut_psu),
      "toute fiche village est reliee a un PSU de menages IHDS-II")
check(cls[statut_psu == "urbain_urbain_inexplique", sum(N)] <= 13L,
      "au plus 13 fiches village urbaines aux deux vagues (chiffre du diagnostic du 02/10)",
      paste("observe :", cls[statut_psu == "urbain_urbain_inexplique", sum(N)]))
fwrite(cls, p_tab("15_village_statut_psu.csv"))
fwrite(v[statut_psu == "urbain_urbain_inexplique", .(STATEID, DISTID, PSUID)],
       p_tab("15_village_psu_inexpliques.csv"))

# PSU ruraux presents aux deux vagues et taille par PSU : faisabilite d'une
# agregation au village depuis les menages (aucune variable de resultat)
psu2 <- b[URBAN2011 == 0, .(n_II = .N), by = cle_psu]
psu1 <- a[URBAN == 0, .(n_I = .N), by = cle_psu]
psu <- merge(psu1, psu2, by = "cle_psu", all = TRUE)
psu_res <- psu[, .(psu_ruraux_I = sum(!is.na(n_I)), psu_ruraux_II = sum(!is.na(n_II)),
                   psu_deux_vagues = sum(!is.na(n_I) & !is.na(n_II)),
                   menages_par_psu_med_I = median(n_I, na.rm = TRUE),
                   menages_par_psu_med_II = median(n_II, na.rm = TRUE),
                   psu_deux_vagues_dans_village = sum(!is.na(n_I) & !is.na(n_II) &
                                                        cle_psu %in% v$cle_psu))]
print(psu_res)
fwrite(psu_res, p_tab("15_psu_ruraux_panel.csv"))

# --- electrification : date ----------------------------------------------------
hr("15h. Date d'electrification du village (VI4B, ou VQ9Y - VI4C)")
# VQ9Y est code sur deux chiffres (11 a 13) ; VI4B porte des valeurs qui ne
# sont pas des annees (0, 30...) : seules 1900-2013 sont gardees ; VI4C = 99
# traite comme code « ne sait pas » (valeur maximale, isolee).
msg("  VQ9Y observe : ", paste(names(table(v$VQ9Y, useNA = "ifany")), table(v$VQ9Y, useNA = "ifany"), sep = " -> ", collapse = " ; "))
check(all(v$VQ9Y %in% c(11, 12, 13, NA)), "VQ9Y code sur deux chiffres (11 a 13)")
v[, an_entretien := 2000 + VQ9Y]
msg(sprintf("  VI4B hors 1900-2013 (mis a NA) : %d ; VI4C == 99 (mis a NA) : %d",
            v[!is.na(VI4B) & !between(VI4B, 1900, 2013), .N], v[VI4C %in% 99, .N]))
v[, VI4B_an := fifelse(between(VI4B, 1900, 2013), VI4B, NA_real_)]
v[, VI4C_n := fifelse(VI4C < 99, VI4C, NA_real_)]
v[, an_elec := fifelse(!is.na(VI4B_an), VI4B_an, an_entretien - VI4C_n)]
v[, source_date := fcase(!is.na(VI4B_an), "VI4B annee",
                         !is.na(VI4C_n), "annee d'entretien - VI4C",
                         default = "aucune")]
msg("  Coherence quand VI4B et VI4C sont tous deux renseignes :")
both <- v[!is.na(VI4B_an) & !is.na(VI4C_n)]
msg(sprintf("    %d villages ; |VI4B - (entretien - VI4C)| <= 1 an : %d ; <= 3 ans : %d",
            nrow(both), both[, sum(abs(VI4B_an - (an_entretien - VI4C_n)) <= 1)],
            both[, sum(abs(VI4B_an - (an_entretien - VI4C_n)) <= 3)]))
print(v[, .N, keyby = source_date])
v[, periode := fcase(is.na(an_elec), "inconnue",
                     an_elec < 1980, "avant 1980", an_elec < 1990, "1980-89",
                     an_elec < 2000, "1990-99", an_elec < 2005, "2000-04",
                     an_elec <= 2012, "2005-12 (entre les vagues)", default = "apres 2012 ?")]
elec <- v[, .(villages = .N, heures_med = median(VI4D, na.rm = TRUE),
              part_menages_elec_med = median(VI4A, na.rm = TRUE)), keyby = periode]
print(elec)
fwrite(elec, p_tab("15_village_electrification.csv"))

# --- codes eau du fichier village : NON ponderes, couverture seulement ------------
hr("15i. Codes eau du fichier village (non pondere, couverture)")
vc <- rbindlist(lapply(c("VI10A", "VI10B", "VI10C", "VI18K"), function(x) {
  t <- v[, .N, keyby = .(code = get(x))]
  niv <- vil$niveaux[variable == x][, code := code_icpsr(factor(niveau))]
  merge(t, niv[, .(code, niveau)], by = "code", all = TRUE)[, variable := x]
}))
setcolorder(vc, c("variable", "code", "niveau", "N"))
print(vc)
fwrite(vc, p_tab("15_village_codes_eau.csv"))

hr("ETAPE 15 TERMINEE")
for (f in sort(list.files(p_tab(), pattern = "^15_"))) msg("  ", f)
log_close()
