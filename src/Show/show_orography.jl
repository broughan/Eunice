# global_oro2w.jl GeoMakie v0.7.15 needs support_functions1.jl possibly
#=
functions:
	global_orography
	find_matching_element
=#
#--------------------------------------------------------------

function find_matching_element(sub_string, y)
	first_index = findfirst(x->occursin(sub_string,x),y)
	if isnothing(first_index) nothing
	else y[first_index]
	end
end

#----------------------------------------------------------------------------


function global_orography(x::Any;  # for NceiNoaa replace ledgend with colorbar, add contour
# titles:
	option = x.option,
	plot_title="Plot of type " * string(typeof(x)) * " for the option " * string(option),
	output_plot_prefix = string(typeof(x)) * "_plot_oro_" * string(option),
						_div=30, # makes for 0.5 deg res
						surface_alpha=0.85,
						color_range=get(x.var_limits, string(option),[0,1]),
						colorbar_limits=color_range,
						lon_range=[180,-1,-180], # start, step, stop
						lat_range=[-90,1,90],
						animation_sleep_time=1/5,
						fig_resolution=(1620,1100),
						color_map=:terrain, #:diverging_rainbow_bgymr_45_85_c67_n256,				
# plots:
			frame_rate = 2,
			zoom_range=[0.5,0.01, 4.0],

# contours
			contour_labels=false,
			contour_levels=[100.0],
			contour_color=:black,
			contour_linewidth=2.0,

# layout:
			fixed_col2 = 800,
			fixed_buttons = 90,
			rel_globe = 0.85,
			rowgap_controls = 20)

println(color)

println("Error check...")
if !(typeof(x)==Etopo)
	Error("To run global_orography(x) set x=Etopo() after loading Eunice")
end
if !(option in ["surface", "bed", "geoid"])
	Error("The value of option must be one of \"surface\", \"bed\" or \"geoid\". See the field var_defs of the struct Etopo.")
end

println("Get values from type....")

	stvar=x.main_variable # ="z" in all cases
	
	lon_limits=x.lon_limits
	lat_limits=x.lat_limits
	var_limits=get(x.var_limits,"z",[-10000.0,8000.0])

println("Extract data ...")
	files=x.file_names
	file_path = x.file_dir * find_matching_element(string(option),files)
	ds = NCDataset(file_path, "r")

	z_missing = ds["z"][_div:_div:end, _div:_div:end]
	close(ds)
	dz = replace_missing(z_missing, NaN)
	z_obs = Observable(dz[:,:])

println("Observables...")
	lon_center = Observable(0)
	lat_center = Observable(0)
	zoom_obs = Observable(1.0)
	cont_lev_obs=Observable(contour_levels)
	alpha_obs = Observable(surface_alpha)
	
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
colsize!(fig.layout, 1, Auto(1.0)) # Relative(rel_globe))
rowsize!(fig.layout, 1, Relative(rel_globe))  
colsize!(fig.layout, 2, Fixed(fixed_col2))

println("Colorbar...")
Colorbar(controls[1,1:5];
			label = "Height and Depth Scale", 
			labelsize=20.0,
			vertical=false, 
			limits=colorbar_limits,
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
	surf=surface!(ax, ll[1] .. ll[2], la[1] .. la[2], z_obs;
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
	ccr=var_limits

	sg = SliderGrid(
		controls[3,1:5],
# (1) lon:
		(label = "Longitude:", 
			range = -180:1:180, 
			format = "{:}°", 
			startvalue = lon_center[],
			snap=false, linewidth=15),

# (2) lat:
		(label = "Latitude:", 
			range = -90:1:90, 
			format = "{:}°", 
			startvalue = lat_center[], 
			snap=false, linewidth=15),

# (3) zoom:
		(label = "Zoom:", 
			range = zr[1]:zr[2]:zr[3],
			format = "{:.1f}", 
			startvalue = zoom_obs[], 
			snap=false, linewidth=15),

# (4) alpha:
		(label = "alpha:", 
			range = 0.0:0.1:1.0, 
			format = "{:.1f}", 
			startvalue = alpha_obs[], 
			snap=false, linewidth=15),

# (5) contours: 
  		(label = "Contour value:",
		 range = ccr[1]:10.0:ccr[2],
		 startvalue = cont_lev_obs[][1], 
		 snap=true, linewidth=15),

# tail:		
		width = 400, height=60, 
		tellwidth=true, tellheight = true)
rowsize!(controls, 3, Relative(0.4))  # <= 0.4 was 1

# Connect sliders to observables:
    connect!(lon_center, sg.sliders[1].value)
    connect!(lat_center, sg.sliders[2].value)
    connect!(zoom_obs, sg.sliders[3].value)
	connect!(alpha_obs, sg.sliders[4].value)
	on(val -> cont_lev_obs[]=[val], sg.sliders[5].value)

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
	#cont_lev_obs = Observable([contour_level])
	cont = contour!(
		ax,
		ll[1] .. ll[2],
		la[1] .. la[2],
		z_obs;
		visible = cont_obs, 
		levels = cont_lev_obs,
		linewidth=contour_linewidth,
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
	winpath = realpath("..\\HTML\\global_orography.html") # change to global_vec_docs.html
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

