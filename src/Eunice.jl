module Eunice

const EUNICE_DIR = @__DIR__

# using ...

# core:
include("./support_functions.jl")
include("./utils.jl")
include("./Eunice_types.jl")
function eunice_test(x)
	println(x)
	return [x,x]
end

#=
# EuniceCairo
include("./Render/EuniceCairo.jl")
include("./Render/render_vegetation.jl")
include("./Render/render_orography.jl")
include("./Render/render_mask.jl")
include("./Render/render_scalar_field.jl")
include("./Render/render_scalar_levels.jl")

# EuniceGL
include("./Show/EuniceGL.jl")
include("./Show/show_vegetation.jl")
include("./Show/show_orography.jl")
include("./Show/show_scalar_field.jl")
include("./Show/show_scalar_levels.jl")
include("./Show/show_vector_field.jl")
include("./Show/show_vector_levels.jl")

# Tools
include("./Tools/eds_small_tools.jl")
include("./Tools/eds_process_2d.jl")
include("./Tools/eds_collate.jl")
include("./Tools/eds_extract.jl")
include("./Tools/eds_thin_deflate.jl")
include("./Tools/eds_extend_time_series.jl")
include("./Tools/eds_generate_type.jl")
=#

export eunice_test

println("Eunice loaded")
end # module Eunice
