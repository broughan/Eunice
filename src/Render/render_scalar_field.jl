# render_scalar_field.jl needs support_functions1.jl possibly
#=
functions:
	render_scalar_field
	reduce_range2
=#
#--------------------------------------------------------------
function reduce_range(ab; mul=1.0)
	a=ab[1]
	b=ab[2]
	hlen=(b-a)/2
	m=(a+b)/2
	return [m-hlen*mul, m+hlen*mul]
end

#--------------------------------------------------------------------

function render_scalar_field(x::Eunice_type, view_lon, view_lat;
# options:
			file_option=x.active_file,
			variable_option=x.active_variable,
			render_option=:plot, # else :antipodal else :movie
# titles:
			plot_title="Plot of type " * string(typeof(x)) * ", variable " * x.active_variable,
			antipodal_title="Antipodal plot of type " * string(typeof(x)) * ", variable " * x.active_variable,	colorbar_title=" Scale for variable " * x.active_variable,
			output_plot_prefix = string(typeof(x)) * "_plot_scalar_" * x.active_variable,

			lon_range=[180,-1,-180], # start, step, stop
			lat_range=[-90,1,90],			
# plot:
			color_map=cat_map(x.var_colormaps[x.active_variable]), 
			surface_alpha=0.85, # was .85
			range_fraction=0.7,
			#color_range=automatic,
			clip_fraction=0.02,
# or reduce_range(get(x.var_limits, x.active_variable,[-2,2]); mul=range_fraction),
			#fig_resolution=(1820,1080),
			width=800,
# movie:
			time_index=1,
			sub_steps=1,
			frame_rate = 2,		
			animation_sleep_time=1/2,		
# contour:
			render_contour=false,
			contour_value=0.5,
			contour_labels=false,
			contour_color=:black,
			contour_linewidth=2.0,
# zoom:
			render_zoom=false,
			zoom_range=[0.5,0.01, 4.0],
			zoom_value=1.0)

antipodal = (if render_option == :antipodal true else false end)

println("Error check...")
	stvar=x.active_variable

if !(render_option in [:plot,:antipodal, :movie])
	Error("The value of option must be one of :plot, :antipodal or :movie. See the field var_defs of the struct Etopo.")
end
if !(typeof(x) in [
	NoaaTemp,NoaaTempMonthly,
	Cheng,Cams,CamsCO2,
	Oisst,
	Cems,
	CdsCci,
	Oscar2daily,Oscar2monthly,
	Merra2])
	Error("The function render_scalar_field cannot be used with type ($typeof(x))")
end
if (typeof(x) in [
	Best,
	CdsSla,
	Jra55,
	Era5,
	CemsFas])
	Error("The function render_scalar_field cannot be used with type ($typeof(x)). However, it will be able to be used once the Zenodo linked version of Eunice is released.")
end

if !(typeof(x) in Eunice_types_git) 
	Error("The function render_scalar_field cannot be used with type $typeof(x)")
end
if !(stvar in x.variables) Error("The variable " * stvar * " is not valid for the Eunice type " * string(typeof(x)))
end

println("Get values from type....")	
	lon_limits=x.lon_limits
	lat_limits=x.lat_limits
	#var_limits=get(x.var_limits,stvar,[0.0,1.0])
	#colorbar_limits=var_limits
	time_range= x.time_indices

println("Extract data ...")
	files=x.file_names
	file_path = x.file_dir * x.active_file
	ds = NCDataset(file_path, "r")
	data_missing =  (if typeof(x)!== NoaaTempMonthly  ds[stvar][:,:,:] 
							else ds[stvar][:,:,1,:]
							end)
	#close(ds)
	data = replace_missing(data_missing, NaN)
	time_var=(if typeof(x)==Cams "valid_time" else "time" end)
	time_array=ds[time_var][:]

println("Observables...")
	lon_center = Observable(view_lon)
	lat_center = Observable(view_lat)
	zoom_obs = Observable(zoom_value)
	time_obs = Observable(time_index)
	cont_lev_obs=Observable([contour_value])
	alpha_obs = Observable(surface_alpha)
	data_obs = @lift(data[:,:,$time_obs])
	field_obs=Observable(data[:,:,1])
	
 # Construct dest string as observable using lift - good for the movie
    dest_str = lift(lon_center, lat_center) do lon, lat
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

#--------------------------------------------------------------
println("Figure...")
	if antipodal two_width=2*width + div(width,2) else two_width=div(3*width,2) end
	fig = Figure(size=(two_width,width))


println("Layout...")
# create left column:
ax1 = GeoMakie.GeoAxis(fig[1, 1];
    dest = dest_str,
    title = plot_title,
    titlesize = 20,
	aspect=1,
    titlegap = 1.2,
    xscale = 1.0,
    yscale = 1.0)

#----------------------------------------------------------------
 
println("Surface...")
# plot the data using a surface heatmap:
	ll=lon_limits
	la=lat_limits

color_range = 	(if plot_option in [:plot, :antipodal]
					slice= vec(data[:,:,time_index])
					av= mean(slice)
					sd= std(slice)
					(av-2*sd,av+2*sd)
				else 
					slice= vec(data)
					av= mean(slice)
					sd= std(slice)
					(av-2*sd,av+2*sd)
				end)
println("color range = $color_range")

	#color_range=quantile(vec(data),[clip_fraction,1.0-clip_fraction])
	#color_range=reduce_range(extrema(vec(data)); mul=range_fraction)
	#println("color range = ", color_range, "variable abs range = ", extrema(vec(data))) #x.var_limits[x.active_variable]

	surf=surface!(ax1, ll[1] .. ll[2], la[1] .. la[2], field_obs; # field was data_obs
			shading=true, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=false,
			colorrange=color_range,
			highclip=:purple,
			lowclip=:white,
			alpha=alpha_obs) # from keyword
#---------------------------------------------------------------
println("Plot the coastlines....")
    coast=lines!(ax1, GeoMakie.coastlines(); 
			color = :black, 
			linewidth = 2, 
			transparency=true)

println("Colorbar..")
if antipodal fig_=fig[2,1:2] else fig_=fig[2,1] end
    Colorbar(fig_;
			label = colorbar_title, 
			labelsize=20.0,
			vertical=false,
			width=width,
			limits=color_range,
			colormap=color_map,
			highclip=:purple,
			lowclip=:white)

#-------------------------------------------------------------------
println("Antipodal plots....")
if antipodal
	(back_lon, back_lat)=antipodal_point(view_lon, view_lat)
	back_proj= "+proj=ortho +lon_0=$back_lon +lat_0=$back_lat"
	ax2 = GeoAxis(fig[1, 2];
        dest = back_proj,
        title = antipodal_title,
		titlesize = 20) #"Etopo antipodal plot", titlesize=20)

	# do it:
	surf_ant=surface!(ax2, ll[1] .. ll[2], la[1] .. la[2], field_obs; 
			shading=true, 
			transparency=true,
			colormap=color_map,
			fxaa=true,
			interpolate=false,
			colorrange=color_range,
			highclip=:purple,
			lowclip=:white,
			alpha=alpha_obs)
	
   # Add coastlines:
	lines!(ax2, GeoMakie.coastlines(); 
		linestyle = :solid, 
		linewidth = 2, 
		color=:black, visible=true)

	#hidedecorations!(ax2)
	GeoMakie.xlims!(ax2, -180, 180)
	GeoMakie.ylims!(ax2, -90, 90)
end
#--------------------------------------------------------------

# ranges and limits:
	zr=zoom_range
	tr=time_range
#--------------------------------------------------------------

println("Contours...")
if (render_option == :plot) && render_contour
# create contours toggle button and slider:
	cont_obs = Observable(render_contour)
	cont = contour!(
		ax,
		ll[1] .. ll[2],
		la[1] .. la[2],
		field_obs;
		visible = cont_obs, 
		linewidth = contour_linewidth,
		levels = cont_lev_obs,
		labels = contour_labels,
		color = contour_color)
end
#---------------------------------------------------------------
println("Zoom....")
if (render_option == :plot) && render_zoom
		ax.scene.transformation.scale[] = Point3f(s, s, s)
		scale!(coast, s, s, s)
		scale!(surf, s, s, s)
		scale!(cont, s, s, s)

 hidexdecorations!(ax; ticks=true,grid=false)
 hideydecorations!(ax; ticks=true,grid=false)
end

#----------------------------------------------------------------
println("Save...")
if render_option in [:plot, :antipodal]
		output_plot_file = output_plot_prefix * string(plot_number()) * ".png"
		save(output_plot_file, fig)
end

#-------------------------------------------------------------------
println("Movie....")
#=
	if render_option==:movie
		output_movie=output_plot_prefix * ".mp4"
		record(fig, output_movie; framerate=frame_rate) do io
			for tix in tr[1]:tr[2]:tr[3]
				@info "frame = $tix, DateTime = $(time_array[tix])\n"
				ax1.title[] = "time index = $(string(tix)) DateTime = $(time_array[tix])"
				time_obs[]=tix
				sleep(0.01)
				recordframe!(io)
			end
		end
	end
=#

	if render_option==:movie
		output_movie=output_plot_prefix * ".mp4"
		workspace = similar(data[:,:,1])
		record(fig, output_movie; framerate=frame_rate) do io
			for tix in tr[1]:tr[2]:(tr[3]-1)
				A=data[:,:,tix]
				B=data[:,:,tix+1]
				for j in 0:sub_steps-1
					beta=j/sub_steps
					@. workspace = (1-beta)*A + beta*B
					field_obs[] = workspace
					dt1=time_array[tix]
					dt2=time_array[tix+1]
					ax1.title[] = "$(dt1) -> $(dt2)"
					sleep(0.01)
					recordframe!(io)
				end
				@info "frame = $tix, DateTime = $(time_array[tix])\n"
			end
			field_obs[]=data[:,:,tr[3]]
			recordframe!(io)
		end
	end

	return typeof(x), option, render_option
end

