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

test_that("testing remove_GISRC", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")

  loc <- initGRASS(
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    remove_GISRC = TRUE,
    pid = 1000,
    override = TRUE
  )

  lockfile <- Sys.getenv("GISRC")
  expect_true(file.exists(lockfile))

  remove_GISRC()
  expect_false(file.exists(lockfile))
})

test_that("testing set/unset.GIS_LOCK", {
  loc <- initGRASS(
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    remove_GISRC = TRUE,
    override = TRUE
  )

  expect_false(
    file.exists(file.path(testdata$gisDbase, "nc_basic_spm_grass7", "user1", ".gislock"))
  )

  loc <- initGRASS(
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    remove_GISRC = TRUE,
    pid = 1000,
    override = TRUE
  )

  # note - shouldn't this be an integer?
  expect_equal(get.GIS_LOCK(), "1000")

  # test setting a lock by switching to mapset
  execGRASS("g.mapset", mapset = "user1")
  expect_true(
    file.exists(file.path(testdata$gisDbase, "nc_basic_spm_grass7", "user1", ".gislock"))
  )

  # changing mapset will cause the lockfile to be removed for current session
  execGRASS("g.mapset", mapset = "PERMANENT")
  expect_false(
    file.exists(file.path(testdata$gisDbase, "nc_basic_spm_grass7", "user1", ".gislock"))
  )
  
  # test removing the lock
  unset.GIS_LOCK()
  expect_equal(get.GIS_LOCK(), "")

  # test removing the GICRC
  expect_error(
    initGRASS(
      gisBase = gisBase,
      gisDbase = testdata$gisDbase,
      location = "nc_basic_spm_grass7",
      mapset = "user1",
      override = FALSE
    ),
    regexp = "A GRASS location"
  )

  remove_GISRC()

  expect_no_error(
    initGRASS(
      gisBase = gisBase,
      gisDbase = testdata$gisDbase,
      location = "nc_basic_spm_grass7",
      mapset = "user1",
      override = FALSE
    )
  )

  unlink(file.path(testdata$gisDbase, "nc_basic_spm_grass7", "user1", ".gislock"))
})
