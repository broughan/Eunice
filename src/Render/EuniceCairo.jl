
# Use the README as the initial module docs Julia in src
#=
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end Eunice
=#
	using NCDatasets
	using GeoMakie
	using CairoMakie
	using GeometryBasics
	using Printf
	using Colors
	using ColorSchemes
	using Observables
	using Dates
	using CSV
	using DataFrames
	#using Statistics

#CairoMakie.activate!()
#=
include("utils.jl")
include("support_functions.jl")
include("Eunice_types.jl")
=#
print("EuniceCairo.jl loaded\n")


