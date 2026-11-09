test_that("package load configures a temporary directory for existing sessions", {
  withr::local_envvar(
    RGRASS_TEMPDIR = NA,
    GRASS_PAGER = NA,
    GRASS_MESSAGE_FORMAT = NA
  )

  .onLoad("", "rgrass")

  expect_identical(Sys.getenv("RGRASS_TEMPDIR"), base::tempdir())
  expect_true(dir.exists(Sys.getenv("RGRASS_TEMPDIR")))

  output_file <- tempfile(tmpdir = Sys.getenv("RGRASS_TEMPDIR"))
  withr::defer(unlink(output_file))
  expect_silent(writeLines("output", output_file))
})

test_that("package load preserves an explicitly configured temporary directory", {
  configured_tempdir <- tempfile("rgrass-tempdir-")
  dir.create(configured_tempdir)
  withr::defer(unlink(configured_tempdir, recursive = TRUE))
  withr::local_envvar(
    RGRASS_TEMPDIR = configured_tempdir,
    GRASS_PAGER = NA,
    GRASS_MESSAGE_FORMAT = NA
  )

  .onLoad("", "rgrass")

  expect_identical(Sys.getenv("RGRASS_TEMPDIR"), configured_tempdir)
})
