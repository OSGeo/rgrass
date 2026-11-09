# Reads GRASS metadata from the current LOCATION

GRASS LOCATION metadata are read into a list in R; helper function
getLocationProj returns a WKT2 string of projection information. The
helper function `gmeta2grd` creates a GridTopology object from the
current GRASS mapset region definitions.

## Usage

``` r
gmeta(ignore.stderr = FALSE, g.proj_WKT = NULL)

getLocationProj(ignore.stderr = FALSE, g.proj_WKT = NULL)

gmeta2grd(ignore.stderr = FALSE)

# S3 method for class 'gmeta'
print(x, ...)

get.ignore.stderrOption()

get.stop_on_no_flags_parasOption()

get.echoCmdOption()

get.useInternOption()

get.legacyExecOption()

get.defaultFlagsOption()

get.suppressEchoCmdInFuncOption()

set.ignore.stderrOption(value)

set.stop_on_no_flags_parasOption(value)

set.echoCmdOption(value)

set.useInternOption(value)

set.legacyExecOption(value)

set.defaultFlagsOption(value)

set.suppressEchoCmdInFuncOption(value)
```

## Arguments

- ignore.stderr:

  default FALSE, can be set to TRUE to silence
  [`system()`](https://rdrr.io/r/base/system.html) output to standard
  error; does not apply on Windows platforms.

- g.proj_WKT:

  default NULL: return WKT2 representation in GRASS \>= 7.6 and Proj4 in
  GRASS \< 7.6; may be set to FALSE to return Proj4 for GRASS \>= 7.6.

- x:

  S3 object returned by gmeta

- ...:

  arguments passed through print method

- value:

  logical value for setting options on `ignore.stderr` set by default on
  package load to FALSE, `stop_on_no_flags_params` set by default on
  package load to TRUE, `echoCmd` set by default on package load to
  FALSE. `useIntern` sets the intern argument globally; `legacyExec`
  sets the legacyExec option globally, but is initialized to FALSE on
  unix systems (all but Windows) and TRUE on Windows; `defaultFlags` is
  initialized to NULL, but may be a character vector with values from
  c("quiet", "verbose") `suppressEchoCmdInFunc` default TRUE suppresses
  the effect of echoCmd within package functions, maybe set FALSE for
  debugging.

## Value

Returns list of g.gisenv, g.region -g3, and g.proj values.

## Author

Roger S. Bivand, e-mail: <Roger.Bivand@nhh.no>

## Examples

``` r
run <- FALSE
if (nchar(Sys.getenv("GISRC")) > 0 &&
    read.dcf(Sys.getenv("GISRC"))[1, "LOCATION_NAME"] == "nc_basic_spm_grass7") {
  run <- TRUE
}

if (run) {
  G <- gmeta()
  print(G)
}
#> gisdbase    /tmp/grassdb 
#> location    nc_basic_spm_grass7 
#> mapset      PERMANENT 
#> rows        1350 
#> columns     1500 
#> north       228500 
#> south       215000 
#> west        630000 
#> east        645000 
#> nsres       10 
#> ewres       10 
#> projection:
#>  PROJCRS["NAD83(HARN) / North Carolina",
#>     BASEGEOGCRS["NAD83(HARN)",
#>         DATUM["NAD83 (High Accuracy Reference Network)",
#>             ELLIPSOID["GRS 1980",6378137,298.257222101,
#>                 LENGTHUNIT["metre",1]]],
#>         PRIMEM["Greenwich",0,
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>         ID["EPSG",4152]],
#>     CONVERSION["SPCS83 North Carolina zone (meters)",
#>         METHOD["Lambert Conic Conformal (2SP)",
#>             ID["EPSG",9802]],
#>         PARAMETER["Latitude of false origin",33.75,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8821]],
#>         PARAMETER["Longitude of false origin",-79,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8822]],
#>         PARAMETER["Latitude of 1st standard parallel",36.1666666666667,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8823]],
#>         PARAMETER["Latitude of 2nd standard parallel",34.3333333333333,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8824]],
#>         PARAMETER["Easting at false origin",609601.22,
#>             LENGTHUNIT["metre",1],
#>             ID["EPSG",8826]],
#>         PARAMETER["Northing at false origin",0,
#>             LENGTHUNIT["metre",1],
#>             ID["EPSG",8827]]],
#>     CS[Cartesian,2],
#>         AXIS["easting (X)",east,
#>             ORDER[1],
#>             LENGTHUNIT["metre",1]],
#>         AXIS["northing (Y)",north,
#>             ORDER[2],
#>             LENGTHUNIT["metre",1]],
#>     USAGE[
#>         SCOPE["Engineering survey, topographic mapping."],
#>         AREA["United States (USA) - North Carolina - counties of Alamance; Alexander; Alleghany; Anson; Ashe; Avery; Beaufort; Bertie; Bladen; Brunswick; Buncombe; Burke; Cabarrus; Caldwell; Camden; Carteret; Caswell; Catawba; Chatham; Cherokee; Chowan; Clay; Cleveland; Columbus; Craven; Cumberland; Currituck; Dare; Davidson; Davie; Duplin; Durham; Edgecombe; Forsyth; Franklin; Gaston; Gates; Graham; Granville; Greene; Guilford; Halifax; Harnett; Haywood; Henderson; Hertford; Hoke; Hyde; Iredell; Jackson; Johnston; Jones; Lee; Lenoir; Lincoln; Macon; Madison; Martin; McDowell; Mecklenburg; Mitchell; Montgomery; Moore; Nash; New Hanover; Northampton; Onslow; Orange; Pamlico; Pasquotank; Pender; Perquimans; Person; Pitt; Polk; Randolph; Richmond; Robeson; Rockingham; Rowan; Rutherford; Sampson; Scotland; Stanly; Stokes; Surry; Swain; Transylvania; Tyrrell; Union; Vance; Wake; Warren; Washington; Watauga; Wayne; Wilkes; Wilson; Yadkin; Yancey."],
#>         BBOX[33.83,-84.33,36.59,-75.38]],
#>     ID["EPSG",3358]] 

if (run) {
  cat(getLocationProj(), "\n")
  cat(getLocationProj(g.proj_WKT = FALSE), "\n")
}
#> PROJCRS["NAD83(HARN) / North Carolina",
#>     BASEGEOGCRS["NAD83(HARN)",
#>         DATUM["NAD83 (High Accuracy Reference Network)",
#>             ELLIPSOID["GRS 1980",6378137,298.257222101,
#>                 LENGTHUNIT["metre",1]]],
#>         PRIMEM["Greenwich",0,
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>         ID["EPSG",4152]],
#>     CONVERSION["SPCS83 North Carolina zone (meters)",
#>         METHOD["Lambert Conic Conformal (2SP)",
#>             ID["EPSG",9802]],
#>         PARAMETER["Latitude of false origin",33.75,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8821]],
#>         PARAMETER["Longitude of false origin",-79,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8822]],
#>         PARAMETER["Latitude of 1st standard parallel",36.1666666666667,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8823]],
#>         PARAMETER["Latitude of 2nd standard parallel",34.3333333333333,
#>             ANGLEUNIT["degree",0.0174532925199433],
#>             ID["EPSG",8824]],
#>         PARAMETER["Easting at false origin",609601.22,
#>             LENGTHUNIT["metre",1],
#>             ID["EPSG",8826]],
#>         PARAMETER["Northing at false origin",0,
#>             LENGTHUNIT["metre",1],
#>             ID["EPSG",8827]]],
#>     CS[Cartesian,2],
#>         AXIS["easting (X)",east,
#>             ORDER[1],
#>             LENGTHUNIT["metre",1]],
#>         AXIS["northing (Y)",north,
#>             ORDER[2],
#>             LENGTHUNIT["metre",1]],
#>     USAGE[
#>         SCOPE["Engineering survey, topographic mapping."],
#>         AREA["United States (USA) - North Carolina - counties of Alamance; Alexander; Alleghany; Anson; Ashe; Avery; Beaufort; Bertie; Bladen; Brunswick; Buncombe; Burke; Cabarrus; Caldwell; Camden; Carteret; Caswell; Catawba; Chatham; Cherokee; Chowan; Clay; Cleveland; Columbus; Craven; Cumberland; Currituck; Dare; Davidson; Davie; Duplin; Durham; Edgecombe; Forsyth; Franklin; Gaston; Gates; Graham; Granville; Greene; Guilford; Halifax; Harnett; Haywood; Henderson; Hertford; Hoke; Hyde; Iredell; Jackson; Johnston; Jones; Lee; Lenoir; Lincoln; Macon; Madison; Martin; McDowell; Mecklenburg; Mitchell; Montgomery; Moore; Nash; New Hanover; Northampton; Onslow; Orange; Pamlico; Pasquotank; Pender; Perquimans; Person; Pitt; Polk; Randolph; Richmond; Robeson; Rockingham; Rowan; Rutherford; Sampson; Scotland; Stanly; Stokes; Surry; Swain; Transylvania; Tyrrell; Union; Vance; Wake; Warren; Washington; Watauga; Wayne; Wilkes; Wilson; Yadkin; Yancey."],
#>         BBOX[33.83,-84.33,36.59,-75.38]],
#>     ID["EPSG",3358]] 
#> +proj=lcc +lat_0=33.75 +lon_0=-79 +lat_1=36.1666666666667 +lat_2=34.3333333333333 +x_0=609601.22 +y_0=0 +ellps=GRS80 +units=m +no_defs +type=crs 

if (run) {
  grd <- gmeta2grd()
  print(grd)
}
#>                       X1     X2
#> cellcentre.offset 630005 215005
#> cellsize              10     10
#> cells.dim           1500   1350

if (run) {
  ncells <- prod(slot(grd, "cells.dim"))
  df <- data.frame(k = rep(1, ncells))
  mask_SG <- sp::SpatialGridDataFrame(grd, data = df)
  print(summary(mask_SG))
}
#>               Length                Class                 Mode 
#>              2025000 SpatialGridDataFrame                   S4 
```
