# Create GRASS session directories

Resolves optional database, location, and mapset paths and creates the
directory structure required for a GRASS session.

## Usage

``` r
create_session_directories(
  gisDbase = NULL,
  location = NULL,
  mapset = NULL,
  tempdir = base::tempdir()
)
```

## Arguments

- gisDbase:

  Optional path to the GRASS database.

- location:

  Optional GRASS location name.

- mapset:

  Optional GRASS mapset name.

- tempdir:

  Directory used for default session paths and names.

## Value

A list containing `gisDbase`, `location`, `mapset`, and `loc_path`.
