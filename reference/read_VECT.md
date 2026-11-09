# Read and write GRASS vector object files

`read_VECT` moves one GRASS vector object file with attribute data
through a temporary GeoPackage file to a
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
object; `write_VECT` moves a
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
object through a temporary GeoPackage file to a GRASS vector object
file. `vect2neigh` returns neighbour pairs with shared boundary length
as described by Markus Neteler, in
<https://stat.ethz.ch/pipermail/r-sig-geo/2005-October/000616.html>.
`cygwin_clean_temp` can be called to try to clean the GRASS
mapset-specific temporary directory under cygwin.

## Usage

``` r
read_VECT(
  vname,
  layer = "",
  proxy = FALSE,
  use_gdal_grass_driver = TRUE,
  type = NULL,
  flags = "overwrite",
  Sys_ignore.stdout = FALSE,
  ignore.stderr = get.ignore.stderrOption()
)

write_VECT(
  x,
  vname,
  flags = "overwrite",
  ignore.stderr = get.ignore.stderrOption()
)

vInfo(vname, layer, ignore.stderr = NULL)

vColumns(vname, layer, ignore.stderr = NULL)

vDataCount(vname, layer, ignore.stderr = NULL)

vect2neigh(
  vname,
  ID = NULL,
  ignore.stderr = NULL,
  remove = TRUE,
  vname2 = NULL,
  units = "k"
)
```

## Arguments

- vname:

  A GRASS vector file name.

- layer:

  a layer name (string); if missing the first layer will be used.

- proxy:

  Default is `FALSE`. Set as `TRUE` if you need a `SpatVectorProxy`
  object.

- use_gdal_grass_driver:

  Default `TRUE`. The [standalone GDAL-GRASS
  driver](https://github.com/OSGeo/gdal-grass) for the vector format
  will be used if it is installed. The advantage is that no intermediate
  file needs to be written from GRASS GIS and subsequently read into R;
  instead the vector layer is read directly from the GRASS GIS database.
  Please read the **Note** further below!.

- type:

  override type detection when multiple types are non-zero, passed to
  v.out.ogr.

- flags:

  Character vector containing additional optional flags and/or options
  for v.in.ogr, particularly "o" and "overwrite".

- Sys_ignore.stdout:

  Passed to `system`.

- ignore.stderr:

  default the value set by `set.ignore.stderrOption`; NULL, taking the
  value set by `set.ignore.stderrOption`, can be set to TRUE to silence
  [`system()`](https://rdrr.io/r/base/system.html) output to standard
  error; does not apply on Windows platforms.

- x:

  A `SpatVector` object moved to GRASS.

- ID:

  A valid DB column name for unique identifiers (optional).

- remove:

  default TRUE, remove copied vectors created in `vect2neigh`.

- vname2:

  If on a previous run, remove was FALSE, the name of the temporary
  vector may be given to circumvent its generation.

- units:

  default "k"; see GRASS 'v.to.db' manual page for alternatives.

## Value

`read_VECT` imports a GRASS vector layer into a `SpatVector` or
`SpatVectorProxy` object. `vect2neigh` returns a data frame object with
left and right neighbours and boundary lengths, also given class
GRASSneigh and spatial.neighbour (as used in spdep). The incantation to
retrieve the neighbours list is `sn2listw(vect2neigh())$neighbours`, and
to retrieve the boundary lengths: `sn2listw(vect2neigh())$weights`. The
GRASSneigh object has two other useful attributes: external is a vector
giving the length of shared boundary between each polygon and the
external area, and total giving each polygon's total boundary length.

## Note

Be aware that the GDAL-GRASS driver may have some
[issues](https://github.com/OSGeo/gdal-grass/issues) for vector data. In
our experience, the error and warning messages for vector data can be
ignored. Further, the returned metadata about the coordinate reference
system may currently be incomplete, e.g. it may miss the EPSG code.

## Author

Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>

## Examples

``` r
# Run example if in active GRASS nc_basic_spm_grass7 location
run <- FALSE
if (nchar(Sys.getenv("GISRC")) > 0 &&
    read.dcf(Sys.getenv("GISRC"))[1, "LOCATION_NAME"] == "nc_basic_spm_grass7") {
  run <- require(terra, quietly = TRUE)
}

# Store original environment variable settings
GV <- Sys.getenv("GRASS_VERBOSE")
Sys.setenv("GRASS_VERBOSE" = 0)
ois <- get.ignore.stderrOption()
set.ignore.stderrOption(TRUE)
#> [1] FALSE

if (run) {
  # Create a new mapset
  meta <- gmeta()
  location_path <- file.path(meta$GISDBASE, meta$LOCATION_NAME)
  previous_mapset <- meta$MAPSET
  example_mapset <- "RGRASS_EXAMPLES"
  execGRASS("g.mapset", "c", mapset = example_mapset)
 }

if (run) {
  # Report basic metadata about the schools dataset
  execGRASS("v.info", map = "schools", layer = "1")
  print(vInfo("schools"))
 }
#>  +----------------------------------------------------------------------------+
#>  | Name:            schools                                                   |
#>  | Mapset:          PERMANENT                                                 |
#>  | Location:        nc_basic_spm_grass7                                       |
#>  | Database:        /tmp/grassdb                                              |
#>  | Title:           Wake County schools (points map)                          |
#>  | Map scale:       1:1                                                       |
#>  | Name of creator: helena                                                    |
#>  | Organization:    NC OneMap                                                 |
#>  | Source date:     Tue Nov  7 19:34:09 2006                                  |
#>  | Timestamp (first layer): none                                              |
#>  |----------------------------------------------------------------------------|
#>  | Map format:      native                                                    |
#>  |----------------------------------------------------------------------------|
#>  |   Type of map: vector (level: 2)                                           |
#>  |                                                                            |
#>  |   Number of points:       167             Number of centroids:  0          |
#>  |   Number of lines:        0               Number of boundaries: 0          |
#>  |   Number of areas:        0               Number of islands:    0          |
#>  |                                                                            |
#>  |   Map is 3D:              No                                               |
#>  |   Number of dblinks:      1                                                |
#>  |                                                                            |
#>  |   Projection: Lambert Conformal Conic                                      |
#>  |                                                                            |
#>  |               N:   248159.84441077    S:   203559.01136227                 |
#>  |               E:   671714.55110786    W:   619215.13388253                 |
#>  |                                                                            |
#>  |   Digitization threshold: 0                                                |
#>  |   Comment:                                                                 |
#>  |                                                                            |
#>  +----------------------------------------------------------------------------+
#> 
#>      nodes     points      lines boundaries  centroids      areas    islands 
#>          0        167          0          0          0          0          0 
#> primitives      map3d 
#>        167          0 

if (run) {
  # Read/write as a SpatVector
  schs <- read_VECT("schools")
  print(summary(schs))
 }
#>       cat               TAG          NAMESHORT        NAMELONG  
#>  Min.   :  1.0   Length   :167   Length   :167   Length   :167  
#>  1st Qu.: 42.5   N.unique :167   N.unique :135   N.unique :167  
#>  Median : 84.0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Mean   : 84.0   Min.nchar:  3   Min.nchar:  3   Min.nchar:  8  
#>  3rd Qu.:125.5   Max.nchar:  3   Max.nchar: 19   Max.nchar: 38  
#>  Max.   :167.0                                                  
#>                                                                 
#>    CORECAPACI       MOBILEUNIT       MOBILECAPA         GLEVEL   
#>  Min.   :   0.0   Min.   : 0.000   Min.   :0.00   Length   :167  
#>  1st Qu.: 498.5   1st Qu.: 0.000   1st Qu.:0.75   N.unique :  7  
#>  Median : 586.0   Median : 6.000   Median :1.50   N.blank  :  0  
#>  Mean   : 763.7   Mean   : 7.318   Mean   :1.75   Min.nchar:  1  
#>  3rd Qu.: 903.0   3rd Qu.:11.000   3rd Qu.:2.50   Max.nchar:  1  
#>  Max.   :2294.0   Max.   :49.000   Max.   :4.00                  
#>  NAs    :23       NAs    :19       NAs    :163                   
#>       LOGRADE         HIGRADE         CALENDAR        HASBASE   
#>  Length   :167   Length   :167   Length   :167   Length   :167  
#>  N.unique :  0   N.unique :  0   N.unique :  3   N.unique :  0  
#>  N.blank  :  0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Min.nchar: NA   Min.nchar: NA   Min.nchar:  1   Min.nchar: NA  
#>  Max.nchar: NA   Max.nchar: NA   Max.nchar:  1   Max.nchar: NA  
#>  NAs      :167   NAs      :167   NAs      : 11   NAs      :167  
#>                                                                 
#>       ISMAGNET         PHONE         ADDRNUMBER      ADDRPREFIX 
#>  Length   :167   Length   :167   Length   :167   Length   :167  
#>  N.unique :  0   N.unique :151   N.unique :135   N.unique :  0  
#>  N.blank  :  0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Min.nchar: NA   Min.nchar:  7   Min.nchar:  3   Min.nchar: NA  
#>  Max.nchar: NA   Max.nchar:  7   Max.nchar:  5   Max.nchar: NA  
#>  NAs      :167   NAs      : 10   NAs      :  4   NAs      :167  
#>                                                                 
#>       ADDRROOT        ADDRTYPE       ADDRSUFFIX       ADDRCITY  
#>  Length   :167   Length   :167   Length   :167   Length   :167  
#>  N.unique :131   N.unique :  0   N.unique :  0   N.unique : 13  
#>  N.blank  :  0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Min.nchar:  6   Min.nchar: NA   Min.nchar: NA   Min.nchar:  4  
#>  Max.nchar: 21   Max.nchar: NA   Max.nchar: NA   Max.nchar: 14  
#>  NAs      :  2   NAs      :167   NAs      :167                  
#>                                                                 
#>      ADDRZIPCOD       SPED           STATUS          NODEID      CAPACITYTO    
#>  Length   :167   Min.   : NA   Length   :167   Length   :167   Min.   :   0.0  
#>  N.unique : 32   1st Qu.: NA   N.unique :  5   N.unique :128   1st Qu.: 543.0  
#>  N.blank  :  0   Median : NA   N.blank  :  0   N.blank  :  0   Median : 761.0  
#>  Min.nchar:  5   Mean   :NaN   Min.nchar:  1   Min.nchar:  5   Mean   : 867.0  
#>  Max.nchar:  5   3rd Qu.: NA   Max.nchar:  1   Max.nchar:  5   3rd Qu.: 992.5  
#>                  Max.   : NA                                   Max.   :2294.0  
#>                  NAs    :167                                   NAs    :20      
#>         ESL          BOARDDIS2      PROJ_CAP            NOTES    
#>  Length   :167   Length   :167   Min.   :   0.0   Length   :167  
#>  N.unique :  2   N.unique :  9   1st Qu.: 497.0   N.unique : 19  
#>  N.blank  :  0   N.blank  :  0   Median : 722.0   N.blank  :  0  
#>  Min.nchar:  1   Min.nchar:  1   Mean   : 793.1   Min.nchar:  1  
#>  Max.nchar:  1   Max.nchar:  1   3rd Qu.: 975.0   Max.nchar:  2  
#>  NAs      :  9   NAs      : 11   Max.   :2390.0   NAs      : 99  
#>                                  NAs    :2                       

if (run) {
  try({
    write_VECT(schs, "newsch", flags = c("o", "overwrite"))
  })
  schs <- read_VECT("schools", use_gdal_grass_driver = FALSE)
 }

if (run) {
  write_VECT(schs, "newsch", flags = c("o", "overwrite"))
  execGRASS("v.info", map = "newsch", layer = "1")
 }
#>  +----------------------------------------------------------------------------+
#>  | Name:            newsch                                                    |
#>  | Mapset:          RGRASS_EXAMPLES                                           |
#>  | Location:        nc_basic_spm_grass7                                       |
#>  | Database:        /tmp/grassdb                                              |
#>  | Title:                                                                     |
#>  | Map scale:       1:1                                                       |
#>  | Name of creator: runner                                                    |
#>  | Organization:                                                              |
#>  | Source date:     Mon Nov  9 15:53:01 2026                                  |
#>  | Timestamp (first layer): none                                              |
#>  |----------------------------------------------------------------------------|
#>  | Map format:      native                                                    |
#>  |----------------------------------------------------------------------------|
#>  |   Type of map: vector (level: 2)                                           |
#>  |                                                                            |
#>  |   Number of points:       167             Number of centroids:  0          |
#>  |   Number of lines:        0               Number of boundaries: 0          |
#>  |   Number of areas:        0               Number of islands:    0          |
#>  |                                                                            |
#>  |   Map is 3D:              No                                               |
#>  |   Number of dblinks:      1                                                |
#>  |                                                                            |
#>  |   Projection: Lambert Conformal Conic                                      |
#>  |                                                                            |
#>  |               N:   248159.84441077    S:   203559.01136227                 |
#>  |               E:   671714.55110786    W:   619215.13388253                 |
#>  |                                                                            |
#>  |   Digitization threshold: 0                                                |
#>  |   Comment:                                                                 |
#>  |                                                                            |
#>  +----------------------------------------------------------------------------+
#> 

if (run) {
  nschs <- read_VECT("newsch")
  print(summary(nschs))
 }
#>       cat             cat_              TAG          NAMESHORT  
#>  Min.   :  1.0   Min.   :  1.0   Length   :167   Length   :167  
#>  1st Qu.: 42.5   1st Qu.: 42.5   N.unique :167   N.unique :135  
#>  Median : 84.0   Median : 84.0   N.blank  :  0   N.blank  :  0  
#>  Mean   : 84.0   Mean   : 84.0   Min.nchar:  3   Min.nchar:  3  
#>  3rd Qu.:125.5   3rd Qu.:125.5   Max.nchar:  3   Max.nchar: 19  
#>  Max.   :167.0   Max.   :167.0                                  
#>                                                                 
#>       NAMELONG     CORECAPACI       MOBILEUNIT       MOBILECAPA  
#>  Length   :167   Min.   :   0.0   Min.   : 0.000   Min.   :0.00  
#>  N.unique :167   1st Qu.: 498.5   1st Qu.: 0.000   1st Qu.:0.75  
#>  N.blank  :  0   Median : 586.0   Median : 6.000   Median :1.50  
#>  Min.nchar:  8   Mean   : 763.7   Mean   : 7.318   Mean   :1.75  
#>  Max.nchar: 38   3rd Qu.: 903.0   3rd Qu.:11.000   3rd Qu.:2.50  
#>                  Max.   :2294.0   Max.   :49.000   Max.   :4.00  
#>                  NAs    :23       NAs    :19       NAs    :163   
#>        GLEVEL         LOGRADE         HIGRADE         CALENDAR  
#>  Length   :167   Length   :167   Length   :167   Length   :167  
#>  N.unique :  7   N.unique :  0   N.unique :  0   N.unique :  3  
#>  N.blank  :  0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Min.nchar:  1   Min.nchar: NA   Min.nchar: NA   Min.nchar:  1  
#>  Max.nchar:  1   Max.nchar: NA   Max.nchar: NA   Max.nchar:  1  
#>                  NAs      :167   NAs      :167   NAs      : 11  
#>                                                                 
#>       HASBASE         ISMAGNET         PHONE         ADDRNUMBER 
#>  Length   :167   Length   :167   Length   :167   Length   :167  
#>  N.unique :  0   N.unique :  0   N.unique :151   N.unique :135  
#>  N.blank  :  0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Min.nchar: NA   Min.nchar: NA   Min.nchar:  7   Min.nchar:  3  
#>  Max.nchar: NA   Max.nchar: NA   Max.nchar:  7   Max.nchar:  5  
#>  NAs      :167   NAs      :167   NAs      : 10   NAs      :  4  
#>                                                                 
#>      ADDRPREFIX       ADDRROOT        ADDRTYPE       ADDRSUFFIX 
#>  Length   :167   Length   :167   Length   :167   Length   :167  
#>  N.unique :  0   N.unique :131   N.unique :  0   N.unique :  0  
#>  N.blank  :  0   N.blank  :  0   N.blank  :  0   N.blank  :  0  
#>  Min.nchar: NA   Min.nchar:  6   Min.nchar: NA   Min.nchar: NA  
#>  Max.nchar: NA   Max.nchar: 21   Max.nchar: NA   Max.nchar: NA  
#>  NAs      :167   NAs      :  2   NAs      :167   NAs      :167  
#>                                                                 
#>       ADDRCITY       ADDRZIPCOD       SPED           STATUS          NODEID   
#>  Length   :167   Length   :167   Min.   : NA   Length   :167   Length   :167  
#>  N.unique : 13   N.unique : 32   1st Qu.: NA   N.unique :  5   N.unique :128  
#>  N.blank  :  0   N.blank  :  0   Median : NA   N.blank  :  0   N.blank  :  0  
#>  Min.nchar:  4   Min.nchar:  5   Mean   :NaN   Min.nchar:  1   Min.nchar:  5  
#>  Max.nchar: 14   Max.nchar:  5   3rd Qu.: NA   Max.nchar:  1   Max.nchar:  5  
#>                                  Max.   : NA                                  
#>                                  NAs    :167                                  
#>    CAPACITYTO            ESL          BOARDDIS2      PROJ_CAP     
#>  Min.   :   0.0   Length   :167   Length   :167   Min.   :   0.0  
#>  1st Qu.: 543.0   N.unique :  2   N.unique :  9   1st Qu.: 497.0  
#>  Median : 761.0   N.blank  :  0   N.blank  :  0   Median : 722.0  
#>  Mean   : 867.0   Min.nchar:  1   Min.nchar:  1   Mean   : 793.1  
#>  3rd Qu.: 992.5   Max.nchar:  1   Max.nchar:  1   3rd Qu.: 975.0  
#>  Max.   :2294.0   NAs      :  9   NAs      : 11   Max.   :2390.0  
#>  NAs    :20                                       NAs    :2       
#>        NOTES    
#>  Length   :167  
#>  N.unique : 19  
#>  N.blank  :  0  
#>  Min.nchar:  1  
#>  Max.nchar:  2  
#>  NAs      : 99  
#>                 

if (run) {
  print(all.equal(names(nschs), as.character(vColumns("newsch")[, 2])))
 }
#> [1] TRUE

if (run) {
  # Show metadata for the roadsmajor dataset and read as spatVector
  print(vInfo("roadsmajor"))
 }
#>      nodes     points      lines boundaries  centroids      areas    islands 
#>        266          0        355          0          0          0          0 
#> primitives      map3d 
#>        355          0 

if (run) {
  roads <- read_VECT("roadsmajor")
  print(summary(roads))
}
#>       cat          MAJORRDS_         ROAD_NAME       MULTILANE  
#>  Min.   :  1.0   Min.   :  1.0   Length   :355   Length   :355  
#>  1st Qu.: 89.5   1st Qu.: 91.5   N.unique : 16   N.unique :  2  
#>  Median :178.0   Median :180.0   N.blank  :  0   N.blank  :  0  
#>  Mean   :178.0   Mean   :179.8   Min.nchar:  4   Min.nchar:  2  
#>  3rd Qu.:266.5   3rd Qu.:268.5   Max.nchar:  6   Max.nchar:  3  
#>  Max.   :355.0   Max.   :357.0   NAs      :243   NAs      : 86  
#>     PROPYEAR         OBJECTID       SHAPE_LEN       
#>  Min.   :   0.0   Min.   :  1.0   Min.   :   20.36  
#>  1st Qu.:   0.0   1st Qu.: 89.5   1st Qu.:  763.32  
#>  Median :   0.0   Median :178.0   Median : 1601.23  
#>  Mean   : 192.7   Mean   :178.0   Mean   : 4934.15  
#>  3rd Qu.:   0.0   3rd Qu.:266.5   3rd Qu.: 9555.59  
#>  Max.   :2025.0   Max.   :355.0   Max.   :64177.25  

# not run: vect2neigh() currently writes 3 new data sources in the PERMANENT
# mapset, despite this mapset not being the active one.
if (FALSE) {
  cen_neig <- vect2neigh("census")
  str(cen_neig)
}

# Cleanup the previously created datasets
if (run) {
  execGRASS(
    "g.remove",
    flags = "f",
    name = c("newsch", "newsch1"),
    type = "vector"
  )
  execGRASS("g.mapset", mapset = previous_mapset)
  if (example_mapset != previous_mapset) {
    unlink(file.path(location_path, example_mapset), recursive = TRUE)
  }
}

# Restore environment variable settings
Sys.setenv("GRASS_VERBOSE" = GV)
set.ignore.stderrOption(ois)
#> [1] TRUE
```
