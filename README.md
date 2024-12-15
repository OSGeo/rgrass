# rgrass

[![CRAN status](https://www.r-pkg.org/badges/version/rgrass)](https://CRAN.R-project.org/package=rgrass)
[![Codecov test coverage](https://codecov.io/gh/stevenpawley/rgrass/graph/badge.svg)](https://app.codecov.io/gh/stevenpawley/rgrass)

### Interface Between GRASS Geographical Information System and R

Interpreted interface between GRASS geographical information system and R, based on starting R from within the GRASS GIS environment, or running free-standing R in a temporary or existing GRASS location; the package provides facilities for using all GRASS commands from the R command line, see https://rsbivand.github.io/rgrass/articles/use.html.

The original interface **GRASS** package for `GRASS 5` (2000-2010) is described in Bivand (2000) (https://doi.org/10.1016/S0098-3004(00)00057-1) and Bivand (2001) (https://www.r-project.org/conferences/DSC-2001/Proceedings/Bivand.pdf). This was succeeded by **spgrass6** for `GRASS 6` (2006-2016) and **rgrass7** for `GRASS 7` (2015-2023).
The **rgrass** package modernizes the interface for `GRASS 8` while still permitting the use of `GRASS 7`.

### Installation

This package depends on [GRASS GIS](https://grass.osgeo.org/) version 8 or above (later version 7 should also be OK).

If you use OSGeo4W on Windows (recommended), remember that you must start RStudio, Rgui or console R from within the OSGeo4W shell.

See the [workshop on **rgrass** at FOSS4G 2022](https://rsbivand.github.io/foss4g_2022/modernizing_220822.html) for a detailed introduction with reproducible examples.

If you would like to contribute, please see the CONTRIBUTING file in the .github folder.

For detailed notes, see https://rsbivand.github.io/foss4g_2022/modernizing_220822.html.




