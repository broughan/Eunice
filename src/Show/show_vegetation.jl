# global_veg1w.jl GeoMakie v0.7.15 needs support_functions1.jl possibly
#=
functions:
	global_vegetation
=#
#--------------------------------------------------------------


function global_vegetation(x::Any;  # for NceiNoaa
# titles:
	plot_title="Plot of type " * string(typeof(x)) * " for var Dominant_type of vegetation",
	output_plot_prefix = string(typeof(x)) * "_plot_for_veg",
						year=2007, # or 1997
						surface_alpha=0.85,
						color_range=(1,17),
						lon_range=[180,-1,-180], # start, step, stop
						lat_range=[-90,1,90],
						animation_sleep_time=1/5,
						fig_resolution=(1620,1100), # 18 was 19
						color_map=:diverging_rainbow_bgymr_45_85_c67_n256,				
# plots:
			frame_rate = 2,
			zoom_range=[0.5,0.01, 4.0],
# layout:
			fixed_col2 = 750,
			rel_globe = 0.93,
			rowgap_controls = 20)

println("Get values from type....")

	stvar=x.main_variable # ["u","v"]
	mainty=typeof(stvar)
	strty=string(typeof(x))
	
	lon_limits=x.lon_limits
	lat_limits=x.lat_limits

println("Extract data ...")
	file_path = x.file_dir * x.main_file 

# This is 0.5 deg resolution: from NCEI NOAA website:
file_path_1997="..\\Artifacts\\NCEI_NOAA\\land-cover_rf_landcover_yr1997.nc"
file_path_2007="..\\Artifacts\\NCEI_NOAA\\land-cover_rf_landcover_yr2007.nc"
#file_path_2020="..\\Artifacts\\NCEI_NOAA\\MCD12Q1.h11v09.ncml.nc4"

	file_path = 
		if year==1997 
			file_path_1997 
		else 
			file_path_2007
		end
	ds = NCDataset(file_path, "r")

	z_missing = ds["Dominant_type"][:,:]
	close(ds)
	z = replace_missing(z_missing, NaN)
	z_obs = Observable(z[:,:])

println("Observables...")
	lon_center = Observable(0)
	lat_center = Observable(0)
	zoom_obs = Observable(1.0)
	alpha_obs = Observable(surface_alpha)
	
 # Construct dest string as observable using lift
    dest_str = lift(lat_center, lon_center) do lat, lon
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	data_obs = z_obs # remove

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

println("Vegetation Legend...")
# replaces colorbar:
	lax=Axis(controls[1,1:4],title="Vegetation Dominant Type", xlabel="Types", ylabel="Colors")
	hidedecorations!(lax)
	qu=1/4
	ga=4/100
	for n=1:17
		poly!(lax,Point2f[(0, (n-1)*qu), (qu, (n-1)*qu), (qu, n*qu), (0, n*qu)], 
			color = n, colormap=color_map, #:diverging_rainbow_bgymr_45_85_c67_n256, 				
			colorrange=(1,17),transparency=false,strokecolor = :black, strokewidth = 2);
	end
#diverging_rainbow=ColorSchemes.diverging_rainbow_bgymr_45_85_c67_n256.colors[1:17]

	text!(lax,Point2f(ga,ga);text="1: Tropical_Evergreen_Broadleaf_Forest") #1
	text!(lax,Point2f(ga,qu+ga);text="2: Tropical_Deciduous_Broadleaf_Forest")
	text!(lax,Point2f(ga,2qu+ga);text="3: Temperate_Evergreen_Broadleaf_Forest")
	text!(lax,Point2f(ga,3qu+ga);text="4: Temperate_Evergreen_Needleleaf_Forest")
	text!(lax,Point2f(ga,4qu+ga);text="5: Temperate_Deciduous_Broadleaf_Forest")
	text!(lax,Point2f(ga,5qu+ga);text="6: Boreal_Evergreen_Needleleaf_Forest")
	text!(lax,Point2f(ga,6qu+ga);text="7: Boreal_Deciduous_Needleleaf_Forest")
	text!(lax,Point2f(ga,7qu+ga);text="8: Savanna")
	text!(lax,Point2f(ga,8qu+ga);text="9: Grassland_or_Steppe")
	text!(lax,Point2f(ga,9qu+ga);text="10: Shrubland")
	text!(lax,Point2f(ga,10qu+ga);text="11: Tundra")
	text!(lax,Point2f(ga,11qu+ga);text="12: Desert")
	text!(lax,Point2f(ga,12qu+ga);text="13: Polar-Desert_or_Rock_or_Ice")
	text!(lax,Point2f(ga,13qu+ga);text="14: Water_or_Rivers")
	text!(lax,Point2f(ga,14qu+ga);text="15: Cropland")
	text!(lax,Point2f(ga,15qu+ga);text="16: Pastureland")
	text!(lax,Point2f(ga,16qu+ga);text="17: Urbanland") #17
rowsize!(controls,1, Auto()) #Auto())

# buttons:
	start_button = Button(controls[2,1], label="Start")
    stop_button = Button(controls[2,2], label="Stop")
	save_button = Button(controls[2,3]; label="Save")
	help_button = Button(controls[2,4]; label="Help")

rowsize!(controls, 2, Auto())
#rowsize!(controls, 3, Relative(1))

# equal width buttons:
for c in 1:4
    colsize!(controls, c, Fixed(95)) # 
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
	#color_map=speed_range_min(du,dv)
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
	ccr=color_range

	sg = SliderGrid(
		controls[3,1:4],
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
# tail:		
		width = 400, height=100, 
		tellwidth=true, tellheight = true)
rowsize!(controls, 3, Relative(0.4))  # <= 0.4 was 1

# Connect sliders to observables:
    connect!(lon_center, sg.sliders[1].value)
    connect!(lat_center, sg.sliders[2].value)
    connect!(zoom_obs, sg.sliders[3].value)
	connect!(alpha_obs, sg.sliders[4].value)

# spacing:
rowgap!(controls, rowgap_controls) 
colgap!(controls, 6)
rowgap!(fig.layout,0)
colgap!(fig.layout, 6)
colsize!(fig.layout,1,Auto(1.0))
#Makie.tightlimits!(ax)
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

#-------------------------------------------------------------------------

# create zoom:
	zoom = sg.sliders[3]
	on(zoom.value) do s
		ax.scene.transformation.scale[] = Point3f(s, s, s)
		scale!(coast, s, s, s)
		scale!(surf, s, s, s)
	end

 hidexdecorations!(ax; ticks=true,grid=false)
 hideydecorations!(ax; ticks=true,grid=false)

#----------------------------------------------------------------

println("Save...")
# save plot button:

	on(save_button.clicks) do _
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
	end

#-------------------------------------------------------------------
println("Help...")
	help_obs = Observable(false)
	winpath = realpath("..\\HTML\\global_vegetation.html")
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

