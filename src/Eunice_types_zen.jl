# Eunice_types_zen.jl
using Dates
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

@kwdef mutable struct Etopo # bathymetry 1/60 deg resolution
	access_url::String="https://www.ncei.noaa.gov/products/etopo-global-relief-model"
	long_name::String="Global orography for 2022 surface (ice), bedrock and geoid"
	file_names::Dict{String,String}=
		Dict("surface"=>"ETOPO_2022_v1_60s_N90W180_surface.nc",
		"bed"=>"ETOPO_2022_v1_60s_N90W180_bed.nc",
		"geoid"=>"ETOPO_2022_v1_60s_N90W180_geoid.nc")
	option::String="surface"
	main_file::String= get(file_names, option, "surface") 
	file_dir::String="../Artifacts/ETOPO/"

	variables::Vector=["z"] #will be "z" for ["surface", "bed", "geoid"]
	main_variable::String="z"
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

	grid_resolution::Float32=0.01667f0 # 1/60 deg resolution
	start_time::DateTime=DateTime(2022)
	time_step::Union{Year, Month, Day, Hour}=Year(1)
	end_time::DateTime=DateTime(2022)
	time_indices::Vector{Int}=[]
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


@kwdef mutable struct CdsSla # sea level anomalies, 1/4 deg res
	access_url::String="https://cds.climate.copernicus.eu/datasets/satellite-sea-level-global"
	long_name::String="CDS Sea level anomaly 1993-2023 march and september 6mthly"
	option::String=""
	file_names::Vector=["cdssla_mar_sep_1993_2023.nc"]
	main_file::String="cdssla_mar_sep_1993_2023.nc"
	file_dir::String="../Artifacts/CDS/"

	variables::Vector=["sla"] # check <========================
	main_variable::String="sla" 
	dim_variables::Vector=["lon", "lat", "time"]
	dim_sizes::Tuple=(1440,720,62)

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-90,90]
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict("sla"=>"sea level anomaly each march and september 1993-2023")
	var_limits::Dict=Dict("sla" => [-1.1,0.8])
	var_units::Dict{String, String}=Dict("sla"=> "(m/s)")	

	grid_resolution::Float32=0.25f0
	start_time::DateTime=DateTime(1993,3)
	time_step::Union{Year, Month, Day, Hour}=Month(6)
	end_time::DateTime=DateTime(2023,9)
	time_indices::Vector{Int}=[1,1,62]
end

@kwdef mutable struct Jra55 # climate surface data, 9/16 deg resolution
	access_url::String="JRA55 or ClimaOcean.jl Artifacts from the git repository, orig files RYF.*.1990_1991.nc"
	long_name::String="Climate variable values from ClimaOcean.jl, 1990, daily"
	option::String="rhuss"
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
	main_file::String= "jra55_" * option * "_1990_daily.nc" 
	file_dir::String="../Artifacts/JRA55/"

	variables::Vector=[
		"rhuss", "huss", "lcalvf","praa","prsn","psi","rlds", 
		"rsds", "fas","uas", "vas","friver"]
	main_variable::String=option
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
			"praa"=>"rainfall flux",
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

	grid_resolution::Float32= 0.5625f0
	start_time::DateTime=DateTime(1990,1,1,1)
	time_step::Union{Year, Month, Day, Hour}=Day(1) # was Hour(3)
	end_time::DateTime=DateTime(1990,12,31,1)# was 12)
	time_indices::Vector{Int}=[1,1,365] # was 2920
end

@kwdef mutable struct Era5 # climate surface data, 8 deg resolution
	access_url::String="https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels"
			# modifed by Clima: see ClimaLan Aftifacts
	long_name::String="Era5 climate surface variables"
	option::String="t2m"
	main_file::String="era5_2008_1.0x1.0_lowres.nc"
	file_names::Vector=["era5_2008_1.0x1.0_lowres.nc"]
	file_dir::String="../Artifacts/ERA5/"

	variables::Vector=["t2m","u10","v10","d2m","sp","msr","msdrswft", "msdwlwrf","msdwswrf","mtpr"]
	main_variable::String=option
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

	grid_resolution::Float32=8.0f0
	start_time::DateTime=DateTime(2008,1,1)
	time_step::Union{Year, Month, Day, Hour}=Hour(1)
	end_time::DateTime=DateTime(2008,12,31,23)
	time_indices::Vector=[1,1,8784]
end

@kwdef mutable struct CemsFas # floods 1/20 deg resolution
	access_url::String="https://ewds.climate.copernicus.eu/"
	long_name::String="Copernicus Emergency Management System, Flood GloFAS data"
	option::String="swir" # other options are "dis24", "sd", "rowe"
	file_names::Vector=[
		"cemsfas_swir_2025.nc",
		"cemsfas_dis24_2025.nc",
		"cemsfas_sd_2025.nc",
		"cemsfas_rowe_2025.nc"]  # order is same as for variables::Vector
	main_file::String= "cemsfas_" * option * "_2025.nc" 
	file_dir::String="../Artifacts/CEMSFAS/"

	variables::Vector=[
		"swir", "dis24", "sd", "rowe"]
	main_variable::String=option
	dim_variables::Vector=["longitude","latitude","valid_time"]
	dim_sizes::Tuple=(7200, 3000,48) # collated

	lon_limits::Vector=[-180,180]
	lat_limits::Vector=[-60,90] # no antartica
	zoom_limits::Vector=[0.5,4.0]
	level_range::Vector=[]

	var_defs::Dict{String,String}=Dict(
			"swir"=>"soil wetness index (rootZone)",
			"dis24"=>"mean river discharge in the previous 24hours",
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

	grid_resolution::Float32= 5e-3
	start_time::DateTime=DateTime(2025,1,2)
	time_step::Union{Year, Month,Week, Day, Hour}=Day(7) # equivalent uniform week for 48 steps
	end_time::DateTime=DateTime(2025,12,23)
	time_indices::Vector{Int}=[1,1,48]
end

#---------------------------------------------------------------------------
# dim=4
@kwdef mutable struct Era5Lev # cloud variables with levels, 12 deg res
	access_url::String="https://climate.copernicus.eu/what-copernicus-climate-change-services-era5-reanalysis-dataset"
	long_name::String="Era5 cloud variables with levels"
	main_file::String="era5_cloud_lowres.nc"
	file_names::Vector=["era5_cloud_lowres.nc"]
	file_dir::String="../Artifacts/ERA5/"
	option::String="cc"

	variables::Vector=["cc","ciwc","clwc","q","r"] 
	main_variable::String=option
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

	grid_resolution::Float32=12.0f0
	start_time::DateTime=DateTime(2010,1,1,1)
	time_step::Union{Year, Month, Day, Hour}=Hour(6)
	end_time::DateTime=DateTime(2010,12,31,18)
	time_indices::Vector=[1,1,1460]	
end

@kwdef mutable struct Merra2Lev  # ozone and other variables with levels, 1/2 deg res
	access_url::String="https://disc.gsfc.nasa.gov/datasets?project=MERRA-2" # GISS
     # also "https://gmao.gsfc.nasa.gov/reanalysis/merra-2/"
# daily such as "MERRA2_400.inst6_3d_ana_Nv.20250101.nc4"
	long_name::String="Merra2 climate variables from Jan 2025 with levels"	
	option::String="O3"
	main_file::String="Smerra2_2025_" * option * ".nc"
	file_names::Vector=[
		"Smerra2_2025_O3.nc",
		"Smerra2_2025_T.nc",
		"Smerra2_2025_U.nc",
		"Smerra2_2025_V.nc",
		"Smerra2_2025_QV.nc",
		"Smerra2_2025_DELP.nc"]
	file_dir::String="../Artifacts/MERRA2/"

	variables::Vector=["O3", "T", "U", "V", "QV","DELP"]
	main_variable::String=option
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

	grid_resolution::Float32=0.5f0
	start_time::DateTime=DateTime(2025,1)
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	end_time::DateTime=DateTime(2025,1)
	time_indices::Vector{Int}=[1,1,31]
end

@kwdef mutable struct CamsCH4Lev # methane concentrations with levels march or september
	access_url::String="https://ads.atmosphere.copernicus.eu/datasets/cams-global-ghg-reanalysis-egg4" # ?
	long_name::String="CAMS ch4 satellite for 2024 september or march daily with levels"
	file_names::Vector=["cams73_latest_ch4_conc_surface_satellite_dm_202409.nc",
			"cams73_latest_ch4_conc_surface_satellite_dm_202403.nc"]
	option::String="september"
	main_file::String = (option=="september" ? file_names[1] : file_names[2])
#=
		(if option=="september" "cams73_latest_ch4_conc_surface_satellite_dm_202409.nc"
		else "cams73_latest_ch4_conc_surface_satellite_dm_202403.nc"
		end)
=#
	file_dir::String="../Artifacts/CAMS/"

	variables::Vector=["CH4","T","Q","ps"]
	main_variable::String="CH4"
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

	grid_resolution::Float32=1.0f0
	start_time::DateTime=(option=="september" ? DateTime(2024,9,1) : DateTime(2024,3,1))
	end_time::DateTime=(option=="september" ? DateTime(2024,9,30) : DateTime(2024,3,31))
	time_step::Union{Year, Month, Day, Hour}=Day(1)
	time_indices::Vector= (option=="september" ? [1,1,30] : [1,1,31])
end
#--------------------------------------------------------------------------
Eunice_types_zen=Union{
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
	CamsCH4Lev}

#------------------------------------------------------------------------
