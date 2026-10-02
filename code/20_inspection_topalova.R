# ---------------------------------------------------------------------------
# 20_inspection_topalova.R -- Piste G (liberalisation tarifaire de 1991 comme
#   decaleur du prix des groupes electrogenes), verrou 0 : INSPECTION du paquet
#   de replication Topalova (2010, AEJ: Applied 2(4), "Factor Immobility and
#   Regional Impacts of Trade Liberalization: Evidence from India").
#
# PORTEE : inventaire seulement. Aucune variable d'issue n'est analysee, aucune
# regression, aucun fichier build/. On lit les .dta, on decrit, on cherche.
#
# SOURCE : raw/topalova2010/113765-V1/_data/*.dta (openICPSR 113765 V1 ;
#   le brief citait aeaweb.org .../2008-0030_data.zip -- meme depot AEA, autre
#   nom de paquet). Lecture directe par haven (etiquettes conservees) ; pas de
#   passage par build/*.rds.
#
# ATTENTES (ecrites AVANT la premiere lecture des donnees) :
#   A0  les 8 .dta du Readme sont presents et lisibles.
#   A1  aucun code produit a 6 chiffres (HS6) ; tarifs seulement agreges :
#       district/region NSS (rural, rural_region, urban), industrie NIC 1987
#       (asi), article WPI (price). Signal automatique = nom/etiquette en
#       hs/harmon/itc, ou colonne entierement composee d'entiers a 6 chiffres ;
#       tout signal est relu a la main avant d'etre declare.
#   A2  price_data : cle (article, annee) unique ; indice de prix ET tarif
#       article par article ; etiquette texte par article ; <= 447 articles
#       (base WPI 1981-82) ; annees ~1987-2001. Sans etiquette : ARRET.
#   A3  asi_data : pas de variable electricite ni combustible (prediction).
#
# AMENDEMENT A2 (decision PI, 2026-10-02, APRES echec constate) : l'attente
#   « une etiquette par article » est tombee -- 52 des 368 code80 (832 lignes)
#   ont item80 vide. Ces 52 codes n'ont AUCUN indice de prix (tarif seulement).
#   Critere restreint accepte par le PI : « chaque code qui porte un indice de
#   prix a une description ». Le constat d'origine reste journalise ci-dessous.
#
# LANCEMENT (racine du depot ; quelques secondes) :
#     Rscript code/20_inspection_topalova.R
#
# Sorties : output/tables/20_inventaire_topalova.csv
#           output/logs/20_inspection_topalova.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("20_inspection_topalova.log"))
on.exit(log_close(), add = TRUE)
suppressWarnings(suppressMessages(library(haven)))

dir_tp <- p_raw("topalova2010", "113765-V1", "_data")

# --- A0 : presence des huit fichiers --------------------------------------
hr("A0 -- presence des huit .dta")
attendus <- c("rural_data", "rural_region_data", "urban_data", "price_data",
              "migration_data", "indpremia_data", "asi_data", "agriwage_data")
trouves <- sub("\\.dta$", "", list.files(dir_tp, pattern = "\\.dta$"))
note("trouves : ", paste(trouves, collapse = ", "))
check(setequal(tolower(trouves), attendus), "A0 : les 8 .dta du Readme, ni plus ni moins",
      paste("ecart :", paste(c(setdiff(attendus, tolower(trouves)),
                                 setdiff(tolower(trouves), attendus)), collapse = ", ")))

# --- Etape 1 : inventaire --------------------------------------------------
hr("Etape 1 -- inventaire des huit .dta")
# Variables temporelles reconnues par leur nom ; la plage est rapportee telle
# quelle (annees civiles, annees fiscales ou rounds NSS selon le fichier).
re_temps <- "^(year|yr|round|annee|fy)$|year$|^year"
re_hs    <- "(^|_)hs|harmon|itc"
six_chiffres <- function(x) {
  if (is.character(x)) { v <- x[!is.na(x) & nzchar(x)]; return(length(v) > 0 && all(grepl("^[0-9]{6}$", v))) }
  if (!is.numeric(x)) return(FALSE)
  v <- x[!is.na(x)]
  length(v) > 0 && all(v == round(v)) && all(v >= 100000 & v <= 999999)
}

dats <- list()
inv <- rbindlist(lapply(sort(trouves), function(f) {
  t0 <- Sys.time()
  d <- read_dta(file.path(dir_tp, paste0(f, ".dta")))
  dats[[f]] <<- d
  vt <- grep(re_temps, names(d), value = TRUE, ignore.case = TRUE)
  plage <- if (length(vt)) paste(sapply(vt, function(v) {
    u <- sort(unique(as.numeric(d[[v]]))); u <- u[!is.na(u)]
    sprintf("%s: %s (%d valeurs)", v, if (length(u) <= 12) paste(u, collapse = ",")
            else paste0(min(u), "-", max(u)), length(u)) }), collapse = " ; ") else "aucune variable temporelle reconnue"
  tmsg(sprintf("%-18s %9s x %3d  | temps : %s  (%s)", f, format(nrow(d), big.mark = ","),
               ncol(d), plage, secs_since(t0)))
  rbindlist(lapply(names(d), function(v) {
    x <- d[[v]]; lab <- attr(x, "label") %||% ""
    num <- is.numeric(x)
    data.table(fichier = f, n_lignes = nrow(d), n_vars = ncol(d), plage_temps = plage,
               variable = v, etiquette = lab,
               classe = paste(class(x), collapse = "/"),
               etiq_valeurs = length(attr(x, "labels")),
               n_non_manq = sum(!is.na(x)), n_distinct = uniqueN(x),
               min = if (num && any(!is.na(x))) signif(min(x, na.rm = TRUE), 6) else NA_real_,
               max = if (num && any(!is.na(x))) signif(max(x, na.rm = TRUE), 6) else NA_real_,
               signal_hs_nom = grepl(re_hs, v, ignore.case = TRUE) | grepl(re_hs, lab, ignore.case = TRUE),
               signal_6chiffres = six_chiffres(x),
               mentionne_tarif = grepl("tar", v, ignore.case = TRUE) | grepl("tar", lab, ignore.case = TRUE))
  }))
}))
fwrite(inv, p_tab("20_inventaire_topalova.csv"))
note("table ecrite : ", p_tab("20_inventaire_topalova.csv"), " (", nrow(inv), " lignes = variables)")

hr("Etape 1 -- variables et etiquettes, fichier par fichier")
for (f in sort(trouves)) {
  cat("\n## ", f, "\n", sep = "")
  s <- inv[fichier == f]
  for (i in seq_len(nrow(s)))
    cat(sprintf("  %-22s %-14s n=%-7d dist=%-6d [%s, %s]  %s\n", s$variable[i], s$classe[i],
                s$n_non_manq[i], s$n_distinct[i], format(s$min[i]), format(s$max[i]), s$etiquette[i]))
}

hr("A1 -- signaux HS6 et niveau d'agregation des tarifs")
sig <- inv[signal_hs_nom | signal_6chiffres]
if (nrow(sig)) { note("SIGNAUX A RELIRE A LA MAIN :"); print(sig[, .(fichier, variable, etiquette, classe, min, max, signal_hs_nom, signal_6chiffres)]) } else note("aucun signal HS (nom, etiquette, valeurs a 6 chiffres)")
note("variables qui mentionnent un tarif :")
print(inv[mentionne_tarif == TRUE, .(fichier, variable, etiquette, n_non_manq)])

# --- Etape 2 : price_data, le point decisif --------------------------------
hr("Etape 2 -- price_data : articles WPI x annee")
pr <- as.data.table(zap_labels(dats[["price_data"]]))
check_vars(pr, c("code80", "year", "item80", "priceindex", "logfiscprice", "tariff", "lagtariff"), "price_data")
check_unique(pr, c("code80", "year"), "A2 price_data")
sans_desc <- pr[!nzchar(trimws(item80))]
warn(sprintf("A2 d'origine TOMBEE : %d lignes (%d codes) sans description ; voir AMENDEMENT A2 en en-tete",
             nrow(sans_desc), uniqueN(sans_desc$code80)))
note(sprintf("codes sans description : %d avec un indice de prix, %d avec un tarif",
             sans_desc[!is.na(priceindex), uniqueN(code80)], sans_desc[!is.na(tariff), uniqueN(code80)]))
check(sum(!is.na(sans_desc$priceindex)) == 0,
      "A2 amendee : chaque code qui porte un indice de prix a une description",
      sprintf("%d lignes avec prix mais sans description", sum(!is.na(sans_desc$priceindex))))
n_lab <- pr[, uniqueN(item80), by = code80][V1 > 1]  # vide constant par code, verifie
check(nrow(n_lab) == 0, "A2 : une seule description par code80 sur toutes les annees",
      sprintf("%d codes a descriptions multiples", nrow(n_lab)))
check(uniqueN(pr$code80) <= 447, "A2 : nombre d'articles <= 447 (panier WPI 1981-82)",
      sprintf("observe %d", uniqueN(pr$code80)))

arts <- pr[, .(item80 = item80[1],
               ans_prix   = if (any(!is.na(priceindex))) paste0(min(year[!is.na(priceindex)]), "-", max(year[!is.na(priceindex)])) else "",
               n_prix     = sum(!is.na(priceindex)),
               ans_tarif  = if (any(!is.na(tariff))) paste0(min(year[!is.na(tariff)]), "-", max(year[!is.na(tariff)])) else "",
               n_tarif    = sum(!is.na(tariff)),
               n_les_deux = sum(!is.na(priceindex) & !is.na(tariff))), by = code80][order(code80)]
arts[, code80 := sprintf("%.0f", code80)]
# Description partagee par plusieurs codes : signalee, pas resolue.
arts[, n_codes_meme_desc := .N, by = item80]
arts[!nzchar(trimws(item80)), `:=`(item80 = "(sans description -- tarif seul)", n_codes_meme_desc = 1L)]
note(sprintf("%d articles (code80), %d descriptions distinctes ; annees %d-%d",
             nrow(arts), uniqueN(arts$item80), min(pr$year), max(pr$year)))
note(sprintf("articles avec prix ET tarif la meme annee au moins une fois : %d ; avec prix seulement : %d ; tarif seulement : %d ; aucun des deux : %d",
             sum(arts$n_les_deux > 0), sum(arts$n_prix > 0 & arts$n_tarif == 0),
             sum(arts$n_prix == 0 & arts$n_tarif > 0), sum(arts$n_prix == 0 & arts$n_tarif == 0)))
note("couverture par annee (articles avec prix / avec tarif) :")
print(pr[, .(avec_prix = sum(!is.na(priceindex)), avec_tarif = sum(!is.na(tariff)),
             avec_logfisc = sum(!is.na(logfiscprice))), by = year][order(year)])
fwrite(arts, p_tab("20_price_articles_wpi.csv"))
note("liste complete ecrite : ", p_tab("20_price_articles_wpi.csv"))
hr("Etape 2 -- liste complete des articles (code80 | annees prix | annees tarif | description)")
for (i in seq_len(nrow(arts)))
  cat(sprintf("  %s | %-9s | %-9s | %s%s\n", arts$code80[i], arts$ans_prix[i], arts$ans_tarif[i],
              arts$item80[i], if (arts$n_codes_meme_desc[i] > 1) sprintf("  [desc. partagee x%d]", arts$n_codes_meme_desc[i]) else ""))

hr("Etape 2 -- recherche large : groupe electrogene, moteur diesel, alternateur, machine electrique")
re_cible <- paste0("generat|gen\\.? ?set|genset|diesel|engine|eng\\.|alternat|dynamo|motor|",
                   "electr|elec\\.|elect\\b|prime mover|\\bi\\.? ?c\\.?\\b|oil eng|turbine|pump|",
                   "transformer|switch|battery|cable|wire|machin|mach\\.|power|starter|armature")
hits <- arts[grepl(re_cible, item80, ignore.case = TRUE)]
note(sprintf("%d articles repondent au motif large", nrow(hits)))
for (i in seq_len(nrow(hits)))
  cat(sprintf("  %s | prix %-9s | tarif %-9s | %s\n", hits$code80[i], hits$ans_prix[i], hits$ans_tarif[i], hits$item80[i]))
# Voisinage hierarchique : les articles du meme groupe (6 premiers chiffres du
# code80) que chaque reponse, pour voir ce que la nomenclature range a cote.
grp <- unique(substr(hits$code80, 1, 6))
note("articles des memes groupes (6 premiers chiffres de code80) :")
vois <- arts[substr(code80, 1, 6) %in% grp & !code80 %in% hits$code80]
for (i in seq_len(nrow(vois))) cat(sprintf("  %s | %s\n", vois$code80[i], vois$item80[i]))

# Cibles retenues a la main apres relecture de la recherche (2026-10-02) :
# aucun article « groupe electrogene » ; « Diesel Engines » est la cible
# directe ; « internal combustion engines » est son voisin immediat (meme
# groupe 13110101) et peut recouvrir des moteurs diesel. « Alternators »
# (1311020108) a un prix mais AUCUN tarif : non trace.
hr("Etape 2 -- series prix et tarif des moteurs (description seulement, pas d'estimation)")
cibles <- c("1311010105" = "Diesel Engines", "1311010104" = "internal combustion engines")
pr[, code := sprintf("%.0f", code80)]
ser <- pr[code %in% names(cibles), .(code, item80, year, priceindex, logfiscprice, tariff)][order(code, year)]
check(setequal(unique(ser$item80), unname(cibles)), "cibles : code80 et description concordent")
print(ser)
p_fig <- function(...) file.path("output", "figures", ...)
suppressWarnings(suppressMessages(library(ggplot2)))
lg <- rbind(ser[, .(item80, year, serie = "Indice de prix WPI (1981-82 = 100)", valeur = priceindex)],
            ser[, .(item80, year, serie = "Tarif (fraction ad valorem)", valeur = tariff)])
g <- ggplot(lg[!is.na(valeur)], aes(year, valeur, colour = item80)) +
  geom_vline(xintercept = 1991, linetype = "dashed", colour = "grey50") +
  geom_line() + geom_point(size = 1.2) +
  facet_wrap(~ serie, ncol = 1, scales = "free_y") +
  labs(x = NULL, y = NULL, colour = NULL) +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(p_fig("20_moteurs_prix_tarif.pdf"), g, width = 7, height = 6)
note("figure ecrite : ", p_fig("20_moteurs_prix_tarif.pdf"))

# --- Etape 3 : asi_data -----------------------------------------------------
hr("Etape 3 -- asi_data : electricite ou combustible ?")
asi <- inv[fichier == "asi_data"]
for (i in seq_len(nrow(asi))) cat(sprintf("  %-18s %s\n", asi$variable[i], asi$etiquette[i]))
re_energie <- "elec|fuel|power|energ|combust|coal|kwh|oil"
en <- asi[grepl(re_energie, variable, ignore.case = TRUE) | grepl(re_energie, etiquette, ignore.case = TRUE)]
note(sprintf("variables energie (motif %s) : %d", re_energie, nrow(en)))
check(nrow(en) == 0, "A3 : aucune variable electricite ou combustible dans asi_data (prediction)")
note("=> intensite electrique par industrie NON constructible ici : remonter aux volumes ASI.")

# Le tarif de « Diesel Engines » et celui de « internal combustion engines »
# sont identiques annee par annee : on mesure a quel niveau le tarif varie
# reellement (description de l'instrument, aucune issue).
hr("Etape 2 -- granularite reelle du tarif : articles partageant la serie des moteurs diesel")
sig_t <- pr[!is.na(tariff), .(sig = paste(sprintf("%.6f", tariff[order(year)]), collapse = ";")), by = .(code, item80)]
n_series <- uniqueN(sig_t$sig)
note(sprintf("%d articles avec tarif, %d series tarifaires distinctes", nrow(sig_t), n_series))
meme <- sig_t[sig == sig_t[code == "1311010105", sig]]
note(sprintf("%d articles partagent exactement la serie de Diesel Engines :", nrow(meme)))
for (i in seq_len(nrow(meme))) cat(sprintf("  %s | %s\n", meme$code[i], meme$item80[i]))
