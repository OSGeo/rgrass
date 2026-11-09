# Set the Python executable used by GRASS

Preserves an existing `GRASS_PYTHON` setting, selects the Python
executable shipped with OSGeo4W when applicable, and otherwise chooses
Python 2 or 3 from the GRASS version.

## Usage

``` r
set_grass_python(
  OSGEO4W_ROOT = Sys.getenv("OSGEO4W_ROOT"),
  grass_version = NULL
)
```

## Arguments

- OSGEO4W_ROOT:

  Path to an OSGeo4W installation, or an empty string.

- grass_version:

  Optional GRASS version string. When `NULL`, the version is obtained
  from `g.version -g`.

## Value

The value of `GRASS_PYTHON`, invisibly.
