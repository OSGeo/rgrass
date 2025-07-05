library(testthat)
library(terra)

test_that("testing ignore.stderrOption", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  origIgnoreStderr <- get.ignore.stderrOption()

  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

  # test setting ignore.stderrOption
  expect_false(get.ignore.stderrOption())
  set.ignore.stderrOption(TRUE)
  expect_true(get.ignore.stderrOption())

  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    ignore.stderr = TRUE,
    override = TRUE
  )
  expect_true(get.ignore.stderrOption())

  # restore defaults
  set.ignore.stderrOption(origIgnoreStderr)
})

test_that("testing stop_on_no_flags_parasOption", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  origStopOnNoFlagsParas <- get.stop_on_no_flags_parasOption()

  # testing stop_on_no_flags_parasOption set to TRUE by default
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )
  expect_true(get.stop_on_no_flags_parasOption())

  # TODO: what is the purpose of stop_on_no_flags_parasOption because
  # commands with no arguments appear to succeed irrespectively, and commands
  # missing required arguments appear to fail irrespectively?
  # expect_error(
  #   execGRASS("g.gisenv"),
  #   regexp = "required parameters with no defaults missing:"
  # )

  set.stop_on_no_flags_parasOption(FALSE)
  expect_false(get.stop_on_no_flags_parasOption())
  # expect_no_error(execGRASS("g.gisenv"))

  # restore defaults
  set.stop_on_no_flags_parasOption(origStopOnNoFlagsParas)
})

test_that("testing echoCmdOption option", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  origEchoCmd <- get.echoCmdOption()

  # testing echoCmdOption (set to FALSE by default)
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )
  expect_false(get.echoCmdOption())

  # testing echoCmdOption set to true with the GRASS command printed to the console
  set.echoCmdOption(TRUE)
  expect_true(get.echoCmdOption())

  res <- capture.output({
    x <- execGRASS("g.list", type = "raster", intern = TRUE)
    }
  )
  expect_true(length(res) > 0)

  # testing echoCmdOption set to false with the GRASS command is silent
  set.echoCmdOption(FALSE)
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )
  res <- capture.output({
    x <- execGRASS("g.list", type = "raster", intern = TRUE)
    }
  )
  expect_length(res, 0)

  # restore defaults
  set.stop_on_no_flags_parasOption(origEchoCmd)
})

test_that("testing useInternOption option", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  origUseIntern <- get.useInternOption()

  # testing echoCmdOption (set to FALSE by default)
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )
  expect_false(get.useInternOption())
  res <- execGRASS("g.list", type = "raster")
  expect_true(res == 0)

  # test echoCmdOption set to TRUE
  set.useInternOption(TRUE)
  expect_true(get.useInternOption())
  res <- execGRASS("g.list", type = "raster")
  expect_length(res, 7)

  # restore defaults
  set.useInternOption(origUseIntern)
})

test_that("testing legacyExecOption option", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  origLegacyExec <- get.legacyExecOption()

  # testing echoCmdOption (set to FALSE by default)
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

  # test legacyExecOption set to FALSE (uses system2 which returns resOut and resErr)
  # default set to FALSE on nix and TRUE on windows
  if (.Platform$OS.type != "windows") {
    expect_false(get.legacyExecOption())
  } else {
    expect_true(get.legacyExecOption())
  }

  res <- execGRASS("r.stats", input = "elevation", flags = c("C", "n"),
                   ignore.stderr = TRUE)

  if (.Platform$OS.type != "windows") {
    expect_named(attributes(res), c("resOut", "resErr"))
  } else {
    expect_null(attributes(res))
  }

  # test legacyExecOption set to TRUE (uses system only returns the module return code)
  set.legacyExecOption(TRUE)
  res <- execGRASS("r.stats", input = "elevation", flags = c("C", "n"))
  expect_equal(res, 0)
  expect_null(attributes(res))

  # restore defaults
  set.legacyExecOption(origLegacyExec)
})

test_that("testing defaultFlagsOption option", {
  skip_if_not(!is.null(gisBase), "GRASS GIS not found on PATH")
  skip_if(is.null(testdata), "GRASS GIS example dataset is not available")

  origDefaultFlags <- get.defaultFlagsOption()

  # testing echoCmdOption (set to FALSE by default)
  loc <- initGRASS(
    home = tempdir(),
    gisBase = gisBase,
    gisDbase = testdata$gisDbase,
    location = "nc_basic_spm_grass7",
    mapset = "PERMANENT",
    override = TRUE
  )

  # test defaultFlagsOption set to NULL
  expect_null(get.defaultFlagsOption())

  # test defaultFlagsOption set to "verbose"
  set.defaultFlagsOption("verbose")
  expect_equal(get.defaultFlagsOption(), "verbose")

  # restore defaults
  set.defaultFlagsOption(origDefaultFlags)
})
