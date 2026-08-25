
# Use the README as the initial module docs
#=
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end Eunice
=#
	using NCDatasets
	using GeoMakie
	using GLMakie 
	using GeometryBasics
	using Printf
	using Colors
	using ColorSchemes
	using Observables
	using Interpolations
	using Blink
	#using Statistics

#GLMakie.activate!(visible=true)

# inline functions:
#=
include("utils.jl")
include("support_data.jl")
include("support_functions.jl")
include("support_functions1.jl")
include("Eunice_types_git.jl")
include("Eunice_types_zen.jl")
=#
print("EuniceGL loaded\n")


