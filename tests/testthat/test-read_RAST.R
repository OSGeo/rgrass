library(testthat)
library(terra)
library(sp)

if (!is.null(gisBase) & !is.null(testdata)) {
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )
}

test_that("testing read_RAST using terra", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

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
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")
  skip_on_ci()
  skip_on_cran()

  # check getting the location
  grass_crs <- execGRASS("g.proj", flags = c("w"), intern = TRUE, ignore.stderr = TRUE)
  grass_crs <- paste(grass_crs, collapse = "\n")

  crs_terra <- terra::crs(grass_crs)
  expect_type(crs_terra, "character")
  expect_equal(terra::crs(grass_crs, describe = TRUE)$code, "3358")

  crs_sp <- sp::CRS(terra::crs(grass_crs))
  expect_s4_class(crs_sp, "CRS")

  grass_crs1 <- getLocationProj()
  expect_type(terra::crs(grass_crs1), "character")
  expect_equal(terra::crs(grass_crs1, describe = TRUE)$code, "3358")

  # test reading a raster map using sp
  nc_basic <- read_RAST("landuse", cat = TRUE, return_format = "SGDF")
  lvls <- levels(nc_basic$landuse)

  expect_equal(
    lvls,
    c("developed", "agriculture", "herbaceous", "shrubland",
      "forest", "water", "sediment")
  )
})
