# Set Unix runtime environment variables for GRASS GIS

Set Unix runtime environment variables for GRASS GIS

## Usage

``` r
setup_runtime_env_unix(gisBase, addon_base = NULL, gv)
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

`NULL`, invisibly.
