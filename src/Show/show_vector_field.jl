# global_vetor_field8na.jl GeoMakie v0.7.15 from vec 8x
#=
functions:
	global_vec
	find_matching_element

=#
#--------------------------------------------------------------
function find_matching_element(sub_string, y)
	first_index = findfirst(x->occursin(sub_string,x),y)
	if isnothing(first_index) nothing
	else y[first_index]
	end
end
#-------------------------------------------------------------


function global_vector_field(x::Any;
# titles:
	plot_title="Plot of type " * string(typeof(x)) * " for var " * main_variable_str(x),
	colorbar_title="Variable Scale",
	output_plot_prefix = string(typeof(x)) * "_plot_for_" * main_variable_str(x),
# option only for Oscar2daily:
			option="january", # also july
# domain:
			domain=:ocean, # also :land, :global
# plots:
			frame_rate = 2,
			surface_alpha = 0.7,
			fig_resolution=(1620,1100),
			zoom_range=[0.5,0.01, 4.0],
			animation_sleep_time=1/5,
			color_map=:diverging_rainbow_bgymr_45_85_c67_n256,
# contours:
			contour_labels=false,
			contour_color=:black,
			contour_linewidth=2.0,
# streamlines:
			stream_scale = 2.0,
			stream_color = :red,
			stream_stepsize = 0.02,
			stream_maxsteps = 1000,
			stream_linewidth = 1,
			stream_density=0.2,
			stream_gridsize=(36,18),
			stream_arrow_size=15,
			stream_arrow_head = 'v',
# layout:
			fixed_col2 = 750,
			rel_globe = 0.93,
			rowgap_controls = 20)

println("Error control....")
	if !(typeof(x) in [Oscar2daily, Oscar2monthly, Jra55, Era5])
		Error("Incorrect type for global_vector_field. Must be one of Oscar2daily, Oscar2monthly, Jra55 or Era4")
	end
# need to fix and do on section for each type: ********
println("Get values....")
	stvar=(if typeof(x) in [Oscar2daily, Oscar2monthly]
				["u","v"]
			elseif typeof(x)==Jra55
				["uas","vas"]
			else
				["u10","v10"] # Era5 only
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

	lon_center = Observable(0)
	lat_center = Observable(0)
	zoom_obs = Observable(1.0)
	alpha_obs = Observable(surface_alpha)
	time_obs = Observable(1)
	speed_obs = Observable(false)
	cont_lev_obs = Observable([0.5])
	stream_obs = Observable(false)

	stream_button_label = @lift($stream_obs ? "Stream\n stop" : "Stream\n go")
	stream_button_color = @lift($stream_obs ? :red : :green)
	
 # Construct dest string as observable using lift
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	data_obs = @lift(dvar[:,:, $time_obs])  # dvar is speed

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

# create right column:
controls = GridLayout()
fig[1,2] = controls

controls.halign = :left
controls.valign = :top

# outer layer sizing:
colsize!(fig.layout, 1, Auto(1.0)) # Relative(rel_globe))
rowsize!(fig.layout, 1, Relative(rel_globe))  
colsize!(fig.layout, 2, Fixed(fixed_col2))

# colorbar:
println("Colorbar...")
Colorbar(controls[1,1:7];
			label = colorbar_title, 
			labelsize=20.0,
			vertical=false, 
			limits=colorbar_limits,
			colormap=color_map,
			highclip=:black,
			lowclip=:white)

println("Buttons...")
# buttons:
	start_button = Button(controls[2,1], label="Start\n animation")
    stop_button = Button(controls[2,2], label="Stop\n animation")
	contour_button = Button(controls[2,3];label = "Contour\n on/off")
	speed_button = Button(controls[2,4];label = "Speed\n on/off")
	stream_button = Button(controls[2,5];
		label = stream_button_label,
		buttoncolor = stream_button_color,
		labelcolor_active = stream_button_color,
		labelcolor = :white)
	save_button = Button(controls[2,6]; label="Save\n image")
	help_button = Button(controls[2,7]; label="Help\n html info")

rowsize!(controls,1,Auto())
rowsize!(controls, 2, Auto())
#rowsize!(controls, 3, Relative(1))

# equal width buttons:
for c in 1:7
    colsize!(controls, c, Auto())
end

#colsize!(controls, 1, Auto())
rowgap!(fig.layout, 8)
colgap!(fig.layout, 8)

println("Menu for gridsize...")
gridsize_menu = Menu(controls[4,1:3], options = ["coarse", "standard", "fine"], default = "standard")

# 3. Add a Label for the menu
Label(controls[4, 2:4, Top()], "Gridsize", tellwidth = false)

# 4. Place the Menu in the layout
controls[4,2:4] = vgrid!(gridsize_menu)

on(gridsize_menu.selection) do gridsize_option
    println("Selected gridsize_option: $gridsize_option")
      global new_stream_gridsize=(
		if gridsize_option == "fine" map(x->2*x,stream_gridsize) 
		elseif gridsize_option == "coarse" map(x->round(Int, x/2), stream_gridsize)
		else stream_gridsize
        end)
println("In on selection stream_gridsize= $new_stream_gridsize")
	if domain==:global update_global_streamlines() end
	if domain==:ocean update_ocean_streamlines() end
end

#----------------------------------------------------------------
 
# plot the coastlines:
    coast=lines!(ax, GeoMakie.coastlines(); 
			color = :black, 
			linewidth = 2, 
			transparency=true)

#-------------------------------------------------------------------

println("Surface...")
# plot the data using a surface heatmap:
	ll=lon_limits
	la=lat_limits

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

	on(speed_button.clicks) do _
		speed_obs[] = !speed_obs[]
	end

#---------------------------------------------------------------
# All Sliders:
	zr=zoom_range
	tr=time_range
	ccr=color_range
	#lon_limits = x.lon_limits
	#lsr=lon_limits[1]:lon_limits[2]

	sg = SliderGrid(
		controls[3,1:6],
# (1) lon:
		(label = "Longitude:", 
			range = 0:1:360, # for Jra55
			format = "{:}°", 
			startvalue = lon_center[],
			snap=false, linewidth=20),
# (2) lat:
		(label = "Latitude:", 
			range = -90:1:90, 
			format = "{:}°", 
			startvalue = lat_center[], 
			snap=false, linewidth=20),
# (3) zoom:
		(label = "Zoom:", 
			range = zr[1]:zr[2]:zr[3],
			format = "{:.1f}", 
			startvalue = zoom_obs[], 
			snap=false, linewidth=20),
# (4) alpha:
		(label = "alpha:", 
			range = 0.0:0.1:1.0, 
			format = "{:.1f}", 
			startvalue = alpha_obs[], 
			snap=false, linewidth=20),   

# (5) time: 
		(label = "time index:", 
			range = tr[1]:tr[2]:tr[3],
			format = "{:}",
			startvalue = time_obs[], 
			snap=true, linewidth=20),  

# (6) contours:
		(label = "Contour value:",
		 range = ccr[1]:0.1:ccr[2],
		 startvalue = cont_lev_obs[][1], 
		 snap=true, linewidth=20),
# tail:		
		width = 400, height=100, 
		tellwidth=true, tellheight = true)
rowsize!(controls, 3, Relative(0.4))  # <= 0.4 was 1

# Connect sliders to observables:
    connect!(lon_center, sg.sliders[1].value)
    connect!(lat_center, sg.sliders[2].value)
    connect!(zoom_obs, sg.sliders[3].value)
	connect!(alpha_obs, sg.sliders[4].value)
	connect!(time_obs, sg.sliders[5].value)
	on(val -> cont_lev_obs[]=[val], sg.sliders[6].value)
	#connect!(stream_density_obs, sg.sliders[7].value)
	#on(val -> stream_grid_obs[]=(36*val, 18*val), sg.sliders[8].value)
	
#= keep for a while until global_scalar_levels and global_vector_levels done
if typeof(x) in [Era5Lev, Merra2Lev, CamsCH4Lev] 
		lr=x.level_range
		lsg = SliderGrid(
		fig[4,4],
# (9) level index:
		(label = "level index:", 
			range = lr[1]:lr[2]:lr[3],
			format = "{:}",
			startvalue = level_obs[], 
			snap=true, linewidth=20),  
		width = 400, height=100, 
		tellwidth=true,
		tellheight = true) 
		connect!(level_obs, lsg.sliders[1].value)
end
=#

# spacing:
rowgap!(controls, rowgap_controls) 
colgap!(controls, 6)
rowgap!(fig.layout,0)
colgap!(fig.layout, 6)
#--------------------------------------------------------------
# animate the plot:
   
    taskref = Ref{Union{Nothing,Task}}(nothing)
    should_close = Ref(false)

	if typeof(x) in [NceiNoaa, Etopo] tsl=sg.sliders[1] else tsl=sg.sliders[5] end
    on(start_button.clicks) do _
        if taskref[] === nothing
            taskref[] = @async begin
                for val in Iterators.cycle(tsl.range[])
                    sleep(animation_sleep_time)
                    set_close_to!(tsl, val)
					global val00=val
                    should_close[] && break
                end
                should_close[] = false
            end
        end
        Consume(true)
    end

    on(stop_button.clicks) do _
        if taskref[] !== nothing && !should_close[]
            should_close[] = true
            wait(taskref[])
            taskref[] = nothing
            set_close_to!(tsl, val00)
        end
        Consume(true)
    end

#----------------------------------------------------------------------------
# create zoom:
	zoom = sg.sliders[3]
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
#last_zoom = Ref(zoom.value[])

on(zoom.value) do s
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

end # on zoom

 hidexdecorations!(ax; ticks=true,grid=false)
 hideydecorations!(ax; ticks=true,grid=false)

#----------------------------------------------------------------
println("Contours...")
# create contours toggle button and slider:
	cont_obs = Observable(false)
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

	on(contour_button.clicks) do _
		cont_obs[] = !cont_obs[]
	end

#---------------------------------------------------------------

# streamlines:
println("Streamlines...")

if typeof(x) in [Era5, Jra55]

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

	on(stream_button.clicks) do _		
		if stream_obs[]==true 
			update_global_streamlines() 
		end
		stream_obs[] = !stream_obs[]
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

	on(stream_button.clicks) do _
		stream_obs[] = !stream_obs[]
		if stream_obs[]==true 
			update_ocean_streamlines() 
		end
	end
end # of Oscar2daily, Oscar2monthly
#------------------------------------------------------------------

println("Save...")
# save plot button:

	on(save_button.clicks) do _
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
	end

#-------------------------------------------------------------------
println("Help...")
	help_obs = Observable(false)
	winpath = realpath("..\\HTML\\eunice.html") # change to global_vec_docs.html
	@assert isfile(winpath)
	winpathurl = "file://$(winpath)" # that was it
	println(winpathurl)

	on(help_button.clicks) do _
		help_obs[]=true		
		blink_window = Window();
		loadurl(blink_window, winpathurl)
	end

		screen=display(fig)
		wait(screen)

#----------------------------------------------------

# clean up:
	return nothing
end
