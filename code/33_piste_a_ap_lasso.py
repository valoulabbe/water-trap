# ---------------------------------------------------------------------------
# 33_piste_a_ap_lasso.py -- porte du premier stage de l'AP avec les couches
#   geologiques FINES : la geologie predit-elle la profondeur de la nappe aux
#   puits CGWB hors echantillon, au-dela des effets fixes de district ?
#
# CRITERE FIXE AVANT ESTIMATION : memo/piste_a_ap_fine_critere.md (commit 9b7eccc)
# Les seuils ci-dessous en sont la copie ; ne pas les changer.
#
# Entree : build/32_puits_variables.csv (code/32_piste_a_ap_couches_fines.R).
# LASSO : rlasso de code/30_piste_a_prime_lasso.py (reutilise, pas copie).
#
# PORTEE : premier stage seulement. AUCUNE variable de resultat, AUCUN village.
#
# LANCEMENT (racine du depot) :
#     python code/33_piste_a_ap_lasso.py
# Sorties : output/tables/33_*.csv, output/logs/33_piste_a_ap_lasso.log
# ---------------------------------------------------------------------------

import importlib.util
import os
import sys
from datetime import datetime

import numpy as np
import pandas as pd
import scipy
import sklearn


def charger(nom, fichier):
    spec = importlib.util.spec_from_file_location(nom, os.path.join("code", fichier))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


A = charger("a_prime_lasso", "30_piste_a_prime_lasso.py")
C4 = charger("a_prime_lasso_c4", "31_piste_a_prime_lasso_c4.py")

# --- seuils du critere (memo/piste_a_ap_fine_critere.md) ----------------------
SEUIL_GAIN_R2CV = 0.05
N_ATTENDU = 825
N_PLIS = 10
CELLULE_M = 20000
GRAINE = 20261007

F_IN = os.path.join("build", "32_puits_variables.csv")
F_LOG = os.path.join("output", "logs", "33_piste_a_ap_lasso.log")
D_TAB = os.path.join("output", "tables")
CTRL = ["elev", "slope_win", "relelev_win", "soil_ph", "soil_oc"]


def colonnes(d, motif):
    return [c for c in d.columns if pd.Series([c]).str.match(motif).iloc[0]]


def blocs(d):
    """Construit les blocs d'instruments du critere ; renvoie {nom: DataFrame}."""
    lit_c = colonnes(d, r"^lit_c_\d+$")
    lit_s = colonnes(d, r"^lit_s[15]_\d+$")
    lit_s1 = colonnes(d, r"^lit_s1_\d+$")
    pro = colonnes(d, r"^pro_(c|s1|s5)_\d+$")
    sq = lambda cols: pd.DataFrame({c + "_sq": d[c] ** 2 for c in cols}, index=d.index)

    def fractures(pref):
        f = [f"{pref}_dist", f"{pref}_l1", f"{pref}_l5"]
        base = d[f]
        inter = pd.DataFrame({f"{a}_x_{b}": d[a] * d[b] for a in f for b in lit_s1}, index=d.index)
        return base, sq(f), inter

    lith = pd.concat([d[lit_c], d[lit_s], sq(lit_s)], axis=1)
    f50, f50sq, f50x = fractures("f50")
    f250, f250sq, f250x = fractures("f250")
    L = pd.concat([lith, f50, f50sq, f50x], axis=1)
    return {
        "L": L,
        "P": d[pro],
        "L+P": pd.concat([L, d[pro]], axis=1),
        "L-250k": pd.concat([lith, f250, f250sq, f250x], axis=1),
        "lithologie seule": lith,
        "fractures seules": pd.concat([f50, f50sq], axis=1),
    }


def plis_cellules(x, y):
    cell = pd.Series(list(zip(np.floor(x / CELLULE_M).astype(int), np.floor(y / CELLULE_M).astype(int))))
    uniq = sorted(set(cell))
    rng = np.random.default_rng(GRAINE)
    pli = rng.permutation(np.arange(len(uniq)) % N_PLIS)
    m = dict(zip(uniq, pli))
    return cell.map(m).to_numpy(int), len(uniq)


if __name__ == "__main__":
    os.makedirs(D_TAB, exist_ok=True)
    log = A.Journal(F_LOG)
    A.log = log
    check = A.check
    log("=" * 78)
    log("LOG:", F_LOG)
    log("Run started:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    log(f"python {sys.version.split()[0]} ; numpy {np.__version__} ; pandas {pd.__version__} ; "
        f"scipy {scipy.__version__} ; scikit-learn {sklearn.__version__}")
    log("=" * 78)
    log("ETAPE 33 -- PISTE A, AP : PREMIER STAGE AVEC COUCHES FINES (LASSO, HORS ECHANTILLON)")
    log("Critere fixe avant estimation : memo/piste_a_ap_fine_critere.md")
    log(f"  gain de R2 hors echantillon du bloc L (10 plis de cellules de 20 km) >= {SEUIL_GAIN_R2CV}")
    log("Aucun second stage, aucune variable de resultat.")

    log.hr("33a. Donnees")
    check(os.path.exists(F_IN), "entree presente (" + F_IN + ")",
          "lancer d'abord : Rscript code/32_piste_a_ap_couches_fines.R")
    # la table doit etre plus recente que toutes les sorties d'etape du script 32
    amont = [os.path.join("build", f) for f in os.listdir("build")
             if f.startswith("32_") and f != os.path.basename(F_IN)]
    perimes = [f for f in amont if os.path.getmtime(f) > os.path.getmtime(F_IN)]
    check(not perimes, "entree a jour (plus recente que les etapes du script 32)",
          "plus recent que la table : " + ", ".join(perimes) + " -- le script 32 n'a pas abouti")
    d = pd.read_csv(F_IN)
    check(len(d) == N_ATTENDU, f"N = {N_ATTENDU} puits (echantillon du script 10)", f"observe {len(d)}")
    check(d["WLCODE"].is_unique, "WLCODE unique")
    check(d[CTRL + ["depth"]].notna().all().all(), "profondeur et controles complets")
    B = blocs(d)
    for k, v in B.items():
        check(v.notna().all().all(), f"bloc {k} sans valeur manquante")
        log(f"  bloc {k} : {v.shape[1]} colonnes, dont non constantes {int((v.nunique() > 1).sum())}")

    dist = d["pc11_district_id"].to_numpy()
    dm = lambda M: M - pd.DataFrame(M).groupby(dist).transform("mean").to_numpy()
    y = dm(d[["depth"]].to_numpy(float))[:, 0]
    C = dm(d[CTRL].to_numpy(float))
    plis, n_cell = plis_cellules(d["x_laea"].to_numpy(), d["y_laea"].to_numpy())
    log(f"  {len(d)} puits, {len(np.unique(dist))} districts, {n_cell} cellules de 20 km -> {N_PLIS} plis")

    def Zde(nom):
        v = B[nom]
        v = v.loc[:, v.nunique() > 1]
        return dm(v.to_numpy(float)), list(v.columns)

    # --- porte ------------------------------------------------------------------
    log.hr("33b. Porte : bloc L")
    ZL, nomsL = Zde("L")
    log.t("validation croisee, bloc L, ponderations heteroscedastiques")
    r_c, r_l, sel = A.cv(y, ZL, C, plis, dist, groupe=False)
    gain = r_l - r_c
    nb = [len(s) for s in sel.values()]
    log(f"  R2 hors echantillon (intra-district) : controles seuls {r_c:.3f} ; post-lasso + controles {r_l:.3f}")
    log(f"  gain : {gain:.3f}  (seuil {SEUIL_GAIN_R2CV}) -> {'PASSE' if gain >= SEUIL_GAIN_R2CV else 'ECHOUE'}")
    log(f"  instruments retenus par pli : {nb}")

    # --- hors critere -------------------------------------------------------------
    log.hr("33c. Rapporte a cote du verdict (hors critere)")
    yr = y - C @ A.ols(C, y)
    ZLr = ZL - C @ A.ols(C, ZL)
    s_full = A.rlasso(yr, ZLr, None)
    noms_full = [nomsL[i] for i in s_full]
    log(f"  bloc L, retenus sur tout l'echantillon ({len(noms_full)}) : {' '.join(noms_full) or '(aucun)'}")
    n_fe = len(np.unique(dist))
    if len(s_full):
        Fi = C4.f_iid(y, ZL[:, s_full], C, n_fe)
        Fc, q, g = A.f_partiel_groupe(y, ZL[:, s_full], C, dist, n_fe=n_fe)
        log(f"  F post-lasso : i.i.d. {Fi:.2f} ; groupe par district {Fc:.2f} (q = {q}, {g} districts)")
    else:
        Fi = Fc = np.nan
        log("  F post-lasso : sans objet (aucun instrument retenu)")
    freq = pd.Series([nomsL[i] for s in sel.values() for i in s]).value_counts()
    tab_sel = pd.DataFrame({"instrument": freq.index, "plis_sur_10": freq.values})
    tab_sel["tout_echantillon"] = tab_sel["instrument"].isin(noms_full)
    log("  frequence de selection sur les 10 plis :")
    log(tab_sel.to_string(index=False) if len(tab_sel) else "  (aucune selection)")
    tab_sel.to_csv(os.path.join(D_TAB, "33_selection_bloc_L.csv"), index=False)

    var = [("bloc L, principal (rappel)", r_c, r_l)]
    for nom in ["P", "L+P", "L-250k", "lithologie seule", "fractures seules"]:
        log.t(f"bloc {nom}")
        Z, cols = Zde(nom)
        if not cols:
            log(f"  bloc {nom} : sans objet (aucune colonne non constante)")
            var.append((f"bloc {nom} (sans objet)", np.nan, np.nan))
            continue
        a, b, _ = A.cv(y, Z, C, plis, dist, groupe=False)
        var.append((f"bloc {nom}", a, b))
    log.t("bloc L, un pli par district")
    a, b, _ = A.cv(y, ZL, C, pd.factorize(dist)[0], dist, groupe=False)
    var.append(("bloc L, un pli par district (regle du 24/09)", a, b))
    log.t("bloc L, plis de puits au hasard")
    rng = np.random.default_rng(GRAINE)
    a, b, _ = A.cv(y, ZL, C, rng.permutation(np.arange(len(y)) % N_PLIS), dist, groupe=False)
    var.append(("bloc L, plis de puits au hasard", a, b))
    log.t("bloc L, ponderations groupees par district")
    a, b, _ = A.cv(y, ZL, C, plis, dist, groupe=True)
    var.append(("bloc L, ponderations groupees par district", a, b))
    tv = pd.DataFrame(var, columns=["variante", "r2cv_controles", "r2cv_lasso_controles"])
    tv["gain"] = tv["r2cv_lasso_controles"] - tv["r2cv_controles"]
    log(tv.round(3).to_string(index=False))
    tv.to_csv(os.path.join(D_TAB, "33_premier_stage_variantes.csv"), index=False)

    verdict = gain >= SEUIL_GAIN_R2CV
    pd.DataFrame([{
        "n_puits": len(d), "n_districts": n_fe, "n_cellules": n_cell, "n_colonnes_L": ZL.shape[1],
        "r2cv_controles": r_c, "r2cv_lasso_controles": r_l, "gain_r2cv": gain,
        "seuil_gain": SEUIL_GAIN_R2CV, "n_retenus_min": min(nb), "n_retenus_max": max(nb),
        "n_retenus_tout": len(s_full), "f_iid": Fi, "f_groupe_district": Fc,
        "verdict": "PASSE" if verdict else "ECHOUE"}]).to_csv(
        os.path.join(D_TAB, "33_premier_stage_verdict.csv"), index=False)

    log.hr("33d. Verdict")
    log(f"Gain de R2 hors echantillon du bloc L {gain:.3f} >= {SEUIL_GAIN_R2CV} : "
        f"{'rempli' if verdict else 'NON rempli'}")
    log(f"VERDICT DE LA PORTE AP COUCHES FINES : {'PASSE' if verdict else 'ECHOUE'}")
    log("\nRun finished:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
