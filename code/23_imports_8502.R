# ---------------------------------------------------------------------------
# 23_imports_8502.R -- Piste G, second verrou : le choc tarifaire atteint-il
#   les quantites importees de groupes electrogenes diesel (HS 8502.11-13) ?
#
# PORTEE : importations indiennes par ligne HS (UN Comtrade, apercu public
#   sans cle). Aucune variable d'issue, aucune exposition, rien sur l'ASI.
#
# DECISIONS PI (2026-10-02) : avant = 1988-1990 en HS tel que declare (pas de
#   1987 en HS) ; critere en part, avec deux denominateurs ; acces par
#   l'apercu public (comtradeapi.un.org/public/v1/preview), sans cle.
#
# ETAPE 0bis -- constats avant ce critere (aucune valeur d'importation vue) :
#   - Convention d'annee : NON TRANCHEE. Les metadonnees Comtrade de l'Inde
#     n'ont aucun champ de periode ; la documentation Comtrade pose l'annee
#     civile comme norme sans rien dire de l'Inde ; le taux de conversion
#     INR->USD implicite colle au taux civil de la Banque mondiale certaines
#     annees (1989, 1992, 1994, 1996, 1999, 2000 : ecart < 0,3 %) et a aucune
#     des deux conventions d'autres annees (1990 : +3,7 % civil, -3,5 %
#     fiscal ; 1991 : +7,8 % / +4,2 %). Les fenetres ci-dessous sont choisies
#     pour etre valides sous les DEUX conventions.
#   - Quantites (unite 5, nombre) presentes pour 8502, 850211, 850213 chaque
#     annee 1988-2000 ; 850212 ABSENT de la reponse 1988 (reponse complete,
#     HTTP 200, 4 lignes : absence structurelle, pas un 429) ; 850220 sans
#     quantite 1991-1993.
#   - Nomenclature : H0 (HS1992) 1988-1995, H1 (HS1996) 1996-2000 ; 850211,
#     850212, 850213 identiques dans les deux revisions (seul 850230 est
#     scinde en 850231/850239). Aucune rupture sur le numerateur.
#
# ===========================================================================
# CRITERE (ecrit le 2026-10-02, commite AVANT toute extraction ; ne bouge
#          plus, meme en cas d'echec)
# ===========================================================================
# Valeurs : primaryValue (USD, CIF), importations, partenaire Monde.
#   Les parts sont des rapports de deux valeurs de la meme annee : le taux
#   de conversion s'annule ; la convention d'annee touche numerateur et
#   denominateur de la meme facon.
#
# Numerateur N_t = 850211 + 850212 + 850213 (groupes diesel, toutes
#   puissances). 850220 (essence) hors critere.
# Denominateurs :
#   D1_t = (84 + 85) - 8502        biens d'equipement hors groupes
#   D2_t = TOTAL - 84 - 85          tout le reste
# Parts : s1_t = N_t / D1_t ; s2_t = N_t / D2_t.
#
# Fenetres : AVANT = 1988-1990 ; APRES = 1995-2000 ; 1991-1994 exclus.
#   Sous la convention fiscale, « 1990 » finit en mars 1991, avant la
#   devaluation de juillet 1991 ; « 1995 » commence en avril 1995, apres le
#   tarif a 25 % (1994). Sous la convention civile, idem a fortiori.
#
# Statistique, pour k = 1, 2 :
#   L_k = moy(log s_k, APRES) - moy(log s_k, AVANT).
# Conditions, pour chaque k (chiffrees d'avance) :
#   (a) magnitude : L_k >= log(1,5) = 0,405 (part en hausse d'au moins 50 %).
#       Repere : si le tarif des groupes a suivi celui des moteurs diesel
#       (110 % -> 25 %), le prix rendu baisse de log(1,25/2,10) = -0,52 ; une
#       elasticite-prix des importations d'au moins ~1,8 (en valeur : 0,8 x
#       0,52 ~ 0,4) suffit a franchir le seuil. En dessous, le mouvement d'une
#       ligne HS etroite n'est pas un decollage.
#   (b) separation : min(s_k, APRES) > max(s_k, AVANT) -- aucune annee
#       d'apres n'est au niveau d'une annee d'avant.
#   Resultat k : OUI si (a) et (b) ; NON si ni (a) ni (b) ; LIMITE sinon.
# VERDICT :
#   DECOLLE            D1 = OUI et D2 = OUI ;
#   NE DECOLLE PAS     D1 = NON et D2 = NON ;
#   NE TRANCHE PAS     un OUI et un NON (les deux denominateurs s'opposent :
#                      resultat recevable, aucun denominateur n'est prefere) ;
#   LIMITE             tout autre cas.
#
# Absence structurelle 850212 en 1988 (connue avant ce critere) : le critere
#   est calcule sous DEUX traitements, fixes d'avance :
#   A  850212 (1988) = 0, avant = 1988-1990 ;
#   B  avant = 1989-1990 pour toutes les series (1988 ecarte).
#   Si A et B donnent le meme verdict, il est retenu ; sinon le verdict est
#   INSTABLE (A : x, B : y), rapporte tel quel.
#
# Lectures hors critere (ne decident rien) :
#   - ventilation 850211 (<= 75 kVA), 850212 (75-375 kVA), 850213 (> 375 kVA) ;
#   - valeur unitaire (USD CIF par unite) des groupes diesel et du 8502,
#     avant contre apres. ATTENTION : une valeur CIF est HORS droits de
#     douane ; elle ne contient pas le tarif. Le prix paye a l'interieur est
#     CIF x (1 + tarif) ; le tarif propre au 8502 n'est pas en main.
#
# LIMITES CONNUES (consignees, non quantifiees) :
#   - devaluation de juillet 1991 : rencherit les importations en roupies au
#     moment ou le tarif baisse ;
#   - les importations repondent aussi au revenu et a la suppression des
#     licences d'importation, pas seulement au tarif ;
#   - valeurs CIF en USD, sensibles au taux de change ;
#   - D2 contient le petrole brut et les produits petroliers, dont la valeur
#     suit le cours mondial (choc de 1990, creux de 1998) ;
#   - le tarif du 8502 lui-meme n'est pas observe : celui des moteurs diesel
#     (WPI 1311010105) sert de repere, pas de mesure.
#
# EXTRACTION : un appel par annee (l'apercu n'accepte qu'une periode),
#   codes 850211, 850212, 850213, 850220, 8502, 84, 85, TOTAL ; reporter 699,
#   partenaire 0, flux M, annuel. Pause de 6 s entre appels ; sur 429 :
#   attente 15 s, 5 essais au plus, puis ARRET. JSON bruts dans raw/comtrade/
#   (ecriture .part puis renommage ; un fichier present et valide est relu,
#   pas retelecharge), SHA256 dans raw/comtrade/SHA256SUMS.txt. Exhaustivite
#   annee x code verifiee AVANT tout calcul.
#
# LANCEMENT (racine du depot ; ~2 minutes au premier passage, a cause des
#   pauses ; quelques secondes ensuite) :
#     Rscript code/23_imports_8502.R
#     Rscript code/23_imports_8502.R --force    # retelecharge tout
#
# Sorties : output/tables/23_imports_annuels.csv
#           output/tables/23_verdict.csv / .tex
#           output/figures/23_parts_8502.pdf
#           output/logs/23_imports_8502.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
p_tab <- function(...) file.path("output", "tables", ...)
p_fig <- function(...) file.path("output", "figures", ...)
dir_ct <- p_raw("comtrade")
dir.create(dir_ct, recursive = TRUE, showWarnings = FALSE)

log_open(p_log("23_imports_8502.log"))
on.exit(log_close(), add = TRUE)
suppressWarnings(suppressMessages({ library(ggplot2) }))

ANNEES   <- 1988:2000
AVANT_A  <- 1988:1990
AVANT_B  <- 1989:1990
APRES    <- 1995:2000
CODES    <- c("850211", "850212", "850213", "850220", "8502", "84", "85", "TOTAL")
DIESEL   <- c("850211", "850212", "850213")
ABS_PREVU <- data.table(annee = 1988L, code = "850212")
SEUIL_L  <- log(1.5)
PAUSE    <- 6
URL_BASE <- "https://comtradeapi.un.org/public/v1/preview/C/A/HS"

hr("CRITERE (fixe et commite avant extraction)")
note("N = 850211+850212+850213 ; D1 = (84+85) - 8502 ; D2 = TOTAL - 84 - 85 ; valeurs CIF USD")
note("AVANT = 1988-1990 (traitement A) ou 1989-1990 (traitement B) ; APRES = 1995-2000 ; 1991-1994 exclus")
note(sprintf("par denominateur : (a) L >= log 1,5 = %.4f ; (b) min(APRES) > max(AVANT)", SEUIL_L))
note("k : OUI si (a) et (b) ; NON si aucun ; LIMITE sinon")
note("verdict : 2 OUI = DECOLLE ; 2 NON = NE DECOLLE PAS ; OUI + NON = NE TRANCHE PAS ; sinon LIMITE")
note("A et B en desaccord : INSTABLE")

hr("LIMITES CONNUES (non quantifiees)")
note("- devaluation de juillet 1991 : importations plus cheres en roupies au moment ou le tarif baisse")
note("- les importations repondent aussi au revenu et a la suppression des licences, pas seulement au tarif")
note("- valeurs CIF en USD, sensibles au taux de change ; CIF = hors droits de douane")
note("- D2 contient le petrole, dont la valeur suit le cours mondial")
note("- tarif propre au 8502 non observe ; celui des moteurs diesel n'est qu'un repere")
note("- convention d'annee (civile / fiscale avril-mars) NON TRANCHEE ; fenetres valides sous les deux")

# --- extraction -------------------------------------------------------------------
hr("Extraction (apercu public Comtrade, sans cle)")
json_valide <- function(path) {
  if (!file.exists(path)) return(FALSE)
  j <- tryCatch(jsonlite::fromJSON(path), error = function(e) NULL)
  !is.null(j) && identical(j$error, "") && isTRUE(j$count > 0)
}
appel <- function(an) {
  url <- sprintf("%s?reporterCode=699&period=%d&cmdCode=%s&flowCode=M&partnerCode=0",
                 URL_BASE, an, paste(CODES, collapse = ","))
  for (essai in 1:5) {
    r <- tryCatch(curl::curl_fetch_memory(url), error = function(e) NULL)
    st <- if (is.null(r)) NA_integer_ else r$status_code
    if (identical(st, 200L)) return(rawToChar(r$content))
    tmsg(sprintf("  %d : HTTP %s, essai %d/5, attente 15 s", an, st, essai))
    Sys.sleep(15)
  }
  stop(sprintf("EXTRACTION ECHOUEE : annee %d sans reponse 200 apres 5 essais. Arret.", an), call. = FALSE)
}
for (an in ANNEES) {
  f <- file.path(dir_ct, sprintf("ind_M_%d.json", an))
  if (!FORCE && json_valide(f)) { tmsg(sprintf("%d : deja present, relu (%s)", an, f)); next }
  tmsg(sprintf("%d : appel", an))
  txt <- appel(an)
  tmp <- paste0(f, ".part")
  writeLines(txt, tmp, useBytes = TRUE)
  check(json_valide(tmp), sprintf("%d : JSON valide (error vide, count > 0)", an))
  if (file.exists(f)) file.remove(f)
  check(file.rename(tmp, f), sprintf("%d : ecrit -> %s", an, f))
  Sys.sleep(PAUSE)
}
fichiers <- file.path(dir_ct, sprintf("ind_M_%d.json", ANNEES))
sha <- vapply(fichiers, function(f) toupper(digest::digest(file = f, algo = "sha256")), "")
writeLines(sprintf("%s  %s", sha, basename(fichiers)), file.path(dir_ct, "SHA256SUMS.txt"))
note("SHA256 :")
for (i in seq_along(fichiers)) note(sprintf("  %s  %s", sha[i], basename(fichiers[i])))

# --- exhaustivite AVANT tout calcul ---------------------------------------------------
hr("Exhaustivite annee x code (avant tout calcul)")
d <- rbindlist(lapply(fichiers, function(f) as.data.table(jsonlite::fromJSON(f)$data)), fill = TRUE)
check_vars(d, c("period", "cmdCode", "primaryValue", "qty", "qtyUnitCode", "classificationCode",
                "reporterCode", "partnerCode", "flowCode"), "comtrade")
check(all(d$reporterCode == 699 & d$partnerCode == 0 & d$flowCode == "M"),
      "toutes les lignes : Inde, partenaire Monde, importations")
if ("partner2Code" %in% names(d)) check(all(d$partner2Code == 0), "partner2Code = 0 partout")
if ("customsCode" %in% names(d)) check(all(d$customsCode == "C00"), "customsCode = C00 partout")
if ("motCode" %in% names(d)) check(all(d$motCode == 0), "motCode = 0 partout")
d[, annee := as.integer(period)]
d[, code := as.character(cmdCode)]
check_unique(d, c("annee", "code"), "comtrade")
check(all(d[annee <= 1995, classificationCode] == "H0") && all(d[annee >= 1996, classificationCode] == "H1"),
      "nomenclature : H0 1988-1995, H1 1996-2000")
attendu <- CJ(annee = ANNEES, code = CODES)
manque <- attendu[!d, on = .(annee, code)]
note(sprintf("couples attendus : %d ; recus : %d ; absents : %d", nrow(attendu), nrow(d[code %in% CODES]), nrow(manque)))
if (nrow(manque)) print(manque)
imprevu <- manque[!ABS_PREVU, on = .(annee, code)]
check(nrow(imprevu) == 0, "aucune absence hors l'absence structurelle connue (850212, 1988)",
      paste(sprintf("%d/%s", imprevu$annee, imprevu$code), collapse = ", "))
check(nrow(manque[ABS_PREVU, on = .(annee, code), nomatch = 0]) == nrow(ABS_PREVU),
      "l'absence structurelle connue est bien la seule (850212, 1988)")

# --- series ------------------------------------------------------------------------
w <- dcast(d[code %in% CODES], annee ~ code, value.var = "primaryValue")
q <- dcast(d[code %in% CODES], annee ~ code, value.var = "qty")
setnames(q, setdiff(names(q), "annee"), paste0("q", setdiff(names(q), "annee")))
w <- merge(w, q, by = "annee")
w[annee == 1988 & is.na(`850212`), `850212` := 0]   # traitement A ; B ecarte 1988
w[annee == 1988 & is.na(q850212), q850212 := 0]
w[, N := `850211` + `850212` + `850213`]
w[, D1 := `84` + `85` - `8502`]
w[, D2 := TOTAL - `84` - `85`]
check(all(w$N <= w$`8502`), "coherence : N <= 8502 chaque annee")
check(all(w$`84` + w$`85` < w$TOTAL), "coherence : 84 + 85 < TOTAL chaque annee")
w[, `:=`(s1 = N / D1, s2 = N / D2)]
w[, uv_diesel := N / (q850211 + q850212 + q850213)]
w[, uv_8502 := `8502` / q8502]
fwrite(w, p_tab("23_imports_annuels.csv"))

hr("Series annuelles (USD courants, CIF)")
print(w[, .(annee, N_musd = round(N / 1e6, 2), D1_musd = round(D1 / 1e6), D2_musd = round(D2 / 1e6),
            s1_pm = round(1e3 * s1, 3), s2_pm = round(1e3 * s2, 3))])
note("s1, s2 en pour mille")

# --- critere ------------------------------------------------------------------------
eval_k <- function(s, avant) {
  L  <- mean(log(s[w$annee %in% APRES])) - mean(log(s[w$annee %in% avant]))
  a  <- L >= SEUIL_L
  b  <- min(s[w$annee %in% APRES]) > max(s[w$annee %in% avant])
  list(L = L, a = a, b = b, res = if (a && b) "OUI" else if (!a && !b) "NON" else "LIMITE")
}
verdict_de <- function(r1, r2) {
  if (r1 == "OUI" && r2 == "OUI") "DECOLLE" else if (r1 == "NON" && r2 == "NON") "NE DECOLLE PAS"
  else if (setequal(c(r1, r2), c("OUI", "NON"))) "NE TRANCHE PAS" else "LIMITE"
}
hr("VERDICT contre le critere ecrit d'avance")
res <- rbindlist(lapply(list(A = AVANT_A, B = AVANT_B), function(av) {
  k1 <- eval_k(w$s1, av); k2 <- eval_k(w$s2, av)
  data.table(avant = paste(range(av), collapse = "-"),
             L1 = k1$L, a1 = k1$a, b1 = k1$b, D1 = k1$res,
             L2 = k2$L, a2 = k2$a, b2 = k2$b, D2 = k2$res,
             verdict = verdict_de(k1$res, k2$res))
}), idcol = "traitement")
for (i in seq_len(nrow(res))) with(res[i], {
  note(sprintf("traitement %s (avant %s)", traitement, avant))
  note(sprintf("  D1 : L = %.4f (x%.2f) ; (a) %s ; (b) %s -> %s", L1, exp(L1), a1, b1, D1))
  note(sprintf("  D2 : L = %.4f (x%.2f) ; (a) %s ; (b) %s -> %s", L2, exp(L2), a2, b2, D2))
  note(sprintf("  verdict : %s", verdict))
})
verdict <- if (res$verdict[1] == res$verdict[2]) res$verdict[1] else
  sprintf("INSTABLE (A : %s, B : %s)", res$verdict[1], res$verdict[2])
cat("\n  >>> VERDICT : ", verdict, "\n", sep = "")
fwrite(cbind(res, verdict_final = verdict), p_tab("23_verdict.csv"))
tex <- c("\\begin{tabular}{llrllrll}", "\\toprule",
         "Trait. & Avant & $L_1$ & D1 & & $L_2$ & D2 & Verdict \\\\", "\\midrule",
         sprintf("%s & %s & %.3f & %s & & %.3f & %s & %s \\\\", res$traitement, res$avant, res$L1, res$D1,
                 res$L2, res$D2, res$verdict),
         "\\bottomrule",
         sprintf("\\multicolumn{8}{l}{\\footnotesize Seuil $L \\geq \\log 1{,}5$ et separation ; apres 1995--2000 ; N = %d annees.} \\\\", nrow(w)),
         "\\end{tabular}")
writeLines(tex, p_tab("23_verdict.tex"))

# --- lectures hors critere --------------------------------------------------------
hr("Lecture hors critere -- ventilation par sous-position (part dans N, moyenne de fenetre)")
fen <- function(a) fifelse(a %in% AVANT_A, "avant 1988-1990", fifelse(a %in% APRES, "apres 1995-2000", NA_character_))
w[, fenetre := fen(annee)]
print(w[!is.na(fenetre), .(N_musd = round(mean(N) / 1e6, 2),
                            p_850211 = round(sum(`850211`) / sum(N), 3),
                            p_850212 = round(sum(`850212`) / sum(N), 3),
                            p_850213 = round(sum(`850213`) / sum(N), 3),
                            q_850211 = round(mean(q850211)), q_850212 = round(mean(q850212)),
                            q_850213 = round(mean(q850213))), by = fenetre])
note("850212 en 1988 compte pour 0 (traitement A) dans la fenetre avant")
note("variation log des valeurs par sous-position (apres - avant 1989-1990, pour eviter le 0 de 1988) :")
for (cc in DIESEL) note(sprintf("  %s : %.3f", cc,
  mean(log(w[annee %in% APRES][[cc]])) - mean(log(w[annee %in% AVANT_B][[cc]]))))

hr("Lecture hors critere -- valeur unitaire (USD CIF par unite, HORS droits)")
print(w[, .(annee, uv_diesel = round(uv_diesel), uv_8502 = round(uv_8502))])
for (v in c("uv_diesel", "uv_8502")) note(sprintf("%s : moy log apres - moy log avant (1989-1990) = %.3f", v,
  mean(log(w[annee %in% APRES][[v]])) - mean(log(w[annee %in% AVANT_B][[v]]))))
note("Rappel : une valeur CIF ne contient pas le droit de douane. Une baisse de la valeur unitaire CIF")
note("ne mesure pas le passage du tarif ; elle reflete prix etrangers, composition et taux de change.")

# --- figure ----------------------------------------------------------------------------
lg <- rbind(w[, .(annee, serie = "Part sur D1 (84-85 hors 8502)", v = log(s1) - mean(log(s1[annee %in% AVANT_A])))],
            w[, .(annee, serie = "Part sur D2 (hors 84-85)",      v = log(s2) - mean(log(s2[annee %in% AVANT_A])))])
g <- ggplot(lg, aes(annee, v, colour = serie)) +
  annotate("rect", xmin = 1990.5, xmax = 1994.5, ymin = -Inf, ymax = Inf, alpha = 0.12) +
  geom_hline(yintercept = c(0, SEUIL_L), linetype = c("solid", "dashed"), colour = "grey50") +
  geom_line() + geom_point(size = 1.4) +
  labs(x = NULL, y = "log de la part, ecart a la moyenne 1988-1990", colour = NULL) +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(p_fig("23_parts_8502.pdf"), g, width = 7, height = 4.5)
note("figure : ", p_fig("23_parts_8502.pdf"))
