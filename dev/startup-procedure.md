# `initGRASS()` startup procedure

This note records the startup order implemented by `initGRASS()`. It is
developer documentation, not package documentation; the `dev/` directory is
excluded from R package builds.

## Startup order

1. Set `RGRASS_TEMPDIR` from the `tempdir` argument.

2. Check for an existing `GISRC` or `GIS_LOCK`. Unless `override = TRUE`,
   `initGRASS()` asks for confirmation before replacing that state.

3. Resolve and validate the lock identifier and the remaining arguments.

4. Discover the GRASS installation when `gisBase` was not supplied
   (`search_grass()`), then validate its layout (`validate_gisbase()`).

5. Read GRASS version information (`grass_version()`) and resolve `HOME`
   once (`set_home_path()`).

6. Resolve and create the complete session directory layout
   (`create_session_directories()`): the GRASS database, location,
   `PERMANENT` mapset, working mapset, and location path. At this point, the
   final database, location, and mapset names are known.

7. Configure the platform runtime environment:
   - `setup_runtime_env_windows()` sets executable and Python paths, add-on
     paths, OSGeo4W/standalone PROJ configuration, and Windows Python home
     handling.
   - `setup_runtime_env_unix()` sets executable, dynamic-library, Python, and
     add-on paths.

8. On Windows, normalize the database path with R's `normalizePath()` using
   forward slashes. No GRASS executable is invoked for path conversion.

9. Write one complete GISRC file (`write_gisrc()`) containing `GISDBASE`,
   `LOCATION_NAME`, `MAPSET`, and `GRASS_GUI: text`. The `GISRC` environment
   variable is set to this file.

10. Set `GIS_LOCK` and record session and cleanup state in `.GRASS_CACHE`.

11. Set the process environment values `GISBASE`, `GISDBASE`, `LOCATION_NAME`,
    and `MAPSET`.

12. Run `g.version` and check that the installed GRASS version is compatible
    with rgrass.

13. Select `GRASS_PYTHON` (`set_grass_python()`).

14. Initialize `DEFAULT_WIND` and the mapset `WIND` file, then configure the
    region and optional projection supplied through `SG` (`write_wind()`).

15. Return session metadata from `gmeta()`.

## Design invariant

The final session directory layout is created before GISRC is written. The
startup procedure must therefore not need a placeholder GISRC or
`g.dirseps.exe` to bootstrap the final session.
