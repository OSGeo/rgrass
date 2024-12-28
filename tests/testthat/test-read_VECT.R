library(testthat)
library(terra)
source("helper.R")

# setup (share grass session across tests)
testdata <- download_nc_basic()
gisBase <- get_gisbase()

if (!is.null(gisBase)) {
  loc <- initGRASS(
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )
}

# test basic read_VECT operation
test_that("testing read_VECT", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  # test basic read/write
  schs <- read_VECT("schools", use_gdal_grass_driver = FALSE)
  expect_s4_class(schs, "SpatVector")
  expect_equal(crs(schs, describe = TRUE)$code, "3358")

  schs <- schs[, -which(names(schs) == "cat")]
  write_VECT(schs, "newsch", flags = c("o", "overwrite"))

  newschs <- read_VECT("newsch")
  expect_s4_class(newschs, "SpatVector")

  grass_colummns <- vColumns("newsch")[, 2]
  expect_equal(names(newschs), grass_colummns)

  execGRASS("g.remove", type = "vector", name = "newsch", flags = "f")
})

# test basic vect2neigh operation
test_that("testing vect2neigh", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  cen_neig <- vect2neigh("census", ignore.stderr = TRUE)
  expect_s3_class(cen_neig, c("data.frame", "GRASSneigh", "spatial.neighbour"))
  expect_equal(names(cen_neig), c("left", "right", "length"))
})
