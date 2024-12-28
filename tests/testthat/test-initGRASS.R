library(testthat)
library(terra)
source("helper.R")

# setup
testdata <- download_nc_basic()
gisBase <- get_gisbase()

test_that("testing basic initGRASS", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  # Initialize a temporary GRASS project using the example data
  loc <- initGRASS(
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

  expect_s3_class(loc, "gmeta")
  expect_equal(loc$LOCATION_NAME, "nc_basic_spm_grass7")
  expect_equal(loc$projection, "99")
  expect_equal(crs(loc$proj4, describe = TRUE)$name, "NAD83(HARN) / North Carolina")
})

test_that("testing initialization from SpatRaster", {
  meuse_grid <- rast(system.file("ex/meuse.tif", package = "terra"))
  loc <- initGRASS(gisBase = gisBase, SG = meuse_grid, override = TRUE)
  expect_s3_class(loc, "gmeta")
})
