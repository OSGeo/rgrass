# Set Windows runtime environment variables for GRASS GIS

Set Windows runtime environment variables for GRASS GIS

## Usage

``` r
setup_runtime_env_windows(gisBase, addon_base = NULL, gv)
```

## Arguments

- gisBase:

  Path to the GRASS installation.

- addon_base:

  Optional path to the GRASS add-ons directory.

- gv:

  Cumulative GRASS version strings returned by
  [`grass_version()`](https://osgeo.github.io/rgrass/reference/grass_version.md).

## Value

The value of `OSGEO4W_ROOT`, invisibly.
