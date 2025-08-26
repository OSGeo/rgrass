# Interpreted GRASS raster interface functions
# Copyright (c) 2022 Roger S. Bivand
#

#' Read and write GRASS raster files
#'
#' Read GRASS raster files from GRASS into R [`terra::SpatRaster`] or
#' [`sp::SpatialGridDataFrame`] objects, and write single columns of
#' [`terra::SpatRaster`] or [`sp::SpatialGridDataFrame`]
#' objects to GRASS. When `return_format="terra"`, temporary binary files
#' and r.out.bin and r.in.bin are used for speed reasons. `read_RAST()` and
#' `write_RAST()` by default use "RRASTER" files written and read by
#' GDAL.
#'
#' @author Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>
#' @keywords spatial
#'
#' @param vname A vector of GRASS raster file names in mapsets in the current
#'   search path, as set by "g.mapsets"; the file names may be given as
#'   fully-qualified map names using "name@mapset", in which case only
#'   the mapset given in the full path will be searched for the existence of the
#'   raster; if more than one raster with the same name is found in mapsets in
#'   the current search path, an error will occur, in which case the user should
#'   give the fully-qualified map name. If the fully-qualified name is used,
#'   `@` will be replaced by underscore in the output object.
#' @param cat default NULL; if not NULL, must be a logical vector matching
#'   vname, stating which (CELL) rasters to return as factor.
#' @param NODATA by default NULL, in which case it is set to one less than
#'   `floor()` of the data values for FCELL rasters or the range maximum
#'   for CELL Byte, UInt16 and Uint32 rasters (with no negative values), and an
#'   attempt is made to set NODATA to the upper Int16 and Int32 range if the
#'   lower range is occupied; otherwise an integer NODATA value (required to be
#'   integer by GRASS r.out.bin).
#' @param return_format default `terra`, optionally `SGDF`.
#' @param close_OK default TRUE - clean up possible open connections used for
#'   reading metadata; may be set to FALSE to avoid the side-effect of other
#'   user-opened connections being broken.
#' @param flags default NULL, character vector, for example `overwrite`.
#' @param Sys_ignore.stdout Passed to `system`.
#' @param ignore.stderr default taking the value set by
#'   `set.ignore.stderrOption`; can be set to TRUE to silence
#'   `system()` output to standard error; does not apply on Windows
#'   platforms.
#'
#' @return by default returns a SpatRaster object, but may return a legacy
#'   SpatialGridDataFrame object if `return_format="SGDF"`.
#'   `write_RAST` silently returns the object being written to GRASS.
#' @export
#' @importFrom stats runif
#' @importFrom methods getMethod slot as
#' @importFrom utils write.table 
#' @importFrom grDevices rgb
#'
#' @examples
#' # Run example only if GRASS settings file indicates that the
#' # nc_basic_spm_grass7 location is active
#' run <- FALSE
#' GISRC <- Sys.getenv("GISRC")
#'
#' if (nchar(GISRC) > 0) {
#'   location_name <- read.dcf(GISRC)[1, "LOCATION_NAME"]
#'   if (location_name == "nc_basic_spm_grass7") {
#'     run <- TRUE
#'   }
#' }
#'
#' # store original environment variables before modifying
#' GV <- Sys.getenv("GRASS_VERBOSE")
#' Sys.setenv("GRASS_VERBOSE" = 0)
#' original_ignore_stderr <- get.ignore.stderrOption()
#' set.ignore.stderrOption(TRUE)
#'
#' if (run) {
#'   # Retrieve GRASS metadata and creata a new mapset
#'   meta <- gmeta()
#'   location_path <- file.path(meta$GISDBASE, meta$LOCATION_NAME)
#'   previous_mapset <- meta$MAPSET
#'   example_mapset <- "RGRASS_EXAMPLES"
#'   execGRASS("g.mapset", flags = "c", mapset = example_mapset)
#' }
#'
#' if (run) {
#'   # List available mapsets and raster maps
#'   mapsets <- unlist(
#'     strsplit(execGRASS("g.mapsets", flags = "p", intern = TRUE), " ")
#'   )
#'   print(mapsets)
#' }
#'
#' if (run) {
#'   execGRASS("g.list", type = "raster", pattern = "soils", flags = "m",
#'             intern = TRUE)
#' }
#'
#' if (run) {
#'   execGRASS("g.list", type = "raster", pattern = "soils@PERMANENT",
#'             mapset = ".", flags = "m", intern = TRUE)
#' }
#'
#' if (run) {
#'   execGRASS("g.list", type = "raster", pattern = "soils",
#'             mapset = "PERMANENT", flags = "m", intern = TRUE)
#' }
#' # Read/write the GRASS "landuse" dataset as a SpatRaster
#' if (require("terra", quietly = TRUE)) {
#'  if (run) {
#'   v1 <- read_RAST("landuse", cat = TRUE, return_format = "terra")
#'   print(v1)
#'   print(inMemory(v1))
#'  }
#'
#'  if (run) {
#'   write_RAST(v1, "landuse1", flags = c("o", "overwrite"))
#'   execGRASS("r.stats", flags = "c", input = "landuse1")
#'   execGRASS("g.remove", flags = "f", name = "landuse1", type = "raster")
#'  }
#' }
#'
#' # read the geology and elevation GRASS datasets as SpatialGridDataFrames
#' if (require("sp", quietly = TRUE)) {
#'  if (run) {
#'   nc_basic <- read_RAST(c("geology", "elevation"), cat = c(TRUE, FALSE),
#'                         return_format = "SGDF")
#'   print(table(nc_basic$geology))
#'  }
#'
#'  if (run) {
#'   execGRASS("r.stats", flags = c("c", "l", "quiet"), input = "geology")
#'   boxplot(nc_basic$elevation ~ nc_basic$geology)
#'  }
#'  if (run) {
#'  # Compute square root of elevation and write back to GRASS
#'   nc_basic$sqdem <- sqrt(nc_basic$elevation)
#'   write_RAST(nc_basic, "sqdemSP", zcol = "sqdem",
#'              flags = c("quiet", "overwrite"))
#'   execGRASS("r.info", map = "sqdemSP")
#'  }
#'
#'  if (run) {
#'   # Read the new raster data and measure read times
#'   print(system.time(
#'     sqdemSP <- read_RAST(c("sqdemSP", "elevation"), return_format = "SGDF")
#'   ))
#'  }
#'
#'  if (run) {
#'   print(system.time(
#'     sqdem <- read_RAST(c("sqdemSP", "elevation"), return_format = "terra"))
#'   )
#'  }
#'
#'  if (run) {
#'   print(names(sqdem))
#'  }
#'
#'  if (run) {
#'   sqdem1 <- read_RAST(c("sqdemSP@RGRASS_EXAMPLES", "elevation@PERMANENT"))
#'   print(names(sqdem1))
#'  }
#'
#'  if (run) {
#'   execGRASS("g.remove", flags = "f", name = "sqdemSP", type = "raster")
#'
#'   # GRASS r.mapcalc example
#'   execGRASS("r.mapcalc", expression = "basins0 = basins - 1",
#'             flags = "overwrite")
#'   execGRASS("r.stats", flags = "c", input = "basins0")
#'  }
#'
#'  if (run) {
#'   basins0 <- read_RAST("basins0", return_format = "SGDF")
#'   print(table(basins0$basins0))
#'   execGRASS("g.remove", flags = "f", name = "basins0", type = "raster")
#'  }
#'
#'  if (run) {
#'   # Create and read a test raster
#'   execGRASS("r.mapcalc", expression = "test_t = 66000",
#'             flags = "overwrite")
#'   execGRASS("r.info", flags = "r", map = "test_t", intern = TRUE)
#'   tt <- read_RAST("test_t")
#'   execGRASS("g.remove", flags = "f", name = "test_t", type = "raster")
#'  }
#' }
#'
#' if (run) {
#'   # Restore the previous mapset and clean up
#'   execGRASS("g.mapset", mapset = previous_mapset)
#'   if (example_mapset != previous_mapset) {
#'     unlink(file.path(location_path, example_mapset), recursive = TRUE)
#'   }
#' }
#'
#' # Restore original GRASS settings
#' Sys.setenv("GRASS_VERBOSE" = GV)
#' set.ignore.stderrOption(original_ignore_stderr)
read_RAST <- function(
    vname, cat = NULL, NODATA = NULL, return_format = "terra",
    close_OK = return_format == "SGDF",
    flags = NULL, Sys_ignore.stdout = FALSE,
    ignore.stderr = get.ignore.stderrOption()) {
  if (!is.null(cat)) {
    if (length(vname) != length(cat)) {
      stop("vname and cat not same length")
    }
  }
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- set.echoCmdOption(FALSE)
  }
  if (close_OK) {
    openedConns <- as.integer(row.names(showConnections()))
  }
  stopifnot(is.logical(ignore.stderr), !is.na(ignore.stderr))

  if (!is.null(NODATA)) {
    if (any(!is.finite(NODATA)) || any(!is.numeric(NODATA))) {
      stop("invalid NODATA value")
    }
    if (NODATA != round(NODATA)) {
      warning("NODATA rounded to integer")
    }
    NODATA <- round(NODATA)
    if (length(NODATA) != length(vname)) {
      NODATA <- rep(NODATA[1], length.out = length(vname))
    }
  }

  msp <- get_mapsets()

  if (return_format == "SGDF") {
    if (!(requireNamespace("sp", quietly = TRUE))) {
      stop("sp required for SGDF output")
    }
    resa <- .read_rast_non_plugin_ng(
      vname = vname, cat = cat, NODATA = NODATA,
      ignore.stderr = ignore.stderr
    )
    if (close_OK) { # closeAllConnections()
      openConns_now <- as.integer(row.names(showConnections()))
      toBeClosed <- openConns_now[!(openConns_now %in% openedConns)]
      for (bye in toBeClosed) close(bye)
    }
  } else {
    if (!(requireNamespace("terra", quietly = TRUE))) {
      stop("terra required for SpatRaster output")
    }
    drv <- "RRASTER"
    fxt <- ".grd"
    ro <- FALSE
    o <- execGRASS("r.out.gdal", flags = "l", intern = TRUE)
    oo <- grep("RRASTER", o)
    if (length(oo) == 0L) ro <- TRUE
    if (!ro) {
      RR <- o[oo]
      RRs <- strsplit(RR, " ")[[1]]
      if (length(grep("\\(rw", RRs)) == 0L) ro <- TRUE
    }
    if (ro) {
      drv <- "GTiff"
      fxt <- ".tif"
    }
    reslist <- vector(mode = "list", length = length(vname))
    names(reslist) <- gsub("@", "_", vname)
    tmplist <- vector(mode = "list", length = length(vname))
    names(tmplist) <- gsub("@", "_", vname)
    for (i in seq(along = vname)) {
      # 130422 at rgdal 0.8-8 GDAL.close(DS)
      # 061107 Dylan Beaudette NODATA
      # 071009 Markus Neteler's idea to use range
      vca <- sanitize_layername(
        name = vname[i],
        type = "raster",
        mapsets = msp,
        ignore.stderr = ignore.stderr
      )
      typei <- NULL
      if (is.null(NODATA)) {
        tx <- execGRASS("r.info",
          flags = "r", map = vname[i], intern = TRUE,
          ignore.stderr = ignore.stderr
        )
        tx <- gsub("=", ":", tx)
        con <- textConnection(tx)
        res <- read.dcf(con)
        close(con)
        lres <- as.list(res)
        names(lres) <- colnames(res)
        lres <- lapply(lres, function(x) {
          ifelse(x == "NULL", as.numeric(NA), as.numeric(x))
        })
        tx <- execGRASS("r.info",
          flags = "g", map = vname[i], intern = TRUE,
          ignore.stderr = ignore.stderr
        )
        tx <- gsub("=", ":", tx)
        con <- textConnection(tx)
        res <- read.dcf(con)
        close(con)
        l1res <- as.list(res)
        names(l1res) <- colnames(res)
        CELL <- l1res$datatype == "CELL"
        NODATAi <- NULL
        if (!is.numeric(lres$min) ||
          !is.finite(as.double(lres$min))) {
          stop("set NODATA manually to a feasible value")
        } else {
          lres$min <- floor(as.double(lres$min))
          may_be_u <- all(c(lres$min, lres$max) >= 0)
          if (may_be_u && CELL) {
            if (lres$max < 4294967295) {
              NODATAi <- 4294967295
              typei <- "UInt32"
            } else if (lres$max == 4294967295) {
              if (lres$min > 0) {
                NODATAi <- 0
              } else {
                stop("set NODATA manually to a feasible value")
              }
            }
            if (lres$max < 65535) {
              NODATAi <- 65535
            } else if (lres$max == 65535) {
              if (lres$min > 0) {
                NODATAi <- 0
                typei <- "UInt16"
              } else {
                stop("set NODATA manually to a feasible value")
              }
            }
            if (lres$max < 255) {
              NODATAi <- 255
            } else if (lres$max == 255) {
              if (lres$min > 0) {
                NODATAi <- 0
                typei <- "Byte"
              } else {
                stop("set NODATA manually to a feasible value")
              }
            }
          } else if (!may_be_u && CELL) {
            if (lres$min == -2147483648) {
              if (lres$max < 2147483647) {
                NODATAi <- 2147483647
                typei <- "Int32"
              } else {
                stop("set NODATA manually to a feasible value")
              }
            }
            if (lres$min == -32768) {
              if (lres$max < 32767) {
                NODATAi <- 32767
                typei <- "Int16"
              } else {
                stop("set NODATA manually to a feasible value")
              }
            }
            if (is.null(NODATAi)) NODATAi <- floor(lres$min) - 1
          } else {
            NODATAi <- floor(lres$min) - 1
          }
        }
      } else {
        NODATAi <- NODATA[i]
      }
      tmplist[[i]] <- tempfile(fileext = fxt, tmpdir = Sys.getenv("RGRASS_TEMPDIR"))
      if (is.null(flags)) flags <- c("overwrite", "c", "m")
      if (!is.null(cat) && cat[i]) flags <- c(flags, "t")
      if (is.null(typei)) {
        execGRASS("r.out.gdal",
                  input = vname[i], output = tmplist[[i]],
                  format = drv, nodata = NODATAi, flags = flags,
                  ignore.stderr = ignore.stderr,
                  Sys_ignore.stdout = Sys_ignore.stdout
        )
      } else {
        execGRASS("r.out.gdal",
                  input = vname[i], output = tmplist[[i]],
                  format = drv, nodata = NODATAi, type = typei, flags = flags,
                  ignore.stderr = ignore.stderr,
                  Sys_ignore.stdout = Sys_ignore.stdout
        )
      }
      reslist[[i]] <- getMethod("rast", "character")(tmplist[[i]])
    }
    resa <- getMethod("rast", "list")(reslist)
  }
  if (get.suppressEchoCmdInFuncOption()) tull <- set.echoCmdOption(inEchoCmd)

  resa
}


.read_rast_non_plugin_ng <- function(vname, cat, NODATA, ignore.stderr) {
  pid <- as.integer(round(runif(1, 1, 1000)))

  gLP <- getLocationProj()
  if (gLP == "XY location (unprojected)") {
    p4 <- sp::CRS(as.character(NA))
  } else {
    p4 <- sp::CRS(gLP)
  }

  reslist <- vector(mode = "list", length = length(vname))
  names(reslist) <- gsub("@", "_", vname)

  msp <- unlist(strsplit(execGRASS("g.mapsets",
    flags = "p",
    intern = TRUE
  ), " "))

  for (i in seq(along = vname)) {
    vca <- unlist(strsplit(vname[i], "@"))
    if (length(vca) == 1L) {
      exsts <- execGRASS("g.list",
        type = "raster", pattern = vca[1],
        intern = TRUE, ignore.stderr = ignore.stderr
      )
      if (length(exsts) > 1L) {
        stop(
          "multiple rasters named ", vca[1],
          " found in in mapsets in search path:\n",
          paste(msp, collapse = ", "),
          "\nuse full path with @ to choose the required raster"
        )
      }
      if (length(exsts) == 0L || exsts != vca[1]) {
        stop(
          vname[i], " not found in mapsets in search path: ",
          paste(msp, collapse = ", ")
        )
      }
    } else if (length(vca) == 2L) {
      exsts <- execGRASS("g.list",
        type = "raster", pattern = vca[1],
        mapset = vca[2], intern = TRUE, ignore.stderr = ignore.stderr
      )
      if (length(exsts) == 0L || exsts != vca[1]) {
        stop(vname[i], " not found in mapset: ", vca[2])
      }
    } else {
      stop(vname[i], " incorrectly formatted")
    }
    glist <- execGRASS("r.info",
      flags = "g", map = vname[i],
      intern = TRUE, ignore.stderr = ignore.stderr
    )
    whCELL <- glist[grep("datatype", glist)]
    to_int <- length(which(unlist(strsplit(
      whCELL, "="
    )) == "CELL")) > 0
    Dcell <- length(which(unlist(strsplit(
      whCELL, "="
    )) == "DCELL")) > 0

    gtmpfl1 <- dirname(execGRASS("g.tempfile",
      pid = pid, intern = TRUE, ignore.stderr = ignore.stderr
    ))
    rtmpfl1 <- ifelse(.Platform$OS.type == "windows" &&
      (Sys.getenv("OSTYPE") == "cygwin"),
    system(paste("cygpath -w", gtmpfl1, sep = " "),
      intern = TRUE
    ), gtmpfl1
    )
    gtmpfl11 <- paste(gtmpfl1, vname[i], sep = .Platform$file.sep)
    rtmpfl11 <- paste(rtmpfl1, vname[i], sep = .Platform$file.sep)

    # 130422 at rgdal 0.8-8 GDAL.close(DS)
    # 061107 Dylan Beaudette NODATA
    # 071009 Markus Neteler's idea to use range
    if (is.null(NODATA)) {
      tx <- execGRASS("r.info",
        flags = "r", map = vname[i], intern = TRUE,
        ignore.stderr = ignore.stderr
      )
      tx <- gsub("=", ":", tx)
      con <- textConnection(tx)
      res <- read.dcf(con)
      close(con)
      lres <- as.list(res)
      names(lres) <- colnames(res)
      lres <- lapply(lres, function(x) {
        ifelse(x == "NULL", as.numeric(NA), as.numeric(x))
      })
      if (!is.numeric(lres$min) ||
        !is.finite(as.double(lres$min))) {
        NODATAi <- as.integer(999)
      } else {
        lres$min <- floor(as.double(lres$min))
        NODATAi <- floor(lres$min) - 1
      }
    }

    rOutBinFlags <- "b"
    # 120118 Rainer Krug
    if (to_int) {
      rOutBinFlags <- c(rOutBinFlags, "i")
    } else {
      rOutBinFlags <- c(rOutBinFlags, "f")
    }
    rOutBinBytes <- 4L
    if (Dcell) rOutBinBytes <- 8L
    tryCatch({
      execGRASS("r.out.bin",
        flags = rOutBinFlags,
        input = vname[i], output = gtmpfl11, bytes = rOutBinBytes,
        null = as.integer(NODATAi), ignore.stderr = ignore.stderr
      )

      gdal_info <- bin_gdal_info_ng(rtmpfl11, to_int)

      what <- ifelse(to_int, "integer", "double")
      n <- gdal_info[1] * gdal_info[2]
      size <- gdal_info[10] / 8

      reslist[[i]] <- readBinGridData(rtmpfl11,
        what = what,
        n = n, size = size, endian = attr(gdal_info, "endian"),
        nodata = attr(gdal_info, "nodata")
      )
    }, finally = {
      unlink(paste(rtmpfl1, list.files(rtmpfl1,
        pattern = vname[i]
      ), sep = .Platform$file.sep))
    })
  }

  co <- unname(c(
    (gdal_info[4] + (gdal_info[6] / 2)),
    (gdal_info[5] + (gdal_info[7] / 2))
  ))
  grid <- sp::GridTopology(
    co, unname(c(gdal_info[6], gdal_info[7])),
    unname(c(gdal_info[2], gdal_info[1]))
  )

  if (length(unique(sapply(reslist, length))) != 1) {
    stop("bands differ in length")
  }

  df <- as.data.frame(reslist)

  resa <- sp::SpatialGridDataFrame(grid = grid, data = df, proj4string = p4)

  if (!is.null(cat)) {
    for (i in seq(along = cat)) {
      if (cat[i] && is.integer(resa@data[[i]])) {
        rSTATS <- execGRASS("r.stats",
          flags = c("l", "quiet"),
          input = vname[i], intern = TRUE,
          ignore.stderr = ignore.stderr
        )

        cats <- strsplit(rSTATS, " ")
        catnos <- sapply(cats, function(x) x[1])
        catlabs <- sapply(
          cats,
          function(x) paste(x[-1], collapse = " ")
        )
        if (any(!is.na(match(catnos, "*")))) {
          isNA <- which(catnos == "*")
          catnos <- catnos[-isNA]
          catlabs <- catlabs[-isNA]
        }
        if (length(catlabs) > length(unique(catlabs))) {
          catlabs <- paste(catlabs, catnos, sep = "_")
          warning("non-unique category labels; category number appended")
        }
        # https://files.nc.gov/ncdeq/Energy+Mineral+and+Land+Resources/Geological+Survey/1985_state_geologic_map_500000_scale.pdf (catnos vector polygon IDs)
        resa@data[[i]] <- factor(resa@data[[i]],
          levels = catnos, labels = catlabs
        )
      }
    }
  }
  return(resa)
}




bin_gdal_info_ng <- function(fname, to_int) {
  if (!file.exists(fname)) stop(paste("no such file:", fname))
  if (!file.exists(paste(fname, "hdr", sep = "."))) {
    stop(paste("no such file:", paste(fname, "hdr", sep = ".")))
  }
  if (!file.exists(paste(fname, "wld", sep = "."))) {
    stop(paste("no such file:", paste(fname, "wld", sep = ".")))
  }
  con <- file(paste(fname, "hdr", sep = "."), "r")
  l8 <- readLines(con, n = 8)
  close(con)
  l8 <- read.dcf(con <- textConnection(gsub(" ", ":", l8)))
  close(con)
  lres <- as.list(l8)
  names(lres) <- colnames(l8)
  lres$nrows <- as.integer(lres$nrows)
  lres$ncols <- as.integer(lres$ncols)
  lres$nbands <- as.integer(lres$nbands)
  lres$nbits <- as.integer(lres$nbits)
  lres$skipbytes <- as.integer(lres$skipbytes)
  lres$nodata <- ifelse(to_int, as.integer(lres$nodata),
    as.numeric(lres$nodata)
  )
  lres$byteorder <- as.character(lres$byteorder)
  endian <- .Platform$endian
  if ((endian == "little" && lres$byteorder == "M") ||
    (endian == "big" && lres$byteorder == "I")) {
    endian <- "swap"
  }
  con <- file(paste(fname, "wld", sep = "."), "r")
  l6 <- readLines(con, n = 6)
  close(con)
  lres$ewres <- abs(as.numeric(l6[1]))
  lres$nsres <- abs(as.numeric(l6[4]))
  lres$n_cc <- as.numeric(l6[6])
  lres$w_cc <- as.numeric(l6[5])
  lres$s_cc <- lres$n_cc - lres$nsres * (lres$nrows - 1)

  outres <- numeric(10)
  outres[1] <- lres$nrows
  outres[2] <- lres$ncols
  outres[3] <- lres$nbands
  outres[4] <- lres$w_cc - (lres$ewres / 2)
  outres[5] <- lres$s_cc - (lres$nsres / 2)
  outres[6] <- lres$ewres
  outres[7] <- lres$nsres
  outres[10] <- lres$nbits
  attr(outres, "endian") <- endian
  attr(outres, "nodata") <- lres$nodata
  # 	grid = GridTopology(c(lres$w_cc, lres$s_cc),
  # 		c(lres$ewres, lres$nsres), c(lres$ncols,lres$nrows))
  outres
}

readBinGridData <- function(fname, what, n, size, endian, nodata) {
  map <- readBin(fname,
    what = what, n = n, size = size, signed = TRUE,
    endian = endian
  )
  is.na(map) <- map == nodata
  map
}

repair_cats <- function(x, layer, vname) {
  if (!(requireNamespace("terra", quietly = TRUE))) {
    stop("terra required for to repair terra object cats")
  }
  if (!inherits(x, "SpatRaster")) stop("x not a SpatRaster object")
  xcats <- getMethod("cats", "SpatRaster")(x)
  nms <- getMethod("names", "SpatRaster")(x)
  if (length(xcats) > 1) {
    nms <- getMethod("names", "SpatRaster")(x)
    if (!(layer %in% nms)) stop("layer not found")
  }
  xcat <- xcats[[match(layer, nms)]]
  if (is.null(xcat)) warning("no cats in layer")
  zcats <- cats_internals(vname)
  res <- vector(mode = "list", length = 1)
  names(res) <- layer
  res[[1]] <- getMethod("classify", "SpatRaster")(x[[layer]], zcats$rcp_out)
  getMethod("set.cats", "SpatRaster")(res[[1]], layer = 1, value = zcats$levs)
  getMethod("rast", "list")(res)
}

cats_internals <- function(vname) {
  cats <- execGRASS("r.category", map = vname, separator = ":", intern = TRUE)
  cats1 <- strsplit(cats, ":")
  cats2 <- data.frame(
    ID = sapply(cats1, "[", 1L),
    category = sapply(cats1, "[", 2)
  )
  cats2$Icat <- as.integer(factor(cats2$category,
    levels = unique(cats2$category)
  ))
  cats3 <- split(cats2, cats2$Icat)
  rcp_out <- do.call("rbind", lapply(cats3, function(x) {
    cbind(as.integer(x[[1]]), as.integer(x[[3]]))
  }))
  levs <- do.call("rbind", lapply(cats3, function(x) {
    ux <- unique(x[, 2:3])
    data.frame(cat = as.integer(ux[[2]]), lev = ux[[1]])
  }))
  list(rcp_out = rcp_out, levs = levs)
}

read_cat_colors <- function(vname) {
  zcats <- cats_internals(vname)
  cols <- execGRASS("r.colors.out", map = vname, intern = TRUE)
  cols12 <- strsplit(cols, " ")
  cat_col1 <- match(as.character(zcats$rcp_out[, 1]), sapply(cols12, "[", 1))
  if (length(cat_col1) != (length(cols12) - 2L)) {
    warning("possible category mismatch")
  }
  coltb <- sapply(cols12[zcats$rcp_out[order(zcats$rcp_out[, 1]), 2]], "[", 2L)
  df <- as.data.frame(t(sapply(strsplit(coltb, ":"), as.integer)))
  pal <- rgb(df$V1, df$V2, df$V3, maxColorValue = 255)
  list(coltab = df, pal = pal)
}

#' @rdname read_RAST
#' @param x A terra [`terra::SpatRaster`] or sp [`sp::SpatialGridDataFrame`]
#'   object,
#' @param zcol Attribute column number or name,
#' @param overwrite default FALSE, if TRUE inserts "overwrite" into the value of
#'   the flags argument if not already there to allow existing GRASS rasters to
#'   be overwritten,
#' @param verbose default TRUE, report how writing to GRASS is specified,
#' @export
write_RAST <- function(
    x, vname, zcol = 1, NODATA = NULL, flags = NULL,
    ignore.stderr = get.ignore.stderrOption(), overwrite = FALSE, verbose = TRUE) {
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- set.echoCmdOption(FALSE)
  }
  stopifnot(is.logical(ignore.stderr))
  stopifnot(is.character(vname))
  if (!is.null(flags)) stopifnot(is.character(flags))

  if (overwrite && !("overwrite" %in% flags)) {
    flags <- c(flags, "overwrite")
  }
  if (inherits(x, "SpatialGridDataFrame")) {
    if (!(requireNamespace("sp", quietly = TRUE))) {
      stop("sp required for SGDF input")
    }
    stopifnot(length(vname) == 1L)
    pid <- as.integer(round(runif(1, 1, 1000)))
    gtmpfl1 <- dirname(execGRASS("g.tempfile",
      pid = pid,
      intern = TRUE, ignore.stderr = ignore.stderr
    ))

    rtmpfl1 <- ifelse(.Platform$OS.type == "windows" &&
      (Sys.getenv("OSTYPE") == "cygwin"),
    system(paste("cygpath -w", gtmpfl1, sep = " "), intern = TRUE),
    gtmpfl1
    )

    fid <- paste("X", pid, sep = "")
    gtmpfl11 <- paste(gtmpfl1, fid, sep = .Platform$file.sep)
    rtmpfl11 <- paste(rtmpfl1, fid, sep = .Platform$file.sep)
    if (!is.numeric(x@data[[zcol]])) {
      stop("only numeric columns may be exported")
    }
    res <- writeBinGrid_ng(x, rtmpfl11, attr = zcol, na.value = NODATA)

    flags <- c(res$flag, flags)

    execGRASS("r.in.bin",
      flags = flags, input = gtmpfl11, output = vname,
      bytes = as.integer(res$bytes), north = as.numeric(res$north),
      south = as.numeric(res$south), east = as.numeric(res$east),
      west = as.numeric(res$west), rows = as.integer(res$rows),
      cols = as.integer(res$cols), anull = as.numeric(res$anull),
      ignore.stderr = ignore.stderr
    )
    if (verbose) message("SpatialGridDataFrame read into GRASS using r.in.bin")
  } else if (inherits(x, "SpatRaster")) {
    if (!(requireNamespace("terra", quietly = TRUE))) {
      stop("terra required for terra output")
    }
    # Suggestion https://github.com/osgeo/rgrass/pull/45#discussion_r816113064 Floris Vanderhaeghe
    srcs <- getMethod("sources", "SpatRaster")(x)
    mems <- getMethod("inMemory", "SpatRaster")(x)
    if (length(srcs) == 1L && !mems[1]) {
      tf <- srcs[1]
    } else {
      tf <- ""
    }
    if (!file.exists(tf)) {
      drv <- "RRASTER"
      fxt <- ".grd"
      gdalver <- gsub("[A-Za-z]", "", strsplit(terra::gdal(), "-")[[1]][1])
      if (gdalver < "2.3.0") {
        drv <- "GTiff"
        fxt <- ".tif"
      }
      tf <- tempfile(fileext = fxt, tmpdir = Sys.getenv("RGRASS_TEMPDIR"))
      on.exit(unlink(tf))
      res <- getMethod("writeRaster", c("SpatRaster", "character"))(x,
        filename = tf, overwrite = TRUE, filetype = drv)
      tmpfl <- TRUE
    } else {
      res <- x
      tmpfl <- FALSE
    }
    execGRASS("r.in.gdal", flags = flags, input = tf, output = vname)
    #        if (tmpfl) unlink(tf)
    if (verbose) {
      message(
        "SpatRaster read into GRASS using r.in.gdal from ",
        ifelse(tmpfl, "memory", "file")
      )
    }
    if (getMethod("nlyr", "SpatRaster")(x) == 1L) {
      xcats <- getMethod("cats", "SpatRaster")(x)[[1]]
      if (!is.null(xcats)) {
        tfc <- tempfile(tmpdir = Sys.getenv("RGRASS_TEMPDIR"))
        on.exit(unlink(tfc), add = TRUE)
        write.table(xcats, tfc,
          sep = ":", row.names = FALSE,
          col.names = FALSE, quote = FALSE
        )
        execGRASS("r.category", map = vname, rules = tfc, separator = ":")
      }
    }
  } else {
    stop("object neither SpatialGridDataFrame nor SpatRaster")
  }
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  invisible(res)
}

writeBinGrid_ng <- function(x, fname, attr = 1, na.value = NULL) {
  if (!sp::gridded(x)) {
    stop("can only write SpatialGridDataFrame objects to binary grid")
  }
  x <- as(x, "SpatialGridDataFrame")
  gp <- sp::gridparameters(x)
  if (length(gp$cells.dim) != 2) {
    stop("binary grid only supports 2D grids")
  }
  z <- x@data[[attr]]
  if (is.factor(z)) z <- as.numeric(z)
  if (!is.numeric(z)) stop("only numeric values may be exported")
  if (is.null(na.value)) {
    na.value <- floor(min(z, na.rm = TRUE)) - 1
  } else {
    if (!is.finite(na.value) || !is.numeric(na.value)) {
      stop("invalid NODATA value")
    }
    if (na.value != round(na.value)) {
      warning("NODATA rounded to integer")
    }
    na.value <- round(na.value)
  }
  res <- list()
  res$anull <- formatC(na.value, format = "d")
  z[is.na(z)] <- as.integer(na.value)
  if (storage.mode(z) == "integer") {
    sz <- 4
  } else if (storage.mode(z) == "double") {
    sz <- 8
    res$flag <- "d"
  } else {
    stop("unknown storage mode")
  }
  res$bytes <- formatC(sz, format = "d")
  f <- file(fname, open = "wb")
  writeBin(z, con = f, size = sz)
  close(f)
  grd <- slot(x, "grid")
  f <- file(paste(fname, "hdr", sep = "."), open = "wt")
  writeLines(paste("nrows", grd@cells.dim[2]), f)
  res$rows <- formatC(grd@cells.dim[2], format = "d")
  writeLines(paste("ncols", grd@cells.dim[1]), f)
  res$cols <- formatC(grd@cells.dim[1], format = "d")
  writeLines(paste("nbands 1"), f)
  writeLines(paste("nbits", 8 * sz), f)
  writeLines(paste("byteorder", ifelse(.Platform$endian == "little",
    "I", "M"
  )), f)
  writeLines(paste("layout bil"), f)
  writeLines(paste("skipbytes 0"), f)
  writeLines(paste("nodata", na.value), f)
  close(f)
  f <- file(paste(fname, "wld", sep = "."), open = "wt")
  writeLines(formatC(grd@cellsize[1], format = "f"), f)
  writeLines("0.0", f)
  writeLines("0.0", f)
  writeLines(formatC(-grd@cellsize[2], format = "f"), f)
  writeLines(formatC(grd@cellcentre.offset[1], format = "f"), f)
  writeLines(formatC((grd@cellcentre.offset[2] +
    grd@cellsize[2] * (grd@cells.dim[2] - 1)), format = "f"), f)
  close(f)
  res$north <- formatC((grd@cellcentre.offset[2] +
    grd@cellsize[2] * (grd@cells.dim[2] - 1)
    + 0.5 * grd@cellsize[2]), format = "f")
  res$south <- formatC(grd@cellcentre.offset[2] - 0.5 * grd@cellsize[2],
    format = "f"
  )
  res$east <- formatC(
    (grd@cellcentre.offset[1] +
      grd@cellsize[1] * (grd@cells.dim[1] - 1) + 0.5 * grd@cellsize[1]),
    format = "f"
  )
  res$west <- formatC(grd@cellcentre.offset[1] - 0.5 * grd@cellsize[1],
    format = "f"
  )
  invisible(res)
}
