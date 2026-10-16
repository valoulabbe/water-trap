# ---------------------------------------------------------------------------
# 34_piste_a_classe_aquifere.R -- la couche Bhujal LGEOM porte-t-elle une
#   classe d'aquifere utilisable (equivalent de AQ_MAT chez Ryan & Sudarshan) ?
#
# CRITERE FIXE AVANT TOUT CHIFFRE : memo/piste_a_classe_aquifere_critere.md
#   (commit b8cb87f). Les seuils ci-dessous en sont la copie ; ne pas les changer.
#
# PORTEE : travail descriptif sur l'instrument. AUCUNE variable de fourniture
# publique, AUCUNE profondeur de puits n'est lue.
#
# DONNEES :
#   raw/geology/bhuvan/Bhuvan_Groundwater_Prospects_LGEOM.0[01].parquet
#       820 552 polygones ; lus colonne par colonne (arrow), jamais en entier
#   raw/geology/ngdr/NGDR_Lithology_50k.parquet   roche = `lithologic`
#   raw/shrug/shrug-pc11dist-poly-gpkg/district.gpkg  (hors critere : R a
#       roche x district)
#   raw/shrug/shrug-shrid-poly-gpkg/shrid2_open.gpkg + build/shrid_loc_names.rds
#   raw/nicholasryan2021/.../data/work/marginal_analysis_sample.dta
#       6 215 agriculteurs ; noms de village/bloc/district, aquifer_type_1..20
#
# PRECISION D'EXECUTION (non tranchee par le memo, fixee ici avant tout
# chiffre) : pour chaque candidat, les mesures de V portent sur les
# agriculteurs apparies, a classe connue, dont le village a un code ET une
# roche NGDR renseignes ; K0, Plafond, A_code, A_roche et A_code x roche sont
# donc calcules sur le meme echantillon. Verdict global : OUI si un candidat
# est OUI ; sinon LIMITE si un candidat est LIMITE ; sinon NON.
#
# LANCEMENT (racine du depot) :
#     Rscript code/34_piste_a_classe_aquifere.R           # reprend
#     Rscript code/34_piste_a_classe_aquifere.R --force   # refait tout
#
# ETAPES RESUMABLES (build/) :
#   1. 34_attributs.rds         attributs LGEOM, toutes lignes, sans geometrie
#   2. 34_lgeom_groupes.gpkg    polygones des trois groupes, LAEA, repares
#   3. 34_roche_points.rds      roche NGDR et district au point interieur
#   4. 34_appariement.rds       agriculteur -> shrid (noms seulement)
#   5. 34_parts_villages.rds    parts de surface des codes et roches par shrid
# Le calcul des criteres et de V est toujours refait (quelques secondes).
#
# Sorties : output/tables/34_*.csv (+ .tex), output/logs/34_piste_a_classe_aquifere.log
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

log_open(p_log("34_piste_a_classe_aquifere.log"))

# --- seuils du critere (memo/piste_a_classe_aquifere_critere.md) --------------
SEUIL_C1          <- 0.80    # part renseignee, polygones ET surface
SEUIL_CLASSE_EFF  <- 0.005   # une classe effective porte >= 0,5 % de la surface
C2_MIN            <- 5L
C2_MAX            <- 60L
SEUIL_COUV_EFF    <- 0.95
SEUIL_C3          <- 0.25    # R = H(cand | roche) / H(cand)
V_PART_APPARIES   <- 0.60
V_MIN_VILLAGES    <- 30L
V_RHO             <- 0.50
V_GAIN            <- 0.05
V_RHO_LIMITE      <- 0.40
V_GAIN_LIMITE     <- 0.03
PART_MANQUANT_VIL <- 0.50    # code du village manquant si > moitie non renseignee

N_LGEOM   <- 820552L
N_RYAN    <- 6215L
MARGE_DEG <- 0.05
LAEA <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"

f_lgeom <- sort(Sys.glob(p_raw("geology", "bhuvan", "Bhuvan_Groundwater_Prospects_LGEOM.0*.parquet")))
f_lith  <- p_raw("geology", "ngdr", "NGDR_Lithology_50k.parquet")
f_dist  <- p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg")
f_shrid <- p_raw("shrug", "shrug-shrid-poly-gpkg", "shrid2_open.gpkg")
f_noms  <- p_build("shrid_loc_names.rds")
f_far   <- p_raw("nicholasryan2021", "20200932data", "rationing_commons", "data", "work",
                 "marginal_analysis_sample.dta")

# --- candidats ----------------------------------------------------------------
CAND_BRUTS <- c("GWMP_CODE", "GWMAP_CODE",
                paste0("Descr_L", 1:5), paste0("DESCR", 1:5), paste0("DESCR_L", 1:5, "_1"),
                "Landform", "PHYSIOGRAP", "geom_landf", "GEOM_UNIT", "GEOM_CODE")
FAMILLES <- c(
  list(GWP = c("GWMP_CODE", "GWMAP_CODE")),
  setNames(lapply(1:5, function(k) c(paste0("Descr_L", k), paste0("DESCR_L", k, "_1"),
                                     paste0("DESCR", k))), paste0("DL", 1:5)),
  list(LANDF = c("Landform", "geom_landf"),
       PHYS  = c("PHYSIOGRAP", "Physiograp_1"),
       GEOMC = c("GEOM_CODE", "Geom_Code_1")))
CANDIDATS     <- c(CAND_BRUTS, names(FAMILLES))
ROCHE_INTERNE <- c("Rock_type", "Rock_Type_1", "ROCK_TYPE_2")
COLS_ATTR     <- unique(c("sname", CAND_BRUTS, unlist(FAMILLES), ROCHE_INTERNE))
GROUPES       <- c("AP non divise", "Rajasthan", "Uttar Pradesh")
MANQUANTS     <- c("", "0", "-", "NA", "N/A", "NULL", "<NULL>", "NIL", "NONE")

msg("ETAPE 34 -- PISTE A : LA COUCHE BHUJAL PORTE-T-ELLE UNE CLASSE D'AQUIFERE ?")
msg("")
msg("Critere fixe avant tout chiffre : memo/piste_a_classe_aquifere_critere.md")
msg(sprintf("  C1 couverture >= %.2f (polygones et surface)", SEUIL_C1))
msg(sprintf("  C2 %d a %d classes effectives (>= %.1f %% de surface), couvrant >= %.0f %%",
            C2_MIN, C2_MAX, 100 * SEUIL_CLASSE_EFF, 100 * SEUIL_COUV_EFF))
msg(sprintf("  C3 R = H(cand | roche NGDR) / H(cand) >= %.2f", SEUIL_C3))
msg(sprintf("  V  rho >= %.2f et gain code x roche >= %.2f (limite : %.2f / %.2f)",
            V_RHO, V_GAIN, V_RHO_LIMITE, V_GAIN_LIMITE))
msg("Aucune variable de fourniture publique, aucune profondeur.")

# --- outils -------------------------------------------------------------------
normaliser <- function(v) {
  v <- toupper(trimws(gsub("\\s+", " ", as.character(v))))
  v[is.na(v) | v %in% MANQUANTS] <- NA_character_
  v
}
nn <- function(v) gsub("[^A-Z]", "", toupper(ifelse(is.na(v), "", v)))
groupe_etat <- function(sn) {
  k <- nn(sn)
  fcase(grepl("ANDHRA|TELANGANA", k), "AP non divise",
        grepl("RAJASTHAN", k),        "Rajasthan",
        grepl("UTTARPRADESH", k),     "Uttar Pradesh",
        default = NA_character_)
}
# normalisation, familles fusionnees (premiere valeur non manquante), groupe
preparer <- function(x) {
  x <- as.data.table(x)
  for (v in setdiff(COLS_ATTR, "sname")) set(x, j = v, value = normaliser(x[[v]]))
  for (f in names(FAMILLES)) set(x, j = f, value = fcoalesce(lapply(FAMILLES[[f]], function(m) x[[m]])))
  x[, roche_interne := fcoalesce(lapply(ROCHE_INTERNE, function(m) x[[m]]))]
  x[, groupe := groupe_etat(sname)]
  x
}
reparer <- function(s) {
  nv <- sum(!st_is_valid(s), na.rm = TRUE)
  tmsg("    geometries invalides reparees : ", nv)
  s <- st_make_valid(s)
  s[!st_is_empty(s), ]
}
# Un CRS relu depuis un .gpkg n'est pas toujours egal, pour sf, a la chaine
# LAEA : les donnees y sont deja, on reecrit seulement l'etiquette.
en_laea <- function(s) suppressWarnings(st_set_crs(s, LAEA))
wkb_sf <- function(x) {
  wkb <- lapply(x$geometry, as.raw)
  x$geometry <- NULL
  st_sf(as.data.frame(x), geometry = st_as_sfc(structure(wkb, class = "WKB"), crs = 4326))
}
# lithologie NGDR dans une emprise (deg), doublons du republieur retires
lire_ngdr <- function(bb) {
  ds <- open_dataset(f_lith)
  x0 <- bb[["xmin"]] - MARGE_DEG; y0 <- bb[["ymin"]] - MARGE_DEG
  x1 <- bb[["xmax"]] + MARGE_DEG; y1 <- bb[["ymax"]] + MARGE_DEG
  x <- ds |> filter(bbox$xmax >= x0, bbox$xmin <= x1, bbox$ymax >= y0, bbox$ymin <= y1) |>
    select(all_of(c("lithologic", "geometry"))) |> collect()
  n0 <- nrow(x)
  x <- x[!duplicated(lapply(x$geometry, as.raw)), ]
  tmsg("    NGDR : ", format(n0, big.mark = ","), " lignes, ",
       format(nrow(x), big.mark = ","), " apres retrait des doublons de geometrie")
  check(nrow(x) > 0, "NGDR : au moins un polygone dans l'emprise")
  s <- st_transform(wkb_sf(x), LAEA)
  s$roche_ngdr <- normaliser(s$lithologic)
  reparer(s[, "roche_ngdr"])
}
# entropies ponderees (log naturel)
H_cond <- function(y, x, w) {
  d <- data.table(y = y, x = x, w = w)[, .(w = sum(w)), by = .(x, y)]
  d[, wx := sum(w), by = x]
  -sum(d$w / sum(d$w) * log(d$w / d$wx))
}
H <- function(y, w) H_cond(y, rep("1", length(y)), w)
purete <- function(y, x, w) {
  d <- data.table(y = y, x = x, w = w)[, .(w = sum(w)), by = .(x, y)]
  d[, .(m = max(w)), by = x][, sum(m)] / sum(d$w)
}
part_residuelle <- function(y, x, w) {
  ok <- !is.na(y) & !is.na(x)
  if (!any(ok)) return(NA_real_)
  h <- H(y[ok], w[ok])
  if (h <= 0) return(NA_real_)
  H_cond(y[ok], x[ok], w[ok]) / h
}
ecrire_tex <- function(d, path) {
  esc <- function(s) gsub("([_&%#$])", "\\\\\\1", s)
  fmt <- function(v) {
    if (is.logical(v)) return(ifelse(is.na(v), "--", ifelse(v, "oui", "non")))
    if (is.integer(v)) return(ifelse(is.na(v), "--", format(v, big.mark = ",")))
    if (is.numeric(v)) return(ifelse(is.na(v), "--", formatC(v, format = "f", digits = 3)))
    ifelse(is.na(v), "--", esc(as.character(v)))
  }
  body <- do.call(paste, c(lapply(d, fmt), sep = " & "))
  lines <- c(sprintf("\\begin{tabular}{%s}", paste(rep("l", ncol(d)), collapse = "")),
             "\\toprule", paste(esc(names(d)), collapse = " & ") |> paste0(" \\\\"),
             "\\midrule", paste0(body, " \\\\"), "\\bottomrule", "\\end{tabular}")
  writeLines(lines, path)
}

# ===========================================================================
# Etape 1 : attributs LGEOM, toutes lignes
# ===========================================================================
hr("34a. Attributs LGEOM (etape 1)")
check(length(f_lgeom) == 2L, "LGEOM : deux parties .00 et .01 presentes",
      paste("trouve :", paste(f_lgeom, collapse = ", ")))

att <- stage("etape 1/5 attributs LGEOM", p_build("34_attributs.rds"), function() {
  ds <- open_dataset(f_lgeom)
  nm <- names(ds)
  check_vars(setNames(as.list(nm), nm), c(COLS_ATTR, "geometry"), "LGEOM (schema)")
  tmsg("    lecture de ", length(COLS_ATTR), " colonnes sur ", length(nm), ", sans geometrie")
  x <- collect(select(ds, all_of(COLS_ATTR)))
  check_rows(x, N_LGEOM, "LGEOM (deux parties)")
  preparer(x)
}, after = f_lgeom)
check_rows(att, N_LGEOM, "attributs LGEOM")
for (g in GROUPES) check(att[groupe == g, .N] > 0, sprintf("groupe %s : au moins un polygone", g))
msg("Valeurs de sname rattachees aux groupes :")
print(att[!is.na(groupe), .N, by = .(groupe, sname)][order(groupe, sname)])

# descriptif national, hors critere (ponderation par polygones)
nat <- rbindlist(lapply(CANDIDATS, function(cc)
  att[, .(candidat = cc, n_poly = .N, part_poly = mean(!is.na(get(cc))),
          n_distinct = uniqueN(get(cc), na.rm = TRUE)), by = .(sname, groupe)]))
fwrite(nat, p_tab("34_couverture_nationale.csv"))
tmsg("ecrit : ", p_tab("34_couverture_nationale.csv"))

# conflits entre membres d'une famille
conf <- rbindlist(lapply(names(FAMILLES), function(f) {
  m <- as.matrix(att[, FAMILLES[[f]], with = FALSE])
  plusieurs <- rowSums(!is.na(m)) >= 2L
  diff <- rowSums(!is.na(m) & m != att[[f]], na.rm = TRUE) > 0
  data.table(groupe = att$groupe, plusieurs, diff)[!is.na(groupe),
    .(famille = f, n_deux_membres = sum(plusieurs), n_conflits = sum(diff)), by = groupe]
}))
msg("Familles : polygones a deux membres renseignes, et conflits :")
print(conf)

# ===========================================================================
# Etape 2 : polygones des trois groupes
# ===========================================================================
hr("34b. Polygones des trois groupes (etape 2)")

f_geo <- p_build("34_lgeom_groupes.gpkg")
geo <- stage("etape 2/5 polygones des trois groupes", f_geo, function() {
  sn <- unique(att[!is.na(groupe), sname])
  n_att <- att[!is.na(groupe), .N]
  x <- open_dataset(f_lgeom) |> filter(sname %in% sn) |>
    select(all_of(c(COLS_ATTR, "geometry"))) |> collect()
  check_rows(x, n_att, "LGEOM, trois groupes, avec geometrie")
  wkb <- lapply(x$geometry, as.raw)
  x$geometry <- NULL
  x <- preparer(x)
  cle <- do.call(paste, c(as.list(x[, COLS_ATTR, with = FALSE]), sep = "\r"))
  dup_g  <- duplicated(wkb)
  dup_ga <- duplicated(Map(list, wkb, cle))
  tmsg("    doublons de geometrie retires : ", format(sum(dup_g), big.mark = ","),
       " dont ", format(sum(dup_g) - sum(dup_ga), big.mark = ","),
       " a attributs differents (premier garde)")
  x <- x[!dup_g]; wkb <- wkb[!dup_g]
  s <- st_sf(as.data.frame(x), geometry = st_as_sfc(structure(wkb, class = "WKB"), crs = 4326))
  s <- reparer(st_transform(s, LAEA))
  s$rid <- seq_len(nrow(s))
  s$aire_m2 <- as.numeric(st_area(s))
  p <- st_coordinates(st_point_on_surface(st_geometry(s)))
  s$px <- p[, 1]; s$py <- p[, 2]
  tmsg("    polygones gardes : ", format(nrow(s), big.mark = ","))
  s
}, after = f_lgeom)
geo <- en_laea(geo)
check_unique(st_drop_geometry(geo), "rid", "polygones des trois groupes")

# ===========================================================================
# Etape 3 : roche NGDR et district au point interieur
# ===========================================================================
hr("34c. Roche NGDR et district aux points interieurs (etape 3)")

roc <- stage("etape 3/5 roche NGDR aux points", p_build("34_roche_points.rds"), function() {
  pts <- st_as_sf(data.frame(rid = geo$rid, groupe = geo$groupe, px = geo$px, py = geo$py),
                  coords = c("px", "py"), crs = LAEA)
  r <- rbindlist(lapply(GROUPES, function(g) {
    tmsg("  groupe ", g)
    pg <- pts[pts$groupe == g, ]
    lith <- lire_ngdr(st_bbox(st_transform(pg, 4326)))
    j <- st_join(pg, lith, join = st_intersects, left = TRUE)
    tmsg("    points dans plusieurs polygones NGDR (premier garde) : ", sum(duplicated(j$rid)))
    j <- j[!duplicated(j$rid), ]
    data.table(rid = j$rid, roche_ngdr = j$roche_ngdr)
  }))
  tmsg("  districts SHRUG")
  dist <- reparer(st_transform(st_read(f_dist, quiet = TRUE), LAEA))
  check_vars(dist, c("pc11_state_id", "pc11_district_id"), "district.gpkg")
  jd <- st_join(pts, dist[, c("pc11_state_id", "pc11_district_id")], join = st_intersects, left = TRUE)
  jd <- jd[!duplicated(jd$rid), ]
  r <- merge(r, data.table(rid = jd$rid,
                           district = fifelse(is.na(jd$pc11_district_id), NA_character_,
                                              paste(jd$pc11_state_id, jd$pc11_district_id))),
             by = "rid", all = TRUE)
  r
}, after = c(f_geo, f_lith, f_dist))
check_rows(roc, nrow(geo), "roche aux points (une ligne par polygone)")
check_unique(roc, "rid", "roche aux points")

# ===========================================================================
# Criteres C1-C3
# ===========================================================================
hr("34d. Criteres C1-C3 par candidat et groupe")

d <- merge(as.data.table(st_drop_geometry(geo)), roc, by = "rid")
check_rows(d, nrow(geo), "polygones x roche")

msg("Part de surface avec roche NGDR, par groupe :")
print(d[, .(part_aire_roche = sum(aire_m2[!is.na(roche_ngdr)]) / sum(aire_m2),
            part_aire_district = sum(aire_m2[!is.na(district)]) / sum(aire_m2)), by = groupe])

crit <- rbindlist(lapply(CANDIDATS, function(cc) rbindlist(lapply(GROUPES, function(g) {
  x <- d[groupe == g]
  y <- x[[cc]]; w <- x$aire_m2; ok <- !is.na(y)
  sh <- data.table(y = y[ok], w = w[ok])[, .(w = sum(w)), by = y][, s := w / sum(w)]
  eff <- sh[s >= SEUIL_CLASSE_EFF]
  ok3 <- ok & !is.na(x$roche_ngdr)
  data.table(
    candidat = cc, groupe = g, n_poly = nrow(x),
    part_poly = mean(ok), part_aire = if (any(ok)) sum(w[ok]) / sum(w) else 0,
    n_distinct = uniqueN(y[ok]), n_eff = nrow(eff), couv_eff = if (nrow(sh)) sum(eff$s) else NA_real_,
    part_aire_c3 = if (any(ok)) sum(w[ok3]) / sum(w[ok]) else NA_real_,
    R = part_residuelle(y, x$roche_ngdr, w),
    purete = if (any(ok3)) purete(y[ok3], x$roche_ngdr[ok3], w[ok3]) else NA_real_,
    R_roche_interne = part_residuelle(y, x$roche_interne, w),
    R_roche_district = part_residuelle(y, ifelse(is.na(x$roche_ngdr) | is.na(x$district), NA,
                                                 paste(x$roche_ngdr, x$district)), w))
}))))
crit[, C1 := part_poly >= SEUIL_C1 & part_aire >= SEUIL_C1]
crit[, C2 := n_eff >= C2_MIN & n_eff <= C2_MAX & !is.na(couv_eff) & couv_eff >= SEUIL_COUV_EFF]
crit[, C3 := !is.na(R) & R >= SEUIL_C3]
crit[, utilisable := C1 & C2 & C3]
fwrite(crit, p_tab("34_criteres_c1c3.csv"))
ecrire_tex(crit[, .(candidat, groupe, part_poly, part_aire, n_eff, couv_eff, R, C1, C2, C3)],
           p_tab("34_criteres_c1c3.tex"))
tmsg("ecrit : ", p_tab("34_criteres_c1c3.csv"), " (+ .tex)")
print(crit[, .(candidat, groupe, part_poly = round(part_poly, 3), part_aire = round(part_aire, 3),
               n_distinct, n_eff, couv_eff = round(couv_eff, 3), R = round(R, 3), C1, C2, C3)])

# ===========================================================================
# Etape 4 : appariement des villages de Ryan (noms seulement)
# ===========================================================================
hr("34e. Appariement des villages de Ryan & Sudarshan (etape 4, noms seulement)")

# Correspondances de noms de district ajoutees apres un arret (cf. critere) :
# nom normalise de Ryan -> nom normalise SHRUG. Vide au depart.
CORR_DISTRICTS <- c()

app <- stage("etape 4/5 appariement", p_build("34_appariement.rds"), function() {
  nm <- names(haven::read_dta(f_far, n_max = 0))
  check_vars(setNames(as.list(nm), nm), c("f_id", "village", "block", "district"),
             "marginal_analysis_sample (noms)")
  f <- as.data.table(haven::zap_labels(haven::read_dta(
    f_far, col_select = all_of(c("f_id", "village", "block", "district")))))
  check_rows(f, N_RYAN, "marginal_analysis_sample")
  check_unique(f, "f_id", "marginal_analysis_sample")
  check(all(vapply(f[, .(village, block, district)], is.character, logical(1))),
        "village, block, district sont des chaines")

  noms <- as.data.table(readRDS(f_noms))
  check_vars(noms, c("shrid2", "state_name", "district_name", "subdistrict_name", "village_name"),
             "shrid_loc_names")
  check_chr_key(noms, "shrid2", "shrid_loc_names")
  check_unique(noms, "shrid2", "shrid_loc_names")
  raj <- noms[nn(state_name) == "RAJASTHAN" & nzchar(nn(village_name)),
              .(shrid2, d_n = nn(district_name), s_n = nn(subdistrict_name), v_n = nn(village_name))]
  check(nrow(raj) > 0, "SHRUG : villages nommes au Rajasthan")
  tmsg("    villages SHRUG nommes au Rajasthan : ", format(nrow(raj), big.mark = ","))

  f[, `:=`(d_n = nn(district), b_n = nn(block), v_n = nn(village))]
  f[d_n %in% names(CORR_DISTRICTS), d_n := CORR_DISTRICTS[d_n]]
  manque <- setdiff(unique(f[nzchar(d_n), d_n]), raj$d_n)
  check(length(manque) == 0, "districts de Ryan : tous retrouves dans SHRUG (Rajasthan)",
        paste0("absents : ", paste(manque, collapse = ", "),
               " | districts SHRUG : ", paste(sort(unique(raj$d_n)), collapse = ", ")))

  vil <- unique(f[, .(district, block, village, d_n, b_n, v_n)])
  res <- rbindlist(lapply(seq_len(nrow(vil)), function(i) {
    r <- vil[i]
    if (!nzchar(r$d_n) || !nzchar(r$v_n)) return(data.table(shrid2 = NA_character_, methode = "absent (nom vide)"))
    pool <- raj[d_n == r$d_n]
    cand <- pool[v_n == r$v_n]; meth <- "exact"
    if (!nrow(cand) && nchar(r$v_n) >= 5L) {
      dd <- as.vector(adist(r$v_n, pool$v_n))
      ok <- dd <= 1L & nchar(pool$v_n) >= 5L
      if (any(ok)) { cand <- pool[ok & dd == min(dd[ok])]; meth <- "levenshtein" }
    }
    shr <- unique(cand$shrid2)
    if (length(shr) > 1L) {
      tb <- unique(cand[s_n == r$b_n, shrid2])
      if (length(tb) == 1L) { shr <- tb; meth <- paste0(meth, "+bloc") }
      else return(data.table(shrid2 = NA_character_, methode = "ambigu"))
    }
    if (!length(shr)) return(data.table(shrid2 = NA_character_, methode = "absent"))
    data.table(shrid2 = shr, methode = meth)
  }))
  vil <- cbind(vil, res)
  merge(f[, .(f_id, district, block, village)], vil[, .(district, block, village, shrid2, methode)],
        by = c("district", "block", "village"), all.x = TRUE)
}, after = c(f_far, f_noms))
check_rows(app, N_RYAN, "appariement (une ligne par agriculteur)")
check_unique(app, "f_id", "appariement")
av <- app[, .(n_agriculteurs = .N), by = .(district, block, village, shrid2, methode)]
fwrite(av, p_tab("34_appariement_villages.csv"))
tmsg("ecrit : ", p_tab("34_appariement_villages.csv"))
print(app[, .(n_agriculteurs = .N, n_villages = uniqueN(paste(district, block, village))), by = methode])

# ===========================================================================
# Etape 5 : parts de surface par shrid apparie
# ===========================================================================
hr("34f. Parts de surface des codes et de la roche par village (etape 5)")

parts <- stage("etape 5/5 parts par village", p_build("34_parts_villages.rds"), function() {
  shr <- sort(unique(na.omit(app$shrid2)))
  check(length(shr) > 0, "au moins un village apparie")
  q <- sprintf("SELECT * FROM shrid2 WHERE shrid2 IN (%s)", paste0("'", shr, "'", collapse = ","))
  v <- st_read(f_shrid, query = q, quiet = TRUE)
  check_rows(v, length(shr), "polygones shrid des villages apparies")
  v <- reparer(st_transform(v[, "shrid2"], LAEA))
  check_rows(v, length(shr), "polygones shrid apres reparation")
  aires <- data.table(shrid2 = v$shrid2, aire_v = as.numeric(st_area(v)))

  bh <- geo[geo$groupe == "Rajasthan", CANDIDATS]
  bh <- bh[lengths(st_intersects(bh, v)) > 0, ]
  tmsg("    polygones Bhujal touchant les villages : ", nrow(bh))
  pb <- suppressWarnings(st_intersection(v, bh))
  pb$a <- as.numeric(st_area(pb))
  lb <- melt(as.data.table(st_drop_geometry(pb)), id.vars = c("shrid2", "a"),
             measure.vars = CANDIDATS, variable.name = "variable", value.name = "valeur",
             variable.factor = FALSE)

  lith <- lire_ngdr(st_bbox(st_transform(v, 4326)))
  pl <- suppressWarnings(st_intersection(v, lith))
  pl$a <- as.numeric(st_area(pl))
  ll <- data.table(shrid2 = pl$shrid2, a = pl$a, variable = "ROCHE_NGDR", valeur = pl$roche_ngdr)

  list(aires = aires, parts = rbind(lb, ll)[, .(a = sum(a)), by = .(shrid2, variable, valeur)])
}, after = c(f_geo, f_lith, f_shrid, p_build("34_appariement.rds")))

code_village <- function(var) {
  p <- parts$parts[variable == var & !is.na(valeur)]
  tot <- p[, .(a_ok = sum(a)), by = shrid2]
  best <- p[order(shrid2, -a, valeur)][, .SD[1], by = shrid2][, .(shrid2, valeur)]
  out <- merge(merge(parts$aires, tot, by = "shrid2", all.x = TRUE), best, by = "shrid2", all.x = TRUE)
  out[is.na(a_ok), a_ok := 0]
  out[a_ok < (1 - PART_MANQUANT_VIL) * aire_v, valeur := NA_character_]
  out[, .(shrid2, valeur)]
}

# ===========================================================================
# Validation V
# ===========================================================================
hr("34g. Validation V sur AQ_MAT (Rajasthan)")

nm <- names(haven::read_dta(f_far, n_max = 0))
aq <- grep("^aquifer_type_[0-9]+$", nm, value = TRUE)
rk <- grep("^rock_type_[0-9]+$", nm, value = TRUE)
check(length(aq) == 20L && length(rk) == 65L, "Ryan : 20 indicatrices d'aquifere, 65 de roche")
y <- as.data.table(haven::zap_labels(haven::read_dta(f_far, col_select = all_of(c("f_id", aq, rk)))))
check_rows(y, N_RYAN, "Ryan, indicatrices")

classe_de <- function(m) {
  m <- as.matrix(m)
  check(all(is.na(m) | m %in% c(0, 1)), "indicatrices a valeurs 0/1/manquant")
  un <- !is.na(m) & m == 1
  s <- rowSums(un)
  list(s = s, classe = ifelse(s == 1L, max.col(un * 1, ties.method = "first"), NA_integer_))
}
ca <- classe_de(y[, aq, with = FALSE])
check(all(ca$s <= 1L), "au plus une classe d'aquifere par agriculteur",
      sprintf("%d lignes en portent plusieurs", sum(ca$s > 1L)))
y[, aq_classe := ca$classe]
cr <- classe_de(y[, rk, with = FALSE])
y[, roche_ryan := if (all(cr$s <= 1L)) cr$classe else NA_integer_]

# hors critere : AQ_MAT varie-t-il a roche donnee chez Ryan ?
if (all(cr$s <= 1L)) {
  r_ryan <- part_residuelle(as.character(y$aq_classe), as.character(y$roche_ryan), rep(1, nrow(y)))
  msg(sprintf("Hors critere : R(AQ_MAT | rock_type) chez Ryan, par agriculteur = %.3f", r_ryan))
} else {
  r_ryan <- NA_real_
  msg("Hors critere : rock_type_* n'est pas a une seule indicatrice par ligne ; R non calcule")
}

v0 <- merge(app[, .(f_id, shrid2)], y[, .(f_id, aq_classe)], by = "f_id")
check_rows(v0, N_RYAN, "appariement x classes")
n_connus <- v0[!is.na(aq_classe), .N]
n_app    <- v0[!is.na(aq_classe) & !is.na(shrid2), .N]
n_vil    <- v0[!is.na(aq_classe) & !is.na(shrid2), uniqueN(shrid2)]
part_app <- n_app / n_connus
faisable <- part_app >= V_PART_APPARIES && n_vil >= V_MIN_VILLAGES
msg(sprintf("Agriculteurs a classe connue : %d ; apparies : %d (%.3f, seuil %.2f) ; villages : %d (seuil %d)",
            n_connus, n_app, part_app, V_PART_APPARIES, n_vil, V_MIN_VILLAGES))
msg("V faisable : ", if (faisable) "OUI" else "NON -> V INFAISABLE, a remonter au PI")

# exactitude en laissant chaque village de cote ; x est constant dans un village
lovo <- function(yy, vv, xx) {
  dd <- data.table(y = yy, v = vv, x = xx)
  vx <- dd[, .(x = unique(x)), by = v]
  if (anyDuplicated(vx$v)) stop("VALIDATION FAILED: predicteur non constant dans un village", call. = FALSE)
  t_xy <- dd[, .N, by = .(x, y)]; t_y <- dd[, .N, by = y]
  pred <- vapply(seq_len(nrow(vx)), function(i) {
    own <- dd[v == vx$v[i], .(n_own = .N), by = y]
    retirer <- function(t) { t <- merge(t, own, by = "y", all.x = TRUE)
      t[is.na(n_own), n_own := 0L][, N := N - n_own][N > 0] }
    o <- retirer(t_xy[x == vx$x[i], .(y, N)])
    if (!nrow(o)) o <- retirer(copy(t_y))
    if (!nrow(o)) return(NA_integer_)
    as.integer(o[order(-N, y)][1, y])
  }, integer(1))
  mean(dd$y == pred[match(dd$v, vx$v)], na.rm = FALSE)
}
cramer <- function(a, b) {
  t <- table(a, b); if (min(dim(t)) < 2L) return(NA_real_)
  e <- outer(rowSums(t), colSums(t)) / sum(t)
  sqrt(sum((t - e)^2 / e) / (sum(t) * (min(dim(t)) - 1L)))
}

roche_v <- code_village("ROCHE_NGDR")
val <- rbindlist(lapply(CANDIDATS, function(cc) {
  cv <- code_village(cc)
  s <- merge(v0[!is.na(aq_classe) & !is.na(shrid2)], cv[, .(shrid2, code = valeur)], by = "shrid2")
  s <- merge(s, roche_v[, .(shrid2, roche = valeur)], by = "shrid2")
  s <- s[!is.na(code) & !is.na(roche)]
  base <- data.table(candidat = cc, n_agriculteurs = nrow(s), n_villages = uniqueN(s$shrid2),
                     n_codes = uniqueN(s$code))
  if (!faisable || uniqueN(s$shrid2) < 2L) return(base)
  plafond <- s[, .N, by = .(shrid2, aq_classe)][, .(m = max(N)), by = shrid2][, sum(m)] / nrow(s)
  cbind(base, data.table(
    K0 = lovo(s$aq_classe, s$shrid2, rep("tous", nrow(s))),
    plafond = plafond,
    A_code = lovo(s$aq_classe, s$shrid2, s$code),
    A_roche = lovo(s$aq_classe, s$shrid2, s$roche),
    A_code_roche = lovo(s$aq_classe, s$shrid2, paste(s$code, s$roche, sep = " | ")),
    cramer_v = cramer(s$code, s$aq_classe)))
}), fill = TRUE)
for (v in c("K0", "plafond", "A_code", "A_roche", "A_code_roche", "cramer_v"))
  if (!v %in% names(val)) set(val, j = v, value = NA_real_)
if (faisable) {
  val[, rho := fifelse(plafond > K0, (A_code - K0) / (plafond - K0), NA_real_)]
  val[, gain := A_code_roche - A_roche]
  val[, V := fcase(is.na(rho), "indefini",
                   rho >= V_RHO & gain >= V_GAIN, "reussie",
                   rho >= V_RHO_LIMITE & gain >= V_GAIN_LIMITE, "limite",
                   default = "echouee")]
} else {
  val[, V := "infaisable"]
}
val[, `:=`(part_appariee = part_app, n_villages_apparies = n_vil, R_ryan_aq_rock = r_ryan)]
fwrite(val, p_tab("34_validation_ryan.csv"))
ecrire_tex(val[, intersect(c("candidat", "n_agriculteurs", "n_villages", "K0", "plafond", "A_code",
                             "A_roche", "A_code_roche", "rho", "gain", "V"), names(val)), with = FALSE],
           p_tab("34_validation_ryan.tex"))
tmsg("ecrit : ", p_tab("34_validation_ryan.csv"), " (+ .tex)")
print(val)

# ===========================================================================
# Verdict contre le critere
# ===========================================================================
hr("34h. Verdict contre le critere")

u <- dcast(crit, candidat ~ groupe, value.var = "utilisable")
ver <- merge(u, val[, .(candidat, V)], by = "candidat")
ver[, groupes_utilisables := apply(.SD, 1, function(z) paste(GROUPES[as.logical(z)], collapse = ", ")),
    .SDcols = GROUPES]
ver[, issue := fcase(
  Rajasthan & V == "reussie",                      "OUI, valide",
  Rajasthan & V == "limite",                       "LIMITE",
  Rajasthan & V %in% c("echouee", "indefini"),     "NON - pas un aquifere",
  nzchar(groupes_utilisables),                     "OUI, non valide",
  default = "NON")]
fwrite(ver, p_tab("34_verdict_candidats.csv"))
tmsg("ecrit : ", p_tab("34_verdict_candidats.csv"))
print(ver[, .(candidat, groupes_utilisables, V, issue)])

global <- if (any(grepl("^OUI", ver$issue))) "OUI" else if (any(ver$issue == "LIMITE")) "LIMITE" else "NON"
msg("")
msg("VERDICT GLOBAL : ", global)
if (global == "OUI") for (i in which(grepl("^OUI", ver$issue)))
  msg("  ", ver$candidat[i], " : ", ver$issue[i], " (", ver$groupes_utilisables[i], ")")

log_close()
