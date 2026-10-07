# ---------------------------------------------------------------------------
# 32_piste_a_ap_couches_fines.R -- variables geologiques FINES aux puits CGWB
#   de l'echantillon AP du script 10 (socle, 825 puits).
#
# CRITERE FIXE AVANT CONSTRUCTION : memo/piste_a_ap_fine_critere.md (commit
# 9b7eccc). Les regles de codage ci-dessous en sont la copie ; ne pas les
# changer. Ce script ne lit AUCUNE profondeur pour construire les variables :
# il ne fait que les attacher aux puits. La porte est estimee par
# code/33_piste_a_ap_lasso.py.
#
# COUCHES (raw/geology/, voir raw/README.md) :
#   ngdr/NGDR_Lithology_50k.parquet          lithologie GSI 1:50k, champ `lithologic`
#   bhuvan/Bhuvan_Lineament_50k_0506.parquet lineaments Bhuvan 1:50k, tous types
#   ngdr/NGDR_Lineament_250k.parquet         lineaments NGDR 1:250k (variante)
#   bhuvan/Bhuvan_Groundwater_Prospects_LGEOM.0[01].parquet  prospects (bloc P)
#
# REGLES (critere) :
#   classe = valeur du champ, en minuscules, espaces reduits et rognes ; vide ->
#     "(non renseigne)" ; une classe est gardee si >= 5 puits y tombent.
#   parts de surface de chaque classe gardee dans un rayon de 1 et 5 km.
#   fractures : distance au lineament le plus proche (km), longueur totale (km)
#     dans 1 et 5 km. Carres et interactions : faits par le script 33.
#   prospects : champ texte (nom contenant lith, geom, rock, descr, landf ou
#     unit) le plus souvent renseigne parmi les polygones de l'emprise.
# Surfaces et distances en LAEA (CLAUDE.md), geometries reparees dans ce CRS.
#
# LANCEMENT (racine du depot, dans un terminal) :
#     Rscript code/32_piste_a_ap_couches_fines.R           # reprend
#     Rscript code/32_piste_a_ap_couches_fines.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 32_echantillon.rds        puits + profondeur + controles (= script 10)
#   2. 32_lithologie_ap.gpkg     lithologie 1:50k dans l'emprise, LAEA, reparee
#   3. 32_lineaments50_ap.gpkg   lineaments 1:50k dans l'emprise, LAEA
#   4. 32_lineaments250_ap.gpkg  lineaments 1:250k dans l'emprise, LAEA
#   5. 32_prospects_ap.gpkg      prospects dans l'emprise, LAEA, champ retenu
#   6. 32_variables.rds          variables aux puits
# Sorties : build/32_puits_variables.csv (lu par le script 33),
#           output/tables/32_classes_*.csv, output/logs/32_piste_a_ap_couches_fines.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
suppressWarnings(suppressMessages({
  library(sf)
  library(arrow)
  library(dplyr)
}))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("32_piste_a_ap_couches_fines.log"))

# --- regles du critere (memo/piste_a_ap_fine_critere.md) ----------------------
N_ATTENDU        <- 825L
MIN_PUITS_CLASSE <- 5L
RAYONS           <- c(1000, 5000)
MARGE_DEG        <- 0.1
LAEA <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"
MOTIF_CHAMP_P <- "(?i)lith|geom|rock|descr|landf|unit"

f_lith <- p_raw("geology", "ngdr", "NGDR_Lithology_50k.parquet")
f_l50  <- p_raw("geology", "bhuvan", "Bhuvan_Lineament_50k_0506.parquet")
f_l250 <- p_raw("geology", "ngdr", "NGDR_Lineament_250k.parquet")
f_pro  <- p_raw("geology", "bhuvan", sprintf("Bhuvan_Groundwater_Prospects_LGEOM.%02d.parquet", 0:1))
for (f in c(f_lith, f_l50, f_l250, f_pro)) check(file.exists(f), paste0("source presente : ", f))

# La table exportee n'existe que si TOUT le script a abouti : on retire
# l'ancienne des le debut, pour qu'un arret en cours de route ne laisse pas au
# script 33 une table perimee (incident du 07/10, 12:41).
f_out <- p_build("32_puits_variables.csv")
if (file.exists(f_out)) file.remove(f_out)

msg("ETAPE 32 -- PISTE A, AP : VARIABLES GEOLOGIQUES FINES AUX PUITS")
msg("Critere : memo/piste_a_ap_fine_critere.md. Aucune estimation ici.")

# ===========================================================================
# Etape 1 : echantillon (identique au script 10)
# ===========================================================================
hr("32a. Echantillon (etape 1)")
f_ech <- p_build("32_echantillon.rds")
amont10 <- p_build(c("10_echantillon.rds", "10_terrain.rds", "10_sol.rds"))
for (f in amont10) check(file.exists(f), paste0("sortie du script 10 presente : ", f))
ech <- stage("etape 1/6 echantillon", f_ech, function() {
  e <- readRDS(amont10[1]); t <- readRDS(amont10[2]); s <- readRDS(amont10[3])
  d <- merge(merge(as.data.table(e), as.data.table(t), by = "WLCODE"), as.data.table(s), by = "WLCODE")
  ctrl <- c("elev", "slope_win", "relelev_win", "soil_ph", "soil_oc")
  d[complete.cases(d[, ..ctrl])]
}, after = amont10)
check_rows(ech, N_ATTENDU, "echantillon (script 10)")
check_unique(ech, "WLCODE", "echantillon")

puits <- st_transform(st_as_sf(as.data.frame(ech), coords = c("LON", "LAT"), crs = 4326,
                               remove = FALSE), LAEA)
emp <- c(min(ech$LON), min(ech$LAT), max(ech$LON), max(ech$LAT)) + MARGE_DEG * c(-1, -1, 1, 1)
msg(sprintf("  emprise (deg) : lon %.2f-%.2f, lat %.2f-%.2f", emp[1], emp[3], emp[2], emp[4]))

# lecture GeoParquet filtree sur l'emprise (bbox qui intersecte)
lire <- function(files, cols = NULL) {
  ds <- open_dataset(files, unify_schemas = TRUE)
  x0 <- emp[1]; y0 <- emp[2]; x1 <- emp[3]; y1 <- emp[4]
  q <- ds |> filter(bbox$xmax >= x0, bbox$xmin <= x1, bbox$ymax >= y0, bbox$ymin <= y1)
  q <- if (is.null(cols)) select(q, -bbox) else select(q, all_of(c(cols, "geometry")))
  x <- collect(q)
  # Doublons du republieur (constat du 07/10) : la lithologie 1:50k porte
  # chaque `gid` exactement 11 fois ; les lineaments ont quelques geometries
  # en double (0,3 % au 1:50k, 1 % au 1:250k). On retire les lignes dont la
  # geometrie est identique octet pour octet a une ligne deja vue.
  n0 <- nrow(x)
  x <- x[!duplicated(lapply(x$geometry, as.raw)), ]
  tmsg("    doublons de geometrie retires : ", format(n0 - nrow(x), big.mark = ","),
       " (", format(n0, big.mark = ","), " -> ", format(nrow(x), big.mark = ","), ")")
  g <- st_as_sfc(structure(lapply(x$geometry, as.raw), class = "WKB"), crs = 4326)
  x$geometry <- NULL
  st_transform(st_sf(as.data.frame(x), geometry = g), LAEA)
}
norm_classe <- function(v) {
  v <- tolower(trimws(gsub("\\s+", " ", as.character(v))))
  v[is.na(v) | v == ""] <- "(non renseigne)"
  v
}
reparer <- function(s) {
  nv <- sum(!st_is_valid(s), na.rm = TRUE)
  tmsg("    geometries invalides reparees : ", nv)
  s <- st_make_valid(s)
  s[!st_is_empty(s), ]
}

# ===========================================================================
# Etapes 2-5 : couches dans l'emprise
# ===========================================================================
hr("32b. Couches dans l'emprise (etapes 2-5)")

lith <- stage("etape 2/6 lithologie 1:50k", p_build("32_lithologie_ap.gpkg"), function() {
  s <- lire(f_lith, "lithologic")
  tmsg("    polygones dans l'emprise : ", format(nrow(s), big.mark = ","))
  s$classe <- norm_classe(s$lithologic)
  reparer(s[, "classe"])
}, after = f_lith)

l50 <- stage("etape 3/6 lineaments 1:50k", p_build("32_lineaments50_ap.gpkg"), function() {
  s <- lire(f_l50, "Des")
  tmsg("    lineaments dans l'emprise : ", format(nrow(s), big.mark = ","))
  s
}, after = f_l50)

l250 <- stage("etape 4/6 lineaments 1:250k", p_build("32_lineaments250_ap.gpkg"), function() {
  s <- lire(f_l250, "l1descript")
  tmsg("    lineaments dans l'emprise : ", format(nrow(s), big.mark = ","))
  s
}, after = f_l250)

pro <- stage("etape 5/6 prospects", p_build("32_prospects_ap.gpkg"), function() {
  s <- lire(f_pro)
  tmsg("    polygones dans l'emprise : ", format(nrow(s), big.mark = ","))
  df <- st_drop_geometry(s)
  cand <- names(df)[vapply(df, is.character, logical(1)) & grepl(MOTIF_CHAMP_P, names(df), perl = TRUE)]
  rens <- vapply(cand, function(v) mean(!is.na(df[[v]]) & trimws(df[[v]]) != ""), 0)
  ndis <- vapply(cand, function(v) length(unique(df[[v]][!is.na(df[[v]])])), 0L)
  tab <- data.table(champ = cand, part_renseignee = rens, n_valeurs = ndis)[order(-part_renseignee, -n_valeurs)]
  msg("    champs candidats (regle : le plus souvent renseigne, puis le plus de valeurs) :")
  print(head(tab, 12))
  fwrite(tab, p_tab("32_prospects_champs.csv"))
  champ <- tab$champ[1]
  msg("    champ retenu : ", champ)
  s$classe <- norm_classe(df[[champ]])
  s$champ_retenu <- champ
  reparer(s[, c("classe", "champ_retenu")])
}, after = f_pro)
champ_p <- unique(pro$champ_retenu)
msg("  prospects : champ retenu = ", champ_p)

# ===========================================================================
# Etape 6 : variables aux puits
# ===========================================================================
hr("32c. Variables aux puits (etape 6)")

classe_point <- function(poly, lab) {
  j <- st_join(puits[, "WLCODE"], poly[, "classe"], join = st_intersects, left = TRUE)
  j <- as.data.table(st_drop_geometry(j))
  n_mult <- j[, .N, by = WLCODE][N > 1, .N]
  n_conf <- j[!is.na(classe), uniqueN(classe), by = WLCODE][V1 > 1, .N]
  msg(sprintf("    %s : puits dans plusieurs polygones %d, dont de classes differentes %d ; hors couche %d",
              lab, n_mult, n_conf, j[is.na(classe), uniqueN(WLCODE)]))
  check(n_conf == 0, sprintf("%s : aucun puits dans des polygones de classes differentes", lab),
        sprintf("%d puits en conflit", n_conf))
  j <- j[!duplicated(WLCODE)]
  j[is.na(classe), classe := "(hors couche)"]
  j
}

# Superpositions residuelles apres dedoublonnage (constat du 07/10 : 79 paires,
# 1,97 km2 sur 206 012 km2, defauts de numerisation en bord de feuille). Option
# A retenue (Valentine, 07/10) : dans la zone utile (5 km autour des puits),
# chaque paire dont les interieurs se recouvrent est resolue en retirant la
# partie commune du polygone de rang le plus eleve (le premier garde la
# surface). Les parts ne comptent ainsi chaque surface qu'une fois.
# Garde la partie surfacique d'un resultat de st_difference, quel que soit son
# type : POLYGON / MULTIPOLYGON tels quels, GEOMETRYCOLLECTION -> polygones,
# et vide si le reste n'est que lignes ou points (incident du 07/10, 12:54 :
# st_collection_extract refuse un type singulier autre que POLYGON).
surfaces <- function(x) {
  vide <- st_sfc(st_multipolygon(), crs = st_crs(x))
  x <- x[!st_is_empty(x)]
  if (!length(x)) return(vide)
  ty <- as.character(st_geometry_type(x))
  x <- x[ty %in% c("POLYGON", "MULTIPOLYGON", "GEOMETRYCOLLECTION")]
  if (!length(x)) return(vide)
  if (any(as.character(st_geometry_type(x)) == "GEOMETRYCOLLECTION")) {
    x <- suppressWarnings(st_collection_extract(st_cast(x, "GEOMETRYCOLLECTION"), "POLYGON"))
  }
  if (!length(x)) vide else st_union(x)
}

sans_superposition <- function(poly, lab) {
  zone <- st_union(st_buffer(st_geometry(puits), max(RAYONS)))
  sub <- poly[lengths(st_intersects(poly, zone)) > 0, ]
  rel <- st_relate(sub, sub, pattern = "2********")
  paires <- rbindlist(lapply(seq_along(rel), function(i) {
    j <- rel[[i]][rel[[i]] > i]
    if (length(j)) data.table(i = i, j = j)
  }))
  g <- st_geometry(sub)
  a0 <- sum(as.numeric(st_area(g)))
  n_diff <- 0L
  tmsg("    ", lab, " : ", nrow(paires), " paires superposees a resoudre")
  for (k in seq_len(nrow(paires))) {
    if (k %% 500L == 0L) tmsg("      ", k, "/", nrow(paires))
    i <- paires$i[k]; j <- paires$j[k]
    if (sub$classe[i] != sub$classe[j]) n_diff <- n_diff + 1L
    g[j] <- surfaces(st_difference(g[j], g[i]))
  }
  st_geometry(sub) <- g
  a1 <- sum(as.numeric(st_area(g)))
  msg(sprintf("    %s : %d polygones dans la zone, %d paires superposees (%d de classes differentes), %.3f km2 retires",
              lab, nrow(sub), nrow(paires), n_diff, (a0 - a1) / 1e6))
  sub[!st_is_empty(sub), ]
}

parts <- function(poly, garde, prefixe) {
  out <- data.table(WLCODE = ech$WLCODE)
  for (r in RAYONS) {
    buf <- st_buffer(puits[, "WLCODE"], r)
    sub <- poly[poly$classe %in% garde, "classe"]
    ix <- st_intersection(buf, sub)
    ix$a <- as.numeric(st_area(ix))
    a <- as.data.table(st_drop_geometry(ix))[, .(a = sum(a)), by = .(WLCODE, classe)]
    a[, part := a / (pi * r^2)]
    w <- dcast(a, WLCODE ~ classe, value.var = "part", fill = 0)
    k <- match(setdiff(names(w), "WLCODE"), garde)
    setnames(w, setdiff(names(w), "WLCODE"), sprintf("%s_s%d_%02d", prefixe, r / 1000, k))
    out <- merge(out, w, by = "WLCODE", all.x = TRUE)
  }
  for (v in setdiff(names(out), "WLCODE")) set(out, which(is.na(out[[v]])), v, 0)
  for (r in RAYONS) {
    cols <- grep(sprintf("^%s_s%d_", prefixe, r / 1000), names(out), value = TRUE)
    smax <- if (length(cols)) max(rowSums(out[, ..cols])) else 0
    check(smax <= 1.001, sprintf("%s : somme des parts a %d km <= 1 (max %.3f)", prefixe, r / 1000, smax),
          "surfaces comptees plusieurs fois : polygones superposes ou dupliques")
  }
  out
}

fractures <- function(lin, prefixe) {
  i <- st_nearest_feature(puits, lin)
  d <- as.numeric(st_distance(puits, lin[i, ], by_element = TRUE)) / 1000
  out <- data.table(WLCODE = ech$WLCODE, dist = d)
  for (r in RAYONS) {
    ix <- st_intersection(st_buffer(puits[, "WLCODE"], r), lin[, 0])
    l <- as.data.table(data.frame(WLCODE = ix$WLCODE, l = as.numeric(st_length(ix)) / 1000))[
      , .(l = sum(l)), by = WLCODE]
    out <- merge(out, setnames(l, "l", paste0("l", r / 1000)), by = "WLCODE", all.x = TRUE)
  }
  out[is.na(l1), l1 := 0][is.na(l5), l5 := 0]
  setnames(out, c("dist", "l1", "l5"), paste0(prefixe, c("_dist", "_l1", "_l5")))
  out
}

bloc_classes <- function(poly, prefixe, lab) {
  pc <- classe_point(poly, lab)
  n <- pc[, .N, by = classe][order(-N)]
  garde <- n[N >= MIN_PUITS_CLASSE & !classe %in% c("(hors couche)"), classe]
  msg(sprintf("    %s : %d classes aux puits, %d gardees (>= %d puits)", lab, nrow(n),
              length(garde), MIN_PUITS_CLASSE))
  dico <- data.table(k = seq_along(garde), classe = garde,
                     n_puits = n[match(garde, classe), N])
  fwrite(dico, p_tab(sprintf("32_classes_%s.csv", prefixe)))
  ind <- data.table(WLCODE = pc$WLCODE)
  for (k in seq_along(garde)) set(ind, j = sprintf("%s_c_%02d", prefixe, k),
                                  value = as.numeric(pc$classe == garde[k]))
  # Une seule classe gardee : la couche ne distingue aucun puits d'un autre.
  # Ses parts ne mesureraient que la couverture de la couche ; on ne les
  # calcule pas (constat du 07/10 sur les prospects : tous les puits dans
  # "(non renseigne)", 25 min de calcul de superpositions sans objet).
  if (length(garde) < 2L) {
    msg(sprintf("    [SIGNALE] %s : bloc degenere (%d classe gardee) -- parts non calculees",
                lab, length(garde)))
    return(ind)
  }
  merge(ind, parts(sans_superposition(poly, lab), garde, prefixe), by = "WLCODE")
}

var <- stage("etape 6/6 variables", p_build("32_variables.rds"), function() {
  tmsg("    lithologie")
  vl <- bloc_classes(lith, "lit", "lithologie 1:50k")
  tmsg("    prospects")
  vp <- bloc_classes(pro, "pro", "prospects")
  tmsg("    fractures 1:50k")
  f50 <- fractures(l50, "f50")
  tmsg("    fractures 1:250k")
  f250 <- fractures(l250, "f250")
  Reduce(function(a, b) merge(a, b, by = "WLCODE"), list(vl, vp, f50, f250))
}, after = p_build(c("32_echantillon.rds", "32_lithologie_ap.gpkg", "32_lineaments50_ap.gpkg",
                     "32_lineaments250_ap.gpkg", "32_prospects_ap.gpkg")))

check_rows(var, N_ATTENDU, "variables : une ligne par puits")
check_unique(var, "WLCODE", "variables")
msg(sprintf("  colonnes : lithologie %d, prospects %d, fractures 1:50k %d, 1:250k %d",
            length(grep("^lit_", names(var))), length(grep("^pro_", names(var))),
            length(grep("^f50_", names(var))), length(grep("^f250_", names(var)))))
print(round(sapply(var[, .(f50_dist, f50_l1, f50_l5, f250_dist, f250_l5)], quantile,
                   c(0, .25, .5, .75, 1)), 2))

xy <- st_coordinates(puits)
out <- merge(ech[, .(WLCODE, pc11_district_id, depth, elev, slope_win, relelev_win, soil_ph, soil_oc)],
             data.table(WLCODE = puits$WLCODE, x_laea = xy[, 1], y_laea = xy[, 2]), by = "WLCODE")
out <- merge(out, var, by = "WLCODE")
check_rows(out, N_ATTENDU, "table exportee")
fwrite(out, f_out)
msg("  ecrit : build/32_puits_variables.csv (", ncol(out), " colonnes)")

log_close()
