library(testthat)
library(terra)

test_that("testing basic doGRASS, execGRASS, stringexecGRASS", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  # This test case will also check the `tempdir` argument to `initGRASS`.
  tp = tempfile()
  dir.create(tp)
  previous.tempdir.contents = dir(tempdir())

  loc <- initGRASS(
    home = tp,
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE,
    tempdir = tp
  )

  # test assembling the command using arguments
  cmd <- doGRASS(
    "r.slope.aspect",
    elevation = "elevation",
    slope = "slope",
    aspect = "aspect"
  )

  expect_type(cmd, "character")
  cmd_expected <- ifelse(
    .Platform$OS.type == "windows",
    "r.slope.aspect.exe",
    "r.slope.aspect"
  )
  expect_equal(attributes(cmd)$cmd, cmd_expected)
  expect_equal(
    as.character(cmd),
    paste(cmd_expected, "elevation=elevation slope=slope aspect=aspect")
  )

  # test assembling the command using a list
  params <- list(elevation = "elevation", slope = "slope", aspect = "aspect")
  cmd2 <- doGRASS("r.slope.aspect", parameters = params)
  expect_equal(cmd, cmd2)

  # test executing the command
  # TODO this fails on windows due to .exe being added
  stringexecGRASS(gsub(".exe", "", cmd))
  aspect <- read_RAST("aspect")
  expect_equal(as.numeric(minmax(aspect)), c(0, 360))
  execGRASS(
    "g.remove",
    type = "raster",
    name = c("slope", "aspect"),
    flags = "f"
  )

  # test executing the command based on the execGRASS wrapper
  execGRASS(
    "r.slope.aspect",
    elevation = "elevation",
    slope = "slope",
    aspect = "aspect"
  )
  aspect <- read_RAST("aspect")
  expect_equal(as.numeric(minmax(aspect)), c(0, 360))
  execGRASS(
    "g.remove",
    type = "raster",
    name = c("slope", "aspect"),
    flags = "f"
  )

  # Try executing 'r.stats' command which will fail because "fire_blocksgg"
  # does not exist in the mapset
  # expect_error(
  #   res <- execGRASS("r.stats", input = "fire_blocksgg", flags = c("c", "n")),
  #   regexp = "ERROR:"
  # )

  # Test using an invalid parameter
  expect_error(
    execGRASS(
      "r.stats",
      input = "elevation",
      flags = c("c", "n"),
      silent = TRUE
    ),
    "Invalid parameter name: silent"
  )

  # Our parameters to `initGRASS` should've prevented creating any new files
  # at the root of `tempdir()`.
  expect_equal(dir(tempdir()), previous.tempdir.contents)
})

test_that("testing options doGRASS, execGRASS, stringexecGRASS", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

  # test 'intern' = TRUE
  raster_maps <- c("basins", "elevation", "elevation_shade", "geology", "lakes",
                   "landuse", "soils")

  res <- execGRASS("g.list", type = "raster")
  expect_type(res, "integer")
  expect_true(res == 0)

  if (.Platform$OS.type != "windows") {
    expect_named(attributes(res), c("resOut", "resErr"))
    expect_equal(attr(res, "resOut"), raster_maps)
  }
  expect_length(attr(res, "resErr"), 0)

  res <- execGRASS("g.list", type = "raster", intern = TRUE)
  expect_type(res, "character")
  expect_equal(res, raster_maps)

  # Execute 'r.stats' with legacyExec
  res <- execGRASS(
    "r.stats",
    input = "elevation",
    flags = c("C", "n"),
    legacyExec = TRUE
  )
  expect_equal(res, 0)

  # Test redirect (allows command to fail with only warning)
  expect_warning(
    execGRASS(
      "r.stats",
      input = "fire_blocksgg",
      flags = c("C", "n"),
      redirect = TRUE,
      legacyExec = TRUE
    )
  )
})
