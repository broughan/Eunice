# edited 13/8/26. Was eds_thin_deflate_2d_4.jl changed to extract a list of climate vars with sims lon,lat.


using NCDatasets,Dates

"""
file_names::Dict extracted from the mutable struct ETOPO < Eunice_type
"""

file_names::Dict{String,String}=
		Dict("surface"=>"ETOPO_2022_v1_60s_N90W180_surface.nc",
		"bed"=>"ETOPO_2022_v1_60s_N90W180_bed.nc",
		"geoid"=>"ETOPO_2022_v1_60s_N90W180_geoid.nc")

"""
eds_process_2d takes a .nc file containing a single .nc dataset with (relative)
pathname infile containing a set of 2 dimensional, lon,lat variables and any number of other variables, thins a named variable with : replaced by d:d:end where d is the thinning factor, and applies the defVar function to the non-dimensional varibles with keyword deflatelevel taking the value deflate_level. Finally the function updates the metadata according to whether or not the update_metadata keyword is true or false.

The outfile is written to the current directory. The deflate level is close to optimal in many cases but the thinning factor will make a very significant difference if increased.

function eds_process_2d(infile, outfile, varnames::Vector{String}; 
			thin_space_factor=2,
			deflate_level=4,
			update_metadata = false)

Note that longitude and latitude may have different names which will require different keyword values. To find the names of variables inspect the Eunice_type *.jl files.

"""

function eds_process_2d(infile::String, outfile::String, varnames::Vector{String}; 
			thin_space_factor=2, # if 2 gives 1/30 deg, 3 gives 1/20, 4 gives 1/15 deg
			deflate_level=4,
			update_metadata = false)

	ds_in = NCDataset(infile, "r")
    ds_out = NCDataset(outfile, "c")

	try
		# get the longitude and latitude names:
		dim_names = keys(ds_in.dim)

		lon_name=check_dim_name(dim_names, "longitude")
		lat_name=check_dim_name(dim_names, "latitude")
		if !isempty(check_dim_name(dim_names,"level")) error("In eds_thin_deflate_2d: no level dimension permitted") end
		if !isempty(check_dim_name(dim_names,"time")) error("In eds_thin_deflate_2d: no time dimension permitted") end

		# Define your thinning stride (e.g., step=2 extracts every 2nd data point)
		d=thin_space_factor
    
    # Create the new lightweight dataset

        # 0. Copy Global Attributes
		for (k, v) in ds_in.attrib
			ds_out.attrib[k] = v
		end  

        # 1. Downsample and copy dimensions
        defDim(ds_out, eval(lon_name), length(ds_in[lon_name][d:d:end]))
        defDim(ds_out, eval(lat_name), length(ds_in[lat_name][d:d:end]))

		# 2. Define thinned coordinate variables
        defVar(ds_out, lon_name, Float64, (lon_name,))
        defVar(ds_out, lat_name, Float64, (lat_name,))
		ds_out[lon_name][:] = ds_in[lon_name][d:d:end]
        ds_out[lat_name][:] = ds_in[lat_name][d:d:end]
             
        # 3. Define thinned non-dimensional variables , ie climate variables
        # Match the naming convention of ETOPO file (usually 'z', 'elevation', or 'height', not a dim here)
		for varname in varnames
			v_in = ds_in[varname]
			base_type = nonmissingtype(eltype(v_in))
			v_out=defVar(ds_out, varname, base_type, (lon_name, lat_name), deflatelevel=deflate_level) 

			# write the metadata for varname
			# STRATEGY: Strip Missing. Force a clean, uniform numeric type (e.g., Float32)
            
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

        
        # 4. Write data to disk using the stride step
      
			ds_out[varname][:, :] = ds_in[varname][d:d:end, d:d:end]
		end

        
        # Optional: Add metadata description
		if update_metadata
			ds_out.attrib["update"] = "Thinned and deflated dataset for Eunice.jl on $today() by kevbroughan@gmail.com with linear thinning factor $d and deflatelevel $deflate_level ."
		end
    finally
	close(ds_in)
	close(ds_out)
	end

	return outfile
end
