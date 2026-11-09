test_that("set_path_variable sets an empty environment variable", {
  # Use a disposable variable so the test does not modify the real PATH.
  variable <- "RGRASS_TEST_PATH"
  # An NA value tells withr to temporarily unset the variable.
  withr::local_envvar(RGRASS_TEST_PATH = NA)

  # The first path becomes the entire value of an empty variable.
  expect_identical(
    set_path_variable(variable, "/opt/grass/bin"),
    invisible("/opt/grass/bin")
  )
  expect_identical(Sys.getenv(variable), "/opt/grass/bin")
})

test_that("set_path_variable prepends to an existing path list", {
  variable <- "RGRASS_TEST_PATH"
  # Use the platform separator (`:` on Unix and `;` on Windows) so this test
  # exercises the same path-list format used by the host operating system.
  existing <- paste(c("/usr/local/bin", "/usr/bin"), collapse = .Platform$path.sep)
  expected <- paste(c("/opt/grass/bin", existing), collapse = .Platform$path.sep)
  withr::local_envvar(RGRASS_TEST_PATH = existing)

  # GRASS paths take precedence by being inserted before existing paths.
  expect_identical(
    set_path_variable(variable, "/opt/grass/bin"),
    invisible(expected)
  )
  expect_identical(Sys.getenv(variable), expected)
})

test_that("set_path_variable does not duplicate an existing path", {
  variable <- "RGRASS_TEST_PATH"
  existing <- paste(c("/opt/grass/bin", "/usr/bin"), collapse = .Platform$path.sep)
  withr::local_envvar(RGRASS_TEST_PATH = existing)

  # Repeated initialization must not make path variables grow indefinitely.
  expect_identical(
    set_path_variable(variable, "/opt/grass/bin"),
    invisible(existing)
  )
  expect_identical(Sys.getenv(variable), existing)
})

test_that("set_path_variable compares complete path entries", {
  variable <- "RGRASS_TEST_PATH"
  existing <- "/opt/grass-old/bin"
  expected <- paste(c("/opt/grass/bin", existing), collapse = .Platform$path.sep)
  withr::local_envvar(RGRASS_TEST_PATH = existing)

  # This guards against the previous substring/regular-expression approach:
  # similarly named directories are distinct entries and both must be retained.
  expect_identical(
    set_path_variable(variable, "/opt/grass/bin"),
    invisible(expected)
  )
  expect_identical(Sys.getenv(variable), expected)
})

test_that("set_addons_path configures a custom add-on directory", {
  addon_base <- tempfile("grass-addons-")
  dir.create(addon_base)
  dir.create(file.path(addon_base, "bin"))
  dir.create(file.path(addon_base, "scripts"))
  withr::defer(unlink(addon_base, recursive = TRUE))
  withr::local_envvar(
    GRASS_ADDON_BASE = NA,
    PATH = "/usr/bin"
  )

  expect_identical(
    set_addons_path(addon_base, gv = list(major = "8", major_minor = "8.4")),
    invisible(addon_base)
  )
  expect_identical(Sys.getenv("GRASS_ADDON_BASE"), addon_base)

  expected_path <- paste(
    c(file.path(addon_base, "bin"), file.path(addon_base, "scripts"), "/usr/bin"),
    collapse = .Platform$path.sep
  )
  expect_identical(Sys.getenv("PATH"), expected_path)
})

test_that("set_addons_path adds only an existing bin directory", {
  addon_base <- tempfile("grass-addons-")
  dir.create(file.path(addon_base, "bin"), recursive = TRUE)
  withr::defer(unlink(addon_base, recursive = TRUE))
  withr::local_envvar(
    GRASS_ADDON_BASE = NA,
    PATH = "/usr/bin"
  )

  set_addons_path(addon_base, gv = list(major = "8", major_minor = "8.4"))

  expected_path <- paste(
    c(file.path(addon_base, "bin"), "/usr/bin"),
    collapse = .Platform$path.sep
  )
  expect_identical(Sys.getenv("PATH"), expected_path)
  expect_false(file.path(addon_base, "scripts") %in% strsplit(
    Sys.getenv("PATH"), .Platform$path.sep, fixed = TRUE
  )[[1]])
})

test_that("set_addons_path adds only an existing scripts directory", {
  addon_base <- tempfile("grass-addons-")
  dir.create(file.path(addon_base, "scripts"), recursive = TRUE)
  withr::defer(unlink(addon_base, recursive = TRUE))
  withr::local_envvar(
    GRASS_ADDON_BASE = NA,
    PATH = "/usr/bin"
  )

  set_addons_path(addon_base, gv = list(major = "8", major_minor = "8.4"))

  expected_path <- paste(
    c(file.path(addon_base, "scripts"), "/usr/bin"),
    collapse = .Platform$path.sep
  )
  expect_identical(Sys.getenv("PATH"), expected_path)
  expect_false(file.path(addon_base, "bin") %in% strsplit(
    Sys.getenv("PATH"), .Platform$path.sep, fixed = TRUE
  )[[1]])
})

test_that("set_addons_path ignores a missing add-on directory", {
  addon_base <- tempfile("missing-grass-addons-")
  withr::local_envvar(
    GRASS_ADDON_BASE = NA,
    PATH = "/usr/bin"
  )

  expect_null(
    set_addons_path(addon_base, gv = list(major = "8", major_minor = "8.4"))
  )
  expect_identical(Sys.getenv("GRASS_ADDON_BASE"), "")
  expect_identical(Sys.getenv("PATH"), "/usr/bin")
})

test_that("set_addons_path does not duplicate existing PATH entries", {
  addon_base <- tempfile("grass-addons-")
  bin_path <- file.path(addon_base, "bin")
  scripts_path <- file.path(addon_base, "scripts")
  dir.create(bin_path, recursive = TRUE)
  dir.create(scripts_path)
  withr::defer(unlink(addon_base, recursive = TRUE))

  existing_path <- paste(
    c(scripts_path, bin_path, "/usr/bin"),
    collapse = .Platform$path.sep
  )
  withr::local_envvar(
    GRASS_ADDON_BASE = NA,
    PATH = existing_path
  )

  set_addons_path(addon_base, gv = list(major = "8", major_minor = "8.4"))

  expect_identical(Sys.getenv("PATH"), existing_path)
})

test_that("setup_runtime_env_unix configures GRASS runtime paths", {
  gisBase <- tempfile("grass-installation-")
  addon_base <- tempfile("grass-addons-")
  dir.create(file.path(addon_base, "bin"), recursive = TRUE)
  dir.create(file.path(addon_base, "scripts"))
  withr::defer(unlink(addon_base, recursive = TRUE))
  withr::local_envvar(
    GISBASE = NA,
    GRASS_ADDON_BASE = NA,
    PATH = "/usr/bin",
    LD_LIBRARY_PATH = "/usr/lib",
    PYTHONPATH = "/usr/lib/python"
  )

  expect_invisible(
    setup_runtime_env_unix(
      gisBase = gisBase,
      addon_base = addon_base,
      gv = list(major = "8", major_minor = "8.4")
    )
  )

  expected_path <- paste(
    c(
      file.path(gisBase, "bin"),
      file.path(gisBase, "scripts"),
      file.path(addon_base, "bin"),
      file.path(addon_base, "scripts"),
      "/usr/bin"
    ),
    collapse = .Platform$path.sep
  )

  expect_identical(Sys.getenv("GISBASE"), gisBase)
  expect_identical(Sys.getenv("GRASS_ADDON_BASE"), addon_base)
  expect_identical(Sys.getenv("PATH"), expected_path)
  expect_identical(
    Sys.getenv("LD_LIBRARY_PATH"),
    paste(c(file.path(gisBase, "lib"), "/usr/lib"), collapse = .Platform$path.sep)
  )
  expect_identical(
    Sys.getenv("PYTHONPATH"),
    paste(
      c(file.path(gisBase, "etc", "python"), "/usr/lib/python"),
      collapse = .Platform$path.sep
    )
  )
})

test_that("setup_runtime_env_windows configures an OSGeo4W environment", {
  gisBase <- tempfile("grass-installation-")
  addon_base <- tempfile("grass-addons-")
  osgeo_root <- tempfile("osgeo4w-")
  dir.create(file.path(addon_base, "bin"), recursive = TRUE)
  dir.create(file.path(addon_base, "scripts"))
  dir.create(file.path(osgeo_root, "apps", "Python39"), recursive = TRUE)
  dir.create(file.path(osgeo_root, "apps", "Python312"), recursive = TRUE)
  withr::defer(unlink(addon_base, recursive = TRUE))
  withr::local_envvar(
    GISBASE = NA,
    GRASS_ADDON_BASE = NA,
    GRASS_PROJSHARE = NA,
    OSGEO4W_ROOT = osgeo_root,
    PATH = "/usr/bin",
    PYTHONPATH = "/usr/lib/python",
    PYTHONHOME = NA
  )

  expect_identical(
    setup_runtime_env_windows(
      gisBase = gisBase,
      addon_base = addon_base,
      gv = list(major = "8", major_minor = "8.4")
    ),
    osgeo_root
  )

  expected_path <- paste(
    c(
      file.path(gisBase, "extrabin"),
      file.path(gisBase, "bin"),
      file.path(gisBase, "lib"),
      file.path(addon_base, "bin"),
      file.path(addon_base, "scripts"),
      "/usr/bin"
    ),
    collapse = .Platform$path.sep
  )

  expect_identical(Sys.getenv("GISBASE"), gisBase)
  expect_identical(Sys.getenv("GRASS_ADDON_BASE"), addon_base)
  expect_identical(Sys.getenv("PATH"), expected_path)
  expect_identical(
    Sys.getenv("PYTHONPATH"),
    paste(
      c(file.path(gisBase, "etc", "python"), "/usr/lib/python"),
      collapse = .Platform$path.sep
    )
  )
  expect_identical(
    Sys.getenv("GRASS_PROJSHARE"),
    file.path(osgeo_root, "share", "proj")
  )
  expect_identical(
    Sys.getenv("PYTHONHOME"),
    file.path(osgeo_root, "apps", "Python312")
  )
})

test_that("setup_runtime_env_windows preserves OSGeo4W PYTHONHOME", {
  gisBase <- tempfile("grass-installation-")
  osgeo_root <- tempfile("osgeo4w-")
  python_home <- file.path(osgeo_root, "apps", "Python313")
  dir.create(python_home, recursive = TRUE)
  withr::defer(unlink(osgeo_root, recursive = TRUE))
  withr::local_envvar(
    OSGEO4W_ROOT = osgeo_root,
    PYTHONHOME = python_home,
    PATH = "/usr/bin",
    PYTHONPATH = NA,
    GRASS_PROJSHARE = NA
  )

  setup_runtime_env_windows(
    gisBase = gisBase,
    addon_base = tempfile("missing-grass-addons-"),
    gv = list(major = "8", major_minor = "8.4")
  )

  expect_identical(Sys.getenv("PYTHONHOME"), python_home)
})

test_that("setup_runtime_env_windows detects bundled Python", {
  gisBase <- tempfile("grass-installation-")
  dir.create(file.path(gisBase, "Python39"), recursive = TRUE)
  withr::defer(unlink(gisBase, recursive = TRUE))
  withr::local_envvar(
    OSGEO4W_ROOT = NA,
    PATH = "/usr/bin",
    PYTHONPATH = NA,
    PYTHONHOME = NA,
    GRASS_PROJSHARE = NA
  )

  setup_runtime_env_windows(
    gisBase = gisBase,
    addon_base = tempfile("missing-grass-addons-"),
    gv = list(major = "8", major_minor = "8.4")
  )

  expect_identical(
    Sys.getenv("GRASS_PROJSHARE"),
    file.path(gisBase, "share", "proj")
  )
  expect_identical(
    Sys.getenv("PYTHONHOME"),
    file.path(gisBase, "Python39")
  )
})

test_that("setup_runtime_env_windows rejects OSGeo4W paths outside its shell", {
  withr::local_envvar(OSGEO4W_ROOT = NA)

  expect_error(
    setup_runtime_env_windows(
      gisBase = "C:/OSGeo4W/apps/grass",
      addon_base = tempfile("missing-grass-addons-"),
      gv = list(major = "8", major_minor = "8.4")
    ),
    "start R in the OSGeo4W shell"
  )
})
