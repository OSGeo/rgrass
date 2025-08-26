# Interpreted GRASS interface functions
# Copyright (c) 2022 Roger S. Bivand


#' Read and write GRASS vector object files
#'
#' `read_VECT` moves one GRASS vector object file with attribute data
#' through a temporary GeoPackage file to a [`terra::SpatVector`]
#' object; `write_VECT` moves a [`terra::SpatVector`] object
#' through a temporary GeoPackage file to a GRASS vector object file.
#' `vect2neigh` returns neighbour pairs with shared boundary length as
#' described by Markus Neteler, in
#' <https://stat.ethz.ch/pipermail/r-sig-geo/2005-October/000616.html>.
#' `cygwin_clean_temp` can be called to try to clean the GRASS
#' mapset-specific temporary directory under cygwin.
#'
#' @note
#' Be aware that the GDAL-GRASS driver may have some
#' [issues](https://github.com/OSGeo/gdal-grass/issues) for vector data. In
#' our experience, the error and warning messages for vector data can be
#' ignored. Further, the returned metadata about the coordinate reference system
#' may currently be incomplete, e.g. it may miss the EPSG code.
#'
#' @author Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>
#' @order 1
#'
#' @param vname A GRASS vector file name.
#' @param layer a layer name (string); if missing the first layer will be used.
#' @param proxy Default is `FALSE`. Set as `TRUE` if you need a
#'   `SpatVectorProxy` object.
#' @param use_gdal_grass_driver Default `TRUE`. The
#'   [standalone GDAL-GRASS driver](https://github.com/OSGeo/gdal-grass)
#'   for the vector format will be used if it is installed. The advantage is
#'   that no intermediate file needs to be written from GRASS GIS and
#'   subsequently read into R; instead the vector layer is read directly from
#'   the GRASS GIS database. Please read the **Note** further below!.
#' @param type override type detection when multiple types are non-zero, passed
#'   to v.out.ogr.
#' @param flags Character vector containing additional optional flags and/or
#'   options for v.in.ogr, particularly "o" and "overwrite".
#' @param Sys_ignore.stdout Passed to `system`.
#' @param ignore.stderr default the value set by `set.ignore.stderrOption`;
#'   NULL, taking the value set by `set.ignore.stderrOption`, can be set to
#'   TRUE to silence `system()` output to standard error; does not apply on
#'   Windows platforms.
#' @param x A `SpatVector` object moved to GRASS.
#' @param flags Character vector containing additional optional flags and/or
#'   options for v.in.ogr, particularly "o" and "overwrite".
#' @param ID A valid DB column name for unique identifiers (optional).
#' @param remove default TRUE, remove copied vectors created in
#'   `vect2neigh`.
#' @param vname2 If on a previous run, remove was FALSE, the name of the
#'   temporary vector may be given to circumvent its generation.
#' @param units default "k"; see GRASS 'v.to.db' manual page for alternatives.
#'
#' @return `read_VECT` imports a GRASS vector layer into a `SpatVector` or
#'   `SpatVectorProxy` object.
#'   `vect2neigh` returns a data frame object with left and right
#'   neighbours and boundary lengths, also given class GRASSneigh and
#'   spatial.neighbour (as used in spdep). The incantation to retrieve the
#'   neighbours list is `sn2listw(vect2neigh())$neighbours`, and to
#'   retrieve the boundary lengths: `sn2listw(vect2neigh())$weights`. The
#'   GRASSneigh object has two other useful attributes: external is a vector
#'   giving the length of shared boundary between each polygon and the external
#'   area, and total giving each polygon's total boundary length.
#' @export
#' @importFrom methods getMethod
#'
#' @examples
#' # Run example if in active GRASS nc_basic_spm_grass7 location
#' run <- FALSE
#' if (nchar(Sys.getenv("GISRC")) > 0 &&
#'     read.dcf(Sys.getenv("GISRC"))[1, "LOCATION_NAME"] == "nc_basic_spm_grass7") {
#'   run <- require(terra, quietly = TRUE)
#' }
#'
#' # Store original environment variable settings
#' GV <- Sys.getenv("GRASS_VERBOSE")
#' Sys.setenv("GRASS_VERBOSE" = 0)
#' ois <- get.ignore.stderrOption()
#' set.ignore.stderrOption(TRUE)
#'
#' if (run) {
#'   # Create a new mapset
#'   meta <- gmeta()
#'   location_path <- file.path(meta$GISDBASE, meta$LOCATION_NAME)
#'   previous_mapset <- meta$MAPSET
#'   example_mapset <- "RGRASS_EXAMPLES"
#'   execGRASS("g.mapset", "c", mapset = example_mapset)
#'  }
#'
#' if (run) {
#'   # Report basic metadata about the schools dataset
#'   execGRASS("v.info", map = "schools", layer = "1")
#'   print(vInfo("schools"))
#'  }
#'
#' if (run) {
#'   # Read/write as a SpatVector
#'   schs <- read_VECT("schools")
#'   print(summary(schs))
#'  }
#'
#' if (run) {
#'   try({
#'     write_VECT(schs, "newsch", flags = c("o", "overwrite"))
#'   })
#'   schs <- read_VECT("schools", use_gdal_grass_driver = FALSE)
#'  }
#'
#' if (run) {
#'   write_VECT(schs, "newsch", flags = c("o", "overwrite"))
#'   execGRASS("v.info", map = "newsch", layer = "1")
#'  }
#'
#' if (run) {
#'   nschs <- read_VECT("newsch")
#'   print(summary(nschs))
#'  }
#'
#' if (run) {
#'   print(all.equal(names(nschs), as.character(vColumns("newsch")[, 2])))
#'  }
#'
#' if (run) {
#'   # Show metadata for the roadsmajor dataset and read as spatVector
#'   print(vInfo("roadsmajor"))
#'  }
#'
#' if (run) {
#'   roads <- read_VECT("roadsmajor")
#'   print(summary(roads))
#' }
#'
#' # not run: vect2neigh() currently writes 3 new data sources in the PERMANENT
#' # mapset, despite this mapset not being the active one.
#' if (FALSE) {
#'   cen_neig <- vect2neigh("census")
#'   str(cen_neig)
#' }
#'
#' # Cleanup the previously created datasets
#' if (run) {
#'   execGRASS(
#'     "g.remove",
#'     flags = "f",
#'     name = c("newsch", "newsch1"),
#'     type = "vector"
#'   )
#'   execGRASS("g.mapset", mapset = previous_mapset)
#'   if (example_mapset != previous_mapset) {
#'     unlink(file.path(location_path, example_mapset), recursive = TRUE)
#'   }
#' }
#'
#' # Restore environment variable settings
#' Sys.setenv("GRASS_VERBOSE" = GV)
#' set.ignore.stderrOption(ois)
read_VECT <- function(
    vname, layer = "", proxy = FALSE, use_gdal_grass_driver = TRUE, type = NULL,
    flags = "overwrite", Sys_ignore.stdout = FALSE,
    ignore.stderr = get.ignore.stderrOption()) {
  if (!(requireNamespace("terra", quietly = TRUE))) {
    stop("terra required for SpatVector output")
  }
  stopifnot(is.logical(ignore.stderr), !is.na(ignore.stderr))
  stopifnot(is.logical(use_gdal_grass_driver), !is.na(use_gdal_grass_driver))
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- set.echoCmdOption(FALSE)
  }
  stopifnot(length(layer) == 1L)
  if (!missing(layer)) layer <- as.character(layer)
  vinfo <- vInfo(vname)
  types <- names(vinfo)[which(vinfo > 0)]
  if (is.null(type)) {
    if (length(grep("points", types)) > 0) type <- "point"
    if (length(grep("lines", types)) > 0) type <- "line"
    if (length(grep("areas", types)) > 0) type <- "area"
    if (is.null(type)) stop("Vector type not found")
  }
  msp <- get_mapsets()
  # in the v.out.ogr case we won't use vca, but this is done to run the checks
  # on vname anyway:
  vca <- sanitize_layername(
    name = vname,
    type = "vector",
    mapsets = msp,
    ignore.stderr = ignore.stderr
  )
  has_grassraster_drv <- gdal_has_grassraster_driver()

  if (has_grassraster_drv && use_gdal_grass_driver) {
    args <- list(name = vca[1], type = "vector")
    if (length(vca) == 2L) args <- c(args, mapset = vca[2])
    tf <- do.call(generate_header_path, args)
    if (layer == "" && type == "area") {
      layers <- terra::vector_layers(tf)
      # Remove this condition once GDAL-GRASS driver issue
      # has been solved (https://github.com/OSGeo/gdal-grass/issues/46).
      # Then also move the type assignment code (from vInfo) to the
      # v.out.ogr case, where it is used as an argument
      layer <- layers[2]
    }
    # message(
    #   "Will get data source ",
    #   tf,
    #   " (layername ",
    #   ifelse(layer == "", "unknown, will get first layer", layer),
    #   ")"
    # )
    res <- getMethod("vect", "character")(tf, layer, proxy = proxy)

  } else {
    if (layer == "") layer <- "1"
    tf <- tempfile(fileext = ".gpkg", tmpdir = Sys.getenv("RGRASS_TEMPDIR"))
    execGRASS("v.out.ogr",
              flags = flags, input = vname, type = type,
              layer = layer, output = tf, output_layer = vname,
              format = "GPKG", Sys_ignore.stdout = Sys_ignore.stdout,
              ignore.stderr = ignore.stderr
    )
    # message("Reading ", tf)
    res <- getMethod("vect", "character")(tf, proxy = proxy)
  }
  if (!all(getMethod("is.valid", "SpatVector")(res))) {
    res <- getMethod("makeValid", "SpatVector")(res)
  }
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  res
}

#' @rdname read_VECT
#' @order 2
#' @export
write_VECT <- function(x, vname, flags = "overwrite",
                       ignore.stderr = get.ignore.stderrOption()) {
  if (!(requireNamespace("terra", quietly = TRUE))) {
    stop("terra required for SpatVector input")
  }

  stopifnot(is.logical(ignore.stderr), !is.na(ignore.stderr))

  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- set.echoCmdOption(FALSE)
  }

  srcs <- getMethod("sources", "SpatVector")(x)

  if (length(srcs) == 1L) {
    tf <- srcs
  } else {
    tf <- ""
  }

  # exit when the source is a GRASS database layer already:
  if (grepl("[/\\\\]head::[^/\\\\]+$", tf)) {
    grass_layername <- regmatches(
      tf,
      regexpr("(?<=[/\\\\]head::)[^/\\\\]+$", tf, perl = TRUE)
    )
    grass_dsn <- regmatches(
      tf,
      regexpr("(?<=[/\\\\])[^/\\\\]+(?=[/\\\\]head::)", tf, perl = TRUE)
    )
    stop(
      "This SpatVector already links to layer '",
      grass_layername,
      "' of the data source '",
      grass_dsn,
      "' in the GRASS GIS database."
    )
  }

  if (!file.exists(tf)) {
    tf <- tempfile(fileext = ".gpkg", tmpdir = Sys.getenv("RGRASS_TEMPDIR"))
    getMethod("writeVector", c("SpatVector", "character"))(x, filename = tf,
      filetype = "GPKG", options = NULL, overwrite = TRUE)
  }

  type <- NULL
  if (getMethod("geomtype", "SpatVector")(x) == "points") type <- "point"
  if (getMethod("geomtype", "SpatVector")(x) == "lines") type <- "line"
  if (getMethod("geomtype", "SpatVector")(x) == "polygons") type <- "boundary"
  if (is.null(type)) stop("Unknown data class")

  execGRASS("v.in.ogr",
    flags = flags, input = tf, output = vname, type = type,
    ignore.stderr = ignore.stderr
  )

  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
}
