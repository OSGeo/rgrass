# Interpreted GRASS 7 interface functions
# Copyright (c) 2015-20 Roger S. Bivand
#

#' Reads GRASS metadata from the current LOCATION
#'
#' GRASS LOCATION metadata are read into a list in R; helper function
#' getLocationProj returns a WKT2 string of projection information. The helper
#' function `gmeta2grd` creates a GridTopology object from the current
#' GRASS mapset region definitions.
#'
#' @author Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>
#' @keywords spatial
#'
#' @param ignore.stderr default FALSE, can be set to TRUE to silence
#'   `system()` output to standard error; does not apply on Windows
#'   platforms.
#' @param g.proj_WKT default NULL: return WKT2 representation in GRASS >= 7.6
#'   and Proj4 in GRASS < 7.6; may be set to FALSE to return Proj4 for GRASS >=
#'   7.6.
#'
#' @return Returns list of g.gisenv, g.region -g3, and g.proj values.
#' @export
#' @order 1
#'
#' @examples
#' run <- FALSE
#' if (nchar(Sys.getenv("GISRC")) > 0 &&
#'     read.dcf(Sys.getenv("GISRC"))[1, "LOCATION_NAME"] == "nc_basic_spm_grass7") {
#'   run <- TRUE
#' }
#'
#' if (run) {
#'   G <- gmeta()
#'   print(G)
#'
#'   cat(getLocationProj(), "\n")
#'   cat(getLocationProj(g.proj_WKT = FALSE), "\n")
#'
#'   grd <- gmeta2grd()
#'   print(grd)
#'
#'   ncells <- prod(slot(grd, "cells.dim"))
#'   df <- data.frame(k = rep(1, ncells))
#'   mask_SG <- sp::SpatialGridDataFrame(grd, data = df)
#'   print(summary(mask_SG))
#' }
gmeta <- function(ignore.stderr = FALSE, g.proj_WKT = NULL) {
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- get.echoCmdOption()
    tull <- set.echoCmdOption(FALSE)
  }
  tx <- execGRASS("g.region",
    flags = c("g", "3"), intern = TRUE,
    ignore.stderr = ignore.stderr
  )
  tx <- gsub("=", ":", tx)
  con <- textConnection(tx)
  res <- read.dcf(con)
  close(con)
  lres <- as.list(res)
  names(lres) <- colnames(res)
  lres$n <- as.double(lres$n)
  lres$s <- as.double(lres$s)
  lres$w <- as.double(lres$w)
  lres$e <- as.double(lres$e)
  lres$t <- as.double(lres$t)
  lres$b <- as.double(lres$b)
  lres$nsres <- as.double(lres$nsres)
  lres$nsres3 <- as.double(lres$nsres3)
  lres$ewres <- as.double(lres$ewres)
  lres$ewres3 <- as.double(lres$ewres3)
  lres$tbres <- as.double(lres$tbres)
  if (length(lres$rows) == 0) {
    lres$rows <- abs(as.integer((lres$n - lres$s) / lres$nsres))
  } else {
    lres$rows <- as.integer(lres$rows)
  }
  if (length(lres$rows3) == 0) {
    lres$rows3 <- lres$rows
  } else {
    lres$rows3 <- as.integer(lres$rows3)
  }
  if (length(lres$cols) == 0) {
    lres$cols <- abs(as.integer((lres$e - lres$w) / lres$ewres))
  } else {
    lres$cols <- as.integer(lres$cols)
  }
  if (length(lres$cols3) == 0) {
    lres$cols3 <- lres$cols
  } else {
    lres$cols3 <- as.integer(lres$cols3)
  }
  if (length(lres$depths) == 0) {
    lres$depths <- abs(as.integer((lres$t - lres$b) / lres$tbres))
  } else {
    lres$depths <- as.integer(lres$depths)
  }
  lres$proj4 <- ""
  prj <- try(getLocationProj(
    g.proj_WKT = g.proj_WKT,
    ignore.stderr = ignore.stderr
  ), silent = TRUE)
  if (!inherits(prj, "try-error")) lres$proj4 <- prj
  gisenv <- execGRASS("g.gisenv",
    flags = "n", intern = TRUE,
    ignore.stderr = ignore.stderr
  )
  gisenv <- gsub("[';]", "", gisenv)
  gisenv <- strsplit(gisenv, "=")
  glist <- as.list(sapply(gisenv, function(x) x[2]))
  names(glist) <- sapply(gisenv, function(x) x[1])
  lres <- c(glist, lres)
  class(lres) <- "gmeta"
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  lres
}

#' @rdname gmeta
#' @order 4
#' @param x S3 object returned by gmeta
#' @param ... arguments passed through print method
#' @export
print.gmeta <- function(x, ...) {
  cat("gisdbase   ", x$GISDBASE, "\n")
  cat("location   ", x$LOCATION_NAME, "\n")
  cat("mapset     ", x$MAPSET, "\n")
  cat("rows       ", x$rows, "\n")
  cat("columns    ", x$cols, "\n")
  cat("north      ", x$n, "\n")
  cat("south      ", x$s, "\n")
  cat("west       ", x$w, "\n")
  cat("east       ", x$e, "\n")
  cat("nsres      ", x$nsres, "\n")
  cat("ewres      ", x$ewres, "\n")
  if (is.character(x$proj4[1]) && nzchar(x$proj4[1])) {
    if (substr(x$proj4[1], 1, 1) == "+") {
      cat("projection ", paste(strwrap(x$proj4), collapse = "\n"), "\n")
    } else {
      cat("projection:\n", x$proj4[1], "\n")
    }
  }
  invisible(x)
}

#' @rdname gmeta
#' @order 3
#' @export
gmeta2grd <- function(ignore.stderr = FALSE) {
  if (!requireNamespace("sp", quietly = TRUE)) {
    stop("sp required to creat a GridTopology object")
  }
  G <- gmeta(ignore.stderr = ignore.stderr)
  cellcentre.offset <- c(G$w + (G$ewres / 2), G$s + (G$nsres / 2))
  cellsize <- c(G$ewres, G$nsres)
  cells.dim <- c(G$cols, G$rows)

  grd <- sp::GridTopology(
    cellcentre.offset = cellcentre.offset,
    cellsize = cellsize, cells.dim = cells.dim
  )
  grd
}

#' @rdname gmeta
#' @order 2
#' @export
getLocationProj <- function(ignore.stderr = FALSE, g.proj_WKT = NULL) {
  # too strict assumption on g.proj Rohan Sadler 20050928
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- get.echoCmdOption()
    tull <- set.echoCmdOption(FALSE)
  }
  gv <- .grassVersion()
  WKT2 <- gv >= "GRASS 7.6"
  old_proj <- TRUE
  if (requireNamespace("terra", quietly = TRUE)) {
    old_proj <- as.integer(substring(terra::gdal(lib = "proj"), 1, 1)) <= 5L
  }
  if (!is.null(g.proj_WKT)) {
    stopifnot(is.logical(g.proj_WKT))
    stopifnot(length(g.proj_WKT) == 1L)
    if (gv < "GRASS 7.6" || g.proj_WKT) {
      warning("Only Proj4 string representation for GRASS < 7.6")
    }
    if (!g.proj_WKT) WKT2 <- FALSE
  }
  if (WKT2 && !old_proj) {
    res <- execGRASS("g.proj", flags = c("w"), intern = TRUE, ignore.stderr = TRUE)
    res <- paste(res, collapse = "\n")
    
    if (substr(res, 1, 5) != "ERROR") {
      if (nchar(res) == 0L) {
        res <- paste(execGRASS("g.proj",
          flags = c("j"), intern = TRUE,
          ignore.stderr = ignore.stderr
        ), collapse = " ")
      }
      return(res)
    }
  }
  projstr <- execGRASS("g.proj",
    flags = c("j", "f"), intern = TRUE,
    ignore.stderr = ignore.stderr
  )
  if (length(grep("XY location", projstr)) > 0) {
    projstr <- as.character(NA)
  }
  if (length(grep("latlong", projstr)) > 0) {
    projstr <- sub("latlong", "longlat", projstr)
  }
  if (is.na(projstr)) {
    uprojargs <- projstr
  } else {
    uprojargs <- paste(unique(unlist(strsplit(projstr, " "))),
      collapse = " "
    )
  }
  if (length(grep("= ", uprojargs)) != 0) {
    warning(paste(
      "No spaces permitted in PROJ4",
      "argument-value pairs:", uprojargs
    ))
    uprojargs <- as.character(NA)
  }
  if (length(grep(" [:alnum:]", uprojargs)) != 0) {
    warning(paste(
      "PROJ4 argument-value pairs",
      "must begin with +:", uprojargs
    ))
    uprojargs <- as.character(NA)
  }
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  uprojargs
}

.g_findfile <- function(vname, type) {
  ms <- execGRASS("g.findfile",
    element = type, file = vname[1],
    intern = TRUE
  )
  tx <- gsub("=", ":", ms)
  con <- textConnection(tx)
  res <- read.dcf(con)
  close(con)
  lres <- as.list(res)
  names(lres) <- colnames(res)
  if (nchar(lres$name) == 0) {
    stop(paste(vname[1], "- file not found"))
  }
  mapset <- gsub("'", "", lres$mapset)
  mapset
}

.addexe <- function() {
  res <- ""
  SYS <- get("SYS", envir = .GRASS_CACHE)
  if (SYS == "WinNat") res <- ".exe"
  res
}

.grassVersion <- function(ignore.stderr = TRUE) {
  Gver <- try(execGRASS(
    "g.version",
    intern = TRUE,
    ignore.stderr = ignore.stderr
  ), silent = TRUE)
  if (inherits(Gver, "try-error")) {
    Gver <- "sh: line 1: g.version: command not found"
  }
  return(Gver)
}

.compatibleGRASSVersion <- function(gv = .grassVersion()) {
  compatible <- ((gv >= "GRASS 7.0") & (gv < "GRASS 9.0"))
  if (gv == "sh: line 1: g.version: command not found") {
    compatible <- as.logical(NA)
    attr(compatible, "message") <- gv
    return(compatible)
  }
  if (!compatible) {
    attr(compatible, "message") <- paste0(
      "\n### rgrass7 is not compatible with the GRASS GIS version '", gv, "'!",
      "\n### Please use the package appropriate to the GRASS GIS version:",
      "\n### GRASS GIS Version 5.x.y  --  GRASS",
      "\n### GRASS GIS Version 6.x.y  --  spgrass6",
      "\n### GRASS GIS Version 7.x.y  --  rgrass7",
      "\n### GRASS GIS Version 8.x.y  --  rgrass"
    )
  } else {
    attr(compatible, "message") <- paste0("rgrass7 is compatible with the GRASS GIS version '", gv, "' R is running in!")
  }
  return(compatible)
}

.get_R_interface <- function() get("R_interface", envir = .GRASS_CACHE)
