# Interpreted GRASS 7, 8 raster interface functions
# Copyright (c) 2008-22 Roger S. Bivand
#
# GIS_LOCK 110814 RSB, suggested by Brian Oney

#' Initiate GRASS session
#'
#' @description
#'  Run GRASS interface in an R session not started within GRASS. In general,
#' most users will use `initGRASS` in throwaway locations, to use GRASS
#' modules  on R objects without the need to define and populate a location. The
#' function initializes environment variables used by GRASS, the .gisrc used by
#' GRASS for further environment variables, and a temporary location.
#'
#' On Windows, if OSGeo4W GRASS is being used, the R session must be started in
#' the OSGeo4W shell. If not, the non-standard placing of files and of
#' environment variables confuses the function. If `toupper(gisBase)`
#' contains "OSGEO4W64/APPS/GRASS" or "OSGEO4W/APPS/GRASS" (and
#' after converting "\\" to "/"), but the environment variable
#' `OSGEO4W_ROOT` is not defined, `initGRASS()` will exit with an
#' error before confusion leads to further errors. For further details, see
#' <https://github.com/osgeo/rgrass/issues/16> and
#' <https://github.com/osgeo/rgrass/issues/16>.
#'
#' The same restriction applies to use of GRASS with QGIS Windows standalone
#' installations, which may be used with `initGRASS` only if the R session
#' is started from the OSGeo4W shell shipped as part of the standalone installer
#' (see <https://github.com/osgeo/rgrass/issues/87>). The function will
#' exit with an error if R was not started from the QGIS OSGeo4W shell before
#' confusion leads to further errors.
#'
#' The locking functions are used internally, but are exposed for experienced
#' R/GRASS scripters needing to use the GRASS module "g.mapset" through
#' `initGRASS` in an existing GRASS location. In particular,
#' "g.mapset" may leave a `.gislock` file in the current MAPSET, so
#' it may be important to call `unlink_.gislock` to clean up before
#' quitting the R session. `remove_GISRC` may be used to try to remove the
#' file given in the "GISRC" environment variable if created by
#' `initGRASS` with argument `remove_GISRC=` TRUE.
#'
#' @details
#' The function establishes an out-of-GRASS working environment providing GRASS
#' commands with the environment variable support required, and may also provide
#' a temporary location for use until the end of the running R session if the
#' `home` argument is set to `tempdir()`, and the `gisDbase`
#' argument is not given. Running `gmeta` shows where the location is,
#' should it be desired to archive it before leaving R.
#'
#' @note
#' If any package command fails with a UTF-8 error from the XML package, try
#' using `setXMLencoding` to work around the problem that GRASS modules
#' declare --interface-description output as UTF-8 without ensuring that it is.
#'
#' @author Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>
#' @seealso [gmeta()]
#' @keywords spatial
#'
#' @param gisBase The directory path to GRASS binaries and libraries, containing
#'   bin and lib subdirectories among others; if NULL, set from environment
#'   variable GRASS_INSTALLATION if found, if not found,
#'   `system("grass --config path")` is tried.
#' @param home The directory in which to create the .gisrc file; defaults to
#'   `$HOME` on Unix systems and to `USERPROFILE` on Windows systems;
#'   can usually be set to `tempdir()`.
#' @param SG An optional `SpatRaster` or `SpatialGrid` object to
#'   define the `DEFAULT_WIND` of the temporary location.
#' @param gisDbase if missing, `tempdir()` will be used; GRASS GISDBASE
#'   directory for the working session.
#' @param addon_base if missing, assumed to be "$HOME/.grass7/addons" on
#'   Unix-like platforms, on MS Windows "\%APPDATA\%\GRASS7\addons",
#'   and checked for existence.
#' @param location if missing, `basename(tempfile())` will be used; GRASS
#'   location directory for the working session.
#' @param mapset if missing, `basename(tempfile())` will be used; GRASS
#'   mapset directory for the working session.
#' @param override default FALSE, set to TRUE if accidental trashing of GRASS
#'   .gisrc files and locations is not a problem.
#' @param use_g.dirseps.exe default TRUE; when TRUE appears to work for WinGRASS
#'   Native binaries, when FALSE for QGIS GRASS binaries; ignored on other
#'   platforms.
#' @param pid default `as.integer(round(runif(1, 1, 1000)))`, integer used
#'   to identify GIS_LOCK; the value here is arbitrary, but probably should be
#'   set correctly.
#' @param remove_GISRC default FALSE; if TRUE, attempt to unlink the temporary
#'   file named in the "GISRC" environment variable when the R session
#'   terminates or when this package is unloaded.
#' @param ignore.stderr default taking the value set by
#'   `set.ignore.stderrOption`; can be set to TRUE to silence
#'   `system()` output to standard error; does not apply on Windows
#'   platforms.
#'
#' @return The function runs `gmeta6` before returning the current values
#'   of the running GRASS session that it provides.
#' @export
#' @importFrom stats runif
#' @importFrom methods getMethod
#'
#' @examples
#' # Run only if GRASS installation is found and 'terra' package is installed
#' GRASS_INSTALLATION <- Sys.getenv("GRASS_INSTALLATION")
#' run <- nzchar(GRASS_INSTALLATION) &&
#'        file.exists(GRASS_INSTALLATION) &&
#'        file.info(GRASS_INSTALLATION)$isdir &&
#'        require(terra, quietly = TRUE)
#'
#' if (run) {
#'   # Plot the terra example dataset
#'   f <- system.file("ex/elev.tif", package="terra")
#'   r <- rast(f)
#'   plot(r, col = terrain.colors(50))
#' }
#'
#' # Check for existing GRASS session running
#' if (run) {
#'   loc_existing <- try(gmeta())
#' }
#'
#' if (run) {
#'   # Initialize a temporary GRASS project using the example data
#'   loc <- initGRASS(
#'     GRASS_INSTALLATION,
#'     home = tempdir(),
#'     SG = r,
#'     override = TRUE
#'   )
#' }
#'
#' if (run) {
#'   # Write the example data to the GRASS database
#'   write_RAST(r, "elev", flags = "overwrite")
#'   execGRASS("r.info", map = "elev")
#' }
#'
#' if (run) {
#'   # Calculate slope and aspect raster
#'   execGRASS(
#'     "r.slope.aspect",
#'     flags    = "overwrite",
#'     elevation = "elev",
#'     slope    = "slope",
#'     aspect   = "aspect"
#'   )
#' }
#'
#' if (run) {
#'   # Read the results back into R and plot
#'   u1 <- read_RAST(c("elev", "slope", "aspect"), return_format = "terra")
#'   plot(u1[["elev"]], col = terrain.colors(50))
#' }
#'
#' # Restore the original GRASS session
#' if (run) {
#'   if (!inherits(loc, "try-error")) {
#'     loc <- initGRASS(
#'       gisBase = GRASS_INSTALLATION,
#'       gisDbase = loc_existing$GISDBASE,
#'       location = loc_existing$LOCATION_NAME,
#'       mapset = loc_existing$MAPSET,
#'       override = TRUE
#'     )
#'   }
#' }
initGRASS <- function(
    gisBase = NULL, home, SG, gisDbase, addon_base, location,
    mapset, override = FALSE, use_g.dirseps.exe = TRUE, pid,
    remove_GISRC = FALSE, ignore.stderr = get.ignore.stderrOption()) {
  if (nchar(Sys.getenv("GISRC")) > 0 && !override) {
    ask_override(
      paste0(
        "A GRASS location (defined by ",
        Sys.getenv("GISRC"),
        ") is already in use"
      ),
      missing_override = missing(override),
      envir = environment()
    )
  }

  if (nchar(get.GIS_LOCK()) > 0) {
    if (!override) {
      ask_override("A GIS_LOCK environment variable is present",
                   missing_override = missing(override),
                   envir = environment()
      )
      unset.GIS_LOCK() # no error means user wants to override
    } else {
      unset.GIS_LOCK()
    }
  }

  if (missing(pid)) pid <- round(runif(1, 1, 1000))
  pid <- as.integer(pid)
  stopifnot(!is.na(pid))
  stopifnot(is.logical(override))
  stopifnot(length(override) == 1)
  stopifnot(is.logical(use_g.dirseps.exe))
  stopifnot(length(use_g.dirseps.exe) == 1)
  stopifnot(is.logical(remove_GISRC))
  stopifnot(length(remove_GISRC) == 1)

  if (is.null(gisBase)) {
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
      tryCatch(
        {
          gisBase <-
            if (.Platform$OS.type == "windows") {
              shell("grass --config path", intern = TRUE)
            } else {
              system("grass --config path", intern = TRUE)
            }
        },
        error = function(e) {
          stop("grass seems to be unavailable in the system PATH.\n",
               "Either provide the gisBase argument or set a ",
               "GRASS_INSTALLATION environment variable to provide the ",
               "gisBase path",
               call. = FALSE
          )
        }
      )
      message(
        "Taking gisBase value from `grass --config path` output: ",
        gisBase
      )
      stopifnot(length(gisBase) == 1L)
    }
  }

  if (!file.exists(gisBase)) stop(paste(gisBase, "not found"))
  if (!file.info(gisBase)$isdir[1]) stop(gisBase, " is not a directory")
  bin_is_dir <- file.info(file.path(gisBase, "bin"))$isdir[1]
  if (is.na(bin_is_dir)) {
    stop(gisBase, " does not contain bin, the directory with GRASS programs")
  }
  if (!bin_is_dir) stop(gisBase, "/bin is not a directory")
  scripts_is_dir <- file.info(file.path(gisBase, "scripts"))$isdir[1]
  if (is.na(scripts_is_dir)) {
    stop(gisBase, " does not contain scripts, the directory with GRASS scripts")
  }
  if (!scripts_is_dir) stop(gisBase, "/scripts is not a directory")



  gv <- readLines(file.path(gisBase, "etc/VERSIONNUMBER"))
  gv <- substring(gv, 1, 1)

  SYS <- get("SYS", envir = .GRASS_CACHE)
  if (SYS == "WinNat") {
    # grass63.bat
    Sys.setenv(GISBASE = gisBase)
    if (missing(home)) home <- Sys.getenv("USERPROFILE")
    Sys.setenv(HOME = home)
    if (missing(addon_base)) {
      addon_base <- paste(Sys.getenv("APPDATA"),
                          "/GRASS", gv, "/addons",
                          sep = ""
      )
    }
    addon_res <- file.exists(addon_base, paste(addon_base, "/bin", sep = ""))
    if (any(addon_res)) Sys.setenv("GRASS_ADDON_BASE" = addon_base)
    OSGEO4W_ROOT <- Sys.getenv("OSGEO4W_ROOT")
    if (nchar(OSGEO4W_ROOT) > 0) {
      Sys.setenv(GRASS_PROJSHARE = paste(OSGEO4W_ROOT,
                                         "\\share\\proj",
                                         sep = ""
      ))
    } else {
      unistring <- toupper(gisBase)
      unistring <- gsub("\\\\", "/", unistring)
      if (length(grep("OSGEO4W.*/APPS/GRASS", unistring)) > 0) {
        stop("NOTE: If using OSGeo4W GRASS, start R in the OSGeo4W shell,\nsee help(initGRASS) for further details")
      }
      if (length(grep("QGIS.*/APPS/GRASS", unistring)) > 0) {
        stop("NOTE: If using Windows standalone QGIS GRASS, start R in the QGIS standalone\nOSGeo4W shell, see help(initGRASS) for further details")
      }
      Sys.setenv(GRASS_PROJSHARE = paste(Sys.getenv("GISBASE"),
                                         "\\share\\proj",
                                         sep = ""
      ))
    }

    Wpath <- Sys.getenv("PATH")
    if (length(grep(basename(Sys.getenv("GISBASE")), Wpath)) < 1) {
      Sys.setenv(PATH = paste(Sys.getenv("GISBASE"), "\\lib;",
                              Sys.getenv("PATH"),
                              sep = ""
      ))
      Sys.setenv(PATH = paste(Sys.getenv("GISBASE"), "\\bin;",
                              Sys.getenv("PATH"),
                              sep = ""
      ))
      Sys.setenv(PATH = paste(Sys.getenv("GISBASE"), "\\extrabin;",
                              Sys.getenv("PATH"),
                              sep = ""
      ))
      if (addon_res[2]) {
        Sys.setenv(PATH = paste(Sys.getenv(
          "GRASS_ADDON_BASE"
        ), "\\bin;", Sys.getenv("PATH"), sep = ""))
      }
      # etc/Init.bat
      #            GRASS_addons <- Sys.getenv("GRASS_ADDON_PATH")
      #            if (GRASS_addons == "")
      #                Sys.setenv(PATH=paste(Sys.getenv("WINGISBASE"), "\\bin;",
      #                    Sys.getenv("WINGISBASE"), "\\lib;",
      #                    Sys.getenv("PATH"), sep=""))
      #            else
      #                Sys.setenv(PATH=paste(Sys.getenv("WINGISBASE"), "\\bin;",
      #                    Sys.getenv("WINGISBASE"), "\\lib;",
      #                    GRASS_addons, ";", Sys.getenv("PATH"), sep=""))
      ePyPATH <- Sys.getenv("PYTHONPATH")
      if ((length(grep(basename(Sys.getenv("GISBASE")), ePyPATH)) < 1) ||
          nchar(ePyPATH) == 0) {
        GrPyPATH <- paste(Sys.getenv("GISBASE"), "/etc/python",
                          sep = ""
        )
        if (nchar(ePyPATH) > 0) {
          Sys.setenv(PYTHONPATH = paste(GrPyPATH, ePyPATH, sep = ";"))
        } else {
          Sys.setenv(PYTHONPATH = GrPyPATH)
        }
      }
      if (nchar(OSGEO4W_ROOT) > 0) {
        Sys.setenv("PYTHONHOME" = paste(OSGEO4W_ROOT, "apps/Python37", sep = "/"))
      } else {
        G_B_files <- list.files(Sys.getenv("GISBASE"))
        Python_dir <- G_B_files[grep("Python", G_B_files)]
        if (length(Python_dir) > 0) Sys.setenv("PYTHONHOME" = paste(Sys.getenv("GISBASE"), Python_dir[1], sep = "/"))
      }
      #            pyScripts <- basename(list.files(paste(Sys.getenv("GISBASE"),
      #                "scripts", sep="/"), pattern="py$"))
      #            names(pyScripts) <- sub("\\.py", "", pyScripts)
      #            assign("pyScripts", pyScripts, envir=.GRASS_CACHE)
    }
    Sys.setenv(GISRC = paste(Sys.getenv("HOME"), "\\.grassrc", gv, sep = ""))
    if (file.exists(Sys.getenv("GISRC")) && !override) {
      ask_override(paste("A GISRC file", Sys.getenv("GISRC"), "already exists"),
                   missing_override = missing(override),
                   envir = environment()
      )
    }
    fn_gisrc <- "junk"
    if (isTRUE(file.access(".", 2) == 0)) {
      Sys.setenv(GISRC = fn_gisrc)
    } else {
      warning("working directory not writable, using tempfile for GISRC")
      Sys.setenv(GISRC = paste0(tempfile(), "_", fn_gisrc))
    }
    cat("GISDBASE:", getwd(), "\n", file = Sys.getenv("GISRC"))
    cat("LOCATION_NAME: <UNKNOWN>", "\n",
        file = Sys.getenv("GISRC"),
        append = TRUE
    )
    cat("MAPSET: <UNKNOWN>", "\n",
        file = Sys.getenv("GISRC"),
        append = TRUE
    )
    gisrc <- ifelse(use_g.dirseps.exe, system(paste(
      "g.dirseps.exe -g",
      shQuote(Sys.getenv("GISRC"))
    ), intern = TRUE),
    Sys.getenv("GISRC")
    )
    assign("addEXE", .addexe(), envir = .GRASS_CACHE)
    Sys.setenv(GISRC = gisrc)
    if (!missing(gisDbase)) {
      if (!file.exists(gisDbase)) dir.create(gisDbase)
    } else {
      gisDbase <- tempdir()
    }
    gisDbase <- ifelse(use_g.dirseps.exe, system(paste(
      "g.dirseps.exe -g",
      shQuote(gisDbase)
    ), intern = TRUE), gisDbase)
  } else if (SYS == "unix") {
    OSGEO4W_ROOT <- ""
    Sys.setenv(GISBASE = gisBase)
    if (missing(home)) home <- Sys.getenv("HOME")
    if (missing(addon_base)) {
      addon_base <- paste(Sys.getenv("HOME"), "/.grass", gv, "/addons", sep = "")
    }
    addon_res <- file.exists(
      addon_base, paste(addon_base, "/bin", sep = ""),
      paste(addon_base, "/scripts", sep = "")
    )
    if (any(addon_res)) Sys.setenv("GRASS_ADDON_BASE" = addon_base)
    ePATH <- Sys.getenv("PATH")
    if (length(grep(basename(Sys.getenv("GISBASE")), ePATH)) < 1) {
      Sys.setenv(PATH = paste(Sys.getenv("GISBASE"), "/bin:",
                              Sys.getenv("GISBASE"), "/scripts",
                              ifelse(addon_res[2],
                                     paste(":", Sys.getenv("GRASS_ADDON_BASE"), "/bin", sep = ""), ""
                              ),
                              ifelse(addon_res[3],
                                     paste(":", Sys.getenv("GRASS_ADDON_BASE"), "/scripts", sep = ""),
                                     ""
                              ),
                              ifelse(nchar(ePATH) == 0, "", ":"), ePATH,
                              sep = ""
      ))
    }
    eLDPATH <- Sys.getenv("LD_LIBRARY_PATH")
    if (length(grep(basename(Sys.getenv("GISBASE")), eLDPATH)) < 1) {
      Sys.setenv(LD_LIBRARY_PATH = paste(Sys.getenv("GISBASE"), "/lib:",
                                         ifelse(nchar(eLDPATH) == 0, "", ":"), eLDPATH,
                                         sep = ""
      ))
    }
    # FIXME Sys.info()["sysname"] == "Darwin"
    Sys.setenv(GISRC = paste(home, "/.grassrc", gv, sep = ""))
    # FIXME
    if (file.exists(Sys.getenv("GISRC")) && !override) {
      ask_override(paste("A GISRC file", Sys.getenv("GISRC"), "already exists"),
                   missing_override = missing(override),
                   envir = environment()
      )
    }
    ePyPATH <- Sys.getenv("PYTHONPATH")
    if (length(grep(basename(Sys.getenv("GISBASE")), ePyPATH)) < 1 ||
        nchar(ePyPATH) == 0) {
      GrPyPATH <- paste(Sys.getenv("GISBASE"), "etc", "python", sep = "/")
      if (nchar(ePyPATH) > 0) {
        Sys.setenv(PYTHONPATH = paste(GrPyPATH, ePyPATH, sep = ":"))
      } else {
        Sys.setenv(PYTHONPATH = GrPyPATH)
      }
    }
    if (!missing(gisDbase)) {
      if (!file.exists(gisDbase)) dir.create(gisDbase)
    } else {
      gisDbase <- tempdir()
    }
    cat("GISDBASE:", gisDbase, "\n", file = Sys.getenv("GISRC"))
    cat("LOCATION_NAME: <UNKNOWN>", "\n",
        file = Sys.getenv("GISRC"),
        append = TRUE
    )
    cat("MAPSET: <UNKNOWN>", "\n",
        file = Sys.getenv("GISRC"),
        append = TRUE
    )
  } else {
    stop(paste("Platform variant", SYS, "not supported"))
  }
  set.GIS_LOCK(pid)
  assign("INIT_USED", TRUE, envir = .GRASS_CACHE)
  assign("GIS_LOCK", pid, envir = .GRASS_CACHE)
  if (remove_GISRC) assign("remove_GISRC", remove_GISRC, envir = .GRASS_CACHE)
  system(paste(
    paste("g.gisenv", get("addEXE", envir = .GRASS_CACHE), sep = ""),
    shQuote(paste("set=GISDBASE=", gisDbase))
  ))
  if (missing(location)) location <- basename(tempfile())
  loc_path <- paste(gisDbase, location, sep = "/")
  if (!file.exists(loc_path)) dir.create(loc_path)
  if (!file.exists(paste(loc_path, "PERMANENT", sep = "/"))) {
    dir.create(paste(loc_path, "PERMANENT", sep = "/"))
  }
  if (missing(mapset)) mapset <- basename(tempfile())
  if (!file.exists(paste(loc_path, mapset, sep = "/"))) {
    dir.create(paste(loc_path, mapset, sep = "/"))
  }
  system(paste(
    paste("g.gisenv", get("addEXE", envir = .GRASS_CACHE), sep = ""),
    shQuote(paste("set=GISDBASE", gisDbase, sep = "="))
  ))
  system(paste(
    paste("g.gisenv", get("addEXE", envir = .GRASS_CACHE), sep = ""),
    shQuote(paste("set=LOCATION_NAME", location, sep = "="))
  ))
  system(paste(
    paste("g.gisenv", get("addEXE", envir = .GRASS_CACHE), sep = ""),
    shQuote(paste("set=MAPSET", mapset, sep = "="))
  ))
  system(paste(
    paste("g.gisenv", get("addEXE", envir = .GRASS_CACHE), sep = ""),
    shQuote("set=GRASS_GUI=text")
  ))
  Sys.setenv(GISBASE = gisBase)
  Sys.setenv(GISDBASE = gisDbase)
  Sys.setenv(LOCATION_NAME = location)
  Sys.setenv(MAPSET = mapset)
  gv <- system(paste("g.version", get("addEXE", envir = .GRASS_CACHE),
                     sep = ""
  ), intern = TRUE)


  comp <- .compatibleGRASSVersion(gv)
  if (!comp) {
    stop(attr(comp, "message"))
  }
  grass_python <- Sys.getenv("GRASS_PYTHON")
  if (grass_python == "") {
    if (nchar(OSGEO4W_ROOT) > 0) {
      if (file.exists(paste(OSGEO4W_ROOT, "bin/python3.exe", sep = "/"))) {
        Sys.setenv("GRASS_PYTHON" = paste(OSGEO4W_ROOT, "bin/python3.exe", sep = "/"))
      } else {
        Sys.setenv("GRASS_PYTHON" = paste(OSGEO4W_ROOT, "bin/python.exe", sep = "/"))
      }
    } else {
      if (strsplit(system(paste("g.version", get("addEXE", envir = .GRASS_CACHE), " -g ", sep = ""), intern = TRUE)[1], "=")[[1]][2] > "7.6.1") {
        Sys.setenv("GRASS_PYTHON" = paste("python3", get("addEXE",
                                                         envir = .GRASS_CACHE
        ), sep = ""))
      } else {
        Sys.setenv("GRASS_PYTHON" = paste("python", get("addEXE",
                                                        envir = .GRASS_CACHE
        ), sep = ""))
      }
    }
  }

  assign("GV", gv, envir = .GRASS_CACHE)
  pfile <- paste(loc_path, "PERMANENT", "DEFAULT_WIND", sep = "/")
  mSG <- FALSE
  if (!file.exists(pfile)) {
    lonlat <- FALSE
    mSG <- !missing(SG)
    if (mSG) {
      if (inherits(SG, "SpatialGrid")) {
        if (!requireNamespace("sp", quietly = TRUE)) {
          stop("The sp package is required for the SG argument")
        }
        bb <- sp::bbox(SG)
        gt <- sp::gridparameters(SG)
        wkt_SG <- sp::wkt(SG)
        lonlatSG <- !sp::is.projected(SG)
      } else if (inherits(SG, "SpatRaster")) {
        if (!requireNamespace("terra", quietly = TRUE)) {
          stop("The terra package is required for the SG argument")
        }
        bb <- getMethod("ext", "SpatRaster")(SG)
        bb <- as.vector(bb)
        bb <- matrix(bb, 2, 2, byrow = TRUE)
        colnames(bb) <- c("min", "max")
        cs <- getMethod("res", "SpatRaster")(SG)
        co <- bb[, 1] + (cs / 2)
        cd <- c(
          getMethod("ncol", "SpatRaster")(SG),
          getMethod("nrow", "SpatRaster")(SG)
        )
        gt <- data.frame(
          cellcentre.offset = co, cellsize = cs,
          cells.dim = cd
        )
        wkt_SG <- getMethod("crs", "SpatRaster")(SG)
        lonlatSG <- getMethod("is.lonlat", "SpatRaster")(SG)
      } else {
        stop("SG must be a SpatRaster or SpatialGrid object")
      }
      lonlat <- !is.na(lonlatSG) && lonlatSG
    }
    cat("proj:       ", ifelse(lonlat, 3, 99), "\n", file = pfile)
    cat("zone:       0\n", file = pfile, append = TRUE)
    cat("north:      ", ifelse(mSG, bb[2, "max"], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("south:      ", ifelse(mSG, bb[2, "min"], 0), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("east:       ", ifelse(mSG, bb[1, "max"], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("west:       ", ifelse(mSG, bb[1, "min"], 0), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("cols:       ", ifelse(mSG, gt$cells.dim[1], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("rows:       ", ifelse(mSG, gt$cells.dim[2], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("e-w resol:  ", ifelse(mSG, gt$cellsize[1], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("n-s resol:  ", ifelse(mSG, gt$cellsize[2], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("top:        1\n", sep = "", file = pfile, append = TRUE)
    cat("bottom:     0\n", sep = "", file = pfile, append = TRUE)
    cat("cols3:      ", ifelse(mSG, gt$cells.dim[1], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("rows3:      ", ifelse(mSG, gt$cells.dim[2], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("depths:     1\n", sep = "", file = pfile, append = TRUE)
    cat("e-w resol3: ", ifelse(mSG, gt$cellsize[1], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("n-s resol3: ", ifelse(mSG, gt$cellsize[2], 1), "\n",
        sep = "", file = pfile, append = TRUE
    )
    cat("t-b resol:  1\n", sep = "", file = pfile, append = TRUE)
  }

  tfile <- paste(loc_path, "PERMANENT", "WIND", sep = "/")
  if (!file.exists(tfile)) file.copy(pfile, tfile, overwrite = TRUE)
  tfile <- paste(loc_path, mapset, "WIND", sep = "/")
  if (!file.exists(tfile)) file.copy(pfile, tfile, overwrite = TRUE)
  execGRASS("g.region",
            save = "input", flags = "overwrite",
            ignore.stderr = ignore.stderr
  )
  if (mSG) {
    if (nzchar(wkt_SG)) {
      tf <- tempfile()
      writeLines(wkt_SG, con = tf)
      MS <- execGRASS("g.mapset",
                      flags = "p", intern = TRUE,
                      ignore.stderr = ignore.stderr
      )
      if (MS != "PERMANENT") {
        execGRASS("g.mapset",
                  mapset = "PERMANENT", flags = "quiet",
                  ignore.stderr = ignore.stderr
        )
      }
      tull <- execGRASS("g.proj",
                        flags = "c", wkt = tf,
                        ignore.stderr = ignore.stderr, intern = TRUE
      )
      execGRASS("g.region",
                flags = "s", region = paste0("input@", mapset),
                ignore.stderr = ignore.stderr
      )
      execGRASS("g.region", flags = "d", ignore.stderr = ignore.stderr)
      if (MS != "PERMANENT") {
        execGRASS("g.mapset",
                  mapset = mapset, flags = "quiet",
                  ignore.stderr = ignore.stderr
        )
      }
    }
  }
  gmeta(ignore.stderr = ignore.stderr)
}

#' @rdname initGRASS
#' @export
get.GIS_LOCK <- function() {
  Sys.getenv("GIS_LOCK")
}

#' @rdname initGRASS
#' @export
set.GIS_LOCK <- function(pid) {
  if (missing(pid)) pid <- round(runif(1, 1, 1000))
  pid <- as.integer(pid)
  stopifnot(!is.na(pid))
  Sys.setenv(GIS_LOCK = pid)
}

#' @rdname initGRASS
#' @export
unset.GIS_LOCK <- function() {
  Sys.unsetenv("GIS_LOCK")
}

#' @rdname initGRASS
#' @export
unlink_.gislock <- function() {
  gl <- paste(Sys.getenv("GISDBASE"), Sys.getenv("LOCATION_NAME"),
    Sys.getenv("MAPSET"), ".gislock",
    sep = "/"
  )
  if (file.exists(gl)) unlink(gl)
}

ask_override <- function(msg, missing_override, envir) {
  if (interactive() && missing_override) {
    message(msg, ".")
    a <- ""
    while (!grepl("^[Yy]([Ee][Ss])?$|^[Nn]([Oo])?$", a)) {
      a <- readline("Do you want to override ('no' will abort)? (y/n) ")
    }
    if (grepl("^[Yy]", a)) {
      assign("override", TRUE, envir = envir)
      message("Overriding. Avoid this question by setting override = TRUE")
    } else {
      stop("Aborting. To override, set override = TRUE", call. = FALSE)
    }
  } else {
    stop(msg, "; to override, set override = TRUE", call. = FALSE)
  }
}

#' @rdname initGRASS
#' @export
remove_GISRC <- function() {
  if (get("INIT_USED", envir = .GRASS_CACHE) &&
    get("remove_GISRC", envir = .GRASS_CACHE)) {
    gisrc <- Sys.getenv("GISRC")
    if (file.exists(gisrc)) unlink(gisrc)
    Sys.unsetenv("GISRC")
  }
}
