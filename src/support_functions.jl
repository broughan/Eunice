# support_functions1.jl GeoMakie v0.7.15
#=
functions:
	find_matching_element (strings)
	plot_number
	vecs2speed
	vecs2speed_lev
	scalar_range
	speed_range
	filter_missing_vectors
	filter_and_scale_vectors2
	meshgrid
	cat_map   (category colormap)
	Base.show (overload Eunice_type)
=# 
#------------------------------------------------------------------------

abstract type Eunice_type end

# overloading:
function Base.show(io::IO, ::MIME"text/plain", x::Eunice_type)
    print(io, typeof(x), " fields:")
    for field in propertynames(x)
        print(io, "\n  • ", field, " = ", repr(getproperty(x, field)))
    end
end

#--------------------------------------------------------------
function find_matching_element(sub_string, y)
	first_index = findfirst(x->occursin(sub_string,x),y)
	if isnothing(first_index) nothing
	else y[first_index]
	end
end

#---------------------------------------------------------------
# plot number_function:
let state = Ref(0)
    global function plot_number(; x0=nothing)
        # Initialize only if the state hasn't been set
        if x0 !== nothing
            state[] = x0
        end
        
        # Capture current value and increment
        val = state[]
        state[] += 1
        return val
    end
end

#------------------------------------------------------------------
function vec2speed(du,dv;trans=false)
	(nlat,nlon,ntime)=size(du)
	t_speed=Array{Any,3}(undef, (nlat,nlon,ntime))
	if trans	
		# compute the speed as a function of lon, lat, time:
		
		t_speed .= sqrt.(du .^2 .+ dv .^2)
		dz = permutedims(t_speed, (2, 1, 3))  # for Oscar2
		return dz
	end
	speed .= sqrt.(du .^2 .+ dv .^2)
	return speed
end

#---------------------------------------------------------------
function vecs2speed_rev(du,dv) # is this always correct? Oscar2 is reversed only 
	(nlat,nlon,ntime)=size(du)
	speed=Array{Any,3}(undef, (nlat,nlon,ntime))
	speed .= sqrt.(du .^2 .+ dv .^2)
	return speed
end
function vecs2speed(du,dv) # is this always correct? Oscar2 is reversed only 
	(nlon,nlat,ntime)=size(du)
	speed=Array{Any,3}(undef, (nlon,nlat,ntime))
	speed .= sqrt.(du .^2 .+ dv .^2)
	return speed
end
function vecs2speed_lev(du,dv)
	(nlon,nlat,nlev,ntime)=size(du)
	speed=Array{Any,4}(undef, (nlon,nlat,nlev, ntime))
	speed .= sqrt.(du .^2 .+ dv .^2)
	return speed
end
#---------------------------------------------------------------
function main_variable_str(x)
	mainvar=x.main_variable
	ustr,vstr = mainvar[1], mainvar[2]
    return( "[" * ustr * "," * vstr * "]")
end

#-------------------------------------------------------------
function scalar_range(data)
	copy_data=copy(data)
	v=vec(copy_data)
	w=filter(!ismissing, v)
	z=filter(!isnan,w)
	return [minimum(z), maximum(z)]
end

#-------------------------------------------------------------
function speed_range_min(u,v)
	ru=scalar_range(u)
	rv=scalar_range(v)
	return [0,sqrt(min(abs(ru[1]),abs(ru[2]))^2+min(abs(rv[1]),abs(rv[2]))^2)]
end

function speed_range_max(u,v)
	ru=scalar_range(u)
	rv=scalar_range(v)
	return [0,sqrt(max(abs(ru[1]),abs(ru[2]))^2+max(abs(rv[1]),abs(rv[2]))^2)]
end

#--------------------------------------------------------------------------
# chatGPT was isnan:
function filter_missing_vectors(lon, lat, u, v) # for ismissing and near zero removal
    xs = Float32[]
    ys = Float32[]
    us = Float32[]
    vs = Float32[]

    for j in eachindex(u)
        uj = u[j]
        vj = v[j]

        if !ismissing(uj) && !ismissing(vj) && (abs(uj) + abs(vj) > 1e-6)

            push!(xs, lon[j])
            push!(ys, lat[j])
            push!(us, uj)
            push!(vs, vj)
        end
    end

    return xs, ys, us, vs
end

#----------------------------------------------------------------
function filter_and_scale_vectors(
    lon2d, lat2d,
    u, v;
    scale = 1.0,
    minmag = 0.0
)
    xs = Float32[]
    ys = Float32[]
    us = Float32[]
    vs = Float32[]

    for CI in CartesianIndices(u)
        ui = u[CI]
        vi = v[CI]

        if ismissing(ui) || ismissing(vi) || isnan(ui) || isnan(vi)
            continue
        end

        mag = hypot(ui, vi)
        mag ≤ minmag && continue

        # Normalise direction, then scale by magnitude
        s = scale * mag
        push!(xs, lon2d[CI])
        push!(ys, lat2d[CI])
        push!(us, s * (ui / mag))
        push!(vs, s * (vi / mag))
    end

    return xs, ys, us, vs
end
#----------------------------------------------------------------------------------
function filter_and_scale_vectors2(
    lon2d::AbstractMatrix,
    lat2d::AbstractMatrix,
    u::AbstractMatrix,
    v::AbstractMatrix;
    scale = 1.0,
    minmag = 0.0
)
    xs = Float32[]
    ys = Float32[]
    us = Float32[]
    vs = Float32[]

    for CI in CartesianIndices(u)
        ui = u[CI]
        vi = v[CI]

        if ismissing(ui) || ismissing(vi) || isnan(ui) || isnan(vi)
            continue
        end

        mag = hypot(ui, vi)
        mag ≤ minmag && continue

        s = scale * mag
        push!(xs, lon2d[CI])
        push!(ys, lat2d[CI])
        push!(us, s * ui / mag)
        push!(vs, s * vi / mag)
    end

    return xs, ys, us, vs
end
#-------------------------------------------------------------------------------

function meshgrid(lon, lat)

 nlon=length(lon)
 nlat=length(lat)
 lon2d=Array{Float32}(undef, (nlon, nlat))
 lat2d=Array{Float32}(undef, (nlon, nlat))

 for i in 1:length(lon)
		for j in 1:length(lat)
			lon2d[i,j]=lon[i]
			lat2d[i,j]=lat[j]
		end
 end
 return lon2d, lat2d
end

#-------------===============================================================

function cat_map(category::Symbol)::Symbol
    Dict(
		:temperature        => :lajolla,
		:temperature_anom   => :vik,
		:precipitation      => :oslo,
		:pressure           => :tokyo,
		:co2                => :batlow,
		#:vegetation         => :greens, use :generic its nice
		:ocean_temperature  => :hawaii,
		:currents           => :roma,
		:elevation          => :bukavu,
		:wind				=> :speed,
		:radiation			=> :solar,
		:ozone				=> :oxy,
		:clouds				=> :grayC,
		:humidity			=> :nuuk,
		:fire				=> :bilbao,
		:flouds				=> :devon,
		:slainity			=> :haline,
		:zeroone			=> [:red,:white],
		:ice				=> :devon,
		:length				=> :bukavu, # temporary also need volume, area and flux
		:generic            => :diverging_rainbow_bgymr_45_85_c67_n256,
		:default			=> :batlow
    )[category]
end


#-------------------------------------------------------------------