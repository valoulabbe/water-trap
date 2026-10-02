# ---------------------------------------------------------------------------
# 16_cgwb_profondeur_district.R -- Piste E : profondeur de nappe CGWB agregee
#   au district PC11 (moyenne, min, max, mediane entre puits + nombre de puits).
#   Mesure d'exposition du plan Badiani & Jessoe (panel de districts).
#
# PORTEE : DESCRIPTIF. Aucune variable de resultat, aucune regression.
#
# CONSTRUCTION (fixee avant execution)
#   Lectures : pre-mousson (mai), build/cgwb_may_long.rds (etape 03).
#   Fenetres : "base_1996_2000" (la plus ancienne disponible, aucune lecture
#     CGWB avant 1996) et "toutes_1996_2016" (pour comparaison de couverture).
#   Par puits : moyenne de ses lectures de mai dans la fenetre. Par district :
#     moyenne, mediane, min et max de ces moyennes de puits, et nombre de puits.
#   Lectures > 300 m exclues (4 lectures, physiquement non credibles : cf. log
#     03, 534 m sur un puits de Gandhinagar). Lectures negatives gardees
#     (artesien / arrondi, 50 lectures). Regle annoncee ici, effet journalise.
#   District : point dans polygone, shrug-pc11dist-poly-gpkg, en LAEA (meme
#     regle que l'etape 09 ; un puits sur une frontiere garde le 1er polygone).
#
# ATTENDUS (ecrits avant la premiere execution)
#   Controles bloquants (check) :
#     V1. 28 076 puits, WLCODE unique ; 242 946 lectures de mai non manquantes.
#     V2. 641 polygones de district, pc11_district_id unique.
#     V3. au plus 1 % des puits hors de tout district (l'etape 09 en trouvait 13).
#     V4. rattachement identique a build/09_puits_geo.rds pour 100 % des puits
#         (si ce fichier existe ; meme polygones, meme regle).
#   Attendus descriptifs (non bloquants, ecart signale dans le log) :
#     D1. fenetre de base : 13 000 a 14 500 puits (13 883 ont une 1re lecture
#         de mai <= 2000 d'apres l'etape 03).
#     D2. districts PC11 sans aucun puits de base : entre 10 % et 35 % des 641,
#         concentres dans le Nord-Est, J&K / HP / Uttarakhand et les districts
#         metropolitains ; districts a moins de 5 puits : 20 % a 50 %.
#
# LANCEMENT (racine du depot) :
#     Rscript code/16_cgwb_profondeur_district.R           # reprend
#     Rscript code/16_cgwb_profondeur_district.R --force   # refait tout
#
# ETAPE RESUMABLE (build/) : 16_puits_district.rds  puits -> district PC11
#
# Sorties : output/tables/16_*.csv, output/logs/16_cgwb_profondeur_district.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages(library(sf)))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("16_cgwb_profondeur_district.log"))

msg("ETAPE 16 -- PISTE E : PROFONDEUR CGWB AU DISTRICT PC11")
msg("Descriptif : aucune variable de resultat lue.")

LAEA     <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"
MAX_PROF <- 300
FENETRES <- list(base_1996_2000 = 1996:2000, toutes_1996_2016 = 1996:2016)
SEUIL_PEU <- 5L
f_dist   <- p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg")

ecart <- function(ok, quoi, obs) {
  if (isTRUE(ok)) msg("  [ATTENDU]  ", quoi, " -- observe : ", obs)
  else            msg("  [ECART]    ", quoi, " -- observe : ", obs, "  <-- a signaler")
}

# ===========================================================================
hr("16a. Entrees et controles")
# ===========================================================================

wells <- as.data.table(readRDS(p_build("cgwb_wells.rds")))
may   <- as.data.table(readRDS(p_build("cgwb_may_long.rds")))
check_rows(wells, 28076L, "cgwb_wells")
check_unique(wells, "WLCODE", "cgwb_wells")
check_rows(may, 242946L, "cgwb_may_long")
check_vars(may, c("WLCODE", "year", "depth_mbgl"), "cgwb_may_long")

dist <- sf::st_read(f_dist, quiet = TRUE)
check_vars(dist, c("pc11_state_id", "pc11_district_id", "district_name"), "district.gpkg")
check(nrow(dist) == 641L, "district.gpkg : 641 polygones", sprintf("observe %d", nrow(dist)))
check_unique(sf::st_drop_geometry(dist), "pc11_district_id", "district.gpkg")

# ===========================================================================
hr("16b. Puits -> district PC11 (etape resumable)")
# ===========================================================================

f_pd <- p_build("16_puits_district.rds")
pd <- stage("etape 1/1 puits -> district", f_pd, function() {
  s <- sf::st_transform(sf::st_as_sf(wells[, .(WLCODE, LON, LAT)],
                                     coords = c("LON", "LAT"), crs = 4326), LAEA)
  d <- sf::st_make_valid(sf::st_transform(dist[, c("pc11_state_id", "pc11_district_id")], LAEA))
  j <- sf::st_join(s, d, join = sf::st_intersects, left = TRUE)
  tmsg("    ", sum(duplicated(j$WLCODE)), " puits sur une frontiere, premier polygone garde")
  as.data.table(sf::st_drop_geometry(j[!duplicated(j$WLCODE), ]))
})

check_rows(pd, 28076L, "puits -> district")
n_hors <- pd[is.na(pc11_district_id), .N]
check(n_hors / nrow(pd) <= 0.01, "au plus 1 % des puits hors de tout district",
      sprintf("observe %d", n_hors))
msg("  puits hors de tout district : ", n_hors)

f09 <- p_build("09_puits_geo.rds")
if (file.exists(f09)) {
  p09 <- as.data.table(readRDS(f09))[, .(WLCODE, d09 = pc11_district_id)]
  cmp <- merge(pd, p09, by = "WLCODE")
  n_diff <- cmp[!(pc11_district_id == d09 | (is.na(pc11_district_id) & is.na(d09))), .N]
  check(nrow(cmp) == 28076L && n_diff == 0L,
        "rattachement identique a l'etape 09 pour tous les puits",
        sprintf("comparables %d, differents %d", nrow(cmp), n_diff))
} else {
  warn("build/09_puits_geo.rds absent : comparaison avec l'etape 09 non faite")
}

# ===========================================================================
hr("16c. Profondeur par puits, par fenetre")
# ===========================================================================

n_exclu <- may[depth_mbgl > MAX_PROF, .N]
msg(sprintf("  lectures > %d m exclues : %d (WLCODE : %s)", MAX_PROF, n_exclu,
            paste(unique(may[depth_mbgl > MAX_PROF, WLCODE]), collapse = ", ")))
msg(sprintf("  lectures negatives gardees : %d", may[depth_mbgl < 0, .N]))
may <- may[depth_mbgl <= MAX_PROF]

par_puits <- rbindlist(lapply(names(FENETRES), function(f) {
  may[year %in% FENETRES[[f]], .(prof = mean(depth_mbgl), n_lect = .N), by = WLCODE][, fenetre := f]
}))
par_puits <- merge(par_puits, pd, by = "WLCODE")
par_puits <- par_puits[!is.na(pc11_district_id)]
print(par_puits[, .(puits = .N, lectures_med = as.numeric(median(n_lect)),
                    prof_med = round(median(prof), 2)), by = fenetre])

n_base <- par_puits[fenetre == "base_1996_2000", .N]
ecart(n_base >= 13000 && n_base <= 14500, "D1 : 13 000 a 14 500 puits dans la fenetre de base",
      format(n_base, big.mark = " "))

# ===========================================================================
hr("16d. Agregation au district")
# ===========================================================================

# noms d'Etat : nom modal par pc11_state_id dans les cles SHRUG (aucun nom saisi)
k   <- as.data.table(read_dta_chk(p_raw("shrug", "shrug-pc-keys-dta", "shrid_pc11dist_key.dta")))
nom <- as.data.table(readRDS(p_build("shrid_loc_names.rds")))[, .(shrid2, state_name)]
etat <- merge(k[, .(shrid2, pc11_state_id)], nom, by = "shrid2")[
  , .N, by = .(pc11_state_id, state_name)][order(-N)][!duplicated(pc11_state_id), .(pc11_state_id, state_name)]

grille <- CJ(pc11_district_id = dist$pc11_district_id, fenetre = names(FENETRES))
grille <- merge(grille, as.data.table(sf::st_drop_geometry(dist)), by = "pc11_district_id")
agg <- par_puits[, .(n_puits = .N, prof_moy = mean(prof), prof_med = median(prof),
                     prof_min = min(prof), prof_max = max(prof)),
                 by = .(pc11_district_id, fenetre)]
dd <- merge(grille, agg, by = c("pc11_district_id", "fenetre"), all.x = TRUE)
dd[is.na(n_puits), n_puits := 0L]
dd <- merge(dd, etat, by = "pc11_state_id", all.x = TRUE)
check(dd[, .N] == 641L * length(FENETRES), "une ligne par district et par fenetre")
cols <- c("prof_moy", "prof_med", "prof_min", "prof_max")
dd[, (cols) := lapply(.SD, round, 2), .SDcols = cols]
setcolorder(dd, c("fenetre", "pc11_state_id", "state_name", "pc11_district_id", "district_name", "n_puits"))
setorder(dd, fenetre, pc11_state_id, pc11_district_id)
fwrite(dd, p_tab("16_profondeur_district.csv"))
msg("  ecrit : 16_profondeur_district.csv (", nrow(dd), " lignes, agregats de district)")

# ===========================================================================
hr("16e. Couverture : districts sans puits, a moins de 5 puits")
# ===========================================================================

couv <- dd[, .(districts = .N, zero_puits = sum(n_puits == 0),
               moins_de_5 = sum(n_puits < SEUIL_PEU), puits = sum(n_puits),
               puits_med_par_district = as.numeric(median(n_puits))), by = fenetre]
couv[, `:=`(zero_pct = round(100 * zero_puits / districts, 1),
            moins_de_5_pct = round(100 * moins_de_5 / districts, 1))]
print(couv)
fwrite(couv, p_tab("16_couverture_nationale.csv"))

cb <- couv[fenetre == "base_1996_2000"]
ecart(cb$zero_pct >= 10 && cb$zero_pct <= 35, "D2 : 10 a 35 % des districts sans puits de base",
      paste0(cb$zero_pct, " %"))
ecart(cb$moins_de_5_pct >= 20 && cb$moins_de_5_pct <= 50,
      "D2 : 20 a 50 % des districts a moins de 5 puits de base", paste0(cb$moins_de_5_pct, " %"))

par_etat <- dd[, .(districts = .N, zero_puits = sum(n_puits == 0),
                   moins_de_5 = sum(n_puits < SEUIL_PEU), au_moins_5 = sum(n_puits >= SEUIL_PEU),
                   puits = sum(n_puits),
                   ecart_prof_moy_entre_districts = round(diff(range(prof_moy, na.rm = TRUE)), 1)),
               by = .(fenetre, pc11_state_id, state_name)]
par_etat[!is.finite(ecart_prof_moy_entre_districts), ecart_prof_moy_entre_districts := NA]
setorder(par_etat, fenetre, -puits)
msg("\n  Par Etat, fenetre de base (districts PC11, puits dans la fenetre 1996-2000) :")
op <- options(width = 200); print(par_etat[fenetre == "base_1996_2000", !"fenetre"]); options(op)
fwrite(par_etat, p_tab("16_couverture_par_etat.csv"))

# Ou se trouvent les districts vides : leur repartition par Etat
vides <- dd[fenetre == "base_1996_2000" & n_puits == 0, .N, by = state_name][order(-N)]
msg("\n  Districts sans aucun puits de base, par Etat :")
print(vides)

hr("ETAPE 16 TERMINEE")
for (f in sort(list.files(file.path("output", "tables"), "^16_"))) note(f)
log_close()
