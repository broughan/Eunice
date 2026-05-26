# Climate Variables

Variable names in datasets are fixed by the metadata. They are retained internally in part by Eunice in order that valid connections might be established between Julia code and the data which is to be visualised. For example the dimension variable longitude might be "longitude", "Longitude" or "lon" in the metadata. When the data is loaded the array of values is inevitably called "lon" in Julia. However, account has to be taken of the interpretation of values: lon could be from -180 to 180 degrees, or from 0 to 360 or even from 180 to -180! Much of this ideosyncratic usage to fixed by the Eunice type structures so need not bother the user. However a warning is needed: should a user wish to vary the code and perform different or additional processing of the data, the actual structure would need to be respected.

# Overview of the data

The topics covered by Eunice include global topography, bathymetry, vegetation, atmospheric temperature, atmospheric carbon dioxide, atmospheric methane, sea surface temperature, ocean surface temperature, sea levels, cloud measures, fire risk indices, river discharge and floud risk indices.

The datasets chosen are assembled into structs or types described in detail in the following section. These types have mutable fields and are easily accessible to the Julia REPL and to Julia functions. Each type has one or more associated climate variables and one or more files containing the data which has been downloaded and extracted and/or combined to obtain the actual data reflected by the type. Of key focus is the set of dimension variables which fit normally into one of the patterns (lon, lat), (lon, lat, time), or (lon, lat, lev, time). Instructions on how to inspect and use the types are given below.

Below in the table we see acronyms which should be of some assistance to the user/reader to find the original data sources, and develop as might be needed alternative or additional data sets to those which have been chosen. In the table Git means the dataset is in an early GitHub Eunice release and Zen that it will be later using Zenodo.


| Acronym | Name | Types |Topics | Git/Zen
|---------|------------|------------|-------|--------|
|ISIMIP |  Inter-Sectoral Impact Model Inter Comparison Project |  Isimp |  land sea mask |  Git |
| ETOPO |  Earth Topography: Global Relief Model |  Etopo | topography, bathymetry |  Zen |
| NOAA |  National Ocean and Atmosphere Administration |  Noaa, NoaaTemp, NoaaTempMonthly |  temperature anomalies |  Git |
| NCEI |  National Centers for Environmental Information |  NceiNoaa |  dominant vegitation species | Git | 
| BEST |  Berkeley Earth Surface Temperature Project | Best |  global temperatures  |  Zen |
| CAMS |  Copernicus Climate Monitoring Service |  Cams, CamsCO2, CamsCH4Lev |   carbon dioxide, methane concentrations |  Git, Zen |
| OI_SST |  Optimum Interpolation Sea Surface Temperature |  Oisst |   sea surface temperatures |  Git |
| OSCAR2 |  Ocean Surface Current Analysis Real Time v2 |  Oscar2daily, Oscar2monthly |  ocean current velocities |  Git |
| CDS SLA |  Copernicus Climate Data Store, Sea Level Anomalies |  CdsSla |  sea level anomalies |  Zen |
| CEMS |  Copernicua Emergency Management Service |  Cems |  fire risk indices |  Git |
| CCI |  European Space Agency Cloud Climate Change Initiative |  CdsCci |  cloud cover data |  Git |
| JRA55 |  Japanese Reanalysis 55 Year Study (1958-present) |  Jra55 |  surface climate data  |  Zen |
| ERA5 |  European Center for Medium-Range Weather Forcasts Reanalysis v5 |  Era5, Era5Lev |  surface climate data, cloud cover levels data  |  Zen |
| MERRA2 |  Modern Era (1980-present) Retrospective Analysis for Research and Applications |  Merra2, Merra2Lev |  climate data, climate data levels  |  Git, Zen |
| CEMSFAS |  Copernicus Emergency Management Flood Analysis System |  CemsFas |  rivers discharge, snow depth, water runoff, soil water indices |  Zen |
