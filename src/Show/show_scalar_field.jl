# global_scalar_field2w.jl GeoMakie v0.7.15 needs support_functions1.jl possibly
#=
functions:
	show_scalar_field
=#
#--------------------------------------------------------------

function show_scalar_field(x::Eunice_type;
# titles:
	plot_title="Plot of type " * string(typeof(x)) * ", variable " * x.active_variable,
	colorbar_title=" Scale for variable " * x.active_variable,
	output_plot_prefix = string(typeof(x)) * "_plot_scalar_" * x.active_variable,

						surface_alpha=0.85,
						#color_range=get(x.var_limits, x.active_variable,[0,1]),
						lon_range=[180,-1,-180], # start, step, stop
						lat_range=[-90,1,90],
						animation_sleep_time=1/2,#1/5,
						fig_resolution=(1820,1080), # 18 was 19
						color_map=cat_map(x.var_colors[x.active_variable]),
						#color_map=cat_map(:generic),
# was :diverging_rainbow_bgymr_45_85_c67_n256,				
# plots:
			frame_rate = 2,
			zoom_range=[0.5,0.01, 4.0],

# contours
			contour_labels=false,
			contour_level=0.0,
			contour_color=:black,
			contour_linewidth=4.0,

# layout:
			fixed_col2 = 850,
			fixed_buttons = 90,
			rel_globe = 0.90,
			rowgap_controls = 20)

println("Error check...")
	stvar=x.active_variable
if !(typeof(x) in [
	NoaaTemp,
	NoaaTempMonthly,
	Best,
	Cheng,
	Cams,
	CamsCO2,
	Oisst,
	Cems,
	CdsCci,
	CdsSla,
	Jra55,
	Era5,
	Merra2,
])
	Error("The function show_scalar_field cannot be used with type ($typeof(x))z")
end
if !(stvar in x.variables) Error("The variable " * stvar * " is not valid for the Eunice type " * string(typeof(x)))
end

println("Get values from type....")
	
	lon_limits=x.lon_limits
	lat_limits=x.lat_limits
	#var_limits=x.var_limits[stvar] # get(x.var_limits,stvar,[0.0,1.0])
	#colorbar_limits=var_limits
	time_range= x.time_indices

println("Extract data ...")
	files=x.file_names
	file_path = x.file_dir * x.active_file
	ds = NCDataset(file_path, "r")

	data_missing = ds[stvar][:,:,:]
	#close(ds)
	data = replace_missing(data_missing, NaN)
	var_limits=quantile(filter(!isnan,vec(data)), [0.1, 0.9])
	colorbar_limits=var_limits

println("Observables...")
	lon_center = Observable(0)
	lat_center = Observable(0)
	zoom_obs = Observable(1.0)
	time_obs = Observable(1)
	cont_lev_obs=Observable([contour_level])
	alpha_obs = Observable(surface_alpha)
	data_obs = @lift(data[:,:,$time_obs])
	
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
	aspect=1,
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

println("Colorbar...")
cmap=to_colormap(color_map)
Colorbar(controls[1,1:5];
			label = colorbar_title, 
			labelsize=20.0,
			vertical=false, 
			limits=colorbar_limits,
			colormap=color_map,
			highclip=cmap[end],
			lowclip=cmap[1])

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
	surf=surface!(ax, ll[1] .. ll[2], la[1] .. la[2], data_obs;
			shading=false, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=true,
			colorrange=color_range,
			alpha=alpha_obs) # from keyword
700
#---------------------------------------------------------------
# All Sliders:
	zr=zoom_range
	tr=time_range
	ccr=var_limits

	sg = SliderGrid(
		controls[3,1:5], # ??
# (1) lon:
		(label = "Longitude:", 
			range = 180:-1:-180, 
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

# spacing:
rowgap!(controls, rowgap_controls) 
colgap!(controls, 6)
rowgap!(fig.layout,0)
colgap!(fig.layout, 6)
colsize!(fig.layout,1,Auto(1.0))
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
		linewidth = contour_linewidth,
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
	winpath = realpath("..\\HTML\\global_scalar_field.html")
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

