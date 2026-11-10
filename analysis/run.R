# From web/: Rscript analysis/run.R
library(jsonlite)
library(sp)
library(ggplot2)
options(stringsAsFactors = FALSE, scipen = 99)
dir.create("scratch", showWarnings = FALSE)
dir.create("analysis/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("site/data", recursive = TRUE, showWarnings = FALSE)

# Keep unchanged source files in scratch.
commit <- "064cf60c13e7ddfbd20c5cbfd1ec220bec200d92"
repo <- paste0("https://raw.githubusercontent.com/mjmoon/sta313-project-datasets/", commit, "/")
input <- function(name, local, url) {
  f <- file.path("scratch", name)
  if (!file.exists(f)) {
    if (file.exists(local)) file.copy(local, f) else download.file(url, f, mode = "wb")
  }
  f
}
files <- c(schools = "ONT-SCHOOL/ont-school-demo-info.csv",
           OW = "ONT-SA/ont-sa-characteristic-ow-cma.csv",
           ODSP = "ONT-SA/ont-sa-characteristic-odsp-cma.csv")
paths <- sapply(files, function(f) input(basename(f),
  file.path("../Files/sta313-project-datasets", f), paste0(repo, f)))
geo_url <- paste0("https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/6/query?",
  "where=PRUID%3D%2735%27%20AND%20CMAUID%20IN%20%28%27505%27,%27521%27,%27529%27,%27532%27,%27535%27,%27537%27,%27539%27,%27541%27,%27543%27,%27550%27,%27555%27,%27559%27,%27568%27,%27580%27,%27595%27%29",
  "&outFields=CMAUID,CMANAME,PRUID&outSR=4326&f=geojson&geometryPrecision=6")
outline_url <- paste0("https://geo.statcan.gc.ca/geo_wa/rest/services/2021/Cartographic_boundary_files/MapServer/0/query?",
  "where=PRUID%3D%2735%27&outFields=PRUID,PRNAME&outSR=4326&f=geojson&maxAllowableOffset=0.01&geometryPrecision=5")
geo_file <- input("cma-boundaries.geojson", "../Project/project/data/cma-boundaries.geojson", geo_url)
outline_file <- input("ontario-outline.geojson", "../Project/project/data/ontario-outline.geojson", outline_url)
geo <- fromJSON(geo_file, simplifyVector = FALSE)
outline <- fromJSON(outline_file, simplifyVector = FALSE)

school <- read.csv(paths['schools'], colClasses = "character", na.strings = "NA")
stopifnot(ncol(school) == 36, !anyDuplicated(school[c("year", "school_number")]))
codes <- c("Deaf", "Blind", "Deaf/Blind", "Demonstration")
school <- school[school$school_special_condition_code %in% codes, ]
s <- data.frame(year = school$year, id = school$school_number, name = school$school_name,
                code = school$school_special_condition_code, stage = school$school_level,
                city = school$city, lon = as.numeric(school$longitude),
                lat = as.numeric(school$latitude), enrolment = school$enrolment)
s$location <- ifelse(is.na(s$lon) | is.na(s$lat), NA,
                     sprintf("%.6f,%.6f", s$lon, s$lat))

# Assign coordinates with complete polygons, including holes.
polygons <- function(g) if (g$type == "Polygon") list(g$coordinates) else g$coordinates
ring <- function(x) do.call(rbind, lapply(x, unlist))
inside <- function(x, y, g) {
  found <- rep(FALSE, length(x))
  for (p in polygons(g)) {
    r <- ring(p[[1]])
    hit <- point.in.polygon(x, y, r[, 1], r[, 2]) > 0
    if (length(p) > 1) for (h in p[-1]) {
      r <- ring(h)
      hit <- hit & point.in.polygon(x, y, r[, 1], r[, 2]) != 1
    }
    found <- found | hit
  }
  found
}
loc <- unique(s[!is.na(s$location), c("location", "lon", "lat")])
match_area <- sapply(geo$features, function(f) inside(loc$lon, loc$lat, f$geometry))
area_codes <- sapply(geo$features, function(f) f$properties$CMAUID)
stopifnot(length(unique(area_codes)) == 15, all(rowSums(match_area) <= 1))
loc$area <- apply(match_area, 1, function(x) if (any(x)) area_codes[which(x)] else NA)
s$area <- loc$area[match(s$location, loc$location)]
s$status <- ifelse(is.na(s$location), "Coordinates unavailable",
                   ifelse(is.na(s$area), "Outside assistance coverage", "Matched"))

read_cases <- function(programme) {
  x <- read.csv(paths[programme])
  x$programme <- programme
  x$area <- as.character(x$cma_code)
  x$name <- sub("^[0-9]+ - ", "", x$cma)
  x$name[x$area == "505"] <- "Ottawa-Gatineau (Ontario)"
  x$name <- gsub("--", "-", x$name)
  # Snapshots refer to the end of the quarter's final month.
  d <- as.Date(sprintf("%d-%02d-01", x$year, x$month))
  x$date <- as.Date(format(d + 31, "%Y-%m-01")) - 1
  x$single_parent <- 100 * x$ftsp / x$cases
  x
}
ow <- read_cases("OW")
odsp <- read_cases("ODSP")
keep <- c("programme", "area", "name", "date", "cases", "fts", "ftsp", "ftc",
          "age24", "age2554", "age55", "single_parent")
a <- rbind(ow[keep], odsp[keep])
a <- a[order(a$programme, a$area, a$date), ]
stopifnot(!anyDuplicated(a[c("programme", "area", "date")]),
          all(table(a$programme, a$area) == 93), !anyNA(a$cases), all(a$cases > 0),
          setequal(a$area, area_codes), all(a$fts + a$ftsp + a$ftc == a$cases),
          all(a$age24 + a$age2554 + a$age55 == a$cases))
for (x in split(a, interaction(a$programme, a$area)))
  stopifnot(identical(x$date, sort(unique(a$date))))
latest <- s[s$year == max(s$year), ]
now <- a[a$date == as.Date("2025-03-31"), ]
stopifnot(nrow(latest) == 16, length(unique(latest$location)) == 5,
          sum(latest$status == "Matched") == 12,
          all(table(latest$area) == 4))
source("analysis/figures.R")

# Simplify only the display copy; spatial assignment above uses the originals.
simplify_line <- function(m, tolerance = 0.006) {
  if (nrow(m) <= 3) return(m)
  v <- m[nrow(m), ] - m[1, ]
  t <- if (sum(v^2) == 0) rep(0, nrow(m)) else
    pmax(0, pmin(1, as.vector(sweep(m, 2, m[1, ]) %*% v) / sum(v^2)))
  d <- sqrt(rowSums((m - (matrix(m[1, ], nrow(m), 2, byrow = TRUE) + t %o% v))^2))
  k <- which.max(d)
  if (d[k] <= tolerance) return(m[c(1, nrow(m)), , drop = FALSE])
  rbind(simplify_line(m[1:k, , drop = FALSE], tolerance),
        simplify_line(m[k:nrow(m), , drop = FALSE], tolerance)[-1, , drop = FALSE])
}
simple_ring <- function(r) {
  m <- ring(r)
  z <- simplify_line(m)
  if (nrow(z) < 4) z <- m
  lapply(seq_len(nrow(z)), function(i) unname(z[i, ]))
}
simple_feature <- function(f) {
  p <- lapply(polygons(f$geometry), function(p) lapply(p, simple_ring))
  f$geometry$coordinates <- if (f$geometry$type == "Polygon") p[[1]] else p
  f
}
geo$features <- lapply(geo$features, simple_feature)
outline$features <- lapply(outline$features, simple_feature)
export <- function(x, file, name) writeLines(paste0("window.", name, " = ",
  toJSON(x, auto_unbox = TRUE, na = "null", digits = 6), ";"), file)
export(list(schools = s, cases = a, years = sort(unique(s$year)),
            sources = list(course = paste0("https://github.com/mjmoon/sta313-project-datasets/tree/", commit),
                           boundaries = geo_url, outline = outline_url)), "site/data/data.js", "DATA")
export(list(areas = geo, outline = outline), "site/data/geography.js", "GEOGRAPHY")

# Findings are rebuilt from the same values used in the figures and page.
fmt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
lines <- c("# Findings", "", "First pass for the layout, using the course data. Run from `web/`:", "",
           "```sh", "Rscript analysis/run.R", "```", "",
           "Requires ggplot2, jsonlite and sp. Source downloads and temporary work stay in scratch/.", "",
           "## Checked", "",
           sprintf("- School selection: %d records across eight school years, 2017-2018 to 2024-2025.", nrow(s)),
           "- 2024-2025: 16 records at five reported coordinates. Records are not campus counts.",
           "- Toronto, London and Brantford each contain four records. Belleville's four records are outside the 15-area assistance coverage.",
           sprintf("- %d selected records have no coordinates, all in 2017-2018 or 2018-2019. Keep these in the list, not on the map.", sum(is.na(s$location))),
           "- Each programme has 1,395 rows: 15 areas and 93 quarters, March 2003 to March 2026.",
           "- No duplicate area/programme/quarter keys or missing case totals. Family and age counts sum to total cases.", "",
           "## March 2025", "")
for (p in c("OW", "ODSP")) {
  x <- now[now$programme == p, ]; hi <- x[which.max(x$cases), ]; lo <- x[which.min(x$cases), ]
  sp_hi <- x[which.max(x$single_parent), ]; sp_lo <- x[which.min(x$single_parent), ]
  lines <- c(lines, sprintf("- %s totals range from %s in %s to %s in %s. These are counts, not population rates.",
                            p, fmt(lo$cases), lo$name, fmt(hi$cases), hi$name),
             sprintf("- %s single-parent share ranges from %.1f%% in %s to %.1f%% in %s, using all cases in each area as the denominator.",
                      p, sp_lo$single_parent, sp_lo$name, sp_hi$single_parent, sp_hi$name))
}
lines <- c(lines, "", "## Figures and layout", "",
           "- 01: school records and reported locations need separate labels. Four records can share one coordinate.",
           "- 02: common count scales preserve area differences, but Toronto dominates. Keep an exact value on every row and offer a percentage measure separately.",
           "- 03: histories show change within each area. The index sets March 2003 to 100; it does not compare absolute caseload size.",
           "- 04: family shares use a shared 0-100% scale, with OW and ODSP distinguished by both shape and colour.", "",
           "## Still open", "",
           "- Population rates: confirm assistance boundary definitions and choose compatible reference dates before adding Table 17-10-0148-01. No rates are displayed yet.",
           "- 2021 boundaries are reference geography; equivalence to historical assistance areas is unconfirmed.",
           "- School filters change school records only. They cannot filter assistance to pupils or their families.",
           "- The pitch's policy-impact and cost-effectiveness questions cannot be answered by these files. No funding, rejected applications or pupil-to-case links are supplied.",
           "- No selected records in an area does not mean no special education is available there.",
           "- Test the layout with the group, replace placeholder prose and agree on the final chart states.", "",
           "## Sources", "", paste0("- [Course snapshot](https://github.com/mjmoon/sta313-project-datasets/tree/", commit, ")"),
           paste0("- [2021 CMA boundaries](", geo_url, ")"), paste0("- [Ontario outline](", outline_url, ")"), "",
           "Source fingerprints (MD5):", "", "```", capture.output(print(tools::md5sum(c(paths, geo_file, outline_file)))), "```", "",
           paste("Run with", R.version.string, "and ggplot2", packageVersion("ggplot2")))
writeLines(lines, "analysis/findings.md")
writeLines(capture.output(sessionInfo()), "scratch/session.txt")
cat("Checked data, four figures and webpage data saved.\n")
