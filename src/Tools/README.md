# Dataset Tools

## Introduction

While exploring climate related datasets I found there was a need to use NCDatasets.jl (or other package) functions to perform a range of operations on the data of interest which was available. For example global data was available in monthly files. It was easier to work with one file with one set of metadata rather than many .nc files, combing them along a time axis with one set of variable and universal attributes. This motivated the use of collation.

As another example, many datasets had data for two or more climate variables, sometimes of the order of 10. Users would want to consier these one at a time, at least initially. This motivated the use of extraction.

A final example. Initially the datsets where split into two groups, with a majority under 100MB but many over that GitHub file size limit. To reduce the size the simple operation called "thinning" was used (for example taking every second data point reducing the resolution by a divisor 2). Combining this with compression (called "deflation" in NCDatasets.jl), a final family of datasets was derived, with each being under the GitHub limit.

At the start of this development, individual Julia functions were written, one for each dataset and process. The functions were hand crafted, with for example the values along the time axis entered "by hand", towards the end. To reduce the maintenance load and offer support for users with their own dataset needs, a set of generic functions were designed and written. The AI Gemini gave very active assistance in this task.

In this README.md there are two types of function: metadata manipulation - to show or change aspects of the metadata without copying the files, and dataset transformation functions - to update, append new values copying the data, or append new values inplace. The only function which uses the existing Eunice type system is eds_eunice_extend_timeseries! .

To use these functions ensure the packages NCDatasets.jl and Dates.jl are added to the Julia process, ensure the directory/folder ../Eunice.jl/Tools  is copied down from GitHub, and then go
```Julia
julia>> include("<users Eunice path>/Tools/eds_tools.jl")
```

### Functions:
-	eds_metadata
-	update_variable_attrib!
-	remove_variable_attrib!
-	update_global_attrib!
-	remove_global_attrib!
-	eds_collate
-	eds_extract
-	eds_thin_deflate
-	update_data!
-	append_time_step! (along an Inf dimensional time array)
-	eds_extend_timeseries! for a given dimensional time array
-	eds_eunice_extend_timeseries!

## Metadata Manipulation Functions


### eds_metadata

This function writes the metadata of a CF compliant .nc or .nc4 file, file_in to a text file, file_out. Optionally, it will also copy the complete metadata to the screen. This is often quite a lot of information, so the motivation for this function is to provide a reusable text file and reduce the clutter on the Julia screen.

```Julia
	eds_metadata(file_in, file_out; 
			write_to_screen=false) # otherwise true
```

### update_variable_attrib!

This function updates or adds a specific attribute to the metadata of a single variable.
```Julia
	update_variable_attrib!(ds::NCDataset, var_name::String, attrib_name::String, value)
```
### remove_variable_attrib!

This function removes an attribute from a variable if it exists. 						remove_variable_attrib!(file_in::String, var_name::String, attrib_name::String)
```Julia
	remove_variable_attrib!(file_in::String, var_name::String, attrib_name::String)

### update_global_attrib!

This function updates or adds a global attribute (e.g., "conventions" => "CF-1.8").
```Julia
    update_global_attrib!(file_in::String, attrib_name::String, value)
```

### remove_global_attrib!

This function removes a global file-level attribute.
```Julia
	remove_global_attrib!(file_in, attrib_name::String)
```

## Dataset Manipulation Functions


### eds_collate

This function scans `input_dir` for files matching `file_mask`, safely sorts them based on internal file timelines, 
and chains them sequentially into a single consolidated, compressed output file.
```Julia
    eds_collate(input_dir::String, file_mask::String, output_file::String; 
                      deflate_level::Int=0, 
                      aggdim::String="time",
                      update_metadata=false,
					  include_dims=[],
                      include_vars=[],
                      time_units=nothing,      # New: Override target time units
                      time_calendar=nothing)   # New: Override target calendar
```

### eds_extract

This function extracts multiple variables from `input_path` and saves them together into a single `output_path`.
Automatically generates and copies matching coordinate axes (like longitude, latitude, valid_time).
```Julia
	eds_extract(input_path::String, output_path::String, varnames::Vector{String};
					update_metadata=false)
```

### eds_thin_deflate

```Julia
	eds_thin_deflate(input, output; 
			thin_space_factor=1,
			thin_time_factor=1,
			start_time_index=1,
			thin_levels_factor=1,
			deflate_level=0, # 0 ... 9
			update_metadata=false)
```
### eds_process_2d

The function takes a .nc file containing a single .nc dataset with (relative)
pathname infile containing a set of 2 dimensional, lon,lat variables and any number of other variables, thins a named variable with : replaced by d:d:end where d is the thinning factor, and applies the defVar function to the non-dimensional varibles with keyword deflatelevel taking the value deflate_level. Finally the function updates the metadata according to whether or not the update_metadata keyword is true or false.

The outfile is written to the current directory. The deflate level is close to optimal in many cases but the thinning factor will make a very significant difference if increased.

```Julia
eds_process_2d(infile, outfile, varnames::Vector{String}; 
			thin_space_factor=2,
			deflate_level=4,
			update_metadata = false)
```

Note that longitude and latitude may have different names which will require different keyword values. To find the names of variables inspect the Eunice_type *.jl files.

## Dataset Update Functions

### eds_extend_timeseries

The function takes an existing NetCDF file with a fixed Time dimension, and generates a new copy 
where the Time dimension (and all variables utilizing it) is extended by exactly 1 step.
The new time slot is initialized with missing/fill values, ready for user updates.

```Julia
    extend_timeseries!(input_nc::String, output_nc::String, time_dim_name::String="Time")
```

### eds_eunice_extend_timeseries

 This function takes an existing NetCDF file with fixed dimensions and creates an extended copy
with exactly 1 extra time step. It identifies the correct time dimension name 
automatically using the `dim_variables` field from the provided Eunice object.
The function automatically locates the time dimension name from the Eunice_type object. It
matches "time", "Times", "valid_time", etc. by checking for variations of "time".
```Julia
	eds_eunice_extend_timeseries!(input_nc::String, output_nc::String, eunice_obj)
```

### update_data!

If a user just wants to correct values without changing the spatial dimensions (e.g., filling in missing values or replacing a corrupted grid cell), they can mutate the array directly using the [:] or standard indexing syntax.
```Julia
	update_data!(file_in::String, var_name::String, new_data::AbstractArray)
```

### append_time_step!

The function appends a new time slice to a variable along its unlimited (Time) dimension.
It assumes Time is the last dimension of the variable.
```Julia
	append_time_step!(ds::NCDataset, var_name::String, new_slice::AbstractArray)
```

## An Example of "Time Marching On"
When a new year of Cheng data arrives, a Eunice user would do this:

1. Append the new timestamp value to the Time variable itself.
If the current time length is 164, this adds the 165th coordinate entry.
```Julia
  append_time_step!(ds, "Time", [2015.0]) 
```
   
2. Append the matching grid data to the climate variable (like temperature):
This step appends the new 2D spatial grid to the 165th slot of the 3D variable
```Julia
   append_time_step!(ds, "temperature", new_2d_grid_for_2015)
```