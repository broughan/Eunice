# ETOPO_orography.jl -> oro.jl

#=
project=
functions:
	render_static_data
	Isimip 
	

Variables:
	lat 10800
	lon 21600
	z (21600 x 10800)
all Float64
=#
#---------------------------------------------------------------
# packages to be first installed (] add PackageName no .jl)
	using NCDatasets
	using GeoMakie
	using CairoMakie
	using GeometryBasics
	using Printf

#include("utils.jl") # <<---------------------- fix
#-------------------------------------------------------------------------
#=
function render_static_data(stvar;  _divisor=1) # 1=deg min 30 or 60 are good 0.5 and 1 deg
	ETOPO_file_path = "..\\Artifacts\\ETOPO\\ETOPO_2022_v1_60s_N90W180_" * stvar * ".nc"
	ds = Dataset(ETOPO_file_path, "r")
# Extract variables
	div=_divisor
	dlon = ds["lon"][div:div:end]
	dlat = ds["lat"][div:div:end]
	dz = ds["z"][div:div:end,div:div:end]
	return (dlon, dlat, dz)
end
=#
#--------------------------------------------------------------
function render_static_data(x::Eunice_type, view_lon, view_lat;
				option=:plot, # or :antipodal or :movie - just rotation
				stvar=x.active_variable,
				width = 800,
				_div=1,
				color_map=:diverging_rainbow_bgymr_45_85_c67_n256, 
				frame_rate = 10,
				output_plot = string(typeof(x)) * "_"  * stvar * ".png", 
				output_movie = string(typeof(x)) * "_" * stvar * ".mp4")
println("check var name:")
#=
	expected_variables = ("surface", "geoid", "bed")
	if !(isa(stvar, String) && isa_member(stvar, expected_variables)) 
		error("In ETOPO_oro_movie: incorrect variable name $stvar")
	end
=#	
println("extract some values from the type:")
	stvar=x.active_variable
	type=typeof(x)
	stype=string(type)
	file_path = x.file_dir * x.active_file
	lo=x.lon_limits
	la=x.lat_limits
	antipodal = (if option==:antipodal true else false end)
	
println("extract the data:")
	ds = Dataset(file_path, "r")
	dvar = ds[stvar][_div:_div:end,_div:_div:end]
	#close(ds) lazy loading!

println("Set up figure and axis with orthographic projection:" )
    if option==:antipodal two_width=2*width else two_width=width end
    fig = Figure(size = (two_width,width))
	lon_obs = Observable(view_lon)
	lat_obs = Observable(view_lat)
	#destnode = @lift("+proj=ortho +lon_0=$lon_obs +lat_0=$lat_obs")
	destnode = lift(lat_obs, lon_obs) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	#dest_node = "+proj=ortho +lon_0=$(view_lon) +lat_0=$(view_lat)"

	ax = GeoAxis(fig[1, 1];
        dest = destnode,
        title = stype * "_" * stvar * " plot",
		titlesize=25.0)

	 surface!(ax, lo[1]..lo[2], la[1]..la[2], dvar; 
			colormap = color_map, 
			interpolate=false)
	xlims!(ax, lo[1], lo[2]);ylims!(ax, la[1], la[2])

    # Add coastlines once
	lines!(ax, GeoMakie.coastlines(); 
		linestyle = :solid, 
		linewidth = 2, 
		color=:black)

println("antipodal plot:")
if antipodal
	(back_lon, back_lat)=antipodal_point(view_lon, view_lat)
	back_proj= "+proj=ortho +lon_0=$back_lon +lat_0=$back_lat"
	ax2 = GeoAxis(fig[1, 2];
        dest = back_proj,
        title = "Antipodal plot",
		titlesize=25.0)

	xlims!(ax, lo[1], lo[2]);ylims!(ax, la[1], la[2])

    # temp is not the observable - see JRA55_explore for the alternative
    #temp_data = Observable(temp[:, :, time_index])
    hm = surface!(ax2, lo[1]..lo[2], la[1]..la[2], dvar; colormap = color_map, interpolate=false)

    # Add coastlines once
	lines!(ax2, GeoMakie.coastlines(); 
		linestyle = :solid, 
		color=:black,
		linewidth = 2)
end
   
println("Add colorbar:")
	fig_=(if antipodal fig[2,1:2] else fig[2,1] end)
    Colorbar(fig_;#,hm; 
		label = stype * "_" * stvar, 
		colormap=color_map,
		limits=get(x.var_limits, stvar, [0,1]),
		lowclip=:white,
		highclip=:black,
		width=div(8*width,10), 
		vertical=false)

    # Save the initial frame
    display(fig)
    save(output_plot, fig)

println("record a movie:")
if output_movie != ""
    record(fig, output_movie; framerate=frame_rate) do io
		for lon in -180:10:180
			@info "longitude = $long"
			ax.title[] = string(long) * "°"
			lon_obs[] = lon #"+proj=ortho +lon_0=$lon +lat_0=$view_lat"
			recordframe!(io)
		end
	end
end

	return output_plot * " " * output_movie
end

#-------------------------------------------------------------------------
#=
@info "frame $time_index"
#display(fig)
#time_=time_obs[]
save(joinpath(output_dir, 
				@sprintf("frame%04d.png",time_index)), fig;
				size=(1920,1080),
				pt_per_unit = 0.75, 
				px_per_unit = 1.0)
dvar=nothing
return output_plot
end
#-----------------------------------------------------------------------------

function oisst_multiple_plots(stvar, month, nplots, view_lon, view_lat; figure_size=(1920, 1080))
	for n in 1:nplots
		oisst_plot(stvar, month, view_lon, view_lat;
				width = figure_size[2],
				time_index=n,
				color_map=:diverging_rainbow_bgymr_45_85_c67_n256,
				output_plot = "oisst_plot_1982_2024_yearly.png",
				output_dir = "frames3")
	end
	return true
end
#--------------------------------------------------------------
 PS

run(`ffmpeg -framerate 30 -i frames3/frame%04d.png -c:v libx264 -crf 18 -pix_fmt yuv420p oisst_ffmpeg_81w_27n_1982_2024.mp4`) # NZ

=#
#-------------------------------------------------------------------

#=
# use the ISIMIP land mask to get the data:
ds=Dataset("../Artifacts/ISIMIP/landseamask.nc", "r")
lon_mask=ds["lon"][:] # -180 -> 180
lat_mask=ds["lat"][:]  # 90 -> -90
land_mask=ds["mask"][:,:]
println("land_mask unique = ", unique(land_mask))
println("land_mask size = ", size(land_mask))
println("lengths lon lat mask = ", [length(lon_mask), length(lat_mask)])

lat_mask=reverse!(lat_mask)
land_mask=reverse!(land_mask, dims=2)

# ocean_mask = replace(land_mask, 1.0=> NaN, 0.0=>1.0)
ocean_mask = ifelse.(land_mask .== 0, 1.0, NaN)

mid = length(lon_mask) ÷ 2
lon_new = vcat(
    lon_mask[mid+1:end],          # 0 → 180
    lon_mask[1:mid] .+ 360)       # -180 → 0 shifted to 180 → 360

mask_new = vcat(
    ocean_mask[mid+1:end, :],
    ocean_mask[1:mid, :])

lon_mask=lon_new
ocean_mask=mask_new

=#

function land_ocean_mask(x::Isimip;
# this gives a land mask with the natural lon [-180,180] and lat [-90,90] and 0.5 deg resolution
# or an ocean mask with lon [0,360]
 option=:land) # else :ocean

#ds=Dataset("../Artifacts/ISIMIP/landseamask.nc", "r")
ds=Dataset(x.file_dir * x.active_file, "r")
lon_mask=ds["lon"][:] # -180 -> 180
lat_mask=ds["lat"][:]  # 90 -> -90
land_mask=ds["mask"][:,:]
#println("land_mask unique = ", unique(land_mask))
#println("land_mask size = ", size(land_mask))
#println("lengths lon lat mask = ", [length(lon_mask), length(lat_mask)])

lat_mask=reverse!(lat_mask)
land_mask=reverse!(land_mask, dims=2)
if option == :land return land_mask end

if option == :ocean
# ocean_mask = replace(land_mask, 1.0=> NaN, 0.0=>1.0)
ocean_mask = ifelse.(land_mask .== 0, 1.0, NaN)

mid = length(lon_mask) ÷ 2
lon_new = vcat(
    lon_mask[mid+1:end],          # 0 → 180
    lon_mask[1:mid] .+ 360)       # -180 → 0 shifted to 180 → 360

mask_new = vcat(
    ocean_mask[mid+1:end, :],
    ocean_mask[1:mid, :])

lon_mask=lon_new
ocean_mask=mask_new
end
return ocean_mask
end



#----------------------------------------------------------------------------------