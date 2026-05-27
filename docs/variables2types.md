

# From Climate Variables to Eunice types

## Introduction

The table would enable the type for a given climate variable to be located. Then the 
Julia function which would enable the interactive screen to be obtained. Documentation 
for each function can be found under the function name in this docs directory. For example 
for show_vegetation see show_vegetation.md. Information on how to run each function is given 
in its documentation file.

The time range field of the table gives a rough idea of the period or date covered by the data. This is followed by
the grid resolution in degrees. Normally the resolution for both latitude and longitude is the same. Finally the 
GitHub or Zenodo data store is indicated. The GitHub source will be part of an early release of Eunice and the larger
Zenodo data will come later.

Note that these interactive functions require EuniceGL.jl to be included. See the installation instructions in installation.md. 
It is possible to obtain files representing the current Eunice screen state, but for individual better quality plots and movies see the documentation Eunice_Cairo.md.

For detailed information regarding each type see the files Eunice_types_git.jl or Eunice_types_zen.jl in the src directory. It 
should not generally be necessary to consult these files.

## From variables to types and interactive functions

| variable | type | interactive function| time range | lon/lat grid | Git or Zen |
|----------|-------------|-----------------|----------|-----|------|
 |orography | Etopo | show_orography | 2022 | 1/60 | Zen |
 | vegetation | NceiNoaa | show_vegetation | 1997,2007 | 1/2 | Git |
 | temperature surface | NoaaTemp | show_scalar_field | 1850-2024 | 5 | Git |
 | temperature surface | NoaaTempMonthly | show_scalar_field, | 1850-2025 | 5 | Git |
 | temperature surface | Best | show_scalar_field | 1950-2025 | 1 | Zen |
 | temperature levels | Merra2Lev | show_scalar_levels | 2025 | 1/2 | Zen |
 | carbon dioxide | Cheng | show_scalar_field | 1950-2013 | 1 | Git | 
 | carbon dioxide, methane | Cams | show_scalar_field | 2003-2020 | 3/4 | Git | 
 | carbon dioxide | CamsCO2 | show_scalar_field | 2015-2024 | 1 | Git |
 | methane levels | CamsCH4Lev | show_scalar_levels | 2024-2024 | 1 | Zen |
 | sea surface temperature | Oisst | show_scalar_field | 1982-2023| 1/2 | Git | 
 | ocean surface currents | Oscar2daily | show_scalar_field | 202101 | 1/2 |  Git |
 | ocean surface currents | Oscar2monthly | show_vector_field | 2024-2025 | 1/2 | Git | 
 | sea surface height | CdsSla | show_scalar_field | 1993-2023 | 1/4 |  Zen | Git |
 | wind surface vectors | Jra55 | show_vector_field | 1990| 9/16 |  Zen |
 | wind levels vectors | Merra2Lev | show_vector_levels | 202501 | 1/2 | Zen | 
 | wind surface components | Jra55 | show_scalar_field | 1990 | 9/16 |  Zen |
 | wind levels components | Merra2Lev | show_scalar_levels | 202501 | 1/2 | Zen | 
 | downwelling longwave radiation | Jra55 | show_scalar_field | 1990-1991 | 9/16 |  Zen |
 | downwelling longwave radiation | Era5 | show_scalar_field | 2008 | 8 |  Zen |
 | downwelling shortwave radiation | Jra55 | show_scalar_field | 1990 | 9/16 |  Zen |
 | downwelling shortwave radiation | Era5 | show_scalar_field | 2008 | 8 | Zen | 
 | ozone density levels | Merra2Lev | show_scalar_levels | 202501 | 1/2 | Zen |
 | surface pressure | Jra55 | show_scalar_pressure | 1990 | 9/16 |  Zen |
 | surface pressure | Merra2 | show_scalar_pressure | 202501 | 1/2 | Git |
 | cloud properties | CdsCci | show_scalar_field | 201801-202206 | 1/2 |  Git |
 | cloud properties levels | Era5Lev | show_scalar_levels | 202501 | 12 |  Zen | 
 | specific humidity surface | Jra55 | show_scalar_field | 1990 | 9/16 |  Zen |
 | specific humidity levels | Era5Lev | show_scalar_levels | 2010 | 12 | Zen |
 | specific humidity levels | Merra2Lev | show_scalar_levels | 20250101 | 1/2 | Zen |
 | relative humidity surface | Jra55 | show_scalar_field | 1990 | 9/16 | Zen |
 | relative humidity levels | Era5Lev | show_scalar_levels | 2010 | 12 | Zen | 
 | rainfall flux | Jra55 | show_scalar_field | 1990 | 9/16 |  Zen | 
 | mean total rainfall rate | Era5 | show_scalar_field | 200801 | 8 | Zen |
 | fire risk indices | Cems | show_scalar_field | 1984-2024 | 1/2 | Git |
