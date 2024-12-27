library(testthat)
library(terra)
source("helper.R")

# setup
testdata <- download_nc_basic()
gisBase <- get_gisbase()

testthat::test_that("testing gmeta", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  # Initialize a temporary GRASS project using the example data
  loc <- initGRASS(
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

  # Get location
  gLP <- getLocationProj()
  
  # Test coercions
  expect_s4_class(sp::CRS(gLP), "CRS")
  expect_type(terra::crs(gLP), "character")
})
