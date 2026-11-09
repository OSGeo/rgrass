test_that("search_grass uses GRASS_INSTALLATION when it is set", {
  grass_home <- tempfile("grass-installation-")
  dir.create(grass_home)
  withr::defer(unlink(grass_home, recursive = TRUE))
  withr::local_envvar(GRASS_INSTALLATION = grass_home)

  expect_message(
    result <- search_grass(),
    "Taking gisBase value from GRASS_INSTALLATION"
  )
  expect_identical(result, grass_home)
})

test_that("search_grass falls back to the grass command", {
  grass_home <- tempfile("grass-installation-")
  executable_dir <- tempfile("grass-path-")
  dir.create(executable_dir)
  withr::defer(unlink(executable_dir, recursive = TRUE))
  withr::local_envvar(GRASS_INSTALLATION = NA)

  if (.Platform$OS.type == "windows") {
    grass_executable <- file.path(executable_dir, "grass.bat")
    writeLines(
      c("@echo off", paste0("echo ", grass_home)),
      grass_executable
    )
  } else {
    grass_executable <- file.path(executable_dir, "grass")
    writeLines(
      c("#!/bin/sh", sprintf("printf '%%s\\n' %s", shQuote(grass_home))),
      grass_executable
    )
    Sys.chmod(grass_executable, mode = "0755")
  }
  withr::local_path(executable_dir, action = "prefix")

  expect_message(
    result <- search_grass(),
    "Trying to set gisBase by running command"
  )
  expect_identical(result, grass_home)
})

test_that("validate_gisbase accepts a GRASS installation layout", {
  grass_home <- tempfile("grass-installation-")
  dir.create(grass_home)
  dir.create(file.path(grass_home, "bin"))
  dir.create(file.path(grass_home, "scripts"))
  withr::defer(unlink(grass_home, recursive = TRUE))

  expect_invisible(validate_gisbase(grass_home))
})

test_that("validate_gisbase rejects invalid installation layouts", {
  missing_home <- tempfile("missing-grass-installation-")
  expect_error(validate_gisbase(missing_home), "gisBase.*not found")

  grass_file <- tempfile("grass-installation-file-")
  file.create(grass_file)
  withr::defer(unlink(grass_file))
  expect_error(validate_gisbase(grass_file), "gisBase.*not a directory")

  grass_home <- tempfile("grass-installation-")
  dir.create(grass_home)
  withr::defer(unlink(grass_home, recursive = TRUE))
  expect_error(validate_gisbase(grass_home), "does not contain bin")

  dir.create(file.path(grass_home, "bin"))
  expect_error(validate_gisbase(grass_home), "does not contain scripts")
})

test_that("grass_version reads cumulative GRASS version strings", {
  grass_home <- tempfile("grass-installation-")
  dir.create(file.path(grass_home, "etc"), recursive = TRUE)
  withr::defer(unlink(grass_home, recursive = TRUE))
  writeLines("8.4.1", file.path(grass_home, "etc", "VERSIONNUMBER"))

  expect_identical(
    grass_version(grass_home),
    list(
      major = "8",
      major_minor = "8.4",
      full = "8.4.1"
    )
  )
})

test_that("grass_version requires a version file", {
  grass_home <- tempfile("grass-installation-")
  dir.create(file.path(grass_home, "etc"), recursive = TRUE)
  withr::defer(unlink(grass_home, recursive = TRUE))

  expect_error(
    suppressWarnings(grass_version(grass_home)),
    "cannot open the connection"
  )
})
