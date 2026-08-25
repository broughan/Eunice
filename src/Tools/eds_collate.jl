# eds_collate.jl from eds_collate_3d_6.jl (home 28/7 5.47pm) [drive 28/7]
# edited 11/8

using NCDatasets
using Glob
using Dates

"""
    eds_collate(input_dir::String, file_mask::String, output_file::String; 
                      deflate_level::Int=0, 
                      aggdim::String="time",
                      update_metadata=false,
                      time_units=nothing,      # New: Override target time units
                      time_calendar=nothing)   # New: Override target calendar

Scans `input_dir` for files matching `file_mask`, safely sorts them based on internal file timelines, 
and chains them sequentially into a single consolidated, compressed output file.
"""

wrapped_indices(dims) = Tuple(Colon() for _ in 1:length(dims))

function eds_collate(input_dir::String, file_mask::String, output_file::String; 
		deflate_level::Int=0, 
		aggdim::String="time",
		update_metadata=false,
		include_dims=[],
		include_vars=[],
		time_units=nothing,      # Nothing inherits source units; String overrides them
		time_calendar=nothing)   # Nothing inherits source calendar; String overrides them
    
    # 1. SCAN DIRECTORY FOR MATCHING FILES
    raw_files = glob(file_mask, input_dir)
    if isempty(raw_files)
        error("No files found matching mask '$file_mask' in directory '$input_dir'")
    end

	# 1.1 use generic names from the first raw_files
	file1=first(raw_files)
	ds1=NCDataset(file1,"r")
	dim__names=keys(ds1.dim)

println("original dimensions = ", dim__names)

	# Dynamically extract real structural strings via utils layer
	lon_name = check_dim_name(dim__names, "longitude")
	lat_name = check_dim_name(dim__names, "latitude")
	time_name = check_dim_name(dim__names, "time")
	lev_name = check_dim_name(dim__names, "level")
	istime = !isempty(time_name) # else isempty time_name == ""
	islevel = !isempty(lev_name)
	if !istime error("In eds_collate: missing a time dimension") end
	dim_names= if islevel 
					(lon_name, lat_name, lev_name, time_name)
				else 
					(lon_name, lat_name, time_name)
				end
				
	# check signature and coordinates
		sig = if (istime && !islevel) 3
			elseif (istime && islevel) 4
			elseif !istime 
			else nothing
			end

	if (sig==3 && !(dim_names in [(lon_name, lat_name, time_name), 
								(lat_name, lon_name, time_name)]))
			error("In eds_collate: $dim_names is an invalid signature")
	end

	if (sig==4 && !(dim_names in [(lon_name, lat_name, lev_name, time_name), 
								(lat_name, lon_name, lev_name, time_name)]))
			error("In eds_collate: $dim_names is an invalid signature")
	end

	# warn if lon, lat is swopped:
	if  (dim_names[1],dim_names[2]) == (lat_name, lon_name)
        @warn "In eds_collate: reversed lon,lat dimensions. Use permutedims for climate variables before plotting."
	end

    # 2. BULLETPROOF SORTING: Parse the actual internal time dimension of each file
    println("Scanning internal file metadata timelines for chronological alignment...")
    file_time_pairs = Tuple{String, Any}[]
    
    for fname in raw_files
        NCDataset(fname, "r") do ds
            if haskey(ds, aggdim) && length(ds[aggdim]) > 0
                first_timestamp = ds[aggdim][1]
                push!(file_time_pairs, (fname, first_timestamp))
            else
                push!(file_time_pairs, (fname, DateTime(1900, 1, 1)))
            end
        end
    end
    
    sort!(file_time_pairs, by = x -> x[2])
    file_list = [pair[1] for pair in file_time_pairs]
    
    println("Found $(length(file_list)) files. Confirmed timeline sorted perfectly.")

    # 3. OPEN THE VIRTUAL MULTI-FILE AGGREGATION VIEW
	aggdim = time_name
    ds_in = NCDataset(file_list, "r", aggdim = aggdim)
    
    isfile(output_file) && rm(output_file)
    ds_out = NCDataset(output_file, "c")
    
    try
 
        # 5. DEFINE ALL DIMENSIONS DYNAMICALLY

        for (dimname, dimlen) in ds_in.dim
           if dimname in dim_names defDim(ds_out, dimname, dimlen) end
        end

        # 6. TRANSFER AND COMPRESS VARIABLES DYNAMICALLY

        # --- PASS 1: Initialize Core Coordinate Dimensions First ---
		coord_names = dim_names 
        for varname in keys(ds_in)
			v_src = ds_in[varname]
            v_dims = dimnames(v_src)
            v_type = nonmissingtype(eltype(v_src))
            if lowercase(varname) in coord_names
              
		# Case A: the coordinate vectors themselves
	                
				attrib_dict = Dict(k => v for (k, v) in v_src.attrib)
                
				# Identify if this is a time/date channel
				is_datetime = v_type <: Dates.AbstractTime || 
					(haskey(attrib_dict, "units") && 
						occursin("since", string(get(attrib_dict, "units", ""))))
                
				if is_datetime
					v_type = Float64  # Store numerical timeline markers
                    
					# Apply manual keyword overrides, fall back to source attributes, or use system defaults
					target_units = isnothing(time_units) ? get(attrib_dict, "units", "seconds since 1970-01-01 00:00:00") : time_units
					target_calendar = isnothing(time_calendar) ? get(attrib_dict, "calendar", "standard") : time_calendar
                    
					attrib_dict["units"] = target_units
					attrib_dict["calendar"] = target_calendar
                    
					# Convert Julia DateTime array into standard CF-compliant numeric values
					data_to_write = NCDatasets.timeencode(v_src[:], target_units, target_calendar)
				else
					data_to_write = v_src[:] # non time coordinates
				end
                
				if !haskey(ds_out, varname)
					v_dst = defVar(ds_out, varname, v_type, v_dims; attrib = attrib_dict)
					v_dst[:] = data_to_write
					println("  -> Successfully initialized coordinate $varname")
					continue
				end
			end # Case A

			# CASE B: It is a valid climate data grid matching your signatures

			if v_dims in [(lon_name, lat_name, time_name), (lon_name, lat_name, lev_name, time_name),
						(lat_name, lon_name, time_name), (lat_name, lon_name, lev_name, time_name)]
				println("Extracting valid data variable: $varname with dimensions:  $v_dims")

				if varname in keys(ds_in)
					if haskey(ds_out, varname)
						continue # then skip the rest of the current loop iteration
					end
            #=
					if !isnothing(include_vars) && !isempty(include_vars)
						if !(varname in include_vars)
							continue
						end
					end
            =#
					v_src = ds_in[varname]
					v_dims = dimnames(v_src)
					v_type = nonmissingtype(eltype(v_src))
            
					attrib_dict = Dict{String, Any}()
					for (k, v) in v_src.attrib
						attrib_dict[k] = v
					end

					# time block safety check  goes here
					# Safety check if a secondary data variable somehow contains raw Dates
					is_datetime = v_type <: Dates.AbstractTime
					if is_datetime
						v_type = Float64
						target_units = isnothing(time_units) ? "seconds since 1970-01-01 00:00:00" : time_units
						target_calendar = isnothing(time_calendar) ? "standard" : time_calendar
                
						attrib_dict["units"] = target_units
						attrib_dict["calendar"] = target_calendar
						raw_data = NCDatasets.timeencode(v_src[:], target_units, target_calendar)
					else
						raw_data = v_src[:]
					end

#					raw_data = v_src[:]
            
					if haskey(attrib_dict, "_FillValue")
						attrib_dict["_FillValue"] = convert(v_type, attrib_dict["_FillValue"])
					end
            
					is_spatial_grid = length(v_dims) > 1
					if is_spatial_grid
						v_dst = defVar(ds_out, varname, v_type, v_dims; deflatelevel = deflate_level, attrib = attrib_dict)
					else
						v_dst = defVar(ds_out, varname, v_type, v_dims; attrib = attrib_dict)
					end
            
					# STREAM AND WRITE COMBINED ARRAYS
					fill_val = get(attrib_dict, "_FillValue", nothing)
					if !isnothing(fill_val)
						clean_data = coalesce.(raw_data, v_type(fill_val))
						v_dst.var[wrapped_indices(v_dims)...] = clean_data
					else
						v_dst[:] = raw_data
					end
            
					println("  -> Successfully merged data variable: $varname")
				end # for loop
			else
				# Case C: skipping a metadata variable which does not fit the criteria
					println("Skipping metadata variable $varname with dimensions $v_dims")
				continue
			end # of cases A,B,C
		end # end of for loop over varnames

		#conditionally updatea metadata
        for (k, v) in ds_in.attrib
            ds_out.attrib[k] = v
        end
		if update_metadata
            existing_history = get(ds_in.attrib, "history", "")
            new_history = "Collated $(length(file_list)) files chronologically via eds_collate_3d on $(today())."
            ds_out.attrib["history"] = isempty(existing_history) ? new_history : "$existing_history\n$new_history"
        end      
        println("\nProcessing complete! Consolidated dataset safely compiled at: ", output_file)
    finally
		close(ds1)
        close(ds_in)
        close(ds_out)
    end # try
	return output_file
end # fun

#---------------------------------------------------------------------------------------------------------
#=
# 1. Define the exact dimension signatures you want to keep
const VALID_DATA_SIGNATURES = Set([
    ("lon", "lat"),
    ("lon", "lat", "time"),
    ("lon", "lat", "lev", "time"),
    ("lat", "lon", "time") # Exception rule for Oscar2 data
])

# 2. Define the core coordinate variables you always need to preserve
const CORE_COORDINATES = Set(["lon", "lat", "time", "times", "valid_time", "longitude", "latitude"])

# 3. Apply the filter inside your processing loop
for var_name in keys(ds_in)
    v_in = ds_in[var_name]
    dims = dimnames(v_in) # Returns a tuple of strings, e.g., ("lon", "lat")
    
    # CASE A: It is a critical coordinate track (the coordinate vectors themselves)
    if var_name in CORE_COORDINATES
        println("Preserving essential coordinate: ", var_name)
        # -> YOUR CODE HERE: Copy coordinate variable to the new file
        continue
    end
    
    # CASE B: It is a valid climate data grid matching your signatures
    if dims in VALID_DATA_SIGNATURES
        println("Extracting valid data variable: ", var_name, " with dimensions: ", dims)
        # -> YOUR CODE HERE: Process/Extract/Collate this variable
        
    # CASE C: It is a metadata variable that doesn't match your criteria
    else
        # This will silently catch and discard 'crs', 'climatology_bnds', etc.
        println("Skipping metadata variable: ", var_name, " (Dimensions: ", dims, ")")
        continue
    end
end

julia> eds_collate_3d("./", "*3_v*.nc","test_collate4.nc")
Scanning internal file metadata timelines for chronological alignment...
Found 31 files. Confirmed timeline sorted perfectly.
Skipping metadata variable crs with dimensions ()
  -> Successfully initialized coordinate time
Skipping metadata variable climatology_bnds with dimensions ("nv", "time")
  -> Successfully initialized coordinate latitude
Skipping metadata variable lat_bnds with dimensions ("nv", "latitude")
  -> Successfully initialized coordinate longitude
Skipping metadata variable lon_bnds with dimensions ("nv", "longitude")
Skipping metadata variable nv with dimensions ("nv",)
Extracting valid data variable: sla with dimensions:  ("longitude", "latitude", "time")
  -> Successfully merged data variable: crs
  -> Successfully merged data variable: climatology_bnds
  -> Successfully merged data variable: lat_bnds
  -> Successfully merged data variable: lon_bnds
  -> Successfully merged data variable: nv
  -> Successfully merged data variable: sla
  -> Successfully merged data variable: eke
Extracting valid data variable: eke with dimensions:  ("longitude", "latitude", "time")

Processing complete! Consolidated dataset safely compiled at: test_collate4.nc

julia> ds=Dataset("test_collate4.nc", "r");

julia> keys(ds)
10-element Vector{String}:
 "time"
 "latitude"
 "longitude"
 "crs"
 "climatology_bnds"
 "lat_bnds"
 "lon_bnds"
 "nv"
 "sla"
 "eke"


=#
