library(testthat)
source("helper.R")

testthat::test_that("testing initGRASS", {
  testdata <- download_nc_basic()

  # Initialize a temporary GRASS project using the example data
  loc <- initGRASS(
    home = tempdir(),
    gisDbase = testdata$gisDbase,
    location = testdata$location,
    mapset = "PERMANENT",
    override = TRUE
  )

  expect_s3_class(loc, "gmeta")
  expect_equal(loc$LOCATION_NAME, testdata$location)
  expect_equal(loc$projection, "99")
})
