
# Eunice

This repo is for climate dataset visualization using Julia. Its uses GLMakie, CairoMakie, and GeoMakie. It is under development. It will be deployed first targeting small datasets, less than 100MB, and later using Zenodo with larger datasets, many about 0.5GB.

# What is Eunice

In more detail Eunice is an intended github package which is currently under development. It is designed to give users of the language Julia a set of examples of how the language can be used to explore climate data. In this manner an understanding of global climate variabity might be obtained, especially that for the last few dccades. To this end, a range of climae variable datasets have been chosen and assembled to be readily available to Julia users. These datasets generally cover the past few decades but not the more immediate past.

Not every potential climate variable has been included. As explained below we have chosen a widely used data type which has good support with Julia packages. Here is the list where in each case the coverage is global: orography/bathymetry, land masking, vegetation, surface temperature, atmospheric levels temperature, carbon dioxide and methane concentrations, sea surface temperature, ocean surface currents, sea surface heights, wind surface velocity, wind levels velocity, downwelling long and short wave surface radiation, ozone density levels, surface pressure, cloud levels properties, specific humidity levels, relative humidity levels, rainfall flux, mean rainfall rate, and fire risk indices.

Scientists and students have many needs for visualization when it comes to data. They require publication quality graphical output. In paraticular, they need to consider variation of climate variables through movies which run independant of Julia. They need easy-to-use interactivity to explore different parts of the global climate system, including different regions and different atmospheric levels. These needs are not able to be provided in a single uniform package. To this end, two sets of related functions are provided, one based on CairoMakie and the other GLMakie.

To reduce the complexity of the code supporting Eunice, two main strategies have been adopted. The first is using functions (methods) to reduce code rewriting. The other is to set up a system of Julia types (structs). These form bridges between the metadata attached to a data variable (or set of data variables or set of data files) and Julia. They include the essential parameter values, file names, URL access points, climate variable internal names and the like. These types are for the most part invisible but do need to be used. They can be observed and values changed.

There are thousands of climate related datasets available online. This can be bewildering for the beginner. To make sense of the labyrinth, choices had to be made to design Eunice. One choice was to keep universally to so-called CF-compliant datasets. These files typically end in .nc or .nc4. There are methods in Julia which support access to these datasets and we have chosen to use the packages NCDatasets.jl, Dates.jl and other packages.

Another design choice was to divide the datasets into small and large, large being anything over the GitHub file size limit of 100MB. The intention is to include the small datasets in an early release and the larger datasets, by linking to the Cern data store Zenodo, at a later date.

Following this introduction we give more details concerning some of these topics but first answer the question why the name "Eunice".


## Who was Eunice

The package is named after the American scientist, inventor and feminist Eunice Newton Foote. She is now (21st century) widely regarded as the first person to have scientifically demonstrated, recognized and published in 1856 the significance of CO2 for global warming. There is a full report on the life and significance of this amazing woman in [Eunice Newton Foote](https://en.wikipedia.org/wiki/Eunice_Newton_Foote "Eunice Newton Foote Wikipedia article"). I am a distant sort of relative, as they say once removed. My grandfather was Alfred George Foote who's father emigrated to New Zealand from Bristol, with the American and English Foote's having a common source, probably in SW England.

## The scope of Eunice

The topics covered by Eunice include global topography, bathymetry, vegetation, atmospheric temperature, atmospheric carbon dioxide, atmospheric methane, sea surface temperature, ocean surface temperature, sea ocean surface currents, levels, cloud measures, fire risk indices, river discharges and floud risk indices.

In the docs subfolder of Eunice there will be information regarding the types, the functions, the data variables, and how to install and run Eunice. In this README.md we will give two examples. The first is a static plot using CairoMakie and the second an example of the interactive screen for manipulating the globe and other parameters to observe how the global values of a climate variable evolve.
