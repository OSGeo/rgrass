download_nc_basic <- function() {
  # online source
  file_url <- "nc_basic_spm_grass7.zip"
  base_url <- "https://grass.osgeo.org/sampledata"
  path_url <- "north_carolina"
  url <- paste(base_url, path_url, file_url, sep = "/")

  # local file path for download
  tmpdir <- tempdir()
  zip_path <- file.path(tmpdir, file_url)

  # extraction directory
  db_dir <- file.path(tmpdir, "grassdb")

  if (!file.exists(zip_path)) {
    result <- try({
      suppressWarnings(download.file(url, zip_path, quiet = TRUE))
    }, silent = TRUE)

    if (inherits(result, "try-error")) {
      message("Failed to download GRASS GIS example dataset")
      return(NULL)
    }

    unzip(zip_path, exdir = db_dir)
    unlink(zip_path)
  }

  return(list(gisDbase = db_dir, location = "nc_basic_spm_grass7"))
}

get_gisbase <- function() {
  if (Sys.info()["sysname"] == "Linux") {
    gisBase <- try(system2("grass", "--config path", stdout = TRUE), silent = TRUE)
  } else {
    gisBase <- Sys.getenv("GRASS_INSTALLATION")
  }

  if (inherits(gisBase, "try-error") | gisBase == "") {
    message("GRASS GIS not found on PATH")
    return(NULL)
  }
  return(gisBase)
}
