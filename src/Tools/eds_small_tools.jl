# eds_small_tools.jl created 14 aug 26 with Gemini assistance. 
#=
functions:
	eds_metadata
	update_variable_attrib!
	remove_variable_attrib!
	update_global_attrib!
	remove_global_attrib!
	update_data!
	append_time_step! (along an Inf dimensional time array)
		See also the tools eds_extend_timeseries! and eds_eunice_extend_timeseries! for a given dimensional time array
=#
using NCDatasets, Dates
#---------------------------------------------------------------------------------------
"""
This function writes the metadata of a CF compliant .nc or .nc4 file, file_in to a text file, file_out. Optionally, it will also copy the complete metadata to the screen. This is often quite a lot of information, so the motivation for this function is to provide a reusable text file and reduce the clutter on the Julia screen.

function eds_metadata(file_in, file_out; 
		write_to_screen=false) # otherwise true
"""

function eds_metadata(file_in::String, file_out::String; 
						write_to_screen::Bool=false) # else true
# Open the netCDF file
	metadata = NCDataset(file_in, "r") # file_in must be .nc or .nc4
	try
		# Write the metadata display directly to the text (normally .txt) file
		open(file_out, "w") do io
			show(io, "text/plain", metadata)
		end
		if write_to_screen
			println(metadata)
		end
	finally
		# Always close the dataset when done
		close(metadata)
	end
	return file_out
end
#---------------------------------------------------------------------------------

"""
This function updates or adds a specific attribute to the metadata of a single variable.

    update_variable_attrib!(ds::NCDataset, var_name::String, attrib_name::String, value)

"""
function update_variable_attrib!(file_in::String, var_name::String, attrib_name::String, value)
	ds=Dataset(file_in,"a")
	try
		if haskey(ds, var_name)
			ds[var_name].attrib[attrib_name] = value
		else
			error("In update_variable_attrib!. Variable '$var_name' not found in dataset.")
		end
	finally
		close(ds)
	end
end
#---------------------------------------------------------------------------

"""
This function removes an attribute from a variable if it exists. 						remove_variable_attrib!(file_in::String, var_name::String, attrib_name::String)

"""
function remove_variable_attrib!(file_in::String, var_name::String, attrib_name::String)
	ds=Dataset(file_in, "a")
	try
		success=false
		if haskey(ds, var_name) && haskey(ds[var_name].attrib, attrib_name)
			delete!(ds[var_name].attrib, attrib_name)
			success=true
		end
	finally
		close(ds)
		return success
	end
end
#----------------------------------------------------------------------------

"""
This function updates or adds a global attribute (e.g., "conventions" => "CF-1.8").
    update_global_attrib!(file_in::String, attrib_name::String, value)
"""
function update_global_attrib!(file_in::String, attrib_name::String, value)
	ds=Dataset(file_in,"a")
	try
		ds.attrib[attrib_name] = value
	finally
		close(ds)
	end
end
#----------------------------------------------------------------------
"""
This function removes a global file-level attribute.
    remove_global_attrib!(file_in, attrib_name::String)
"""
function remove_global_attrib!(file_in, attrib_name::String)
	ds=Dataset(file_in, "a")
	try
		success=false
		if haskey(ds.attrib, attrib_name)
			delete!(ds.attrib, attrib_name)
			success=true
		end
	finally
		close(ds)
		return success
	end
end
#---------------------------------------------------------------------------

## The Difficult One: update_data! and remove_data!
## 1. Overwriting Existing Data (Easy)
If a user just wants to correct values without changing the spatial dimensions (e.g., filling in missing values or replacing a corrupted grid cell), they can mutate the array directly using the [:] or standard indexing syntax.

function update_data!(file_in::String, var_name::String, new_data::AbstractArray)
	ds=Dataset(file_in, "a")
	try
		success=false
		if haskey(ds, var_name)
			# The sizes must match exactly
			if size(ds[var_name]) == size(new_data)
				ds[var_name][:] = new_data
			success=true
			else
				error("In update_data!: dimension mismatch. Existing size: $(size(ds[var_name])), New size: $(size(new_	data))")
			end
		end
	finally
		close(ds)
		return success
	end
end
#---------------------------------------------------------------------------------
"""
    append_time_step!(ds::NCDataset, var_name::String, new_slice::AbstractArray)

Appends a new time slice to a variable along its unlimited (Time) dimension.
Assumes Time is the last dimension of the variable.
"""
function append_time_step!(ds::NCDataset, var_name::String, new_slice::AbstractArray)
    if !haskey(ds, var_name)
        error("Variable '$var_name' not found.")
    end
    
    # Get current dimensions of the variable
    current_size = size(ds[var_name])
    last_dim_idx = length(current_size)
    
    # Calculate the next available index along the time axis
    next_time_index = current_size[last_dim_idx] + 1
    
    # Create a dynamic slicing tuple (e.g., [:, :, next_time_index])
    # This keeps spatial dimensions whole and appends to the new time slot
    colons = Any[Colon() for _ in 1:(last_dim_idx-1)]
    push!(colons, next_time_index)
    
    # Write the new data slice to the disk
    ds[var_name][colons...] = new_slice
end

## An Example of "Time Marching On"
When a new year of Cheng data arrives, a Eunice user would do this:

   1. Append the new timestamp value to the Time variable itself:
   
   # If current time length is 164, this adds the 165th coordinate entry
   append_time_step!(ds, "Time", [2015.0]) 
   
   2. Append the matching grid data to the climate variable (like temperature):
   
   # Appends the new 2D spatial grid to the 165th slot of the 3D variable
   append_time_step!(ds, "temperature", new_2d_grid_for_2015)
#----------------------------------------------------------------------------------

