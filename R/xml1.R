#' @rdname execGRASS
#' @order 4
#' @export
parseGRASS <- function(cmd, legacyExec = NULL) {
  cmdCACHE <- get("cmdCACHE", envir = .GRASS_CACHE)
  res <- cmdCACHE[[cmd]]
  if (is.null(legacyExec)) {
    legacyExec <- get.legacyExecOption()
  }
  stopifnot(is.logical(legacyExec))
  if (get("SYS", envir = .GRASS_CACHE) != "unix" && !legacyExec) {
    warning("legacyExec set TRUE on non-unix platform")
    legacyExec <- TRUE
  }
  if (is.null(res)) {
    ext <- get("addEXE", envir = .GRASS_CACHE)
    WN_bat <- get("WN_bat", envir = .GRASS_CACHE)
    if (get("SYS", envir = .GRASS_CACHE) == "WinNat" &&
      (length(WN_bat) == 1L && nchar(WN_bat) == 0)) {
      WN_bat <- sub(
        ".bat", "",
        list.files(paste(Sys.getenv("GISBASE"), "bin", sep = "/"),
          pattern = ".bat$"
        )
      )
      if (nchar(Sys.getenv("GRASS_ADDON_BASE")) > 0) {
        t0 <- try(sub(
          ".bat", "",
          list.files(paste(Sys.getenv("GRASS_ADDON_BASE"),
            "bin",
            sep = "/"
          ), pattern = ".bat$")
        ), silent = TRUE)
        if (length(t0) > 0 && !inherits(t0, "try-error") &&
          is.character(t0) && all(nchar(t0) > 0)) {
          WN_bat <- c(WN_bat, t0)
        }
      }
      assign("WN_bat", WN_bat, envir = .GRASS_CACHE)
    }
    prep <- ""
    if ((get("SYS", envir = .GRASS_CACHE) == "WinNat") &&
      cmd %in% get("WN_bat", envir = .GRASS_CACHE)) {
      ext <- ".bat"
    }

    cmd0 <- paste(paste(prep, cmd, ext, sep = ""), "--interface-description")
    if (legacyExec) {
      tr <- try(system(cmd0, intern = TRUE))
      if (inherits(tr, "try-error")) stop(paste(cmd, "not found"))
    } else {
      errFile <- tempfile()
      outFile <- tempfile()
      command <- paste(prep, cmd, ext, sep = "")
      arguments <- "--interface-description"
      res <- system2(
        command = command, args = arguments, stdout = outFile,
        stderr = errFile
      )
      resErr <- readLines(errFile)
      if (res == 127L) {
        stop(
          "The command\n", "   ", command, " ", arguments,
          "\ncould not be run (", res,
          "), and produced the error message:\n", "   ", resErr
        )
      } else if (res == 1L) {
        stop(
          "The command\n", "   ", command, " ", arguments,
          "\nproduced an error (", res,
          ") during execution:\n", "   ", resErr
        )
      }
      tr <- readLines(outFile)
    }
    tr <- paste(tr, collapse = " ")
    enc <- get("override_encoding", envir = .GRASS_CACHE)
    if (nchar(enc) > 0) {
      #          if (length(grep("UTF-8", tr[1])) > 0) {
      #            tr[1] <- sub("UTF-8", enc, tr[1])
      #          }
      tr <- try(xml2::read_xml(tr, encoding = enc))
    } else {
      tr <- try(xml2::read_xml(tr))
    }
    #        tr <- try(xmlTreeParse(tr))
    if (inherits(tr, "try-error")) stop(paste(cmd, "not parsed"))
    tr1 <- xml2::xml_contents(xml2::xml_root(tr))
    #        tr1 <- xmlChildren(xmlRoot(tr))
    res <- vector(mode = "list", length = 9)
    names(res) <- c(
      "cmd", "description", "keywords", "parameters", "flags",
      "pnames", "fnames", "ext", "prep"
    )
    res$cmd <- cmd
    res$ext <- ext
    res$prep <- prep
    #        res$description <- xmlValue(tr1[[1]])
    if (is.na(match("description", xml_name(tr1)))) {
      res$description <- xml_text(tr1[[match("label", xml_name(tr1))]],
        trim = TRUE
      )
    } else if (is.na(match("label", xml_name(tr1)))) {
      res$description <- xml_text(tr1[[match(
        "description",
        xml_name(tr1)
      )]], trim = TRUE)
    } else {
      res$description <- paste0(xml_text(tr1[[match(
        "label",
        xml_name(tr1)
      )]], trim = TRUE), " ", xml_text(tr1[[match(
        "description", xml_name(tr1)
      )]], trim = TRUE))
    }
    #        res$keywords <- xmlValue(tr1[[2]])
    res$keywords <- xml_text(tr1[[match("keywords", xml_name(tr1))]], trim = TRUE)
    #        o0 <- names(tr1)
    o0 <- xml2::xml_name(tr1)
    pseq <- which(o0 == "parameter")
    np <- length(pseq)
    ps <- vector(mode = "list", length = np)
    for (i in seq(along = pseq)) {
      obj <- tr1[[pseq[i]]]
      onms <- xml2::xml_name(xml2::xml_contents(obj))
      #            pv <- xmlAttrs(obj)
      pv <- xml2::xml_attrs(obj)
      #            pvCh <- xmlChildren(obj)
      #            pv <- c(pv, xmlValue(pvCh[["description"]]))
      pv <- c(pv, xml2::xml_text(xml2::xml_child(obj, "description"), trim = TRUE))
      #            default <- pvCh[["default"]]
      #            if (is.null(default)) {
      if (!("default" %in% onms)) {
        strdef <- as.character(NA)
      } else {
        strdef <- xml2::xml_text(xml2::xml_child(obj, "default"), trim = TRUE)
        if (length(strdef) == 0) strdef <- ""
      }
      pv <- c(pv, strdef)
      #            kd <- pvCh[["keydesc"]]
      #            if (is.null(kd)) {
      if (!("keydesc" %in% onms)) {
        nkd <- as.integer(NA)
        strkd <- as.character(NA)
      } else {
        #                kda <- xmlApply(kd, xmlValue)
        kda <- xml2::xml_child(obj, "keydesc")
        kda <- xml2::xml_text(xml2::xml_children(kda), trim = TRUE)
        nkd <- length(kda)
        strkd <- paste(sapply(kda, c), collapse = ",")
      }
      pv <- c(pv, nkd, strkd)
      #            names(pv) <- c(names(xmlAttrs(obj)), "desc", "default",
      names(pv) <- c(
        names(xml2::xml_attrs(obj)), "desc", "default",
        "keydesc_count", "keydesc"
      )
      ps[[i]] <- pv
    }
    res$parameters <- ps
    fseq <- which(o0 == "flag")
    nf <- length(fseq)
    fs <- vector(mode = "list", length = nf)
    for (i in seq(along = fseq)) {
      obj <- tr1[[fseq[i]]]
      #            fv <- xmlAttrs(obj)
      fv <- xml2::xml_attrs(obj)
      # find description, don't assume first place 101206
      #            nobj <- sapply(xmlChildren(obj), xmlName)
      #            di <- match("description", nobj)
      #            fv <- c(fv, xmlValue(xmlChildren(obj)[[di]]))
      fv <- c(fv, xml2::xml_text(xml2::xml_child(obj, "description"), trim = TRUE))
      #            suppr_req <- as.character("suppress_required" %in% nobj)
      suppr_req <- as.character(!(is.na(xml2::xml_child(obj, "suppress_required"))))
      fv <- c(fv, suppr_req)
      #            names(fv) <- c(names(xmlAttrs(obj)), "desc", "suppr_req")
      names(fv) <- c(names(xml2::xml_attrs(obj)), "desc", "suppr_req")
      fs[[i]] <- fv
    }
    res$flags <- fs
    res$pnames <- sapply(res$parameters, function(x) x["name"])
    names(res$pnames) <- NULL
    res$fnames <- sapply(res$flags, function(x) x["name"])
    names(res$fnames) <- NULL
    class(res) <- "GRASS_interface_desc"
    cmdCACHE[[cmd]] <- res
    assign("cmdCACHE", cmdCACHE, envir = .GRASS_CACHE)
  }
  res
}

#' @rdname execGRASS
#' @param enc character string to replace UTF-8 in header of XML data generated
#'   by GRASS module –interface-description output when the internationalised
#'   messages are not in UTF-8 (known to apply to French, which is in latin1)
#' @order 7
#' @export
setXMLencoding <- function(enc) {
  if (!is.character(enc) || length(enc) > 1) {
    stop("enc must be a character string")
  }
  invisible(assign("override_encoding", enc, envir = .GRASS_CACHE))
}

#' @rdname execGRASS
#' @order 6
#' @export
getXMLencoding <- function() {
  get("override_encoding", envir = .GRASS_CACHE)
}

#' @rdname execGRASS
#' @param x object to be printed
#' @order 5
#' @export
print.GRASS_interface_desc <- function(x, ...) {
  cat("Command:", x$cmd, "\n")
  if (nchar(x$ext) > 0) cat("Extension:", x$ext, "\n")
  if (nchar(x$prep) > 0) cat("Shell prefix:", x$prep, "\n")
  cat("Description:", x$description, "\n")
  cat("Keywords:", x$keywords, "\n")
  cat("Parameters:\n")
  for (i in x$parameters) {
    cat("  name: ", i["name"], ", type: ",
      i["type"], ", required: ", i["required"], ", multiple: ",
      i["multiple"], "\n",
      sep = ""
    )
    if (!is.na(i["default"])) {
      cat("  default: ", i["default"],
        "\n",
        sep = ""
      )
    }
    if (!is.na(i["keydesc"])) {
      cat("  keydesc: ", i["keydesc"],
        ", keydesc_count: ", i["keydesc_count"], "\n",
        sep = ""
      )
    }
    cat("[", i["desc"], "]\n", sep = "")
  }
  cat("Flags:\n")
  for (i in x$flags) {
    cat("  name: ", i["name"], " [",
      i["desc"], "] {", i["suppr_req"], "}\n",
      sep = ""
    )
  }
  invisible(x)
}

#' @rdname execGRASS
#' @order 3
#' @export
doGRASS <- function(cmd, flags = NULL, ..., parameters = NULL, echoCmd = NULL, legacyExec = NULL) {
  defFlags <- get.defaultFlagsOption()
  if (!is.null(defFlags)) flags <- unique(c(flags, defFlags))
  if (all(c("quiet", "verbose") %in% flags)) {
    flags <- flags[flags != "quiet"]
  }
  if (!is.null(flags)) stopifnot(is.character(flags))
  if (!is.null(parameters)) stopifnot(is.list(parameters))
  if (is.null(echoCmd)) {
    echoCmd <- get("echoCmd", envir = .GRASS_CACHE)
  }
  stopifnot(is.logical(echoCmd))
  if (is.null(legacyExec)) {
    legacyExec <- get.legacyExecOption()
  }
  stopifnot(is.logical(legacyExec))
  if (get("SYS", envir = .GRASS_CACHE) != "unix" && !legacyExec) {
    warning("legacyExec set TRUE on non-unix platform")
    legacyExec <- TRUE
  }

  #    G6 <- get("GV", envir=.GRASS_CACHE) < "GRASS 7"

  dlist <- list(...)
  if (!is.null(parameters) && (length(dlist) > 0)) {
    stop(paste("Use either GRASS parameters as R arguments,",
      "or as a parameter argument list object, but not both",
      sep = "\n"
    ))
  }
  if (is.null(parameters) && (length(dlist) > 0)) parameters <- dlist
  pcmd <- parseGRASS(cmd, legacyExec = legacyExec)
  cmd <- paste(pcmd$prep, cmd, pcmd$ext, sep = "")
  res <- cmd
  suppress_required <- FALSE
  if (!is.null(flags)) {
    fm <- match(flags, pcmd$fnames)
    if (any(is.na(fm))) {
      stop(paste(pcmd, "\nInvalid flag value:", flags[is.na(fm)]))
    }
    suppr_req <- as.logical(sapply(pcmd$flags, "[", "suppr_req"))
    if (!suppress_required && any(suppr_req[fm])) suppress_required <- TRUE
    dble_dash <- c("verbose", "overwrite", "quiet")
    dbm <- na.omit(match(dble_dash, flags))
    if (length(dbm) > 0) flags[dbm] <- paste("-", flags[dbm], sep = "")
    res <- paste(res, paste("-", flags, collapse = " ", sep = ""))
  }
  pt <- do.call("rbind", pcmd$parameters)
  req <- NULL
  if (!is.null(pt)) {
    # g.version no parameters exception caught by Rainer M Krug 090923
    req <- pt[pt[, "required"] != "no", "name"]
    # patch for multiple values Patrick Caldon 090524
    #      mult <- pt[pt[, "multiple"] != "no", "name"]
    # patch to accept no or multiple keydesc_count 090902
    mults <- pt[, "multiple"] != "no" | (!is.na(pt[, "keydesc_count"]) &
      pt[, "keydesc_count"] > 1)
    mult <- pt[mults, "name"]
    parameters <- insert_required(
      pcmd = pcmd, parameters = parameters,
      pt = pt, req = req, suppress_required = suppress_required
    )
    if (!suppress_required && length(req) > 0 && is.null(parameters)) {
      stop(paste(pcmd, "\nNo parameters given where some are required with defaults declared"))
    }
    if (!is.null(parameters)) {
      parnms <- names(parameters)
      pm <- match(parnms, pcmd$pnames)
      if (any(is.na(pm))) {
        stop(paste(pcmd, "\nInvalid parameter name:", parnms[is.na(pm)]))
      }
      if (!suppress_required && length(req) > 0) {
        pmr <- match(req, parnms)
        if (any(is.na(pmr))) {
          stop(paste(pcmd, "\nMissing required parameter:", req[is.na(pmr)]))
        }
      }
      pmv <- pt[pm, "type"]
      # patch for multiple values Patrick Caldon 090524
      pmmult <- match(mult, parnms)
      for (i in seq(along = parameters)) {
        # patch for multiple values Patrick Caldon 090524
        if (length(parameters[[i]]) > 1 && !(i %in% pmmult)) {
          stop(paste("Parameter <", names(parameters)[i],
            "> has multiple values",
            sep = ""
          ))
        }
        if (pmv[i] == "string") {
          if (!is.character(parameters[[i]])) {
            stop(paste("Parameter <", names(parameters)[i],
              "> does not have string value",
              sep = ""
            ))
          }
          # added any() 140516
          if (any(is.na(parameters[[i]]))) {
            stop(paste("Parameter <", names(parameters)[i],
              "> is NA",
              sep = ""
            ))
          }
          # string space protection 091108 Martin Mainzer
          Space <- length(grep(" ", parameters[[i]])) > 0
          # Rainer Krug 110128
          Paran <- length(grep("\\(", parameters[[i]])) > 0 ||
            length(grep(")", parameters[[i]])) > 0
          if (Space || Paran) {
            # extra protection against existing escaping of quotes 100422
            if (length(grep("\"", parameters[[i]])) == 0) {
              parameters[[i]] <- paste("\"", parameters[[i]], "\"",
                sep = ""
              )
            }
          }
        } else if (pmv[i] == "float") {
          if (!is.numeric(parameters[[i]])) {
            stop(paste("Parameter <", names(parameters)[i],
              "> does not have numeric value",
              sep = ""
            ))
          }
          if (any(!is.finite(parameters[[i]]))) {
            stop(paste("Parameter <", names(parameters)[i],
              "> is not finite",
              sep = ""
            ))
          }
        } else if (pmv[i] == "integer") {
          if (!is.numeric(parameters[[i]])) {
            stop(paste("Parameter <", names(parameters)[i],
              "> does not have numeric value",
              sep = ""
            ))
          }
          if (any(!is.finite(parameters[[i]]))) {
            stop(paste("Parameter <", names(parameters)[i],
              "> is not finite",
              sep = ""
            ))
          }
          if (!is.integer(parameters[[i]])) {
            opi <- parameters[[i]]
            if (all(as.integer(opi) == opi)) {
              parameters[[i]] <- as.integer(opi)
            } else {
              stop(paste("Parameter <", names(parameters)[i],
                "> is not integer",
                sep = ""
              ))
            }
          }
        } else {
          warning("unknown parameter type")
        }
        # patch for multiple values Patrick Caldon 090524
        param <- paste(parameters[[i]], collapse = ",")
        res <- paste(res, paste(names(parameters)[i], param,
          sep = "="
        ))
      }
    }
  }
  if (length(req) > 0) {
    if ((!is.null(pt) && is.null(parameters)) && is.null(flags)) {
      if (get.stop_on_no_flags_parasOption()) {
        stop("No flags or parameters provided")
      } else {
        warning("No flags or parameters provided")
      }
    }
  }
  if (echoCmd) cat("GRASS command:", res, "\n")
  attr(res, "cmd") <- cmd
  res
}

insert_required <- function(pcmd, parameters, pt, req, suppress_required) {
  defs <- pt[match(req, pt[, "name"]), "default"]
  nadefs <- which(is.na(defs))
  nms <- pt[match(req, pt[, "name"]), "name"]
  nadefnms <- nms[nadefs]
  pnms <- names(parameters)
  nadefnms1 <- nadefnms[is.na(match(nadefnms, pnms))]
  if (!suppress_required && length(nadefnms1) > 0) {
    stop(paste(
      pcmd, "\nrequired parameters with no defaults missing:",
      paste(nadefnms1, collapse = " ")
    ))
  }
  types <- pt[match(req, pt[, "name"]), "type"]
  defnms <- nms[!is.na(defs)]
  deftypes <- types[!is.na(defs)]
  defdefs <- defs[!is.na(defs)]
  if (is.null(parameters)) parameters <- list()
  for (i in seq(along = defnms)) {
    if (!(defnms[i] %in% pnms)) {
      parameters[[defnms[i]]] <- switch(deftypes[i],
        integer = as.integer(defdefs[i]),
        float = as.numeric(defdefs[i]),
        string = defdefs[i]
      )
    }
  }
  if (length(parameters) == 0) parameters <- NULL
  parameters
}

#' Run GRASS commands
#'
#' The functions provide an interface to GRASS commands run through
#' `system`, based on the values returned by the `--interface description`
#' flag using XML parsing. If required parameters are omitted, and
#' have declared defaults, the defaults will be used.
#'
#' @details
#' `parseGRASS` checks to see whether the GRASS command has been parsed
#' already and cached in this session; if not, it reads the interface
#' description, parses it and caches it for future use. `doGRASS` assembles
#' a proposed GRASS command with flags and parameters as a string, wrapping
#' `parseGRASS`, and `execGRASS` is a wrapper for `doGRASS`,
#' running the command through `system` (from 0.7-4, the `...`
#' argument is not used for passing extra arguments for `system`). The
#' command string is termed proposed, because not all of the particular needs of
#' commands are provided by the interface description, and no check is made for
#' the existence of input objects. Support for multiple parameter values added
#' with help from Patrick Caldon. Support for defaults and for direct use of
#' GRASS parameters instead of a parameter list suggested by Rainer Krug.
#'
#' `stringexecGRASS` is a wrapper around `execGRASS`, and accepts a
#' single shell statement as a string (following GRASS's command syntax).
#'
#' @note
#' If any package command fails with a UTF-8 error from the XML package, try
#' using `setXMLencoding` to work around the problem that GRASS modules
#' declare --interface-description output as UTF-8 without ensuring that it is
#' (French is of 6.4.0 RC5 latin1).
#'
#' @author Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>
#' @seealso [base::system()]
#' @keywords spatial
#' @order 1
#'
#' @param cmd GRASS command name.
#' @param flags character vector of GRASS command flags.
#' @param ... for `execGRASS` and `doGRASS`, GRASS module parameters
#'   given as R named arguments directly. For the `print` method, other
#'   arguments to print method. The storage modes of values passed must match
#'   those required in GRASS, so a single GRASS string must be a character vector
#'   of length 1, a single GRASS integer must be an integer vector of length 1
#'   (may be an integer constant such as 10L), and a single GRASS float must be
#'   a numeric vector of length 1. For multiple values, use vectors of suitable
#'   length.
#' @param parameters list of GRASS command parameters, used if GRASS parameters
#'   are not given as R arguments directly; the two methods for passing GRASS
#'   parameters may not be mixed. The storage modes of values passed must match
#'   those required in GRASS, so a single GRASS string must be a character vector
#'   of length 1, a single GRASS integer must be an integer vector of length 1
#'   (may be an integer constant such as 10L), and a single GRASS float must be
#'   a numeric vector of length 1. For multiple values, use vectors of suitable
#'   length.
#' @param intern default NULL, in which case set internally from
#'   `get.useInternOption`; a logical (not 'NA') which indicates whether to
#'   make the output of the command an R object. Not available unless 'popen' is
#'   supported on the platform.
#' @param ignore.stderr default NULL, taking the value set by
#'   `set.ignore.stderrOption`, a logical indicating whether error messages
#'   written to 'stderr' should be ignored.
#' @param Sys_ignore.stdout,Sys_wait,Sys_input pass extra arguments to
#'   `system`.
#' @param Sys_show.output.on.console,Sys_minimized,Sys_invisible pass extra
#'   arguments to `system` on Windows systems only.
#' @param echoCmd default NULL, taking the logical value set by
#'   `set.echoCmdOption`, print GRASS command to be executed to console.
#' @param redirect default `FALSE`, if `TRUE`, add "2>&1" to
#'   the command string and set `intern` to `TRUE`; only used in
#'   legacy mode.
#' @param legacyExec default NULL, taking the logical value set by
#'   `set.legacyExecOption` which is initialised to `FALSE` on
#'   "unix" platforms and `TRUE` otherwise. If `TRUE`, use
#'   `system`, if `FALSE` use `system2` and divert stderr to
#'   temporary file to record error messages and warnings from GRASS modules.
#'
#' @return `parseGRASS` returns a `GRASS_interface_desc` object,
#'   `doGRASS` returns a character string with a proposed GRASS command -
#'   the expanded command name is returned as an attribute, and `execGRASS`
#'   and  `stringexecGRASS` return what `system` or `system2`
#'   return, particularly depending on the `intern` argument when the
#'   character strings output by GRASS modules are returned.
#'
#'   If `intern` is `FALSE`, `system` returns the module exit
#'   code, while `system2` returns the module exit code with
#'   "resOut" and "resErr" attributes.
#' @export
#'
#' @examples
#' # Run examples if in an active GRASS session in the nc_basic_spm_grass7
#' Sys.setenv("_SP_EVOLUTION_STATUS_" = "2")
#' run <- FALSE
#' GISRC <- Sys.getenv("GISRC")
#' if (nchar(GISRC) > 0) {
#'   location_name <- read.dcf(GISRC)[1, "LOCATION_NAME"]
#'   if (location_name == "nc_basic_spm_grass7") {
#'     run <- TRUE
#'   }
#' }
#'
#' # Save and set echo command option
#' echoCmdOption <- get.echoCmdOption()
#' set.echoCmdOption(TRUE)
#'
#' if (run) {
#'   # Read and print GRASS interface description for 'r.slope.aspect'
#'   print(parseGRASS("r.slope.aspect"))
#'
#'   # Assemble the 'r.slope.aspect' command with specified parameters as a string
#'   doGRASS(
#'     "r.slope.aspect",
#'     flags = c("overwrite"),
#'     elevation = "elevation.dem",
#'     slope = "slope",
#'     aspect = "aspect"
#'   )
#'
#'   # Alternatively, specify parameters as a list
#'   params <- list(elevation = "elevation",
#'                  slope = "slope",
#'                  aspect = "aspect")
#'   doGRASS("r.slope.aspect",
#'           flags = c("overwrite"),
#'           parameters = params)
#'
#'   # Read and print GRASS interface description for 'r.buffer'
#'   print(parseGRASS("r.buffer"))
#'
#'   # Assemble the 'r.buffer' with specified parameters as as string
#'   doGRASS(
#'     "r.buffer",
#'     flags = c("overwrite"),
#'     input = "schools",
#'     output = "bmap",
#'     distances = seq(1000, 15000, 1000)
#'   )
#'
#'   # Alternatively, specify parameters as a list
#'   params <- list(
#'     input = "schools",
#'     output = "bmap",
#'     distances = seq(1000, 15000, 1000)
#'   )
#'   doGRASS("r.buffer", flags = c("overwrite"), parameters = params)
#'
#'   # Restore original echo command option
#'   set.echoCmdOption(echoCmdOption)
#'
#'   # Try executing 'r.stats' command which will fail because "fire_blocksgg"
#'   # does not exist in the mapset
#'   try(res <- execGRASS("r.stats", input = "fire_blocksgg", flags = c("C", "n")),
#'       silent = FALSE)
#'
#'   # Execute 'r.stats' with legacyExec and print the result
#'   res <- execGRASS(
#'     "r.stats",
#'     input = "fire_blocksgg",
#'     flags = c("C", "n"),
#'     legacyExec = TRUE
#'   )
#'   print(res)
#'
#'   # If the command failed, retrieve error message
#'   if (res != 0) {
#'     resERR <- execGRASS(
#'       "r.stats",
#'       input = "fire_blocksgg",
#'       flags = c("C", "n"),
#'       redirect = TRUE,
#'       legacyExec = TRUE
#'     )
#'     print(resERR)
#'   }
#'
#'   # Use 'stringexecGRASS' to run a command and print the result
#'   res <- stringexecGRASS("r.stats -p -l input=geology", intern = TRUE)
#'   print(res)
#'
#'   stringexecGRASS(
#'     "r.random.cells --overwrite --quiet output=samples distance=1000 ncells=100 seed=1"
#'   )
#'
#'   # Alternatively, run the same command using 'execGRASS'
#'   execGRASS(
#'     "r.random.cells",
#'     flags  = c("overwrite", "quiet"),
#'     output = "samples",
#'     distance = 1000,
#'     ncells = 100L,
#'     seed = 1L
#'   )
#' }
execGRASS <- function(
    cmd, flags = NULL, ..., parameters = NULL, intern = NULL,
    ignore.stderr = NULL, Sys_ignore.stdout = FALSE, Sys_wait = TRUE,
    Sys_input = NULL, Sys_show.output.on.console = TRUE, Sys_minimized = FALSE,
    Sys_invisible = TRUE, echoCmd = NULL, redirect = FALSE, legacyExec = NULL) {
  if (is.null(ignore.stderr)) {
    ignore.stderr <- get.ignore.stderrOption()
  }
  stopifnot(is.logical(ignore.stderr))
  if (is.null(intern)) {
    intern <- get.useInternOption()
  }
  stopifnot(is.logical(intern))
  if (is.null(legacyExec)) {
    legacyExec <- get.legacyExecOption()
  }
  stopifnot(is.logical(legacyExec))
  if (get("SYS", envir = .GRASS_CACHE) != "unix" && !legacyExec) {
    warning("legacyExec set TRUE on non-unix platform")
    legacyExec <- TRUE
  }

  syscmd <- doGRASS(cmd,
    flags = flags, ..., parameters = parameters,
    echoCmd = echoCmd, legacyExec = legacyExec
  )
  if (legacyExec) {
    if (redirect) {
      syscmd <- paste(syscmd, "2>&1")
      intern <- TRUE
    }
    if (get("SYS", envir = .GRASS_CACHE) == "unix") {
      res <- system(syscmd,
        intern = intern, ignore.stderr = ignore.stderr,
        ignore.stdout = Sys_ignore.stdout, wait = Sys_wait, input = Sys_input
      )
    } else {
      res <- system(syscmd,
        intern = intern, ignore.stderr = ignore.stderr,
        ignore.stdout = Sys_ignore.stdout, wait = Sys_wait, input = Sys_input,
        show.output.on.console = Sys_show.output.on.console,
        minimized = Sys_minimized, invisible = Sys_invisible
      )
    }
    if (intern) {
      return(res)
    }
  } else {
    command <- attr(syscmd, "cmd")
    arguments <- substring(syscmd, (nchar(command) + 2), nchar(syscmd))

    errFile <- tempfile(fileext = ".err")
    outFile <- tempfile(fileext = ".out")

    res <- system2(command, arguments,
      stderr = errFile,
      stdout = outFile, wait = Sys_wait, input = Sys_input
    )

    resErr <- readLines(errFile)
    if (res == 127L) {
      stop(
        "The command:\n", command, " ", arguments,
        "\ncould not be run (", res,
        "), and produced the error message:\n",
        paste(resErr, collapse = "\n")
      )
    } else if (res == 1L) {
      stop(
        "The command:\n", command, " ", arguments,
        "\nproduced an error (", res,
        ") during execution:\n", paste(resErr, collapse = "\n")
      )
    } else if (res == 0L & !ignore.stderr) {
      if (length(grep("ERROR:", resErr)) > 0) {
        stop(
          "The command:\n", command, " ", arguments,
          "\nproduced an error (", res,
          ") during execution:\n",
          paste(resErr, collapse = "\n")
        )
      } else if (length(grep("WARNING:", resErr)) > 0) {
        warning(
          "The command:\n", command, " ", arguments,
          "\nproduced at least one warning during execution:\n",
          paste(resErr, collapse = "\n")
        )
      }
    }

    resOut <- readLines(outFile)
    if (intern) {
      return(resOut)
    }

    if (length(resOut) > 0 && !Sys_ignore.stdout) cat(resOut, sep = "\n")
    if (length(resErr) > 0 && !ignore.stderr) cat(resErr, sep = "\n")

    attr(res, "resOut") <- resOut
    attr(res, "resErr") <- resErr
  }
  if (cmd == "g.gui") message("WX GUI launched - Close GUI manually when finished")
  invisible(res)
}

#' @rdname execGRASS
#' @param string a string representing *one* full GRASS statement, using shell
#'   syntax: command name, optionally followed by flags and parameters, all
#'   separated by whitespaces. Parameters follow the key=value format; if
#'   ’value’ contains spaces, then ’value’ must be quoted
#' @order 2
#' @export
stringexecGRASS <- function(string,
                            intern = NULL,
                            ignore.stderr = NULL,
                            Sys_ignore.stdout = FALSE,
                            Sys_wait = TRUE,
                            Sys_input = NULL,
                            Sys_show.output.on.console = TRUE,
                            Sys_minimized = FALSE,
                            Sys_invisible = TRUE,
                            echoCmd = NULL,
                            redirect = FALSE,
                            legacyExec = NULL) {
  stopifnot(is.character(string) && length(string) == 1)
  # extract quoted parameters
  quoted_params <- regmatches(
    string,
    gregexpr("\\w+=['\"].*?['\"]", string)
  )[[1]]
  if (length(quoted_params) > 0) {
    names(quoted_params) <- regmatches(
      quoted_params,
      regexpr("^\\w+", quoted_params)
    )
    quoted_params <- regmatches(
      quoted_params,
      regexpr("(?<==['\"]).+(?=['\"]$)",
        quoted_params,
        perl = TRUE
      )
    )
    quoted_params <- as.list(quoted_params)
  }
  # split remaining parts into cmd, flags and simple parameters
  components <- strsplit(gsub("\\w+=['\"].*?['\"]", "", string), "\\s+")[[1]]
  cmd <- components[1]
  if (!grepl("^\\w{1,2}\\.\\w+(\\.\\w+)*$", cmd)) {
    stop(
      "The string argument of stringexecGRASS() ",
      "must begin with a valid GRASS command name."
    )
  }
  pattern_flag <- "^-+"
  flags <- grep(pattern_flag, components, value = TRUE)
  if (length(flags) > 0) {
    flags <- sub(pattern_flag, "", flags)
  } else {
    flags <- NULL
  }
  simple_params <- grep("^\\w+=", components, value = TRUE)
  if (length(simple_params) > 0) {
    names(simple_params) <- regmatches(
      simple_params,
      regexpr("^\\w+", simple_params)
    )
    simple_params <- regmatches(
      simple_params,
      regexpr("(?<==).+$",
        simple_params,
        perl = TRUE
      )
    )
    simple_params <- as.list(simple_params)
    simple_params[grep("^[+-]?(\\d*\\.)?\\d+$", simple_params)] <-
      as.numeric(simple_params[grep("^[+-]?(\\d*\\.)?\\d+$", simple_params)])
  }
  # combine simple and quoted parameters
  if (length(simple_params) > 0 || length(quoted_params) > 0) {
    parameters <- c(simple_params, quoted_params)
  } else {
    parameters <- NULL
  }
  # non-processed parts of 'components' will lead to an error
  if (length(flags) + length(parameters) + 1 !=
    length(components) + length(quoted_params)) {
    stop(
      "stringexecGRASS() could not successfully split the provided string ",
      "into ONE command name plus (optionally) flags and parameters.\n",
      "Please check syntax:\n",
      "- the command name, flags and parameters must be separated by ",
      "a whitespace\n",
      "- each parameter must be of the form key=value; ",
      "if 'value' contains spaces, then 'value' must be quoted\n",
      "- concatenation of flags (as in 'g.proj -wf') is not supported: ",
      "use 'g.proj -w -f'\n",
      "- the command name must come at the beginning\n"
    )
  }
  execGRASS(
    cmd = cmd,
    flags = flags,
    parameters = parameters,
    intern = intern,
    ignore.stderr = ignore.stderr,
    Sys_ignore.stdout = Sys_ignore.stdout,
    Sys_wait = Sys_wait,
    Sys_input = Sys_input,
    Sys_show.output.on.console = Sys_show.output.on.console,
    Sys_minimized = Sys_minimized,
    Sys_invisible = Sys_invisible,
    echoCmd = echoCmd,
    redirect = redirect,
    legacyExec = legacyExec
  )
}
