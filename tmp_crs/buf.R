suppressMessages({library(sf); library(data.table)})
sf_use_s2(TRUE)
w <- readRDS("build/cgwb_wells.rds")
set.seed(1)
# puits repartis sur toute l'amplitude de latitude
w <- as.data.table(w)[order(LAT)]
idx <- round(seq(1, nrow(w), length.out = 12))
s <- w[idx, .(WLCODE, STATE, LAT, LON)]
laea <- "+proj=laea +lat_0=24 +lon_0=80 +datum=WGS84 +units=m +no_defs"
R <- 5000  # rayon 5 km

res <- rbindlist(lapply(seq_len(nrow(s)), function(i) {
  p4326 <- st_sfc(st_point(c(s$LON[i], s$LAT[i])), crs = 4326)
  aeqd <- sprintf("+proj=aeqd +lat_0=%.6f +lon_0=%.6f +datum=WGS84 +units=m +no_defs",
                  s$LAT[i], s$LON[i])
  # tampon construit dans chaque projection, puis aire mesuree dans cette projection
  a_aeqd <- as.numeric(st_area(st_buffer(st_transform(p4326, aeqd), R)))
  a_lcc  <- as.numeric(st_area(st_buffer(st_transform(p4326, 7755), R)))
  a_laea <- as.numeric(st_area(st_buffer(st_transform(p4326, laea), R)))
  # aire vraie au sol d'un disque de 5 km : pi*R^2 (AEQD local = reference)
  a_true <- pi * R^2
  data.table(WLCODE = s$WLCODE[i], STATE = s$STATE[i], lat = s$LAT[i],
             err_aeqd = a_aeqd/a_true - 1,
             err_lcc  = a_lcc /a_true - 1,
             err_laea = a_laea/a_true - 1)
}))
cat("Tampon de 5 km autour d'un puits : erreur d'AIRE selon la projection\n")
cat("(tampon construit ET mesure dans la meme projection ; reference = pi*R^2)\n\n")
print(res[, .(STATE, lat = round(lat,2),
              aeqd_pct = round(100*err_aeqd, 4),
              lcc7755_pct = round(100*err_lcc, 4),
              laea_pct = round(100*err_laea, 4))])
cat("\nEtendue entre puits (points de %) :\n")
cat("  AEQD local :", round(100*(max(res$err_aeqd)-min(res$err_aeqd)), 4), "\n")
cat("  EPSG:7755  :", round(100*(max(res$err_lcc) -min(res$err_lcc)),  4), "\n")
cat("  LAEA Inde  :", round(100*(max(res$err_laea)-min(res$err_laea)), 4), "\n")
