.GRASS_CACHE <- new.env(FALSE, parent = globalenv())

.onLoad <- function(lib, pkg) {
  # `initGRASS()` sets this for sessions created from R. When R is started
  # inside an existing GRASS session, however, `initGRASS()` is not called.
  # Ensure command output/error files still use R's session temporary
  # directory instead of `tempfile(tmpdir = "")`, which resolves at the
  # filesystem root on Unix.
  if (!nzchar(Sys.getenv("RGRASS_TEMPDIR"))) {
    Sys.setenv(RGRASS_TEMPDIR = base::tempdir())
  }

  # backup original environment variables
  assign(
    ".GRASS_old.GRASS_PAGER",
    Sys.getenv("GRASS_PAGER"),
    envir = .GRASS_CACHE
  )

  assign(
    ".GRASS_old.GRASS_MESSAGE_FORMAT",
    Sys.getenv("GRASS_MESSAGE_FORMAT"),
    envir = .GRASS_CACHE
  )

  Sys.setenv("GRASS_PAGER" = "cat")
  Sys.setenv("GRASS_MESSAGE_FORMAT" = "text")

  # set up the GRASS_CACHE environment
  assign("INIT_USED", FALSE, envir = .GRASS_CACHE)
  assign("remove_GISRC", FALSE, envir = .GRASS_CACHE)
  assign("cmdCACHE", list(), envir = .GRASS_CACHE)
  assign("override_encoding", "", envir = .GRASS_CACHE)

  # add platform type to .GRASS_CACHE
  if (.Platform$OS.type == "windows") {
    platform <- "WinNat"
  } else if (.Platform$OS.type == "unix") {
    platform <- "unix"
  } else {
    platform <- "unknown"
  }
  assign("SYS", platform, envir = .GRASS_CACHE)

  # store the platform-specific executable extension
  res <- ifelse(platform == "WinNat", "exe", "")
  assign("addEXE", res, envir = .GRASS_CACHE)
  assign("WN_bat", "", envir = .GRASS_CACHE)

  # set up other GRASS_CACHE environment variables
  assign("ignore.stderr", FALSE, envir = .GRASS_CACHE)
  assign("stop_on_no_flags_paras", TRUE, envir = .GRASS_CACHE)
  assign("echoCmd", FALSE, envir = .GRASS_CACHE)
  assign("GV", "", envir = .GRASS_CACHE)
  assign("useIntern", FALSE, envir = .GRASS_CACHE)
  assign("legacyExec", .Platform$OS.type == "windows", envir = .GRASS_CACHE)
  assign("defaultFlags", NULL, envir = .GRASS_CACHE)
  assign("suppressEchoCmdInFunc", TRUE, envir = .GRASS_CACHE)
  assign("R_interface", NULL, envir = .GRASS_CACHE)
}

.onAttach <- function(lib, pkg) {
  # display the GRASS version and location when the package is attached
  gisrc <- Sys.getenv("GISRC")
  loc <- Sys.getenv("LOCATION_NAME")

  if (nchar(gisrc) == 0) {
    gv <- "(GRASS not running)"
  } else {
    gv <- .grassVersion()
    comp <- .compatibleGRASSVersion(gv)

    if (!is.na(comp) && !comp) {
      stop(attr(comp, "message"))
    }

    assign("GV", gv, envir = .GRASS_CACHE)
    if (nchar(loc) == 0) {
      loc <- read.dcf(gisrc)[1, "LOCATION_NAME"]
    }
  }

  startup_message <- paste0(
    "GRASS GIS interface loaded ",
    "with GRASS version: ", gv, "\n",
    ifelse(nchar(loc) == 0, "", paste0("and location: ", loc, "\n"))
  )
  packageStartupMessage(startup_message, appendLF = FALSE)
}

.onUnload <- function(lib, pkg) {
  # unset the GISRC environment variable and remove gisrc file
  if (get("INIT_USED", envir = .GRASS_CACHE)) {
    if (get("remove_GISRC", envir = .GRASS_CACHE)) {
      gisrc <- Sys.getenv("GISRC")
      if (file.exists(gisrc)) unlink(gisrc)
      Sys.unsetenv("GISRC")
    }
    unlink_.gislock()
    unset.GIS_LOCK()
  }

  # restore original environment variables
  Sys.setenv(
    "GRASS_PAGER" = get(".GRASS_old.GRASS_PAGER", envir = .GRASS_CACHE)
  )

  Sys.setenv(
    "GRASS_MESSAGE_FORMAT" =
      get(".GRASS_old.GRASS_MESSAGE_FORMAT", envir = .GRASS_CACHE)
  )

  rm(.GRASS_CACHE)
}
