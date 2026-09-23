# ---------------------------------------------------------------------------
# 09_geology_by_state.R -- quels Etats ont une variation geologique
#   exploitable, et des puits CGWB pour l'observer ?
#
# Piste A (instrument geologique) : choix de la zone d'etude sur des chiffres,
# pas sur le code deja ecrit pour l'UP. AUCUNE regression, AUCUNE variable de
# resultat : seulement la geologie, les districts et la position des puits.
#
# SOURCE GEOLOGIQUE : carte geologique GSI au 1:2M (NGDR), copie republiee en
# GeoParquet (raw/geology/ngdr/, voir raw/README.md). C'est une carte
# STRATIGRAPHIQUE : elle ne porte ni type de roche ni classe d'aquifere. On
# travaille donc avec les champs tels quels, sans recodage a la main :
#   unit       = index_      unite stratigraphique (504 valeurs)
#   age        = age         age geologique (72 valeurs)
#   supergroup = supergroup  super-groupe (18 valeurs ; vide -> "(aucun)")
# plus UNE classe par regle : quat = (age == "QUATERNARY"), c.-a-d. sediments
# non consolides (alluvions) contre roches plus anciennes. Age absent ou
# "UNMAPPED" -> quat = NA, compte a part.
# La couche des aquiferes principaux CGWB (India-WRIS) n'est pas joignable
# depuis cette machine : elle manque ici, voir le log.
#
# AIRES : grille de points de 5 km dans une projection EQUIVALENTE (LAEA
# centree sur l'Inde). EPSG:7755 est conforme et deforme les aires de -4 % a
# +4 % selon la latitude (tmp_crs/, 23/09), ce qui biaiserait les densites
# comparees entre Etats. Chaque point pese 25 km2.
#
# LANCEMENT (racine du depot, dans un terminal) :
#     Rscript code/09_geology_by_state.R           # reprend ou il s'etait arrete
#     Rscript code/09_geology_by_state.R --force   # refait toutes les etapes
#
# ETAPES RESUMABLES (build/) :
#   1. 09_geologie_2m_laea.gpkg  couche geologique reparee, en LAEA
#   2. 09_grille5km.rds          points de grille -> district + geologie
#   3. 09_puits_geo.rds          puits CGWB -> district + geologie
# Les tableaux finaux sont toujours recalcules (quelques secondes).
#
# Sorties : output/tables/09_*.csv, output/logs/09_geology_by_state.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(sf)
  library(arrow)
}))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("09_geology_by_state.log"))

LAEA  <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"
CELL  <- 5000                       # pas de grille, m
KM2_PT <- (CELL / 1000)^2           # aire representee par un point, km2
MIX   <- 0.10                       # district "mixte" : Q et non-Q >= 10 % chacun

f_src  <- p_raw("geology", "ngdr", "NGDR_Geology_2M.parquet")
f_dist <- p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg")

msg("ETAPE 9 -- VARIATION GEOLOGIQUE ET PUITS CGWB, PAR ETAT")
msg("")
msg("Aucune regression, aucune variable de resultat. Geologie + puits seulement.")
msg("La couche des aquiferes principaux CGWB (India-WRIS) n'est PAS utilisee :")
msg("le serveur arc.indiawris.gov.in ne repond pas depuis cette machine (connexion")
msg("TCP expiree le 2026-09-23). Seule la carte geologique GSI 1:2M est lue.")

# ===========================================================================
# Etape 1 : couche geologique
# ===========================================================================
hr("9a. Carte geologique GSI 1:2M (etape 1)")

check(file.exists(f_src), paste0("source presente : ", f_src))
f_geo <- p_build("09_geologie_2m_laea.gpkg")
geo <- stage("etape 1/3 geologie", f_geo, function() {
  p <- as.data.frame(arrow::read_parquet(
    f_src, col_select = c("index_", "age", "supergroup", "geometry")))
  g <- sf::st_sf(unit = p$index_, age = p$age, supergroup = p$supergroup,
                 geometry = sf::st_as_sfc(structure(lapply(p$geometry, as.raw),
                                                    class = "WKB"), crs = 4326))
  tmsg("    ", nrow(g), " polygones lus ; invalides avant reparation : ",
       sum(!sf::st_is_valid(g)))
  sf::st_make_valid(sf::st_transform(g, LAEA))
})

check(nrow(geo) == 4531L, "geologie : 4 531 polygones",
      sprintf("observe %d", nrow(geo)))
check(all(sf::st_is_valid(geo)), "geologie : toutes les geometries valides apres reparation")
geo_km2 <- sum(as.numeric(sf::st_area(geo))) / 1e6
msg(sprintf("  aire totale : %s km2 (Inde : ~3 287 000 km2)",
            format(round(geo_km2), big.mark = " ")))
check(abs(geo_km2 / 3287000 - 1) < 0.03, "geologie : aire totale a +/-3 % de celle de l'Inde")

geo$supergroup[is.na(geo$supergroup) | geo$supergroup == ""] <- "(aucun)"
geo$age[is.na(geo$age) | geo$age == ""] <- "(absent)"
geo$quat <- ifelse(geo$age %in% c("(absent)", "UNMAPPED", "Unmapped Area"), NA,
                   geo$age == "QUATERNARY")
msg(sprintf("  unites : %d ; ages : %d ; super-groupes : %d (dont '(aucun)')",
            length(unique(geo$unit)), length(unique(geo$age)),
            length(unique(geo$supergroup))))

# ===========================================================================
# Etape 2 : grille de 5 km -> district + geologie
# ===========================================================================
hr("9b. Grille de 5 km (etape 2)")

read_districts <- function() {
  d <- sf::st_read(f_dist, quiet = TRUE)
  sf::st_make_valid(sf::st_transform(d[, c("pc11_state_id", "pc11_district_id")], LAEA))
}

# Rattache chaque point a au plus un polygone : un point sur une frontiere
# partagee peut en toucher deux ; on garde le premier et on compte les cas.
join_first <- function(pts, polys, id, label) {
  j <- sf::st_join(pts, polys, join = sf::st_intersects, left = TRUE)
  n_dup <- sum(duplicated(j[[id]]))
  tmsg("    ", label, " : ", n_dup, " point(s) sur une frontiere, premier polygone garde")
  j[!duplicated(j[[id]]), ]
}

f_grid <- p_build("09_grille5km.rds")
grid <- stage("etape 2/3 grille 5 km", f_grid, function() {
  dist <- read_districts()
  pts <- sf::st_sf(geometry = sf::st_make_grid(dist, cellsize = CELL, what = "centers"))
  pts$pid <- seq_len(nrow(pts))
  tmsg("    ", format(nrow(pts), big.mark = ","), " points dans l'emprise ; rattachement aux districts ...")
  pts <- join_first(pts, dist, "pid", "districts")
  pts <- pts[!is.na(pts$pc11_district_id), ]
  tmsg("    ", format(nrow(pts), big.mark = ","), " points dans un district ; rattachement a la geologie ...")
  pts <- join_first(pts, geo[, c("unit", "age", "supergroup", "quat")], "pid", "geologie")
  xy <- sf::st_coordinates(pts)
  data.table(pid = pts$pid, x = xy[, 1], y = xy[, 2],
             pc11_state_id = pts$pc11_state_id, pc11_district_id = pts$pc11_district_id,
             unit = pts$unit, age = pts$age, supergroup = pts$supergroup, quat = pts$quat)
}, after = f_geo)

msg(sprintf("  points dans un district : %s, soit %s km2",
            format(nrow(grid), big.mark = ","), format(nrow(grid) * KM2_PT, big.mark = " ")))
check(abs(nrow(grid) * KM2_PT / 3287000 - 1) < 0.05,
      "grille : aire couverte a +/-5 % de celle de l'Inde")
msg(sprintf("  points hors de toute unite geologique : %s (%.2f %%)",
            format(grid[is.na(unit), .N], big.mark = ","), 100 * grid[, mean(is.na(unit))]))
msg(sprintf("  points a age absent ou non cartographie (quat = NA) : %s",
            format(grid[is.na(quat), .N], big.mark = ",")))

# ===========================================================================
# Etape 3 : puits CGWB -> district + geologie
# ===========================================================================
hr("9c. Puits CGWB (etape 3)")

f_wells <- p_build("09_puits_geo.rds")
wells <- stage("etape 3/3 puits", f_wells, function() {
  w <- as.data.table(readRDS(p_build("cgwb_wells.rds")))
  w <- w[!is.na(LAT) & !is.na(LON) & LAT %between% c(6, 38) & LON %between% c(67, 98)]
  s <- sf::st_transform(sf::st_as_sf(w, coords = c("LON", "LAT"), crs = 4326, remove = FALSE), LAEA)
  s <- join_first(s, read_districts(), "WLCODE", "districts")
  s <- join_first(s, geo[, c("unit", "age", "supergroup", "quat")], "WLCODE", "geologie")
  as.data.table(sf::st_drop_geometry(s))
}, after = f_geo)

n_raw <- nrow(readRDS(p_build("cgwb_wells.rds")))
check(n_raw == 28076L, "puits CGWB : 28 076 dans build/cgwb_wells.rds")
check(sum(duplicated(wells$WLCODE)) == 0, "puits : un seul rattachement par WLCODE")
msg(sprintf("  puits a coordonnees valides : %s ; ecartes (coordonnees) : %d",
            format(nrow(wells), big.mark = ","), n_raw - nrow(wells)))
msg(sprintf("  puits hors de tout district pc11 : %d (exclus des tableaux par Etat)",
            wells[is.na(pc11_district_id), .N]))
msg(sprintf("  puits hors de toute unite geologique : %d", wells[is.na(unit), .N]))
wells <- wells[!is.na(pc11_district_id)]
wells[, may_any  := has_any_may %in% TRUE]
wells[, may_9600 := earliest_may_le_2000 %in% TRUE]
msg(sprintf("  dont avec au moins une lecture de mai : %s ; premiere lecture de mai <= 2000 : %s",
            format(wells[may_any == TRUE, .N], big.mark = ","),
            format(wells[may_9600 == TRUE, .N], big.mark = ",")))

# ===========================================================================
# Tableaux
# ===========================================================================
hr("9d. Noms d'Etat")

# Nom modal par pc11_state_id, depuis les cles SHRUG (aucun nom saisi a la main).
k11 <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-pc-keys-dta", "pc11r_shrid_key.dta")))
loc <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-shrid-keys-dta", "shrid_loc_names.dta")))
st_names <- merge(k11[, .(shrid2, pc11_state_id)], loc[, .(shrid2, state_name)], by = "shrid2")
st_names <- st_names[state_name != "", .N, by = .(pc11_state_id, state_name)][
  order(pc11_state_id, -N)][!duplicated(pc11_state_id), .(pc11_state_id, state_name)]
msg("  Etats nommes : ", nrow(st_names))

gini_simpson <- function(x) { p <- table(x) / length(x); 1 - sum(p^2) }

hr("9e. Variation geologique au sein des districts (aires, grille)")

g <- grid[!is.na(unit)]
dist_tab <- g[, .(
  area_km2   = .N * KM2_PT,
  n_units    = uniqueN(unit),
  gs_unit    = gini_simpson(unit),
  share_quat = mean(quat, na.rm = TRUE)
), by = .(pc11_state_id, pc11_district_id)]
dist_tab[, mixed_q := share_quat >= MIX & share_quat <= 1 - MIX]
fwrite(dist_tab, p_tab("09_districts_geologie.csv"))
msg("  ", nrow(dist_tab), " districts ; ecrit : 09_districts_geologie.csv")

hr("9f. Tableau par Etat")

st_area <- g[, .(
  area_km2        = .N * KM2_PT,
  n_units         = uniqueN(unit),
  n_units_1pct    = sum(table(unit) / .N >= 0.01),
  n_ages          = uniqueN(age),
  n_supergroups   = uniqueN(supergroup[supergroup != "(aucun)"]),
  share_area_quat = mean(quat, na.rm = TRUE)
), by = pc11_state_id]

st_dist <- dist_tab[, .(
  n_districts          = .N,
  mean_gs_unit_dist    = mean(gs_unit),
  share_dist_mixed_q   = mean(mixed_q, na.rm = TRUE)
), by = pc11_state_id]

wu <- wells[may_any == TRUE & !is.na(unit)]
st_wells <- wells[, .(n_wells = .N, n_wells_may = sum(may_any),
                      n_wells_may9600 = sum(may_9600)), by = pc11_state_id]
st_wgeo <- wu[, .(
  share_wells_quat   = mean(quat, na.rm = TRUE),
  n_wells_nonquat    = sum(quat %in% FALSE),
  eff_units_wells    = 1 / sum((table(unit) / .N)^2),
  top_unit_share     = max(table(unit)) / .N
), by = pc11_state_id]

# Puits dans un contraste INTRA-district (ce qui reste avec des effets fixes
# de district) :
#   contrast_q    = somme sur les districts de min(n Quaternaire, n non-Quat.)
#   contrast_unit = somme sur les districts de (n - n de l'unite modale)
wd <- wu[, .(n = .N, nq = sum(quat %in% TRUE), nnq = sum(quat %in% FALSE),
             nmod = max(table(unit))), by = .(pc11_state_id, pc11_district_id)]
st_contrast <- wd[, .(contrast_q_wells    = sum(pmin(nq, nnq)),
                      contrast_unit_wells = sum(n - nmod)), by = pc11_state_id]

tab <- Reduce(function(a, b) merge(a, b, by = "pc11_state_id", all = TRUE),
              list(st_names, st_area, st_dist, st_wells, st_wgeo, st_contrast))
for (v in c("n_wells", "n_wells_may", "n_wells_may9600", "n_wells_nonquat",
            "contrast_q_wells", "contrast_unit_wells"))
  set(tab, which(is.na(tab[[v]])), v, 0L)
tab[, wells_per_1000km2       := 1000 * n_wells / area_km2]
tab[, wells_may_per_1000km2   := 1000 * n_wells_may / area_km2]
setorder(tab, -contrast_q_wells)
fwrite(tab, p_tab("09_etats_geologie_puits.csv"))

show <- tab[area_km2 >= 5000, .(
  etat = substr(state_name, 1, 16), id = pc11_state_id,
  km2 = round(area_km2 / 1000), dist = n_districts,
  units = n_units, u1pct = n_units_1pct, sgrp = n_supergroups,
  quat_aire = round(share_area_quat, 2),
  gs_dist = round(mean_gs_unit_dist, 2), dist_mixtes = round(share_dist_mixed_q, 2),
  puits = n_wells, p_mai = n_wells_may, p_9600 = n_wells_may9600,
  dens = round(wells_may_per_1000km2, 1),
  quat_puits = round(share_wells_quat, 2), eff_u = round(eff_units_wells, 1),
  ctr_q = contrast_q_wells, ctr_u = contrast_unit_wells)]
msg("  Etats de plus de 5 000 km2, tries par ctr_q (decroissant).")
msg("  km2 en milliers ; dens = puits avec une lecture de mai / 1 000 km2 ;")
msg("  gs_dist = moyenne sur les districts de l'indice de Gini-Simpson des unites")
msg("  (0 = une seule unite, ->1 = tres fragmente) ; dist_mixtes = part des")
msg("  districts ou Quaternaire et non-Quaternaire couvrent chacun >= 10 % ;")
msg("  ctr_q / ctr_u = puits dans un contraste intra-district (voir le code).")
msg("")
op <- options(width = 250)
print(show, nrows = 100)
options(op)
msg("")
msg("  Tableau complet (tous les Etats, sans arrondi) : 09_etats_geologie_puits.csv")

# Parts detaillees, pour aller voir un Etat en particulier.
wsu <- wu[, .N, by = .(pc11_state_id, unit, age, quat)][
  , share := N / sum(N), by = pc11_state_id][order(pc11_state_id, -N)]
wsu <- merge(st_names, wsu, by = "pc11_state_id", all.y = TRUE)
fwrite(wsu, p_tab("09_puits_par_etat_unite.csv"))
asu <- g[, .(km2 = .N * KM2_PT), by = .(pc11_state_id, unit, age, quat)][
  , share := km2 / sum(km2), by = pc11_state_id][order(pc11_state_id, -km2)]
asu <- merge(st_names, asu, by = "pc11_state_id", all.y = TRUE)
fwrite(asu, p_tab("09_aire_par_etat_unite.csv"))
msg("  Parts par unite : 09_puits_par_etat_unite.csv, 09_aire_par_etat_unite.csv")

hr("RAPPEL DE PORTEE")
msg("Geologie et position des puits seulement. Aucune profondeur regressee,")
msg("aucune variable de resultat lue.")

hr("ETAPE 9 TERMINEE")
for (f in sort(list.files(p_tab(), pattern = "^09"))) msg("  ", f)
log_close()
