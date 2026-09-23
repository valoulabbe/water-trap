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
