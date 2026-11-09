# Initialize GRASS region files

Creates `DEFAULT_WIND` and mapset `WIND` files, initializes the saved
input region, and applies projection information supplied through `SG`.

## Usage

``` r
write_wind(loc_path, mapset, SG = NULL, ignore.stderr)
```

## Arguments

- loc_path:

  Path to the GRASS location.

- mapset:

  Name of the active mapset.

- SG:

  Optional `SpatRaster` or `SpatialGrid` defining the region.

- ignore.stderr:

  Whether GRASS command standard error should be ignored.

## Value

`NULL`, invisibly.
