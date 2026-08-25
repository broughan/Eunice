# render_orography.jl  v0.7.15 needs support_functions1.jl possibly
#=
functions:
	render_orography
=#
#--------------------------------------------------------------
using CairoMakie

function render_orography(x::Any, view_lon, view_lat; # for NceiNoaa replace ledgend with colorbar, add contour
# titles:
	option = x.option, # :surface, :bed, :geoid
	render_option = :plot, # or [:antipodal,] :movie

	plot_title="Plot of type " * string(typeof(x)) * " for the option " * string(option),
	output_plot_prefix = string(typeof(x)) * "_plot_oro_" * string(option) * "_",
						_div=30, # makes for 0.5 deg res
						surface_alpha=0.85,
						color_range=get(x.var_limits, string(option),[0,1]),
						colorbar_limits=color_range,
						lon_range=[180,-1,-180], # start, step, stop
						lat_range=[-90,1,90],
						#fig_resolution=(1620,1100),
						width=800,
						color_map=:terrain, #:diverging_rainbow_bgymr_45_85_c67_n256,				
# plots:
			zoom_range=[0.5,0.01, 4.0],
			zoom_value=1.0,

# contour:
			contour_rend=false,
			contour_labels=false,
			contour_level=[100.0],
			contour_color=:black,
			contour_linewidth=2.0,
# movie:
			frame_rate = 2,
			animation_sleep_time = 1/5)

antipodal = (if render_option == :antipodal true else false end)

println("Error check...")
if !(typeof(x)==Etopo)
	Error("To run render_orography(x) set x=Etopo() after loading EuniceCairo.jl and Eunice_types_zen.jl")
end
if !(option in ["surface", "bed", "geoid"])
	Error("The value of option must be one of \"surface\", \"bed\" or \"geoid\". See the field var_defs of the struct Etopo.")
end
if !(render_option in [:plot,:antipodal, :movie])
	Error("The value of option must be one of :plot, :antipodal or :movie. See the field var_defs of the struct Etopo.")
end
println("Get values from type....")

	stvar=x.main_variable # ="z" in all cases
	
	lon_limits=x.lon_limits
	lat_limits=x.lat_limits
	var_limits=get(x.var_limits,"z",[-10000.0,8000.0])

println("Extract the data ...")
	files=x.file_names
	file_path = x.file_dir * find_matching_element(string(option),files)
	ds = NCDataset(file_path, "r")

	z_missing = ds["z"][_div:_div:end, _div:_div:end]
	#close(ds)
	dz = replace_missing(z_missing, NaN)
	z_obs = Observable(dz[:,:])

println("Observables...")
	lon_center = Observable(view_lon)
	lat_center = Observable(view_lat)
	zoom_obs = Observable(zoom_value)
	cont_lev_obs=Observable(contour_level)
	alpha_obs = Observable(surface_alpha)
	
 # Construct dest string as observable using lift - good needed for movie
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

#--------------------------------------------------------------
println("Figure...")
	if antipodal two_width=2*width + div(width,2) else two_width=div(3*width,2) end
#fig = Figure(; size = fig_resolution)
	fig = Figure(size=(two_width,width))

println("Create the axis...")
ax1 = GeoMakie.GeoAxis(fig[1, 1];
    dest = dest_str,
    title = plot_title,
    titlesize = 20,
	aspect=1,
    titlegap = 1.2,
    xscale = 1.0,
    yscale = 1.0)

#-------------------------------------------------------------------
println("Surface...")
# plot the data using a surface heatmap:
	ll=lon_limits
	la=lat_limits
	surf=surface!(ax1, ll[1] .. ll[2], la[1] .. la[2], z_obs;
			shading=false, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=true,
			colorrange=color_range,
			alpha=alpha_obs) # from keyword
println("Plot coastlines...")
    coast=lines!(ax1, GeoMakie.coastlines(); 
			linestyle = :solid,
			color = :black, 
			linewidth = 2, 
			visible=true)

	#hidedecorations!
	GeoMakie.xlims!(ax1, -180, 180)
	GeoMakie.ylims!(ax1, -90, 90)

if antipodal
println("Antipodal plots....")
	(back_lon, back_lat)=antipodal_point(view_lon, view_lat)
	back_proj= "+proj=ortho +lon_0=$back_lon +lat_0=$back_lat"
	ax2 = GeoAxis(fig[1, 2];
        dest = back_proj,
        title = "Etopo antipodal plot", titlesize=20)

 

	# do it:
	surface!(ax2, ll[1] .. ll[2], la[1] .. la[2], z_obs; 
			colormap = color_map, 
			interpolate=false, shading=false)
	
   # Add coastlines:
	lines!(ax2, GeoMakie.coastlines(); 
		linestyle = :solid, 
		linewidth = 2, 
		color=:black, visible=true)

	#hidedecorations!(ax2)
	GeoMakie.xlims!(ax2, -180, 180)
	GeoMakie.ylims!(ax2, -90, 90)
end
println("Colorbar...")
if antipodal fig_=fig[2,1:2] else fig_=fig[2,1] end
    Colorbar(fig_;
			label = "Height and Depth Scale", 
			labelsize=20.0,
			vertical=false, 
			limits=colorbar_limits,
			colormap=color_map,
			highclip=:black,
			lowclip=:white)
 
#---------------------------------------------------------------

println("Contours...")
# create contours toggle button and slider:

if render_option == :plot
	cont = contour!(
		ax,
		ll[1] .. ll[2],
		la[1] .. la[2],
		z_obs;
		visible = contour_rend, 
		levels = contour_level,
		linewidth=contour_linewidth,
		labels = contour_labels,
		color = contour_color)
end
#---------------------------------------------------------------

println("Create zoom...")
if render_option == :plot
		s=zoom_value
		ax.scene.transformation.scale[] = Point3f(s, s, s)
		scale!(coast, s, s, s)
		scale!(surf, s, s, s)
		scale!(cont, s, s, s)

	hidexdecorations!(ax; ticks=true,grid=false)
	hideydecorations!(ax; ticks=true,grid=false)
end

#----------------------------------------------------------------

println("Save plot...")
if render_option in [:plot, :antipodal]
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
end

println("Make a movie....")
if render_option == :movie
		output_movie=output_plot_prefix * string(render_option) * ".mp4"
		record(fig, output_movie; framerate=frame_rate) do io
			for lon in -180:10:180
				@info "frame = $lon"
				ax.title[] = string(lon) * "°"
				lon_center[]=lon
				sleep(0.01)
				recordframe!(io)
			end
		end
end

#-------------------------------------------------------------------

	return typeof(x), option
end

