# ---------------------------------------------------------------------------
# 35_piste_j_source_publique_privee.R -- piste J : source d'eau de boisson,
#   reseau public contre eau souterraine privee, dans les NFHS (DHS Inde),
#   Household Recode, vagues 2 a 5.
#
# MOTIF : la piste C portait sur le traitement de l'eau. Le filtre (hv237d)
# ne concerne que 6.6 % des menages en 2005-06, et tout traitement confondu
# 34.4 % (script 15, controle sur le tableau 2.11 du rapport NFHS-3). La
# source d'eau, elle, partage les menages a peu pres en deux : 42.8 % sur
# puits tube ou forage contre 42.0 % sur reseau public, soit 24.5 % d'eau
# courante dans le logement ou la parcelle et 17.5 % de borne-fontaine
# (rapport final NFHS-3, vol. 1, tableau 2.11, p. 35 ; reproduit en 35h).
# C'est la question d'origine du projet, eau souterraine privee contre reseau
# public, mais au niveau menage et croisee avec la richesse.
#
# PORTEE : parts ponderees descriptives par vague, quintile, secteur et Etat.
# Aucune fusion entre sources, aucune estimation causale. hv001 (grappe) est
# garde dans build/ pour l'analyse intra-grappe a venir, non faite ici.
#
# CLASSIFICATION : hv201 (type de source) x hv235 (localisation : 1 logement,
# 2 cour/parcelle, 3 ailleurs). Table de correspondance par vague dans
# code/ref/35_hv201_classes.csv : colonnes loc_1_2 / loc_3 / loc_na = classe
# selon hv235. TROIS nomenclatures distinctes (verifiees sur les etiquettes
# de valeur des .DTA, controlees en 35b) :
#   - NFHS-2 : codage propre, prive/public NATIF dans hv201 (21 handpump in
#     residence / 22 public handpump, 23 well in residence / 25-26 public
#     wells). Le code 24 "open well" n'est ni prive ni public : classe a part
#     souterrain_indetermine.
#   - NFHS-3 et 4 : 11-12 reseau a domicile, 13 borne, 21/31/32 souterrain
#     sans distinction prive/public, 71 embouteille, 72 RO communautaire
#     (NFHS-4 seulement).
#   - NFHS-5 : 13 devient "piped to neighbor" (classe en reseau partage, par
#     jugement), la borne passe en 14 et le RO communautaire en 92.
# Un menage souterrain sans hv235 tombe dans souterrain_loc_inconnue, pas
# dans prive ni dans partage. La distribution brute de hv201 (35c bis) fait
# ressortir tout code observe absent de la table.
#
# RUPTURE DE SERIE NFHS-5 : "piped to neighbor" (code 13) pese 1.62 % des
# menages en NFHS-5 (1.71 % urbain, 1.58 % rural ; 35c bis). Cette categorie
# n'existe pas avant et ces menages etaient comptes ailleurs, sous un code
# inconnu. Rapporte aux 15.0 % de reseau_public_partage en NFHS-5, ce n'est
# pas negligeable : la serie reseau_public_partage N'EST PAS COMPARABLE entre
# NFHS-4 et NFHS-5, et reseau_public_domicile ne l'est pas non plus si ces
# menages s'y declaraient auparavant.
#
# PRIVE / PARTAGE : NON VALIDABLE DANS LE NFHS (constat definitif). Seule
# NFHS-2 porte une distinction native dans hv201, et hv235 y est absent
# (verifie sur les entetes du .DTA et sur le .MAP, qui n'a aucune variable
# HV230-HV239). La matrice de confusion natif x localisation ne sera donc
# jamais produite a partir de cette source. Le codage natif est de toute
# facon ambigu sur le cas qui decide : "handpump in residence/yard/plot" nomme
# un lieu, "public handpump" nomme un statut, et une pompe publique dans une
# cour satisfait les deux libelles.
# CONSEQUENCE : souterrain_prive mesure une LOCALISATION, pas une propriete.
# Une pompe a main publique (India Mark II) installee sur une parcelle y entre
# comme du prive. C'est le meme contaminant que celui deja note pour
# private_gw dans SHRUG.
#
# POMPE A EAU : HYPOTHESE FALSIFIEE. La pompe devait etre une mesure directe
# de l'infrastructure privee, avec une reserve sur le surpresseur. Les
# sorties (35g) montrent que la reserve est le cas dominant : la possession
# varie d'un facteur dix a douze entre quintiles (NFHS-4 : 3.5 % en Q1 contre
# 41.0 % en Q5) et de moins d'un facteur deux entre classes de source (21.1 %
# chez les raccordes a domicile contre 24.8 % en souterrain prive), et les
# menages a l'eau embouteillee (27.3 %) ou au RO communautaire (22.9 % ;
# 33.0 % en NFHS-5) sont parmi les plus equipes. La pompe mesure la richesse
# et le type de logement, pas le type de source : elle ne peut servir ni de
# validation de hv235 ni de mesure independante du substitut prive. Les
# tables 35g sont gardees parce qu'elles documentent ce constat.
#
# Variable pompe, nom propre a chaque vague : sh47q (1998, "water pump"),
# sh47u (2005, "has water pump"), sh37x (2015), sh50x (2019).
#
# QUINTILES : NFHS-2 n'a ni hv270 ni hv271 (absente des tables par quintile).
# hv270 est relatif a chaque vague, et NFHS-5 utilise l'indice "combined" la
# ou NFHS-3 et 4 n'ont qu'un hv270 simple (NFHS-5 a en plus hv270a, urbain /
# rural). Toute comparaison par quintile entre vagues compare des positions
# relatives, pas des niveaux de vie absolus.
#
# ETATS : les codes hv024 different entre vagues (creations d'Etats,
# recodages). La table par Etat n'est pas comparable entre vagues en l'etat ;
# une table de passage sera necessaire (non construite ici).
#
# CONTROLE 35h, EAU EMBOUTEILLEE : le rapport la publie sur deux lignes selon
# la source d'eau non potable (hv202), "Bottled water, improved / non-improved
# source for cooking, handwashing". Liste "amelioree" retenue pour hv202 :
# 11, 12, 13, 21, 31, 41, 51 (reseau logement/parcelle, borne, forage, puits
# protege, source protegee, pluie). C'est un CHOIX DE CODAGE, fonde sur la
# definition JMP OMS/UNICEF des sources ameliorees reprise par le Guide to
# DHS Statistics (camion et charrette non ameliores dans cette definition).
# Tout le reste, y compris hv202 = 99 (manquant), compte comme non ameliore :
# definition residuelle.
# SENSIBILITE : la ligne non amelioree URBAINE ne passe que sous cette
# convention. 99 = non ameliore : 0.0582 contre 0.1 publie (ecart 0.042,
# passe). 99 = manquant : 0.0463 (ecart 0.054, ECHOUE). Les autres cases
# passent dans les deux cas (35h affiche la variante). Ce controle-la est
# donc plus faible qu'il n'en a l'air : il ne tranche pas la convention, il
# est compatible avec une seule des deux.
# hv202 n'est utilisable qu'en NFHS-3 : les .MAP de NFHS-2, 4 et 5 le
# libellent "NA - Source of non-drinking water" ; 35h constate les non
# manquants vague par vague.
#
# DENOMINATEUR : convention DHS, comme le script 15 -- tous les menages ; hv201
# manquant (NA, ou 99 non etiquete en NFHS-3) forme une classe "manquant",
# pompe inconnue compte comme non.
#
# LANCEMENT (racine du depot) :
#     Rscript code/35_piste_j_source_publique_privee.R           # reprend
#     Rscript code/35_piste_j_source_publique_privee.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 35_nfhs_entetes.rds  noms, libelles et etiquettes de valeur, par vague
#   2. 35_nfhs_menages.rds  colonnes utiles de chaque Household Recode
#
# Sorties : output/tables/35_*.csv, output/logs/35_piste_j_source_publique_privee.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("35_piste_j_source_publique_privee.log"))

msg("ETAPE 35 -- PISTE J : SOURCE D'EAU, RESEAU PUBLIC CONTRE SOUTERRAIN PRIVE (NFHS 2 a 5)")
msg("Parts ponderees descriptives. Aucune fusion, aucune estimation causale.")

# --- vagues ----------------------------------------------------------------
VAGUES <- list(
  nfhs2 = list(annee = "1998-99", pompe = "sh47q",
               fichier = p_raw("dhs", "india", "1998", "IAHR42DT", "IAHR42FL.DTA")),
  nfhs3 = list(annee = "2005-06", pompe = "sh47u",
               fichier = p_raw("dhs", "india", "2005", "IAHR52DT", "IAHR52FL.dta")),
  nfhs4 = list(annee = "2015-16", pompe = "sh37x",
               fichier = p_raw("dhs", "india", "2015", "IAHR74DT", "IAHR74FL.DTA")),
  nfhs5 = list(annee = "2019-21", pompe = "sh50x",
               fichier = p_raw("dhs", "india", "2019", "IAHR7EDT", "IAHR7EFL.DTA"))
)

# Obligatoires partout (arret si absentes) ; optionnelles : avertissement
# nommant la vague et la variable. La pompe est ajoutee vague par vague.
OBLIG <- c(poids = "hv005", grappe = "hv001", etat = "hv024", secteur = "hv025",
           source = "hv201")
OPT   <- c(quintile = "hv270", score = "hv271", localisation = "hv235",
           temps = "hv204", electricite = "hv206", non_potable = "hv202")

CLASSES <- c("reseau_public_domicile", "reseau_public_partage",
             "souterrain_prive", "souterrain_partage", "souterrain_loc_inconnue",
             "souterrain_indetermine", "embouteille", "ro_communautaire",
             "surface_et_autre", "manquant")

if (!requireNamespace("haven", quietly = TRUE))
  stop("PACKAGE INDISPONIBLE : haven est requis pour lire les .DTA des NFHS. ",
       "Arret -- aucune relance automatique.", call. = FALSE)

# --- table de correspondance -----------------------------------------------
hr("35a. Table de correspondance hv201 -> classe (code/ref)")
f_ref <- file.path("code", "ref", "35_hv201_classes.csv")
check(file.exists(f_ref), paste0("table de correspondance presente -> ", f_ref))
REF <- fread(f_ref, colClasses = list(character = c("vague", "libelle_dhs", "note"),
                                      numeric = "hv201"))
check_vars(REF, c("vague", "hv201", "libelle_dhs", "loc_1_2", "loc_3", "loc_na"), "ref")
check_unique(REF, c("vague", "hv201"), "ref")
check(setequal(unique(REF$vague), names(VAGUES)), "ref : une table par vague, ni plus ni moins")
cl_ref <- unique(unlist(REF[, .(loc_1_2, loc_3, loc_na)]))
check(all(cl_ref %in% CLASSES), "ref : toutes les classes sont connues",
      paste("inconnues :", paste(setdiff(cl_ref, CLASSES), collapse = ", ")))
note(nrow(REF), " lignes ; dependantes de hv235 : ",
     REF[loc_1_2 != loc_3 | loc_1_2 != loc_na, .N])

# ===========================================================================
# Etape 1 : entetes de chaque vague (zero ligne)
# ===========================================================================
hr("35b. Variables et etiquettes par vague (etape 1)")

f_ent <- p_build("35_nfhs_entetes.rds")
ent <- stage("etape 1/2 entetes NFHS", f_ent, function() {
  res <- lapply(names(VAGUES), function(v) {
    f <- VAGUES[[v]]$fichier
    tmsg("  lecture des entetes ", f)
    check(file.exists(f), paste0(v, " : fichier present -> ", f))
    d <- haven::read_dta(f, n_max = 0L)
    vars <- data.table(vague = v, variable = names(d),
                       libelle = vapply(d, function(x) attr(x, "label") %||% "", character(1)))
    codes <- rbindlist(lapply(intersect(c("hv201", "hv235"), names(d)), function(cc) {
      lb <- attr(d[[cc]], "labels")
      if (!length(lb)) return(NULL)
      data.table(vague = v, variable = cc, code = as.numeric(lb), etiquette = names(lb))
    }))
    list(vars = vars, codes = codes)
  })
  list(vars  = rbindlist(lapply(res, `[[`, "vars")),
       codes = rbindlist(lapply(res, `[[`, "codes")))
})

for (v in names(VAGUES)) {
  dispo <- ent$vars[vague == v, variable]
  msg(""); msg(v, " (", VAGUES[[v]]$annee, ") : ", length(dispo), " variables")
  vise <- c(OBLIG, pompe = VAGUES[[v]]$pompe)
  check(all(vise %in% dispo), paste0(v, " : ", length(vise), " variables obligatoires presentes"),
        paste("absentes :", paste(setdiff(vise, dispo), collapse = ", ")))
  for (k in names(OPT)[!OPT %in% dispo])
    warn(v, " : variable optionnelle absente -> ", OPT[[k]], " (", k, ")")
}

msg(""); msg("Libelles observes des variables utilisees")
lib_obs <- ent$vars[variable %in% c(OBLIG, OPT, sapply(VAGUES, `[[`, "pompe"))][order(variable, vague)]
op <- options(width = 200); print(lib_obs, nrows = 200); options(op)
fwrite(lib_obs, p_tab("35_nfhs_libelles.csv"))

# La table de correspondance doit coller aux etiquettes de valeur de chaque
# vague : meme code, meme libelle. C'est ce qui empeche d'appliquer le codage
# d'une vague a une autre (13 = borne en NFHS-3/4, voisin en NFHS-5).
msg(""); msg("Concordance table de correspondance / etiquettes hv201 des .DTA")
et <- ent$codes[variable == "hv201", .(vague, hv201 = code, etiquette = tolower(trimws(etiquette)))]
cmp <- merge(REF[, .(vague, hv201, libelle_dhs = tolower(trimws(libelle_dhs)))], et,
             by = c("vague", "hv201"), all.x = TRUE)
bad <- cmp[is.na(etiquette) | etiquette != libelle_dhs]
if (nrow(bad)) print(bad)
check(nrow(bad) == 0L, "ref : chaque code a la meme etiquette que dans le .DTA de sa vague",
      sprintf("%d discordance(s)", nrow(bad)))
# codes etiquetes non couverts : seuls les codes de rubrique (multiples de 10)
non_couv <- et[!REF, on = c("vague", "hv201")]
note("codes etiquetes hors table (rubriques attendues) : ",
     paste(unique(non_couv$hv201), collapse = ", "))
check(all(non_couv$hv201 %% 10 == 0), "ref : seuls des codes de rubrique sont hors table",
      paste("non couverts :", paste(non_couv[hv201 %% 10 != 0, paste(vague, hv201)], collapse = ", ")))

# ===========================================================================
# Etape 2 : colonnes utiles de chaque vague
# ===========================================================================
hr("35c. Lecture des Household Recode (etape 2)")

f_men <- p_build("35_nfhs_menages.rds")
men <- stage("etape 2/2 menages NFHS", f_men, function() {
  lapply(names(VAGUES), function(v) {
    f <- VAGUES[[v]]$fichier
    dispo <- ent$vars[vague == v, variable]
    vars <- intersect(c(OBLIG, OPT, VAGUES[[v]]$pompe), dispo)
    tmsg("  lecture ", f, " (", length(vars), " colonnes)")
    raw <- haven::read_dta(f, col_select = all_of(vars))
    etat_nom <- as.character(haven::as_factor(raw$hv024, levels = "labels"))
    d <- as.data.table(lapply(raw, as.numeric))
    setnames(d, VAGUES[[v]]$pompe, "pompe")
    d[, `:=`(vague = v, etat_nom = etat_nom)]
    d[]
  }) |> setNames(names(VAGUES))
}, after = f_ent)

for (v in names(VAGUES)) {
  d <- men[[v]]
  msg(""); msg(v, " (", VAGUES[[v]]$annee, ") : ", format(nrow(d), big.mark = " "), " menages")
  # une sortie d'etape 2 anterieure a l'ajout d'une colonne serait relue telle
  # quelle : on exige toutes les colonnes attendues
  attendues <- setdiff(intersect(c(OBLIG, OPT, VAGUES[[v]]$pompe), ent$vars[vague == v, variable]),
                       VAGUES[[v]]$pompe)
  check(all(c(attendues, "pompe") %in% names(d)),
        paste0(v, " : toutes les colonnes attendues dans ", f_men),
        paste("absentes :", paste(setdiff(c(attendues, "pompe"), names(d)), collapse = ", "),
              "-- relancer avec --force"))
  check(nrow(d) > 0L, paste0(v, " : au moins un menage lu"))
  check(all(!is.na(d$hv005)) && all(d$hv005 >= 0), paste0(v, " : poids hv005 present et positif"))
  check(all(!is.na(d$hv001)), paste0(v, " : grappe hv001 presente partout"))
  check(all(d$hv025 %in% c(1, 2)), paste0(v, " : hv025 dans {1, 2}"))
}

# ===========================================================================
# Classification
# ===========================================================================
# ===========================================================================
# Distribution brute de hv201 (audit de la table de correspondance)
# ===========================================================================
# Avant toute recodification (99 encore visible). Un code observe absent de
# code/ref/35_hv201_classes.csv ressort en dans_table = FALSE et en
# avertissement, au lieu d'etre absorbe.
hr("35c bis. Distribution brute de hv201, code par code")

dist_hv201 <- rbindlist(lapply(names(men), function(v) {
  d <- men[[v]]
  t <- d[, .(n = .N, pct = 100 * sum(hv005 / 1e6)), by = hv201]
  t[, pct := pct / sum(d$hv005 / 1e6)]
  t[, vague := v]
  t
}))
dist_hv201 <- merge(dist_hv201,
                    ent$codes[variable == "hv201", .(vague, hv201 = code, etiquette_dta = etiquette)],
                    by = c("vague", "hv201"), all.x = TRUE)
dist_hv201[, dans_table := paste(vague, hv201) %in% REF[, paste(vague, hv201)]]
dist_hv201[is.na(etiquette_dta), etiquette_dta := fifelse(is.na(hv201), "(manquant NA)", "(non etiquete)")]
setcolorder(dist_hv201, c("vague", "hv201", "etiquette_dta", "dans_table", "n", "pct"))
setorderv(dist_hv201, c("vague", "hv201"), na.last = TRUE)

op <- options(width = 200); print(dist_hv201, nrows = 200); options(op)
fwrite(dist_hv201, p_tab("35_nfhs_distribution_hv201.csv"))

hors <- dist_hv201[dans_table == FALSE]
for (i in seq_len(nrow(hors)))
  warn(hors$vague[i], " : hv201 = ", hors$hv201[i], " ", hors$etiquette_dta[i],
       " ABSENT de la table de correspondance -- ", hors$n[i], " menages, ",
       sprintf("%.3f", hors$pct[i]), " %")
# rupture de serie NFHS-5 : poids de "piped to neighbor"
p13 <- dist_hv201[vague == "nfhs5" & hv201 == 13, pct]
note("NFHS-5 : hv201 = 13 piped to neighbor (code absent avant) : ",
     sprintf("%.2f", if (length(p13)) p13 else 0), " % des menages")

hr("35d. Classification hv201 x hv235")

for (v in names(men)) {
  d <- copy(men[[v]])   # relu d'un .rds : copie pour que := ne realloque pas en silence
  ref_v <- REF[vague == v]
  dep_loc <- ref_v[loc_1_2 != loc_3 | loc_1_2 != loc_na, hv201]
  if (!"hv235" %in% names(d)) {
    check(length(dep_loc) == 0L,
          paste0(v, " : hv235 absent et aucune classe n'en depend dans la table"),
          paste("codes dependants :", paste(dep_loc, collapse = ", ")))
    d[, hv235 := NA_real_]
  }
  # 99 = manquant DHS, non etiquete dans les .DTA (9 menages en NFHS-3) :
  # traite comme hv201 manquant, donc classe "manquant", au denominateur.
  n99 <- sum(d$hv201 %in% 99)
  if (n99) {
    note(v, " : hv201 == 99 (manquant DHS) -> NA, ", n99, " menages")
    d[hv201 %in% 99, hv201 := NA_real_]
  }
  inconnus <- setdiff(unique(d$hv201[!is.na(d$hv201)]), ref_v$hv201)
  check(length(inconnus) == 0L, paste0(v, " : tout code hv201 observe est dans la table"),
        paste("absents de la table :", paste(inconnus, collapse = ", ")))

  d[ref_v, on = "hv201", `:=`(l12 = i.loc_1_2, l3 = i.loc_3, lna = i.loc_na)]
  d[, classe := fcase(is.na(hv201),      "manquant",
                      hv235 %in% c(1, 2), l12,
                      hv235 %in% 3,       l3,
                      rep(TRUE, .N),      lna)]
  d[, c("l12", "l3", "lna") := NULL]
  d[, w := hv005 / 1e6]
  check(all(!is.na(d$classe)), paste0(v, " : chaque menage a une classe"))

  # localisation des sources souterraines, non pondere : combien tombent
  # hors {1, 2, 3} et donc en souterrain_loc_inconnue
  if (length(dep_loc)) {
    msg(""); msg(v, " : hv235 parmi les sources souterraines (", paste(dep_loc, collapse = ", "), "), non pondere")
    print(d[hv201 %in% dep_loc, .N, by = .(hv201, hv235)][order(hv201, hv235)])
  }
  men[[v]] <- d
}

# ===========================================================================
# Parts ponderees
# ===========================================================================
hr("35e. Parts ponderees des classes")

# Classes en colonnes, ordre fixe. Une classe absente de la nomenclature d'une
# vague sort NA (non posee), pas zero.
parts_classes <- function(by = NULL) {
  rbindlist(lapply(names(men), function(v) {
    d <- men[[v]]
    if (!all(by %in% names(d))) return(NULL)
    tot <- d[, .(n = .N, menages_ponderes = sum(w)), by = c("vague", by)]
    cl  <- d[, .(p = sum(w)), by = c("vague", by, "classe")]
    cl[, p := 100 * p / sum(p), by = c("vague", by)]
    poses <- unique(c(unlist(REF[vague == v, .(loc_1_2, loc_3, loc_na)]), "manquant"))
    wide <- dcast(cl, as.formula(paste(paste(c("vague", by), collapse = " + "), "~ classe")),
                  value.var = "p", fill = 0)
    for (k in setdiff(poses, names(wide))) set(wide, j = k, value = 0)
    merge(tot, wide, by = c("vague", by))
  }), fill = TRUE)
}
ordonne <- function(t, by) {
  setcolorder(t, c("vague", by, "n", "menages_ponderes", intersect(CLASSES, names(t))))
  setorderv(t, c("vague", by))
  t
}

tab_vague    <- ordonne(parts_classes(),                    character())
tab_quintile <- ordonne(parts_classes("hv270"),             "hv270")
tab_secteur  <- ordonne(parts_classes("hv025"),             "hv025")
tab_etat     <- ordonne(parts_classes(c("hv024", "etat_nom")), c("hv024", "etat_nom"))

op <- options(width = 250)
msg(""); msg("Par vague (% des menages)"); print(tab_vague)
msg(""); msg("Par quintile hv270 (1 = plus pauvre, 5 = plus riche)"); print(tab_quintile)
msg(""); msg("Par secteur hv025 (1 = urbain, 2 = rural)"); print(tab_secteur)
msg(""); msg("Par Etat hv024 : ", nrow(tab_etat), " lignes, voir output/tables/35_nfhs_classes_par_etat.csv")
options(op)

fwrite(tab_vague,    p_tab("35_nfhs_classes_par_vague.csv"))
fwrite(tab_quintile, p_tab("35_nfhs_classes_par_quintile.csv"))
fwrite(tab_secteur,  p_tab("35_nfhs_classes_par_secteur.csv"))
fwrite(tab_etat,     p_tab("35_nfhs_classes_par_etat.csv"))

# ===========================================================================
# Validation de la reconstruction par hv235 (NFHS-2)
# ===========================================================================
hr("35f. Validation : classement natif NFHS-2 x hv235")

d2 <- men[["nfhs2"]]
if (all(is.na(d2$hv235))) {
  warn("NFHS-2 : hv235 ABSENT (entetes .DTA et .MAP). Constat definitif : la matrice de ",
       "confusion natif x localisation ne sera jamais produite a partir du NFHS.")
  warn("La distinction prive/partage par hv235 (NFHS-3, 4, 5) n'est pas validable dans cette ",
       "source. Le codage natif de NFHS-2 est de plus ambigu : 'handpump in residence/yard/plot' ",
       "nomme un lieu, 'public handpump' un statut ; une pompe publique dans une cour satisfait ",
       "les deux. souterrain_prive mesure une localisation, pas une propriete.")
} else {
  conf <- d2[classe %in% c("souterrain_prive", "souterrain_partage", "souterrain_indetermine"),
             .(n = .N, poids = sum(w)), by = .(natif = classe, hv235)]
  conf[, pct_du_natif := 100 * poids / sum(poids), by = natif]
  setorder(conf, natif, hv235)
  print(conf)
  fwrite(conf, p_tab("35_nfhs2_confusion_natif_hv235.csv"))
}

# ===========================================================================
# Pompe a eau
# ===========================================================================
hr("35g. Pompe a eau (par quintile, et par classe de source)")

for (v in names(men)) {
  msg(v, " : valeurs brutes de la pompe")
  print(men[[v]][, .N, by = pompe][order(pompe)])
}
part_pompe <- function(by) {
  rbindlist(lapply(names(men), function(v) {
    d <- men[[v]]
    if (!all(by %in% names(d))) return(NULL)
    d[, .(n = .N, menages_ponderes = sum(w), pompe_inconnue = sum(!pompe %in% c(0, 1)),
          pct_pompe = 100 * sum(w * (pompe %in% 1)) / sum(w)),
      by = c("vague", by)]
  }))
}
pompe_quintile <- setorderv(part_pompe("hv270"),  c("vague", "hv270"))
# La reserve de l'en-tete : la pompe ne se lit que croisee avec la source.
pompe_classe   <- part_pompe("classe")
pompe_classe[, classe := factor(classe, levels = CLASSES)]
setorderv(pompe_classe, c("vague", "classe"))

op <- options(width = 200)
msg(""); msg("Part de menages avec pompe, par quintile (%)"); print(pompe_quintile)
msg(""); msg("Part de menages avec pompe, par classe de source (%)"); print(pompe_classe)
options(op)
fwrite(pompe_quintile, p_tab("35_nfhs_pompe_par_quintile.csv"))
fwrite(pompe_classe,   p_tab("35_nfhs_pompe_par_classe.csv"))

# ===========================================================================
# Controle dur contre le rapport NFHS-3
# ===========================================================================
# Rapport final NFHS-3, vol. 1, tableau 2.11, p. 35. Parts de menages par code
# hv201, total / urbain / rural. Tolerance 0.05 point (arrondi au dixieme),
# ligne par ligne : on ne compare jamais une SOMME de lignes publiees, dont
# l'incertitude d'arrondi serait de +/- 0.10. L'eau embouteillee est donc
# controlee sur ses deux lignes publiees, decoupees par hv202 (voir en-tete
# pour la liste "amelioree"). Les effectifs ponderes fixent le codage de hv025.
hr("35h. Controle pondere, NFHS-3 contre le rapport (tableau 2.11)")

# hv202 : constate vague par vague dans les donnees (les .MAP de NFHS-2, 4 et 5
# le libellent "NA - Source of non-drinking water").
msg("hv202 (source d'eau non potable) par vague : non manquants, et parmi hv201 == 71")
for (v in names(men)) {
  d <- men[[v]]
  if (!"hv202" %in% names(d)) { note(v, " : hv202 absent du fichier"); next }
  note(v, " : libelle '", ent$vars[vague == v & variable == "hv202", libelle], "' ; non NA ",
       format(sum(!is.na(d$hv202)), big.mark = " "), " / ", format(nrow(d), big.mark = " "),
       " ; parmi embouteille ", sum(!is.na(d$hv202[d$hv201 %in% 71])), " / ", sum(d$hv201 %in% 71))
}
check("hv202" %in% names(men[["nfhs3"]]) && all(!is.na(men[["nfhs3"]][hv201 %in% 71, hv202])),
      "NFHS-3 : hv202 renseigne pour tous les menages a eau embouteillee")

# Liste "amelioree" de hv202 (JMP OMS/UNICEF, reprise par le Guide to DHS
# Statistics) : tout code hors liste, y compris 99 manquant, est non ameliore.
HV202_AMELIORE <- c(11, 12, 13, 21, 31, 41, 51)

PUBLIE_NFHS3 <- rbindlist(list(
  list("11+12 reseau logement/parcelle", "11,12", "",            24.5, 50.7, 11.8),
  list("13 borne-fontaine",              "13",    "",            17.5, 20.3, 16.1),
  list("21 puits tube ou forage",        "21",    "",            42.8, 21.3, 53.2),
  list("31 puits protege",               "31",    "",             2.5,  1.8,  2.8),
  list("32 puits non protege",           "32",    "",             9.3,  2.9, 12.4),
  list("41 source protegee",             "41",    "",             0.2,  0.1,  0.3),
  list("42 source non protegee",         "42",    "",             0.6,  0.1,  0.8),
  list("43 eau de surface",              "43",    "",             1.5,  0.8,  1.8),
  list("51 eau de pluie",                "51",    "",             0.1,  0.0,  0.2),
  list("61+62 camion ou charrette",      "61,62", "",             0.5,  0.9,  0.3),
  # "Bottled water, improved source for cooking, handwashing"
  list("71 embouteillee, hv202 ameliore",     "71", "ameliore",     0.3,  0.8,  0.1),
  # "Bottled water, non-improved source for cooking, handwashing"
  list("71 embouteillee, hv202 non ameliore", "71", "non_ameliore", 0.0,  0.1,  0.0),
  list("96 autre",                       "96",    "",             0.2,  0.2,  0.1)))
setnames(PUBLIE_NFHS3, c("ligne", "codes", "hv202", "total", "urbain", "rural"))
EFFECTIFS_NFHS3 <- c(total = 109041, urbain = 35579, rural = 73462)
TOL_PART <- 0.05
TOL_EFF  <- 1

d3 <- men[["nfhs3"]]
sous3 <- list(total = d3, urbain = d3[hv025 == 1], rural = d3[hv025 == 2])

for (s in names(EFFECTIFS_NFHS3)) {
  o <- sum(sous3[[s]]$w)
  check(abs(o - EFFECTIFS_NFHS3[[s]]) <= TOL_EFF,
        sprintf("NFHS-3 : menages ponderes %s == %s (a %d pres)", s,
                format(EFFECTIFS_NFHS3[[s]], big.mark = " "), TOL_EFF),
        sprintf("attendu %s, observe %.2f", format(EFFECTIFS_NFHS3[[s]], big.mark = " "), o))
}

for (i in seq_len(nrow(PUBLIE_NFHS3))) {
  cds <- as.numeric(strsplit(PUBLIE_NFHS3$codes[i], ",")[[1]])
  for (s in names(sous3)) {
    d   <- sous3[[s]]
    att <- PUBLIE_NFHS3[[s]][i]
    sel <- d$hv201 %in% cds
    sel <- switch(PUBLIE_NFHS3$hv202[i],
                  ameliore     = sel &  (d$hv202 %in% HV202_AMELIORE),
                  non_ameliore = sel & !(d$hv202 %in% HV202_AMELIORE),
                  sel)
    o   <- 100 * sum(d$w[sel]) / sum(d$w)
    check(abs(o - att) <= TOL_PART,
          sprintf("NFHS-3 : hv201 %s, %s == %.1f (tol. %.2f)", PUBLIE_NFHS3$ligne[i], s, att, TOL_PART),
          sprintf("hv201 %s %s : attendu %.1f, observe %.4f, ecart %.4f",
                  PUBLIE_NFHS3$codes[i], s, att, o, o - att))
  }
}

# Variante informative, sans arret : hv202 = 99 traite comme manquant (exclu
# des deux lignes embouteillees) au lieu de non ameliore.
msg(""); msg("Sensibilite (informative) : eau embouteillee non amelioree, 99 = manquant")
i_na <- which(PUBLIE_NFHS3$hv202 == "non_ameliore")
for (s in names(sous3)) {
  d   <- sous3[[s]]
  att <- PUBLIE_NFHS3[[s]][i_na]
  o   <- 100 * sum(d$w[d$hv201 %in% 71 & !(d$hv202 %in% c(HV202_AMELIORE, 99))]) / sum(d$w)
  note(sprintf("%-6s : attendu %.1f, observe %.4f, ecart %.4f -> %s", s, att, o, o - att,
               if (abs(o - att) <= TOL_PART) "passerait" else "ECHOUERAIT"))
}

msg(""); msg("Termine. Tables dans output/tables/35_*.csv")
log_close()
