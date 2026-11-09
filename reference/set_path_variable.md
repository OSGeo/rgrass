# Prepend a path to an environment variable

Adds a path to a path-list environment variable unless that exact path
is already present.

## Usage

``` r
set_path_variable(variable_name, install_path)
```

## Arguments

- variable_name:

  Name of the environment variable.

- install_path:

  Path to prepend.

## Value

The updated environment-variable value, invisibly.
