#render_vector_field.jl GeoMakie v0.7.15 from vec 8x
#=
functions:
	render_vector_field
	find_matching_element

=#
#------move to support functions--------------------------------------------------------
function find_matching_element(sub_string, y)
	first_index = findfirst(x->occursin(sub_string,x),y)
	if isnothing(first_index) nothing
	else y[first_index]
	end
end
active_variable_string(x)= x.active_variable
#-------------------------------------------------------------


function render_vector_field(x::Eunice_type, view_lon, view_lat;
# titles:
	stvar=x.active_variable,
	plot_title="Plot of type " * string(typeof(x)) * " for var " * stvar,
	colorbar_title="Variable Scale",
	output_plot_prefix = string(typeof(x)) * "_plot_for_" * stvar,

# option only for Oscar2daily:
			option="january", # also july
			render_option=:plot, # or :antipodal or :movie
			stream_render=false,
			zoom_render=false,
# domain:
			domain=:ocean, # also :land, :global
# plots:
			render_speed = true,
			frame_rate = 2,
			surface_alpha = 0.7,
			#fig_resolution=(1620,1100),
			width=800,
# zoom:
			zoom_range=[0.5,0.01, 4.0],
			zoom_value=1.0,
# movie:
			animation_sleep_time=1/5,
			color_map=:diverging_rainbow_bgymr_45_85_c67_n256,
# contours:
			render_contour=false,
			contour_value=0.5,
			contour_labels=false,
			contour_color=:black,
			contour_linewidth=2.0,
# streamlines:
			render_streams=false,
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
if !(render_option in [:plot,:antipodal,:movie])
	Error("The value of option must be one of :plot, :antipodal or :movie.")
end
	if !(typeof(x) in [Oscar2daily, Oscar2monthly, Jra55, Era5]) # last two are for Zenodo
		Error("Incorrect type for global_vector_field. Must be one of Oscar2daily, Oscar2monthly, Jra55 or Era5")
	end

# need to fix and do on section for each type: ********
println("Get values....")
	stvar=(if typeof(x) in [Oscar2daily, Oscar2monthly]
				["u","v"]
			elseif typeof(x)==Jra55 # Zen
				["uas","vas"]
			else
				["u10","v10"] # Era5 # Zen
			end)
	file_name = (if typeof(x)==Oscar2daily 
					find_matching_element(option, x.file_names)
				elseif typeof(x)==Jra55
					[find_matching_element("uas",x.file_names),
					 find_matching_element("vas",x.file_names)]
				else
					x.main_file # Era5 only one file
				end)

	if typeof(x) !== Jra55 file_path = x.file_dir * file_name end

	lon_limits=x.lon_limits
	lat_limits=x.lat_limits

	time_range = x.time_indices

println("Extract Data ...")
	time_obs=Observable(1)
	level_obs = Observable(1)

	if file_name==string(file_name) ds=Dataset(file_path, "r") # one file case
		islatlon = typeof(x) in [Oscar2daily, Oscar2monthly]
		tdu=ds[stvar[1]][:,:,:] # lat x lon x time in case Oscar2 daily or monthly
		tdv=ds[stvar[2]][:,:,:]
		if islatlon 
			dum = permutedims(tdu, (2, 1, 3)) 
			dvm = permutedims(tdv, (2,1,3))
		else 
			dum=tdu
			dvm=tdv
		end
		du=replace_missing(dum,NaN)
		dv=replace_missing(dvm,NaN)
		#du_obs = @lift(du[:,:,$time_obs]) 
		#dv_obs = @lift(dv[:,:,$time_obs])

		dlon=ds["lon"][:]
		dlat=ds["lat"][:]
		close(ds)
	end
	if typeof(x)==Jra55 # two file case
		fileu=file_name[1]
		filev=file_name[2]
		dsu=Dataset(x.file_dir * fileu, "r")
		dsv=Dataset(x.file_dir * filev, "r")
		dum=dsu["uas"][:,:,:]
		dvm=dsv["vas"][:,:,:]
		du=replace_missing(dum,NaN)
		dv=replace_missing(dvm,NaN)
		#du_obs = @lift(du[:,:,$time_obs])
		#dv_obs = @lift(dv[:,:,$time_obs])

		dlon=dsu["lon"][:]
		dlat=dsu["lat"][:]
		close(dsu)
		close(dsv)
	end

	color_range= speed_range_min(du,dv) #get(x.var_limits,stvar[1],(0.0f0, 1.0f0))
	colorbar_limits=color_range

	dvar=vecs2speed(du,dv)
#println(["tdu, du, dvar sizes: ",size(tdu), size(du),size(dvar)])

#-----------------------------------------------------------
println("Observables...")
# create some observables:

	lon_center = Observable(view_lon)
	lat_center = Observable(view_lat)
	zoom_obs = Observable(zoom_value)
	alpha_obs = Observable(surface_alpha)
	time_obs = Observable(1)
	speed_obs = Observable(render_speed)
	cont_lev_obs = Observable([contour_level])
	contour_obs = Observable([contour_value])
	stream_obs = Observable(render_streams)
	
 # Construct dest string as observable using lift
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	data_obs = @lift(dvar[:,:, $time_obs])  # dvar is speed

#--------------------------------------------------------------
println("Figure...")
	if antipodal two_width=2*width + div(width,2) else two_width=div(3*width,2) end
	fig = Figure(size=(two_width,width))

println("GeoAxis...")
# create left column:
ax1 = GeoMakie.GeoAxis(fig[1, 1];
    dest = dest_str,
    title = plot_title,
    titlesize = 20,
	autolimitaspect=1,
	#aspect=DataAspect(),
    titlegap = 1.2,
    xscale = 1.0,
    yscale = 1.0)
#ax.aspect=DataAspect()

println("Render the coastlines....")
    coast=lines!(ax1, GeoMakie.coastlines(); 
			color = :black, 
			linewidth = 2, 
			transparency=true)

#-------------------------------------------------------------------

println("Render the surface...")
# plot the data using a surface heatmap:
	ll=lon_limits
	la=lat_limits

	#color_map=speed_range_min(du,dv)
	surf=surface!(ax1, ll[1] .. ll[2], la[1] .. la[2], data_obs;
			shading=false, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=true,
			colorrange=color_range,
			visible=speed_obs,
			alpha=alpha_obs) # from keyword

#---------------------------------------------------------------
println("Antipodal plots....")
if antipodal
	(back_lon, back_lat)=antipodal_point(view_lon, view_lat)
	back_proj= "+proj=ortho +lon_0=$back_lon +lat_0=$back_lat"
	ax2 = GeoAxis(fig[1, 2];
        dest = back_proj,
        title = "Etopo antipodal plot", titlesize=20)

	# do it:
	surface!(ax2, ll[1] .. ll[2], la[1] .. la[2], data_obs; 
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
#-----------------------------------------------------

# colorbar:
println("Colorbar...")
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
# All Sliders:
	zr=zoom_range
	tr=time_range
	ccr=color_range
#----------------------------------------------------------------------------
# create zoom:
#=
	on(zoom.value) do s
		ax.scene.transformation.scale[] = Point3f(s, s, s)
		scale!(coast, s, s, s)
		scale!(surf, s, s, s)
		scale!(vects, s, s, s)
		scale!(cont, s, s, s)
		scale!(stream_obj[], s, s, s) # check
	end
=#
println("Zoom....")
if render_zoom == true
	s=zoom_value
	cx,cy = lon_center[], lat_center[]
	dx = 180/s
	dy = 90/s
	xlims!(ax, cx-dx, cx+dx)
	ylims!(ax, cy-dy, cy+dy)

	if stream_obs[] && domain==:ocean
		update_ocean_streamlines()
	elseif stream_obs[] && domain==:global
		update_global_streamlines()
	end

	hidexdecorations!(ax; ticks=true,grid=false)
	hideydecorations!(ax; ticks=true,grid=false)
end
#----------------------------------------------------------------
println("Contours...")
if render_contour == true
# create contours toggle button and slider:
	cont_obs = Observable(render_contour)
	cont_lev_obs = Observable([contour_level])
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
if render_streams == true

if (typeof(x) in [Era5, Jra55])

    itp_u = @lift linear_interpolation((dlon, dlat), du[:,:,$time_obs]; extrapolation_bc=NaN)
    itp_v = @lift linear_interpolation((dlon, dlat), dv[:,:,$time_obs];extrapolation_bc=NaN)

    lon_min, lon_max = extrema(dlon)
    lat_min, lat_max = extrema(dlat)

# --- flow function ---
    function global_flow(p)
        x, y = p
		x=mod(x,360)
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
println("In update stream_gridsize = $stream_gridsize_arg")
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

	on(time_obs) do _
		if stream_obs[]==true 
			update_global_streamlines() 
		end
	end

end # of Era5, Jra55 vect fields

#----------------------------------------------------------------

if typeof(x) in [Oscar2daily, Oscar2monthly]

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

# --- interpolators ---
	
    itp_u = @lift linear_interpolation((dlon, dlat), du[:,:,$time_obs]; extrapolation_bc=NaN)
    itp_v = @lift linear_interpolation((dlon, dlat), dv[:,:,$time_obs];extrapolation_bc=NaN)
    itp_m = linear_interpolation((lon_mask, lat_mask), ocean_mask; extrapolation_bc=NaN)

    lon_min, lon_max = extrema(lon_mask)
    lat_min, lat_max = extrema(lat_mask)

# --- flow function ---
    function ocean_flow(p)
        x, y = p
		x=mod(x,360)
		margin=0.1
       if x < lon_min+margin || x > lon_max -margin|| y < lat_min +margin|| y > lat_max-margin
            return Point2f(NaN, NaN)
        end

        m = itp_m(x, y)
        if (isnan(m) || m < 0.5)
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


ocean_stream_obj = Ref{Any}(nothing)

function update_ocean_streamlines()
    if ocean_stream_obj[] !== nothing
        delete!(ax, ocean_stream_obj[])
    end
	stream_gridsize_arg=new_stream_gridsize

    ocean_stream_obj[] = streamplot!(
        ax,
        ocean_flow,
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

	on(time_obs) do _
		if stream_obs[]==true 
			update_ocean_streamlines() 
		end
	end

end # of Oscar2daily, Oscar2monthly
end # end of render_streams == true block
#------------------------------------------------------------------

println("Save plot...")
if render_option in [:plot, :antipodal]
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
end

#-------------------------------------------------------------------
println("Render a movie....") # fix not rotate
	if option == :movie
		record(fig, output_movie; framerate=frame_rate) do io
			for tdx in tr[1]:tr[2]:tr[3]  # FIX rest
				@info "frame = $lon"
				ax1.title[] = string(lon) * "°"
				lon_center[]=lon
				sleep(0.01)
				recordframe!(io)
			end
		end
	end

# clean up:
	return nothing
end
