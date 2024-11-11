download_nc_basic <- function() {
  if (!file.exists("/tmp/nc_basic_spm_grass7.zip")) {
    download.file(
      "https://grass.osgeo.org/sampledata/north_carolina/nc_basic_spm_grass7.zip",
      "/tmp/nc_basic_spm_grass7.zip"
    )
    unzip("/tmp/nc_basic_spm_grass7.zip", exdir = "/tmp/grassdb/nc_basic_spm_grass7")
  }

  return(
    list(gisDbase = "/tmp/grassdb/nc_basic_spm_grass7", location = "nc_basic_spm_grass7")
  )
}
