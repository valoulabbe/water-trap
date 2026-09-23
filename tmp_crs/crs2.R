suppressMessages({library(sf); library(data.table)})
sf_use_s2(TRUE)
d <- st_make_valid(st_read("raw/shrug/shrug-pc11dist-poly-gpkg/district.gpkg", quiet=TRUE))
laea <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"
aea  <- "+proj=aea +lat_0=24 +lon_0=80 +lat_1=12.5 +lat_2=35.2 +datum=WGS84 +units=m +no_defs"
a_laea <- as.numeric(st_area(st_transform(d, laea)))
a_aea  <- as.numeric(st_area(st_transform(d, aea)))
a_s2   <- as.numeric(st_area(d))
cat("LAEA vs Albers (deux projections equivalentes) : ecart relatif\n")
print(round(quantile(a_laea/a_aea - 1, c(0,.5,1))*1e6, 2))
cat("  (en PARTIES PAR MILLION -- elles sont d'accord)\n\n")
cat("s2 (spherique) vs LAEA (ellipsoidal) : ecart relatif en %\n")
print(round(quantile(a_s2/a_laea - 1, c(0,.5,1))*100, 3))
cat("  -> l'ecart de ~0.2-0.4% vient de la reference spherique s2, pas de LAEA\n")
