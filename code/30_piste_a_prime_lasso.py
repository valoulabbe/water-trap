# ---------------------------------------------------------------------------
# 30_piste_a_prime_lasso.py -- variante A'-L de la porte A' :
#   la selection LASSO des auteurs (Ryan & Sudarshan 2022) retrouve-t-elle un
#   premier stage HORS ECHANTILLON pour la profondeur du puits ?
#
# CRITERE FIXE AVANT ESTIMATION : memo/piste_a_prime_lasso_critere.md
# Les seuils ci-dessous en sont la copie ; ne pas les changer.
#
# Python et non R, a la demande de Valentine (06/10/2026). Dependances :
# numpy, pandas, scipy, scikit-learn (versions ecrites dans le log).
#
# PORTEE : premier stage seulement. AUCUNE variable de resultat, AUCUN second
# stage, AUCUN appariement SHRUG.
#
# LASSO "rigoureux" (formules de rlasso / lassopack, Belloni-Chernozhukov-Hansen) :
#   objectif (1/N)||y - Zb||^2 + (lambda/N) sum_j psi_j |b_j|
#   lambda = 2 c sqrt(N) Phi^-1(1 - gamma/(2p)),  c = 1.1,  gamma = 0.1/log(G)
#   psi_j (groupe par depart) = sqrt( (1/N) sum_g (sum_{i in g} z_ij e_i)^2 )
#   residus initiaux : MCO sur les 5 candidats les plus correles ; 15 iterations
#   au plus ; residus post-lasso.
# Resolution : sklearn.linear_model.Lasso sur Z_j / psi_j, alpha = lambda/(2N)
# (meme objectif divise par 2).
#
# LANCEMENT (racine du depot) :
#     python code/30_piste_a_prime_lasso.py               # reprend
#     python code/30_piste_a_prime_lasso.py --force       # refait l'echantillon
#     python code/30_piste_a_prime_lasso.py --echantillon # echantillon seul, sans estimation
#
# PREREQUIS : build/29_plis_departs.csv (ecrit par code/29_piste_a_prime_geologie_fine.R)
#
# ETAPE RESUMABLE (build/) :
#   1. 30_echantillon.pkl   agriculteurs + profondeur + 419 candidats + depart
#
# Sorties : output/tables/30_*.csv, output/logs/30_piste_a_prime_lasso.log
# ---------------------------------------------------------------------------

import os
import re
import sys
import time
import warnings
from datetime import datetime

import numpy as np
import pandas as pd
import scipy
import sklearn
from scipy.stats import norm
from sklearn.linear_model import Lasso

# --- seuils du critere (memo/piste_a_prime_lasso_critere.md) ----------------
SEUIL_GAIN_R2CV = 0.05
N_ATTENDU = 4006          # echantillon de A'
DEPARTS_ATTENDUS = 304
N_CANDIDATS = 419         # ensemble MAIN des auteurs
C_RL = 1.1
MAX_ITER_PSI = 15

# Instruments retenus par les auteurs (rationing_main.log, l. 2157 ; Z = 419)
LISTE_AUTEURS = ["rock_area_1", "rock_area_4", "rock_area_6", "rock_area_15",
                 "rock_area_20", "rock_type_34", "rock_area2_4", "rock_area2_10",
                 "ltot5km_area115", "ltot5km_area1115", "dist2fault_area112",
                 "dist2fault_area1114", "aquifer_type_4"]

RS = os.path.join("raw", "nicholasryan2021", "20200932data", "rationing_commons",
                  "data", "work")
F_FAR = os.path.join(RS, "marginal_analysis_sample.dta")
F_CROP = os.path.join(RS, "marginal_analysis_sample_crop_level.dta")
F_PLIS = os.path.join("build", "29_plis_departs.csv")
F_ECH = os.path.join("build", "30_echantillon.pkl")
F_LOG = os.path.join("output", "logs", "30_piste_a_prime_lasso.log")
D_TAB = os.path.join("output", "tables")

FORCE = "--force" in sys.argv
ECH_SEUL = "--echantillon" in sys.argv


# --- journal ------------------------------------------------------------------
class Journal:
    def __init__(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.f = open(path, "w", encoding="utf-8")

    def __call__(self, *a):
        s = " ".join(str(x) for x in a)
        print(s, flush=True)
        self.f.write(s + "\n")
        self.f.flush()

    def t(self, *a):
        self("[" + datetime.now().strftime("%Y-%m-%d %H:%M:%S") + "]", *a)

    def hr(self, titre):
        self("\n" + "-" * 78 + "\n" + titre + "\n" + "-" * 78)


def check(cond, quoi, detail=""):
    if cond:
        log("  [OK]   " + quoi)
        return
    log("  [FAIL] " + quoi + ("\n         " + detail if detail else ""))
    raise SystemExit("VALIDATION FAILED: " + quoi + (" -- " + detail if detail else ""))


# --- candidats : ensemble MAIN de rationing_profit_regressions.do -------------
MOTIFS = [
    ("fractures", r"^(dist2fault_km|ltot_1km|ltot_5km)$", 3),
    ("parts de roche", r"^rock_area_\d+$", 65),
    ("types de roche", r"^rock_type_\d+$", 65),
    ("aquiferes", r"^aquifer_type_\d+$", 20),
    ("carres des fractures", r"^(dist2fault_km2|ltot_1km2|ltot_5km2)$", 3),
    ("carres des parts", r"^rock_area2_\d+$", 65),
    ("fractures x fractures", r"^(ltot1km_ltot5km11|ltot1km_dist11|ltot5km_dist11)$", 3),
    ("fractures x parts", r"^(ltot1km_area11|ltot5km_area11|dist2fault_area11)\d+$", 195),
]
BASE_A_PRIME = MOTIFS[0][1], MOTIFS[1][1], MOTIFS[2][1], MOTIFS[3][1]


def colonnes_candidates(noms):
    out = []
    for lab, motif, attendu in MOTIFS:
        c = [n for n in noms if re.match(motif, n)]
        check(len(c) == attendu, f"candidats, {lab} : {attendu} colonnes", f"observe {len(c)}")
        out += c
    return out


# --- etape 1 : echantillon ------------------------------------------------------
def construire_echantillon():
    noms = list(pd.read_stata(F_FAR, iterator=True).variable_labels().keys())
    cand = colonnes_candidates(noms)
    check(len(cand) == N_CANDIDATS, f"{N_CANDIDATS} candidats au total", f"observe {len(cand)}")
    base = [n for n in cand if any(re.match(m, n) for m in BASE_A_PRIME)]
    vars_ = ["f_id", "SDO", "farmer_well_depth", "elevation", "slope"] + cand
    log.t("lecture de", F_FAR)
    d = pd.read_stata(F_FAR, columns=vars_, convert_categoricals=False)
    check(len(d) == 6215, "marginal_analysis_sample : 6 215 lignes", f"observe {len(d)}")
    check(d["f_id"].is_unique, "marginal_analysis_sample : f_id unique")
    log.t("lecture des departs dans", F_CROP)
    fe = pd.read_stata(F_CROP, columns=["f_id", "sdo_feeder_code"],
                       convert_categoricals=False).drop_duplicates()
    check(fe["f_id"].is_unique, "departs : un depart par agriculteur")
    d = d.merge(fe, on="f_id", how="left")
    d["elevation"] = pd.to_numeric(d["elevation"], errors="coerce")
    d["slope"] = pd.to_numeric(d["slope"], errors="coerce")

    # memes filtres, dans le meme ordre, que l'etape 1 de A' (script 29)
    n0 = len(d)
    d = d[d["farmer_well_depth"].notna() & (d["farmer_well_depth"] > 0)]
    log(f"  profondeur > 0 et renseignee : {len(d)} / {n0}")
    n1 = len(d)
    d = d[d[base].notna().all(axis=1)]
    log(f"  bloc geologie de A' complet : {len(d)} / {n1}")
    n2 = len(d)
    d = d[d["elevation"].notna() & d["slope"].notna()]
    log(f"  altitude et pente numeriques : {len(d)} / {n2}")
    n3 = len(d)
    d = d[d["sdo_feeder_code"].notna()]
    log(f"  depart connu : {len(d)} / {n3}")
    n_na = int(d[cand].isna().sum().sum())
    check(n_na == 0, "aucune valeur manquante dans les 419 candidats", f"{n_na} manquantes")
    return d.sort_values("f_id").reset_index(drop=True)


def etape(label, path, build):
    t0 = time.time()
    if os.path.exists(path) and not FORCE:
        log.t(f"{label} : deja fait, relu depuis {path}")
        return pd.read_pickle(path)
    log.t(f"{label} : debut ({'--force' if FORCE else 'sortie absente'})")
    out = build()
    tmp = path.replace(".pkl", ".part.pkl")
    out.to_pickle(tmp)
    os.replace(tmp, path)
    log.t(f"{label} : fini ({time.time() - t0:.1f} s)")
    return out


# --- LASSO rigoureux ------------------------------------------------------------
def ols(X, y):
    b, *_ = np.linalg.lstsq(X, y, rcond=None)
    return b


def charges(Z, e, groupes):
    """Ponderations psi_j : groupees si `groupes` est donne, sinon heteroscedastiques."""
    n = Z.shape[0]
    if groupes is None:
        return np.sqrt(((Z * e[:, None]) ** 2).mean(axis=0))
    u = pd.DataFrame(Z * e[:, None]).groupby(groupes).sum().to_numpy()
    return np.sqrt((u ** 2).sum(axis=0) / n)


def rlasso(y, Z, groupes=None):
    """Indices des colonnes de Z retenues. y et Z deja purges des controles."""
    n, p = Z.shape
    g_n = len(np.unique(groupes)) if groupes is not None else n
    gamma = 0.1 / np.log(g_n)
    lam = 2 * C_RL * np.sqrt(n) * norm.ppf(1 - gamma / (2 * p))
    # residus initiaux : MCO sur les 5 candidats les plus correles
    zc = Z - Z.mean(axis=0)
    cor = np.abs(zc.T @ (y - y.mean())) / (np.sqrt((zc ** 2).sum(axis=0)) *
                                           np.sqrt(((y - y.mean()) ** 2).sum()) + 1e-300)
    top = np.argsort(-cor)[:5]
    e = y - Z[:, top] @ ols(Z[:, top], y)
    psi_old = None
    sel = np.array([], dtype=int)
    for _ in range(MAX_ITER_PSI):
        psi = charges(Z, e, groupes)
        psi = np.where(psi > 0, psi, np.inf)        # colonne nulle : jamais retenue
        m = Lasso(alpha=lam / (2 * n), fit_intercept=False, tol=1e-10, max_iter=200000)
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            m.fit(Z / psi, y)
        sel = np.flatnonzero(m.coef_ != 0)
        e = y - Z[:, sel] @ ols(Z[:, sel], y) if len(sel) else y.copy()
        if psi_old is not None and np.nanmax(np.abs(psi - psi_old) /
                                             np.where(np.isfinite(psi_old), psi_old, 1)) < 1e-6:
            break
        psi_old = psi
    return sel


# --- validation croisee ---------------------------------------------------------
def r2_cv(y, pred):
    return 1 - ((y - pred) ** 2).sum() / (y ** 2).sum()


def cv(y, Z, C, plis, depart, groupe=True, liste_fixe=None):
    """Renvoie (R2 controles, R2 post-lasso, selections par pli)."""
    pred_c = np.zeros_like(y)
    pred_l = np.zeros_like(y)
    selections = {}
    for k in np.unique(plis):
        te = plis == k
        tr = ~te
        bc = ols(C[tr], y[tr])
        pred_c[te] = C[te] @ bc
        if liste_fixe is None:
            # controles retires dans l'apprentissage seulement
            yr = y[tr] - C[tr] @ bc
            Zr = Z[tr] - C[tr] @ ols(C[tr], Z[tr])
            vivantes = np.flatnonzero(Zr.std(axis=0) > 1e-12)
            s = vivantes[rlasso(yr, Zr[:, vivantes], depart[tr] if groupe else None)]
        else:
            s = np.asarray(liste_fixe, dtype=int)
        selections[k] = s
        if len(s):
            X = np.column_stack([Z[:, s], C])
            pred_l[te] = X[te] @ ols(X[tr], y[tr])
        else:
            pred_l[te] = pred_c[te]
    return r2_cv(y, pred_c), r2_cv(y, pred_l), selections


def f_partiel_groupe(y, Z, C, groupes, n_fe):
    """F de Wald des colonnes Z, erreurs groupees (correction de petit echantillon de Stata)."""
    X = np.column_stack([Z, C])
    n, k = X.shape
    b = ols(X, y)
    e = y - X @ b
    xx_inv = np.linalg.pinv(X.T @ X)
    u = pd.DataFrame(X * e[:, None]).groupby(groupes).sum().to_numpy()
    g = u.shape[0]
    V = xx_inv @ (u.T @ u) @ xx_inv * (g / (g - 1)) * ((n - 1) / (n - k - n_fe))
    q = Z.shape[1]
    bz, Vz = b[:q], V[:q, :q]
    return float(bz @ np.linalg.solve(Vz, bz) / q), q, g


# ===========================================================================
if __name__ == "__main__":
    os.makedirs(D_TAB, exist_ok=True)
    log = Journal(F_LOG)
    log("=" * 78)
    log("LOG:", F_LOG)
    log("Run started:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    log(f"python {sys.version.split()[0]} ; numpy {np.__version__} ; pandas {pd.__version__} ; "
        f"scipy {scipy.__version__} ; scikit-learn {sklearn.__version__}")
    log("=" * 78)
    log("ETAPE 30 -- PISTE A'-L : SELECTION LASSO DES AUTEURS, PREMIER STAGE HORS ECHANTILLON")
    log("Critere fixe avant estimation : memo/piste_a_prime_lasso_critere.md")
    log(f"  gain de R2 hors echantillon (plis de A', selection refaite par pli) >= {SEUIL_GAIN_R2CV}")
    log("Aucun second stage, aucune variable de resultat.")

    log.hr("30a. Echantillon (etape 1)")
    check(os.path.exists(F_PLIS), "plis de A' presents (" + F_PLIS + ")",
          "lancer d'abord : Rscript code/29_piste_a_prime_geologie_fine.R")
    d = etape("etape 1/1 echantillon", F_ECH, construire_echantillon)
    plis_dep = pd.read_csv(F_PLIS)
    check(len(d) == N_ATTENDU, f"echantillon identique a A' : N = {N_ATTENDU}", f"observe {len(d)}")
    check(set(d["sdo_feeder_code"]) == set(plis_dep["sdo_feeder_code"])
          and len(plis_dep) == DEPARTS_ATTENDUS,
          f"memes {DEPARTS_ATTENDUS} departs que A'")
    d = d.merge(plis_dep, on="sdo_feeder_code", how="left")
    check(d["pli"].notna().all(), "chaque agriculteur a un pli")
    if ECH_SEUL:
        log("--echantillon : arret avant toute estimation.")
        raise SystemExit(0)

    log.hr("30b. Porte")
    cand = [c for c in colonnes_candidates(list(d.columns)) if d[c].nunique() > 1]
    log(f"  candidats non constants : {len(cand)} / {N_CANDIDATS}")
    sdo = d["SDO"].to_numpy()
    dm = lambda M: M - pd.DataFrame(M).groupby(sdo).transform("mean").to_numpy()
    y = dm(d[["farmer_well_depth"]].to_numpy(float))[:, 0]
    Z = dm(d[cand].to_numpy(float))
    C = dm(d[["elevation", "slope"]].to_numpy(float))
    plis = d["pli"].to_numpy(int)
    depart = d["sdo_feeder_code"].to_numpy()

    log.t("validation croisee, ponderations groupees par depart")
    r_c, r_l, sel_plis = cv(y, Z, C, plis, depart, groupe=True)
    gain = r_l - r_c
    nb = [len(s) for s in sel_plis.values()]
    log(f"  R2 hors echantillon (intra-SDO) : controles seuls {r_c:.3f} ; post-lasso + controles {r_l:.3f}")
    log(f"  gain : {gain:.3f}  (seuil {SEUIL_GAIN_R2CV}) -> {'PASSE' if gain >= SEUIL_GAIN_R2CV else 'ECHOUE'}")
    log(f"  instruments retenus par pli : {nb}")

    # --- hors critere ----------------------------------------------------------
    log.hr("30c. Rapporte a cote du verdict (hors critere)")
    yr = y - C @ ols(C, y)
    Zr = Z - C @ ols(C, Z)
    log.t("selection sur tout l'echantillon")
    s_full = rlasso(yr, Zr, depart)
    noms_full = [cand[i] for i in s_full]
    log(f"  retenus sur tout l'echantillon ({len(noms_full)}) : {' '.join(noms_full) or '(aucun)'}")
    commun = sorted(set(noms_full) & set(LISTE_AUTEURS))
    log(f"  liste des auteurs ({len(LISTE_AUTEURS)}) : {' '.join(LISTE_AUTEURS)}")
    log(f"  en commun : {len(commun)} : {' '.join(commun) or '(aucun)'}")
    if len(s_full):
        F, q, g = f_partiel_groupe(y, Z[:, s_full], C, depart, n_fe=d["SDO"].nunique())
        log(f"  F partiel post-lasso (groupe par depart) : {F:.2f}  (q = {q}, {g} departs)")
    else:
        F = np.nan

    freq = pd.Series([cand[i] for s in sel_plis.values() for i in s]).value_counts()
    tab_sel = pd.DataFrame({"instrument": freq.index, "plis_sur_10": freq.values})
    tab_sel["tout_echantillon"] = tab_sel["instrument"].isin(noms_full)
    tab_sel["liste_auteurs"] = tab_sel["instrument"].isin(LISTE_AUTEURS)
    log("  frequence de selection sur les 10 plis :")
    log(tab_sel.to_string(index=False) if len(tab_sel) else "  (aucune selection)")
    tab_sel.to_csv(os.path.join(D_TAB, "30_selection_lasso.csv"), index=False)

    variantes = [("principal (rappel)", r_c, r_l)]
    log.t("variante : ponderations heteroscedastiques")
    a, b, _ = cv(y, Z, C, plis, depart, groupe=False)
    variantes.append(("ponderations heteroscedastiques", a, b))
    log.t("variante : un pli par SDO")
    plis_sdo = pd.factorize(sdo)[0]
    a, b, _ = cv(y, Z, C, plis_sdo, depart, groupe=True)
    variantes.append(("un pli par SDO (6 plis)", a, b))
    log.t("variante : liste fixe choisie sur tout l'echantillon (fuit)")
    a, b, _ = cv(y, Z, C, plis, depart, liste_fixe=s_full)
    variantes.append(("naif : liste fixe, choisie sur tout l'echantillon", a, b))
    log.t("variante : liste des auteurs, fixe")
    idx_aut = [cand.index(v) for v in LISTE_AUTEURS if v in cand]
    a, b, _ = cv(y, Z, C, plis, depart, liste_fixe=idx_aut)
    variantes.append(("liste des auteurs, fixe", a, b))
    tab_var = pd.DataFrame(variantes, columns=["variante", "r2cv_controles", "r2cv_lasso_controles"])
    tab_var["gain"] = tab_var["r2cv_lasso_controles"] - tab_var["r2cv_controles"]
    log(tab_var.round(3).to_string(index=False))
    tab_var.to_csv(os.path.join(D_TAB, "30_premier_stage_lasso_variantes.csv"), index=False)

    verdict = gain >= SEUIL_GAIN_R2CV
    pd.DataFrame([{
        "n_agriculteurs": len(d), "n_departs": len(np.unique(depart)), "n_candidats": len(cand),
        "r2cv_controles": r_c, "r2cv_lasso_controles": r_l, "gain_r2cv": gain,
        "seuil_gain": SEUIL_GAIN_R2CV, "n_retenus_min": min(nb), "n_retenus_max": max(nb),
        "n_retenus_tout": len(s_full), "f_partiel_tout": F,
        "verdict": "PASSE" if verdict else "ECHOUE"}]).to_csv(
        os.path.join(D_TAB, "30_premier_stage_lasso_verdict.csv"), index=False)

    log.hr("30d. Verdict")
    log(f"Gain de R2 hors echantillon {gain:.3f} >= {SEUIL_GAIN_R2CV} : "
        f"{'rempli' if verdict else 'NON rempli'}")
    log(f"VERDICT DE LA PORTE A'-L : {'PASSE' if verdict else 'ECHOUE'}")
    log("Rappel : passer A'-L ne rouvre pas la piste A (portes B et C restent).")
    log("\nRun finished:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
