test_that("create_session_directories creates a requested session layout", {
  gisDbase <- tempfile("grass-database-")
  withr::defer(unlink(gisDbase, recursive = TRUE))

  session <- create_session_directories(
    gisDbase = gisDbase,
    location = "location1",
    mapset = "user1",
    tempdir = tempdir()
  )

  expect_identical(session$gisDbase, gisDbase)
  expect_identical(session$location, "location1")
  expect_identical(session$mapset, "user1")
  expect_identical(session$loc_path, file.path(gisDbase, "location1"))
  expect_true(dir.exists(file.path(session$loc_path, "PERMANENT")))
  expect_true(dir.exists(file.path(session$loc_path, "user1")))
})

test_that("create_session_directories supplies temporary defaults", {
  session_tempdir <- tempfile("rgrass-session-")
  dir.create(session_tempdir)
  withr::defer(unlink(session_tempdir, recursive = TRUE))

  session <- create_session_directories(tempdir = session_tempdir)

  expect_identical(session$gisDbase, session_tempdir)
  expect_true(nzchar(session$location))
  expect_true(nzchar(session$mapset))
  expect_true(dir.exists(file.path(session$loc_path, "PERMANENT")))
  expect_true(dir.exists(file.path(session$loc_path, session$mapset)))
})

test_that("write_gisrc records the complete Unix session", {
  home <- tempfile("rgrass-home-")
  dir.create(home)
  withr::defer(unlink(home, recursive = TRUE))
  withr::local_envvar(GISRC = NA)

  gisrc <- write_gisrc(
    gisDbase = "/data/grass",
    location = "location1",
    mapset = "user1",
    home = home,
    gv = list(major = "8"),
    platform = "unix",
    override = TRUE
  )

  expect_identical(gisrc, file.path(home, ".grassrc8"))
  expect_identical(Sys.getenv("GISRC"), gisrc)

  settings <- read.dcf(gisrc)
  expect_identical(unname(settings[1, "GISDBASE"]), "/data/grass")
  expect_identical(unname(settings[1, "LOCATION_NAME"]), "location1")
  expect_identical(unname(settings[1, "MAPSET"]), "user1")
  expect_identical(unname(settings[1, "GRASS_GUI"]), "text")
})

test_that("write_gisrc initializes a Windows session without GRASS commands", {
  home <- tempfile("rgrass-windows-home-")
  gisDbase <- tempfile("rgrass-windows-database-")
  dir.create(home)
  dir.create(gisDbase)
  withr::defer(unlink(c(home, gisDbase), recursive = TRUE))
  withr::local_envvar(GISRC = NA)

  gisrc <- write_gisrc(
    gisDbase = normalizePath(gisDbase, winslash = "/"),
    location = "location1",
    mapset = "user1",
    home = home,
    gv = list(major = "8"),
    platform = "WinNat",
    override = TRUE,
    use_g.dirseps.exe = TRUE
  )

  expect_identical(
    gisrc,
    normalizePath(
      file.path(home, ".grassrc8"),
      winslash = "/",
      mustWork = FALSE
    )
  )
  expect_true(file.exists(gisrc))
  expect_identical(Sys.getenv("GISRC"), gisrc)
  expect_identical(
    unname(read.dcf(gisrc)[1, "GISDBASE"]),
    normalizePath(gisDbase, winslash = "/")
  )
})

test_that("write_gisrc protects an existing file", {
  home <- tempfile("rgrass-home-")
  dir.create(home)
  withr::defer(unlink(home, recursive = TRUE))
  writeLines("existing configuration", file.path(home, ".grassrc8"))

  expect_error(
    write_gisrc(
      gisDbase = "/data/grass",
      location = "location1",
      mapset = "user1",
      home = home,
      gv = list(major = "8"),
      platform = "unix",
      override = FALSE,
      missing_override = FALSE
    ),
    "A GISRC file.*already exists"
  )
})

test_that("Python setup preserves an existing executable", {
  withr::local_envvar(GRASS_PYTHON = "/custom/python")

  result <- set_grass_python(
    OSGEO4W_ROOT = "/unused",
    grass_version = "8.4.0"
  )

  expect_identical(result, "/custom/python")
  expect_identical(Sys.getenv("GRASS_PYTHON"), "/custom/python")
})

test_that("Python setup selects the OSGeo4W executable", {
  osgeo_root <- tempfile("osgeo4w-")
  dir.create(file.path(osgeo_root, "bin"), recursive = TRUE)
  withr::defer(unlink(osgeo_root, recursive = TRUE))
  withr::local_envvar(GRASS_PYTHON = NA)

  python3 <- file.path(osgeo_root, "bin", "python3.exe")
  file.create(python3)
  expect_identical(
    set_grass_python(OSGEO4W_ROOT = osgeo_root),
    python3
  )

  Sys.unsetenv("GRASS_PYTHON")
  unlink(python3)
  expect_identical(
    set_grass_python(OSGEO4W_ROOT = osgeo_root),
    file.path(osgeo_root, "bin", "python.exe")
  )
})

test_that("Python setup selects an executable from the GRASS version", {
  old_addexe <- get("addEXE", envir = .GRASS_CACHE)
  withr::defer(assign("addEXE", old_addexe, envir = .GRASS_CACHE))
  assign("addEXE", "", envir = .GRASS_CACHE)
  withr::local_envvar(GRASS_PYTHON = NA)

  expect_identical(
    set_grass_python(OSGEO4W_ROOT = "", grass_version = "8.4.0"),
    "python3"
  )

  Sys.unsetenv("GRASS_PYTHON")
  expect_identical(
    set_grass_python(OSGEO4W_ROOT = "", grass_version = "7.6.1"),
    "python"
  )
})

test_that("write_wind creates default region files", {
  loc_path <- tempfile("grass-location-")
  mapset <- "user1"
  dir.create(file.path(loc_path, "PERMANENT"), recursive = TRUE)
  dir.create(file.path(loc_path, mapset))
  withr::defer(unlink(loc_path, recursive = TRUE))

  commands <- character()
  local_mocked_bindings(
    execGRASS = function(cmd, ...) {
      commands <<- c(commands, cmd)
      invisible(NULL)
    },
    .package = "rgrass"
  )

  expect_invisible(
    write_wind(
      loc_path = loc_path,
      mapset = mapset,
      SG = NULL,
      ignore.stderr = TRUE
    )
  )

  default_wind <- file.path(loc_path, "PERMANENT", "DEFAULT_WIND")
  permanent_wind <- file.path(loc_path, "PERMANENT", "WIND")
  mapset_wind <- file.path(loc_path, mapset, "WIND")

  expect_true(file.exists(default_wind))
  expect_identical(readLines(permanent_wind), readLines(default_wind))
  expect_identical(readLines(mapset_wind), readLines(default_wind))
  expect_identical(commands, "g.region")

  region <- read.dcf(default_wind)
  expect_identical(unname(region[1, "proj"]), "99")
  expect_identical(unname(region[1, "north"]), "1")
  expect_identical(unname(region[1, "south"]), "0")
  expect_identical(unname(region[1, "cols"]), "1")
  expect_identical(unname(region[1, "rows"]), "1")
})

test_that("write_wind rejects unsupported SG objects", {
  loc_path <- tempfile("grass-location-")
  mapset <- "user1"
  dir.create(file.path(loc_path, "PERMANENT"), recursive = TRUE)
  dir.create(file.path(loc_path, mapset))
  withr::defer(unlink(loc_path, recursive = TRUE))

  expect_error(
    write_wind(
      loc_path = loc_path,
      mapset = mapset,
      SG = list(),
      ignore.stderr = TRUE
    ),
    "SG must be a SpatRaster or SpatialGrid object"
  )
})
