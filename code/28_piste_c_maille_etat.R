# ---------------------------------------------------------------------------
# 28_piste_c_maille_etat.R -- piste C : la maille « Etat de 1998 x milieu »
#   tient-elle sur les quatre vagues NFHS-2/3/4/5 ?
#   A  correspondance des codes d'Etat entre vagues ; proprete des scissions
#      (2000 : Jharkhand, Chhattisgarh, Uttarakhand ; 2014 : Telangana ;
#      2019 : Ladakh) ; autres discontinuites de frontiere.
#   B  effectifs par cellule Etat de 1998 x milieu x vague : menages,
#      grappes, taux d'adoption du purificateur et IC a 95 %.
#
# DESCRIPTIF SEULEMENT : aucune regression, aucune issue construite.
#
# DONNEES : caches valides build/25_cache_nfhs2.rds, build/24_cache_nfhs{3,4,5}.rds ;
#   table de jugement code/ref/piste_c_etats_1998.csv (vague, code hv024,
#   libelle exact, etat_1998, statut) ; SHRUG : shrid_pc91dist_key,
#   shrid_pc11dist_key, shrid_loc_names, district.gpkg (districts 2011).
#
# ===========================================================================
# ATTENTES (ECRITES AVANT EXECUTION ; arret dur et question si l'une tombe)
# ===========================================================================
#   E1  Table des Etats : chaque code hv024 observe, dans chaque vague, y
#       figure une fois avec son libelle exact, et inversement ; les 26 Etats
#       de 1998 ont des menages dans chacune des quatre vagues ; seules des
#       UT absentes de 1998 sont « hors maille ».
#   E2  Scissions de 2000 (SHRUG, recensements 1991 -> 2011, shrids presents
#       dans les deux cles) : il existe un Etat 1991 dont les shrids vont a
#       {bihar, jharkhand}, un a {madhya pradesh, chhattisgarh}, un a
#       {uttar pradesh, uttarakhand} (destinations >= 1 % des shrids) ; dans
#       ces trois Etats, chaque district de 1991 a >= 99 % de ses shrids dans
#       un seul Etat de 2011 (decoupage en districts entiers).
#       Les AUTRES transferts entre Etats 1991 -> 2011 ne sont pas une
#       attente : ils sont listes comme constats (discontinuites a signaler).
#   E3  Scissions de 2014 et 2019 (districts NFHS-4/5 de code <= 640 =
#       districts du recensement 2011, cf. script 26) : dans chaque vague,
#       un code de district appartient a un seul Etat NFHS ; chaque Etat
#       NFHS correspond a un seul Etat du recensement 2011, sauf « dadra &
#       nagar haveli and daman & diu » (NFHS-5, deux UT fusionnees) ; le
#       Telangana a le meme Etat 2011 que l'Andhra Pradesh, le Ladakh le meme
#       que le Jammu-et-Cachemire ; deux Etats NFHS distincts n'ont sinon
#       jamais le meme Etat 2011.
#   E4  NFHS-3 et NFHS-5 : un meme Etat (nom normalise) a le meme code hv024.
#
# SEUIL D'EFFECTIF (ECRIT AVANT EXECUTION)
#   Une cellule Etat x milieu x vague est EXPLOITABLE si elle compte au moins
#   300 menages a reponse renseignee ET au moins 15 grappes. Raison : avec un
#   taux de 10 % et un effet de plan de 2 a 3, 300 menages donnent une
#   erreur-type de 2,5 a 3 points (IC d'environ +/- 5 points) ; 15 grappes
#   evitent qu'une poignee de quartiers fasse le taux.
#   Un Etat est UTILISABLE pour la piste (urbaine) si sa cellule URBAINE est
#   exploitable dans les QUATRE vagues. La maille Etat TIENT si au moins 20
#   des 26 Etats de 1998 sont utilisables ; sinon elle est trop mince. Le
#   seuil de 20 est un jugement (assez d'unites pour une variation entre
#   Etats), pas un calcul.
#
# REGLES DECIDEES AVANT EXECUTION
#   Poids : 1998 = shv005 (poids d'Etat ; nhv005 est nul au Tripura) ;
#   2005-2021 = hv005 (les Etats regroupes melangent deux Etats : poids
#   national). Purificateur : 1998 sh32e ; 2005+ hv237h avec la regle du
#   script 24 (0 si hv237 = 0). Grappe = (hv024, hv021) [hv001 si hv021 ne
#   varie pas], strate = (hv024, hv022), dans chaque vague.
#
# LANCEMENT (racine du depot) : Rscript code/28_piste_c_maille_etat.R
# Sorties : output/tables/28_*.csv (+ .tex) ; output/logs/28_piste_c_maille_etat.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("28_piste_c_maille_etat.log"))
msg("ETAPE 28 -- PISTE C : MAILLE ETAT DE 1998 x MILIEU, QUATRE VAGUES")
msg("Descriptif seulement : aucune regression, aucune issue construite.")

hr("Decisions de Valentine consignees (06/10), avant execution")
msg("1. Le recul a 1998 TIENT pour la serie urbaine. Le critere du point 1 (script 26)")
msg("   a echoue sur une premisse posee par Valentine et fausse : l'ecart de 7,7 points")
msg("   etait non pondere ; pondere, il est nul en ville (49,6 % contre 49,0 %). On ne")
msg("   peut pas decomposer un ecart inexistant : le verdict FAUSSE ne porte aucune")
msg("   information sur les donnees. Le national (ecart de 2,8 points) n'est pas le")
msg("   terrain de la piste, qui est urbaine.")
msg("   CRITERE MAL SPECIFIE PAR VALENTINE -- deuxieme fois sur cette piste, apres le")
msg("   repere 16,7 % / 3,3 % de l'attente A4 du script 24. Memo : memo/piste_c_recul_1998.md.")
msg("2. Codes ambigus de hv201 tranches : « piped to neighbor » (NFHS-5, 13) cote reseau,")
msg("   variante hors reseau ; usine RO communautaire (NFHS-4 72, NFHS-5 92) hors reseau,")
msg("   variante menages exclus. Table : code/ref/piste_c_hv201_reseau.csv.")

CACHES <- c(nfhs2 = p_build("25_cache_nfhs2.rds"), nfhs3 = p_build("24_cache_nfhs3.rds"),
            nfhs4 = p_build("24_cache_nfhs4.rds"), nfhs5 = p_build("24_cache_nfhs5.rds"))
PERIODES <- c(nfhs2 = "1998-99", nfhs3 = "2005-06", nfhs4 = "2015-16", nfhs5 = "2019-21")
F_ETATS <- file.path("code", "ref", "piste_c_etats_1998.csv")
F_K91 <- p_raw("shrug", "shrug-pc-keys-dta", "shrid_pc91dist_key.dta")
F_K11 <- p_raw("shrug", "shrug-pc-keys-dta", "shrid_pc11dist_key.dta")
F_NOMS <- p_raw("shrug", "shrug-shrid-keys-dta", "shrid_loc_names.dta")
F_D11 <- p_raw("shrug", "shrug-pc11dist-poly-gpkg", "district.gpkg")

N_MIN <- 300L; G_MIN <- 15L; ETATS_MIN <- 20L
SCISSIONS_2000 <- list(c("bihar", "jharkhand"), c("madhya pradesh", "chhattisgarh"),
                       c("uttar pradesh", "uttarakhand"))
SEUIL_DEST <- 0.01; SEUIL_DISTRICT <- 0.99

num <- function(x) as.numeric(haven::zap_labels(x))
etiquettes <- function(x) {
  l <- attr(x, "labels", exact = TRUE)
  data.table(code = as.numeric(l), libelle = names(l))
}
norm_etat <- function(x) {
  x <- tolower(trimws(sub("^\\[..\\] ", "", x)))
  x <- gsub("&", "and", x); x <- sub("^nct of ", "", x)
  x <- sub("^uttaranchal$", "uttarakhand", x); x <- sub("^orissa$", "odisha", x)
  gsub("\\s+", " ", x)
}

hr("Attentes et seuil ecrits avant execution")
msg("E1 table des Etats complete ; E2 scissions 2000 en districts entiers (SHRUG) ;")
msg("E3 Telangana / Ladakh dans un seul Etat 2011 avec leur Etat d'origine ; E4 codes NFHS-3 = NFHS-5.")
msg("Cellule exploitable : >= ", N_MIN, " menages ET >= ", G_MIN, " grappes. Etat utilisable :")
msg("cellule urbaine exploitable aux 4 vagues. Maille Etat TIENT si >= ", ETATS_MIN, " Etats sur 26.")

caches <- lapply(CACHES, function(f) { check(file.exists(f), paste("cache present :", f)); readRDS(f)$d })

# ===========================================================================
hr("A1. Table de correspondance des Etats (E1)")
# ===========================================================================

ref <- fread(F_ETATS, colClasses = list(character = c("libelle", "etat_1998", "statut")))
check_vars(ref, c("vague", "code", "libelle", "etat_1998", "statut"), "table des Etats")
check_unique(ref, c("vague", "code"), "table des Etats")
ref[, code := as.numeric(code)]
etats98 <- ref[vague == "nfhs2", sort(unique(etat_1998))]
check(length(etats98) == 26L, "26 Etats de 1998 dans la table", paste(length(etats98)))
for (v in names(CACHES)) {
  x <- caches[[v]]$hv024
  e <- etiquettes(x)[code %in% unique(num(x))]
  r <- ref[vague == v]
  m <- merge(e, r[, .(code, libelle_ref = libelle)], by = "code", all = TRUE)
  ko <- m[is.na(libelle) | is.na(libelle_ref) | libelle != libelle_ref]
  if (nrow(ko)) print(ko, row.names = FALSE)
  check(nrow(ko) == 0L, sprintf("E1 %s : %d codes hv024 observes = table, libelles exacts", v, nrow(e)))
  check(setequal(r[nzchar(etat_1998), unique(etat_1998)], etats98),
        sprintf("E1 %s : les 26 Etats de 1998 presents", v))
  check(all(grepl("^hors maille 1998 \\(UT", r[!nzchar(etat_1998), statut])),
        sprintf("E1 %s : seules des UT sont hors maille", v))
}
msg("Statuts par vague :")
print(dcast(ref[, .N, by = .(vague, statut = sub(" \\(.*$| ;.*$", "", statut))], statut ~ vague,
            value.var = "N", fill = 0), row.names = FALSE)

# ===========================================================================
hr("A2. NFHS-3 et NFHS-5 : memes codes pour un meme Etat (E4)")
# ===========================================================================

c3 <- ref[vague == "nfhs3", .(nom = norm_etat(libelle), code3 = code)]
c5 <- ref[vague == "nfhs5", .(nom = norm_etat(libelle), code5 = code)]
c35 <- merge(c3, c5, by = "nom", all.x = TRUE)
print(c35[is.na(code5) | code3 != code5], row.names = FALSE)
check(!anyNA(c35$code5) && all(c35$code3 == c35$code5),
      sprintf("E4 les %d Etats du NFHS-3 ont le meme code hv024 en NFHS-5", nrow(c3)))
msg("Codes NFHS-2 (propres a la vague) et NFHS-4 (ordre alphabetique) : raccord par nom seulement.")

# ===========================================================================
hr("A3. Scissions de 2000 et autres transferts 1991 -> 2011 (SHRUG) (E2)")
# ===========================================================================

k91 <- as.data.table(haven::read_dta(F_K91))
k11 <- as.data.table(haven::read_dta(F_K11))
noms <- as.data.table(haven::read_dta(F_NOMS, col_select = c("shrid2", "state_name")))
check_unique(k91, "shrid2", "shrid_pc91dist_key"); check_unique(k11, "shrid2", "shrid_pc11dist_key")
kk <- merge(k91, k11, by = "shrid2")
msg("shrids : pc91 ", nrow(k91), " ; pc11 ", nrow(k11), " ; presents dans les deux ", nrow(kk),
    " (", round(100 * nrow(kk) / nrow(k91), 1), " % des shrids pc91)")
nom11 <- merge(k11[, .(shrid2, pc11_state_id)], noms, by = "shrid2")[
  , .N, by = .(pc11_state_id, state_name)][order(-N)][, .SD[1], by = pc11_state_id]
nom11[, nom := norm_etat(state_name)]
check_unique(nom11, "nom", "noms des Etats 2011 (SHRUG)")
kk <- merge(kk, nom11[, .(pc11_state_id, nom11 = nom)], by = "pc11_state_id")
msg("Etats 1991 dans SHRUG : ", uniqueN(kk$pc91_state_id), " ; Etats 2011 : ", uniqueN(kk$pc11_state_id),
    " (le recensement de 1991 n'a pas eu lieu au Jammu-et-Cachemire)")

flux <- kk[, .N, by = .(pc91_state_id, nom11)][, part := N / sum(N), by = pc91_state_id]
dest <- flux[part >= SEUIL_DEST, .(destinations = paste(sort(nom11), collapse = " + "),
                                   n_dest = .N), by = pc91_state_id]
mineurs <- flux[part < SEUIL_DEST]
msg("Etats 1991 a plusieurs destinations 2011 (>= 1 % des shrids) :")
print(dest[n_dest > 1], row.names = FALSE)
for (s in SCISSIONS_2000) {
  cible <- paste(sort(s), collapse = " + ")
  sid <- dest[destinations == cible, pc91_state_id]
  check(length(sid) == 1L, paste("E2 un Etat 1991 se partage en", cible))
  pd <- kk[pc91_state_id == sid, .N, by = .(pc91_district_id, nom11)][
    , part := N / sum(N), by = pc91_district_id][, .(max_part = max(part), n_shrids = sum(N)), by = pc91_district_id]
  msg("  ", cible, " : ", nrow(pd), " districts de 1991 ; part minimale dans un seul Etat 2011 = ",
      round(100 * min(pd$max_part), 2), " %")
  check(all(pd$max_part >= SEUIL_DISTRICT), paste("E2", cible, ": chaque district 1991 >= 99 % dans un seul Etat 2011"))
}
autres <- dest[n_dest > 1 & !destinations %in% vapply(SCISSIONS_2000, function(s) paste(sort(s), collapse = " + "), "")]
msg("CONSTAT -- autres Etats 1991 a plusieurs destinations (>= 1 %) : ",
    if (nrow(autres)) paste(autres$destinations, collapse = " ; ") else "aucun")
msg("CONSTAT -- flux mineurs (< 1 % des shrids d'un Etat 1991, bruit de rattachement ou transfert local) :")
mineurs <- merge(mineurs, flux[, .SD[which.max(part)], by = pc91_state_id][, .(pc91_state_id, origine = nom11)],
                 by = "pc91_state_id")
print(mineurs[order(-N), .(origine_principale_1991 = origine, vers_2011 = nom11, shrids = N,
                           part = round(100 * part, 3))], row.names = FALSE)
fwrite(flux[, .(pc91_state_id, nom11, shrids = N, part)], p_tab("28_A_shrug_flux_etats_1991_2011.csv"))

# ===========================================================================
hr("A4. Scissions de 2014 et 2019 : districts NFHS-4/5 -> Etats 2011 (E3)")
# ===========================================================================

d11 <- as.data.table(sf::st_drop_geometry(sf::st_read(F_D11, quiet = TRUE)))
d11[, `:=`(code_dist = as.numeric(pc11_district_id), etat11 = as.numeric(pc11_state_id))]
d11 <- merge(d11, nom11[, .(etat11 = as.numeric(pc11_state_id), nom11 = nom)], by = "etat11", all.x = TRUE)
corr <- list()
for (v in c("nfhs4", "nfhs5")) {
  x <- caches[[v]]; vd <- intersect(c("shdistri", "shdist"), names(x))
  t <- unique(data.table(code = num(x$hv024), code_dist = num(x[[vd]])))
  check(!anyDuplicated(t$code_dist), sprintf("E3 %s : chaque district dans un seul Etat NFHS", v))
  t <- merge(t, ref[vague == v, .(code, libelle, etat_1998)], by = "code")
  t <- merge(t, d11[, .(code_dist, etat11, nom11)], by = "code_dist", all.x = TRUE)
  s <- t[, .(districts = .N, districts_hors_2011 = sum(is.na(etat11)),
             etats_2011 = paste(sort(unique(na.omit(nom11))), collapse = " + "),
             n_etats_2011 = uniqueN(na.omit(etat11))), by = .(code, libelle, etat_1998)]
  s[, vague := v]; corr[[v]] <- s
  print(s[order(code)], row.names = FALSE)
  multi <- s[n_etats_2011 > 1, libelle]
  check(setequal(multi, if (v == "nfhs5") "dadra & nagar haveli and daman & diu" else character()),
        sprintf("E3 %s : un seul Etat 2011 par Etat NFHS (sauf DNH-DD fusionnes)", v),
        paste(multi, collapse = ", "))
  et <- function(l) s[libelle == l, etats_2011]
  check(et("telangana") == et("andhra pradesh"), sprintf("E3 %s : Telangana dans l'Etat 2011 de l'Andhra Pradesh (%s)", v, et("telangana")))
  if (v == "nfhs5") check(et("ladakh") == et("jammu & kashmir"),
                          sprintf("E3 nfhs5 : Ladakh dans l'Etat 2011 du Jammu-et-Cachemire (%s)", et("ladakh")))
  appar <- c("telangana", "andhra pradesh", "ladakh", "jammu & kashmir")
  dbl <- s[n_etats_2011 == 1 & !libelle %in% appar, .N, by = etats_2011][N > 1]
  check(nrow(dbl) == 0L, sprintf("E3 %s : deux Etats NFHS distincts n'ont pas le meme Etat 2011 (hors paires attendues)", v),
        paste(dbl$etats_2011, collapse = ", "))
}
fwrite(rbindlist(corr), p_tab("28_A_nfhs45_etats_vers_2011.csv"))
msg("Les districts NFHS-5 de code > 640 (nouveaux depuis 2011) n'ont pas d'Etat 2011 verifiable ;")
msg("ils sont rattaches par hv024 (colonne districts_hors_2011).")

# ===========================================================================
hr("B. Cellules Etat de 1998 x milieu x vague : effectifs et purificateur")
# ===========================================================================

taux_pondere <- function(w, strate, psu, y) {
  ok <- !is.na(y) & !is.na(w) & w > 0
  if (!any(ok)) return(data.table(menages = 0L, grappes = 0L, taux = NA_real_, se = NA_real_))
  w <- w[ok]; y <- y[ok]; strate <- strate[ok]; psu <- psu[ok]
  W <- sum(w); r <- sum(w * y) / W
  tt <- data.table(s = strate, p = psu, z = w * (y - r) / W)[, .(z = sum(z)), by = .(s, p)]
  v  <- tt[, .(nh = .N, ss = sum((z - mean(z))^2)), by = s][nh > 1, sum(nh / (nh - 1) * ss)]
  data.table(menages = length(y), grappes = uniqueN(paste(strate, psu)), taux = r, se = sqrt(v))
}

menages <- rbindlist(lapply(names(CACHES), function(v) {
  d <- caches[[v]]
  etat <- num(d$hv024)
  if (v == "nfhs2") {
    w <- num(d$shv005) / 1e6
    y <- fifelse(num(d$sh32e) %in% c(0, 1), num(d$sh32e), NA_real_)
  } else {
    w <- num(d$hv005) / 1e6
    t <- num(d$hv237); h <- num(d$hv237h)
    y <- fifelse(t == 0, 0, fifelse(t == 1 & h %in% c(0, 1), h, NA_real_))
  }
  psu0 <- if (uniqueN(num(d$hv021)) > 1L) num(d$hv021) else num(d$hv001)
  data.table(vague = v, code = etat, urbain = num(d$hv025) == 1, w = w,
             strate = paste(etat, num(d$hv022)), psu = paste(etat, psu0), y = y)
}))
menages <- merge(menages, ref[, .(vague, code, etat_1998)], by = c("vague", "code"), all.x = TRUE)
check(!anyNA(menages$etat_1998), "chaque menage a un Etat dans la table")
hors <- menages[!nzchar(etat_1998), .N, by = vague]
msg("Menages hors maille 1998 (UT) : ", if (nrow(hors)) paste(hors$vague, hors$N, sep = " = ", collapse = " ; ") else "aucun")
menages <- menages[nzchar(etat_1998)]
menages[, milieu := fifelse(urbain, "urbain", "rural")]

cellules <- menages[, taux_pondere(w, strate, psu, y), by = .(etat_1998, milieu, vague)]
# Grille complete : une cellule sans aucun menage compte comme non exploitable.
grille <- CJ(etat_1998 = etats98, milieu = c("rural", "urbain"), vague = names(CACHES))
cellules <- merge(grille, cellules, by = c("etat_1998", "milieu", "vague"), all.x = TRUE)
msg("Cellules sans aucun menage : ", cellules[is.na(menages), .N],
    if (cellules[is.na(menages), .N]) paste0(" (", cellules[is.na(menages), paste(etat_1998, milieu, vague, collapse = " ; ")], ")") else "")
cellules[is.na(menages), `:=`(menages = 0L, grappes = 0L)]
cellules[, periode := PERIODES[vague]]
cellules[, `:=`(pct = 100 * taux, ic_bas = 100 * (taux - 1.96 * se), ic_haut = 100 * (taux + 1.96 * se))]
cellules[, exploitable := menages >= N_MIN & grappes >= G_MIN]
setorder(cellules, milieu, etat_1998, vague)
check(nrow(cellules) == 26L * 2L * 4L, "grille de 208 cellules (26 Etats x 2 milieux x 4 vagues)")
fwrite(cellules, p_tab("28_B_cellules_etat_milieu_vague.csv"))

msg("Cellules URBAINES : menages / grappes / purificateur % [IC]")
u <- cellules[milieu == "urbain"]
u[, txt := sprintf("%5d / %3d / %5.1f [%4.1f;%4.1f]%s", menages, grappes, pct, ic_bas, ic_haut,
                   fifelse(exploitable, "", " *"))]
print(dcast(u, etat_1998 ~ periode, value.var = "txt"), row.names = FALSE)
msg("(* = sous le seuil : < ", N_MIN, " menages ou < ", G_MIN, " grappes)")
msg("Cellules RURALES : menages / grappes")
r <- cellules[milieu == "rural"]
r[, txt := sprintf("%5d / %3d%s", menages, grappes, fifelse(exploitable, "", " *"))]
print(dcast(r, etat_1998 ~ periode, value.var = "txt"), row.names = FALSE)

passe <- cellules[, .(cellules = .N, exploitables = sum(exploitable)), by = .(milieu, periode)]
print(dcast(passe, milieu ~ periode, value.var = "exploitables"), row.names = FALSE)
fwrite(passe, p_tab("28_B_cellules_exploitables.csv"))
msg("Total : ", sum(cellules$exploitable), " cellules exploitables sur ", nrow(cellules),
    " ; urbaines : ", sum(u$exploitable), " sur ", nrow(u))

etats_ok <- u[, .(vagues_ok = sum(exploitable), menages_min = min(menages), grappes_min = min(grappes),
                  vague_limitante = periode[which.min(menages)]), by = etat_1998]
etats_ok[, utilisable := vagues_ok == 4L]
setorder(etats_ok, -utilisable, -menages_min)
print(etats_ok, row.names = FALSE)
fwrite(etats_ok, p_tab("28_B_etats_utilisables.csv"))
n_ok <- sum(etats_ok$utilisable)
verdict <- if (n_ok >= ETATS_MIN) "TIENT" else "TROP MINCE"
msg("Etats utilisables (cellule urbaine exploitable aux 4 vagues) : ", n_ok, " sur 26")
msg("VERDICT MAILLE ETAT (seuil ecrit avant execution, >= ", ETATS_MIN, " Etats) : ", verdict)
fwrite(data.table(etats_utilisables = n_ok, seuil = ETATS_MIN, verdict = verdict), p_tab("28_B_verdict.csv"))

# Table de presentation : urbain, menages et purificateur par Etat et vague.
tex <- dcast(u, etat_1998 ~ periode, value.var = c("menages", "pct"))
setcolorder(tex, c("etat_1998", as.vector(t(outer(c("menages_", "pct_"), PERIODES, paste0)))))
fmt <- function(x) if (is.integer(x)) formatC(x, format = "d", big.mark = ",") else
  if (is.numeric(x)) formatC(x, format = "f", digits = 1) else x
corps <- apply(as.data.frame(lapply(tex, fmt)), 1, paste, collapse = " & ")
writeLines(c("\\begin{tabular}{l*{8}{r}}", "\\toprule",
             paste("Etat (1998)", paste(sprintf("& \\multicolumn{2}{c}{%s}", PERIODES), collapse = " "), "\\\\"),
             paste("", paste(rep("& menages & \\%", 4), collapse = " "), "\\\\"), "\\midrule",
             paste(corps, "\\\\"), "\\bottomrule", "\\end{tabular}"), p_tab("28_B_urbain_etat_vague.tex"))

hr("Limites a consigner")
msg("- la correspondance des Etats est un codage de jugement (code/ref/piste_c_etats_1998.csv) ;")
msg("- 1998 : libelle « jammu » ; le recensement de 1991 n'a pas couvert le Jammu-et-Cachemire,")
msg("  la frontiere de cet Etat n'est donc pas verifiable par SHRUG ;")
msg("- transferts infra-district (ex. mandals du Khammam passes a l'AP en 2014) invisibles a")
msg("  la maille district ; absorbes ici par le regroupement AP + Telangana.")

log_close()
