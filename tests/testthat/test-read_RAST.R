library(testthat)
library(terra)
library(sp)
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

test_that("testing read_RAST using terra", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  # read a categorical raster map
  v1 <- read_RAST("landuse", cat = TRUE, return_format = "terra")
  expect_s4_class(v1, "SpatRaster")
  expect_false(inMemory(v1))

  # check the values and labels
  lvls <- terra::levels(v1)
  expect_equal(lvls[[1]]$value, 0:7)
  expect_equal(
    lvls[[1]]$label,
    c("undefined", "developed", "agriculture", "herbaceous", "shrubland",
      "forest", "water", "sediment")
  )
})

test_that("testing read_RAST using sp", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  nc_basic <- read_RAST("landuse", cat = TRUE, return_format = "SGDF")
  lvls <- levels(nc_basic$landuse)

  expect_equal(
    lvls,
    c("developed", "agriculture", "herbaceous", "shrubland",
      "forest", "water", "sediment")
  )
})
