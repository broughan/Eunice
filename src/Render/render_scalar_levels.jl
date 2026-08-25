# render_scalar_levels.jl GeoMakie v0.7.15 needs support_functions1.jl possibly
#=
functions:
	render_scalar_levels all Zenodo
=#
#--------------------------------------------------------------

function render_scalar_levels(x::Eunice_type, view_lon, view_lat;
# options:
	option="",
	render_option = :plot, # or :antipodal, :movie_time, :movie_level
# titles:
	stvar=x.main_variable,
	plot_title
		="Plot of scalar levels, type " * string(typeof(x)) * ", variable " * stvar,
	output_plot_prefix = string(typeof(x)) * "_plot_scalar_levels_" * stvar,
	colorbar_title = "Plot scalar levels colorbar scale",

# plots:
			surface_alpha=0.85,
			color_range=get(x.var_limits, stvar,[0,1]),
			animation_sleep_time=1/2,
			#fig_resolution=(1620,1080), # 18 was 19
			width=800,
			color_map=:diverging_rainbow_bgymr_45_85_c67_n256,				
			frame_rate = 2,

# limits:
			lon_limits = x.lon_limits,
			lat_limits = x.lat_limits,
			lon_range=[180,-1,-180], # start, step, stop
			lat_range=[-90,1,90],
			level_range=x.level_range,
			level_index=1,
			time_index=1,

# zoom:
			render_zoom=false,
			zoom_range=[0.5,0.01, 4.0],
			zoom_value=1.0,

# contours:
			contour_render=false,
			contour_labels=false,
			contour_level=0.1,
			contour_color=:black)

antipodal = (if render_option == :antipodal true else false end)

println("Error check...change")
if !(render_option in [:plot,:antipodal,:movie_time, :movie_level])
	Error("The value of option must be one of :plot, :antipodal, :movie_time or :movie_level. See the field var_defs of the struct Etopo.")
end

if !(typeof(x) in [
	Merra2Lev,Era5Lev,CamsCH4Lev])
	Error("The function render_scalar_levels cannot be used with type $(typeof(x))")
end
if !(stvar in x.variables) Error("The variable " * stvar * " is not valid for the Eunice type " * string(typeof(x)))
end

println("Get values from type....")
	
	lon_limits=x.lon_limits
	lat_limits=x.lat_limits
	var_limits=get(x.var_limits,stvar,[0.0,1.0])
	time_range= x.time_indices

println("Extract data ...")
	files=x.file_names
	file_path = x.file_dir * find_matching_element(stvar,files)
	ds = NCDataset(file_path, "r")

	z_missing = ds[stvar][:,:,:,:]
	close(ds)
	dz = replace_missing(z_missing, NaN)


println("Observables...")
	lon_center = Observable(view_lon)
	lat_center = Observable(view_lat)
	level_obs = Observable(level_index)
	zoom_obs = Observable(zoom_value)
	time_obs = Observable(time_index)
	cont_lev_obs=Observable([contour_level])
	alpha_obs = Observable(surface_alpha)
	z_obs = @lift(dz[ :, :, $level_obs, $time_obs])
	
 # Construct dest string as observable using lift
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end
#--------------------------------------------------------------
println("Figure...")
	if antipodal two_width=2*width + div(width,2) else two_width=div(3*width,2) end
	fig = Figure(size=(two_width,width))

println("GeoAxis...")
ax1 = GeoMakie.GeoAxis(fig[1, 1];
    dest = dest_str,
    title = plot_title,
    titlesize = 20,
	#autolimitaspect=1,
	aspect=1.0,
    titlegap = 1.2,
    xscale = 1.0,
    yscale = 1.0)
#----------------------------------------------------------------
 
println("Render the coastlines....")
    coast=lines!(ax, GeoMakie.coastlines(); 
			color = :black, 
			linewidth = 2, 
			transparency=true)

#-------------------------------------------------------------------
println("Surface...")
	ll=lon_limits
	la=lat_limits
	color_range=var_limits
	surf=surface!(ax, ll[1] .. ll[2], la[1] .. la[2], z_obs;
			shading=false, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=true,
			colorrange=color_range,
			alpha=alpha_obs) # from keyword
println("Antipodal plots....")
if antipodal
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

println("Colorbar..")
if antipodal fig_=fig[2,1:2] else fig_=fig[2,1] end
    Colorbar(fig_;
			label = colorbar_title, 
			labelsize=20.0,
			vertical=false, 
			limits=colorbar_limits,
			colormap=color_map,
			highclip=:black,
			lowclip=:white)

#---------------------------------------------------------------

# was for sliders:
	zr=zoom_range
	tr=time_range
	ccr=var_limits
	contour_step=(ccr[2]-ccr[1])/20.0
	lr=level_range
	lor=x.lon_range
	lar=x.lat_range
#--------------------------------------------------------------


println("Contours...")
# create contours toggle button and slider:
	cont_obs = Observable(contour_render)
if render_option== :plot && contour_render
	cont = contour!(
		ax,
		ll[1] .. ll[2],
		la[1] .. la[2],
		data_obs;
		visible = cont_obs, 
		levels = [contour_value],
		labels = contour_labels,
		color = contour_color)
end
#---------------------------------------------------------------

# println("Zoom ....")
if render_option == :plot && zoom_render
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

#----------------------------------------------------
println("Render a movie....") # fix not rotate

	if render_option == :movie_time
		record(fig, output_movie; framerate=frame_rate) do io
			for tdx in tr[1]:tr[2]:tr[3]
				@info "frame = $tdx"
				ax1.title[] = "time index = " * string(tdx)
				time_obs[]=tdx
				sleep(0.01)
				recordframe!(io)
			end
		end
	end

	if render_option == :movie_level
		record(fig, output_movie; framerate=frame_rate) do io
			for ldx in lr[1]:lr[2]:lr[3]
				@info "frame = $time"
				ax1.title[] = "level index = " * string(ldx)
				time_obs[]=ldx
				sleep(0.01)
				recordframe!(io)
			end
		end
	end


	return nothing
end

