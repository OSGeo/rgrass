# Interpreted GRASS interface functions
# Copyright (c) 2015-22 Roger S. Bivand
#

#' @rdname read_VECT
#' @export
vInfo <- function(vname, layer, ignore.stderr = NULL) {
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- get.echoCmdOption()
    tull <- set.echoCmdOption(FALSE)
  }
  if (is.null(ignore.stderr)) {
    ignore.stderr <- get("ignore.stderr", envir = .GRASS_CACHE)
  }
  stopifnot(is.logical(ignore.stderr))

  if (missing(layer)) layer <- "1"
  layer <- as.character(layer)
  vinfo0 <- execGRASS("v.info",
    flags = "t", map = vname,
    layer = layer, intern = TRUE, ignore.stderr = ignore.stderr
  )

  # fix to avoid locale problems 091022

  vinfo1 <- gsub("=", ":", vinfo0)
  con <- textConnection(vinfo1)
  res <- drop(read.dcf(con))
  close(con)
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  storage.mode(res) <- "integer"
  res
}

#' @rdname read_VECT
#' @export
vColumns <- function(vname, layer, ignore.stderr = NULL) {
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- get.echoCmdOption()
    tull <- set.echoCmdOption(FALSE)
  }
  if (is.null(ignore.stderr)) {
    ignore.stderr <- get("ignore.stderr", envir = .GRASS_CACHE)
  }
  stopifnot(is.logical(ignore.stderr))
  if (missing(layer)) layer <- "1"
  layer <- as.character(layer)
  vinfo0 <- execGRASS("v.info",
    flags = "c", map = vname,
    layer = layer, intern = TRUE, ignore.stderr = ignore.stderr
  )
  vinfo1 <- strsplit(vinfo0, "\\|")
  vinfo2 <- vinfo1[sapply(vinfo1, length) == 2]
  if (length(vinfo1) != length(vinfo2)) {
    warning(
      "vColumns: v.info -c output not in two columns:\n",
      paste(vinfo1[sapply(vinfo1, length) != 2])
    )
  }
  res <- as.data.frame(do.call("rbind", vinfo2))
  names(res) <- c("storageType", "name")
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  res
}

#' @rdname read_VECT
#' @export
vDataCount <- function(vname, layer, ignore.stderr = NULL) {
  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- get.echoCmdOption()
    tull <- set.echoCmdOption(FALSE)
  }
  if (is.null(ignore.stderr)) {
    ignore.stderr <- get("ignore.stderr", envir = .GRASS_CACHE)
  }
  stopifnot(is.logical(ignore.stderr))
  column <- "column" %in% parseGRASS("v.db.select")$pnames
  if (missing(layer)) layer <- "1"
  layer <- as.character(layer)
  parms <- list(map = vname, layer = as.character(layer), columns = "cat")
  if (column) {
    tull <- execGRASS("v.db.select",
      flags = "c",
      parameters = parms, intern = TRUE, ignore.stderr = ignore.stderr
    )
  } else {
    tull <- execGRASS("v.db.select",
      flags = "c",
      parameters = parms, intern = TRUE, ignore.stderr = ignore.stderr
    )
  }
  n <- length(tull)
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }
  n
}


# Date: Thu, 13 Oct 2005 17:34:06 +0200
# From: Markus Neteler <neteler@itc.it>
#
# EXERCISE: HOW LONG ARE COMMON BOUNDARIES OF POLYGONS?
#
#
## Requires: GRASS 6.1-CVS from 13 Oct 2005 or later
##
## data: sudden infant deaths data from North Carolina
## data imported from SHAPE file with v.in.ogr
#
## let's have a look
# d.mon x0
# d.vect sids
#
## we work on a copy:
# g.copy vect=sids,sids_nc
#
## we add a second layer to the map which references the boundaries of
## polygons. In the vector geometry we generate an ID (category) for each
## boundary:
# v.category sids_nc out=sids_nc2 layer=2 type=boundary option=add
#
## Underlying idea:
## we'll fetch the IDs (categories) of the polygons left and right from
## each boundary and store it into the attribute table linked to layer 2.
## In general:
## cat_of_boundary | cat_of_left_polygon | cat_of_right_polygon | length_of_boundary
##
## We want only one category per boundary, that's why the sides check is
## needed (a boundary may consist of several pieces)
##
## So we create a new attribute table and link it to the new layer 2
## of the vector map:
# v.db.addtable sids_nc2 layer=2 col="left integer,right integer,length integer"
#
## Now we query the polygon/boundary relationsships and store it into
## the attribute table linked to layer 2:
# v.to.db map=sids_nc2 option=sides col=left,right layer=2
#
## Now we have unique categories for the boundaries and can calculate the
## lengths:
# v.to.db map=sids_nc2 option=length col=length layer=2
#
## Done.
#
## See the new attribute table containing the boundary lengths:
# v.db.select sids_nc2 layer=2
#
## verification (let's check boundary #193):
# d.vect sids_nc2 cat=193 layer=2 col=red type=boundary
# d.zoom
# d.measure
## LEN:     12756.00 meters
#
## what does the attribute table say:
# v.db.select sids_nc2 layer=2 | grep '^193'
## 190|65|68|12814
#
## This is reasonably close since on screen digitization in d.measure
## isn't always that precise ...
#

#' @rdname read_VECT
#' @export
vect2neigh <- function(
    vname, ID = NULL, ignore.stderr = NULL, remove = TRUE,
    vname2 = NULL, units = "k") {

  if (get.suppressEchoCmdInFuncOption()) {
    inEchoCmd <- get.echoCmdOption()
    tull <- set.echoCmdOption(FALSE)
  }

  if (is.null(ignore.stderr)) {
    ignore.stderr <- get("ignore.stderr", envir = .GRASS_CACHE)
  }
  stopifnot(is.logical(ignore.stderr))

  vinfo <- vInfo(vname)
  types <- names(vinfo)[which(vinfo > 0)]

  if (length(grep("areas", types)) == 0) {
    stop("Vector object not of area type")
  }

  n <- vDataCount(vname, ignore.stderr = ignore.stderr)

  if (!is.null(ID)) {
    if (!is.character(ID)) stop("ID not character string")
    # 		cmd <- paste(paste("v.info", .addexe(), sep=""),
    #                    " -c ", vname, sep="")
    # 		if(.Platform$OS.type == "windows")
    # 			tull <- system(cmd, intern=TRUE)
    # 		else tull <- system(cmd, intern=TRUE,
    # 			ignore.stderr=ignore.stderr)
    tull <- execGRASS("v.info",
      flags = "c",
      map = vname, intern = TRUE,
      ignore.stderr = ignore.stderr
    )
    if (length(grep(ID, tull)) == 0) {
      stop("ID not found")
    }
    # 		cmd <- paste(paste("v.db.select", .addexe(), sep=""),
    #                    " -c map=", vname, " column=",
    # 			ID, sep="")
    # 		if(.Platform$OS.type == "windows")
    # 			ID <- as.character(system(cmd, intern=TRUE))
    # 		else ID <- as.character(system(cmd, intern=TRUE,
    # 			ignore.stderr=ignore.stderr))
    ID <- execGRASS("v.db.select",
      flags = "c",
      map = vname, columns = ID, intern = TRUE,
      ignore.stderr = ignore.stderr
    )
    if (length(unique(ID)) != n) {
      stop("fewer than n unique ID values")
    }
  }
  vname2_was_null <- FALSE

  if (is.null(vname2)) {
    pid <- as.integer(round(runif(1, 1, 1000)))
    vname2 <- paste(vname, pid, sep = "")

    tull <- execGRASS("g.remove",
      type = "vector", name = vname2, flags = "f",
      intern = TRUE, ignore.stderr = ignore.stderr
    )
    # 	cmd <- paste(paste("g.copy", .addexe(), sep=""),
    #                    " vect=", vname, ",", vname2, sep="")
    # 	if(.Platform$OS.type == "windows") tull <- system(cmd, intern=TRUE)
    # 	else tull <- system(cmd, intern=TRUE, ignore.stderr=ignore.stderr)
    tull <- execGRASS("g.copy",
      vector = paste(vname,
        vname2,
        sep = ","
      ), flags = "overwrite", intern = TRUE,
      ignore.stderr = ignore.stderr
    )
    vname2_was_null <- TRUE
  }
  vname2a <- paste(vname2, "a", sep = "")
  if (vname2_was_null) {
    # 	cmd <- paste(paste("v.category", .addexe(), sep=""),
    #                    " ", vname2, " out=", vname2a,
    # 		"  layer=2 type=boundary option=add", sep="")
    # 	if(.Platform$OS.type == "windows") tull <- system(cmd, intern=TRUE)
    # 	else tull <- system(cmd, intern=TRUE, ignore.stderr=ignore.stderr)
    tull <- execGRASS("v.category",
      input = vname2,
      output = vname2a, layer = as.character(2), type = "boundary",
      option = "add", flags = "overwrite", intern = TRUE, ignore.stderr = ignore.stderr
    )

    # 	cmd <- paste(paste("v.db.addtable", .addexe(), sep=""),
    #                    " ", vname2a,
    # 	" layer=2 col=\"left integer,right integer,length double precision\"",
    # 	sep="")
    # 	if(.Platform$OS.type == "windows") system(cmd)
    # 	else system(cmd, ignore.stderr=ignore.stderr)
    execGRASS("v.db.addtable",
      map = vname2a,
      layer = as.integer(2),
      columns = "left integer,right integer,length double precision",
      ignore.stderr = ignore.stderr
    )

    # Using vector map name extended by layer number as table name: landuse175a_2
    # Creating table with columns (cat integer, left integer,right integer,length
    # double precision)
    # The table <landuse175a_2> is now part of vector map <landuse175a> and may
    # be deleted or overwritten by GRASS modules
    # Select privileges were granted on the table
    # Reading features...
    #
    # and: no such driver available
    # WARNING: Unable to start driver <and>
    # ERROR: Unable to open database <C:\Documents> by driver <and>
    # Current attribute table links:
    # layer <1> table <landuse175a> in database <C:\Documents and Settings\s1155\My Documents\GIS DataBase/Spearfish60/s1155/dbf/> through driver <dbf> with key <cat>
    # layer <2> table <landuse175a_2> in database <C:\Documents> through driver <and> with key <cat>
    # Vector map <landuse175a@s1155> is connected by:


    # 	cmd <- paste(paste("v.to.db", .addexe(), sep=""),
    #                    " map=", vname2a,
    # 		" option=sides col=left,right layer=2", sep="")
    # 	if(.Platform$OS.type == "windows") system(cmd)
    # 	else system(cmd, ignore.stderr=ignore.stderr)
    execGRASS("v.to.db",
      flags = c("overwrite"), map = vname2a, option = "sides",
      columns = "left,right", layer = as.character(2),
      ignore.stderr = ignore.stderr
    )

    # 	cmd <- paste(paste("v.to.db", .addexe(), sep=""),
    #                    " map=", vname2a,
    # 		" option=length col=length layer=2", sep="")
    # 	if(.Platform$OS.type == "windows") system(cmd)
    # 	else system(cmd, ignore.stderr=ignore.stderr)
    execGRASS("v.to.db",
      flags = c("overwrite"), map = vname2a, option = "length",
      columns = "length", layer = as.character(2), units = units,
      ignore.stderr = ignore.stderr
    )

    # 	cmd <- paste(paste("v.db.select", .addexe(), sep=""),
    #                    " ", vname2a, " layer=2", sep="")
    #
    # 	if(.Platform$OS.type == "windows") res <- system(cmd, intern=TRUE)
    # 	else res <- system(cmd, intern=TRUE, ignore.stderr=ignore.stderr)
  }
  res <- execGRASS("v.db.select",
    map = vname2a,
    layer = as.character(2), flags = "overwrite", intern = TRUE,
    ignore.stderr = ignore.stderr
  )

  # 	cmd <- paste(paste("g.remove", .addexe(), sep=""),
  #                    " vect=", vname2, ",", vname2a, sep="")
  # 	if(.Platform$OS.type == "windows") tull <- system(cmd, intern=TRUE)
  # 	else tull <- system(cmd, intern=TRUE, ignore.stderr=ignore.stderr)
  if (remove) {
    tull <- execGRASS("g.remove",
      name = paste(vname2, vname2a, sep = ","), type = "vector",
      intern = TRUE, ignore.stderr = ignore.stderr, flags = "f"
    )
  }

  con <- textConnection(res)
  t2 <- read.table(con, sep = "|", header = TRUE, row.names = 1)
  close(con)
  t3 <- t2[t2$left == -1, ]
  t4 <- tapply(t3$length, t3$right, sum)
  external <- numeric(n)
  external[as.integer(names(t4))] <- t4
  t5 <- t2[!t2$left == -1, ]
  tmp <- t5$left
  t5$left <- t5$right
  t5$right <- tmp
  t6 <- rbind(t2, t5)
  total <- c(tapply(t6$length, t6$right, sum))
  res <- t6[!t6$left == -1, ]
  #       avoid integer overflow in by=
  # 	res <- aggregate(res[3], by=list(left=res$left, right=res$right), sum)
  #        dups <- duplicated(res[,1:2])
  #        resd <- res[dups,]
  #        resda <- aggregate(resd[3], by=list(left=resd$left,
  #            right=resd$right), sum)
  #        resnd <- res[!dups,]
  #        res <- rbind(resda, resnd)
  zz <- paste(res$left, res$right, sep = ":")
  uzz <- unique(zz)
  mo <- match(zz, uzz)
  smo <- c(tapply(res[, 3], mo, sum))
  names(smo) <- NULL
  suzz <- strsplit(uzz, ":")
  lsuzz <- as.integer(sapply(suzz, "[", 1))
  rsuzz <- as.integer(sapply(suzz, "[", 2))
  reso <- data.frame(left = lsuzz, right = rsuzz, length = smo)
  o <- order(reso$left, reso$right)
  reso <- reso[o, ]
  attr(reso, "external") <- external
  attr(reso, "total") <- total
  attr(reso, "region.id") <- ID
  attr(reso, "n") <- n
  class(reso) <- c(class(reso), "GRASSneigh", "spatial.neighbour")
  if (get.suppressEchoCmdInFuncOption()) {
    tull <- set.echoCmdOption(inEchoCmd)
  }

  reso
}
