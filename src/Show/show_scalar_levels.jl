# global_scalar_levels1h.jl GeoMakie v0.7.15 needs support_functions1.jl possibly
#=
functions:
	global_scalar_levels
=#
#--------------------------------------------------------------

function find_matching_element(sub_string, y)
	first_index = findfirst(x->occursin(sub_string,x),y)
	if isnothing(first_index) nothing
	else y[first_index]
	end
end

#----------------------------------------------------------------------------

function global_scalar_levels(x::Any;
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
			fig_resolution=(1620,1080), # 18 was 19
			color_map=:diverging_rainbow_bgymr_45_85_c67_n256,				
			frame_rate = 2,
			zoom_range=[0.5,0.01, 4.0],
# limits:
			lon_limits = x.lon_limits,
			lat_limits = x.lat_limits,
			lon_range=[180,-1,-180], # start, step, stop
			lat_range=[-90,1,90],
			level_range=x.level_range,
# contours:
			contour_labels=false,
			contour_level=0.0,
			contour_color=:black,
# layout:
			fixed_col2 = 750,
			fixed_buttons = 95,
			rel_globe = 0.93,
			rowgap_controls = 20)

println("Error check...change")
if !(typeof(x) in [
	Merra2Lev,Era5Lev,CamsCH4Lev])
	Error("The function global_scalar_field cannot be used with type $(typeof(x))")
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
	lon_center = Observable(0)
	lat_center = Observable(0)
	level_obs = Observable(1)
	zoom_obs = Observable(1.0)
	time_obs = Observable(1)
	cont_lev_obs=Observable([contour_level])
	alpha_obs = Observable(surface_alpha)
	z_obs = @lift(dz[ :, :, $level_obs, $time_obs])
	
 # Construct dest string as observable using lift
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end
#--------------------------------------------------------------
println("Figure...")
fig = Figure(; size = fig_resolution)

println("Layout...")
# create left column:
ax = GeoMakie.GeoAxis(fig[1, 1];
    dest = dest_str,
    title = plot_title,
    titlesize = 20,
	#autolimitaspect=1,
	aspect=1.0,
    titlegap = 1.2,
    xscale = 1.0,
    yscale = 1.0)

# create right column:
controls = GridLayout()
fig[1,2] = controls

controls.halign = :left
controls.valign = :top

# outer layer sizing:
colsize!(fig.layout, 1, Relative(rel_globe))
rowsize!(fig.layout, 1, Relative(rel_globe))  
colsize!(fig.layout, 2, Fixed(fixed_col2))

println("Colorbar..")
# colorbar:
println("Colorbar...")
Colorbar(controls[1,1:5];
			label = colorbar_title, 
			labelsize=20.0,
			vertical=false, 
			limits=color_range,
			colormap=color_map,
			highclip=:black,
			lowclip=:white)

rowsize!(controls,1,Auto())
#rowsize!(controls, 3, Relative(1))

# equal width buttons:
for c in 1:5
    colsize!(controls, c, Auto())
end

rowsize!(controls,1, Auto()) #Auto())

# buttons:
	start_button = Button(controls[2,1], label="Start")
    stop_button = Button(controls[2,2], label="Stop")
	contour_button = Button(controls[2,3], label="Contour")
	save_button = Button(controls[2,4]; label="Save")
	help_button = Button(controls[2,5]; label="Help")

rowsize!(controls, 2, Auto())
#rowsize!(controls, 3, Relative(1))

# equal width buttons:
for c in 1:5
    colsize!(controls, c, Fixed(fixed_buttons)) # 
end

#colsize!(controls, 1, Auto())
rowgap!(fig.layout, 8)
colgap!(fig.layout, 8)

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
	color_range=var_limits
	surf=surface!(ax, ll[1] .. ll[2], la[1] .. la[2], z_obs;
			shading=false, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=true,
			colorrange=color_range,
			alpha=alpha_obs) # from keyword
#---------------------------------------------------------------
# All Sliders:
	zr=zoom_range
	tr=time_range
	ccr=var_limits
	contour_step=(ccr[2]-ccr[1])/20.0
	lr=level_range
	lor=x.lon_range
	lar=x.lat_range

	sg = SliderGrid(
		controls[3,1:6], # ??
# (1) lon:
		(label = "Longitude:", 
			range = lor[1]:lor[2]:lor[3], #180:-1:-180, #<----- for 03
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
		 range = ccr[1]:contour_step:ccr[2],
		 startvalue = cont_lev_obs[][1], 
		 snap=true, linewidth=20),

# (7) levels: 
  		(label = "Level index:",
		 range = lr[1]:lr[2]:lr[3],
		 startvalue = level_obs[][1], 
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
	on(zoom.value) do s
		ax.scene.transformation.scale[] = Point3f(s, s, s)
		scale!(coast, s, s, s)
		scale!(surf, s, s, s)
		scale!(cont, s, s, s)
	end

 hidexdecorations!(ax; ticks=true,grid=false)
 hideydecorations!(ax; ticks=true,grid=false)

#----------------------------------------------------------------
println("Contours...")
# create contours toggle button and slider:
	cont_obs = Observable(false)
	#cont_lev_obs = Observable(contour_level) already assigned
	cont = contour!(
		ax,
		ll[1] .. ll[2],
		la[1] .. la[2],
		data_obs;
		visible = cont_obs, 
		levels = cont_lev_obs,
		labels = contour_labels,
		color = contour_color)

	on(contour_button.clicks) do _
		cont_obs[] = !cont_obs[]
	end

#---------------------------------------------------------------

println("Save...")
# save plot button:

	on(save_button.clicks) do _
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
	end

#-------------------------------------------------------------------
println("Help...")
	help_obs = Observable(false)
	winpath = realpath("..\\HTML\\eunice4.html") # change to global_scalar_levels.html
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

