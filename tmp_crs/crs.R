suppressMessages({library(sf); library(data.table)})
sf_use_s2(TRUE)

cat("=== Definition EPSG:7755 ===\n")
cr <- st_crs(7755)
cat(cr$proj4string, "\n\n")

d <- st_read("raw/shrug/shrug-pc11dist-poly-gpkg/district.gpkg", quiet = TRUE)
d <- st_make_valid(d)
cat("districts:", nrow(d), "\n\n")

# Aire vraie = geodesique (s2) sur le sphero-ellipsoide, en 4326
a_true <- as.numeric(st_area(d))
# Aire planaire dans 7755
a_lcc  <- as.numeric(st_area(st_transform(d, 7755)))
# Aire planaire dans une LAEA equivalente centree sur l'Inde
laea <- "+proj=laea +lat_0=24 +lon_0=80 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
a_laea <- as.numeric(st_area(st_transform(d, laea)))

ctr <- st_coordinates(st_point_on_surface(st_transform(d, 4326)))
res <- data.table(state = d$pc11_state_id, dist = d$district_name,
                  lat = ctr[,2], lon = ctr[,1],
                  a_true = a_true, a_lcc = a_lcc, a_laea = a_laea)
res[, err_lcc  := a_lcc  / a_true - 1]      # erreur d'aire, LCC 7755
res[, err_laea := a_laea / a_true - 1]      # erreur d'aire, LAEA
res[, k := sqrt(a_lcc / a_true)]            # facteur d'echelle lineaire
res[, err_density := 1/k - 1]               # erreur sur longueur/aire

cat("=== Erreur d'AIRE dans EPSG:7755 (conforme) ===\n")
print(round(quantile(res$err_lcc, c(0,.05,.25,.5,.75,.95,1))*100, 3))
cat("\n=== Erreur d'AIRE dans LAEA equivalente ===\n")
print(round(quantile(res$err_laea, c(0,.05,.25,.5,.75,.95,1))*100, 3))
cat("\n=== Erreur sur une DENSITE longueur/aire calculee dans 7755 ===\n")
print(round(quantile(res$err_density, c(0,.05,.25,.5,.75,.95,1))*100, 3))

cat("\n=== Erreur d'aire 7755 par bande de latitude ===\n")
res[, bande := cut(lat, breaks=c(6,12,16,20,24,28,32,38))]
print(res[, .(n=.N, err_aire_pct = round(100*mean(err_lcc),2),
              err_dens_pct = round(100*mean(err_density),2)), by=bande][order(bande)])

cat("\n=== Extremes (aire) ===\n")
print(res[order(err_lcc)][c(1:3, (.N-2):.N), .(dist, lat=round(lat,2),
        err_aire_pct=round(100*err_lcc,2), err_dens_pct=round(100*err_density,2))])

cat("\n=== Uttar Pradesh seul (state 09) ===\n")
up <- res[state=="09"]
cat("n =", nrow(up), "\n")
cat("erreur aire  : moyenne", round(100*mean(up$err_lcc),3), "% | min",
    round(100*min(up$err_lcc),3), "| max", round(100*max(up$err_lcc),3), "\n")
cat("erreur densite: moyenne", round(100*mean(up$err_density),3), "% | min",
    round(100*min(up$err_density),3), "| max", round(100*max(up$err_density),3), "\n")
fwrite(res, "tmp_crs/crs_distortion.csv")
