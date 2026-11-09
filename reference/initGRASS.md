# Initiate GRASS session

Run GRASS interface in an R session not started within GRASS. In
general, most users will use `initGRASS` in throwaway locations, to use
GRASS modules on R objects without the need to define and populate a
location. The function initializes environment variables used by GRASS,
the .gisrc used by GRASS for further environment variables, and a
temporary location.

On Windows, if OSGeo4W GRASS is being used, the R session must be
started in the OSGeo4W shell. If not, the non-standard placing of files
and of environment variables confuses the function. If
`toupper(gisBase)` contains "OSGEO4W64/APPS/GRASS" or
"OSGEO4W/APPS/GRASS" (and after converting "\\ to "/"), but the
environment variable `OSGEO4W_ROOT` is not defined, `initGRASS()` will
exit with an error before confusion leads to further errors. For further
details, see <https://github.com/osgeo/rgrass/issues/16> and
<https://github.com/osgeo/rgrass/issues/16>.

The same restriction applies to use of GRASS with QGIS Windows
standalone installations, which may be used with `initGRASS` only if the
R session is started from the OSGeo4W shell shipped as part of the
standalone installer (see <https://github.com/osgeo/rgrass/issues/87>).
The function will exit with an error if R was not started from the QGIS
OSGeo4W shell before confusion leads to further errors.

The locking functions are used internally, but are exposed for
experienced R/GRASS scripters needing to use the GRASS module "g.mapset"
through `initGRASS` in an existing GRASS location. In particular,
"g.mapset" may leave a `.gislock` file in the current MAPSET, so it may
be important to call `unlink_.gislock` to clean up before quitting the R
session. `remove_GISRC` may be used to try to remove the file given in
the "GISRC" environment variable if created by `initGRASS` with argument
`remove_GISRC=` TRUE.

## Usage

``` r
initGRASS(
  gisBase = NULL,
  home = NULL,
  SG = NULL,
  gisDbase = NULL,
  addon_base = NULL,
  location = NULL,
  mapset = NULL,
  override = FALSE,
  use_g.dirseps.exe = TRUE,
  pid,
  remove_GISRC = FALSE,
  ignore.stderr = get.ignore.stderrOption(),
  tempdir = base::tempdir()
)

get.GIS_LOCK()

set.GIS_LOCK(pid)

unset.GIS_LOCK()

unlink_.gislock()

remove_GISRC()
```

## Arguments

- gisBase:

  The directory path to GRASS binaries and libraries, containing bin and
  lib subdirectories among others; if NULL, set from environment
  variable GRASS_INSTALLATION if found, if not found,
  `system("grass --config path")` is tried.

- home:

  The directory in which to create the .gisrc file; defaults to `$HOME`
  on Unix systems and to `USERPROFILE` on Windows systems; can usually
  be set to [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- SG:

  An optional `SpatRaster` or `SpatialGrid` object to define the
  `DEFAULT_WIND` of the temporary location.

- gisDbase:

  if missing, [`tempdir()`](https://rdrr.io/r/base/tempfile.html) will
  be used; GRASS GISDBASE directory for the working session.

- addon_base:

  if missing, assumed to be "\$HOME/.grass7/addons" on Unix-like
  platforms, on MS Windows "\\ and checked for existence.

- location:

  if missing, `basename(tempfile())` will be used; GRASS location
  directory for the working session.

- mapset:

  if missing, `basename(tempfile())` will be used; GRASS mapset
  directory for the working session.

- override:

  default FALSE, set to TRUE if accidental trashing of GRASS .gisrc
  files and locations is not a problem.

- use_g.dirseps.exe:

  default TRUE; whether Windows paths should be normalized. The argument
  name is retained for compatibility, but path normalization is
  performed by R and no longer invokes `g.dirseps.exe`. Ignored on other
  platforms.

- pid:

  default `as.integer(round(runif(1, 1, 1000)))`, integer used to
  identify GIS_LOCK; the value here is arbitrary, but probably should be
  set correctly.

- remove_GISRC:

  default FALSE; if TRUE, attempt to unlink the temporary file named in
  the "GISRC" environment variable when the R session terminates or when
  this package is unloaded.

- ignore.stderr:

  default taking the value set by `set.ignore.stderrOption`; can be set
  to TRUE to silence [`system()`](https://rdrr.io/r/base/system.html)
  output to standard error; does not apply on Windows platforms.

- tempdir:

  a directory to use for temporary files. You may want to provide the
  same value for `home`.

## Value

The function runs `gmeta6` before returning the current values of the
running GRASS session that it provides.

## Details

The function establishes an out-of-GRASS working environment providing
GRASS commands with the environment variable support required, and may
also provide a temporary location for use until the end of the running R
session if the `home` argument is set to
[`tempdir()`](https://rdrr.io/r/base/tempfile.html), and the `gisDbase`
argument is not given. Running `gmeta` shows where the location is,
should it be desired to archive it before leaving R.

## Note

If any package command fails with a UTF-8 error from the XML package,
try using `setXMLencoding` to work around the problem that GRASS modules
declare –interface-description output as UTF-8 without ensuring that it
is.

## See also

[`gmeta()`](https://osgeo.github.io/rgrass/reference/gmeta.md)

## Author

Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>

## Examples

``` r
# Run only if GRASS installation is found and 'terra' package is installed
GRASS_INSTALLATION <- Sys.getenv("GRASS_INSTALLATION")
run <- nzchar(GRASS_INSTALLATION) &&
       file.exists(GRASS_INSTALLATION) &&
       file.info(GRASS_INSTALLATION)$isdir &&
       require(terra, quietly = TRUE)
#> terra 1.9.50

if (run) {
  # Get the terra example dataset
  f <- system.file("ex/elev.tif", package="terra")
  r <- rast(f)
}

# Check for existing GRASS session running
if (run) {
  loc_existing <- try(gmeta(), silent = TRUE)
}

if (run) {
  # Initialize a temporary GRASS project using the example data
  loc <- initGRASS(
    gisBase = GRASS_INSTALLATION,
    home = tempdir(),
    SG = r,
    override = TRUE
  )
}

if (run) {
  # Write the example data to the GRASS database
  write_RAST(r, "elev", flags = "overwrite")
  execGRASS("r.info", map = "elev")
}
#> Importing raster map <elev>...
#>    0%   3%   6%  10%  13%  16%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> SpatRaster read into GRASS using r.in.gdal from file
#>  +----------------------------------------------------------------------------+
#>  | Map:      elev                           Date: Mon Nov  9 15:52:51 2026    |
#>  | Mapset:   file209e3643765e               Login of Creator: runner          |
#>  | Location: file209e48409473                                                 |
#>  | DataBase: /tmp/grass7-runner-8345/Rtmp75ihZb                               |
#>  | Title:                                                                     |
#>  | Timestamp: none                                                            |
#>  |----------------------------------------------------------------------------|
#>  |                                                                            |
#>  |   Type of Map:  raster               Number of Categories: 0               |
#>  |   Data Type:    CELL                                                       |
#>  |   Rows:         90                                                         |
#>  |   Columns:      95                                                         |
#>  |   Total Cells:  8550                                                       |
#>  |        Projection: Latitude-Longitude                                      |
#>  |            N:  50:11:30N    S:  49:26:30N   Res: 0:00:30                   |
#>  |            E:      6:32E    W:   5:44:30E   Res: 0:00:30                   |
#>  |   Range of data:    min = 141  max = 547                                   |
#>  |                                                                            |
#>  |   Data Description:                                                        |
#>  |    generated by r.in.gdal                                                  |
#>  |                                                                            |
#>  |   Comments:                                                                |
#>  |    r.in.gdal --overwrite input="/home/runner/work/_temp/Library/terra/e\   |
#>  |    x/elev.tif" output="elev" memory=300 offset=0 num_digits=0              |
#>  |                                                                            |
#>  +----------------------------------------------------------------------------+
#> 

if (run) {
  # Calculate slope and aspect raster
  execGRASS(
    "r.slope.aspect",
    flags    = "overwrite",
    elevation = "elev",
    slope    = "slope",
    aspect   = "aspect"
  )
}
#>    0%   3%   6%   9%  12%  15%  18%  21%  24%  27%  30%  34%  37%  40%  43%  46%  49%  52%  56%  59%  62%  65%  68%  71%  74%  78%  81%  84%  87%  90%  93%  96% 100%
#> Aspect raster map <aspect> complete
#> Slope raster map <slope> complete

if (run) {
  # Read the results back into R and plot
  u1 <- read_RAST(c("elev", "slope", "aspect"), return_format = "terra")
  plot(u1[["elev"]], col = terrain.colors(50))
}
#> Checking GDAL data type and nodata value...
#>    2%   5%   8%  11%  14%  17%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> Using GDAL data type <UInt32>
#> Exporting raster data to RRASTER format...
#>    2%   5%   8%  11%  14%  17%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> r.out.gdal complete. File
#> </tmp/grass7-runner-8345/Rtmp75ihZb/file209e33838ae7.grd> created.
#> Checking GDAL data type and nodata value...
#>    2%   5%   8%  11%  14%  17%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> Using GDAL data type <Float32>
#> Exporting raster data to RRASTER format...
#>    2%   5%   8%  11%  14%  17%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> r.out.gdal complete. File
#> </tmp/grass7-runner-8345/Rtmp75ihZb/file209e45864e76.grd> created.
#> Checking GDAL data type and nodata value...
#>    2%   5%   8%  11%  14%  17%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> Using GDAL data type <Float32>
#> Exporting raster data to RRASTER format...
#>    2%   5%   8%  11%  14%  17%  20%  23%  26%  30%  33%  36%  40%  43%  46%  50%  53%  56%  60%  63%  66%  70%  73%  76%  80%  83%  86%  90%  93%  96% 100%
#> r.out.gdal complete. File
#> </tmp/grass7-runner-8345/Rtmp75ihZb/file209e8e7741e.grd> created.


# Restore the original GRASS session
if (run) {
  if (!inherits(loc_existing, "try-error")) {
    loc <- initGRASS(
      home = tempdir(),
      gisBase = GRASS_INSTALLATION,
      gisDbase = loc_existing$GISDBASE,
      location = loc_existing$LOCATION_NAME,
      mapset = loc_existing$MAPSET,
      override = TRUE
    )
  }
}
```
