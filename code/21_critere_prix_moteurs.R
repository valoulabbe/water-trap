# ---------------------------------------------------------------------------
# 21_critere_prix_moteurs.R -- Piste G, verrou 0, seconde moitie : le choc
#   tarifaire sur les moteurs diesel (WPI 1311010105) atteint-il le prix ?
#
# PORTEE : un article traite, un panier temoin, un chiffre, un verdict.
# Aucune variable d'issue, aucune exposition, rien sur l'ASI.
#
# DIVULGATION : la serie de prix NOMINALE des moteurs diesel a ete vue a
#   l'etape 20 (log 20_inspection_topalova.log) avant l'ecriture de ce critere.
#   Ni le panier, ni aucun deflateur, ni aucun prix relatif n'avaient ete vus.
#
# ===========================================================================
# CRITERE (ecrit le 2026-10-02 AVANT toute lecture des prix du panier ;
#          ne bouge plus, meme en cas d'echec)
# ===========================================================================
# Enonce : « le prix reel des moteurs diesel (1311010105), deflate, baisse
#   apres 1994 relativement a un panier d'articles WPI non touches par la
#   liberalisation ».
#
# Variable de prix : logfiscprice (indice en annee fiscale, log), celle que
#   Topalova (2010, tableau 7) apparie au tarif. Annee = libelle du fichier.
#
# Deflateur : le panier temoin lui-meme (moyenne non ponderee des log-prix
#   des articles du panier). Raisons : (i) le paquet ne contient pas le WPI
#   agrege ni les poids WPI ; (ii) la statistique decisive est une double
#   difference de log-prix, invariante a tout deflateur commun -- deflater par
#   le WPI agrege puis comparer au panier donnerait le meme chiffre ; (iii) pas
#   de source externe ajoutee en cours de verrou. Poids egaux faute de poids.
#
# Fenetres : AVANT = 1987-1990 ; APRES = 1995-2001 ; 1991-1994 = transition,
#   exclue. 1991 est retire de l'avant (contre la suggestion 1987-1991) parce
#   que la devaluation de juillet 1991 et le budget de juillet 1991 tombent
#   dans l'annee 1991 que le libelle soit civil ou fiscal (1991-92) : l'avant
#   doit etre pur. APRES commence en 1995, premiere annee entiere apres que le
#   tarif soit tombe a 25 % (1994), et s'arrete en 2001, derniere annee
#   tarifee.
#
# Statistique : pour chaque article i, c_i = moyenne(log p, APRES) -
#   moyenne(log p, AVANT). D = c_diesel - moyenne_j(c_j), j dans le panier.
#   D < 0 = le prix des moteurs diesel baisse relativement au panier.
#
# Seuil (les DEUX conditions, chiffrees d'avance) :
#   S1 magnitude : D <= log(0,90) = -0,105, soit une baisse relative d'au
#      moins 10 %. Repere : avec le tarif moyen AVANT (~1,08) et APRES (~0,23),
#      un transfert integral au prix d'import donnerait log(1,23/2,08) ~ -0,53 ;
#      -0,105 equivaut a ~20 % de ce transfert. En dessous, le choc sur le cout
#      du substitut prive est trop faible pour etre le levier d'une piste.
#   S2 singularite : D est inferieur au 10e centile de la distribution placebo
#      {D_j}, ou D_j = c_j - moyenne(c_k, k != j) pour chaque article j du
#      panier. Sans S2, une baisse de 10 % peut n'etre que la dispersion
#      ordinaire des prix relatifs entre articles.
#   VERDICT : S1 ET S2 -> le choc PASSE ; ni S1 ni S2 -> NE PASSE PAS ;
#      une seule des deux -> LIMITE (rapporte comme limite, pas arrondi).
#
# Hors critere (montre, ne decide rien) : « internal combustion engines »
#   (1311010104), meme serie tarifaire, donc traite : exclu du panier.
#
# ===========================================================================
# REGLE DU PANIER (sur le TARIF seulement ; ecrite avant d'en compter les
#   articles)
# ===========================================================================
#   R1 tarif observe chaque annee 1987-2001 (un tarif manquant n'est pas un
#      tarif inchange : les prix administres -- produits petroliers -- sont
#      ainsi exclus).
#   R2 max(tarif) - min(tarif) sur 1987-2001 < 0,10 (10 points ad valorem),
#      sur toute la trajectoire et pas seulement entre les bornes.
#   R3 couverture : logfiscprice non manquant chaque annee des deux fenetres
#      (porte sur la presence d'une valeur, jamais sur sa valeur).
#   R4 articles 1311010105 et 1311010104 exclus (traites).
#   Taille minimale : >= 10 articles apres R1-R4 ; sinon ARRET, avant tout
#   calcul de prix.
#
# LIMITE CONNUE (consignee, non quantifiee) : la roupie est fortement
#   devaluee en juillet 1991 (~ -18 % contre le dollar en deux temps), ce qui
#   rencherit en roupies les importations au moment ou le tarif baisse. Les
#   deux effets jouent en sens inverse sur le prix interieur des moteurs
#   diesel (et inegalement sur le panier selon la part importee de chaque
#   article). Un prix relatif qui ne bouge pas ne prouve donc pas que le tarif
#   n'a eu aucun effet ; il prouve que le prix paye n'a pas baisse.
#
# LANCEMENT (racine du depot ; quelques secondes) :
#     Rscript code/21_critere_prix_moteurs.R
#
# Sorties : output/tables/21_panier_temoin.csv (articles, tarifs ; aucun prix)
#           output/tables/21_critere_verdict.csv / .tex
#           output/figures/21_prix_relatif_moteurs.pdf
#           output/logs/21_critere_prix_moteurs.log
# ---------------------------------------------------------------------------

source(file.path("code", "00_utils.R"))
ensure_dirs()
p_tab <- function(...) file.path("output", "tables", ...)
p_fig <- function(...) file.path("output", "figures", ...)

log_open(p_log("21_critere_prix_moteurs.log"))
on.exit(log_close(), add = TRUE)
suppressWarnings(suppressMessages({ library(haven); library(ggplot2) }))

# Parametres du critere : copie exacte de l'en-tete, journalisee avant lecture.
TRAITE   <- "1311010105"
FRERE    <- "1311010104"
AVANT    <- 1987:1990
APRES    <- 1995:2001
ANS_TAR  <- 1987:2001
X_TARIF  <- 0.10
N_MIN    <- 10L
S1_SEUIL <- log(0.90)
S2_CENT  <- 0.10

hr("CRITERE (fixe avant lecture des prix du panier)")
note("article traite : ", TRAITE, " (Diesel Engines) ; variable : logfiscprice")
note("deflateur : panier temoin (moyenne non ponderee des log-prix) ; invariance a tout deflateur commun")
note("AVANT = ", paste(range(AVANT), collapse = "-"), " ; APRES = ", paste(range(APRES), collapse = "-"),
     " ; 1991-1994 transition exclue")
note(sprintf("S1 : D <= log(0,90) = %.4f", S1_SEUIL))
note(sprintf("S2 : D < centile %.0f %% de la distribution placebo des articles du panier", 100 * S2_CENT))
note("verdict : S1 et S2 = PASSE ; aucun = NE PASSE PAS ; un seul = LIMITE")
note(sprintf("panier : tarif observe %d-%d, amplitude < %.2f, prix presents sur les deux fenetres, traites exclus ; minimum %d articles",
             min(ANS_TAR), max(ANS_TAR), X_TARIF, N_MIN))

hr("LIMITE CONNUE -- devaluation de juillet 1991")
note("La roupie est fortement devaluee en juillet 1991 : les importations rencherissent en roupies")
note("au moment ou le tarif baisse. Effets de sens oppose sur le prix interieur des moteurs diesel.")
note("Un prix relatif qui ne bouge pas ne prouve PAS que le tarif n'a eu aucun effet ; il dit seulement")
note("que le prix paye n'a pas baisse relativement au panier. Non quantifie dans cet exercice.")

# --- lecture ----------------------------------------------------------------
pr <- as.data.table(zap_labels(read_dta(p_raw("topalova2010", "113765-V1", "_data", "price_data.dta"))))
check_rows(pr, 5888L, "price_data")
check_unique(pr, c("code80", "year"), "price_data")
pr[, code := sprintf("%.0f", code80)]
check(all(c(TRAITE, FRERE) %in% pr$code), "articles traites presents")

# --- Etape 2 : panier, regle sur le TARIF seulement -------------------------
hr("Etape 2 -- panier temoin : regle sur le tarif")
tar <- pr[year %in% ANS_TAR, .(n_tar = sum(!is.na(tariff)),
                               t_min = min(tariff, na.rm = TRUE), t_max = max(tariff, na.rm = TRUE),
                               t_1987 = tariff[year == 1987], t_2001 = tariff[year == 2001]),
          by = .(code, item80)]
tar[n_tar == 0, `:=`(t_min = NA_real_, t_max = NA_real_)]
r1 <- tar[n_tar == length(ANS_TAR)]
note(sprintf("R1 tarif observe chaque annee %d-%d : %d articles sur %d", min(ANS_TAR), max(ANS_TAR), nrow(r1), nrow(tar)))
r2 <- r1[t_max - t_min < X_TARIF]
note(sprintf("R2 amplitude du tarif < %.2f : %d articles", X_TARIF, nrow(r2)))
cov <- pr[year %in% c(AVANT, APRES), .(n_prix = sum(!is.na(logfiscprice))), by = code]
r3 <- r2[code %in% cov[n_prix == length(c(AVANT, APRES)), code]]
note(sprintf("R3 prix presents chaque annee des deux fenetres : %d articles", nrow(r3)))
panier <- r3[!code %in% c(TRAITE, FRERE)]
note(sprintf("R4 traites exclus : %d articles dans le panier", nrow(panier)))
cat("\n  code       | tarif min-max | 1987 -> 2001 | description\n")
for (i in seq_len(nrow(panier)))
  cat(sprintf("  %s | %.3f-%.3f   | %.3f -> %.3f | %s\n", panier$code[i], panier$t_min[i], panier$t_max[i],
              panier$t_1987[i], panier$t_2001[i], panier$item80[i]))
fwrite(panier, p_tab("21_panier_temoin.csv"))
note("panier ecrit : ", p_tab("21_panier_temoin.csv"))
note("tarif de l'article traite :")
print(tar[code == TRAITE])
check(nrow(panier) >= N_MIN, sprintf("panier d'au moins %d articles -- sinon ARRET avant tout prix", N_MIN),
      sprintf("seulement %d articles retenus", nrow(panier)))
