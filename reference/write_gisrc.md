# Write the GRASS session configuration file

Creates the platform-specific GISRC path and writes the values
identifying the active GRASS database, location, and mapset.

## Usage

``` r
write_gisrc(
  gisDbase,
  location,
  mapset,
  home,
  gv,
  platform,
  override = FALSE,
  missing_override = FALSE,
  use_g.dirseps.exe = TRUE,
  tempdir = base::tempdir()
)
```

## Arguments

- gisDbase:

  Path to the GRASS database.

- location:

  Name of the GRASS location.

- mapset:

  Name of the GRASS mapset.

- home:

  Directory in which to create the GISRC file.

- gv:

  GRASS version information returned by
  [`grass_version()`](https://osgeo.github.io/rgrass/reference/grass_version.md).

- platform:

  GRASS platform variant (`"unix"` or `"WinNat"`).

- override:

  Whether an existing GISRC file may be overwritten.

- missing_override:

  Whether `override` was omitted from
  [`initGRASS()`](https://osgeo.github.io/rgrass/reference/initGRASS.md).

- use_g.dirseps.exe:

  Whether to normalize Windows path separators. The argument name is
  retained for compatibility; normalization is performed by R and does
  not invoke `g.dirseps.exe`.

- tempdir:

  Directory used for a fallback GISRC file when the current working
  directory is not writable on Windows.

## Value

The path to the GISRC file, invisibly.
