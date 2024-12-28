library(testthat)
library(terra)
source("helper.R")

# setup
testdata <- download_nc_basic()
gisBase <- get_gisbase()

testthat::test_that("testing initGRASS", {
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
})
