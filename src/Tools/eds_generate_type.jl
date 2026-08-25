
using NCDatasets
using Dates

#=
functions:
	generate_eunice_type
	generate_eunice_type_file
	eunice_type_gen
=#
		Eunice_ordered_fields=	[
            :access_url,
            :long_name,
            :file_names,
            :active_file,
            :file_dir,

            :variables,
            :active_variable,
            :dim_variables,
            :dim_sizes,
            :lon_limits,
            :lat_limits,

            :zoom_limits, 
            :level_range,
            :var_defs,
            :var_limits,
            :var_units,
            :var_colors,

            :grid_resolution,
			:start_time,
            :end_time,
			:time_step,
            :time_indices
        ]

Fields_Types=Dict(:access_url => String,
	:long_name => String,
	:file_names => Vector{String},
	:active_file => String,
	:file_dir => String,

	:variables => Vector{String},
	:active_variable => String,
	:dim_variables => Vector{String},
	:dim_sizes => Tuple{Int64},

	:lon_limits => Vector{Float32},
	:lat_limits => Vector{Float32},
	:zoom_limits => Vector{Float32},
	:level_range => Vector{Int64},

	:var_defs => Dict{String,String},
	:var_limits => Dict{String,Vector{Float64}},
	:var_units => Dict,
	:var_colors => Dict,

	:grid_resolution => Float32,
	:start_time => DateTime,
	:end_time => DateTime,
	:time_step => Union{Hour, Day, Week, Month, Year},
	:time_indices => Vector{Int64}
	)

function eunice_type_gen(filein::String, typename::String, fileout::String; 
		)# key word args go here

	ds = NCDataset(filein, "r")
	try
		code_lines = String[]

		# Generate the header matching your abstract type hierarchy
		push!(code_lines, "# Generated dynamically from NetCDF Metadata")
		push!(code_lines, "@kwdef mutable struct $typename <: Eunice_type")
		type_named_tuple=generate_eunice_type(filein)

		for key in Eunice_ordered_fields
			val=get(type_named_tuple,key,"")
			safe_val= isa(val,String) ? "\"$(escape_string(val))\"" : string(val)
			line = "     " * string(key) * "::" * string(Fields_Types[key]) * " = " * safe_val
			push!(code_lines,line)
		end
		push!(code_lines, "end")
		complete_code = join(code_lines, "\n")

		# Print the code directly to the console terminal screen
		println("="^40) # ======= ... ========
		println(" GENERATED JULIA CODE FOR: $typename ")
		println("="^40)
		println(complete_code)
		println("="^40)

		# Write the complete text into the file
		open(fileout, "w") do io
			write(io, complete_code)
		end
	finally
	close(ds)
	end
	return(fileout)
end
#=
Generated fields successfully for best_temperature_st1801_d4.nc:
(access_url = "Local/Model Dataset", long_name = "Native Format Berkeley Earth Surface Temperature Anomaly Field", file_names = ["best_temperature_st1801_d4.nc"], active_file = "best_temperature_st1801_d4.nc", file_dir = "/", variables = ["temperature"], active_variable = "temperature", dim_variables = ["longitude", "latitude", "time"], dim_sizes = (360, 180, 300), lon_limits = Float32[-179.5, 179.5], lat_limits = Float32[-89.5, 89.5], zoom_limits = [0.5, 4.0], level_range = Any[], var_defs = Dict("temperature" => "Air Surface Temperature Anomaly"), var_limits = Dict("temperature" => [-13.787121772766113, 14.396573066711426]), var_units = Dict("temperature" => "degree C"), var_colors = Dict("temperature" => :viridis), grid_resolution = 1.0f0, start_time = DateTime("1955-06-24T01:00:00"), time_step = Millisecond(7200000), end_time = DateTime("1955-07-18T23:00:00"), time_indices = [1, 1, 300])

========================================
 GENERATED JULIA CODE FOR: EuniceTest
========================================
# Generated dynamically from NetCDF Metadata
@kwdef mutable struct EuniceTest <: Eunice_type
     access_url="Local/Model Dataset"
     long_name="Native Format Berkeley Earth Surface Temperature Anomaly Field"
     file_names=["best_temperature_st1801_d4.nc"]
     active_file="best_temperature_st1801_d4.nc"
     file_dir="/"
     variables=["temperature"]
     active_variable="temperature"
     dim_variables=["longitude", "latitude", "time"]
     dim_sizes=(360, 180, 300)
     lon_limits=Float32[-179.5, 179.5]
     lat_limits=Float32[-89.5, 89.5]
     zoom_limits=[0.5, 4.0]
     level_range=Any[]
     var_defs=Dict("temperature" => "Air Surface Temperature Anomaly")
     var_limits=Dict("temperature" => [-13.787121772766113, 14.396573066711426])
     var_units=Dict("temperature" => "degree C")
     var_colors=Dict("temperature" => :viridis)
     grid_resolution=1.0
     start_time=1955-06-24T01:00:00
     end_time=1955-07-18T23:00:00
     time_step=7200000 milliseconds
     time_indices=[1, 1, 300]
end
========================================
Successfully saved code to: eunice_test4.jl
"eunice_test4.jl"
=#
#--------------------------------------------------------------------------------------------------
"""
    generate_eunice_type(file_path::String)

Inspects the data and metadata of a custom or model-generated NetCDF file and extracts the exact structure 
required to instantiate or suggest fields for a custom Eunice_type.
Supported signatures: [lon, lat], [lon, lat, time], or [lon, lat, lev, time].
"""
function generate_eunice_type(file_path::String)
    # Extract filename from path for the active fields
    f_name = basename(file_path)
    f_dir = dirname(file_path) * "/"
    
    NCDataset(file_path, "r") do ds
        # 1. Map dimensions robustly
        all_dims = keys(ds.dim)
 println(".")       
        # Robustly find longitude, latitude, time, and level/vertical dimensions
		lon_name = check_dim_name(all_dims, "longitude")
		lat_name = check_dim_name(all_dims, "latitude")
		time_name = check_dim_name(all_dims, "time")
		lev_name = check_dim_name(all_dims, "level")
     
        if isempty(lon_name) || isempty(lat_name)
            error("Dataset must contain identifiable longitude and latitude dimensions.")
        end
        
        # Order the dimensions strictly into your package standard
        dim_variables = String[]
        push!(dim_variables, lon_name, lat_name)
        !isempty(lev_name) && push!(dim_variables, lev_name)
        !isempty(time_name) && push!(dim_variables, time_name)
         
        dim_sizes = Tuple(ds.dim[d] for d in dim_variables)
        
        # 2. Identify core spatial/data variables
        # Exclude the 1D coordinate tracking variables themselves
        all_vars = keys(ds)
        data_vars = filter(v -> !(v in all_dims) && length(dimnames(ds[v])) >= 2, all_vars)

        active_var = data_vars[1] #first(data_vars, "")
         
        # 3. Pull coordinate limits safely
        lon_vals = ds[lon_name][:]
        lat_vals = ds[lat_name][:]
        lon_limits = [minimum(lon_vals), maximum(lon_vals)]
        lat_limits = [minimum(lat_vals), maximum(lat_vals)]
         
        # Calculate approximate grid resolution (assuming regular grid)
        grid_res = length(lon_vals) > 1 ? Float32(abs(lon_vals[2] - lon_vals[1])) : 1.0f0
         
        # 4. Handle time dimension properties if it exists
        start_time = DateTime(1970, 1, 1) # Fallbacks
        end_time = DateTime(1970, 1, 1)
        t_step = Year(1)
        t_indices = Int[]
        
        if !isempty(time_name)
            time_vals = ds[time_name][:]
            if !isempty(time_vals)
                start_time = DateTime(minimum(time_vals))
                end_time = DateTime(maximum(time_vals))
                t_len = length(time_vals)
                t_indices = [1, 1, t_len]
                
                # Deduce time step step if enough points exist
                if t_len > 1
                    delta = time_vals[2] - time_vals[1]
                    # Convert NCDatasets Dates/Periods to standard Dates periods if necessary
                    t_step = delta
                end
            end
        end
        
        # 5. Extract Level range if available
        level_range = !isempty(lev_name) ? Any[minimum(ds[lev_name][:]), maximum(ds[lev_name][:])] : Any[]
        
        # 6. Map dictionaries for variables
        var_defs = Dict{String, String}()
        var_limits = Dict{String, Vector{Float64}}()
        var_units = Dict{String, String}()
        var_colors = Dict{String, Symbol}()
         
        for v in data_vars
            # Extract metadata safely using fallbacks
            var_defs[v]   = get(ds[v].attrib, "long_name", "No description available")
            var_units[v]  = get(ds[v].attrib, "units", "unknown")
            var_colors[v] = :viridis # Default package safe-fallback color palette
            
            # Read a small subset or full array to evaluate actual data limits
            v_data = ds[v][:]
            v_clean = filter(!ismissing, v_data)
            if !isempty(v_clean)
                var_limits[v] = [Float64(minimum(v_clean)), Float64(maximum(v_clean))]
            else
                var_limits[v] = [0.0, 1.0]
            end
        end
         
        # Print out a copy-pasteable boilerplate for the user or return the values KeyTuple?
        println("Generated fields successfully for $f_name:")
        return (
            access_url = "<insert raw code web entry point>",
            long_name = get(ds.attrib, "title", "Custom Dataset"),
            file_names = [f_name],
            active_file = f_name,
            file_dir = f_dir,
            variables = collect(data_vars),
            active_variable = active_var,
            dim_variables = dim_variables,
            dim_sizes = dim_sizes,
            lon_limits = lon_limits,
            lat_limits = lat_limits,
            zoom_limits = [0.5, 4.0],
            level_range = level_range,
            var_defs = var_defs,
            var_limits = var_limits,
            var_units = var_units,
            var_colors = var_colors,
            grid_resolution = grid_res,
            start_time = start_time,
            time_step = t_step,
            end_time = end_time,
            time_indices = t_indices
        )
    end
end

#---------------------------------------------------------------------

function generate_eunice_type_file(ds::NCDataset, type_name::String, filename::String)
code_lines = String[]

# 1. Generate the header matching your abstract type hierarchy
push!(code_lines, "# Generated dynamically from NetCDF Metadata")
push!(code_lines, "@kwdef mutable struct $type_name <: Eunice_type")

# 2. Extract and format dimensions as fields
push!(code_lines, "    # --- Dimensions ---")
for (dimname, dimlen) in ds.dim
    push!(code_lines, "    dim_$dimname::Int = $dimlen")
end

# 3. Extract variables with fallback type annotations
push!(code_lines, "\n    # --- Data Variables ---")
for varname in keys(ds)
    v = ds[varname]
    # Determine element type safely, extracting it out of missing-value wraps
    el_type = eltype(v)
    push!(code_lines, "    var_$varname::Vector{$el_type} = $el_type[]")
end

# 4. Extract global attributes as metadata documentation or fields
push!(code_lines, "\n    # --- Global Metadata ---")
for (attname, attval) in ds.attrib
    # Escape strings so they don't break the generated Julia syntax
    safe_val = isa(attval, String) ? "\"$(escape_string(attval))\"" : attval
    push!(code_lines, "    meta_$attname = $safe_val")
end

push!(code_lines, "end")

# Combine everything into a single clean string
complete_code = join(code_lines, "\n")

# Print the code directly to the console terminal screen
println("="^40)
println(" GENERATED JULIA CODE FOR: $type_name ")
println("="^40)
println(complete_code)
println("="^40)

# Write the complete text into the file
open(filename, "w") do io
    write(io, complete_code)
end
println("Successfully saved code to: $filename")
end

#=
How to use this generator:
Open your target file
ds = NCDataset("site_ Eunice_data.nc", "r")

Generate the code structure, display it, and save it to 'eunice_structures.jl'
generate_eunice_type_file(ds, "EuniceSiteA", "eunice_structures.jl")

close(ds)
=#
#------------------------------------------------------------------------------

