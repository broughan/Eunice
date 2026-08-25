# eds_thin_deflate.jl from eds_thin_deflate_3dg.jl (home 7/8 12.17pm) [drive 7/8]
# edited 11/8/26 
using NCDatasets, Dates

"""
....
"""
function eds_thin_deflate(input, output; 
			thin_space_factor=1,
			thin_time_factor=1,
			start_time_index=1,
			thin_levels_factor=1,
			deflate_level=0, # 0 ... 9
			update_metadata=false)

# Open files cleanly
	ds_in = NCDataset(input, "r")
	ds_out = NCDataset(output, "c")

try
	# generic names
	#dim_names=dimnames(ds_in) 
	#dim_names=keys(ds_in.dim) # this gives lev for the level vble z
	dim_names=keys(ds_in.dim)
println(dim_names)
	if 3 != length(dim_names) error("In eds_thin_deflate_3d: number of dims not 3.") end

	# Dynamically extract real structural strings via utils layer
	lon_name = check_dim_name(dim_names, "longitude")
	lat_name = check_dim_name(dim_names, "latitude")
	time_name = check_dim_name(dim_names, "time")
	lev_name = check_dim_name(dim_names, "level")
	istime = !isempty(time_name)
	islevel = !isempty(lev_name)

	# abreviations
	ts=thin_space_factor
	if islevel tl=thin_levels_factor end
	if istime
		tt=thin_time_factor
		st=start_time_index
	end

    # 1. Global Attributes
    for (k, v) in ds_in.attrib
        ds_out.attrib[k] = v
    end

    # Copy and Thin Dimensions

	#Define the space and levels stride ranges
    lon_slice = ts:ts:size(ds_in[lon_name], 1)
    lat_slice = ts:ts:size(ds_in[lat_name], 1)
	if islevel lev_slice = 1:tl:size(ds_in[lev_name], 1) end
	if istime time_slice = st:tt:size(ds_in[time_name], 1) end

# Copy and update dimensions
    for dim_name in keys(ds_in.dim)
		if dim_name == lon_name
            defDim(ds_out, dim_name, length(lon_slice))
        elseif dim_name == lat_name
            defDim(ds_out, dim_name, length(lat_slice))
         elseif dim_name == lev_name
            defDim(ds_out, dim_name, length(lev_slice))
         elseif dim_name == time_name
            defDim(ds_out, dim_name, length(time_slice))
        else
            defDim(ds_out, dim_name, ds_in.dim[dim_name])
        end
    end
println(3)
# 3. Define all variables uniformly
for var_name in keys(ds_in)
    v_in = ds_in[var_name]
    dim_names = dimnames(v_in)
    
    if var_name == time_name
        # Time always needs a numeric type and standard calendar attributes
        # Define the correct _FillValue type directly in the attributes dictionary
        time_attrib = [
            "units" => "days since 1950-01-01", # "year A.D.",
            "calendar" => "standard",
            "_FillValue" => NaN # Or Float64(-999.0) if you prefer a number
        ]
        v_out = defVar(ds_out, time_name, Float64, (time_name,);
				attrib = time_attrib,
				chunksizes=[1],
				deflatelevel=1,
				shuffle=true
				)
        
        for (k, v) in v_in.attrib
            # Skip units, calendar, AND the mismatched _FillValue
            if k != "units" && k != "calendar" && k != "_FillValue"
                println("k,v = ", k, v)
                v_out.attrib[k] = v
            end
        end
    else
            # STRATEGY: Strip Missing. Force a clean, uniform numeric type (e.g., Float32)
            base_type = nonmissingtype(eltype(v_in))
            v_out = defVar(ds_out, var_name, base_type, dim_names; deflatelevel=deflate_level)
            
            # Copy attributes, ensuring a strict numeric _FillValue is set
            has_fill = false
            for (k, v) in v_in.attrib
                if k == "_FillValue"
                    v_out.attrib[k] = convert(base_type, -9999.0)
                    has_fill = true
                else
                    v_out.attrib[k] = v
                end
            end
            
            # If the original variable didn't have a fill value but might need one, add it
            if !has_fill && (base_type == Float32 || base_type == Float64)
                v_out.attrib["_FillValue"] = convert(base_type, -9999.0)
            end
        end
    end
println(4)
    # 4. Process and write data without any 'Missing' interference
    for var_name in keys(ds_in)
        v_in = ds_in[var_name]
        v_out = ds_out[var_name]
        dim_names = dimnames(v_in)
        
        # [Insert your existing logic here that calculates your bounding box 'src_slices']
		# For data fields (sst, ice, time, lev) build custom source indices
        src_slices = Any[]
        for (i, d_name) in enumerate(dim_names)
            if d_name == lon_name
                push!(src_slices, lon_slice)
            elseif d_name == lat_name
                push!(src_slices, lat_slice)
            elseif d_name == time_name
                push!(src_slices, time_slice)
			else
                push!(src_slices, 1:size(v_in, i)) 
            end
        end

 println(5)       
        # Read the raw data slice
        data_chunk = v_in[src_slices...]

# Write safely to the output file using the exact size of the chunk
		if var_name == time_name
			# NCDatasets will auto-encode the thinned DateTime objects generically
			encoded_datetimes=
				if ds_in[time_name].attrib["units"]=="year A.D."
					map(dy2dt, data_chunk)
				else data_chunk
				end
			v_out[1:length(data_chunk)] = encoded_datetimes #data_chunk
		else
            # STRATEGY: Instantly replace any 'missing' with -9999.0
            # This strips the 'Missing' structure entirely. Julia now sees a pure array of numbers.
            clean_data = coalesce.(data_chunk, -9999.0)
    # Works perfectly for 1D coordinates (lat/lon) and 3D/4D data variables
			v_out[[1:size(clean_data, i) for i in 1:ndims(clean_data)]...] = clean_data
		end
    end

    println("Success! All variables thinned cleanly with uniform fill values.")

# 6 update metadata
println(6)
if update_metadata==true
        current_date = today()
        # Fetch existing history if it exists, otherwise start clean
        existing_history = get(ds_in.attrib, "history", "")
        new_entry = "Thinned and deflated $input on $current_date using Gemini code assistance, by Kevin Broughan kevbroughan@gmail.com ."       
        # Combine existing log with your new entry
        ds_out.attrib["history"] = isempty(existing_history) ? new_entry : "$existing_history\n$new_entry"
end
finally

    # will execute always even on error, but not before try
    close(ds_in)
    close(ds_out)
end # of try
return output
end
