# ---------------------------------------------------------------------------
# 14_piste_i_salinite.R -- piste I : la salinite des eaux souterraines comme
#   decaleur du cout du substitut prive (purificateur).
#
# HYPOTHESE. Ce qui fait varier le cout du substitut prive n'est pas son prix
# mais la TECHNOLOGIE requise : un filtre a gravite traite la contamination
# microbienne pour quelques centaines de roupies ; seule l'osmose inverse (RO)
# retire les solides dissous, pour dix fois plus. La geochimie locale (et non
# le revenu) trancherait entre les deux. Le reseau public traite en amont : son
# cout ne varie pas au meme endroit.
#
# LA LITTERATURE PENCHE CONTRE NOUS. Acharya, « Tasting numbers », Water
# Alternatives 17(2), 2024 (lu en entier) : enquete qualitative de douze mois a
# Bhuj (Gujarat, 143 000 habitants), groupes de discussion en societes de
# logement de classe moyenne. Son argument est l'inverse du notre : l'adoption
# du RO y est commandee par la construction discursive du TDS en contaminant,
# pas par la qualite mesuree. Aucune etude epidemiologique n'etablit qu'un TDS
# sous la limite de 2 000 ppm nuise a la sante ; le seuil officiel de 500 ppm
# n'est quasiment jamais invoque par les habitants, et toute valeur au-dessus de
# 100-150 ppm est pourtant tenue pour une contamination. L'adoption PERSISTE
# apres amelioration du service public : Bhuj recoit 77 % de son eau du Narmada
# depuis 2004 sans que la demande de RO recule.
# Notre test met son argument a l'epreuve ; il ne l'illustre pas. Si
# l'adoption ne suit pas la conductivite reelle, Acharya a raison et la piste
# meurt.
#
# PORTEE : SESSION DESCRIPTIVE. Aucune regression, aucune variable de resultat
# (adoption de purificateur) n'est lue. On mesure seulement si l'instrument
# (conductivite) varie assez A L'INTERIEUR des districts pour qu'un design a
# effets fixes de district ait de la puissance, et si l'appariement aux grappes
# NFHS est faisable.
#
# SOURCE. raw/cgwb_quality/repo/data/raw/*.csv : depot GitHub tiers
# (nishant8975/Groundwater-Quality-Intelligence-System-, commit fd934ab), PAS une
# source officielle : exports CGWB / India-WRIS passes par un intermediaire.
# Provenance et SHA256 : raw/README.md. 30 fichiers, en-tete commun de 46
# colonnes. Seule la conductivite (EC, uS/cm) sert de mesure de salinite : le
# TDS des fichiers CGWB en est quasi parfaitement derive (Kri520/GroundWater_
# Quality-in-Rajasthan recommande de le supprimer), et il n'est renseigne que
# sur ~18 % des echantillons d'apres le depot. Il ne sert ici qu'a verifier le
# facteur de conversion.
#
# CONVERSION TDS -> EC. TDS (mg/L) = k x EC (uS/cm a 25 degres C), k entre 0,55
# et 0,75 selon la composition ionique (Hem 1985, USGS WSP 2254). Valeur
# retenue d'avance : k = 0,64, convention courante dans les etudes CGWB et
# hydrochimiques indiennes. Seuil BIS IS 10500 « acceptable » de 500 mg/L ->
# EC = 500 / 0,64 = 781 uS/cm. Limite « permissible » sans autre source :
# 2 000 mg/L -> 3 125 uS/cm (rapporte, pas utilise dans le critere). Le k
# empirique (mediane de TDS/EC la ou les deux existent) est rapporte a titre de
# controle ; il ne modifie pas le seuil du critere.
#
# ATTENTES ENONCEES AVANT VERIFICATION (arret et question si l'une tombe) :
#   E1. 30 fichiers, en-tete identique, 165 162 lignes au total (README du
#       depot). Verifie en dur.
#   E2. Coordonnees valides (dans le cadre de l'Inde, non nulles) >= 99 % des
#       lignes (le depot annonce 165 010 localisations valides).
#   E3. EC renseignee et > 0 sur >= 90 % des lignes.
#   E4. Periode : annees 2000 a 2020 environ ; une mesure par station et par
#       an (echantillonnage pre-mousson), donc au plus une ligne par
#       station-annee dans l'immense majorite des cas.
#   E5. De l'ordre de 15 000 a 25 000 stations ; ~600-700 districts LGD.
#   E6. Grappes NFHS a coordonnees valides : 28 395 (NFHS-4, IAGE71FL) et
#       30 079 (NFHS-5, IAGE7AFL). Verifie en dur.
#   E7. Distance mediane grappe -> station la plus proche ~7 km (une station
#       par ~200 km2 en moyenne) ; ~65 % des grappes avec une station a moins
#       de 10 km. Plus faible la ou le depot n'a pas de fichier (Kerala, Nord-
#       Est).
#
# CRITERE DE PUISSANCE, ECRIT AVANT DE REGARDER LA DECOMPOSITION.
# Unite : la station (station = Etat x code LGD de district x nom de station),
# valeur = moyenne sur ses echantillons de log(EC). District = code LGD.
#   C1. Part intra-district de la variance de log(EC) entre stations >= 0,40.
#       En dessous, un effet fixe de district absorbe l'essentiel de la
#       variation de l'instrument.
#   C2. Un district « passe » s'il a (a) >= 10 stations avec EC, (b) un ecart
#       interquartile de log(EC) >= log(2) = 0,693 (la station du 3e quartile a
#       au moins deux fois la conductivite de celle du 1er ; doubler l'EC fait
#       passer de ~500 a ~1 000 uS/cm, de part et d'autre du seuil BIS), et
#       (c) au moins 20 % de ses stations de chaque cote de 781 uS/cm.
#       Il faut >= 150 districts qui passent, repartis dans >= 10 Etats.
#   C3. La variation intra-district n'est pas du bruit de mesure : la variance
#       intra-station d'une annee a l'autre de log(EC) (stations a >= 2 annees)
#       est < 50 % de la variance intra-district entre stations.
# VERDICT : OUI si C1, C2 et C3 passent. NON si C2 echoue de plus de 10 %
# (moins de 135 districts, ou moins de 10 Etats). LIMITE dans tous les autres
# cas (C2 passe mais C1 ou C3 echoue, ou C2 entre 135 et 149 districts).
#
# LIMITES A CONSIGNER : (1) echantillonnage CGWB annuel en pre-mousson, une
# mesure par an et par station ; (2) coordonnees DHS deplacees au hasard
# (jusqu'a 2 km en ville, 5 km en rural, 1 % des rurales jusqu'a 10 km), ce qui
# plafonne la finesse de l'appariement ; (3) depot intermediaire non officiel ;
# (4) l'argument d'Acharya ci-dessus.
#
# LANCEMENT (racine du depot) :
#     Rscript code/14_piste_i_salinite.R           # reprend
#     Rscript code/14_piste_i_salinite.R --force   # refait tout
# ETAPES RESUMABLES (build/) :
#   1. 14_qualite_brut.rds    empilement des 30 csv (texte), colonne fichier
#   2. 14_qualite.rds         colonnes utiles typees, drapeaux de validite
#   3. 14_dhs_ge.rds          grappes NFHS-4/5 (GE), coordonnees
# Sorties : output/tables/14_*.csv (agregats seulement),
#           output/logs/14_piste_i_salinite.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("14_piste_i_salinite.log"))
msg("ETAPE 14 -- PISTE I : SALINITE DES EAUX SOUTERRAINES (DESCRIPTIF)")
msg("Aucune regression, aucune variable de resultat lue.")

DIR_Q   <- p_raw("cgwb_quality", "repo", "data", "raw")
N_FIC   <- 30L
N_LIGNES_DOC <- 165162L
K_TDS   <- 0.64
SEUIL_EC <- 500 / K_TDS        # 781,25 uS/cm
SEUIL_EC_PERM <- 2000 / K_TDS  # 3 125 uS/cm
N_DHS_DOC <- c(nfhs4 = 28395L, nfhs5 = 30079L)

V_EC  <- "Electric Conductivity (μS/cm)"
V_TDS <- "Total Dissolved Solids (mg/L)"
V_UTILES <- c("Station", "Agency", "State LGD Code", "State", "District LGD Code",
              "District", "Block", "Village", "Latitude", "Longitude",
              "Data Acquisition Time", V_EC, V_TDS)

# Nombre « propre » : vide, "-" ou texte non numerique -> NA, compte a part.
num_ou_na <- function(x) suppressWarnings(as.numeric(x))
non_num <- function(x) !is.na(x) & nzchar(trimws(x)) & trimws(x) != "-" &
  is.na(num_ou_na(x))

# ===========================================================================
hr("1. EMPILEMENT DES 30 CSV")
# ===========================================================================
fics <- sort(list.files(DIR_Q, pattern = "\\.csv$", full.names = TRUE))
check(length(fics) == N_FIC, sprintf("E1 : %d fichiers csv", N_FIC),
      sprintf("observe %d", length(fics)))

f_brut <- p_build("14_qualite_brut.rds")
brut <- stage("etape 1/3 empilement", f_brut, function() {
  l <- lapply(fics, function(f) {
    d <- fread(f, colClasses = "character", encoding = "UTF-8", na.strings = NULL)
    d[, fichier := basename(f)]
    d
  })
  hdr <- lapply(l, function(d) setdiff(names(d), "fichier"))
  check(all(vapply(hdr, identical, logical(1), hdr[[1]])),
        "E1 : en-tete identique dans les 30 fichiers")
  rbindlist(l, use.names = TRUE)
}, after = fics)

check_rows(brut, N_LIGNES_DOC, "E1 : lignes empilees")
check_vars(brut, V_UTILES, "qualite CGWB")

# ===========================================================================
hr("2. INVENTAIRE")
# ===========================================================================
f_q <- p_build("14_qualite.rds")
q <- stage("etape 2/3 typage", f_q, function() {
  d <- brut[, .(fichier, station = trimws(Station), agence = Agency,
                etat_lgd = `State LGD Code`, etat = State,
                dist_lgd = `District LGD Code`, district = District,
                lat_txt = Latitude, lon_txt = Longitude,
                date_txt = `Data Acquisition Time`,
                ec_txt = get(V_EC), tds_txt = get(V_TDS))]
  d[, `:=`(lat = num_ou_na(lat_txt), lon = num_ou_na(lon_txt),
           ec = num_ou_na(ec_txt), tds = num_ou_na(tds_txt))]
  d[, date := as.IDate(as.Date(substr(date_txt, 1, 10), format = "%d-%m-%Y"))]
  d[, annee := year(date)]
  d[, mois := month(date)]
  d[, coord_ok := !is.na(lat) & !is.na(lon) & lat != 0 & lon != 0 &
      lat >= 6 & lat <= 38 & lon >= 68 & lon <= 98]
  d[, ec_ok := !is.na(ec) & ec > 0]
  d
}, after = f_brut)

# Ruptures de format : valeurs non vides qui ne se lisent pas.
msg("Ruptures de format (valeurs non vides illisibles), par fichier :")
rupt <- q[, .(n = .N,
              date_illisible = sum(is.na(date) & nzchar(date_txt)),
              date_vide = sum(!nzchar(date_txt)),
              lat_non_num = sum(non_num(lat_txt)), lon_non_num = sum(non_num(lon_txt)),
              ec_non_num = sum(non_num(ec_txt)), tds_non_num = sum(non_num(tds_txt))),
          by = fichier]
print(rupt[date_illisible + lat_non_num + lon_non_num + ec_non_num + tds_non_num +
             date_vide > 0])
if (rupt[, sum(date_illisible + lat_non_num + lon_non_num + ec_non_num)] > 0) {
  msg("Exemples de valeurs illisibles :")
  print(q[(is.na(date) & nzchar(date_txt)) | non_num(lat_txt) | non_num(lon_txt) |
            non_num(ec_txt), .(fichier, station, date_txt, lat_txt, lon_txt, ec_txt)][1:20])
}
fwrite(rupt, p_tab("14_ruptures_format.csv"))

msg("Formats de date observes (chiffres -> 9) :")
print(q[, .N, by = .(forme = gsub("[0-9]", "9", date_txt))][order(-N)])
msg("Mois d'acquisition (toutes lignes) :")
print(q[, .N, by = mois][order(mois)])
msg("Agences :")
print(q[, .N, by = agence][order(-N)])

# Station : Etat x district LGD x nom. Controle d'unicite des coordonnees.
q[, sta := paste(etat_lgd, dist_lgd, station, sep = "|")]
msg("Codes LGD manquants : Etat ", q[!nzchar(etat_lgd) | etat_lgd == "-", .N],
    ", district ", q[!nzchar(dist_lgd) | dist_lgd == "-", .N])
msg("Noms de station vides : ", q[!nzchar(station) | station == "-", .N])
msg("Etats LGD par fichier (un fichier = un Etat attendu) :")
print(q[, .(n_etats_lgd = uniqueN(etat_lgd), etats = paste(unique(etat), collapse = "/")),
        by = fichier][n_etats_lgd > 1])

inv <- q[, .(lignes = .N, stations = uniqueN(sta), districts = uniqueN(dist_lgd),
             annee_min = min(annee, na.rm = TRUE), annee_max = max(annee, na.rm = TRUE),
             n_annees = uniqueN(annee[!is.na(annee)]),
             part_coord_ok = round(mean(coord_ok), 4),
             part_ec_ok = round(mean(ec_ok), 4),
             part_tds = round(mean(!is.na(tds)), 4)),
         by = .(fichier)][order(fichier)]
print(inv)
fwrite(inv, p_tab("14_inventaire_par_etat.csv"))

tot <- q[, .(lignes = .N, stations = uniqueN(sta), districts = uniqueN(dist_lgd),
             annee_min = min(annee, na.rm = TRUE), annee_max = max(annee, na.rm = TRUE),
             part_coord_ok = mean(coord_ok), part_ec_ok = mean(ec_ok),
             part_tds = mean(!is.na(tds)))]
print(tot)
msg("Lignes par annee :")
print(q[, .N, by = annee][order(annee)])

check(tot$part_coord_ok >= 0.99, "E2 : coordonnees valides >= 99 %",
      sprintf("observe %.4f", tot$part_coord_ok))
check(tot$part_ec_ok >= 0.90, "E3 : EC renseignee >= 90 %",
      sprintf("observe %.4f", tot$part_ec_ok))

# E4 : au plus une ligne par station-annee.
dup_sa <- q[!is.na(annee), .N, by = .(sta, annee)][N > 1]
msg("Station-annees avec plusieurs lignes : ", nrow(dup_sa), " (",
    sum(dup_sa$N), " lignes) sur ", q[!is.na(annee), uniqueN(paste(sta, annee))])

# Coordonnees d'une meme station : dispersion.
disp <- q[coord_ok == TRUE, .(n = .N, dlat = diff(range(lat)), dlon = diff(range(lon))),
          by = sta]
msg("Stations dont les coordonnees varient de plus de 0,01 degre (~1 km) : ",
    disp[dlat > 0.01 | dlon > 0.01, .N], " sur ", nrow(disp))

# EC : valeurs extremes et facteur TDS/EC.
msg("Distribution de l'EC (uS/cm, lignes ec_ok) :")
print(round(quantile(q[ec_ok == TRUE, ec], c(0, .001, .01, .1, .25, .5, .75, .9, .99, .999, 1)), 1))
msg("EC > 50 000 uS/cm (au-dela de l'eau de mer) : ", q[ec_ok & ec > 50000, .N], " lignes")
rat <- q[ec_ok & !is.na(tds) & tds > 0, tds / ec]
msg("Facteur empirique k = TDS/EC (", length(rat), " lignes) : mediane ",
    round(median(rat), 3), ", P10-P90 ", round(quantile(rat, .1), 3), "-",
    round(quantile(rat, .9), 3), "  (k retenu d'avance : ", K_TDS, ")")
msg("Seuil EC retenu : ", round(SEUIL_EC, 1), " uS/cm ; avec k empirique : ",
    round(500 / median(rat), 1), " uS/cm (controle seulement)")

# ===========================================================================
hr("3. VARIATION INTRA-DISTRICT (LE CHIFFRE QUI DECIDE)")
# ===========================================================================
qe <- q[ec_ok == TRUE & nzchar(dist_lgd) & dist_lgd != "-"]
qe[, lec := log(ec)]
qe[, dist := paste(etat_lgd, dist_lgd, sep = "|")]

st <- qe[, .(lec = mean(lec), n_ech = .N, n_annees = uniqueN(annee),
             ec_med = median(ec),
             lat = median(lat[coord_ok]), lon = median(lon[coord_ok])),
         by = .(sta, dist, etat)]
check_unique(st, "sta", "stations")
msg("Stations avec EC : ", nrow(st), " ; districts : ", uniqueN(st$dist))
msg("Echantillons par station :")
print(st[, .N, by = .(n_ech = pmin(n_ech, 10))][order(n_ech)])

decomp <- function(y, g) {
  m <- ave(y, g)
  ss_tot <- sum((y - mean(y))^2)
  ss_in <- sum((y - m)^2)
  c(var_tot = ss_tot / (length(y) - 1), part_intra = ss_in / ss_tot)
}
d_all <- decomp(st$lec, st$dist)
st[, n_dist := .N, by = dist]
d_10 <- st[n_dist >= 10, decomp(lec, dist)]
msg(sprintf("Station, tous districts : variance totale log(EC) = %.3f ; part intra-district = %.3f",
            d_all["var_tot"], d_all["part_intra"]))
msg(sprintf("Station, districts >= 10 stations (%d stations) : variance = %.3f ; part intra = %.3f",
            st[n_dist >= 10, .N], d_10["var_tot"], d_10["part_intra"]))

# Decomposition a trois niveaux sur les echantillons : district / station /
# annee (bruit intra-station).
qe[, m_d := mean(lec), by = dist]
qe[, m_s := mean(lec), by = sta]
ss_tot <- qe[, sum((lec - mean(lec))^2)]
trois <- qe[, c(entre_districts = sum((m_d - mean(lec))^2),
                entre_stations_intra_district = sum((m_s - m_d)^2),
                intra_station = sum((lec - m_s)^2))] / ss_tot
msg("Echantillons : decomposition de la somme des carres de log(EC) :")
print(round(trois, 3))

# C3 : bruit intra-station vs signal intra-district entre stations.
multi <- qe[, if (uniqueN(annee) >= 2) .(v = var(lec), n = .N), by = sta]
v_bruit <- multi[, weighted.mean(v, n - 1)]
v_intra <- st[, .(v = var(lec), n = .N), by = dist][n >= 2, weighted.mean(v, n - 1)]
msg(sprintf("Variance intra-station (annee a annee, %d stations a >= 2 annees) : %.3f",
            nrow(multi), v_bruit))
msg(sprintf("Variance intra-district entre stations (districts >= 2 stations) : %.3f",
            v_intra))
msg(sprintf("Rapport bruit / signal intra-district : %.3f", v_bruit / v_intra))

# Tableau par district.
dt <- st[, .(etat = etat[1], n_stations = .N,
             ec_med = round(exp(median(lec)), 0),
             ec_p25 = round(exp(quantile(lec, .25)), 0),
             ec_p75 = round(exp(quantile(lec, .75)), 0),
             iqr_lec = round(IQR(lec), 3),
             part_sup_seuil = round(mean(exp(lec) > SEUIL_EC), 3),
             part_sup_perm = round(mean(exp(lec) > SEUIL_EC_PERM), 3)),
         by = dist][order(dist)]
dt[, deux_cotes := part_sup_seuil > 0 & part_sup_seuil < 1]
dt[, passe := n_stations >= 10 & iqr_lec >= log(2) &
      pmin(part_sup_seuil, 1 - part_sup_seuil) >= 0.20]
fwrite(dt, p_tab("14_districts_conductivite.csv"))

msg("Districts : ", nrow(dt), " ; avec >= 10 stations : ", dt[n_stations >= 10, .N])
msg("Part des districts avec des stations des deux cotes de ", round(SEUIL_EC),
    " uS/cm : ", round(dt[, mean(deux_cotes)], 3), " (tous) ; ",
    round(dt[n_stations >= 10, mean(deux_cotes)], 3), " (>= 10 stations)")
msg("Ecart interquartile de log(EC) par district (>= 10 stations) :")
print(round(quantile(dt[n_stations >= 10, iqr_lec], c(.1, .25, .5, .75, .9)), 3))
msg("Filtre C2 pas a pas : >= 10 stations ", dt[n_stations >= 10, .N],
    " ; + IQR >= log 2 ", dt[n_stations >= 10 & iqr_lec >= log(2), .N],
    " ; + 20 % de chaque cote ", dt[passe == TRUE, .N])
par_etat <- dt[, .(districts = .N, dix_stations = sum(n_stations >= 10),
                   passent = sum(passe)), by = etat][order(-passent)]
print(par_etat)
fwrite(par_etat, p_tab("14_districts_par_etat.csv"))

# ===========================================================================
hr("4. FAISABILITE DE L'APPARIEMENT AUX GRAPPES NFHS")
# ===========================================================================
f_ge <- c(nfhs4 = p_raw("dhs", "india", "2015", "IAGE71FL", "IAGE71FL.shp"),
          nfhs5 = p_raw("dhs", "india", "2019", "IAGE7AFL", "IAGE7AFL.shp"))
f_dhs <- p_build("14_dhs_ge.rds")
ge <- stage("etape 3/3 grappes DHS", f_dhs, function() {
  rbindlist(lapply(names(f_ge), function(v) {
    g <- sf::st_drop_geometry(sf::st_read(f_ge[[v]], quiet = TRUE))
    check_vars(g, c("DHSCLUST", "URBAN_RURA", "LATNUM", "LONGNUM"), v)
    data.table(vague = v, grappe = g$DHSCLUST, urbain = g$URBAN_RURA,
               lat = g$LATNUM, lon = g$LONGNUM)
  }))
}, after = f_ge)
ge <- ge[!(lat == 0 & lon == 0) & !is.na(lat) & !is.na(lon)]
for (v in names(N_DHS_DOC))
  check(ge[vague == v, .N] == N_DHS_DOC[[v]],
        sprintf("E6 : %s grappes a coordonnees valides == %s", v,
                format(N_DHS_DOC[[v]], big.mark = ",")),
        sprintf("observe %d", ge[vague == v, .N]))

sf::sf_use_s2(TRUE)
st_pts <- sf::st_as_sf(st[!is.na(lat) & !is.na(lon)], coords = c("lon", "lat"),
                       crs = 4326)
msg("Stations avec EC et coordonnees : ", nrow(st_pts))
dist_res <- rbindlist(lapply(names(N_DHS_DOC), function(v) {
  g <- sf::st_as_sf(ge[vague == v], coords = c("lon", "lat"), crs = 4326)
  t0 <- Sys.time()
  i <- sf::st_nearest_feature(g, st_pts)
  d_km <- as.numeric(sf::st_distance(g, st_pts[i, ], by_element = TRUE)) / 1000
  tmsg(v, " : plus proche station calculee (", secs_since(t0), ")")
  data.table(vague = v, urbain = ge[vague == v, urbain], d_km = d_km)
}))
res4 <- dist_res[, .(grappes = .N, d_med_km = round(median(d_km), 2),
                     d_p75_km = round(quantile(d_km, .75), 2),
                     part_10km = round(mean(d_km <= 10), 3),
                     part_5km = round(mean(d_km <= 5), 3)),
                 by = .(vague, urbain)]
res4 <- rbind(res4, dist_res[, .(urbain = "tous", grappes = .N,
                                 d_med_km = round(median(d_km), 2),
                                 d_p75_km = round(quantile(d_km, .75), 2),
                                 part_10km = round(mean(d_km <= 10), 3),
                                 part_5km = round(mean(d_km <= 5), 3)), by = vague])
setorder(res4, vague, urbain)
print(res4)
fwrite(res4, p_tab("14_dhs_distance_station.csv"))
msg("Distances geodesiques (s2, WGS84). Coordonnees DHS deplacees : 2 km en",
    " ville, 5 km en rural (10 km pour 1 % des rurales).")

# ===========================================================================
hr("VERDICT CONTRE LE CRITERE ECRIT D'AVANCE")
# ===========================================================================
n_passe <- dt[passe == TRUE, .N]
n_etats <- dt[passe == TRUE, uniqueN(etat)]
c1 <- d_all["part_intra"] >= 0.40
c2 <- n_passe >= 150 && n_etats >= 10
c3 <- v_bruit / v_intra < 0.50
msg(sprintf("C1 part intra-district = %.3f (seuil 0,40) : %s", d_all["part_intra"],
            if (c1) "PASSE" else "ECHOUE"))
msg(sprintf("C2 districts qui passent = %d dans %d Etats (seuils 150 / 10) : %s",
            n_passe, n_etats, if (c2) "PASSE" else "ECHOUE"))
msg(sprintf("C3 bruit / signal = %.3f (seuil 0,50) : %s", v_bruit / v_intra,
            if (c3) "PASSE" else "ECHOUE"))
verdict <- if (c1 && c2 && c3) "OUI" else
  if (n_passe < 135 || n_etats < 10) "NON" else "LIMITE"
msg("VERDICT : ", verdict)

log_close()
