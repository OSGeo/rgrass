library(testthat)
library(terra)

# test basic read_VECT operation
test_that("testing read_VECT", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  if (!is.null(gisBase)) {
    loc <- initGRASS(
      home = tempdir(),
      gisBase = gisBase,
      gisDbase = testdata$gisDbase,
      location = "nc_basic_spm_grass7",
      mapset = "PERMANENT",
      override = TRUE
    )
  }

  # test basic read/write (using grass gdal driver, misses epsg code)
  schs <- read_VECT("schools")
  expect_s4_class(schs, "SpatVector")
  # expect_equal(crs(schs, describe = TRUE)$code, NA_character_)

  # expect failute when using gdal driver (not using grass driver)
  schs2 <- read_VECT("schools", use_gdal_grass_driver = FALSE)
  expect_s4_class(schs, "SpatVector")
  # expect_equal(crs(schs, describe = TRUE)$code, "3358")
})

test_that("testing write_VECT", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  shp <- vect(system.file("ex/lux.shp", package = "terra"))
  elev <- rast(system.file("ex/elev.tif", package = "terra"))

  loc <- initGRASS(home = tempdir(), gisBase = gisBase, SG = elev, override = TRUE)
  write_VECT(shp, "lux")

  lux <- read_VECT("lux")
  expect_s4_class(lux, "SpatVector")
  expect_equal(nrow(lux), nrow(shp))
  expect_equal(ncol(lux) - 1, ncol(shp))
  expect_setequal(names(lux), c("cat", names(shp)))

  grass_colummns <- vColumns("lux")[, 2]
  expect_setequal(grass_colummns, c("cat", names(shp)))
})

# test basic vect2neigh operation
test_that("testing vect2neigh", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  if (!is.null(gisBase)) {
    loc <- initGRASS(
      home = tempdir(),
      gisBase = gisBase,
      gisDbase = testdata$gisDbase,
      location = "nc_basic_spm_grass7",
      mapset = "PERMANENT",
      override = TRUE
    )
  }

  cen_neig <- vect2neigh("census", ignore.stderr = TRUE)
  expect_s3_class(cen_neig, c("data.frame", "GRASSneigh", "spatial.neighbour"))
  expect_equal(names(cen_neig), c("left", "right", "length"))
})
