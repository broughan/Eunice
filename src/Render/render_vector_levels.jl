# render_vetor_levels.jl GeoMakie v0.7.15 from vec 8naz
#=
functions:
	global_vector_levels only two files from Merra2Lev type
=#
#--------------------------------------------------------------

function render_vector_levels(x::Eunice_type; # only Merra2Lev for this function
# options:
			#option = x.active_variable, # ?
			render_option = :plot, # else :antipodal, :movie_level, :movie_time
# titles:
	plot_title="Plot of type " * string(Merra2Lev) * " for [U,V]", # only type
	colorbar_title="Wind speed scale",
	output_plot_prefix = "plot_of_" * string(Merra2Lev) * "_for_[U,V]_" * string(render_option),

# plots:
			frame_rate = 2,
			surface_alpha = 0.7,
			fig_resolution=(1620,1100),
			zoom_range=[0.5,0.01, 4.0],
			zoom_value=1.0,
			animation_sleep_time=1/5,
			color_map=:diverging_rainbow_bgymr_45_85_c67_n256,
			speed_render=true, # surface plot
			time_render=true, # movie

# levels:
			render_levels=false, # movie
			level_range=x.level_range,
			level_index=1,

# contours:
			render_contour=false,
			contour_labels=false,
			contour_color=:black,
			contour_linewidth=2.0,
			contour_value=0.5,

# streamlines:
			stream_render=false,
			stream_scale = 2.0,
			stream_color = :red,
			stream_stepsize = 0.02,
			stream_maxsteps = 1000,
			stream_linewidth = 1,
			stream_density=0.2,
			stream_gridsize=(36,18),
			stream_arrow_size=15,
			stream_arrow_head = 'v')

println("Error control....")
	if typeof(x) !== Merra2Lev
		Error("Incorrect type for render_vector_levels. Must be Merra2Lev")
	end

println("Get values....")
	stvar=["U","V"]
	file_name = [find_matching_element("U",x.file_names),
				find_matching_element("V",x.file_names)]

	lon_limits=x.lon_limits
	lat_limits=x.lat_limits

	time_range = x.time_indices

println("Extract Data ...")
	#time_obs=Observable(1)
	#level_obs = Observable(1)


	fileu=file_name[1]
	filev=file_name[2]
	dsu=Dataset(x.file_dir * fileu, "r")
	dsv=Dataset(x.file_dir * filev, "r")
		dum=dsu["U"][:,:,:,:]
		dvm=dsv["V"][:,:,:,:]
		du=replace_missing(dum,NaN)
		dv=replace_missing(dvm,NaN)
		#du_obs = @lift(du[:,:,$level_obs, $time_obs])
		#dv_obs = @lift(dv[:,:,$level_obs, $time_obs])

		dlon=dsu["lon"][:]
		dlat=dsu["lat"][:]
		close(dsu)
		close(dsv)

	color_range= speed_range_min(du,dv) #get(x.var_limits,stvar[1],(0.0f0, 1.0f0))
	colorbar_limits=color_range

	dvar=vecs2speed_lev(du,dv)
#println([" du, dvar sizes: ", size(du),size(dvar)])

#-----------------------------------------------------------
println("Observables...")
# create some observables:

	lon_center = Observable(view_lon)
	lat_center = Observable(view_lat)
	zoom_obs = Observable(zoom_value)
	alpha_obs = Observable(surface_alpha)
	time_obs = Observable(time_index)
	level_obs = Observable(level_index)
	speed_obs = Observable(speed_render)
	cont_lev_obs = Observable([contour_value])
	stream_obs = Observable(stream_render)

	stream_button_label = @lift($stream_obs ? "Stream\n go" : "Stream\n stop")
	stream_button_color = @lift($stream_obs ? :green : :orange)
	
 # Construct dest string as observable using lift
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	data_obs = @lift(dvar[:,:, $level_obs, $time_obs])  # dvar is speed

#--------------------------------------------------------------
println("Figure...")
 # Set up the figure:
fig = Figure(; size = fig_resolution, padding=(0,0,0,0))

println("Layout...")
# create left column:
ax = GeoMakie.GeoAxis(fig[1, 1];
    dest = dest_str,
    title = plot_title,
    titlesize = 20,
	autolimitaspect=1,
	#aspect=DataAspect(),
    titlegap = 1.2,
    xscale = 1.0,
    yscale = 1.0)
#ax.aspect=DataAspect()

println("Colorbar...")
Colorbar(controls[1,1:7];
			label = colorbar_title, 
			labelsize=20.0,
			vertical=false, 
			limits=colorbar_limits,
			colormap=color_map,
			highclip=:black,
			lowclip=:white)
#----------------------------------------------------------------
 
println("Render the coastlines....")
    coast=lines!(ax, GeoMakie.coastlines(); 
			color = :black, 
			linewidth = 2, 
			transparency=true)
#-------------------------------------------------------------------

println("Surface speed...")
	ll=lon_limits
	la=lat_limits
if speed_render==true
	#color_map=speed_range_min(du,dv)
	surf=surface!(ax, ll[1] .. ll[2], la[1] .. la[2], data_obs;
			shading=false, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=true,
			colorrange=color_range,
			visible=speed_obs,
			alpha=alpha_obs) # from keyword
end

#---------------------------------------------------------------
# All Sliders:
	zr=zoom_range
	tr=time_range
	lr=x.level_range
	ccr=color_range

#----------------------------------------------------
# create zoom:
		s=zoom_value
		cx,cy = lon_center[], lat_center[]
		dx = 180/s
		dy = 90/s
		xlims!(ax, cx-dx, cx+dx)
		ylims!(ax, cy-dy, cy+dy)

		if stream_obs[]
			update_global_streamlines()
		end

	end # on zoom

 hidexdecorations!(ax; ticks=true,grid=false)
 hideydecorations!(ax; ticks=true,grid=false)

#----------------------------------------------------------------
println("Contours...")
if contour_render==true
	cont_obs = Observable(contour_render)
	#cont_lev_obs = Observable([0.5])
	cont = contour!(
		ax,
		ll[1] .. ll[2],
		la[1] .. la[2],
		data_obs;
		visible = cont_obs, 
		levels = cont_lev_obs,
		labels = contour_labels,
		linewidth = contour_linewidth,
		color = contour_color)
end
#---------------------------------------------------------------

# streamlines:
println("Streamlines...")
of streams_render==true
    itp_u = @lift linear_interpolation((dlon, dlat), 
		du[:,:,$level_obs, $time_obs]; extrapolation_bc=NaN)
    itp_v = @lift linear_interpolation((dlon, dlat),
		dv[:,:,$level_obs, $time_obs];extrapolation_bc=NaN)

    lon_min, lon_max = extrema(dlon)
    lat_min, lat_max = extrema(dlat)

# --- flow function ---
    function global_flow(p)
        x, y = p
		#x=mod(x,360)
		margin=0.1 # was 0.1
       if x < lon_min+margin || x > lon_max -margin|| y < lat_min +margin|| y > lat_max-margin
            return Point2f(NaN, NaN)
        end

        u = itp_u[](x, y)
        v = itp_v[](x, y)

       # if isnan(u) || isnan(v) return Point2f(NaN, NaN) end
       return Point2f(stream_scale*u, stream_scale*v)
    end

    lon_range = range(lon_min, lon_max, length=stream_gridsize[1])
    lat_range = range(lat_min, lat_max, length=stream_gridsize[2])
	lor=lon_range
	lar=lat_range

global_stream_obj = Ref{Any}(nothing)

function update_global_streamlines()
    if global_stream_obj[] !== nothing
        delete!(ax, global_stream_obj[])
    end
	stream_gridsize_arg = new_stream_gridsize
println("In update_stream_gridsize = $stream_gridsize_arg")
    global_stream_obj[] = streamplot!(
        ax,
        global_flow,
		lor, lar,
		visible = stream_obs,
		gridsize = stream_gridsize_arg,
        stepsize = stream_stepsize,
        maxsteps = stream_maxsteps,
        linewidth = stream_linewidth,
        color = _ -> stream_color,
        colormap = [stream_color],
		arrow_size = stream_arrow_size,
		arrow_head = stream_arrow_head)
end
update_global_streamlines()

	on(time_obs) do _
		if stream_obs[]==true 
			update_global_streamlines() 
		end
	end
end
#------------------------------------------------------------------

println("Save...")
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)

#-------------------------------------------------------------------
println("Render a speed movie....") 
	time_movie_file="Merra2Lev_time_movie.mp4"
	if time_render
		tr=x.time_indices
		record(fig, time_movie_file; framerate=frame_rate) do io
			for time_index in tr[1]:tr[2]:tr[3]
				@info "frame = $time_index"
				ax.title[] = string(time)
				time_obs[]=time_index
				sleep(0.01)
				recordframe!(io)
			end
		end
	end

#----------------------------------------------------
println("Render a levels movie....") 
	levels_movie_file="Merra2Lev_levels_movie.mp4"
	if levels_render
		lr=x.level_range
		record(fig, level_movie_file; framerate=frame_rate) do io
			for level_index in lr[1]:lr[2]:lr[3]
				@info "frame = $level_index"
				ax.title[] = string(level_index)
				level_obs[]=level_index
				sleep(0.01)
				recordframe!(io)
			end
		end
	end

#----------------------------------------------------
# clean up:
	return typeof(x), 
end
