# Changelog

## **rgrass** version 0.5-3 (2025-07-09)

CRAN release: 2025-07-11

- allow tests to run (or fail gracefully) when internet resources are
  not available for downloading the GRASS example database

## **rgrass** version 0.5-2 (2025-02-13)

CRAN release: 2025-02-14

- minor change to testsuite to ensure that temporary directory is
  cleaned up after tests

## **rgrass** version 0.5-1 (2025-02-02)

CRAN release: 2025-02-03

- see [\#96](https://github.com/osgeo/rgrass/issues/96), transfer
  maintainership to Steven Pawley

- transfer repo to `osgeo/rgrass` - thanks to Markus Neteler

- convert help pages to `roxygen2` - thanks to Steven Pawley

- add and enable Github Actions CI/CD - thanks to Steven Pawley

## **rgrass** version 0.4-4 (2024-09-03)

CRAN release: 2024-09-03

- use `## IGNORE_RDIFF_BEGIN` and `## IGNORE_RDIFF_END` in regular test
  output

## **rgrass** version 0.4-3 (2024-06-19)

CRAN release: 2024-06-19

- see [\#87](https://github.com/osgeo/rgrass/issues/87) - Windows QGIS
  standalone installations of GRASS GIS can be used only if R is started
  in the OSGeo4W shell bundled with the installation

- [`write_VECT()`](https://osgeo.github.io/rgrass/reference/read_VECT.md):
  when the `SpatVector` object already refers to a source file, an
  intermediate temporary file is no longer written to get the data into
  the GRASS GIS database
  ([\#93](https://github.com/osgeo/rgrass/issues/93)). A similar
  shortcut was already in place for
  [`write_RAST()`](https://osgeo.github.io/rgrass/reference/read_RAST.md).

- [`read_VECT()`](https://osgeo.github.io/rgrass/reference/read_VECT.md):
  provide access to the standalone GDAL-GRASS driver to read vector
  data, which skips the step of writing a intermediate file
  ([\#93](https://github.com/osgeo/rgrass/issues/93)). Note that this
  standalone driver needs to be set up separately. More information is
  in the [driver’s
  README](https://github.com/OSGeo/gdal-grass/blob/main/README.md).

- [`read_VECT()`](https://osgeo.github.io/rgrass/reference/read_VECT.md):
  support reading as `SpatVectorProxy` class of
  [terra](https://rspatial.org/), by providing a `proxy` argument
  ([\#93](https://github.com/osgeo/rgrass/issues/93)).

## **rgrass** version 0.4-2 (2024-03-17)

CRAN release: 2024-03-17

- see [\#84](https://github.com/osgeo/rgrass/issues/84) - handling
  fully-qualified map names

## **rgrass** version 0.4-1 (2024-01-08)

CRAN release: 2024-01-08

- replace `XML` with `xml2` see
  [\#72](https://github.com/osgeo/rgrass/issues/72)

## **rgrass** version 0.3-9 (2023-09-10)

CRAN release: 2023-09-10

- reinstate `grass-stable`
  <https://github.com/OSGeo/grass-website/issues/357>

- fix [\#79](https://github.com/osgeo/rgrass/issues/79) thanks to
  Adam B. Smith, use
  [`terra::as.vector`](https://rspatial.github.io/terra/reference/coerce.html)
  method rather than internal slot name

## **rgrass** version 0.3-8 (2023-03-17)

CRAN release: 2023-03-17

- [\#73](https://github.com/osgeo/rgrass/issues/73) guess `gisBase=` in
  [`initGRASS()`](https://osgeo.github.io/rgrass/reference/initGRASS.md)

- added *SP_EVOLUTION_STATUS* 2 to examples

- [\#66](https://github.com/osgeo/rgrass/issues/66) re-examining to
  protect from UInt maxing out; add stop for required manual NODATA

- [\#68](https://github.com/osgeo/rgrass/issues/68),
  [\#69](https://github.com/osgeo/rgrass/issues/69) improvements to
  vignettes, thanks to Floris Vanderhaeghe and Veronica Andreo

## **rgrass** version 0.3-6 (2022-10-11)

CRAN release: 2022-10-11

- macOS vignette issue

## **rgrass** version 0.3-5 (2022-09-29)

CRAN release: 2022-09-29

- [\#63](https://github.com/osgeo/rgrass/issues/63) and
  [\#64](https://github.com/osgeo/rgrass/issues/64), detection of GRASS
  path for
  [`initGRASS()`](https://osgeo.github.io/rgrass/reference/initGRASS.md)
  semi-automated if `grass --config path` works or if environment
  variable `GRASS_INSTALLATION` set to path, thanks to Robin Lovelace

- correct NODATA logic in
  [`read_RAST()`](https://osgeo.github.io/rgrass/reference/read_RAST.md)
  for unsigned rasters [\#66](https://github.com/osgeo/rgrass/issues/66)
  thanks to Laura Poggio

## **rgrass** version 0.3-3 (2022-08-08)

CRAN release: 2022-08-08

- correct vignette logic error triggered on M1 when **stars** not
  installed

## **rgrass** version 0.3-2 (2022-07-21)

CRAN release: 2022-07-21

- first release to replace deprecated **rgrass7**

- remove suggested packages planned for retirement (**rgdal**)

- add vignettes

- remove old code working around earlier use by GRASS of DBF rather than
  SQLite for storing vector attributes

- remove `use_sp()` and `use_sf()` for file transfer

- remove code using GDAL GRASS plugin
