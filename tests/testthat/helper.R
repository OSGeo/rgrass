download_nc_basic <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    tmpdir <- "/tmp"
  } else if (Sys.info()["sysname"] == "Darwin") {
    tmpdir <- tempdir()
  }

  if (!file.exists(file.path(tmpdir, "nc_basic_spm_grass7.zip"))) {
    base_url <- "https://grass.osgeo.org/sampledata"
    path_url <- "north_carolina"
    file_url <- "nc_basic_spm_grass7.zip"

    download.file(
      paste(base_url, path_url, file_url, sep = "/"),
      file.path(tmpdir, "nc_basic_spm_grass7.zip")
    )

    unzip(
      file.path(tmpdir, "nc_basic_spm_grass7.zip"),
      exdir = file.path(tmpdir, "grassdb")
    )
  }

  dataset <- list(
    gisDbase = file.path(tmpdir, "grassdb"),
    location = "nc_basic_spm_grass7"
  )

  return(dataset)
}

get_gisbase <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    gisBase <- try(system2("grass", "--config path", stdout = TRUE))
  } else if (Sys.info()["sysname"] == "Darwin") {
    gisBase <- "/Applications/GRASS-8.5.app/Contents/Resources"
  }
  
  if (inherits(gisBase, "try-catch")) {
    gisBase <- NULL
  }
  
  return(gisBase)
}