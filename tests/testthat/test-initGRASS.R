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

  # Test gmeta working
  meta <- gmeta()

  expect_equal(
    names(meta),
    c("GISDBASE", "LOCATION_NAME", "MAPSET", "GRASS_GUI", "projection", "zone", "n",
      "s", "w", "e", "t", "b", "nsres", "nsres3", "ewres", "ewres3", "tbres", "rows", "rows3",
      "cols", "cols3", "depths", "cells", "cells3", "proj4")
  )

  expect_equal(meta$LOCATION_NAME, testdata$location)
  expect_equal(meta$projection, "99")
  expect_equal(crs(meta$proj4, describe = TRUE)$code, "3358")
  
  # Test old proj4 output from grass
  meta2 <- gmeta(g.proj_WKT = FALSE)
  expect_equal(meta2$proj4, paste(crs("epsg:3358", proj = TRUE), "+type=crs"))

  # Test gmeta2grd
  meta3 <- gmeta2grd()
  expect_s4_class(meta3, "GridTopology")
})
