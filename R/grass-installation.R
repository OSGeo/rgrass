#' Search for GRASS GIS installation
#'
#' @returns a character string with the path to the GRASS GIS installation
#' @keywords internal
search_grass <- function() {
  message(
    "No gisBase set. Trying to detect from the GRASS_INSTALLATION ",
    "environment variable."
  )
  grass_installation <- Sys.getenv("GRASS_INSTALLATION")
  stopifnot(is.character(grass_installation))

  if (nchar(grass_installation) > 0) {
    message(
      "Taking gisBase value from GRASS_INSTALLATION: ",
      grass_installation
    )
    gisBase <- grass_installation
  } else {
    message(
      "No GRASS_INSTALLATION environment variable was found.\n",
      "Trying to set gisBase by running command ",
      "`grass --config path` (requires grass in the system PATH)."
    )

    tryCatch({
      gisBase <-
        if (.Platform$OS.type == "windows") {
          shell("grass --config path", intern = TRUE)
        } else {
          system("grass --config path", intern = TRUE)
        }
    }, error = function(e) {
      stop(
        "grass seems to be unavailable in the system PATH.\n",
        "Either provide the gisBase argument or set a ",
        "GRASS_INSTALLATION environment variable to provide the ",
        "gisBase path",
        call. = FALSE
      )
    })

    message("Taking gisBase value from `grass --config path` output: ", gisBase)
    stopifnot(length(gisBase) == 1L)
  }

  return(gisBase)
}

#' Check that the GRASS installation directory is valid
#'
#' @param gisBase Path to the GRASS installation directory
#'
#' @returns NULL
#' @keywords internal
validate_gisbase <- function(gisBase) {
  # gisBase requires one non-missing character path
  stopifnot(
    "`gisBase` must be one path" =
      is.character(gisBase) && length(gisBase) == 1L && !is.na(gisBase)
  )

  # Check that the directory exists
  stopifnot(
    "`gisBase` not found" = file.exists(gisBase),
    "`gisBase` is not a directory" = file.info(gisBase)$isdir[1]
  )

  # Check that it contains the /bin directory with the GRASS programs
  bin_is_dir <- file.info(file.path(gisBase, "bin"))$isdir[1]
  stopifnot(
    "`gisBase` does not contain bin, the directory with GRASS programs" = !is.na(bin_is_dir),
    "`gisBase`/bin is not a directory" = bin_is_dir
  )

  # Check that it contains the /scripts directory
  scripts_is_dir <- file.info(file.path(gisBase, "scripts"))$isdir[1]
  stopifnot(
    "`gisBase` does not contain scripts, the directory with GRASS scripts" = !is.na(scripts_is_dir),
    "`gisBase`/scripts is not a directory" = scripts_is_dir
  )
  return(invisible(NULL))
}


#' Get the GRASS GIS version
#'
#' @param gisBase A character string with the path to the GRASS installation.
#'
#' @returns A list containing cumulative version strings for the major version,
#'   major-minor version, and full version.
#' @keywords internal
grass_version <- function(gisBase) {
  version_file <- file.path(gisBase, "etc", "VERSIONNUMBER")
  version <- readLines(version_file, warn = FALSE)

  list(
    major = substring(version, 1, 1),
    major_minor = substring(version, 1, 3),
    full = substring(version, 1, 5)
  )
}
