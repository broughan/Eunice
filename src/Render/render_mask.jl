# render_mask.jl

#=
project=
functions:
	render_mask 0.5 deg res
	land_ocean_mask
	Isimip 
	needs EuniceCairo.jl and support_functions1.jl

Variables:
	lon 720
	lat 360
	mask (720 x 360)
=#
#---------------------------------------------------------------
# packages to be first installed (] add PackageName no .jl)
	using NCDatasets
	using GeoMakie
	using CairoMakie
	using GeometryBasics
	using Printf
	using CairoMakie
CairoMakie.activate!()

#include("utils.jl") # <<---------------------- fix
#------------------------------------------------------------------------

function land_ocean_mask(x::Isimip;
# this gives a land mask with the natural lon [-180,180] and lat [-90,90] and 0.5 deg resolution
# or an ocean mask with lon [0,360]
		mask_option=:land, # else :ocean
		mask_lon=180) # else 360

ds=Dataset(x.file_dir * x.active_file, "r")
lon_mask=ds["lon"][:] # -180 -> 180
lat_mask=ds["lat"][:]  # 90 -> -90
land_mask=ds["mask"][:,:]

lat_mask=reverse!(lat_mask)
land_mask=reverse!(land_mask, dims=2)
if mask_option == :land return land_mask end

# ocean_mask = replace(land_mask, 1.0=> NaN, 0.0=>1.0)
ocean_mask = ifelse.(land_mask .== 0, 1.0, 0.0) # was NaN
#println(size(ocean_mask))
#println(ocean_mask[360,180])

if mask_lon == 360
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
#--------------------------------------------------------------

function render_mask(x::Eunice_type, view_lon, view_lat;
				render_option=:plot, # or :antipodal or :movie - just rotation
				option=:land, # or :ocean
				mask_lon=180, # or 360
				stvar=x.active_variable,
				width = 800,
				color_map=[:white, :red], #diverging_rainbow_bgymr_45_85_c67_n256, 
				frame_rate = 10,
				output_plot_prefix = string(typeof(x)) * "_" * string(option) * "_" * stvar * "_", 
				output_movie = string(typeof(x)) * "_" * string(option) * "_" * stvar * ".mp4")

println("Get values from the type:")
	stvar=x.active_variable
	type=typeof(x)
	stype=string(type)
	mask=land_ocean_mask(x; mask_option=option, mask_lon=mask_lon)

	ll=x.lon_limits
	la=x.lat_limits
	antipodal = (if render_option==:antipodal true else false end)

println("Set up figure and axis with orthographic projection:" )
	if render_option==:antipodal two_width=2*width else two_width=width end

    fig = Figure(size = (two_width,width))
	lon_obs = Observable(view_lon)
	lat_obs = Observable(view_lat)
	destnode = lift(lon_obs, lat_obs) do lon, lat
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	ax1 = GeoAxis(fig[1, 1];
        dest = destnode,
        title = output_plot_prefix,
		titlesize=25.0)

	 surface!(ax1, ll[1]..ll[2], la[1]..la[2], mask; 
			colormap = color_map, 
			colorrange=(0,1),
			shading=NoShading,
			interpolate=false)

    # Add coastlines once
	lines!(ax1, GeoMakie.coastlines(); 
		linestyle = :solid, 
		linewidth = 2, 
		visible=true,
		color=:black)
	GeoMakie.xlims!(ax1, ll[1], ll[2])
	GeoMakie.ylims!(ax1, la[1], la[2])

println("antipodal plot:")
if antipodal
	(back_lon, back_lat)=antipodal_point(view_lon, view_lat)
	back_proj= "+proj=ortho +lon_0=$back_lon +lat_0=$back_lat"
	ax2 = GeoAxis(fig[1, 2];
        dest = back_proj,
        title = "Antipodal plot",
		titlesize=25.0)

    # temp is not the observable - see JRA55_explore for the alternative
    #temp_data = Observable(temp[:, :, time_index])
    surface!(ax2, ll[1]..ll[2], la[1]..la[2], mask; 
			colormap = color_map, 
			shading=NoShading,
			colorrange=(0,1),
			interpolate=false)

    # Add coastlines once
	lines!(ax2, GeoMakie.coastlines(); 
		linestyle = :solid, 
		visible = true,
		color=:black,
		linewidth = 2)
	xlims!(ax2, ll[1], ll[2])
	ylims!(ax2, la[1], la[2])

end

println("Add colorbar:")
	fig_=(if antipodal fig[2,1:2] else fig[2,1] end)
    Colorbar(fig_;
		label = stype * "_" * stvar, 
		colormap=color_map,
		limits=get(x.var_limits, stvar, [0.0,1.0]),
		lowclip=:white,
		highclip=:black,
		width=div(8*width,10), 
		vertical=false)

println("Save plot...")
if render_option in [:plot, :antipodal]
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
end

println("record a movie:")
if render_option == :movie
    record(fig, output_movie; framerate=frame_rate) do io
		for lon in -180:10:180
			@info "longitude = $lon"
			ax1.title[] = string(lon) * "°"
			lon_obs[] = lon
			recordframe!(io)
		end
	end
end

	return if render_option in [:plot, :antipodal] output_plot_file else output_movie end
end
