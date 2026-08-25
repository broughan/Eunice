# Eunice_types.jl 19 aug 26 reconstituted from Eunice_types_git.jl + Eunice_types_zen
# remove option field
using Dates
export Eunice_type

# add field for color_map each vble
#=
structs:
	dim=2
[:,:] lon x lat
	Isimip
	NceiNoaa

	dim=3
[:,:,:] lon x lat x time
	NoaaTemp
	NoaaTempMonthly
	Cheng 
	Cams
	CamsC02
	Oisst
	Oscar2daily [u,v] ocean current velocity
	Oscar2monthly [u,v] ocean current velocity
	Cems
	CdsCci
	Merra2
=#

abstract type Eunice_type end # can repeat

# dim=2

@kwdef mutable struct Isimip <: Eunice_type # land sea mask 1/2 deg resolution
	access_url::String="https://cds.climate.copernicus.eu"
	long_name::String="WFDE5-ERA5 MASK"
	file_names::Vector=["landseamask.nc"]
	active_file::String= file_names[1] #"landseamask.nc"
	file_dir::String="../Artifacts/ISIMIP/"

	variables::Vector=["mask"]
	active_variable::String="mask"
	dim_variables::Vector=["lon","lat"]
	dim_sizes::Tuple=(720,360)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"mask"=>"1 for each land point and 0 for each ocean point")
	var_units::Dict{String,String}=Dict(
			"mask"=>"(1)")
	var_limits::Dict{String,Vector}=Dict(
			"mask" => [0,1])
	var_colors::Dict{String,Symbol}=Dict(
			"mask" => identity(:zeroone))

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2026)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2026)
	time_indices::Vector{Int}=[]
end

@kwdef mutable struct NceiNoaa <: Eunice_type # vegetation
	access_url::String=
"https://www.ncei.noaa.gov/thredds/catalog/sat/landcover/RF_AREAVEG/land-cover_rf_landcover_yr2007.nc"
	long_name::String="Global dominant vegetation species"
	active_file::String="land-cover_rf_landcover_yr2007.nc"
	file_names::Vector=["land-cover_rf_landcover_yr1997.nc", "land-cover_rf_landcover_yr2007.nc"]
	file_dir::String="../Artifacts/NCEI_NOAA/"

	variables::Vector=["Dominant_type", "Water", "Urban", "C3grass", "C4grass", "Savanna", "Tundra", "C3crop", "C4crop", "C3past", "C4past"] # many other variables in the .nc files, available here using NceiNoaa().active_variable= "new_variable_name"
	active_variable::String="Dominant_type" 
	dim_variables::Vector=["longitude", "latitude", "time"]
	dim_sizes::Tuple=(720,360,1)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,1]

	var_defs::Dict{String,String}=Dict(
"Dominant_type"=>"Dominant land cover type 1-17 within each cell type where type
(1) is Tropical_Evergreen_Broadleaf_Forest,
(2) is Tropical_Deciduous_Broadleaf_Forest,
(3) is Temperate_Evergreen_Broadleaf_Forest,
(4) is Temperate_Evergreen_Needleleaf_Forest,
(5) is Temperate_Deciduous_Broadleaf_Forest,
(6) is Boreal_Evergreen_Needleleaf_Forest,
(7) is Boreal_Deciduous_Needleleaf_Forest,
(8) is Savanna,
(9) is Grassland_or_Steppe,
(10) is Shrubland,
(11) is Tundra,
(12) is Desert,
(13) is Polar-Desert_or_Rock_or_Ice,
(14) is Water_or_Rivers,
(15) is Cropland,
(16) is Pastureland,
and (17) is Urbanland")
	var_units::Dict{String, String}=Dict("Dominant_type"=>"(1)")	
	var_limits::Dict{String, Tuple}=Dict("Dominant_type" => (1,17))
	var_colors::Dict{String, Symbol}=Dict("Dominant_type" => identity(:generic))  # a rainbow

	grid_resolution::Float32=0.5f0
	start_time::DateTime=(occursin("2007", active_file) ? DateTime(2007) : DateTime(1997))
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=start_time
	time_indices::Vector{Int}=[1]
end

#--------------------------------------------------------------------
#dim=3
@kwdef mutable struct NoaaTemp <: Eunice_type # global surface temperatures 5 deg res
	access_url::String="https://www.ncei.noaa.gov/products/land-based-station/noaa-global-temp"
	long_name::String="NOAA global temperature 1950-2024"
	active_file::String="NOAAGlobalTemp_1950_2024_sept.nc"
	file_names::Vector=["NOAAGlobalTemp_1950_2024_sept.nc"] # 1MB
	file_dir::String="../Artifacts/NOAA/"

	variables::Vector=["anom"]
	active_variable::String="anom"
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(72,36,75)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,1]

	var_defs::Dict{String,String}=Dict("anom"=>"global temp anomaly yearly Septembers 1950-2024")
	var_units::Dict{String, String}=Dict("anom"=>"degrees C")
	var_limits::Dict{String,Vector}=Dict("anom" => [-11.5,4.8])
	var_colors::Dict{String,Symbol}=Dict("anom" => identity(:temperature_anom)) # change to var_colors was 

	grid_resolution::Float32=5.0f0
	start_time::DateTime=DateTime(1950,9)
	time_step::Union{Year, Month, Week, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2024,9)
	time_indices::Vector=[1,1,75] # or [1,1,175]
end

@kwdef mutable struct NoaaTempMonthly <: Eunice_type # global surface temperatures
	access_url::String="https://www.ncei.noaa.gov/products/land-based-station/noaa-global-temp"
	long_name::String="NOAA global temperature 1850-2024 monthly"
	active_file::String="NOAAGlobalTemp_v6.0.0_gridded_s185001_e202505.nc" # 21MB
	file_names::Vector=["NOAAGlobalTemp_v6.0.0_gridded_s185001_e202505.nc"]
	file_dir::String="../Artifacts/NOAA/"

	variables::Vector=["anom"]
	active_variable::String="anom"
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(72,36,1,2105)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,1]

	var_defs::Dict{String,String}=Dict("anom"=>"global temperature anomaly monthly 1850-2025")
	var_limits::Dict=Dict("anom" => [-11.5,4.8])
	var_units::Dict{String, String}=Dict("anom"=>"degrees C")
	var_colors::Dict{String,Symbol}=Dict("anom" => identity(:temperature_anom))

	grid_resolution::Float32=5.0f0
	start_time::DateTime=DateTime(1850,9)
	time_step::Union{Year, Month, Day, Hour}=Month(1)
	end_time::DateTime=DateTime(2025,5)
	time_indices::Vector=[1, 1, 2105]	
end

@kwdef mutable struct Cheng <: Eunice_type # carbon dioxide conc, 1 deg resolution
# see also CO2_1deg_month_1850-2023.nc
	access_url::String="https://doi.org/10.5281/zenodo.5021361"
	long_name::String="Estimated C02 concentration 1950-2013 Septs, Cheng"
	file_names::Vector=["CO2_1deg_september_1950-2013.nc"] # 32MB
	active_file::String="CO2_1deg_september_1950-2013.nc"
	file_dir::String="../Artifacts/CHENG/"

	variables::Vector=["value"]
	active_variable="value"
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(360,180,64)

	lon_limits::Vector=[-180,180] # defaults check
	lat_limits::Vector=[90,-90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict("value" => "CO2 concentration Sept 1950-2013")
	var_units::Dict{String, String}=Dict("value" => "ppm")
	var_limits::Dict=Dict("value"=>[284.0, 288.7])
	var_colors::Dict{String,Symbol}=Dict("value" => identity(:generic)) # its the rainbow
	
	grid_resolution::Float32=1.0f0

	start_time::DateTime=DateTime(1950,9)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2013,9)	
	time_indices::Vector=[1,1,64]
end;

@kwdef mutable struct Cams <: Eunice_type # CO2 and CH4 conc, 3/4 deg resolution
	access_url::String="https://ads.atmosphere.copernicus.eu/datasets/cams-global-ghg-reanalysis-egg4"
	long_name::String="Column mean molar fraction C02 & CH4, 2003-2020, 6 mthly"
	file_names::Vector=["cams_data_allhours_sfc.nc"]
	active_file::String="cams_data_allhours_sfc.nc"
	file_dir::String="../Artifacts/CAMS/"

	variables::Vector=["tcco2","tcch4"]
	active_variable::String=variables[1]
	dim_variables::Vector=["longitude","latitude","valid_time"]
	dim_sizes::Tuple=(480, 241,36)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[90,-90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"tcco2"=>"mean molar concentration of CO2",
			"tcch4"=>"mean molar concentration of CH4")
	var_limits::Dict=var_limits::Dict=Dict(
			"tcco2" => [368.7,380.5],
			"tcch4" => [1604.3,1853.6])
	var_units::Dict{String, String}=Dict(
			"tcco2"=> "(ppm)", 
			"tcch4"=> "(ppb)")
	var_colors::Dict{String, Symbol}=Dict(
			"tcco2"=> identity(:co2), 
			"tcch4"=> identity(:co2))

	grid_resolution::Float32=0.75f0
	start_time::DateTime=DateTime(2003,3)
	time_step::Union{Year, Month, Day, Hour}=Month(6)
	end_time::DateTime=DateTime(2020,9)
	time_indices::Vector=[1,1,36] # was [1801,12,2105]
end

@kwdef mutable struct CamsCO2 <: Eunice_type # carbon dioxide conc, 1 deg resolution
	access_url::String="https://ads.atmosphere.copernicus.eu/datasets/cams-global-ghg-reanalysis-egg4"
	long_name::String="CO2 concentration 2015-2024 September"
	file_names::Vector=["cams_co2_col_september_2015_2024.nc"] # 2.5MB
	active_file::String="cams_co2_col_september_2015_2024.nc"
	file_dir::String="../Artifacts/CAMS/"

	variables::Vector=["XCO2"]
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(360,180,10)
	active_variable::String="XCO2"

	grid_resolution::Float32=1.0f0
	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict("XCO2"=>"mean molar concentration of CO2 each sept 2015-2024")
	var_limits::Dict=Dict("XCO2" => [368.7,380.5]) # from Cams
	var_units::Dict{String, String}=Dict("XCO2"=> "molar fraction")
	var_colors::Dict=Dict("XCO2" => identity(:co2))

	start_time::DateTime=DateTime(2015,9)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2024,9)
	time_indices::Vector=[1,1,10]
end

@kwdef mutable struct Oisst <: Eunice_type # sea surface temperatures, and ice cover, 1/2 deg resolution
	access_url::String="https://www.ncei.noaa.gov/products/climate-data-records/sea-surface-temperature-optimum-interpolation/v2.1/avhrr/"
	long_name::String="Sea surface temperature or ice 1982-2023 September, OI-SST"
	file_names::Vector=["oisst_september_1982_2023.nc", "oisst_ice_september_1982_2023.nc"] 
	active_file::String=file_names[1]
	file_dir::String="../Artifacts/OI_SST/"

	variables::Vector=["sst","ice"]
	active_variable::String=variables[1]
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(720,360,42)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"sst"=>"sea surface temperature each sept 1982-2023",
			"ice"=>"partial indicator for sea surface ice each sept 1982-2023")
	var_limits::Dict=Dict("sst" => [-1.8,32.2],
							"ice" => [0.0, 1.0])
	var_units::Dict{String, String}=Dict(
			"sst"=> "(C)",
			"ice"=>"(C)")
	var_colors::Dict{String, Symbol}=Dict(
			"sst"=> identity(:ocean_temperature),
			"ice"=> identity(:ice))
	
	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(1982,9)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2023,9)
	time_indices::Vector=[1,1,42]
end

@kwdef mutable struct Oscar2daily <: Eunice_type # global ocean currents, 1/2 deg resolution
	access_url::String="https://cmr.earthdata.nasa.gov/virtual-directory/collections/"
	long_name::String="Global ocean currents 2021 daily january or july"
	active_file::String="oscar2_2021_january2.nc"
	file_names::Vector=["oscar2_2021_january2.nc", "oscar2_2021_july2.nc"]
	file_dir::String="../Artifacts/OSCAR2/"

	variables::Vector=["u","v"]
	active_variable::Vector=["u","v"]
	dim_variables::Vector=["lat","lon","time"] # note the order of lat, lon
	dim_sizes::Tuple=(359,720,31) # lat x lon x time

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]

	var_defs::Dict{String,String}=Dict("[u,v]" => "ocean surface current velocity")
	var_limits::Dict=Dict("z" => [0.0, 1.5]) # z should be speed
	var_units::Dict{String, String}=Dict("[u,v]" => "(m/s)")	
	var_colors::Dict{String, Symbol}=Dict("[u,v]" => identity(:currents))

	grid_resolution::Float32=0.5f0

	start_time::DateTime = (occursin("january", active_file) ? DateTime(2021,1,1) : DateTime(2021,7,1))
	end_time::DateTime = (occursin("january", active_file) ? DateTime(2021,1,31) : DateTime(2021,7,31))
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	time_indices::Vector{Int}=[1,1,31]
end

@kwdef mutable struct Oscar2monthly <: Eunice_type # global ocean currents, 1/2 deg res
	access_url::String="https://cmr.earthdata.nasa.gov/virtual-directory/collections/"
	long_name::String="Global ocean currents monthly 2024"
	active_file::String="oscar2_2024_mthly.nc"
	file_names::Vector=["oscar2_2024_mthly.nc"]
	file_dir::String="../Artifacts/OSCAR2/"

	variables::Vector=["u","v"]
	active_variable::Vector=["u","v"] # <=================== different
	dim_variables::Vector=["lat","lon","time"] # lat lon reversed
	dim_sizes::Tuple=(359,720,12)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict("[u,v]" => "ocean surface current velocity")
	var_limits::Dict=Dict("z" => [0.0,1.5]) # is z correct ? should be speed
	var_units::Dict{String, String}=Dict("[u,v]" => "(m/s)")	
	var_colors::Dict{String, Symbol}=Dict("[u,v]" => identity(:ocean_currents))	

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2024,1)
	time_step::Union{Year, Month, Day, Hour}=Month(1)
	end_time::DateTime=DateTime(2024,12)
	time_indices::Vector{Int}=[1,1,12]
end

@kwdef mutable struct Cems <: Eunice_type # fire risk indices, 1/2 deg res
	access_url::String="https://ewds.climate.copernicus.eu/datasets/cems-fire-historical-v1"
	active_variable::String="fdimrk" 
	active_file::String="cems_fi_1984_2024_september.nc"
	long_name::String="CEMS fire indices, 1984-2024, march or september" 
	file_names::Vector=["cems_fi_1984_2024_march.nc", "cems_fi_1984_2024_september.nc"]
	file_dir::String="../Artifacts/CEMS/"

	variables::Vector=[ "buinfdr", "drtmrk","fdimrk", "fdsrte"]	
	dim_variables::Vector=["longitude","latitude","valid_time"]
	dim_sizes::Tuple=(720, 361, 41)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[90,-90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"buinfdr"=>"burning index of the US Forest Service", 
			"drtmrk"=>"drought factor of the Australian Forest Service",
			"fdimrk"=>"fire danger index of the Australian Forest Service",
			"fdsrte"=>"fire daily severity rating of the Canadian Forest Service")
	var_limits::Dict=Dict(
				"buinfdr" => [0.0,67.0],
				"drtmrk" => [0.1,10.0],
				"fdimrk" => [0.0,41.2],
				"fdsrte"  => [0.0,224.8])
	var_units::Dict{String, String}=Dict("buinfdr" => "(1)",
				"drtmrk" => "(1)",
				"fdimrk" => "(1)",
				"fdsrte"  => "(1)")	
	var_colors::Dict{String, Symbol}=Dict("buinfdr" => identity(:fire),
				"drtmrk" => identity(:fire),
				"fdimrk" => identity(:fire),
				"fdsrte"  => identity(:fire))	

	grid_resolution::Float32=0.5f0

	start_time::DateTime = (occursin("march", active_file) ? DateTime(1984,3,1) : DateTime(1984,9,1))
	end_time::DateTime = (occursin("march", active_file) ? DateTime(2024,3,1) : DateTime(2024,9,1))
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	time_indices::Vector{Int}=[1,1,41]
end

@kwdef mutable struct CdsCci <: Eunice_type # cloud cover measures, 1/2 deg resolution
	access_url::String="https://cds.climate.copernicus.eu/datasets/satellite-cloud-properties"
	active_variable::String="cfc"
	active_file::String="cds_cci_cfc_201801_202206_monthly.nc"
	long_name::String="CDS CCI Cloud variables files, 2018-2022 monthly"
	file_names::Vector=
		["cds_cci_cfc_201801_202206_monthly.nc",
		"cds_cci_cot_201801_202206_monthly.nc",
		"cds_cci_cer_201801_202206_monthly.nc",
		"cds_cci_ctp_201801_202206_monthly.nc",
		"cds_cci_ctt_201801_202206_monthly.nc",
		"cds_cci_cth_201801_202206_monthly.nc"]
	file_dir::String="../Artifacts/CCI/"

	variables::Vector=["cer","cfc","cot","ctp","ctt","cth"]
	dim_variables::Vector=["lon", "lat", "time"]
	dim_sizes::Tuple=(720,360,54)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]
	
	var_defs::Dict{String,String}=Dict(
			"cer"=>"cloud effective radius",
			"cfc"=>"cloud area fraction",
			"cot"=>"cloud optical depth at 550nm",
			"ctp"=>"cloud top pressure",
			"ctt"=>"cloud top temperature",
			"cth"=>"cloud top height")
	var_limits::Dict=Dict(
			"cer" => [0.3,100.0],
			"cfc" => [0.0,1.0],
			"cot" => [0.0,100.0],
			"ctp"  => [145.4, 1005.6],
			"ctt" => [203.1, 301.0],
			"cth" => [0.1, 13.6])
	var_units::Dict{String, String}=Dict(
			"cer"=>"(mu m)",
			"cfc"=>"(1)",
			"cot"=>"(mu m)",
			"ctp"=>"(hPa)",
			"ctt"=>"(K)",
			"cth"=>"(km)")	
	var_colors::Dict=Dict(
			"cer" => identity(:default),
			"cfc" => identity(:grayC),
			"cot" => identity(:buk),
			"ctp"  => identity(:pressure),
			"ctt" => identity(:temperture),
			"cth" => identity(:bukavu ))

	grid_resolution::Float32=0.5f0

	start_time::DateTime=DateTime(2018,1)
	time_step::Union{Year, Month, Day, Hour}=Month(1)
	end_time::DateTime=DateTime(2022,6)
	time_indices::Vector{Int}=[1,1,54]
end

@kwdef mutable struct Merra2 <: Eunice_type # surface air pressure, 1/2 deg resolution
	access_url::String="https://disc.gsfc.nasa.gov/datasets?project=MERRA-2" # GISS
     # also "https://gmao.gsfc.nasa.gov/reanalysis/merra-2/"
	long_name::String="Merra2 climate variables surface PS from 2025"
	active_file::String="Smerra2_2025_PS.nc"
	file_names::Vector=["Smerra2_2025_PS.nc"]
	file_dir::String="../Artifacts/MERRA2/"

	variables::Vector=["PS"]
	active_variable::String="PS"
	dim_variables::Vector=["lon", "lat", "time"]
	dim_sizes::Tuple=(576,361,31)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict("PS"=>"surface air pressure")
	var_units::Dict{String, String}=Dict("PS" => "(Pa)")	
	var_limits::Dict{String, Vector}=Dict("PS" => [50989.2,104716.2])
	var_colors::Dict{String, Symbol}=Dict("PS" => identity(:pressure))

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2025,1,1)
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	end_time::DateTime=DateTime(2025,1,31)
	time_indices::Vector{Int}=[1,1,31]
end

#--------------------------------------------------------------------------

#=
structs:
	dim=2
[:,:] lon x lat
	Etopo
	dim=3
[:,:,:] lon x lat x time
	Best
	CdsSla
	Jra55 plus [uas,vas] wind velocity
	Era5 plus [u10,v10] wind velocity
	CemsFas
	dim=4
[:,:,:,:] lon x lat x lev x time 
	Era5Lev
	Merra2Lev [U,V] wind velocity
	CamsCH4Lev
=#

# dim=2

@kwdef mutable struct Etopo  <: Eunice_type # bathymetry 1/60 deg resolution
	access_url::String="https://www.ncei.noaa.gov/products/etopo-global-relief-model"
	long_name::String="Global orography for 2022 surface (ice), bedrock and geoid"
	file_names::Vector{String}=
		["ETOPO_2022_v1_60s_N90W180_surface.nc",
		"ETOPO_2022_v1_60s_N90W180_bed.nc",
		"ETOPO_2022_v1_60s_N90W180_geoid.nc"]
	active_file::String= file_names[1]
	file_dir::String="../Artifacts/ETOPO/"

	variables::Vector=["z"] # will be "z" for any one of "surface", "bed", or  "geoid"]
	active_variable::String="z"
	dim_variables::Vector=["lon","lat"]
	dim_sizes::Tuple=(21600, 10800)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"surface"=>"a global relief model including the  height of the ice sheet surfaces measured upwards from sea level",
			"bed"=>"a global relief model including the height of the bedrock below the ice surfaces measured upwards from sea level",
			"geoid"=>"height of a virtual surface on which the earth's gravitational potential is constant and is not spherical")
	var_units::Dict{String,String}=Dict(
			"surface"=>"(m)",
			"bed"=>"(m)",
			"geoid"=>"(m)")
	var_limits::Dict{String,Vector}=Dict(
			"surface" => [-10752.1,8157.4],
			"bed"=>[-10752.1,8157.4],
			"geoid"=>[-106.9,85.8])
	var_colors::Dict{String,Symbol}=Dict(
			"surface" => identity(:elevation),
			"bed"=> identity(:generic),
			"geoid"=> identity(:elevation))

	grid_resolution::Float32=0.01667f0 # 1/60 deg resolution
	start_time::DateTime=DateTime(2022)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2022)
	time_indices::Vector{Int}=[]
end

@kwdef mutable struct Best <: Eunice_type  # fixed dims 13/5/2026, res and mask 1 deg
	access_url::String="https://climatedataguide.ucar.edu/climate-data/global-surface-temperatures-best-berkeley-earth-surface-temperatures"
	long_name::String="Berkeley global temperature 1950-2025"
	active_file::String="Land_and_Ocean_Alternate_LatLong1.nc" # 432MB
	file_names::Vector=["Land_and_Ocean_Alternate_LatLong1.nc"]
	file_dir::String="../Artifacts/BEST/"

	variables::Vector=["temperature", "land_mask", "climatology"] 
	active_variable::String=variables[1]
	dim_variables::Vector=["longitude","latitude","time"] # not in file "longitude" etc
	dim_sizes::Tuple=
		if active_variable=="temperature" Tuple((360,180, 2100))
		elseif active_variable=="climatology" Tuple((360,180,12))
		else Tuple((360,180))
		end

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,1]

	var_defs::Dict{String,String}=Dict(
			"temperature"=>"temperature anomaly relative to the climatology", 
			"land_mask"=>"Berkeley land mask", 
			"climatology"=>"Berkeley climatology using temp from 1951-1980 inclusive")
	var_units::Dict{String,String}=Dict(
			"temperature"=>"(K)",
			"land_mask"=>"(1)",
			"climatology"=>"(K)")
	var_limits::Dict{String,Vector}=Dict(
			"temperature" => [-9.7,4.0], 
			"land_mask"=> [0,1], 
			"climatology"=>[-47.9,32.2])
	var_colors::Dict{String,Symbol}=Dict(
			"temperature" => identity(:temperature), 
			"land_mask"=>  identity(:zeroone), 
			"climatology"=> identity(:temperature))

	grid_resolution::Float32=1.0f0
	start_time::DateTime =
		if active_variable=="temperature" DateTime(1950)
		elseif active_variable=="climatology" DateTime(1951)
		else DateTime(1950)
		end

	end_time::DateTime =
		if active_variable=="temperature" DateTime(2025,5)
		elseif active_variable=="climatology" DateTime(1980,12)
		else DateTime(1950)
		end

	time_step =
		if active_variable=="temperature" Year(1)
		elseif active_variable=="climatology" Month(1)
		else Month(1)
		end

	time_indices::Vector = (option=="temperature" ? [1801,12,2105] : [1,1,12])

end
# wrote to Berkeley Earth 28 April 26 re climatology 12 entries

@kwdef mutable struct CdsSla <: Eunice_type  # sea level anomalies, 1/4 deg res
	access_url::String="https://cds.climate.copernicus.eu/datasets/satellite-sea-level-global"
	long_name::String="CDS Sea level anomaly 1993-2023 march and september 6mthly"
	file_names::Vector=["cdssla_mar_sep_1993_2023.nc"]
	active_file::String="cdssla_mar_sep_1993_2023.nc"
	file_dir::String="../Artifacts/CDS/"

	variables::Vector=["sla"] # check <========================
	active_variable::String="sla" 
	dim_variables::Vector=["lon", "lat", "time"]
	dim_sizes::Tuple=(1440,720,62)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict("sla"=>"sea level anomaly each march and september 1993-2023")
	var_limits::Dict=Dict("sla" => [-1.1,0.8])
	var_units::Dict{String, String}=Dict("sla"=> "(m/s)")	
	var_colors::Dict{String, Symbol}=Dict("sla"=> identity(:elevation))	

	grid_resolution::Float32=0.25f0
	start_time::DateTime=DateTime(1993,3)
	time_step::Union{Year, Month, Day, Hour}=Month(6)
	end_time::DateTime=DateTime(2023,9)
	time_indices::Vector{Int}=[1,1,62]
end

@kwdef mutable struct Jra55 <: Eunice_type  # climate surface data, 9/16 deg resolution
	access_url::String="JRA55 or ClimaOcean.jl Artifacts from the git repository, orig files RYF.*.1990_1991.nc"
	long_name::String="Climate variable values from ClimaOcean.jl, 1990, daily"

	variables::Vector=[
		"rhuss", "huss", "lcalvf","praa","prsn","psi","rlds", 
		"rsds", "fas","uas", "vas","friver"]
	active_variable::String=variables[1]
	file_names::Vector=[
		"jra55_rhuss_1990_daily.nc",
		"jra55_huss_1990_daily.nc",
		"jra55_lcalvf_1990_daily.nc",
		"jra55_praa_1990_daily.nc",
		"jra55_prsn_1990_daily.nc",
		"jra55_psi_1990_daily.nc",
		"jra55_rlds.1990_daily.nc",
		"jra55_rsds_1990_daily.nc",
		"jra55_fas_1990_daily.nc",
		"jra55_uas_1990_daily.nc",
		"jra55_vas_1990_daily.nc",
		"jra55_friver_1990_daily.nc"]  # order is same as for variables::Vector
	active_file::String= "jra55_" * active_variable * "_1990_daily.nc" 
	file_dir::String="../Artifacts/JRA55/"
	
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(640,320,365) # extracted

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"rhuss"=>"surface relative humidity",
			"huss"=>"surface specific humidity",
			"lcalvf"=>"freshwater flux from calving icebergs",
			"prra"=>"rainfall flux",
			"prsn"=>"freshwater flux from snowfall",
			"psl"=>"sea level pressure",
			"rlds"=>"downwelling longwave radiation", 
			"rsds"=>"downwelling shortwave radiation",
			"tas"=>"near-surface air temperature",
			"uas"=>"eastward near-surface wind",
			"vas"=>"northward near-surface wind",
			"friver"=>"water flux into sea water from rivers")

	var_limits::Dict=Dict("prra" => [0.0, 0.00883],
			"prsn" => [0.0, 0.002627],    
			"lcalvf" => [0.0, 0.00474], 
			"huss" => [2.0f-5, 0.0664],    
			"psl" => [95508.0, 105371.0],     
			"rhuss" => [0.0, 206.0] ,   
			"rlds" => [105.0, 483.0],  
			"rsds" => [0.0, 1137.0],  
			"tas" => [236.0, 314.0],     
			"uas" => [-25.0, 29.0],    
			"vas" => [-21.0, 21.0],
			"friver" => [0.0, 0.2],
			"prra" => [0.0, 0.2])
	var_units::Dict{String, String}=Dict(
			"rhuss"=>"(%)",
			"huss"=>"(1)",
			"lcalvf"=>"(kg /(m^2 s))",
			"prra"=>"(kg /(m^2 s))",
			"prsn"=>"(kg /(m^2 s))",
			"psl"=>"(Pa)",
			"rlds"=>"(W/m^2)", 
			"rsds"=>"(W/m^2)",
			"tas"=>"(K)",
			"uas"=>"(m/s)",
			"vas"=>"(m/s)",
			"friver"=>"(kg /(m^2 s))")	
	var_colors::Dict{String, Symbol}=Dict(
			"rhuss"=> identity(:humidity),
			"huss"=> identity(:humidity),
			"lcalvf"=> identity(:ice),
			"prra"=> identity(:precipitation),
			"prsn"=> identity(:precipitation),
			"psl"=> identity(:pressure),
			"rlds"=> identity(:radiation), 
			"rsds"=> identity(:radiation),
			"tas"=> identity(:temperature),
			"uas"=> identity(:wind),
			"vas"=> identity(:wind),
			"friver"=> identity(:currents))	

	grid_resolution::Float32= 0.5625f0
	start_time::DateTime=DateTime(1990,1,1,1)
	time_step::Union{Year, Month, Day, Hour}=Day(1) # was Hour(3)
	end_time::DateTime=DateTime(1990,12,31,1)# was 12)
	time_indices::Vector{Int}=[1,1,365] # was 2920
end

@kwdef mutable struct Era5 <: Eunice_type  # climate surface data, 8 deg resolution
	access_url::String="https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels"
			# modifed by Clima: see ClimaLan Aftifacts
	long_name::String="Era5 climate surface variables"
	active_file::String="era5_2008_1.0x1.0_lowres.nc"
	file_names::Vector=["era5_2008_1.0x1.0_lowres.nc"]
	file_dir::String="../Artifacts/ERA5/"

	variables::Vector=["t2m","u10","v10","d2m","sp","msr","msdrswft", "msdwlwrf","msdwswrf","mtpr"]
	active_variable::String=variables[1]
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(45,23,8784) #  hourly for 2008 a leap year of 366 days

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,86]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_limits::Dict{String, Vector}=
		Dict(
		"t2m" => [231.0,309.5],
		"u10" => [-18.3,22.6],
		"v10" => [-16.6,19.6],
		"d2m" => [229.0,298.2],
		"sp" => [5176.3,104030.3],
		"msr" => [0.0,0.00181],
		"msdrswft" => [0.0,962.1],
		"msdwlwrf" => [92.2,440.2],
		"msdwswrf" => [0.0,1064.1],
		"mtpr" => [0.0,0.0081])
	var_defs::Dict{String,String}=
		Dict(
		"t2m" => "2 m temperature",
		"u10" => "10 m wind eastward velocity",
		"v10" => "10 m wind northward velocity",
		"d2m" => "2 m dewpoint temperature",
		"sp" => "surface air pressure",
		"msr" => "mean snowfall rate",
		"msdrswft" => "mean surface direct short-wave radiation flux",
		"msdwlwrf" => "mean surface direct long-wave radiation flux",
		"msdwswrf" => "mean surface downward short-wave radiation flux",
		"mtpr" => "mean total precipitation rate")
	var_units::Dict{String,String}=
		Dict(
		"t2m" => "(k)",
		"u10" => "(m/s)",
		"v10" => "(m/s)",
		"d2m" => "(K)",
		"sp" => "(Pa)",
		"msr" => "(kg/(m^2*s))",
		"msdrswft" => "(W/m^2)",
		"msdwlwrf" => "(W/m^2)",
		"msdwswrf" => "(W/m^2)",
		"mtpr" => "(kg/(m^2*s))")
	var_colors::Dict{String,Symbol}=
		Dict(
		"t2m" => identity(:temperature),
		"u10" => identity(:wind),
		"v10" => identity(:wind),
		"d2m" => identity(:temperature),
		"sp" => identity(:pressure),
		"msr" => identity(:precipitation),
		"msdrswft" => identity(:radiation),
		"msdwlwrf" => identity(:radiation),
		"msdwswrf" => identity(:radiation),
		"mtpr" => identity(:precipitation))

	grid_resolution::Float32=8.0f0

	start_time::DateTime=DateTime(2008,1,1)
	time_step::Union{Year, Month, Day, Hour}=Hour(1)
	end_time::DateTime=DateTime(2008,12,31,23)
	time_indices::Vector=[1,1,8784]
end

@kwdef mutable struct CemsFas <: Eunice_type  # floods 1/20 deg resolution
	access_url::String="https://ewds.climate.copernicus.eu/"
	long_name::String="Copernicus Emergency Management System, Flood GloFAS data"

	variables::Vector=[
		"swir", "dis24", "sd", "rowe"]
	active_variable::String=variables[1]
	file_names::Vector=[
		"cemsfas_swir_2025.nc",
		"cemsfas_dis24_2025.nc",
		"cemsfas_sd_2025.nc",
		"cemsfas_rowe_2025.nc"]  # order is same as for variables::Vector
	active_file::String= "cemsfas_" * active_variable * "_2025.nc" 
	file_dir::String="../Artifacts/CEMSFAS/"


	dim_variables::Vector=["longitude","latitude","valid_time"]
	dim_sizes::Tuple=(7200, 3000,48) # collated

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-60,90] # no antartica
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"swir"=>"soil wetness index (rootZone)",
			"dis24"=>"mean river discharge in the previous 24 hours",
			"sd"=>"snow depth water equivalent",
			"rowe"=>"runoff water equivalent (surface and subsurface)")

	var_limits::Dict=Dict(
			"swir" => [0.0,1.0],
			"dis24" => [0.0,128428.5],
			"sd" => [0.0, 582303.9],    
			"rowe" => [0.0, 192.7])

	var_units::Dict{String, String}=Dict(
			"swir" => "(1e0)",
			"dis24" => "(m^3/s)",
			"sd" => "(kg/m^2)",
			"rowe" => "(kg /m^2)")	
			
	var_colors::Dict{String, Symbol}=Dict(
			"swir" => identity(:precipitation),
			"dis24" =>  identity(:roma),
			"sd" =>  identity(:precipitation),
			"rowe" => identity(:currents))				

	grid_resolution::Float32= 5e-3
	start_time::DateTime=DateTime(2025,1,2)
	time_step::Union{Year, Month,Week, Day, Hour}=Day(7) # equivalent uniform week for 48 steps
	end_time::DateTime=DateTime(2025,12,23)
	time_indices::Vector{Int}=[1,1,48]
end

#---------------------------------------------------------------------------
# dim=4
@kwdef mutable struct Era5Lev <: Eunice_type  # cloud variables with levels, 12 deg res
	access_url::String="https://climate.copernicus.eu/what-copernicus-climate-change-services-era5-reanalysis-dataset"
	long_name::String="Era5 cloud variables with levels"
	active_file::String="era5_cloud_lowres.nc"
	file_names::Vector=["era5_cloud_lowres.nc"]
	file_dir::String="../Artifacts/ERA5/"

	variables::Vector=["cc","ciwc","clwc","q","r"] 
	active_variable::String=variables[1]
	dim_variables::Vector=["lon","lat","z","time"]
	dim_sizes::Tuple=(30,16,37,1460) # every 6 hours for 2010 except for the last 6 hours 

	lon_limits::Vector=[0,348]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,37]

	var_limits::Dict=Dict(
		"cc" => [0,1],
		"ciwc" => [0.0,0.001217],
		"clwc" => [0.0,0.001167],
		"q" => [-1.7613114f-5, 0.0253443],
		"r" => [0.1,1.0])
	var_defs::Dict{String,String}=Dict(
		"cc"=>"cloud cover fraction",
		"ciwc"=>"specific cloud ice water content",
		"clwc"=>"specific cloud liquid water content",
		"q"=>"specific humidity",
		"r"=>"relative humidity")
	var_units::Dict{String, String}=Dict(
			"cc"=>"(1)",
			"ciwc"=>"(kg/kg)",
			"clwc"=>"(kg/kg)",
			"q"=>"(kg/kg)",
			"r"=>"(1)")
	var_colors::Dict{String, Symbol}=Dict(
			"cc"=> identity(:clouds),
			"ciwc"=> identity(:precipitation),
			"clwc"=> identity(:precipitation),
			"q"=> identity(:humidity),
			"r"=> identity(:humidity))

	grid_resolution::Float32=12.0f0
	start_time::DateTime=DateTime(2010,1,1,1)
	time_step::Union{Year, Month, Day, Hour}=Hour(6)
	end_time::DateTime=DateTime(2010,12,31,18)
	time_indices::Vector=[1,1,1460]	
end

@kwdef mutable struct Merra2Lev  <: Eunice_type  # ozone and other variables with levels, 1/2 deg res
	access_url::String="https://disc.gsfc.nasa.gov/datasets?project=MERRA-2" # GISS
     # also "https://gmao.gsfc.nasa.gov/reanalysis/merra-2/"
# daily such as "MERRA2_400.inst6_3d_ana_Nv.20250101.nc4"
	long_name::String="Merra2 climate variables from Jan 2025 with levels"	

	variables::Vector=["O3", "T", "U", "V", "QV","DELP"]
	active_variable::String=variables[1]
	active_file::String="Smerra2_2025_" * active_variable * ".nc"
	file_names::Vector=[
		"Smerra2_2025_O3.nc",
		"Smerra2_2025_T.nc",
		"Smerra2_2025_U.nc",
		"Smerra2_2025_V.nc",
		"Smerra2_2025_QV.nc",
		"Smerra2_2025_DELP.nc"]
	file_dir::String="../Artifacts/MERRA2/"

	dim_variables::Vector=["lon", "lat", "lev","time"]
	dim_sizes::Tuple=(576,361,18,31)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,18]

	var_limits::Dict=Dict(
			"DELP" => [463.0,463.8],
			"T" => [187.94,240.134],    
			"U" => [-24.1,64.45],
			"V" => [-28.2,44.51],    
			"QV" => [2.54f-6, 3.656f-6],    
			"O3" => [5.05f-6,1.11f-5])
	var_defs::Dict{String,String}=Dict(
		"03" => "ozone concentration",
		"T" => "air temperature", 
		"U" => "eastward wind component", 
		"V" => "northward wind component", 
		"QV" => "specific humidity",
		"DELP" => "layer pressure thickness")
	var_units::Dict{String, String}=Dict(
		"03" => "(ppb)",
		"T" => "(K)", 
		"U" => "(m/s)", 
		"V" => "(m/s)", 
		"QV" => "(kg/kg)",
		"DELP" => "(Pa)")
	var_colors::Dict{String, Symbol}=Dict(
		"03" => identity(:ozone),
		"T" => identity(:temperature), 
		"U" => identity(:wind), 
		"V" => identity(:wind), 
		"QV" => identity(:humidity),
		"DELP" => identity(:length))

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2025,1)
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	end_time::DateTime=DateTime(2025,1)
	time_indices::Vector{Int}=[1,1,31]
end

@kwdef mutable struct CamsCH4Lev <: Eunice_type  # methane concentrations with levels march or september
	access_url::String="https://ads.atmosphere.copernicus.eu/datasets/cams-global-ghg-reanalysis-egg4" # ?
	long_name::String="CAMS ch4 satellite for 2024 september or march daily with levels"
	file_names::Vector=["cams73_latest_ch4_conc_surface_satellite_dm_202409.nc",
			"cams73_latest_ch4_conc_surface_satellite_dm_202403.nc"]
	active_file=file_names[1]

	file_dir::String="../Artifacts/CAMS/"

	variables::Vector=["CH4","T","Q","ps"]
	active_variable::String="CH4"
	dim_variables::Vector=["longitude","latitude","level","time"]
	dim_sizes::Tuple=(360,180,34,30)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,34]

	var_defs::Dict{String,String}=Dict(
		"CH4"=>"mole fraction of CH4 in dry air",
		"T"=>"air temperature",
		"Q"=>"specific humidity",
		"ps"=>"surface air pressure")
	var_limits::Dict=Dict(
		"CH4" => [1851.8,5917.2],
		"T"=>[220.7, 310.0],
		"Q"=>[3.14787f-7, 0.024983805],
		"ps"=>[52005.6,104459.8])
	var_units::Dict{String, String}=Dict(
		"CH4"=> "(molar fraction of dry air)",
		"T"=>"(K)", 
		"Q"=>"(1)", 
		"ps"=>"(Pa)")
	var_colors::Dict{String, Symbol}=Dict(
		"CH4"=> identity(:co2),
		"T"=> identity(:temperature), 
		"Q"=> identity(:humidity), 
		"ps"=> identity(:pressure))

	grid_resolution::Float32=1.0f0

	start_time::DateTime=(occursin("09.nc", active_file) ? DateTime(2024,9,1) : DateTime(2024,3,1))
	end_time::DateTime=(occursin("09.nc", active_file) ? DateTime(2024,9,30) : DateTime(2024,3,31))
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	time_indices::Vector= (occursin("09.nc", active_file) ? [1,1,30] : [1,1,31])
end

#------------------------------------------------------------------------
Eunice_types=[
	Isimip,
	NceiNoaa,
#
	NoaaTemp,
	NoaaTempMonthly,
	Cheng,
	Cams,
	CamsCO2,
	Oisst,
	Cems,
	CdsCci,
	Oscar2daily,
	Oscar2monthly,
	Merra2,
##
	Etopo,
#
	Best,
	CdsSla,
	Jra55,
	Era5,
	CemsFas,
#
	Merra2Lev,
	Era5Lev,
	CamsCH4Lev]

#------------------------------------------------------------------------
