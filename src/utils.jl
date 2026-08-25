#=
 methods:
	isa_member
	@vars_name
	antipodal_point
	PS> search for a string in files
	replace_missing
	replace_nan_func!
	min_max
	activate_backend
	check_dim_name
	dy2dt
=#
using Dates, NCDatasets

function isa_member(a, vec)
	ans=false
	for x in vec
		if a==x ans=true; break end
	end
	return ans
end
#----------------------------------------------------------------

macro vars_name(arg)
   string(arg)
end
#---------------------------------------------------

# PS> Select-String -Path '*.txt' -Pattern 'example' -Recurse -List

function antipodal_point(lon, lat)
	if lon <= 0 
		antip_lon=180-abs(lon)
	else
		antip_lon=lon-180
	end
	return (antip_lon,-lat)
end
#-----------------------------------------------------------------

function min_max_array(data)
	vec_data = vec(data)
	return [minimum(vec_data), maximum(vec_data)]
end

#-------------------------------------------------------------------------

function replace_missing(arr, replacement)
   coalesce.(arr, replacement)
end
#--------------------------------------------------------------------------

function replace_nan_func!(arr::AbstractArray{T}, replacement_value::T) where T<:AbstractFloat
    replace!(arr, NaN => replacement_value)
    return arr
end
#-----------------------------------------------------------------------

global BackEnd=nothing
function activate_backend(back_end)
 back_end.activate!()
 global BackEnd=back_end
	return(BackEnd)
end
#-----------------------------------------------------------------------
"""
    validate_and_find_dim(file_dims, target::String)

Scans the present file dimensions against a wide mapping of geophysical aliases,
including standard, ECMWF, CMIP6, and unique custom vendor quirks (e.g., Cheng).
Throws a clear error if no matching dimension is identified.
"""
function check_dim_name(file_dims, target::String)
    # Comprehensive master list mapping canonical targets to wild dimension variations
    aliases = Dict(
        "longitude" => [
            "lon", "longitude", "Longitude", "LON", "x", "X", # Standard & CF
            "LonDim"                                         # Cheng custom dimension quirk
        ],
        "latitude"  => [
            "lat", "latitude", "Latitude", "LAT", "y", "Y",   # Standard & CF
            "LatDim"                                         # Custom variant pair
        ],
        "level"     => [
            "lev", "level", "levels", "pff", "plev", "levs",  # Standard & Legacy
            "z", "Z", "depth", "pressure", "isobaric"         # Vertical variants
        ],
        "time"      => [
            "time", "Time", "TIME", "t", "T",                 # Standard
            "valid_time", "Times", "leadtime", "forecast_time"# ECMWF / single use
        ])
    
    # Check the dictionary configuration for our target axis
    for alias in get(aliases, target, [target])
        if alias in file_dims
           return alias # Returns the exact match found inside the NetCDF file
		end
    end
	return ""
    
    #= Catch-all descriptive error if a file is truly unmapped or broken
    println("WARNING: Could not dynamically resolve the axis for: '$target'.\n" *
          "Available file dimensions are: $(collect(file_dims)).\n" *
          "Action: If necessary, please append this missing dimension string directly to the 'utils.jl' appropriate term of check_dim_name method.")
=#
end
#------------------------------------------------------------------------------------------

function decimal_year_to_datetime(val::Float64)
    year_int = floor(Int, val)
    remainder = val - year_int
    
    # Calculate exact milliseconds in this specific year (accounts for leap years)
    year_start = DateTime(year_int, 1, 1)
    next_year_start = DateTime(year_int + 1, 1, 1)
    ms_in_year = Dates.value(next_year_start - year_start)
    
    # Calculate elapsed milliseconds and add to the start of the year
    elapsed_ms = round(Int, remainder * ms_in_year)
    return year_start + Millisecond(elapsed_ms)
end
dy2dt=decimal_year_to_datetime 
#--------------------------------------------------------------------------------------
