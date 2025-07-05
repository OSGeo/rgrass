library(testthat)
library(terra)

testthat::test_that("testing gmeta", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  # Initialize a temporary GRASS project using the example data
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

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

  # Test old proj4 output from grass
  meta2 <- gmeta(g.proj_WKT = FALSE)
  expect_equal(meta2$proj4, paste(crs("epsg:3358", proj = TRUE), "+type=crs"))

  # Test gmeta2grd
  meta3 <- gmeta2grd()
  expect_s4_class(meta3, "GridTopology")

  # Test just returning the projection
  meta4 <- getLocationProj()
  expect_equal(meta4, meta$proj4)

  meta4 <- getLocationProj(g.proj_WKT = FALSE)
  expect_equal(meta4, paste(crs("epsg:3358", proj = TRUE), "+type=crs"))

  # Test coercion of projection into terra and sp classes
  gLP <- getLocationProj()
  expect_type(terra::crs(gLP), "character")

  # disabled due to unknown issue with sp reading WTK
  # expect_s4_class(sp::CRS(gLP), "CRS")
})
