# rgrass: Interface between GRASS geographical information system and R

Interpreted interface between GRASS geographical information system,
versions 7 and 8, and R, based on starting R from within the GRASS
environment, or on running R stand-alone and creating a throw-away GRASS
environment from within R. The interface uses classes defined in the sp
package to hold spatial data.

## Details

Index:


    read_RAST              read GRASS raster files
    write_RAST             write GRASS raster files
    read_VECT              read GRASS vector object files
    write_VECT             write GRASS vector object files
    gmeta                  read GRASS metadata from the current LOCATION
    getLocationProj        return a WKT2 string of projection information
    gmeta2grd              create a GridTopology object from the GRASS region
    vInfo                  return vector geometry information
    vColumns               return vector database columns information
    vDataCount             return count of vector database rows
    vect2neigh             return area neighbours with shared boundary length

Note that the examples now use the smaller subset North Carolina
location:
<https://grass.osgeo.org/sampledata/north_carolina/nc_basic_spm_grass7.tar.gz>

## See also

Useful links:

- <https://osgeo.github.io/rgrass/>

- <https://grass.osgeo.org/>

- <https://github.com/osgeo/rgrass>

- <https://lists.osgeo.org/mailman/listinfo/grass-stats>

- Report bugs at <https://github.com/osgeo/rgrass/issues/>

## Author

**Maintainer**: Steven Pawley <dr.stevenpawley@gmail.com>
([ORCID](https://orcid.org/0000-0002-5524-3320))

Authors:

- Steven Pawley <dr.stevenpawley@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-5524-3320))

- Roger Bivand <Roger.Bivand@nhh.no>
  ([ORCID](https://orcid.org/0000-0003-2392-6140))

Other contributors:

- Sebastian Jeworutzki <Sebastian.Jeworutzki@rub.de>
  ([ORCID](https://orcid.org/0000-0002-2671-5253)) \[contributor\]

- Rainer Krug <Rainer@krugs.de>
  ([ORCID](https://orcid.org/0000-0002-7490-0066)) \[contributor\]

- Robin Lovelace ([ORCID](https://orcid.org/0000-0001-5679-6536))
  \[contributor\]

- Markus Neteler <neteler@osgeo.org>
  ([ORCID](https://orcid.org/0000-0003-1916-1966)) \[contributor\]

- Floris Vanderhaeghe <floris.vanderhaeghe@inbo.be>
  ([ORCID](https://orcid.org/0000-0002-6378-6229)) \[contributor\]
