# Eunice_types_git.jl
using Dates
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

	dim=4
=#

# dim=2

@kwdef mutable struct Isimip # land sea mask 1/2 deg resolution
	access_url::String="https://cds.climate.copernicus.eu"
	long_name::String="WFDE5-ERA5 MASK"
	file_names::Vector=["landseamask.nc"]
	option::String=""
	main_file::String= "landseamask.nc"
	file_dir::String="../Artifacts/ISIMIP/"

	variables::Vector=["mask"]
	main_variable::String="mask"
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

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2026)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2026)
	time_indices::Vector{Int}=[]
end

@kwdef mutable struct NceiNoaa # vegetation
	access_url::String=
"https://www.ncei.noaa.gov/thredds/catalog/sat/landcover/RF_AREAVEG/land-cover_rf_landcover_yr2007.nc"
	long_name::String="Global dominant vegetation species"
	option::String="2007"
	main_file::String="land-cover_rf_landcover_yr" * option * ".nc"
	file_names::Vector=["land-cover_rf_landcover_yr1997.nc", "land-cover_rf_landcover_yr2007.nc"]
	file_dir::String="../Artifacts/NCEI_NOAA/"

	variables::Vector=["Dominant_type", "Water", "Urban", "C3grass", "C4grass", "Savanna", "Tundra", "C3crop", "C4crop", "C3past", "C4past"] # many other variables in the .nc files, available here using NceiNoaa().main_variable= "new_variable_name"
	main_variable::String="Dominant_type" 
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

	grid_resolution::Float32=0.5f0
	start_time::DateTime=(option=="2007" ? DateTime(2007) : DateTime(1997))
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=start_time
	time_indices::Vector{Int}=[1]
end

#--------------------------------------------------------------------
#dim=3
@kwdef mutable struct NoaaTemp # global surface temperatures 5 deg res
	access_url::String="https://www.ncei.noaa.gov/products/land-based-station/noaa-global-temp"
	option::String=""
	long_name::String="NOAA global temperature 1950-2024"
	main_file::String="NOAAGlobalTemp_1950_2024_sept.nc"
	file_names::Vector=["NOAAGlobalTemp_1950_2024_sept.nc"] # 1MB
	file_dir::String="../Artifacts/NOAA/"

	variables::Vector=["anom"]
	main_variable::String="anom"
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(72,36,75)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,1]

	var_defs::Dict{String,String}=Dict("anom"=>"global temp anomaly yearly Septembers 1950-2024")
	var_units::Dict{String, String}=Dict("anom"=>"degrees C")
	var_limits::Dict=Dict("anom" => [-11.5,4.8])

	grid_resolution::Float32=5.0f0
	start_time::DateTime=DateTime(1950,9)
	time_step::Union{Year, Month, Week, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2024,9)
	time_indices::Vector=[1,1,75] # or [1,1,175]
end

@kwdef mutable struct NoaaTempMonthly  # global surface temperatures
	option::String=""
	access_url::String="https://www.ncei.noaa.gov/products/land-based-station/noaa-global-temp"
	long_name::String="NOAA global temperature 1850-2024 monthly"
	main_file::String="NOAAGlobalTemp_v6.0.0_gridded_s185001_e202505.nc" # 21MB
	file_names::Vector=["NOAAGlobalTemp_v6.0.0_gridded_s185001_e202505.nc"]
	file_dir::String="../Artifacts/NOAA/"

	variables::Vector=["anom"]
	main_variable::String="anom"
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(72,36,1,2105)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[1,1,1]

	var_defs::Dict{String,String}=Dict("anom"=>"global temperature anomaly monthly 1850-2025")
	var_limits::Dict=Dict("anom" => [-11.5,4.8])
	var_units::Dict{String, String}=Dict("temperture"=>"degrees C")

	grid_resolution::Float32=5.0f0
	start_time::DateTime=DateTime(1850,9)
	time_step::Union{Year, Month, Day, Hour}=Month(1)
	end_time::DateTime=DateTime(2025,5)
	time_indices::Vector=[1, 1, 2105]	
end

@kwdef mutable struct Best # fixed dims 13/5/2026, res and mask 1 deg
	access_url::String="https://climatedataguide.ucar.edu/climate-data/global-surface-temperatures-best-berkeley-earth-surface-temperatures"
	long_name::String="Berkeley global temperature 1950-2025"
	main_file::String="Land_and_Ocean_Alternate_LatLong1.nc" # 432MB
	file_names::Vector=["Land_and_Ocean_Alternate_LatLong1.nc"]
	file_dir::String="../Artifacts/BEST/"
	option::String="temperature"

	variables::Vector=["temperature", "land_mask", "climatology"] 
	main_variable=option
	dim_variables::Vector=["longitude","latitude","time"] # not in file "longitude" etc
	dim_sizes::Tuple=
		if option=="temperature" Tuple((360,180, 2100))
		elseif option=="climatology" Tuple((360,180,12))
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
	var_limits::Dict=Dict(
			"temperature" => [-9.7,4.0], 
			"land_mask"=> [0,1], 
			"climatology"=>[-47.9,32.2])

	grid_resolution::Float32=1.0f0
	start_time::DateTime =
		if option=="temperature" DateTime(1950)
		elseif option=="climatology" DateTime(1951)
		else DateTime(1950)
		end

	end_time::DateTime =
		if option=="temperature" DateTime(2025,5)
		elseif option=="climatology" DateTime(1980,12)
		else DateTime(1950)
		end

	time_step =
		if option=="temperature" Year(1)
		elseif option=="climatology" Month(1)
		else Month(1)
		end

	time_indices::Vector = (option=="temperature" ? [1801,12,2105] : [1,1,12])

end
# wrote to Berkeley Earth 28 April 26 re climatology 12 entries

@kwdef mutable struct Cheng # carbon dioxide conc, 1 deg resolution
# see also CO2_1deg_month_1850-2023.nc
	access_url::String="https://doi.org/10.5281/zenodo.5021361"
	long_name::String="Estimated C02 concentration 1950-2013 Septs, Cheng"
	option::String=""
	file_names::Vector=["CO2_1deg_september_1950-2013.nc"] # 32MB
	main_file::String="CO2_1deg_september_1950-2013.nc"
	file_dir::String="../Artifacts/CHENG/"

	variables::Vector=["value"]
	main_variable="value"
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(360,180,64)

	lon_limits::Vector=[-180,180] # defaults check
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict("value"=>"CO2 concentration Sept 1950-2013")
	var_units::Dict{String, String}=Dict("value"=>"ppm")
	var_limits::Dict=Dict("value"=>[284.0, 288.7])

	grid_resolution::Float32=1.0f0
	start_time::DateTime=DateTime(1950,9)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2013,9)	
	time_indices::Vector=[1,1,64]
end
@kwdef mutable struct Cams # CO2 and CH4 conc, 3/4 deg resolution
	access_url::String="https://ads.atmosphere.copernicus.eu/datasets/cams-global-ghg-reanalysis-egg4"
	long_name::String="Column mean molar fraction C02 & CH4, 2003-2020, 6 mthly"
	option::String="tcco2"
	file_names::Vector=["cams_data_allhours_sfc.nc"]
	main_file::String="cams_data_allhours_sfc.nc"
	file_dir::String="../Artifacts/CAMS/"

	variables::Vector=["tcco2","tcch4"]
	main_variable::String=option
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

	grid_resolution::Float32=0.75f0
	start_time::DateTime=DateTime(2003,3)
	time_step::Union{Year, Month, Day, Hour}=Month(6)
	end_time::DateTime=DateTime(2020,9)
	time_indices::Vector=[1,1,36] # was [1801,12,2105]
end

@kwdef mutable struct CamsCO2 # carbon dioxide conc, 1 deg resolution
	access_url::String="https://ads.atmosphere.copernicus.eu/datasets/cams-global-ghg-reanalysis-egg4"
	long_name::String="CO2 concentration 2015-2024 September"
	file_names::Vector=["cams_co2_col_september_2015_2024.nc"] # 2.5MB
	option::String=""
	main_file::String="cams_co2_col_september_2015_2024.nc"
	file_dir::String="../Artifacts/CAMS/"

	variables::Vector=["XCO2"]
	dim_variables::Vector=["lon","lat","time"]
	dim_sizes::Tuple=(360,180,10)
	main_variable::String="XCO2"

	grid_resolution::Float32=1.0f0
	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict("XCO2"=>"mean molar concentration of CO2 each sept 2015-2024")
	var_limits::Dict=Dict("XCO2" => [368.7,380.5]) # from Cams
	var_units::Dict{String, String}=Dict("XCO2"=> "molar fraction")

	start_time::DateTime=DateTime(2015,9)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2024,9)
	time_indices::Vector=[1,1,10]
end

@kwdef mutable struct Oisst # sea surface temperatures, and ice cover, 1/2 deg resolution
	access_url::String="https://www.ncei.noaa.gov/products/climate-data-records/sea-surface-temperature-optimum-interpolation/v2.1/avhrr/"
	long_name::String="Sea surface temperature or ice 1982-2023 September, OI-SST"
	option::String="sst"
	file_names::Vector=["oisst_september_1982_2023.nc", "oisst_ice_september_1982_2023.nc"] 
	main_file::String=(option=="sst" ? file_names[1] : file_names[2]) 
	file_dir::String="../Artifacts/OI_SST/"

	variables::Vector=["sst","ice"]
	main_variable::String=option 
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
	
	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(1982,9)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2023,9)
	time_indices::Vector=[1,1,42]
end

@kwdef mutable struct Oscar2daily # global ocean currents, 1/2 deg resolution
	access_url::String="https://cmr.earthdata.nasa.gov/virtual-directory/collections/"
	long_name::String="Global ocean currents 2021 daily january or july"
	option::String="january"
	main_file::String="oscar2_2021_" * option * "2.nc"
	file_names::Vector=["oscar2_2021_january2.nc", "oscar2_2021_july2.nc"]
	file_dir::String="../Artifacts/OSCAR2/"

	variables::Vector=["u","v"]
	main_variable::Vector=["u","v"]
	dim_variables::Vector=["lat","lon","time"] # note the order of lat, lon
	dim_sizes::Tuple=(359,720,31) # lat x lon x time

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]

	var_defs::Dict{String,String}=Dict("[u,v]" => "ocean surface current velocity")
	var_limits::Dict=Dict("z" => [0.0, 1.5]) # z should be speed
	var_units::Dict{String, String}=Dict("[u,v]" => "(m/s)")	

	grid_resolution::Float32=0.5f0

	start_time::DateTime = (option=="january" ? DateTime(2021,1,1) : DateTime(2021,7,1))
	end_time::DateTime = (option=="january" ? DateTime(2021,1,31) : DateTime(2021,7,31))
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	time_indices::Vector{Int}=[1,1,31]
end

@kwdef mutable struct Oscar2monthly # global ocean currents, 1/2 deg res
	access_url::String="https://cmr.earthdata.nasa.gov/virtual-directory/collections/"
	long_name::String="Global ocean currents monthly 2024"
	option::String=""
	main_file::String="oscar2_2024_mthly.nc"
	file_names::Vector=["oscar2_2024_mthly.nc"]
	file_dir::String="../Artifacts/OSCAR2/"

	variables::Vector=["u","v"]
	main_variable::Vector=["u","v"] # <=================== different
	dim_variables::Vector=["lat","lon","time"] # lat lon reversed
	dim_sizes::Tuple=(359,720,12)

	lon_limits::Vector=[0,360]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	lev_limits::Vector=[]

	var_defs::Dict{String,String}=Dict("[u,v]" => "ocean surface current velocity")
	var_limits::Dict=Dict("z" => [0.0,1.5]) # is z correct ? should be speed
	var_units::Dict{String, String}=Dict("[u,v]" => "(m/s)")	

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2024,1)
	time_step::Union{Year, Month, Day, Hour}=Month(1)
	end_time::DateTime=DateTime(2024,12)
	time_indices::Vector{Int}=[1,1,12]
end

@kwdef mutable struct Cems # fire risk indices, 1/2 deg res
	access_url::String="https://ewds.climate.copernicus.eu/datasets/cems-fire-historical-v1"
	option::String="september"
	main_variable::String="fdimrk" 
	main_file::String="cems_fi_1984_2024_" * option * ".nc"
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

	grid_resolution::Float32=0.5f0

	start_time::DateTime = (option=="march" ? DateTime(1984,3,1) : DateTime(1984,9,1))
	end_time::DateTime = (option=="march" ? DateTime(2024,3,1) : DateTime(2024,9,1))
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	time_indices::Vector{Int}=[1,1,41]
end

@kwdef mutable struct CdsCci # cloud cover measures, 1/2 deg resolution
	access_url::String="https://cds.climate.copernicus.eu/datasets/satellite-cloud-properties"
	option::String="cfc"
	main_variable::String=option 
	main_file::String="cds_cci_" * option * "_201801_202206_monthly.nc"
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

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2018,1)
	time_step::Union{Year, Month, Day, Hour}=Month(1)
	end_time::DateTime=DateTime(2022,6)
	time_indices::Vector{Int}=[1,1,54]
end

@kwdef mutable struct Merra2 # surface air pressure, 1/2 deg resolution
	access_url::String="https://disc.gsfc.nasa.gov/datasets?project=MERRA-2" # GISS
     # also "https://gmao.gsfc.nasa.gov/reanalysis/merra-2/"
	long_name::String="Merra2 climate variables surface PS from 2025"
	option::String=""
	main_file::String="Smerra2_2025_PS.nc"
	file_names::Vector=["Smerra2_2025_PS.nc"]
	file_dir::String="../Artifacts/MERRA2/"

	variables::Vector=["PS"]
	main_variable::String="PS"
	dim_variables::Vector=["lon", "lat", "time"]
	dim_sizes::Tuple=(576,361,31)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict("PS"=>"surface air pressure")
	var_units::Dict{String, String}=Dict("PS" => "(Pa)")	
	var_limits::Dict{String, Vector}=Dict("PS" => [50989.2,104716.2])

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2025,1,1)
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	end_time::DateTime=DateTime(2025,1,31)
	time_indices::Vector{Int}=[1,1,31]
end

#--------------------------------------------------------------------------
Eunice_types_git=Union{
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
	Merra2}

#------------------------------------------------------------------------
