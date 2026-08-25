# eds_extend_time_series.jl: created 14 aug 26 Gemini assistance
# version 1

"""
    extend_time_series!(input_nc::String, output_nc::String, time_dim_name::String="Time")

Takes an existing NetCDF file with a fixed Time dimension, and generates a new copy 
where the Time dimension (and all variables utilizing it) is extended by exactly 1 step.
The new time slot is initialized with missing/fill values, ready for user updates.
"""
function extend_time_series!(input_nc::String, output_nc::String, time_dim_name::String="Time")
    NCDataset(input_nc, "r") do ds_in
        # Validate that the requested time dimension actually exists
        if !haskey(ds_in.dim, time_dim_name)
            error("Dimension '$time_dim_name' not found in source file.")
        end
        
        # Calculate the new expanded size (+1 step)
        old_time_len = ds_in.dim[time_dim_name]
        new_time_len = old_time_len + 1
        
        NCDataset(output_nc, "c") do ds_out
            # 1. Copy global attributes
            for (att_name, att_val) in ds_in.attrib
                ds_out.attrib[att_name] = att_val
            end
            
            # 2. Recreate dimensions, applying the +1 expansion to the time axis
            for (dim_name, dim_len) in ds_in.dim
                if dim_name == time_dim_name
                    defDim(ds_out, dim_name, new_time_len)
                else
                    defDim(ds_out, dim_name, dim_len)
                end
            end
            
            # 3. Recreate variables and migrate existing data
            for (var_name, v_in) in ds_in
                var_dims = dimnames(v_in)
                
                # Check if this specific variable relies on the time dimension
                uses_time = time_dim_name in var_dims
                
                # Create the variable structure in the new file
                v_out = defVar(ds_out, var_name, eltype(v_in), var_dims, attrib=v_in.attrib)
                
                if uses_time
                    # Find which axis index belongs to Time (e.g., 3rd dimension in a 3D grid)
                    time_axis_idx = findfirst(==(time_dim_name), var_dims)
                    
                    # Create a slicing tuple to extract the old data structure
                    # Dynamically builds something like [:, :, 1:old_time_len]
                    colons = Any[Colon() for _ in 1:length(var_dims)]
                    colons[time_axis_idx] = 1:old_time_len
                    
                    # Map the old historical records into the new expanded array layout
                    v_out[colons...] = v_in[:]
                else
                    # If it's a static variable (like invariant ETOPO topology or baseline grids), copy it whole
                    v_out[:] = v_in[:]
                end
            end
        end
    end
end
#----------------------------------------------------------------------------------------
# version 2

"""
    extend_time_series!(input_nc::String, output_nc::String, eunice_obj)

Takes an existing NetCDF file with fixed dimensions and creates an extended copy
with exactly 1 extra time step. It identifies the correct time dimension name 
automatically using the `dim_variables` field from the provided Eunice object.
"""
function eds_extend_time_series!(input_nc::String, output_nc::String, eunice_obj)
    # Automatically locate the time dimension name from the Eunice_type object
    # Matches "time", "Times", "valid_time", etc. by checking for variations of "time"
    possible_time_names = eunice_obj.dim_variables
    time_idx = findfirst(name -> occursin("time", lowercase(name)), possible_time_names)
    
    if isnothing(time_idx)
        error("Could not automatically identify a time dimension in dim_variables: $possible_time_names")
    end
    
    time_dim_name = possible_time_names[time_idx]

    NCDataset(input_nc, "r") do ds_in
        if !haskey(ds_in.dim, time_dim_name)
            error("Dimension '$time_dim_name' not found in source file structure.")
        end
        
        # Calculate the expanded length
        old_time_len = ds_in.dim[time_dim_name]
        new_time_len = old_time_len + 1
        
        NCDataset(output_nc, "c") do ds_out
            # 1. Migrate global attributes
            for (att_name, att_val) in ds_in.attrib
                ds_out.attrib[att_name] = att_val
            end
            
            # 2. Recreate dimensions, applying +1 to the identified time axis
            for (dim_name, dim_len) in ds_in.dim
                if dim_name == time_dim_name
                    defDim(ds_out, dim_name, new_time_len)
                else
                    defDim(ds_out, dim_name, dim_len)
                end
            end
            
            # 3. Recreate variables and safely migrate data slices
            for (var_name, v_in) in ds_in
                var_dims = dimnames(v_in)
                uses_time = time_dim_name in var_dims
                
                v_out = defVar(ds_out, var_name, eltype(v_in), var_dims, attrib=v_in.attrib)
                
                if uses_time
                    # Find which array axis matches the time dimension
                    time_axis_idx = findfirst(==(time_dim_name), var_dims)
                    
                    # Dynamically slice the historical data up to old_time_len
                    colons = Any[Colon() for _ in 1:length(var_dims)]
                    colons[time_axis_idx] = 1:old_time_len
                    
                    v_out[colons...] = v_in[:]
                else
                    # Keep static grids or baseline invariant variables unchanged
                    v_out[:] = v_in[:]
                end
            end
        end
    end
end
