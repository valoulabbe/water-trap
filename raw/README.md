# Données brutes — provenance

## SHRUG (v2.2)
Source : https://www.devdatalab.org/shrug_download/
Licence : CC BY-NC-SA 4.0
Documentation : https://docs.devdatalab.org

| Fichier | Module | Téléchargé le | SHA256 |
| --- | --- | --- | --- |
| shrug-con-keys-dta.zip | | 2026-09-18 | 73ABA374D92E165B5D0E8708E07845760CEC4AC364058B2F4D35ACA14020E82C |
| shrug-ec-keys-dta.zip | | 2026-09-18 | ACA1FEABA3AE5C74F98B67E1D89011E1E196B0B3D16B86F4169A68F9FC10CA4A |
| shrug-pc-keys-dta.zip | | 2026-09-18 | 85EF2B53E08A1DA9BB3BAF6D1DF7F0C67B2C994D1090FE3C04A06B2DD9F45C18 |
| shrug-pca01-dta.zip | | 2026-09-18 | D16197A82D5F5912A2FCE413A9B0061D88C12339AB6DE4B123A7B4BC20A8759A |
| shrug-pca11-dta.zip | | 2026-09-18 | 752DFC50423D63E05625DA859EAFECD2CDA284BDA3D60A903A4A0E67EBBB6193 |
| shrug-pca91-dta.zip | | 2026-09-18 | 83FA900A6E4A47030FF9460A24127CDB5B237C3C4C96C6FD411107B7A1DD22E6 |
| shrug-shrid-keys-dta.zip | | 2026-09-18 | F915A577D824F9577E4EB7F7F49A95516DA8C920DF29C43F000F66639A9272CD |
| shrug-vd01-dta.zip | | 2026-09-18 | BDF9977F2ABC5CB738A001CDFFB41162B200A03C43B56457D688D97A2BD36E49 |
| shrug-vd11-dta.zip | | 2026-09-18 | 318A65FF58C70792A1DFB78494AD6656DB0EA3F43286BA5E8D9F7BFBA0C821C5 |
| shrug-vd91-dta.zip | | 2026-09-18 | EBD975D24CF24AE27D7E2668F52334D5C512F821D88BC4A99DF7D416F2F4017B |
| shrug-shrid-poly-gpkg.zip | Polygones des shrid (GeoPackage) | 2026-09-18 | 8BA138D378D453D251C2E09F5E5EB10938CFEB218E971E44613E25A7AA85699D |
| shrug-pc11dist-poly-gpkg.zip | Polygones des districts PC11 (GeoPackage) | 2026-09-18 | 2580E68507CB8DE9CDD1874EDD03D47EFB8D75CE05D258B6E80290A5F1813841 |

Fichiers décompressés dans un dossier au nom de chaque zip ; zip d'origine conservés, rien n'est modifié.


## Sekhri
| Fichier | Contenu | Source | Téléchargé le | SHA256 |
| --- | --- | --- | --- | --- |
| 113902-V1.zip | Réplication Sekhri (2014), AEJ: Applied 6(3) | openICPSR projet 113902, V1 | 2026-09-18 | 2AC1D9D3EF1E8624ADB7858E8E1B24F73326A88EAA62930022FFB3010B17641A |
| 113803-V1.zip | Réplication Sekhri (2011), AEJ: Applied 3(4) — code et Readme uniquement, aucune donnée | openICPSR projet 113803, V1 | 2026-09-18 | B99D959198E664CF813197886BEE036C22D16BA9C88327717B2DA48224624ECE |

   ## CGWB — puits d'observation
   | Fichier | Contenu | Source | Téléchargé le | SHA256 |
   | --- | --- | --- | --- | --- |
   | CGWB_data_wide.csv | 28 076 puits, niveaux trimestriels mai 1996–janv. 2017, lat/lon | github.com/craigdsouza/cgwb (données CGWB obtenues par mail par T. Hora, U. Waterloo ; copie non officielle, sans licence) | 2026-09-18 | 9C229185FB0153CBF0074CA65842622724866089097F33F3E8E64AC4FD65C14D |
## Géologie — carte GSI 1:2M (NGDR)
| Fichier | Contenu | Source | Téléchargé le | SHA256 |
| --- | --- | --- | --- | --- |
| geology/ngdr/NGDR_Geology_2M.parquet | Carte géologique de l'Inde au 1:2M, 4 531 polygones (GeoParquet 1.1, WKB, EPSG:4326) : unité stratigraphique, âge, super-groupe, groupe. Pas de type de roche ni de classe d'aquifère | GSI / National Geoscience Data Repository (geodataindia.gov.in), republié par ramSeraph/indian_land_features, release `geology` (2025-02-13) ; rangé par le republieur sous « not-so-open » ; licence annoncée « CC0 1.0, attribuer DataMeet et la source gouvernementale » | 2026-09-23 | 8BBEC03D2F0A3898648B3E95F4EF967F51F889395A29D6EA11748420973E6526 |
| geology/ngdr/NGDR_Geology_2M.geojsonl.7z | Même couche en GeoJSONSeq compressé. **Inutilisable ici** : l'extraction par tar (Windows) échoue (PPMd) et produit un fichier corrompu ; GDAL local sans /vsi7z/. Conservé pour provenance ; lire le .parquet | idem | 2026-09-23 | 98C84FA8EF98CB7676334ED687FCEC76AF293BB469FD0F4F0AA9AEFF97631650 |

## Terrain — CartoDEM v3r1 (1 seconde d'arc, ~30 m)
Source : NRSC/ISRO Bhuvan, dérivé en COG par ramSeraph/indian_land_features, release `cartodem-30m-v3r1` ; licence annoncée « CC0 1.0, attribuer DataMeet et la source gouvernementale ». Seules les 34 tuiles de 1° × 1° contenant un puits de l'échantillon de l'étape 10 (socle de l'AP) sont téléchargées. Nom de tuile : `cdn` + bande de 4° de latitude (c = 8–12° N, d = 12–16°, e = 16–20°) + zone UTM (43 = 72–78° E, 44 = 78–84°) + case a–x (six par ligne, du nord au sud). Téléchargé le 2026-09-24. SHA256 par fichier :

| Fichier | SHA256 |
| --- | --- |
| cartodem/cdnd43f.tif | 615B73815D20325FF662AFB33A3265E1E8AD6A12EBD7B15943C8DCEC71856440 |
| cartodem/cdnd43k.tif | 0D2BF061ACB59B178E740C34C9EC2C067C302A7AB28E1D29091AFEB4B31A1153 |
| cartodem/cdnd43l.tif | 2968BE1990EAB2A5A552D8B1D0981E2170AC3700987C37B99F876C4CB9B904E9 |
| cartodem/cdnd43r.tif | 3F110C92AF6198B2DD580417CCB7AE562538577D78E8FAA03F44224DA23FE9F6 |
| cartodem/cdnd44a.tif | 37156D15909914F95A0212076C655AAFD040621A9EB82ABCA35568D11EC2D9F1 |
| cartodem/cdnd44b.tif | C0623A1626BF9E70A7B7CDA995055C52ADBB861266FC2193C3ADEBC92C16828C |
| cartodem/cdnd44c.tif | B7EBB336FECE22F9E34AD9AAE4A96D6126CE7D960846BB4E6218A3F2324FCC50 |
| cartodem/cdnd44g.tif | 91D20EF0EBAB807237A0B28176CFB12D051C5B6F1A946C03A050E3B462551E46 |
| cartodem/cdnd44h.tif | F41113F7270F830C54F912BAF128622236A03A84ACABC05E92F0A14812AD63F3 |
| cartodem/cdnd44m.tif | 66EE6A6B782AE779863793D9EEEF31F5A6195DC83CF3DC585A6715A9490B9FA2 |
| cartodem/cdnd44n.tif | 6F7C84C8433DDCF76BC791E4E1392C8A2FCB04D22E5CE6B42CA6830BD20026B2 |
| cartodem/cdnd44o.tif | E0ED4FE197F64EB4598B1FE091AF213BAD7B96742C325AB9E92A5253D607D14F |
| cartodem/cdnd44s.tif | 503F4F9A9992D704E4D3487E28D28E1470B9FD4B905F9CB4029CDF61C3ADDA2F |
| cartodem/cdne43f.tif | F554B8A1EF02B4812683D422F24437578FD2BD1A4B601C621787DEB03A8956B4 |
| cartodem/cdne43l.tif | C67312C1BA425590C107A893ECE97EF51A61F207E4E9FFAF79FD3D661EAE5FD5 |
| cartodem/cdne43r.tif | 6885AC9C1D427426D865F39012D9E7BB4F70025F5364735C33235027AF4515B6 |
| cartodem/cdne43x.tif | BF79DBD5460B3C916A5F0B4C7EF1D9EF3208B44DA6F368564B38FD6DB15CDFFB |
| cartodem/cdne44a.tif | 0B7DDCAD76D4B35B6B29602710A9137E0160E89711122A3D503A6C4B7DB04DBD |
| cartodem/cdne44b.tif | 0EED27AE258B9DE60375201AF6256433D5FD2C05562CCF995BCFF657BEA9EEA2 |
| cartodem/cdne44g.tif | BAE2297AC0F972169B6EA5FEA0271670C0A497F2138FC2C4BABDBD5D53526EB3 |
| cartodem/cdne44h.tif | FD57266C93B9AA4E6CAAA809E4FD2FF9C4AC59E9EA5186D47BEC59946B920B15 |
| cartodem/cdne44k.tif | F7946CE21B399DEA41BED20AC1BEC3BF617BB666EE37D591F953B5EA7A62CD99 |
| cartodem/cdne44l.tif | C1970006E5201F472B0070018D379FF4DB60D748DE6FDC0304E1FC8A726B5365 |
| cartodem/cdne44m.tif | 37B94339A28F69C6E567C8EF9986E30ED1CD47AF89E6B6BE757A003981BB8269 |
| cartodem/cdne44n.tif | 1FB3EFE854BC896C0F2813E5EE0C32142949BCD7AC9DECB46F259E188C1004A5 |
| cartodem/cdne44o.tif | B8F6E0E33BB80CF0159C2F4928057ECE123351A03F0E0378F4E85A791E1B188B |
| cartodem/cdne44p.tif | B918320C40B199C46DA1F587589D4DB3B0FCD99D0F032A64D0AFC610A5E5E722 |
| cartodem/cdne44q.tif | D40B2FBD30753D0B178857EA583B4749A56795E17092BB606497FF3973B0F8AE |
| cartodem/cdne44r.tif | 4B1698A56F6C01F140E5A304E2F57D08B1FF5BC879499A5E7F0C2F23FB983BFD |
| cartodem/cdne44s.tif | 920C5F0A9BFF9E5B29AF27D3113D00091137A901402FDEEE07F76A942BB58981 |
| cartodem/cdne44t.tif | 566355688099AF32B86AFFEE6FDA2E19B0D98E82D7A0F37CD5D767A4C90AC017 |
| cartodem/cdne44u.tif | A45FEA63F2C9D896A1CD98C57DAD9426CE312CFB844263451DBE4D45562934DA |
| cartodem/cdne45a.tif | 2EE4687561A746505DEFDA37E839A2E0832AE4C6808E4CD156E3D73F8707BEEF |
| cartodem/cdne45g.tif | AED0DDE9FE762D9DDCE59D38E443DF4B7D569CD070201FF27930844949DB8DE6 |

## Sol — SLUSI Soil Health Cards
| Fichier | Contenu | Source | Téléchargé le | SHA256 |
| --- | --- | --- | --- | --- |
| slusi/SLUSI_SHC.parquet | Analyses de sol par parcelle (N, P, K, pH, EC, OC, oligo-éléments), Inde entière, GeoParquet points. Pas de texture ni de profondeur de sol | Soil and Land Use Survey of India (slusi.da.gov.in), republié par ramSeraph/indian_land_features, release `soil-health` ; licence annoncée « CC0 1.0, attribuer DataMeet et la source gouvernementale » | 2026-09-24 | 7B3DA9C37809E27C0291303486FC10E1EB38F8D4AC1D236E657C8B9947C7A3A6 |

## NSS — Schedule 1.2 (Drinking Water, Sanitation, Hygiene and Housing Condition)
Source : portail microdonnées du MoSPI, https://microdata.gov.in
Accès : compte gratuit, description du projet de recherche requise à l'inscription.
Conditions : usage académique. **Ne pas committer les microdonnées** — seuls les
fichiers dérivés et agrégés vont dans le dépôt.

| Round | Période | Rôle dans le design | Catalogue | Téléchargé le | Fichier | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| 58 | juil.–déc. 2002 | pré-choc, variable de gauche seule (pas d'item de traitement de l'eau) | catalog/97 | 2026-09-27 | | |
| 69 | juil.–déc. 2012 | post-choc, gauche + droite | catalog/129 | 2026-09-27 | | |
| 76 | juil.–déc. 2018 | post-choc, gauche + droite | catalog/153 | 2026-09-27 | | |

Round 54 (janv.–juin 1998, Schedule 31) : **non disponible** en accès direct.
C'était le seul point pré-choc pour l'adoption privée dans la série NSS ;
l'ancrage pré-choc repose donc sur IHDS-I (2004-05).
Ruptures de série connues : la qualité de l'eau de la source principale est
collectée au 69 mais pas au 76 ; la méthode de traitement est à réponse unique
(premier code applicable, purificateur électrique = code 1) ; la catégorie
« non traité » inclut « pas besoin de l'être ».

## IHDS — India Human Development Survey
Source : ICPSR / DSDR, https://www.icpsr.umich.edu/web/DSDR/series/507
Accès : compte gratuit. Conditions d'utilisation ICPSR — redistribution interdite,
**ne pas committer les microdonnées**.

| Vague | Période | Étude ICPSR | Ménages | Téléchargé le | Fichier | SHA256 |
| --- | --- | --- | --- | --- | --- | --- |
| IHDS-I | 2004-05 | 22626 | 41 554 | 2026-09-27 | | |
| IHDS-II | 2011-12 | 36151 | 42 152 | 2026-09-27 | | |

Panel : IHDS-II ré-interroge l'essentiel des ménages d'IHDS-I. Item de traitement
de l'eau formulé avec les modalités « bouillir / filtre acheté / Aquaguard /
produits chimiques ». Seul ancrage pré-choc disponible pour l'adoption privée.

## Prix des carburants — archive WDI (Banque mondiale), série GIZ
Source : API Banque mondiale, source 57 « WDI Database Archives », version
**202407** (juillet 2024), dernière version qui porte encore la série (vide à
partir de 202409). Organisation source déclarée : GIZ. Prix à la pompe en US$ par
litre, sans composante fiscale ; relevés 1991, 1992, 1995, 1998 puis tous les
deux ans 2000–2016 ; le relevé 2018 n'y est jamais entré. Conditions : Banque
mondiale, CC BY 4.0 par défaut, les indicateurs de source tierce restant soumis
aux conditions de la source (non vérifié pour cette série).
Requête : `https://api.worldbank.org/v2/sources/57/series/<série>/country/all/version/202407/time/all?format=json&per_page=20000`
(une seule page, 19 564 lignes pays-agrégats × années, valeurs nulles comprises).
Métadonnées pays (pour exclure les agrégats) : `https://api.worldbank.org/v2/country?format=json&per_page=400`
(version courante au 2026-09-30, 295 entrées).

| Fichier | Contenu | Téléchargé le | SHA256 |
| --- | --- | --- | --- |
| wdi_archive/wdi_arch_202407_EP.PMP.DESL.CD.json | Diesel, 2 327 valeurs non nulles | 2026-09-30 | 7EB9C2EF3FB5F8D47576F152CEEA7FBBAF9C581771B55F85E3FB5C2282FA667C |
| wdi_archive/wdi_arch_202407_EP.PMP.SGAS.CD.json | Essence, 2 351 valeurs non nulles | 2026-09-30 | 965F26C5B04B24C3C690A3444525B5114934656E3AE9857D286C62B1F501FB59 |
| wdi_archive/wdi_pays_metadata.json | Pays et agrégats WDI, région | 2026-09-30 | D29D57F8ADF954C5E2A1520A02FB2C7B45575D8DB3BD327A9DFF47D66914231C |

## Prix des carburants — GIZ / TUMI Mobility Data Hub
Source : https://hub.tumidata.org/dataset/worldwide-fuel-prices, ressource
« Fuel prices from 1991 to 2020 » (XLSX), jeu v1.0.2 mis à jour le 2024-06-04,
auteur Armin Wagner + GIZ. Licence affichée : « Creative Commons Attribution »,
avec la mention « covered by different Terms of Use ». Le serveur refuse la
connexion depuis cette machine (réinitialisée) : **téléchargement manuel par
l'utilisatrice**, dans `raw/giz/`. Nom exact du fichier, date et SHA256 à
compléter au dépôt.

| Fichier | Contenu | Téléchargé le | SHA256 |
| --- | --- | --- | --- |
| giz/(à compléter) | Prix diesel, essence, super, 1991–2020 | | |

## Arsenic à Araihazar (Bangladesh) — HydroShare
Source : Jameel, M. Y. (2021). *Groundwater arsenic measurements from Araihazar,
Bangladesh*, HydroShare, https://doi.org/10.4211/hs.8e1373d87419447c945625af13f0a2ea
(données de Jameel et al. 2021, GeoHealth, doi:10.1029/2021GH000464). Arsenic en
ppb (µg/L). Licence : non vérifiée.

| Fichier | Contenu | Téléchargé le | SHA256 |
| --- | --- | --- | --- |
| hydroshare/Dataset1.csv | Mesures appariées kit de terrain / laboratoire (ICP-MS) : `Sample`, `Kit category` (0, 10, 25, 50, 100, 200, 300, 500, 1000, et 999), `Laboratory measured As (ppb)`, lat/lon. 943 puits (la page annonce 950) | 2026-10-03 | 8B16A282F28FF8791CA43F654186EA4C049C15A5C0B4863ECEC390DF2D172D8B |
| hydroshare/Dataset2.csv | 6 605 puits mesurés en laboratoire, analysés dans van Geen et al. (2003) : `Well_ID`, `Union`, `Village`, `As_ppb`, lat/lon, `Depth` (pieds), `Year` (installation, déclarée ; 52 valeurs hors 1960-2003 ou non numériques : 1900 ×44, 1950 ×2, 1951, 1930, 200, « N.A », « ? », 2 vides). Deux lots : `Well_ID` 1-8000 (5 964 puits, noms de village en majuscules, installations jusqu'en 2001) et 8001-8808 (634 puits, seuls à porter les installations 2002-2003) | 2026-10-03 | BAFE256A83EF7A6AD1CDC0F11C289D7D9DB179B6F3EC247CEE16A01013A437A9 |

## Arsenic par village (Bangladesh) — van Geen et al. (2019)
Source : supporting information de van Geen et al. (2019), « Effectiveness of
Different Approaches to Arsenic Mitigation over 18 Years in Araihazar,
Bangladesh: Implications for National Policy », *Environmental Science &
Technology* 53(10) : 5596–5604, doi:10.1021/acs.est.9b01375. Conditions : celles
de l'éditeur (ACS) pour les SI, non vérifiées.

| Fichier | Contenu | Téléchargé le | SHA256 |
| --- | --- | --- | --- |
| vangeen2019/es9b01375_si_001.xlsx | Une feuille « all villages », 44 865 lignes : `Vid`, District, Upazila, Union, Mouza, village, `No. wells`, `Mean As from kit`, `%wells <=50 ug/L As`, `Safe depth (ft)` | 2026-10-03 | 6383CCF2D2E63D69FB3AFCCD949A909C2D5FD35EC4876146D52248F3AF5C5A4F |
