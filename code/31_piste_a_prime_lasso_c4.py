# ---------------------------------------------------------------------------
# 31_piste_a_prime_lasso_c4.py -- variante A'-L-C4 : le premier stage publie
#   (tableau C4, colonne "Main", Ryan & Sudarshan 2022) tient-il HORS
#   ECHANTILLON ? Meme fichier, echantillon, controles et candidats que C4 ;
#   validation croisee par depart de A'-L.
#
# CRITERE FIXE AVANT ESTIMATION : memo/piste_a_prime_lasso_c4_critere.md
# Les seuils ci-dessous en sont la copie ; ne pas les changer.
#
# Reproduit, du code des auteurs (raw/nicholasryan2021/.../code/marginal_analysis/) :
#   rationing_data_preparation.do   destring, variable de profit (l. 14-52)
#   rationing_summary_statistics.do drop l. 93, deciles de terre l. 103-115,
#                                   controles de sol l. 129-224
#   rationing_profit_regressions.do controles et candidats (l. 105-127), appel
#                                   lasso_iv_first (l. 186)
# La variable de profit ne sert QU'A reproduire le e(sample) d'ivlasso : elle
# n'est jamais estimee ni lue comme resultat.
#
# PORTEE : premier stage seulement. AUCUNE variable de resultat de notre
# question, AUCUN second stage, AUCUN appariement SHRUG.
#
# LANCEMENT (racine du depot) :
#     python code/31_piste_a_prime_lasso_c4.py               # reprend
#     python code/31_piste_a_prime_lasso_c4.py --force       # refait l'echantillon
#     python code/31_piste_a_prime_lasso_c4.py --echantillon # echantillon seul
#
# PREREQUIS : build/29_plis_departs.csv ; code/30_piste_a_prime_lasso.py
# ETAPE RESUMABLE : build/31_echantillon.pkl
# Sorties : output/tables/31_*.csv, output/logs/31_piste_a_prime_lasso_c4.log
# ---------------------------------------------------------------------------

import importlib.util
import os
import sys
from datetime import datetime

import numpy as np
import pandas as pd
import scipy
import sklearn

# fonctions communes (rlasso, ols, colonnes_candidates, etape, check) du script 30
_spec = importlib.util.spec_from_file_location(
    "a_prime_lasso", os.path.join("code", "30_piste_a_prime_lasso.py"))
A = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(A)

# --- seuils et attentes du critere (memo/piste_a_prime_lasso_c4_critere.md) ----
SEUIL_GAIN_R2CV = 0.05
N_LIGNES_C4 = 8973
N_AGRI_C4 = 3999
N_CONTROLES_C4 = 28
SEUIL_RECOUVREMENT = 8    # signale seulement, ne decide pas

# Liste publiee, C4 colonne "Main" (rationing_main.log, l. 33515 et suivantes)
LISTE_C4 = ["rock_area_1", "rock_area_4", "rock_area_6", "rock_area_15", "rock_area_20",
            "aquifer_type_4", "rock_area2_4", "rock_area2_10", "ltot5km_area119",
            "ltot5km_area1115", "ltot5km_area1130", "dist2fault_area112",
            "dist2fault_area116", "dist2fault_area1114", "dist2fault_area1120",
            "dist2fault_area1146"]
F_IID_C4 = 86.82

F_CROP = A.F_CROP
F_PLIS = A.F_PLIS
F_ECH = os.path.join("build", "31_echantillon.pkl")
F_LOG = os.path.join("output", "logs", "31_piste_a_prime_lasso_c4.log")
D_TAB = A.D_TAB

ECH_SEUL = "--echantillon" in sys.argv

SOL_BRUT = ["AS_pH", "HAc_pH", "MAc_pH", "SLAc_pH", "SrAC_pH", "N_pH", "MAl_pH", "Tot_pH",
            "VH_K", "H_K", "M_K", "Tot_K", "VH_P", "H_P", "M_P", "Tot_P",
            "S_S", "Tot_S", "S_Zn", "Tot_Zn", "S_Fe", "Tot_Fe", "S_Cu", "Tot_Cu",
            "S_Mn", "Tot_Mn"]
SOL = ["prop_sufficient_s", "prop_sufficient_zn", "prop_sufficient_fe", "prop_sufficient_cu",
       "prop_sufficient_mn", "prop_high_k", "prop_high_p", "prop_med_k", "prop_med_p",
       "prop_acidic", "prop_mildly_alkaline", "missing_soil_controls"]
PROFIT = ["f5_4_12_net_profit_perha_wins", "f5_4_12_net_profit_perha_w_own",
          "impu_profit_per_hectare"]


def num(s):
    """destring, force : texte non numerique -> manquant."""
    if s.dtype == object:
        s = s.replace("", np.nan)
    return pd.to_numeric(s, errors="coerce")


def ratio(a, b):
    """Division a la Stata : x/0 -> manquant."""
    r = a / b
    return r.replace([np.inf, -np.inf], np.nan)


def xtile(x, nq=10):
    """xtile de Stata (percentiles de _pctile, definition par defaut)."""
    v = np.sort(x.dropna().to_numpy())
    n = len(v)
    cuts = []
    for k in range(1, nq):
        P = n * k / nq
        j = int(np.floor(P))
        cuts.append((v[j - 1] + v[j]) / 2 if P == j else v[j])
    cat = pd.Series(nq, index=x.index, dtype=float)
    for k in range(nq - 1, 0, -1):
        cat[x <= cuts[k - 1]] = k
    cat[x.isna()] = np.nan
    return cat


def construire_echantillon():
    with pd.read_stata(F_CROP, iterator=True) as r:
        noms = list(r.variable_labels().keys())
    cand = A.colonnes_candidates(noms)
    vars_ = (["f_id", "crop", "sdo", "sdo_feeder_code", "farmer_well_depth", "elevation",
              "slope", "d1_tot_land", "b7_3_3_avg_surce_dpth_resp_ft"] + SOL_BRUT + PROFIT + cand)
    absentes = [v for v in vars_ if v not in noms]
    check(not absentes, f"fichier agriculteur x culture : {len(vars_)} variables presentes",
          "absentes : " + ", ".join(absentes))
    log.t("lecture de", F_CROP)
    d = pd.read_stata(F_CROP, columns=vars_, convert_categoricals=False)
    log(f"  {len(d)} lignes, {d['f_id'].nunique()} agriculteurs")
    check(not d.duplicated(["f_id", "crop"]).any(), "cle (f_id, crop) unique")

    # rationing_data_preparation.do : destring ... , force
    for v in ["elevation", "slope"] + PROFIT:
        d[v] = num(d[v])
    d["profit_cashwown"] = d["f5_4_12_net_profit_perha_w_own"]
    m = d["f5_4_12_net_profit_perha_wins"].isna()
    d.loc[m, "profit_cashwown"] = d.loc[m, "impu_profit_per_hectare"]

    # rationing_summary_statistics.do l. 93
    n0 = len(d)
    d["d1_tot_land"] = num(d["d1_tot_land"])
    prof = d["b7_3_3_avg_surce_dpth_resp_ft"]
    prof_manq = prof.isna() | (prof.astype(str).str.strip() == "") if prof.dtype == object else prof.isna()
    d = d[d["d1_tot_land"].notna() & ~prof_manq].copy()
    log(f"  drop if missing(d1_tot_land, b7_3_3_avg_surce_dpth) : {len(d)} / {n0}")

    # deciles de terre (l. 103-107)
    d["land_decile"] = xtile(d["d1_tot_land"], 10)
    for k in range(2, 11):
        d[f"_Ildland_de_{k}"] = (d["land_decile"] == k).astype(float)

    # controles de sol (l. 129-224), coquille prop_med_p comprise
    for v in SOL_BRUT:
        d[v] = num(d[v])
    d.loc[d["Tot_S"] == 0, "Tot_S"] = np.nan
    d["missing_soil_controls"] = (d["AS_pH"].isna() | d["Tot_S"].isna()).astype(float)
    acid = d[["AS_pH", "HAc_pH", "MAc_pH", "SLAc_pH", "SrAC_pH", "N_pH"]].sum(axis=1, min_count=0)
    d["prop_acidic"] = ratio(acid, d["Tot_pH"])
    d["prop_mildly_alkaline"] = ratio(d["MAl_pH"], d["Tot_pH"])
    d["prop_high_k"] = ratio(d[["VH_K", "H_K"]].sum(axis=1, min_count=0), d["Tot_K"])
    d["prop_med_k"] = ratio(d["M_K"], d["Tot_K"])
    d["prop_high_p"] = ratio(d[["VH_P", "H_P"]].sum(axis=1, min_count=0), d["Tot_P"])
    d["prop_med_p"] = ratio(d["M_P"], d["Tot_K"])          # sic (auteurs)
    for el in ["s", "zn", "fe", "cu", "mn"]:
        E = el.capitalize() if el != "s" else "S"
        d[f"prop_sufficient_{el}"] = ratio(d[f"S_{E}"], d[f"Tot_{E}"])
    for v in SOL[:-1]:
        d.loc[d["missing_soil_controls"] == 1, v] = 0.0

    # e(sample) d'ivlasso : tout non manquant
    deciles = [f"_Ildland_de_{k}" for k in range(2, 11)]
    req = (["farmer_well_depth", "profit_cashwown", "sdo", "elevation", "slope"]
           + deciles + SOL + cand)
    n1 = len(d)
    d = d[d[req].notna().all(axis=1)]
    log(f"  e(sample) (profondeur, profit, 419 candidats, 28 controles) : {len(d)} / {n1}")
    keep = ["f_id", "crop", "sdo", "sdo_feeder_code", "farmer_well_depth", "elevation",
            "slope"] + deciles + SOL + cand
    return d[keep].sort_values(["f_id", "crop"]).reset_index(drop=True)


def cv_pred(y, Z, C, plis, depart, liste_fixe=None):
    """Predictions hors echantillon : controles seuls, post-lasso + controles."""
    pc = np.zeros_like(y)
    pl = np.zeros_like(y)
    sel = {}
    for k in np.unique(plis):
        te = plis == k
        tr = ~te
        bc = A.ols(C[tr], y[tr])
        pc[te] = C[te] @ bc
        if liste_fixe is None:
            yr = y[tr] - C[tr] @ bc
            Zr = Z[tr] - C[tr] @ A.ols(C[tr], Z[tr])
            viv = np.flatnonzero(Zr.std(axis=0) > 1e-12)
            s = viv[A.rlasso(yr, Zr[:, viv], depart[tr])]
        else:
            s = np.asarray(liste_fixe, dtype=int)
        sel[k] = s
        if len(s):
            X = np.column_stack([Z[:, s], C])
            pl[te] = X[te] @ A.ols(X[tr], y[tr])
        else:
            pl[te] = pc[te]
    return pc, pl, sel


def f_iid(y, Zs, C, n_fe):
    """F de Wald i.i.d. des colonnes Zs (y, Zs, C deja centres par SDO)."""
    n = len(y)
    X = np.column_stack([Zs, C])
    e_u = y - X @ A.ols(X, y)
    e_r = y - C @ A.ols(C, y)
    q = Zs.shape[1]
    ddl = n - X.shape[1] - n_fe
    return float(((e_r @ e_r - e_u @ e_u) / q) / ((e_u @ e_u) / ddl))


# ===========================================================================
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
    log("ETAPE 31 -- PISTE A'-L-C4 : LE PREMIER STAGE PUBLIE (C4) TIENT-IL HORS ECHANTILLON ?")
    log("Critere fixe avant estimation : memo/piste_a_prime_lasso_c4_critere.md")
    log(f"  gain de R2 hors echantillon (plis de A', selection refaite par pli) >= {SEUIL_GAIN_R2CV}")
    log("Aucun second stage, aucune variable de resultat.")

    log.hr("31a. Echantillon de C4 (etape 1)")
    check(os.path.exists(F_PLIS), "plis de A' presents (" + F_PLIS + ")")
    d = A.etape("etape 1/1 echantillon", F_ECH, construire_echantillon)
    check(len(d) == N_LIGNES_C4, f"lignes == {N_LIGNES_C4} (C4)", f"observe {len(d)}")
    check(d["f_id"].nunique() == N_AGRI_C4, f"agriculteurs == {N_AGRI_C4} (C4)",
          f"observe {d['f_id'].nunique()}")
    deciles = [f"_Ildland_de_{k}" for k in range(2, 11)]
    ctrl = deciles + ["elevation", "slope"] + SOL
    n_ctrl = sum(d[c].nunique() > 1 for c in ctrl) + (d["sdo"].nunique() - 1)
    check(n_ctrl == N_CONTROLES_C4, f"controles non constants == {N_CONTROLES_C4} (C4)",
          f"observe {n_ctrl}")
    plis_dep = pd.read_csv(F_PLIS)
    d = d.merge(plis_dep, on="sdo_feeder_code", how="left")
    check(d["pli"].notna().all(), "chaque ligne a un pli de A'",
          f"{int(d['pli'].isna().sum())} lignes sans pli")
    log(f"  {len(d)} lignes, {d['f_id'].nunique()} agriculteurs, "
        f"{d['sdo_feeder_code'].nunique()} departs, {d['sdo'].nunique()} SDO")
    if ECH_SEUL:
        log("--echantillon : arret avant toute estimation.")
        raise SystemExit(0)

    log.hr("31b. Porte")
    cand = [c for c in A.colonnes_candidates(list(d.columns)) if d[c].nunique() > 1]
    log(f"  candidats non constants : {len(cand)} / {A.N_CANDIDATS}")
    sdo = d["sdo"].to_numpy()
    dm = lambda M: M - pd.DataFrame(M).groupby(sdo).transform("mean").to_numpy()
    y = dm(d[["farmer_well_depth"]].to_numpy(float))[:, 0]
    Z = dm(d[cand].to_numpy(float))
    C = dm(d[ctrl].to_numpy(float))
    plis = d["pli"].to_numpy(int)
    depart = d["sdo_feeder_code"].to_numpy()
    fid = d["f_id"].to_numpy()

    log.t("validation croisee, ponderations groupees par depart")
    pc, pl, sel_plis = cv_pred(y, Z, C, plis, depart)
    r_c, r_l = A.r2_cv(y, pc), A.r2_cv(y, pl)
    gain = r_l - r_c
    nb = [len(s) for s in sel_plis.values()]
    log(f"  R2 hors echantillon (intra-SDO, lignes) : controles seuls {r_c:.3f} ; "
        f"post-lasso + controles {r_l:.3f}")
    log(f"  gain : {gain:.3f}  (seuil {SEUIL_GAIN_R2CV}) -> "
        f"{'PASSE' if gain >= SEUIL_GAIN_R2CV else 'ECHOUE'}")
    log(f"  instruments retenus par pli : {nb}")

    # --- hors critere ----------------------------------------------------------
    log.hr("31c. Rapporte a cote du verdict (hors critere)")
    agg = pd.DataFrame({"f": fid, "y": y, "pc": pc, "pl": pl}).groupby("f").mean()
    r_c_f, r_l_f = A.r2_cv(agg["y"].to_numpy(), agg["pc"].to_numpy()), \
        A.r2_cv(agg["y"].to_numpy(), agg["pl"].to_numpy())
    log(f"  R2 par agriculteur : controles {r_c_f:.3f} ; post-lasso {r_l_f:.3f} ; "
        f"gain {r_l_f - r_c_f:.3f}")

    log.t("selection sur tout l'echantillon")
    yr = y - C @ A.ols(C, y)
    Zr = Z - C @ A.ols(C, Z)
    s_full = A.rlasso(yr, Zr, depart)
    noms_full = [cand[i] for i in s_full]
    commun = sorted(set(noms_full) & set(LISTE_C4))
    log(f"  retenus sur tout l'echantillon ({len(noms_full)}) : {' '.join(noms_full) or '(aucun)'}")
    log(f"  liste publiee C4 ({len(LISTE_C4)}) : {' '.join(LISTE_C4)}")
    log(f"  en commun : {len(commun)} / {len(LISTE_C4)} : {' '.join(commun) or '(aucun)'}")
    if len(commun) < SEUIL_RECOUVREMENT:
        log(f"  [SIGNALE] recouvrement < {SEUIL_RECOUVREMENT} : l'implementation differe de "
            "lassopack sur l'echantillon des auteurs")
    n_fe = d["sdo"].nunique()
    idx_c4 = [cand.index(v) for v in LISTE_C4 if v in cand]
    check(len(idx_c4) == len(LISTE_C4), "les 16 instruments publies sont parmi les candidats")
    if len(s_full):
        Fi = f_iid(y, Z[:, s_full], C, n_fe)
        Fc, q, g = A.f_partiel_groupe(y, Z[:, s_full], C, depart, n_fe=n_fe)
        log(f"  notre selection : F i.i.d. {Fi:.2f} ; F groupe par depart {Fc:.2f} (q = {q})")
    else:
        Fi = Fc = np.nan
    Fi16 = f_iid(y, Z[:, idx_c4], C, n_fe)
    Fc16, _, _ = A.f_partiel_groupe(y, Z[:, idx_c4], C, depart, n_fe=n_fe)
    log(f"  liste publiee de 16 : F i.i.d. {Fi16:.2f} (publie : {F_IID_C4}) ; "
        f"F groupe par depart {Fc16:.2f}")

    freq = pd.Series([cand[i] for s in sel_plis.values() for i in s]).value_counts()
    tab_sel = pd.DataFrame({"instrument": freq.index, "plis_sur_10": freq.values})
    tab_sel["tout_echantillon"] = tab_sel["instrument"].isin(noms_full)
    tab_sel["liste_c4"] = tab_sel["instrument"].isin(LISTE_C4)
    log("  frequence de selection sur les 10 plis :")
    log(tab_sel.to_string(index=False) if len(tab_sel) else "  (aucune selection)")
    tab_sel.to_csv(os.path.join(D_TAB, "31_selection_lasso_c4.csv"), index=False)

    variantes = [("principal (rappel)", r_c, r_l),
                 ("R2 par agriculteur", r_c_f, r_l_f)]
    log.t("variante : un pli par SDO")
    a, b, _ = cv_pred(y, Z, C, pd.factorize(sdo)[0], depart)
    variantes.append(("un pli par SDO (6 plis)", A.r2_cv(y, a), A.r2_cv(y, b)))
    log.t("variante : liste publiee de 16, fixe")
    a, b, _ = cv_pred(y, Z, C, plis, depart, liste_fixe=idx_c4)
    variantes.append(("liste publiee C4 (16), fixe", A.r2_cv(y, a), A.r2_cv(y, b)))
    log.t("variante : sans deciles de terre")
    C2 = dm(d[["elevation", "slope"] + SOL].to_numpy(float))
    a, b, _ = cv_pred(y, Z, C2, plis, depart)
    variantes.append(("sans deciles de terre", A.r2_cv(y, a), A.r2_cv(y, b)))
    tab_var = pd.DataFrame(variantes, columns=["variante", "r2cv_controles", "r2cv_lasso_controles"])
    tab_var["gain"] = tab_var["r2cv_lasso_controles"] - tab_var["r2cv_controles"]
    log(tab_var.round(3).to_string(index=False))
    tab_var.to_csv(os.path.join(D_TAB, "31_premier_stage_lasso_c4_variantes.csv"), index=False)

    verdict = gain >= SEUIL_GAIN_R2CV
    pd.DataFrame([{
        "n_lignes": len(d), "n_agriculteurs": d["f_id"].nunique(),
        "n_departs": len(np.unique(depart)), "n_candidats": len(cand), "n_controles": n_ctrl,
        "r2cv_controles": r_c, "r2cv_lasso_controles": r_l, "gain_r2cv": gain,
        "seuil_gain": SEUIL_GAIN_R2CV, "n_retenus_min": min(nb), "n_retenus_max": max(nb),
        "n_retenus_tout": len(s_full), "recouvrement_c4": len(commun),
        "f_iid_selection": Fi, "f_groupe_selection": Fc, "f_iid_liste_c4": Fi16,
        "f_groupe_liste_c4": Fc16,
        "verdict": "PASSE" if verdict else "ECHOUE"}]).to_csv(
        os.path.join(D_TAB, "31_premier_stage_lasso_c4_verdict.csv"), index=False)

    log.hr("31d. Verdict")
    log(f"Gain de R2 hors echantillon {gain:.3f} >= {SEUIL_GAIN_R2CV} : "
        f"{'rempli' if verdict else 'NON rempli'}")
    log(f"VERDICT DE LA PORTE A'-L-C4 : {'PASSE' if verdict else 'ECHOUE'}")
    log("Rappel : les portes B et C restent la question pour la piste A.")
    log("\nRun finished:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
