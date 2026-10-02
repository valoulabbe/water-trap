# ---------------------------------------------------------------------------
# 19_declaratif_vs_administratif.R -- Piste E, validation de mesure : source
#   d'eau declaree par les menages ruraux IHDS-II contre les sources d'eau
#   potable enregistrees au questionnaire village IHDS-II (DS0012).
#
# PORTEE : controle de mesure, pas une estimation. Taux d'accord et sens du
#   desaccord, non ponderes. Aucune part de provision publique n'est
#   interpretee comme resultat.
#
# HISTORIQUE (02/10/2026) : la comparaison prevue etait menage IHDS-II contre
#   repertoire des villages du recensement 2011 (SHRUG pc11_vd). Controle L2
#   echoue : VILL, seul « code village » de DS0012, va de 1 a 88 et vaut
#   PSUID dans 97,5 % des cas (numero d'ordre IHDS, pas un code du
#   recensement) : aucun lien village IHDS -> PC11 dans les fichiers publics.
#   Decision : comparer au questionnaire village IHDS-II. ATTENTION : c'est
#   une declaration d'informateur de village, PAS une source administrative ;
#   le test est donc une coherence interne a l'enquete, plus faible.
#   Le diagnostic L2 est garde en 19a (journalise, non bloquant).
#
# CORRESPONDANCE DES CODES (relue dans le log 15) : WA1A (menage) et
#   VI10A/B/C (village) partagent les codes 1 a 11 dans le meme ordre :
#   1 Piped, 2 Tube well, 3 Hand pump, 4 Open/dug well, 5 Covered well,
#   6 River/canal, 7 Pond, 8 Tanker, 9 Rainwater, 10 Bottled, 11 Other.
#   Le village liste au plus 3 sources : une source de menage absente de la
#   liste n'est pas forcement une contradiction (4e source, source privee).
#
# MESURES (fixees avant execution)
#   M1 menage : source du menage parmi {VI10A, VI10B, VI10C}.
#   M2 village, eau courante : « le village liste Piped » contre « au moins un
#      menage enquete declare Piped ». Deux sens de desaccord :
#        village_seul  : le village liste Piped, aucun menage ne le declare
#                        (couverture partielle : pas une contradiction franche)
#        menages_seuls : des menages declarent Piped, le village ne le liste
#                        pas (contradiction franche)
#   M3 menage, eau courante : menage Piped contre village liste Piped.
#
# ATTENDUS ET CRITERE (ecrits avant la premiere execution)
#   Bloquants : 1 410 villages, cle unique ; >= 90 % des menages ruraux
#     IHDS-II relies a un village (etape 15 : 96,4 %) ; codes 1 a 11 seuls.
#   Descriptifs : M1 >= 70 % ; M2 >= 80 %.
#   CRITERE d'usage du declaratif pour l'eau courante :
#     UTILISABLE si accord M2 >= 80 % ET villages « menages_seuls » <= 5 % ;
#     LIMITE si accord M2 entre 65 et 80 % ou menages_seuls entre 5 et 10 % ;
#     NON UTILISABLE sinon.
#
# LANCEMENT : Rscript code/19_declaratif_vs_administratif.R
#   (prealable : etape 15, build/15_ihds_menages.rds et 15_ihds_village.rds)
# Sorties : output/tables/19_*.csv, output/logs/19_declaratif_vs_administratif.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
p_tab <- function(...) file.path("output", "tables", ...)

log_open(p_log("19_declaratif_vs_administratif.log"))
msg("ETAPE 19 -- PISTE E : DECLARATIF MENAGE CONTRE QUESTIONNAIRE VILLAGE (IHDS-II)")
msg("Controle de mesure : accords non ponderes, aucune estimation.")

ecart <- function(ok, quoi, obs) {
  if (isTRUE(ok)) msg("  [ATTENDU]  ", quoi, " -- observe : ", obs)
  else            msg("  [ECART]    ", quoi, " -- observe : ", obs, "  <-- a signaler")
}
LIB <- c("Piped", "Tube well", "Hand pump", "Open well", "Covered well", "River/canal",
         "Pond", "Tanker", "Rainwater", "Bottled", "Other")

# ===========================================================================
hr("19a. Lien au recensement 2011 (diagnostic, non bloquant)")
# ===========================================================================
code_icpsr <- function(x) {
  if (!is.factor(x)) return(as.numeric(x))
  as.numeric(sub("^\\((-?[0-9]+)\\).*$", "\\1", as.character(x)))
}
charge_rda <- function(f) { e <- new.env(); o <- load(f, envir = e); e[[o]] }
d12 <- charge_rda(p_raw("ihds", "2011", "DS0012", "36151-0012-Data.rda"))
ids <- as.data.table(lapply(d12[, c("PSUID", "STATE", "DISTA", "VILL")], code_icpsr))
l2 <- ids[, .(villages = .N, vill_min = min(VILL), vill_max = max(VILL),
              vill_valeurs_distinctes = uniqueN(VILL),
              vill_egal_psuid_pct = round(100 * mean(VILL == PSUID), 1),
              cle_etat_dist_vill_unique = uniqueN(ids, by = c("STATE", "DISTA", "VILL")) == .N)]
print(l2)
fwrite(l2, p_tab("19_lien_recensement.csv"))
msg("  VILL n'est pas un code du recensement : comparaison faite au questionnaire village IHDS-II.")
rm(d12)

# ===========================================================================
hr("19b. Entrees et lien menage -> village")
# ===========================================================================
f_m <- p_build("15_ihds_menages.rds"); f_v <- p_build("15_ihds_village.rds")
check(all(file.exists(c(f_m, f_v))), "sorties de l'etape 15 presentes")
men <- readRDS(f_m)$ihds2$d
vil <- readRDS(f_v)$d
check_rows(vil, 1410L, "village IHDS-II")
check_unique(vil, c("STATEID", "DISTID", "PSUID"), "village IHDS-II")
check_rows(men, 42152L, "menages IHDS-II")

rur <- men[URBAN2011 == 0, .(STATEID, DISTID, PSUID, HHID, HHSPLITID, src = WA1A)]
rur <- merge(rur, vil[, .(STATEID, DISTID, PSUID, v1 = VI10A, v2 = VI10B, v3 = VI10C)],
             by = c("STATEID", "DISTID", "PSUID"), all.x = TRUE)
lie <- rur[, mean(!is.na(v1) | !is.na(v2) | !is.na(v3))]
check(lie >= 0.90, ">= 90 % des menages ruraux relies a un village renseigne",
      sprintf("observe %.1f %%", 100 * lie))
msg(sprintf("  menages ruraux : %d ; relies a un village renseigne : %.1f %%", nrow(rur), 100 * lie))
codes <- unique(na.omit(c(rur$src, rur$v1, rur$v2, rur$v3)))
check(all(codes %in% 1:11), "codes de source dans 1 a 11", paste(sort(codes), collapse = " "))

ech <- rur[!is.na(src) & (!is.na(v1) | !is.na(v2) | !is.na(v3))]
msg(sprintf("  echantillon de comparaison : %d menages, %d villages",
            nrow(ech), uniqueN(ech, by = c("STATEID", "DISTID", "PSUID"))))

# ===========================================================================
hr("19c. M1 : source du menage parmi les sources listees par le village")
# ===========================================================================
ech[, dans_liste := (src == v1) %in% TRUE | (src == v2) %in% TRUE | (src == v3) %in% TRUE]
m1 <- ech[, .(menages = .N, accord = sum(dans_liste), accord_pct = round(100 * mean(dans_liste), 1)),
          keyby = .(code = src)][, source_menage := LIB[code]]
setcolorder(m1, c("code", "source_menage"))
m1 <- rbind(m1, ech[, .(code = NA_real_, source_menage = "TOTAL", menages = .N,
                        accord = sum(dans_liste), accord_pct = round(100 * mean(dans_liste), 1))])
print(m1)
fwrite(m1, p_tab("19_m1_menage_dans_liste.csv"))
m1_tot <- m1[source_menage == "TOTAL", accord_pct]
ecart(m1_tot >= 70, "M1 >= 70 %", paste0(m1_tot, " %"))

# ===========================================================================
hr("19d. M2 : eau courante, au niveau du village")
# ===========================================================================
vv <- ech[, .(menages = .N, menages_piped = sum(src == 1),
              village_liste_piped = any(c(v1[1], v2[1], v3[1]) %in% 1),
              village_piped_principal = v1[1] %in% 1),
          by = .(STATEID, DISTID, PSUID)]
vv[, menages_declarent_piped := menages_piped > 0]
vv[, cas := fifelse(village_liste_piped & menages_declarent_piped, "accord_oui",
            fifelse(!village_liste_piped & !menages_declarent_piped, "accord_non",
            fifelse(village_liste_piped, "village_seul", "menages_seuls")))]
m2 <- vv[, .(villages = .N), keyby = cas][, pct := round(100 * villages / sum(villages), 1)]
print(m2)
fwrite(m2, p_tab("19_m2_piped_village.csv"))
m2_acc <- m2[cas %in% c("accord_oui", "accord_non"), sum(pct)]
m2_ms  <- m2[cas == "menages_seuls", sum(pct)]
ecart(m2_acc >= 80, "M2 >= 80 %", paste0(m2_acc, " %"))

# intensite : part des menages Piped selon que le village liste Piped (principal ou non)
m2b <- vv[, .(villages = .N, part_menages_piped_med = round(median(menages_piped / menages), 2),
              part_menages_piped_moy = round(mean(menages_piped / menages), 2)),
          keyby = .(village_liste_piped, village_piped_principal)]
print(m2b)
fwrite(m2b, p_tab("19_m2b_intensite.csv"))

# ===========================================================================
hr("19e. M3 : eau courante, au niveau du menage")
# ===========================================================================
ech[, v_piped := (v1 %in% 1) | (v2 %in% 1) | (v3 %in% 1)]
m3 <- ech[, .(menages = .N), keyby = .(menage_piped = src == 1, village_liste_piped = v_piped)]
m3[, pct := round(100 * menages / sum(menages), 1)]
print(m3)
fwrite(m3, p_tab("19_m3_piped_menage.csv"))

# ===========================================================================
hr("19f. Verdict contre le critere ecrit")
# ===========================================================================
verdict <- if (m2_acc >= 80 && m2_ms <= 5) "UTILISABLE" else
  if (m2_acc >= 65 && m2_ms <= 10) "LIMITE" else "NON UTILISABLE"
ver <- data.table(m1_accord_pct = m1_tot, m2_accord_pct = m2_acc,
                  m2_menages_seuls_pct = m2_ms,
                  m2_village_seul_pct = m2[cas == "village_seul", sum(pct)],
                  verdict = verdict,
                  reference = "questionnaire village IHDS-II (pas administratif)")
print(ver)
fwrite(ver, p_tab("19_verdict.csv"))

hr("ETAPE 19 TERMINEE")
for (f in sort(list.files(file.path("output", "tables"), "^19_"))) note(f)
log_close()
