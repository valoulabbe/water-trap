# ---------------------------------------------------------------------------
# 22_dose_prix_moteurs.R -- Piste G, verrou 0, voie 2 (decision PI du
#   2026-10-02 apres l'arret de 21_critere_prix_moteurs.R : panier « non
#   touche » de 5 articles < 10). Le critere de 21 reste tel quel ; celui-ci
#   le remplace sans le reecrire.
#
# Question : le choc tarifaire sur les moteurs diesel (WPI 1311010105)
#   atteint-il le prix ? Design en dose continue : tous les articles WPI
#   tarifes, la variation du log-prix regressee sur la variation du tarif.
#
# PORTEE : prix WPI et tarifs seulement. Aucune variable d'issue, aucune
#   exposition, rien sur l'ASI.
#
# DIVULGATION : vus avant ce critere -- la serie nominale des moteurs diesel
#   (etape 20) et les trajectoires TARIFAIRES (etapes 20-21 ; le traitement,
#   pas l'issue). Jamais vus : un prix relatif, une variation de prix d'un
#   autre article, une pente.
#
# ===========================================================================
# CRITERE (ecrit le 2026-10-02, commite AVANT toute execution ; ne bouge
#          plus, meme en cas d'echec)
# ===========================================================================
# Variables : logfiscprice (log de l'indice WPI, annee fiscale) et tariff
#   (fraction ad valorem), celles de Topalova (2010, tableau 7).
#
# Fenetres (inchangees depuis 21) : AVANT = 1987-1990, APRES = 1995-2001,
#   1991-1994 transition exclue (devaluation et budget de juillet 1991 dans
#   « 1991 », que l'annee soit civile ou fiscale ; tarif des moteurs a 25 %
#   des 1994 ; 2001 derniere annee tarifee).
#
# Par article i : dp_i = moy(logfiscprice, APRES) - moy(logfiscprice, AVANT) ;
#   dt_i = moy(tariff, APRES) - moy(tariff, AVANT).
#
# Echantillon (regles sur la PRESENCE des valeurs, jamais sur les prix) :
#   E1 tarif observe chaque annee 1987-2001 ;
#   E2 logfiscprice observe chaque annee des deux fenetres ;
#   E3 exclus : 1311010105 (point teste), 1311010104 (meme serie tarifaire,
#      traite), 12000300xx electricite (prix public administre ; c'est le
#      service public de la piste B, il ne peut pas servir de reference) ;
#   E4 minimum 50 articles et 20 grappes tarifaires, sinon ARRET avant prix.
#
# Deflateur : aucun explicite. La constante absorbe tout mouvement commun
#   (inflation, devaluation moyenne) ; la pente est identifiee par les ecarts
#   entre articles. Equivaut a deflater par n'importe quel indice commun.
#
# Estimation : MCO, dp_i = a + b * dt_i + e_i, poids egaux (pas de poids
#   WPI dans le paquet). Ecarts-types groupes par serie tarifaire identique
#   (179 series pour 336 articles a l'etape 20 : le tarif varie au niveau
#   d'une ligne industrielle, pas de l'article), correction CR1, loi de
#   Student a G-1 degres.
#
# Effet sur les moteurs diesel : E = b * dt_diesel. dt_diesel est connu
#   d'avance (traitement) : moy(1995-2001) - moy(1987-1990) = 0,2370 - 1,0716
#   = -0,8346. E = baisse du prix imputable au tarif, par rapport a un article
#   au tarif inchange.
#
# Garde-fou de magnitude -- De Loecker, Goldberg, Khandelwal, Pavcnik
#   (Econometrica 2016 ; lu dans NBER WP w17925, p. 35 et tableau 9) :
#   prix firme-produit sur tarif de sortie, Inde 1989-1997 : 0,136 (EF
#   annee), 0,167 (EF secteur-annee), 0,156 (avec tarifs d'intrants).
#   Leur note 48 : Topalova (2010) sur le WPI, 0,096. Applique a dt_diesel :
#   0,136 -> E = -0,114 ; 0,167 -> E = -0,139 ; 0,096 -> E = -0,080.
#   Le seuil C2 (-0,105) est donc a portee de la litterature mais pas acquis.
#
# Conditions (chiffrees d'avance) :
#   C1 transmission generale : b > 0, p unilateral < 0,05.
#   C2 magnitude : E = b * dt_diesel <= log(0,90) = -0,105 (baisse d'au moins
#      10 %, seuil repris de 21 : en dessous, le choc sur le cout du substitut
#      prive est trop faible pour porter la piste).
#   C3 garde-fou De Loecker : b <= 3 x 0,167 = 0,501. Au-dela, la pente WPI
#      est trois fois la borne haute firme-produit sur la meme reforme :
#      magnitude suspecte (composition des articles, prix administres).
#   C4 conformite : le residu des moteurs diesel, dp_diesel - (a + b *
#      dt_diesel), est <= 90e centile des residus de l'echantillon. Sinon la
#      droite transmet mais le prix des moteurs n'a pas suivi.
#   VERDICT :
#     PASSE          C1, C2, C3 et C4 ;
#     NE PASSE PAS   C1 ou C2 echoue ;
#     LIMITE         C1 et C2 tiennent mais C3 ou C4 echoue.
#
# LIMITE CONNUE (consignee, non quantifiee) : la devaluation de juillet 1991
#   rencherit les importations en roupies au moment ou le tarif baisse ;
#   effets de sens oppose sur le prix interieur. La constante absorbe sa
#   partie commune, pas son incidence differentielle (articles plus importes
#   = souvent plus taxes avant 1991 : biais vers b = 0). Un prix qui ne bouge
#   pas ne prouve pas que le tarif n'a eu aucun effet.
#
# LANCEMENT (racine du depot ; quelques secondes) :
#     Rscript code/22_dose_prix_moteurs.R
#
# Sorties : output/tables/22_dose_verdict.csv / .tex
#           output/figures/22_dose_prix_tarif.pdf
#           output/logs/22_dose_prix_moteurs.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
p_tab <- function(...) file.path("output", "tables", ...)
p_fig <- function(...) file.path("output", "figures", ...)

log_open(p_log("22_dose_prix_moteurs.log"))
on.exit(log_close(), add = TRUE)
suppressWarnings(suppressMessages({ library(haven); library(ggplot2) }))

# Parametres : copie exacte de l'en-tete.
TRAITE   <- "1311010105"
FRERE    <- "1311010104"
AVANT    <- 1987:1990
APRES    <- 1995:2001
ANS_TAR  <- 1987:2001
N_MIN    <- 50L
G_MIN    <- 20L
C2_SEUIL <- log(0.90)
DL       <- c(ef_annee = 0.136, ef_secteur_annee = 0.167, avec_intrants = 0.156, topalova_wpi = 0.096)
C3_PLAF  <- 3 * DL[["ef_secteur_annee"]]
C4_CENT  <- 0.90

hr("CRITERE (fixe et commite avant execution)")
note("dp_i = a + b * dt_i ; fenetres 1987-1990 / 1995-2001 ; MCO, grappes = serie tarifaire, CR1")
note(sprintf("C1 : b > 0, p unilateral < 0,05"))
note(sprintf("C2 : E = b * dt_diesel <= %.4f", C2_SEUIL))
note(sprintf("C3 : b <= %.3f (3 x 0,167, De Loecker et al. 2016)", C3_PLAF))
note(sprintf("C4 : residu diesel <= centile %.0f des residus", 100 * C4_CENT))
note("verdict : C1-C4 = PASSE ; C1 ou C2 echoue = NE PASSE PAS ; C1, C2 mais pas C3 ou C4 = LIMITE")

hr("LIMITE CONNUE -- devaluation de juillet 1991")
note("La roupie est fortement devaluee en juillet 1991 : les importations rencherissent en roupies")
note("au moment ou le tarif baisse. Effets de sens oppose sur le prix interieur des moteurs diesel.")
note("La constante absorbe la part commune, pas l'incidence differentielle (biais vers b = 0).")
note("Un prix qui ne bouge pas ne prouve PAS que le tarif n'a eu aucun effet. Non quantifie ici.")

# --- lecture ------------------------------------------------------------------
pr <- as.data.table(zap_labels(read_dta(p_raw("topalova2010", "113765-V1", "_data", "price_data.dta"))))
check_rows(pr, 5888L, "price_data")
check_unique(pr, c("code80", "year"), "price_data")
pr[, code := sprintf("%.0f", code80)]
check(all(c(TRAITE, FRERE) %in% pr$code), "articles traites presents")

# --- echantillon : presence seulement -------------------------------------------
hr("Echantillon (regles de presence, avant tout calcul de prix)")
pres <- pr[, .(n_tar  = sum(!is.na(tariff[year %in% ANS_TAR])),
               n_prix = sum(!is.na(logfiscprice[year %in% c(AVANT, APRES)]))), by = .(code, item80)]
e1 <- pres[n_tar == length(ANS_TAR)]
note(sprintf("E1 tarif observe chaque annee %d-%d : %d articles sur %d", min(ANS_TAR), max(ANS_TAR), nrow(e1), nrow(pres)))
e2 <- e1[n_prix == length(c(AVANT, APRES))]
note(sprintf("E2 prix observe chaque annee des deux fenetres : %d articles", nrow(e2)))
check(TRAITE %in% e2$code, "l'article teste satisfait E1 et E2")
ech <- e2[!code %in% c(TRAITE, FRERE) & !startsWith(code, "12000300")]
note(sprintf("E3 traites et electricite exclus : %d articles", nrow(ech)))

# Grappes : series tarifaires identiques annee par annee.
sig <- pr[code %in% c(ech$code, TRAITE) & year %in% ANS_TAR][order(year),
          .(sig = paste(sprintf("%.6f", tariff), collapse = ";")), by = code]
sig[, grappe := as.integer(factor(sig))]
ech <- merge(ech, sig[, .(code, grappe)], by = "code")
G <- uniqueN(ech$grappe)
note(sprintf("grappes tarifaires dans l'echantillon : %d", G))
check(nrow(ech) >= N_MIN, sprintf("E4 : au moins %d articles", N_MIN), sprintf("observe %d", nrow(ech)))
check(G >= G_MIN, sprintf("E4 : au moins %d grappes", G_MIN), sprintf("observe %d", G))

# --- variations par fenetre ---------------------------------------------------
var_fen <- function(codes) pr[code %in% codes, .(
  dp = mean(logfiscprice[year %in% APRES]) - mean(logfiscprice[year %in% AVANT]),
  dt = mean(tariff[year %in% APRES]) - mean(tariff[year %in% AVANT])), by = .(code, item80)]
d  <- merge(var_fen(ech$code), ech[, .(code, grappe)], by = "code")
dd <- var_fen(TRAITE)
check(abs(dd$dt - (-0.8346)) < 5e-4, "dt_diesel conforme a la valeur ecrite d'avance (-0,8346)",
      sprintf("observe %.4f", dd$dt))
note(sprintf("dt dans l'echantillon : moyenne %.3f, mediane %.3f, min %.3f, max %.3f",
             mean(d$dt), median(d$dt), min(d$dt), max(d$dt)))

# --- estimation -----------------------------------------------------------------
hr("Estimation : dp = a + b * dt")
X <- cbind(1, d$dt); y <- d$dp
XtXi <- solve(crossprod(X))
beta <- drop(XtXi %*% crossprod(X, y))
u <- drop(y - X %*% beta)
meat <- Reduce(`+`, lapply(split(seq_along(u), d$grappe), function(ix) {
  s <- crossprod(X[ix, , drop = FALSE], u[ix]); s %*% t(s) }))
N <- nrow(X); K <- ncol(X)
V <- XtXi %*% meat %*% XtXi * (G / (G - 1)) * ((N - 1) / (N - K))
se <- sqrt(diag(V))
t_b <- beta[2] / se[2]
p_uni <- pt(t_b, df = G - 1, lower.tail = FALSE)
note(sprintf("N = %d articles, G = %d grappes, moyenne de dp = %.4f", N, G, mean(y)))
note(sprintf("a = %.4f (e.-t. %.4f) ; b = %.4f (e.-t. %.4f) ; t = %.2f ; p unilateral (b > 0) = %.4f",
             beta[1], se[1], beta[2], se[2], t_b, p_uni))

E    <- beta[2] * dd$dt
E_ic <- (beta[2] + c(-1, 1) * qt(0.975, G - 1) * se[2]) * dd$dt
res_d <- dd$dp - (beta[1] + beta[2] * dd$dt)
q90 <- quantile(u, C4_CENT, names = FALSE)
note(sprintf("moteurs diesel : dt = %.4f ; dp observe = %.4f ; dp predit = %.4f ; residu = %.4f (rang %d/%d parmi les residus)",
             dd$dt, dd$dp, beta[1] + beta[2] * dd$dt, res_d, sum(u < res_d) + 1L, N + 1L))
note(sprintf("E = b * dt_diesel = %.4f (soit %+.1f %%) ; IC 95 %% [%.4f, %.4f]", E, 100 * (exp(E) - 1),
             min(E_ic), max(E_ic)))
note("repere De Loecker et al. : E pour chaque pente publiee")
for (k in names(DL)) note(sprintf("  %-17s b = %.3f -> E = %.4f", k, DL[[k]], DL[[k]] * dd$dt))

# --- verdict ------------------------------------------------------------------
hr("VERDICT contre le critere ecrit d'avance")
C1 <- beta[2] > 0 && p_uni < 0.05
C2 <- E <= C2_SEUIL
C3 <- beta[2] <= C3_PLAF
C4 <- res_d <= q90
note(sprintf("C1 b > 0 et p < 0,05      : %s (b = %.4f, p = %.4f)", if (C1) "OUI" else "NON", beta[2], p_uni))
note(sprintf("C2 E <= %.4f           : %s (E = %.4f)", C2_SEUIL, if (C2) "OUI" else "NON", E))
note(sprintf("C3 b <= %.3f            : %s", C3_PLAF, if (C3) "OUI" else "NON"))
note(sprintf("C4 residu <= q90 = %.4f : %s (residu = %.4f)", q90, if (C4) "OUI" else "NON", res_d))
verdict <- if (!C1 || !C2) "NE PASSE PAS" else if (C3 && C4) "PASSE" else "LIMITE"
cat("\n  >>> VERDICT : ", verdict, "\n", sep = "")

out <- data.table(
  grandeur = c("N articles", "G grappes", "moyenne dp", "a", "e.-t. a", "b", "e.-t. b", "p unilateral b>0",
               "dt diesel", "dp diesel observe", "residu diesel", "q90 residus", "E = b*dt diesel",
               "E IC95 bas", "E IC95 haut", "seuil C2", "plafond C3", "C1", "C2", "C3", "C4", "verdict"),
  valeur = c(N, G, round(mean(y), 4), round(beta[1], 4), round(se[1], 4), round(beta[2], 4), round(se[2], 4),
             round(p_uni, 4), round(dd$dt, 4), round(dd$dp, 4), round(res_d, 4), round(q90, 4), round(E, 4),
             round(min(E_ic), 4), round(max(E_ic), 4), round(C2_SEUIL, 4), round(C3_PLAF, 3),
             C1, C2, C3, C4, verdict))
fwrite(out, p_tab("22_dose_verdict.csv"))
tex <- c("\\begin{tabular}{lr}", "\\toprule", "Grandeur & Valeur \\\\", "\\midrule",
         sprintf("%s & %s \\\\", out$grandeur, out$valeur), "\\bottomrule",
         sprintf("\\multicolumn{2}{l}{\\footnotesize MCO, %d articles WPI, grappes = %d series tarifaires (CR1).} \\\\", N, G),
         "\\end{tabular}")
writeLines(tex, p_tab("22_dose_verdict.tex"))
note("tables : ", p_tab("22_dose_verdict.csv"), " / .tex")

g <- ggplot(d, aes(dt, dp)) +
  geom_point(colour = "grey55", size = 1.4) +
  geom_abline(intercept = beta[1], slope = beta[2]) +
  geom_point(data = dd, colour = "firebrick", size = 2.8) +
  annotate("text", x = dd$dt, y = dd$dp, label = "Diesel Engines", colour = "firebrick",
           hjust = -0.1, vjust = -0.6, size = 3.3) +
  labs(x = "Variation du tarif (fraction), 1995-2001 moins 1987-1990",
       y = "Variation du log-prix WPI, 1995-2001 moins 1987-1990") +
  theme_minimal(base_size = 11)
ggsave(p_fig("22_dose_prix_tarif.pdf"), g, width = 7, height = 5)
note("figure : ", p_fig("22_dose_prix_tarif.pdf"))
