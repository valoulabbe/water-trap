# ---------------------------------------------------------------------------
# 08_wells_in_villages.R -- combien de villages d'Uttar Pradesh contiennent un
#   puits d'observation CGWB, et combien sont proches du seuil de 8 m ?
#
# Methode, d'apres Boudot-Reddy & Butler (WBER 2025) : un puits est rattache a
# un village SEULEMENT s'il tombe a l'interieur du polygone du village
# (st_within). AUCUNE interpolation. Profondeur du village = maximum sur la
# fenetre temporelle par puits, puis moyenne entre les puits du meme village.
#
# LIMITES DE PORTEE (inchangees depuis l'etape 6) :
#   * AUCUNE RD n'est estimee.
#   * AUCUNE variable de resultat "eau" n'est lue.
#   * Aucune profondeur n'est predite : on ne fait qu'un rattachement spatial
#     exact, puis une agregation temporelle.
#
# DEUX MESURES EN PARALLELE, pour chaque fenetre :
#   max4q : maximum sur les 4 trimestres de la fenetre
#   may   : maximum sur les seules lectures de mai (pre-mousson, CLAUDE.md)
# Les memes statistiques sont sorties cote a cote pour les deux.
#
# FENETRES :
#   1998-2000 : la fenetre principale demandee
#   1996-1998 : REMPLACE la fenetre 1990-1993 initialement voulue. Voir le bloc
#               "PORTEE TEMPORELLE" en tete de log : 1990-1993 est hors de
#               portee de cette source.
#
# LANCEMENT (depuis la racine du depot, dans un terminal) :
#     Rscript code/08_wells_in_villages.R            # reprend ou il s'etait arrete
#     Rscript code/08_wells_in_villages.R --force    # refait toutes les etapes
#
# ETAPES RESUMABLES, sorties intermediaires dans build/ :
#   1. build/08_cgwb.rds      CGWB en format long + table des puits
#   2. build/08_up_poly.gpkg  polygones shrid de l'UP (la plus longue, ~1 min)
#   3. build/08_link.rds      puits -> village (st_within)
# Une etape dont la sortie existe est relue, pas refaite ; l'etape 3 est
# refaite si l'etape 1 ou 2 est plus recente. Les tableaux finaux sont
# toujours recalcules (quelques secondes).
#
# Sorties : output/tables/08_*.csv, output/logs/08_wells_in_villages.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(sf)
}))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("08_wells_in_villages.log"))

CRS_WGS   <- 4326L
CUT       <- 8
DEPTH_MIN <- 0      # on garde depth > 0
DEPTH_MAX <- 200    # on garde depth <= 200 m
UP_STATE  <- "09"

msg("ETAPE 8 -- PUITS CGWB A L'INTERIEUR DES POLYGONES DE VILLAGE (UTTAR PRADESH)")
msg("")
msg("Rattachement spatial exact (st_within), aucune interpolation.")
msg("Aucune RD, aucune variable de resultat 'eau' n'est lue.")

# ===========================================================================
# PORTEE TEMPORELLE -- pourquoi 1990-1993 est impossible
# ===========================================================================
hr("PORTEE TEMPORELLE : 1990-1993 EST HORS DE PORTEE")

msg("La fenetre 1990-1993 demandee au depart NE PEUT PAS etre calculee.")
msg("raw/cgwb/CGWB_data_wide.csv COMMENCE EN MAI 1996 : il ne contient aucune")
msg("colonne de mesure anterieure a cette date. C'est verifie par assertion")
msg("plus bas, pas suppose.")
msg("")
msg("Consequence pour le 2e recensement de l'irrigation mineure (MI), dont")
msg("l'annee de reference est 1993-94 : cette source ne peut PAS fournir une")
msg("profondeur contemporaine de ce recensement. Elle commence environ trois")
msg("ans trop tard. Couvrir 1993-94 exigerait les ANNUAIRES PAPIER de la CGWB,")
msg("donc une numerisation -- item de Phase 1 selon PHASE0_SPEC.md 3.2, hors")
msg("de ce qui est realisable ici.")
msg("")
msg("La fenetre 1996-1998 est utilisee A LA PLACE : c'est la fenetre de trois")
msg("ans la plus precoce que la source permette. Elle ne couvre PAS le 2e")
msg("recensement MI et ne doit pas etre presentee comme telle.")

# ===========================================================================
# 8a. Lecture et mise en forme longue du fichier CGWB
# ===========================================================================
hr("8a. Fichier CGWB (etape 1 : build/08_cgwb.rds)")

# Etapes resumables (voir stage() dans 00_utils.R) : chaque sortie est ecrite
# dans build/08_*.{rds,gpkg} des qu'elle existe ; une relance saute les
# etapes deja faites. --force refait tout.
# Les controles de validite portent sur la SORTIE de l'etape, pour tourner
# aussi quand l'etape est relue plutot que refaite.
f_cgwb <- p_build("08_cgwb.rds")
cgwb <- stage("etape 1/3 CGWB -> format long", f_cgwb, function() {
  cg <- fread(p_raw("cgwb", "CGWB_data_wide.csv"))
  if ("V1" %in% names(cg)) cg[, V1 := NULL]   # 1re colonne du CSV : index sans nom
  meas <- grep("^(Jan|May|Aug|Nov) [0-9]{4}$", names(cg), value = TRUE)
  long <- melt(cg, id.vars = c("WLCODE", "STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE"),
               measure.vars = meas, variable.name = "col", value.name = "depth",
               variable.factor = FALSE)
  long[, month := sub(" .*$", "", col)]
  long[, year  := as.integer(sub("^\\S+ ", "", col))]
  long[, col := NULL]
  list(n_rows = nrow(cg), cols = names(cg), meas = meas,
       dup_wlcode = sum(duplicated(cg$WLCODE)),
       wells = unique(cg[, .(WLCODE, STATE, DISTRICT, LAT, LON, SITE_TYPE)]),
       long = long[!is.na(depth)])
})

check(cgwb$n_rows == 28076L, "CGWB : 28 076 puits")
check(all(c("STATE", "DISTRICT", "LAT", "LON", "SITE_TYPE", "WLCODE") %in% cgwb$cols),
      "CGWB : colonnes d'identification presentes")
check(cgwb$dup_wlcode == 0, "CGWB : WLCODE unique")
meas <- cgwb$meas
check(length(meas) == 84L, "CGWB : 84 colonnes de mesure trimestrielles",
      sprintf("observe %d", length(meas)))
yrs_all <- as.integer(sub("^\\S+ ", "", meas))
check(min(yrs_all) == 1996L, "CGWB : premiere annee de mesure = 1996",
      sprintf("observe %d", min(yrs_all)))
check(sum(yrs_all <= 1995L) == 0L,
      "CGWB : aucune colonne anterieure a 1996 (confirme que 1990-1993 est impossible)")
msg("  colonnes de mesure : ", meas[1], " ... ", meas[length(meas)])
long <- cgwb$long
msg("  lectures non manquantes : ", format(nrow(long), big.mark = ","))

# ===========================================================================
# 8b. Puits -> sf, filtrage des coordonnees
# ===========================================================================
hr("8b. Puits en objet spatial")

w <- cgwb$wells
bad_coord <- w[is.na(LAT) | is.na(LON) |
                 !(LAT %between% c(6, 38)) | !(LON %between% c(67, 98))]
msg("  puits : ", format(nrow(w), big.mark = ","))
msg("  coordonnees manquantes ou hors bbox Inde : ", nrow(bad_coord))
if (nrow(bad_coord) > 0) {
  print(bad_coord[, .(WLCODE, STATE, DISTRICT, LAT, LON)])
  fwrite(bad_coord, p_tab("08_puits_coord_ecartes.csv"))
}
w <- w[!is.na(LAT) & !is.na(LON) & LAT %between% c(6, 38) & LON %between% c(67, 98)]
w_sf <- sf::st_as_sf(w, coords = c("LON", "LAT"), crs = CRS_WGS, remove = FALSE)
msg("  puits conserves : ", format(nrow(w_sf), big.mark = ","))

# ===========================================================================
# 8c. Polygones shrid de l'Uttar Pradesh
# ===========================================================================
hr("8c. Polygones shrid, Uttar Pradesh")

# pc11_state_id ne figure PAS dans le gpkg : il vient de la cle rurale pc11.
# Le 2e segment de shrid2 porte le code Etat (ex. 11-09-132-00701-108884).
# Source preferee : build/pc11r_shrid_key.rds, une conversion du .dta faite en
# amont. Elle se lit sans haven, dont le chargement est bloque par
# intermittence sur cette machine par une politique de controle d'application.
# Repli sur le .dta via haven seulement si le .rds est absent.
key_src <- read_shrug_key(p_build("pc11r_shrid_key.rds"),
                          p_raw("shrug", "shrug-pc-keys-dta", "pc11r_shrid_key.dta"))
k11 <- key_src$data
if (key_src$source == "rds") {
  msg("  cle pc11 lue depuis la CONVERSION : ", key_src$path)
  msg("  (conversion du .dta d'origine faite en amont ; evite haven, dont le")
  msg("   chargement est bloque par intermittence par la politique de controle")
  msg("   d'application de cette machine)")
} else {
  msg("  cle pc11 lue depuis le .dta D'ORIGINE via haven : ", key_src$path)
  msg("  (build/pc11r_shrid_key.rds absent ; repli utilise)")
}
check(all(c("shrid2", "pc11_state_id") %in% names(k11)),
      "cle pc11 : colonnes shrid2 et pc11_state_id presentes")
check(is.character(k11$shrid2), "cle pc11 : shrid2 est de type caractere")
check(nrow(k11) == 597597L, "cle pc11 : 597 597 lignes",
      sprintf("observe %s", format(nrow(k11), big.mark = ",")))
up_ids <- unique(k11[pc11_state_id == UP_STATE, shrid2])
check(length(up_ids) > 90000L, "UP : plus de 90 000 shrid ruraux dans la cle pc11",
      sprintf("observe %d", length(up_ids)))
msg("  shrid ruraux avec pc11_state_id == '", UP_STATE, "' : ",
    format(length(up_ids), big.mark = ","))

gpkg <- p_raw("shrug", "shrug-shrid-poly-gpkg", "shrid2_open.gpkg")
lyr  <- sf::st_layers(gpkg)
n_feat <- as.integer(lyr$features[match("shrid2", lyr$name)])
check(n_feat == 595438L, "polygones shrid : 595 438 entites")

# Etape 2, la plus longue : lecture par blocs (fichier de 380 Mo), on ne
# conserve que l'UP. Un horodatage par bloc.
f_poly <- p_build("08_up_poly.gpkg")
up_poly <- stage("etape 2/3 polygones UP", f_poly, function() {
  CHUNK <- 25000L
  offs  <- seq(0L, n_feat - 1L, by = CHUNK)
  parts <- vector("list", length(offs))
  for (i in seq_along(offs)) {
    q <- sprintf("SELECT shrid2, geom FROM shrid2 LIMIT %d OFFSET %d", CHUNK, offs[i])
    g <- sf::st_read(gpkg, query = q, quiet = TRUE)
    g <- g[g$shrid2 %in% up_ids, ]
    if (nrow(g) > 0) parts[[i]] <- g
    tmsg("    bloc ", i, "/", length(offs), " : ", nrow(g), " polygones UP")
  }
  p <- do.call(rbind, parts[!vapply(parts, is.null, logical(1))])
  tmsg("    st_make_valid sur ", format(nrow(p), big.mark = ","), " polygones ...")
  sf::st_make_valid(p)
})
msg("  polygones UP recuperes : ", format(nrow(up_poly), big.mark = ","))
check(nrow(up_poly) > 0, "au moins un polygone UP recupere")
msg("  shrid UP sans polygone : ",
    format(length(setdiff(up_ids, up_poly$shrid2)), big.mark = ","))

# ===========================================================================
# 8d. Jointure spatiale : puits A L'INTERIEUR d'un polygone de village
# ===========================================================================
hr("8d. Jointure spatiale st_within")

# Etape 3 : refaite si l'etape 1 ou 2 est plus recente (voir stage()).
link <- stage("etape 3/3 jointure st_within", p_build("08_link.rds"), function() {
  j <- sf::st_join(w_sf, up_poly, join = sf::st_within, left = FALSE)
  as.data.table(sf::st_drop_geometry(j))[, .(WLCODE, shrid2, STATE, SITE_TYPE)]
}, after = c(f_cgwb, f_poly))
check(sum(duplicated(link$WLCODE)) == 0,
      "chaque puits tombe dans au plus un polygone de village",
      sprintf("%d puits rattaches a plusieurs shrid", sum(duplicated(link$WLCODE))))
msg("  puits tombant dans un village d'UP : ", format(nrow(link), big.mark = ","))
msg("  villages d'UP distincts touches    : ",
    format(uniqueN(link$shrid2), big.mark = ","))
msg("")
msg("  Etat CGWB des puits rattaches (un puits peut etre etiquete autrement")
msg("  que 'UP' tout en tombant dans un polygone d'UP) :")
print(link[, .N, by = STATE][order(-N)])

# Distribution du nombre de puits par village, sur le rattachement seul (tous
# les puits rattaches, avec ou sans lecture dans une fenetre donnee).
hr("8d(ii). Puits par village (rattachement seul)")
pv <- link[, .(n_wells = .N), by = shrid2][, .(villages = .N), by = n_wells][order(n_wells)]
print(pv)
fwrite(pv, p_tab("08_puits_par_village_rattachement.csv"))
fwrite(link[order(shrid2, WLCODE)], p_tab("08_rattachement_puits_village.csv"))

# ===========================================================================
# 8e-8h : HERITAGE DU RD A 8 m -- DESACTIVE LE 2026-09-23
# Profondeur de village, comptages dans les bandes de +/-1/3/7 m autour de
# 8 m et test de changement de cote du seuil : construits pour le RD
# abandonne. Code conserve tel quel mais NON EXECUTE. Mettre RD_LEGACY a TRUE
# pour le relancer.
# ===========================================================================
RD_LEGACY <- FALSE
msg("")
msg("8e-8h (profondeur de village, bandes autour de 8 m) : DESACTIVE,")
msg("heritage du RD abandonne. Voir RD_LEGACY dans le script.")
if (RD_LEGACY) {

# ===========================================================================
# 8e. Profondeur du village, par fenetre et par mesure
# ===========================================================================
hr("8e. Profondeur du village")

msg("Regle : max par puits sur la fenetre, puis MOYENNE entre puits du village.")
msg("Lectures ecartees si depth <= ", DEPTH_MIN, " ou > ", DEPTH_MAX, " m.")

lw <- merge(long, link[, .(WLCODE, shrid2)], by = "WLCODE")
out_of_range <- lw[depth <= DEPTH_MIN | depth > DEPTH_MAX]
msg("")
msg("  lectures rattachees a un village : ", format(nrow(lw), big.mark = ","))
msg("  lectures ecartees (hors bornes)  : ", nrow(out_of_range))
if (nrow(out_of_range) > 0) {
  print(head(out_of_range[order(-depth), .(WLCODE, shrid2, year, month, depth)], 20))
  fwrite(out_of_range[, .(WLCODE, shrid2, year, month, depth)],
         p_tab("08_lectures_ecartees.csv"))
}
lw <- lw[depth > DEPTH_MIN & depth <= DEPTH_MAX]

# max par puits sur la fenetre, puis moyenne entre puits du village
village_depth <- function(d, yrs_keep, may_only) {
  x <- d[year %in% yrs_keep]
  if (may_only) x <- x[month == "May"]
  if (nrow(x) == 0L) return(data.table())
  per_well <- x[, .(d_well = max(depth), n_read = .N), by = .(shrid2, WLCODE)]
  per_well[, .(depth = mean(d_well), n_wells = .N, n_read = sum(n_read)), by = shrid2]
}

# idem, mais annee par annee : support du test d'instabilite
village_depth_year <- function(d, yrs_keep, may_only) {
  x <- d[year %in% yrs_keep]
  if (may_only) x <- x[month == "May"]
  if (nrow(x) == 0L) return(data.table())
  per_well <- x[, .(d_well = max(depth)), by = .(shrid2, WLCODE, year)]
  per_well[, .(depth = mean(d_well)), by = .(shrid2, year)]
}

WINDOWS  <- list("1998-2000" = 1998:2000, "1996-1998" = 1996:1998)
MEASURES <- list(max4q = FALSE, may = TRUE)

stats_for <- function(win_name, meas_name) {
  yrs_keep <- WINDOWS[[win_name]]
  may_only <- MEASURES[[meas_name]]
  v  <- village_depth(lw, yrs_keep, may_only)
  vy <- village_depth_year(lw, yrs_keep, may_only)
  if (nrow(v) == 0L)
    return(data.table(fenetre = win_name, mesure = meas_name, villages = 0L))
  fl <- vy[, .(n_years = .N, n_sides = uniqueN(depth > CUT)), by = shrid2]
  fl_multi <- fl[n_years >= 2L]
  data.table(
    fenetre = win_name, mesure = meas_name,
    villages          = nrow(v),
    puits_total       = sum(v$n_wells),
    villages_1_puits  = sum(v$n_wells == 1L),
    villages_2plus    = sum(v$n_wells >= 2L),
    prof_med          = median(v$depth),
    bande_7m          = sum(abs(v$depth - CUT) <= 7),
    bande_3m          = sum(abs(v$depth - CUT) <= 3),
    bande_1m          = sum(abs(v$depth - CUT) <= 1),
    part_au_dessus_8m = mean(v$depth > CUT),
    villages_testables_instab = nrow(fl_multi),
    part_changeant_de_cote = if (nrow(fl_multi) > 0L) mean(fl_multi$n_sides > 1L)
                             else NA_real_)
}

res <- rbindlist(lapply(names(WINDOWS), function(w)
  rbindlist(lapply(names(MEASURES), function(m) stats_for(w, m)), fill = TRUE)),
  fill = TRUE)

hr("8f. Resultats : les deux mesures cote a cote")
print(res[, .(fenetre, mesure, villages, puits_total,
              villages_1_puits, villages_2plus,
              prof_med = round(prof_med, 2),
              bande_7m, bande_3m, bande_1m,
              part_au_dessus_8m = round(part_au_dessus_8m, 4))])
msg("")
msg("  Test d'instabilite (le village change-t-il de cote du seuil de 8 m")
msg("  selon l'annee retenue dans la fenetre ?) :")
print(res[, .(fenetre, mesure, villages_testables_instab,
              part_changeant_de_cote = round(part_changeant_de_cote, 4))])
fwrite(res, p_tab("08_villages_seuil_8m.csv"))

# distribution du nombre de puits par village (fenetre principale, max4q)
v_main <- village_depth(lw, WINDOWS[["1998-2000"]], FALSE)
hr("8g. Distribution du nombre de puits par village (1998-2000, max4q)")
dist_w <- v_main[, .N, by = n_wells][order(n_wells)]
setnames(dist_w, "N", "villages")
print(dist_w)
fwrite(dist_w, p_tab("08_puits_par_village.csv"))
fwrite(v_main[order(shrid2)], p_tab("08_profondeur_village_1998_2000_max4q.csv"))

msg("")
msg("  Pour situer : l'Uttar Pradesh compte ", format(length(up_ids), big.mark = ","),
    " shrid ruraux.")
msg(sprintf("  Couverture : %.2f%% des villages d'UP contiennent un puits.",
            100 * nrow(v_main) / length(up_ids)))

# ===========================================================================
# 8h. Bilan
# ===========================================================================
hr("8h. BILAN")

r1 <- res[fenetre == "1998-2000" & mesure == "max4q"]
r2 <- res[fenetre == "1998-2000" & mesure == "may"]
r3 <- res[fenetre == "1996-1998" & mesure == "max4q"]

msg("COMBIEN DE VILLAGES ?")
msg(sprintf("  1998-2000 : %s villages d'UP contiennent au moins un puits, soit",
            format(r1$villages, big.mark = ",")))
msg(sprintf("  %.2f%% des %s shrid ruraux de l'Etat.",
            100 * r1$villages / length(up_ids), format(length(up_ids), big.mark = ",")))
msg(sprintf("  1996-1998 : %s villages.", format(r3$villages, big.mark = ",")))

msg("")
msg("COMBIEN PRES DU SEUIL ?")
msg(sprintf("  1998-2000, max4q : %s villages a +/-7 m du seuil, %s a +/-3 m,",
            format(r1$bande_7m, big.mark = ","), format(r1$bande_3m, big.mark = ",")))
msg(sprintf("  %s a +/-1 m. Part au-dessus de 8 m : %.1f%%.",
            format(r1$bande_1m, big.mark = ","), 100 * r1$part_au_dessus_8m))

msg("")
msg("MAX 4 TRIMESTRES CONTRE MAI SEUL")
msg(sprintf("  Part au-dessus de 8 m : %.1f%% (max4q) contre %.1f%% (mai seul).",
            100 * r1$part_au_dessus_8m, 100 * r2$part_au_dessus_8m))
msg(sprintf("  Villages a +/-1 m du seuil : %s contre %s.",
            format(r1$bande_1m, big.mark = ","), format(r2$bande_1m, big.mark = ",")))
msg(sprintf("  Villages retenus : %s contre %s.",
            format(r1$villages, big.mark = ","), format(r2$villages, big.mark = ",")))
msg("  Le max sur 4 trimestres retient la lecture la plus profonde de l'annee,")
msg("  qui est le plus souvent pre-moussonnique ; 'mai seul' impose cette")
msg("  lecture. CLAUDE.md impose la mesure pre-mousson : 'mai seul' est donc la")
msg("  variante conforme a la specification, 'max4q' celle de la methode")
msg("  Boudot-Reddy & Butler. L'ecart ci-dessus mesure ce que le choix coute.")

msg("")
msg("INSTABILITE SELON L'ANNEE RETENUE")
msg(sprintf("  1998-2000, max4q : %.1f%% des villages testables changent de cote du",
            100 * r1$part_changeant_de_cote))
msg(sprintf("  seuil selon l'annee retenue (%s villages testables).",
            format(r1$villages_testables_instab, big.mark = ",")))
msg(sprintf("  1998-2000, mai seul : %.1f%%.", 100 * r2$part_changeant_de_cote))
msg("  C'est le test d'instabilite de l'etape 7, refait ici sur une mesure")
msg("  SANS interpolation. L'instabilite qui subsiste vient donc du mouvement")
msg("  reel de la nappe, pas de l'erreur de prediction spatiale.")

}  # fin de if (RD_LEGACY)

hr("RAPPEL DE PORTEE")
msg("Aucune RD, aucune variable de resultat 'eau', aucune interpolation.")
msg("1990-1993 reste hors de portee : voir le bloc en tete de log.")

hr("ETAPE 8 TERMINEE")
msg("Tableaux ecrits dans output/tables/ :")
for (f in sort(list.files(p_tab(), pattern = "^08"))) msg("  ", f)
log_close()
