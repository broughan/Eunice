# render_vegetation.jl from ncei_noaa_veg.jl in wrk2 of 0.0.2
#=
using CairoMakie
using Makie.GeometryBasics
using ColorSchemes, Colors
using GeoMakie
using NCDatasets
# didn't add CairoMakie


====> need to get the details for downloading here and everywhere!!!!
# Define dataset URL (example: MODIS 2020 land cover)
creds = ENV["ECCO_USERNAME"]*":"*ENV["ECCO_PASSWORD"]
url = "https://"* creds *":23.0"*"/opendap.cr.usgs.gov/opendap/hyrax/MCD12Q1.006/2020.01.01/MCD12Q1.A2020001.h11v09.006.2021.01.01.nc4"

# Download the file
file_path = Downloads.download(url, "modis_land_cover.nc")
file_path="Artifacts\\He_et_al_2012_1x1.nc"

#Open the NetCDF file
nc_veg = Dataset(file_path, "r")

#Load longitude, latitude, and vegetation classification data
lon = NetCDF.read(nc_data, "longitude")  # Modify based on dataset variable name
lat = NetCDF.read(nc_data, "latitude")   # Modify based on dataset variable name
land_cover = NetCDF.read(nc_data, "LC_Type1")  # MODIS land cover classification
nc_veg=Dataset("Artifacts\\MCD12Q1.h11v09.ncml.nc4", "r");
nc_veg=Dataset("Artifacts\\era5_2008_1.0x1.0_lowres.nc", "r") # no veg in this one
# Close the NetCDF file
close(nc_data)
=#
#------------------------------------------------------------------------
# This is 0.5 deg resolution: from NCEI NOAA website:
file_path_1997="Artifacts\\land-cover_rf_landcover_yr1997.nc"


function render_vegetation(x::Eunice_type,view_lon,view_lat; # yrstr is "1997" or "2007"
				option = "2007", # or "1997"
				render_option=:plot, # else :antipodal, :movie
				file_path = x.file_dir * x.active_file,
				width = 800,
				frame_rate=10,
				color_map=:diverging_rainbow_bgymr_45_85_c67_n256, 
# also :terrain, :cividis, :magma,:balance, :viridis
				output_plot = "ncei_veg_" * option * "_plot.png", 
				output_movie = "ncei_noaa_veg_" * option * "_movie.mp4")

yrstr=option

antipodal = (if render_option == :antipodal true else false end)

# get the data:
file_path="..\\Artifacts\\NCEI_NOAA\\land-cover_rf_landcover_yr" * option * ".nc"
# get the data:
	ds=Dataset(file_path, "r")
# extract the variables values:	
    #lat=ds["latitude"][:]
	#lon=ds["longitude"][:]
	veg=ds["Dominant_type"][:,:]
#close(ds)

# draw the figure:
	if antipodal two_width=2*width + div(width,2) else two_width=div(3*width,2) end

	fig = Figure(size=(two_width,width))
	lon_obs = Observable(view_lon)
	lat_obs = Observable(view_lat)
 # Construct dest string as observable using lift - good needed for movie
    dest_obs = lift(lon_obs, lat_obs) do lon, lat
        "+proj=ortho +lon_0=$lon +lat_0=$lat"
    end

	ax1 = GeoAxis(
		fig[1, 1];
		dest = dest_obs,
		xzoomlock = true, yzoomlock = true,
		title="NCEI NOAA land cover " * yrstr, titlesize=25)

	surface!(ax1, 0 .. 360, -90 .. 90, veg; colormap = color_map, interpolate=false) # 

 # Add coastlines:
   	lines!(ax1, GeoMakie.coastlines(); 
			linestyle = :solid, 
			linewidth = 2, 
			visible=true, 
			color=:black)

	#hidedecorations!(ax1)
	GeoMakie.xlims!(ax1, -180, 180) 
	GeoMakie.ylims!(ax1, -90, 90)

if antipodal
println("Antipodal plots....")
	(back_lon, back_lat)=antipodal_point(view_lon, view_lat)
	back_proj= "+proj=ortho +lon_0=$back_lon +lat_0=$back_lat"
	ax2 = GeoAxis(fig[1, 2];
        dest = back_proj,
        title = "NCEI NOAA antipodal plot", titlesize=20)

	# do it:
	surface!(ax2, 0..360, -90..90, veg; 
			colormap = color_map, 
			interpolate=false, shading=false)
	
    # Add coastlines:
	lines!(ax2, GeoMakie.coastlines(); 
		linestyle = :solid, 
		linewidth = 2, 
		color=:black)
	#hidedecorations!(ax2)
	GeoMakie.xlims!(ax2, -180, 180)
	GeoMakie.ylims!(ax2, -90, 90)
end

println("Legend....")
if render_option in [:plot, :antipodal]
	if antipodal fig_=fig[1,3] else fig_=fig[1,2] end

	ax=Axis(fig_, title="Vegetation Dominant Type", 
				xlabel="Types", xzoomlock=true, yzoomlock=true,
				ylabel="Colors")
	qu=1/4
	ga=1/100
	for n=1:17
		poly!(ax,Point2f[(0, (n-1)*qu), (qu, (n-1)*qu), (qu, n*qu), (0, n*qu)], 
			color = n, 
			colormap=:diverging_rainbow_bgymr_45_85_c67_n256,
			colorrange=(1,17),
			transparency=true,
			strokecolor = :black, 
			strokewidth = 1);
	end
#diverging_rainbow=ColorSchemes.diverging_rainbow_bgymr_45_85_c67_n256.colors[1:17]

	text!(ax,Point2f(ga,ga);text="Tropical_Evergreen_Broadleaf_Forest") #1
	text!(ax,Point2f(ga,qu+ga);text="Tropical_Deciduous_Broadleaf_Forest")
	text!(ax,Point2f(ga,2qu+ga);text="Temperate_Evergreen_Broadleaf_Forest")
	text!(ax,Point2f(ga,3qu+ga);text="Temperate_Evergreen_Needleleaf_Forest")
	text!(ax,Point2f(ga,4qu+ga);text="Temperate_Deciduous_Broadleaf_Forest")
	text!(ax,Point2f(ga,5qu+ga);text="Boreal_Evergreen_Needleleaf_Forest")
	text!(ax,Point2f(ga,6qu+ga);text="Boreal_Deciduous_Needleleaf_Forest")
	text!(ax,Point2f(ga,7qu+ga);text="Savanna")
	text!(ax,Point2f(ga,8qu+ga);text="Grassland_or_Steppe")
	text!(ax,Point2f(ga,9qu+ga);text="Shrubland")
	text!(ax,Point2f(ga,10qu+ga);text="Tundra")
	text!(ax,Point2f(ga,11qu+ga);text="Desert")
	text!(ax,Point2f(ga,12qu+ga);text="Polar-Desert_or_Rock_or_Ice")
	text!(ax,Point2f(ga,13qu+ga);text="Water_or_Rivers")
	text!(ax,Point2f(ga,14qu+ga);text="Cropland")
	text!(ax,Point2f(ga,15qu+ga);text="Pastureland")
	text!(ax,Point2f(ga,16qu+ga);text="Urbanland") #17

xlims!(ax, low=nothing, high=nothing) ;ylims!(ax,low=nothing, high=nothing)
end


# Display and save the figure:
if render_option in [:plot, :antipodal]
    display(fig)
    save(output_plot, fig)
end

println("Movie....")
	if (render_option == :movie)
		record(fig, output_movie; framerate=frame_rate) do io
			for long in -180:10:180
				@info "frame = $long"
				ax1.title[] = string(long) * "°"
				lon_obs[]=long
				sleep(0.01)
				recordframe!(io)
			end
		end
	end
return (if render_option in [:plot, :antipodal] output_plot else output_movie end)
end

#----------------------------------------------------------------------------------




#=
diverging_rainbow=[RGB(0.032081, 0.36182, 0.97348),
 RGB(0.05836, 0.37092, 0.95845),
 RGB(0.075961, 0.37984, 0.94345),
 RGB(0.088784, 0.38858, 0.92847),
 RGB(0.098335, 0.39714, 0.91352),
 RGB(0.10538, 0.40555, 0.89858),
 RGB(0.1105, 0.4138, 0.88367),
 RGB(0.1138, 0.42191, 0.86877),
 RGB(0.11557, 0.4299, 0.85388),
 RGB(0.11592, 0.43777, 0.83902),
 RGB(0.11487, 0.44549, 0.82416),
 RGB(0.11266, 0.45311, 0.80932),
 RGB(0.10918, 0.46059, 0.79447),
 RGB(0.10455, 0.46796, 0.77961),
 RGB(0.099069, 0.47521, 0.76474),
 RGB(0.092835, 0.4823, 0.74982),
 RGB(0.08633, 0.48923, 0.73486)]
=#
#---------------------------------------------------------------------------------------

function ncei_noaa_veg_legend(;
				width = 800,
				color_map=:diverging_rainbow_bgymr_45_85_c67_n256, 
				output_plot = "ncei_noaa_veg_legend.png")

	# draw the figure:
	width2=div(4*width,3)
	fig = Figure(size=(width,width2))

	# Legend:
	ax=Axis(fig, title="Vegetation Dominant Type Legend", 
				xlabel="Types", #xzoomlock=true, yzoomlock=true,
				ylabel="Colors")
	qu=1; ga=1/25 # qu=1/4; ga=1/100
	for n=1:17
		poly!(ax,Point2f[(0, (n-1)*qu), (qu, (n-1)*qu), (qu, n*qu), (0, n*qu)], 
			color = n, colormap=:diverging_rainbow_bgymr_45_85_c67_n256, 				colorrange=(1,17),transparency=true,strokecolor = :black, strokewidth = 1);
	end
#diverging_rainbow=ColorSchemes.diverging_rainbow_bgymr_45_85_c67_n256.colors[1:17]

	text!(ax,Point2f(ga,ga);text="Tropical_Evergreen_Broadleaf_Forest") #1
	text!(ax,Point2f(ga,qu+ga);text="Tropical_Deciduous_Broadleaf_Forest")
	text!(ax,Point2f(ga,2qu+ga);text="Temperate_Evergreen_Broadleaf_Forest")
	text!(ax,Point2f(ga,3qu+ga);text="Temperate_Evergreen_Needleleaf_Forest")
	text!(ax,Point2f(ga,4qu+ga);text="Temperate_Deciduous_Broadleaf_Forest")
	text!(ax,Point2f(ga,5qu+ga);text="Boreal_Evergreen_Needleleaf_Forest")
	text!(ax,Point2f(ga,6qu+ga);text="Boreal_Deciduous_Needleleaf_Forest")
	text!(ax,Point2f(ga,7qu+ga);text="Savanna")
	text!(ax,Point2f(ga,8qu+ga);text="Grassland_or_Steppe")
	text!(ax,Point2f(ga,9qu+ga);text="Shrubland")
	text!(ax,Point2f(ga,10qu+ga);text="Tundra")
	text!(ax,Point2f(ga,11qu+ga);text="Desert")
	text!(ax,Point2f(ga,12qu+ga);text="Polar-Desert_or_Rock_or_Ice")
	text!(ax,Point2f(ga,13qu+ga);text="Water_or_Rivers")
	text!(ax,Point2f(ga,14qu+ga);text="Cropland")
	text!(ax,Point2f(ga,15qu+ga);text="Pastureland")
	text!(ax,Point2f(ga,16qu+ga);text="Urbanland") #17
xlims!(ax, low=0, high=width) ;ylims!(ax,low=0, high=width2)
	# Display and save the figure:
    display(fig)
    save(output_plot, fig)

	return output_plot
end
